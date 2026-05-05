module arduino::gpio @private;

// Data-space addresses (I/O base + 0x20)
// PORTB=0x25 DDRB=0x24 PINB=0x23  →  D8-D13 (PB0-PB5)
// PORTC=0x28 DDRC=0x27 PINC=0x26  →  A0-A5  (PC0-PC5)
// PORTD=0x2B DDRD=0x2A PIND=0x29  →  D0-D7  (PD0-PD7)

fn char get_port(Pin pin) {
    if ((int)pin <= 7)  return 0x2B;
    if ((int)pin <= 13) return 0x25;
    return 0x28;
}
fn char get_ddr(Pin pin) {
    if ((int)pin <= 7)  return 0x2A;
    if ((int)pin <= 13) return 0x24;
    return 0x27;
}
fn char get_pin_reg(Pin pin) {
    if ((int)pin <= 7)  return 0x29;
    if ((int)pin <= 13) return 0x23;
    return 0x26;
}
fn char get_bit(Pin pin) {
    if ((int)pin <= 7)  return (char)pin;
    if ((int)pin <= 13) return (char)(pin - 8);
    return (char)((int)pin - 14);
}

fn void reg_set(char addr, char bit) {
    char* r = (char*)(uptr)addr;
    @volatile_store(*r, (char)(@volatile_load(*r) | (char)(1 << bit)));
}
fn void reg_clr(char addr, char bit) {
    char* r = (char*)(uptr)addr;
    @volatile_store(*r, (char)(@volatile_load(*r) & (char)~(1 << bit)));
}
fn void reg_clr_mask(char addr, char mask) {
    char* r = (char*)(uptr)addr;
    @volatile_store(*r, (char)(@volatile_load(*r) & (char)~mask));
}
fn char reg_read(char addr) {
    char* r = (char*)(uptr)addr;
    return @volatile_load(*r);
}

fn void disable_pwm(Pin pin) {
    // Match Arduino's turnOffPWM(): normal digital I/O must disconnect
    // timer compare output from PWM-capable pins.
    switch (pin) {
        case Pin.D3:  reg_clr_mask(0xB0, 0x30); // OC2B / COM2B1:0
        case Pin.D5:  reg_clr_mask(0x44, 0x30); // OC0B / COM0B1:0
        case Pin.D6:  reg_clr_mask(0x44, 0xC0); // OC0A / COM0A1:0
        case Pin.D9:  reg_clr_mask(0x80, 0xC0); // OC1A / COM1A1:0
        case Pin.D10: reg_clr_mask(0x80, 0x30); // OC1B / COM1B1:0
        case Pin.D11: reg_clr_mask(0xB0, 0xC0); // OC2A / COM2A1:0
        default:
    }
}

fn void pin_mode_impl(Pin pin, PinMode mode) {
    if ((int)pin < 0 || (int)pin >= 20) return;
    disable_pwm(pin);
    char bit  = get_bit(pin);
    char ddr  = get_ddr(pin);
    char port = get_port(pin);
    switch (mode) {
        case PinMode.OUTPUT:
            reg_set(ddr, bit);
        case PinMode.INPUT:
            reg_clr(ddr, bit);
            reg_clr(port, bit);
        case PinMode.INPUT_PULLUP:
            reg_clr(ddr, bit);
            reg_set(port, bit);
    }
}

fn void digital_write_impl(Pin pin, PinState value) {
    if ((int)pin < 0 || (int)pin >= 20) return;
    disable_pwm(pin);
    char bit  = get_bit(pin);
    char port = get_port(pin);
    if (value != PinState.LOW) {
        reg_set(port, bit);
    } else {
        reg_clr(port, bit);
    }
}

fn PinState digital_read_impl(Pin pin) {
    if ((int)pin < 0 || (int)pin >= 20) return PinState.LOW;
    char bit     = get_bit(pin);
    char pin_reg = get_pin_reg(pin);
    return (reg_read(pin_reg) & (char)(1 << bit)) != 0 ? PinState.HIGH : PinState.LOW;
}