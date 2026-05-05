module arduino::pwm @private;

// ATmega328P PWM registers.
// Timer0 is shared with arduino::time, like the official Arduino core.
const uint TCCR0A_REG = 0x44;
const uint TCCR0B_REG = 0x45;
const uint OCR0A_REG  = 0x47;
const uint OCR0B_REG  = 0x48;

const uint TCCR1A_REG = 0x80;
const uint TCCR1B_REG = 0x81;
const uint OCR1AL_REG = 0x88;
const uint OCR1AH_REG = 0x89;
const uint OCR1BL_REG = 0x8A;
const uint OCR1BH_REG = 0x8B;

const uint TCCR2A_REG = 0xB0;
const uint TCCR2B_REG = 0xB1;
const uint OCR2A_REG  = 0xB3;
const uint OCR2B_REG  = 0xB4;

const uint DDRD_REG = 0x2A;   // D0-D7
const uint DDRB_REG = 0x24;   // D8-D13

const char WGM_FAST_PWM_8 = 0x03;
const char T0_PS64 = 0x03;
const char T1_PS64 = 0x03;
const char T2_PS64 = 0x04;

const char COM_A_ENABLE = 0x80;
const char COM_B_ENABLE = 0x20;

bool timer1_active = false;
bool timer2_active = false;

fn void reg_write(uint addr, char val) {
    @volatile_store(*(char*)(uptr)addr, val);
}

fn char reg_read(uint addr) {
    return @volatile_load(*(char*)(uptr)addr);
}

fn void reg_set(uint addr, char mask) {
    reg_write(addr, (char)(reg_read(addr) | mask));
}

fn void pin_set_output(uint ddr_addr, int bit) {
    reg_set(ddr_addr, (char)(1 << bit));
}

fn void ensure_timer0() {
    // Preserve Arduino timekeeping (TOIE0) and any existing compare output bits.
    reg_set(TCCR0A_REG, WGM_FAST_PWM_8);
    reg_write(TCCR0B_REG, (char)((reg_read(TCCR0B_REG) & (char)0xF8) | T0_PS64));
}

fn void ensure_timer1() {
    if (timer1_active) return;
    // 8-bit Fast PWM: WGM10=1, WGM12=1, TOP=0x00ff; prescaler /64.
    reg_write(TCCR1A_REG, 0x01);
    reg_write(TCCR1B_REG, 0x08 | T1_PS64);
    timer1_active = true;
}

fn void ensure_timer2() {
    if (timer2_active) return;
    reg_write(TCCR2A_REG, WGM_FAST_PWM_8);
    reg_write(TCCR2B_REG, T2_PS64);
    timer2_active = true;
}

fn void write_ocr16(uint low_addr, uint high_addr, char duty) {
    reg_write(high_addr, 0);
    reg_write(low_addr, duty);
}

fn void analog_write_impl(PWMPin pin, char duty) {
    switch (pin) {
        case PWMPin.D3:    // PD3 = OC2B
            ensure_timer2();
            pin_set_output(DDRD_REG, 3);
            reg_set(TCCR2A_REG, COM_B_ENABLE);
            reg_write(OCR2B_REG, duty);
        case PWMPin.D5:    // PD5 = OC0B
            ensure_timer0();
            pin_set_output(DDRD_REG, 5);
            reg_set(TCCR0A_REG, COM_B_ENABLE);
            reg_write(OCR0B_REG, duty);
        case PWMPin.D6:    // PD6 = OC0A
            ensure_timer0();
            pin_set_output(DDRD_REG, 6);
            reg_set(TCCR0A_REG, COM_A_ENABLE);
            reg_write(OCR0A_REG, duty);
        case PWMPin.D9:    // PB1 = OC1A
            ensure_timer1();
            pin_set_output(DDRB_REG, 1);
            reg_set(TCCR1A_REG, COM_A_ENABLE);
            write_ocr16(OCR1AL_REG, OCR1AH_REG, duty);
        case PWMPin.D10:   // PB2 = OC1B
            ensure_timer1();
            pin_set_output(DDRB_REG, 2);
            reg_set(TCCR1A_REG, COM_B_ENABLE);
            write_ocr16(OCR1BL_REG, OCR1BH_REG, duty);
        case PWMPin.D11:   // PB3 = OC2A
            ensure_timer2();
            pin_set_output(DDRB_REG, 3);
            reg_set(TCCR2A_REG, COM_A_ENABLE);
            reg_write(OCR2A_REG, duty);
    }
}
