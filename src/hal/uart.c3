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
const char RXEN0 = 0x10;
const char TXEN0 = 0x08;

// UCSR0C bits
const char UCSZ0_8BIT = 0x06; // 8N1

bool initialized = false;

fn void reg_write(uint addr, char val) {
    @volatile_store(*(char*)(uptr)addr, val);
}

fn char reg_read(uint addr) {
    return @volatile_load(*(char*)(uptr)addr);
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

    // Write UBRR *before* touching UCSR0A so the bootloader’s
    // leftover U2X0 state cannot corrupt the baud generator.
    reg_write(UBRR0H_REG, (char)(ubrr >> 8));
    reg_write(UBRR0L_REG, (char)(ubrr & 0xFF));

    // Explicitly clear U2X0 (and any stale status flags).
    // U2X0 is unreliable after the 115200 optiboot loader because
    // it leaves UCSR0A in an indeterminate state.
    reg_write(UCSR0A_REG, 0x00);

    reg_write(UCSR0C_REG, UCSZ0_8BIT);
    reg_write(UCSR0B_REG, (char)(RXEN0 | TXEN0));

    initialized = true;
}

// ── TX ────────────────────────────────────────────────────────────────────────

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

// ── RX ────────────────────────────────────────────────────────────────────────

fn bool can_read_impl() {
    if (!initialized) begin_impl(9600);
    return (reg_read(UCSR0A_REG) & RXC0) != 0;
}

fn char read_impl() {
    if (!initialized) begin_impl(9600);
    while ((reg_read(UCSR0A_REG) & RXC0) == 0) {}
    return reg_read(UDR0_REG);
}

// Non-blocking: drain whatever bytes are waiting in the HW FIFO into buf.
// Returns the number of bytes written. 0 means nothing was waiting.
fn usz read_buf_impl(char[] buf) {
    if (!initialized) begin_impl(9600);
    usz n = 0;
    while (n < buf.len && (reg_read(UCSR0A_REG) & RXC0) != 0) {
        buf[n] = reg_read(UDR0_REG);
        n++;
    }
    return n;
}

// Blocking: fill buf completely before returning.
// Always returns buf.len.
fn usz read_buf_exact_impl(char[] buf) {
    if (!initialized) begin_impl(9600);
    for (usz i = 0; i < buf.len; i++) {
        while ((reg_read(UCSR0A_REG) & RXC0) == 0) {}
        buf[i] = reg_read(UDR0_REG);
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
        while ((reg_read(UCSR0A_REG) & RXC0) == 0) {}
        char c = reg_read(UDR0_REG);

        if (c == '\n') break;

        if (c == '\r') {
            // Attempt to consume a paired \n (CR+LF).
            // Spin briefly rather than blocking forever (bare-CR senders).
            uint timeout = 1000;
            while (timeout > 0 && (reg_read(UCSR0A_REG) & RXC0) == 0) {
                timeout--;
            }
            if ((reg_read(UCSR0A_REG) & RXC0) != 0) {
                char next = reg_read(UDR0_REG);
                if (next != '\n') {
                    // Not the paired LF — treat as regular data
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
