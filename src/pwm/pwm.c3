module arduino::pwm @private;

// Timer0 registers — drives D6 (OC0A) and D5 (OC0B)
const uint TCCR0A_REG = 0x44;
const uint TCCR0B_REG = 0x45;
const uint TCNT0_REG  = 0x46;
const uint OCR0A_REG  = 0x47;
const uint OCR0B_REG  = 0x48;

// Timer2 registers — drives D11 (OC2A) and D3 (OC2B)
const uint TCCR2A_REG = 0xB0;
const uint TCCR2B_REG = 0xB1;
const uint TCNT2_REG  = 0xB2;
const uint OCR2A_REG  = 0xB3;
const uint OCR2B_REG  = 0xB4;

// Port data-direction registers
const uint DDRD_REG = 0x2A;   // Port D: D0-D7
const uint DDRB_REG = 0x24;   // Port B: D8-D13

// TCCR0A / TCCR2A bit patterns
//   WGM01:WGM00 = 11  →  Fast PWM, TOP = 0xFF
//   COM_A_ENABLE       →  non-inverting output on OC_A (bit 7)
//   COM_B_ENABLE       →  non-inverting output on OC_B (bit 5)
const char WGM_FAST_PWM  = 0x03;
const char COM_A_ENABLE  = 0x80;
const char COM_B_ENABLE  = 0x20;

// Prescaler selections
//   Timer0 CS01:CS00 = 11  →  clk/64  ≈  976 Hz PWM @ 16 MHz
//   Timer2 CS22      = 1   →  clk/64  ≈  976 Hz PWM @ 16 MHz
const char T0_PS64 = 0x03;
const char T2_PS64 = 0x04;

bool timer0_active = false;
bool timer2_active = false;

fn void reg_write(uint addr, char val) {
    $$volatile_store((char*)(uptr)addr, val);
}

fn char reg_read(uint addr) {
    return $$volatile_load((char*)(uptr)addr);
}

fn void pin_set_output(uint ddr_addr, int bit) {
    char* r = (char*)(uptr)ddr_addr;
    *r = (char)(*r | (char)(1 << bit));
}

fn void ensure_timer0() {
    if (timer0_active) return;
    reg_write(TCCR0A_REG, WGM_FAST_PWM);
    reg_write(TCCR0B_REG, T0_PS64);
    reg_write(TCNT0_REG, 0);
    timer0_active = true;
}

fn void ensure_timer2() {
    if (timer2_active) return;
    reg_write(TCCR2A_REG, WGM_FAST_PWM);
    reg_write(TCCR2B_REG, T2_PS64);
    reg_write(TCNT2_REG, 0);
    timer2_active = true;
}

fn void analog_write_impl(PWMPin pin, char duty) {
    switch (pin) {
        case PWMPin.D6:    // D6 = PD6 = OC0A  (Timer0 channel A)
            ensure_timer0();
            pin_set_output(DDRD_REG, 6);
            reg_write(TCCR0A_REG, (char)(reg_read(TCCR0A_REG) | COM_A_ENABLE));
            reg_write(OCR0A_REG, duty);
        case PWMPin.D5:    // D5 = PD5 = OC0B  (Timer0 channel B)
            ensure_timer0();
            pin_set_output(DDRD_REG, 5);
            reg_write(TCCR0A_REG, (char)(reg_read(TCCR0A_REG) | COM_B_ENABLE));
            reg_write(OCR0B_REG, duty);
        case PWMPin.D11:   // D11 = PB3 = OC2A  (Timer2 channel A)
            ensure_timer2();
            pin_set_output(DDRB_REG, 3);
            reg_write(TCCR2A_REG, (char)(reg_read(TCCR2A_REG) | COM_A_ENABLE));
            reg_write(OCR2A_REG, duty);
        case PWMPin.D3:    // D3 = PD3 = OC2B  (Timer2 channel B)
            ensure_timer2();
            pin_set_output(DDRD_REG, 3);
            reg_write(TCCR2A_REG, (char)(reg_read(TCCR2A_REG) | COM_B_ENABLE));
            reg_write(OCR2B_REG, duty);
    }
}
