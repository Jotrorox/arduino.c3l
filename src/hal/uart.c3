module arduino::uart @private;

// ATmega328P USART0 register addresses in data space
const uint UCSR0A_REG = 0xC0;
const uint UCSR0B_REG = 0xC1;
const uint UCSR0C_REG = 0xC2;
const uint UBRR0L_REG = 0xC4;
const uint UBRR0H_REG = 0xC5;
const uint UDR0_REG   = 0xC6;

// GPIO direction register for Port D (D0/D1)
const uint DDRD_REG = 0x2A;

// UCSR0A bits
const char RXC0  = 0x80;
const char UDRE0 = 0x20;
const char U2X0  = 0x02;

// UCSR0B bits
const char RXCIE0 = 0x80;
const char RXEN0  = 0x10;
const char TXEN0  = 0x08;

// UCSR0C bits
const char UCSZ0_8BIT = 0x06; // 8N1

const char RX_BUFFER_SIZE = 64;
const char RX_BUFFER_MASK = RX_BUFFER_SIZE - 1;

bool initialized = false;
char[64] rx_buffer;
char rx_head = 0;
char rx_tail = 0;

fn void reg_write(uint addr, char val) {
    @volatile_store(*(char*)(uptr)addr, val);
}

fn char reg_read(uint addr) {
    return @volatile_load(*(char*)(uptr)addr);
}

fn void rx_store(char c) {
    char head = @volatile_load(rx_head);
    char next = (char)((head + 1) & RX_BUFFER_MASK);

    // Drop the new byte when the buffer is full, matching Arduino's
    // non-blocking ISR behavior (old buffered data is preserved).
    if (next != @volatile_load(rx_tail)) {
        rx_buffer[head] = c;
        @volatile_store(rx_head, next);
    }
}

fn void rx_poll_hardware() {
    while ((reg_read(UCSR0A_REG) & RXC0) != 0) {
        rx_store(reg_read(UDR0_REG));
    }
}

fn bool rx_available() {
    rx_poll_hardware();
    return @volatile_load(rx_head) != @volatile_load(rx_tail);
}

fn char rx_read_buffered() {
    while (!rx_available()) {}

    char tail = @volatile_load(rx_tail);
    char c = rx_buffer[tail];
    @volatile_store(rx_tail, (char)((tail + 1) & RX_BUFFER_MASK));
    return c;
}

fn ushort ubrr_for_baud(uint baud) {
    // Standard (non-U2X0) UBRR values for 16 MHz.
    // BAUD = F_CPU / (16 * (UBRR + 1))
    switch (baud) {
        case 2400:   return 416;
        case 4800:   return 207;
        case 9600:   return 103;
        case 14400:  return 68;
        case 19200:  return 51;
        case 28800:  return 34;
        case 38400:  return 25;
        case 57600:  return 16;
        case 115200: return 8;
        default:     return 103; // fallback: 9600
    }
}

fn void begin_impl(uint baud) {
    ushort ubrr = ubrr_for_baud(baud);

    // D1 / TX as output
    char ddrd = reg_read(DDRD_REG);
    reg_write(DDRD_REG, (char)(ddrd | 0x02));

    // Disable TX/RX while reconfiguring.
    reg_write(UCSR0B_REG, 0x00);

    // Write UBRR *before* touching UCSR0A so the bootloader's
    // leftover U2X0 state cannot corrupt the baud generator.
    reg_write(UBRR0H_REG, (char)(ubrr >> 8));
    reg_write(UBRR0L_REG, (char)(ubrr & 0xFF));

    // Explicitly clear U2X0 (and any stale status flags).
    // U2X0 is unreliable after the 115200 optiboot loader because
    // it leaves UCSR0A in an indeterminate state.
    reg_write(UCSR0A_REG, 0x00);

    // Reset buffered RX state whenever Serial is (re)configured.
    @volatile_store(rx_head, (char)0);
    @volatile_store(rx_tail, (char)0);

    reg_write(UCSR0C_REG, UCSZ0_8BIT);
    reg_write(UCSR0B_REG, (char)(RXCIE0 | RXEN0 | TXEN0));
    asm("sei");

    initialized = true;
}

fn void write_impl(char c) {
    if (!initialized) begin_impl(9600);
    while ((reg_read(UCSR0A_REG) & UDRE0) == 0) {}
    reg_write(UDR0_REG, c);
}

fn void write_string_impl(char[] s) {
    if (!initialized) begin_impl(9600);
    for (usz i = 0; i < s.len; i++) {
        write_impl(s[i]);
    }
}

fn void write_zstring_impl(char* s) {
    if (!initialized) begin_impl(9600);
    char* p = s;
    while (*p != 0) {
        write_impl(*p);
        p++;
    }
}

fn void write_crlf_impl() {
    write_impl('\r');
    write_impl('\n');
}

fn void write_line_impl(char[] s) {
    write_string_impl(s);
    write_crlf_impl();
}

fn void write_line_zstring_impl(char* s) {
    write_zstring_impl(s);
    write_crlf_impl();
}

fn bool can_read_impl() {
    if (!initialized) begin_impl(9600);
    return rx_available();
}

fn char read_impl() {
    if (!initialized) begin_impl(9600);
    return rx_read_buffered();
}

// Non-blocking: copy bytes from the interrupt-driven RX ring into buf.
// Returns the number of bytes written. 0 means nothing was buffered.
fn usz read_buf_impl(char[] buf) {
    if (!initialized) begin_impl(9600);
    usz n = 0;
    while (n < buf.len && rx_available()) {
        buf[n] = rx_read_buffered();
        n++;
    }
    return n;
}

// Blocking: fill buf completely before returning.
// Always returns buf.len.
fn usz read_buf_exact_impl(char[] buf) {
    if (!initialized) begin_impl(9600);
    for (usz i = 0; i < buf.len; i++) {
        buf[i] = rx_read_buffered();
    }
    return buf.len;
}

// Blocking: read until \n or \r\n, store into buf, null-terminate.
// Returns the number of data bytes written (excluding the '\0').
// buf.len must be >= 1; one byte is reserved for the null terminator.
// The line terminator is consumed but NOT stored.
fn usz read_line_impl(char[] buf) {
    if (!initialized) begin_impl(9600);
    if (buf.len == 0) return 0;

    usz n   = 0;
    usz cap = buf.len - 1; // one byte reserved for '\0'

    while (n < cap) {
        char c = rx_read_buffered();

        if (c == '\n') break;

        if (c == '\r') {
            // Attempt to consume a paired \n (CR+LF).
            // Spin briefly rather than blocking forever (bare-CR senders).
            uint timeout = 1000;
            while (timeout > 0 && !rx_available()) {
                timeout--;
            }
            if (rx_available()) {
                char next = rx_read_buffered();
                if (next != '\n') {
                    // Not the paired LF - treat as regular data
                    buf[n] = next;
                    n++;
                }
            }
            break;
        }

        buf[n] = c;
        n++;
    }

    buf[n] = 0; // null-terminate so buf.ptr can be used as char* safely
    return n;   // excludes the '\0'
}

fn void print_ulong(ulong value) {
    if (value == 0) {
        write_impl('0');
        return;
    }
    bool started = false;
    ulong[10] powers = {
        1000000000, 100000000, 10000000, 1000000,
        100000, 10000, 1000, 100, 10, 1
    };
    for (int i = 0; i < 10; i++) {
        char digit = 0;
        ulong p = powers[i];
        while (value >= p) {
            value = value - p;
            digit++;
        }
        if (digit > 0 || started || i == 9) {
            write_impl((char)(digit + '0'));
            started = true;
        }
    }
}

fn void print_long(long value) {
    if (value == 0) {
        write_impl('0');
        return;
    }
    if (value < 0) {
        write_impl('-');
        value = -value;
    }
    print_ulong((ulong)value);
}

fn int ulong_digits(ulong value) {
    if (value == 0) return 1;
    int digits = 0;
    ulong[10] powers = {
        1000000000, 100000000, 10000000, 1000000,
        100000, 10000, 1000, 100, 10, 1
    };
    for (int i = 0; i < 10; i++) {
        if (value >= powers[i]) digits = i + 1;
    }
    return digits;
}

fn void print_ulong_width(ulong value, int width, char pad) {
    int digits = ulong_digits(value);
    for (int p = digits; p < width; p++) {
        write_impl(pad);
    }
    print_ulong(value);
}

fn void print_long_width(long value, int width, char pad) {
    if (value < 0) {
        value = -value;
        int digits = ulong_digits((ulong)value);
        int total = digits + 1;
        if (pad == '0') {
            write_impl('-');
            for (int p = total; p < width; p++) write_impl('0');
        } else {
            for (int p = total; p < width; p++) write_impl(' ');
            write_impl('-');
        }
        print_ulong((ulong)value);
    } else {
        print_ulong_width((ulong)value, width, pad);
    }
}

fn int ulong_hex_digits(ulong value) {
    if (value == 0) return 1;
    int digits = 0;
    ulong v = value;
    while (v > 0) {
        v >>= 4;
        digits++;
    }
    return digits;
}

fn void print_hex_ulong_width(ulong value, int width, bool upper) {
    char[] hex = upper ? "0123456789ABCDEF" : "0123456789abcdef";
    int digits = ulong_hex_digits(value);
    for (int p = digits; p < width; p++) {
        write_impl('0');
    }
    if (value == 0) {
        write_impl('0');
        return;
    }
    char[16] buf;
    int len = 0;
    while (value > 0) {
        buf[len++] = hex[value & 0xF];
        value >>= 4;
    }
    for (int j = len - 1; j >= 0; j--) {
        write_impl(buf[j]);
    }
}

fn void print_impl(Type value) <Type> {
    $if (Type == int):
        print_long((long)value);
    $else
        $if (Type == uint):
            print_ulong((ulong)value);
        $else
            $if (Type == short):
                print_long((long)value);
            $else
                $if (Type == ushort):
                    print_ulong((ulong)value);
                $else
                    $if (Type == long):
                        print_long(value);
                    $else
                        $if (Type == ulong):
                            print_ulong(value);
                        $else
                            $if (Type == char):
                                write_impl(value);
                            $else
                                $if (Type == ichar):
                                    print_long((long)value);
                                $else
                                    $if (Type == bool):
                                        if (value) {
                                            write_string_impl("true");
                                        } else {
                                            write_string_impl("false");
                                        }
                                    $else
                                        $if (Type == char[]):
                                            write_string_impl(value);
                                        $else
                                            $if (Type == String):
                                                write_string_impl(value);
                                            $else
                                                $if (Type == char*):
                                                    write_zstring_impl(value);
                                                $else
                                                    $error("Unsupported type for print");
                                                $endif
                                            $endif
                                        $endif
                                    $endif
                                $endif
                            $endif
                        $endif
                    $endif
                $endif
        $endif
    $endif
$endif
}

fn void println_impl(Type value) <Type> {
    print_impl(value);
    write_crlf_impl();
}

fn void printf_impl(char[] fmt, args...) {
    int arg_idx = 0;
    for (usz i = 0; i < fmt.len; i++) {
        char c = fmt[i];
        if (c != '%') {
            write_impl(c);
            continue;
        }
        if (i + 1 >= fmt.len) break;
        i++;

        char pad = ' ';
        if (fmt[i] == '0') {
            pad = '0';
            i++;
        }
        int width = 0;
        while (i < fmt.len && fmt[i] >= '0' && fmt[i] <= '9') {
            width = width * 10 + (int)(fmt[i] - '0');
            i++;
        }
        if (i >= fmt.len) break;

        char spec = fmt[i];
        if (spec == '%') {
            write_impl('%');
            continue;
        }

        if (arg_idx >= args.len) {
            write_impl('?');
            continue;
        }
        any a = args[arg_idx];
        arg_idx++;

        switch (spec) {
            case 'd':
            case 'i':
                long val = 0;
                switch (a.type) {
                    case int:
                        val = (long)*(int*)a.ptr;
                    case short:
                        val = (long)*(short*)a.ptr;
                    case long:
                        val = *(long*)a.ptr;
                    case char:
                        val = (long)*(char*)a.ptr;
                    case ichar:
                        val = (long)*(ichar*)a.ptr;
                    case bool:
                        val = *(bool*)a.ptr ? 1 : 0;
                    default:
                        write_impl('?');
                        continue;
                }
                print_long_width(val, width, pad);
            case 'u':
                ulong val = 0;
                switch (a.type) {
                    case uint:
                        val = (ulong)*(uint*)a.ptr;
                    case ushort:
                        val = (ulong)*(ushort*)a.ptr;
                    case ulong:
                        val = *(ulong*)a.ptr;
                    case char:
                        val = (ulong)*(char*)a.ptr;
                    default:
                        write_impl('?');
                        continue;
                }
                print_ulong_width(val, width, pad);
            case 'x':
            case 'X':
                ulong val = 0;
                switch (a.type) {
                    case uint:
                        val = (ulong)*(uint*)a.ptr;
                    case ushort:
                        val = (ulong)*(ushort*)a.ptr;
                    case ulong:
                        val = *(ulong*)a.ptr;
                    case char:
                        val = (ulong)*(char*)a.ptr;
                    case int:
                        val = (ulong)*(int*)a.ptr;
                    case short:
                        val = (ulong)*(short*)a.ptr;
                    case long:
                        val = (ulong)*(long*)a.ptr;
                    default:
                        write_impl('?');
                        continue;
                }
                print_hex_ulong_width(val, width, spec == 'X');
            case 's':
                switch (a.type) {
                    case char[]:
                        char[]* p = (char[]*)a.ptr;
                        write_string_impl(*p);
                    case char*:
                        char** p = (char**)a.ptr;
                        write_zstring_impl(*p);
                    default:
                        write_impl('?');
                }
            case 'c':
                if (a.type == char) {
                    write_impl(*(char*)a.ptr);
                } else if (a.type == ichar) {
                    write_impl((char)*(ichar*)a.ptr);
                } else {
                    write_impl('?');
                }
            case 'p':
                write_impl('0');
                write_impl('x');
                print_hex_ulong_width((ulong)(uptr)a.ptr, width, true);
            default:
                write_impl('?');
        }
    }
}

fn void usart_rx_impl() @export("usart_rx_impl") {
    rx_store(reg_read(UDR0_REG));
}

fn void __vector_18() @naked @export("__vector_18") {
    // USART RX complete. Save the same call-clobbered register set used by
    // the Timer0 ISR wrapper, then return with RETI.
    asm("push r0");
    asm("in r0, 0x3f");
    asm("push r0");
    asm("push r1");
    asm("eor r1, r1");
    asm("push r18");
    asm("push r19");
    asm("push r20");
    asm("push r21");
    asm("push r22");
    asm("push r23");
    asm("push r24");
    asm("push r25");
    asm("push r26");
    asm("push r27");
    asm("push r30");
    asm("push r31");
    asm("rcall usart_rx_impl");
    asm("pop r31");
    asm("pop r30");
    asm("pop r27");
    asm("pop r26");
    asm("pop r25");
    asm("pop r24");
    asm("pop r23");
    asm("pop r22");
    asm("pop r21");
    asm("pop r20");
    asm("pop r19");
    asm("pop r18");
    asm("pop r1");
    asm("pop r0");
    asm("out 0x3f, r0");
    asm("pop r0");
    asm("reti");
}
