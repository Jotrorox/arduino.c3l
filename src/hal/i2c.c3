module arduino::i2c @private;

// TWI register addresses
const uint TWBR_REG = 0xB8;
const uint TWSR_REG = 0xB9;
const uint TWDR_REG = 0xBB;
const uint TWCR_REG = 0xBC;

// TWCR control bits
const char TWINT = 0x80; // Interrupt flag (clear by writing 1)
const char TWEA  = 0x40; // Enable acknowledge
const char TWSTA = 0x20; // START condition
const char TWSTO = 0x10; // STOP condition
const char TWEN  = 0x04; // TWI enable

// Status mask (prescaler bits are in TWSR [1:0])
const char STATUS_MASK = 0xF8;

// Master transmitter / receiver status codes
const char STATUS_START      = 0x08;
const char STATUS_REP_START  = 0x10;
const char STATUS_SLA_W_ACK  = 0x18;
const char STATUS_SLA_W_NACK = 0x20;
const char STATUS_TX_ACK     = 0x28;
const char STATUS_TX_NACK    = 0x30;
const char STATUS_SLA_R_ACK  = 0x40;
const char STATUS_SLA_R_NACK = 0x48;
const char STATUS_RX_ACK     = 0x50;
const char STATUS_RX_NACK    = 0x58;

// Buffers
const char BUF_SIZE = 32;
char[BUF_SIZE] tx_buf;
char[BUF_SIZE] rx_buf;
char tx_len = 0;
char tx_pos = 0;
char rx_len = 0;
char rx_pos = 0;
char tx_addr = 0;
bool initialized = false;

// Register helpers
fn void reg_write(uint addr, char val) {
    @volatile_store(*(char*)(uptr)addr, val);
}

fn char reg_read(uint addr) {
    return @volatile_load(*(char*)(uptr)addr);
}

fn bool twi_wait() {
    uint timeout = 60000;
    while ((reg_read(TWCR_REG) & TWINT) == 0) {
        if (timeout == 0) return false;
        timeout--;
    }
    return true;
}

fn char twi_status() {
    return (char)(reg_read(TWSR_REG) & STATUS_MASK);
}

// Low-level primitives

fn void init_impl() {
    if (initialized) return;

    // SDA = PC4, SCL = PC5. Enable internal pull-ups.
    char* ddrc  = (char*)(uptr)0x27;
    char* portc = (char*)(uptr)0x28;
    *ddrc  = (char)(*ddrc  & (char)~0x30);
    *portc = (char)(*portc | 0x30);

    // 100 kHz @ 16 MHz: prescaler = 1, TWBR = 72
    reg_write(TWSR_REG, 0x00);
    reg_write(TWBR_REG, 72);
    reg_write(TWCR_REG, (char)(TWEN));
    initialized = true;
}

fn bool start_impl() {
    reg_write(TWCR_REG, (char)(TWINT | TWSTA | TWEN));
    return twi_wait();
}

fn void stop_impl() {
    reg_write(TWCR_REG, (char)(TWINT | TWSTO | TWEN));
    uint timeout = 60000;
    while ((reg_read(TWCR_REG) & TWSTO) != 0 && timeout > 0) {
        timeout--;
    }
}

fn bool send_byte_impl(char b) {
    reg_write(TWDR_REG, b);
    reg_write(TWCR_REG, (char)(TWINT | TWEN));
    if (!twi_wait()) return false;
    char s = twi_status();
    return s == STATUS_TX_ACK || s == STATUS_SLA_W_ACK;
}

fn char read_byte_raw_impl(bool ack) {
    if (ack) {
        reg_write(TWCR_REG, (char)(TWINT | TWEA | TWEN));
    } else {
        reg_write(TWCR_REG, (char)(TWINT | TWEN));
    }
    if (!twi_wait()) return 0;
    return reg_read(TWDR_REG);
}

fn bool start_write_impl(char addr) {
    init_impl();
    if (!start_impl()) return false;
    char s = twi_status();
    if (s != STATUS_START && s != STATUS_REP_START) return false;
    reg_write(TWDR_REG, (char)(addr << 1));
    reg_write(TWCR_REG, (char)(TWINT | TWEN));
    if (!twi_wait()) return false;
    return twi_status() == STATUS_SLA_W_ACK;
}

fn bool start_read_impl(char addr) {
    init_impl();
    if (!start_impl()) return false;
    char s = twi_status();
    if (s != STATUS_START && s != STATUS_REP_START) return false;
    reg_write(TWDR_REG, (char)((addr << 1) | 0x01));
    reg_write(TWCR_REG, (char)(TWINT | TWEN));
    if (!twi_wait()) return false;
    return twi_status() == STATUS_SLA_R_ACK;
}

// High-level Wire-like API

fn void begin_transmission_impl(char addr) {
    tx_addr = addr;
    tx_len = 0;
    tx_pos = 0;
}

fn void write_impl(char b) {
    if (tx_len < BUF_SIZE) {
        tx_buf[tx_len] = b;
        tx_len++;
    }
}

fn void write_bytes_impl(char[] data) {
    for (usz i = 0; i < data.len && tx_len < BUF_SIZE; i++) {
        tx_buf[tx_len] = data[i];
        tx_len++;
    }
}

// Returns 0 on success, 2 = NACK on address, 3 = NACK on data
fn char end_transmission_impl() {
    if (!start_write_impl(tx_addr)) {
        stop_impl();
        return 2;
    }

    for (char i = 0; i < tx_len; i++) {
        if (!send_byte_impl(tx_buf[i])) {
            stop_impl();
            return 3;
        }
    }

    stop_impl();
    return 0;
}

fn char request_from_impl(char addr, char quantity) {
    if (quantity == 0) {
        rx_len = 0;
        rx_pos = 0;
        return 0;
    }
    if (quantity > BUF_SIZE) quantity = BUF_SIZE;

    if (!start_read_impl(addr)) {
        stop_impl();
        rx_len = 0;
        rx_pos = 0;
        return 0;
    }

    for (char i = 0; i < quantity; i++) {
        bool ack = (i < quantity - 1);
        rx_buf[i] = read_byte_raw_impl(ack);
    }

    stop_impl();
    rx_len = quantity;
    rx_pos = 0;
    return quantity;
}

fn char available_impl() {
    return (char)(rx_len - rx_pos);
}

fn char read_byte_impl() {
    if (rx_pos >= rx_len) return 0;
    char b = rx_buf[rx_pos];
    rx_pos++;
    return b;
}

fn bool scan_impl(char addr) {
    // Scan only the normal 7-bit user address range. Reserved addresses can
    // behave strangely on some devices/buses and are not useful here.
    if (addr < 0x08 || addr > 0x77) return false;

    // A plain SLA+W probe can report false positives on a marginal/stuck AVR
    // TWI bus. Be stricter: require the device to ACK both write and read
    // addressing. The sensors used by these examples (AHT20 and BMP280/BME280)
    // support both directions, and this avoids printing every address.
    bool write_ack = start_write_impl(addr);
    stop_impl();
    if (!write_ack) return false;

    time_delay_scan_impl();

    bool read_ack = start_read_impl(addr);
    stop_impl();
    return read_ack;
}

fn void time_delay_scan_impl() {
    // Short settle delay between STOP and the next START without importing the
    // time module into this low-level HAL.
    for (uint i = 0; i < 2000; i++) { }
}
