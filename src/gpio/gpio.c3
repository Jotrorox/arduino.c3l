module arduino::gpio @private;

// Data-space addresses (I/O base + 0x20)
// PORTB=0x25 DDRB=0x24 PINB=0x23  →  D8-D13 (PB0-PB5)
// PORTC=0x28 DDRC=0x27 PINC=0x26  →  A0-A5  (PC0-PC5)
// PORTD=0x2B DDRD=0x2A PIND=0x29  →  D0-D7  (PD0-PD7)

fn char get_port(int pin) {
    if (pin <= 7)  return 0x2B;
    if (pin <= 13) return 0x25;
    return 0x28;
}
fn char get_ddr(int pin) {
    if (pin <= 7)  return 0x2A;
    if (pin <= 13) return 0x24;
    return 0x27;
}
fn char get_pin_reg(int pin) {
    if (pin <= 7)  return 0x29;
    if (pin <= 13) return 0x23;
    return 0x26;
}
fn char get_bit(int pin) {
    if (pin <= 7)  return (char)pin;
    if (pin <= 13) return (char)(pin - 8);
    return (char)(pin - 14);
}

fn void reg_set(char addr, char bit) {
    char* r = (char*)(uptr)addr;
    *r = (char)(*r | (char)(1 << bit));
}
fn void reg_clr(char addr, char bit) {
    char* r = (char*)(uptr)addr;
    *r = (char)(*r & (char)~(1 << bit));
}
fn char reg_read(char addr) {
    char* r = (char*)(uptr)addr;
    return *r;
}

fn void pin_mode_impl(int pin, int mode) {
    if (pin < 0 || pin >= 20) return;
    char bit  = get_bit(pin);
    char ddr  = get_ddr(pin);
    char port = get_port(pin);
    switch (mode) {
        case OUTPUT:
            reg_set(ddr, bit);
        case INPUT:
            reg_clr(ddr, bit);
            reg_clr(port, bit);
        case INPUT_PULLUP:
            reg_clr(ddr, bit);
            reg_set(port, bit);
    }
}

fn void digital_write_impl(int pin, int value) {
    if (pin < 0 || pin >= 20) return;
    char bit  = get_bit(pin);
    char port = get_port(pin);
    if (value != LOW) {
        reg_set(port, bit);
    } else {
        reg_clr(port, bit);
    }
}

fn int digital_read_impl(int pin) {
    if (pin < 0 || pin >= 20) return LOW;
    char bit     = get_bit(pin);
    char pin_reg = get_pin_reg(pin);
    return (reg_read(pin_reg) & (char)(1 << bit)) != 0 ? HIGH : LOW;
}