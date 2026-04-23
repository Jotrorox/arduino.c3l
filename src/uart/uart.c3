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
    switch (baud) {
        case 2400:
            return 832;
        case 4800:
            return 416;
        case 9600:
            return 207;
        case 14400:
            return 138;
        case 19200:
            return 103;
        case 28800:
            return 68;
        case 38400:
            return 51;
        case 57600:
            return 34;
        case 115200:
            return 16;
        default:
            return 207; // 9600
    }
}

fn void begin_impl(uint baud) {
    ushort ubrr = ubrr_for_baud(baud);

    // D1 / TX as output
    char ddrd = reg_read(DDRD_REG);
    reg_write(DDRD_REG, (char)(ddrd | 0x02));

    reg_write(UCSR0B_REG, 0x00);
    reg_write(UCSR0A_REG, U2X0);
    reg_write(UBRR0H_REG, (char)(ubrr >> 8));
    reg_write(UBRR0L_REG, (char)(ubrr & 0xFF));
    reg_write(UCSR0C_REG, UCSZ0_8BIT);
    reg_write(UCSR0B_REG, (char)(RXEN0 | TXEN0));

    initialized = true;
}

fn void write_impl(char c) {
    if (!initialized) begin_impl(9600);

    while ((reg_read(UCSR0A_REG) & UDRE0) == 0) {}
    reg_write(UDR0_REG, c);
}

fn void write_buf_impl(char[] s) {
    if (!initialized) begin_impl(9600);

    for (usz i = 0; i < s.len; i++) {
        write_impl(s[i]);
    }
}

fn void write_zstr_impl(char* s) {
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

fn void write_line_zstr_impl(char* s) {
    write_zstr_impl(s);
    write_crlf_impl();
}

fn bool can_read_impl() {
    if (!initialized) begin_impl(9600);
    return (reg_read(UCSR0A_REG) & RXC0) != 0;
}

fn char read_impl() {
    if (!initialized) begin_impl(9600);

    while ((reg_read(UCSR0A_REG) & RXC0) == 0) {}
    return reg_read(UDR0_REG);
}
