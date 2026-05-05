module arduino::time @private;

// Arduino-compatible time base for ATmega328P.
// Timer0 runs in Fast PWM mode with a /64 prescaler.  It overflows every
// 256 ticks (1024 us at 16 MHz), exactly like the official Arduino core.
// Keeping time on Timer0 leaves Timer1 free for PWM on D9/D10.
const uint TCCR0A = 0x44;
const uint TCCR0B = 0x45;
const uint TCNT0  = 0x46;
const uint TIMSK0 = 0x6E;
const uint TIFR0  = 0x35;
const uint SREG   = 0x5F;

const char WGM01_WGM00 = 0x03; // Fast PWM, TOP = 0xff
const char CS00_CS01   = 0x03; // clk/64
const char TOIE0_BIT   = 0x01;
const char TOV0_BIT    = 0x01;

const uint MILLIS_INC = 1;
const char FRACT_INC = 3;      // (1024 % 1000) >> 3
const char FRACT_MAX = 125;    // 1000 >> 3

uint timer0_overflow_count = 0;
uint timer0_millis = 0;
char timer0_fract = 0;
bool timer0_time_active = false;

fn void reg_write(uint addr, char val) {
    @volatile_store(*(char*)(uptr)addr, val);
}

fn char reg_read(uint addr) {
    return @volatile_load(*(char*)(uptr)addr);
}

fn void reg_set(uint addr, char mask) {
    reg_write(addr, (char)(reg_read(addr) | mask));
}

fn void arduino_time_init() @export("arduino_time_init") {
    if (timer0_time_active) return;

    // Preserve COM0A/COM0B bits if PWM was already enabled, but make sure
    // Timer0 is in Arduino's Fast PWM mode and uses the /64 prescaler.
    reg_set(TCCR0A, WGM01_WGM00);
    reg_write(TCCR0B, (char)((reg_read(TCCR0B) & (char)0xF8) | CS00_CS01));
    reg_set(TIMSK0, TOIE0_BIT);
    asm("sei");
    timer0_time_active = true;
}

fn uint millis_impl() {
    arduino_time_init();

    char old_sreg = reg_read(SREG);
    asm("cli");
    uint m = @volatile_load(timer0_millis);
    reg_write(SREG, old_sreg);
    return m;
}

fn uint micros_impl() {
    arduino_time_init();

    char old_sreg = reg_read(SREG);
    asm("cli");
    uint m = @volatile_load(timer0_overflow_count);
    char t = reg_read(TCNT0);
    if ((reg_read(TIFR0) & TOV0_BIT) != 0 && t < 255) {
        m++;
    }
    reg_write(SREG, old_sreg);

    // 64 / clockCyclesPerMicrosecond() == 4 at 16 MHz.
    return ((m << 8) + (uint)t) * 4;
}

fn void delay_ms_impl(uint ms) {
    uint start = micros_impl();
    while (ms > 0) {
        while (ms > 0 && (micros_impl() - start) >= 1000) {
            ms--;
            start += 1000;
        }
    }
}

fn void delay_us_impl(uint us) {
    if (us <= 1) return;
    uint start = micros_impl();
    while ((micros_impl() - start) < us) {}
}

fn void timer0_ovf_impl() @export("timer0_ovf_impl") {
    uint m = @volatile_load(timer0_millis);
    char f = @volatile_load(timer0_fract);

    m += MILLIS_INC;
    f += FRACT_INC;
    if (f >= FRACT_MAX) {
        f -= FRACT_MAX;
        m += 1;
    }

    @volatile_store(timer0_fract, f);
    @volatile_store(timer0_millis, m);
    @volatile_store(timer0_overflow_count, (uint)(@volatile_load(timer0_overflow_count) + 1));
}

fn void __vector_16() @naked @export("__vector_16") {
    // C3 does not currently emit an AVR ISR prologue/epilogue for us.
    // Save the call-clobbered registers plus SREG, call the normal helper,
    // then restore everything and return with RETI, matching avr-libc ISR.
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
    asm("rcall timer0_ovf_impl");
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
