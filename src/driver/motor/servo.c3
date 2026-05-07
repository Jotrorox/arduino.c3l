module arduino::driver::motor::servo @private;

// Timer1 registers on ATmega328P.
const uint TCCR1A_REG = 0x80;
const uint TCCR1B_REG = 0x81;
const uint ICR1L_REG  = 0x86;
const uint ICR1H_REG  = 0x87;
const uint OCR1AL_REG = 0x88;
const uint OCR1AH_REG = 0x89;
const uint OCR1BL_REG = 0x8A;
const uint OCR1BH_REG = 0x8B;
const uint DDRB_REG   = 0x24;

// Fast PWM, TOP=ICR1, prescaler /8. At 16 MHz this gives 0.5 us ticks.
const ushort SERVO_TOP_TICKS = 39999; // 20 ms / 50 Hz
const char WGM11 = 0x02;
const char WGM13_WGM12 = 0x18;
const char CS11 = 0x02;
const char COM1A_ENABLE = 0x80;
const char COM1B_ENABLE = 0x20;

bool timer_ready = false;

fn void reg_write(uint addr, char val) {
    @volatile_store(*(char*)(uptr)addr, val);
}

fn char reg_read(uint addr) {
    return @volatile_load(*(char*)(uptr)addr);
}

fn void reg_set(uint addr, char mask) {
    reg_write(addr, (char)(reg_read(addr) | mask));
}

fn void reg_clr(uint addr, char mask) {
    reg_write(addr, (char)(reg_read(addr) & (char)~mask));
}

fn void write_u16(uint low_addr, uint high_addr, ushort value) {
    reg_write(high_addr, (char)(value >> 8));
    reg_write(low_addr, (char)value);
}

fn void ensure_timer1() {
    if (timer_ready) return;

    // Mode 14 Fast PWM: WGM13:0 = 1110, TOP=ICR1, non-inverting outputs.
    reg_write(TCCR1A_REG, WGM11);
    reg_write(TCCR1B_REG, (char)(WGM13_WGM12 | CS11));
    write_u16(ICR1L_REG, ICR1H_REG, SERVO_TOP_TICKS);
    timer_ready = true;
}

fn ushort clamp_pulse(ushort pulse_us) {
    if (pulse_us < MIN_PULSE_US) return MIN_PULSE_US;
    if (pulse_us > MAX_PULSE_US) return MAX_PULSE_US;
    return pulse_us;
}

fn void write_us_impl(ServoPin pin, ushort pulse_us) {
    ensure_timer1();
    ushort ticks = (ushort)(clamp_pulse(pulse_us) * 2);

    switch (pin) {
        case ServoPin.D9:
            reg_set(DDRB_REG, 0x02); // PB1 / OC1A
            reg_set(TCCR1A_REG, COM1A_ENABLE);
            write_u16(OCR1AL_REG, OCR1AH_REG, ticks);
        case ServoPin.D10:
            reg_set(DDRB_REG, 0x04); // PB2 / OC1B
            reg_set(TCCR1A_REG, COM1B_ENABLE);
            write_u16(OCR1BL_REG, OCR1BH_REG, ticks);
    }
}

fn void write_angle_impl(ServoPin pin, int angle) {
    if (angle < 0) angle = 0;
    if (angle > 180) angle = 180;

    ushort pulse = (ushort)((int)MIN_PULSE_US + (((int)MAX_PULSE_US - (int)MIN_PULSE_US) * angle) / 180);
    write_us_impl(pin, pulse);
}

fn void attach_impl(ServoPin pin) {
    write_us_impl(pin, DEFAULT_PULSE_US);
}

fn void detach_impl(ServoPin pin) {
    switch (pin) {
        case ServoPin.D9:  reg_clr(TCCR1A_REG, 0xC0);
        case ServoPin.D10: reg_clr(TCCR1A_REG, 0x30);
    }
}
