module arduino::time @private;

const uint TCCR1A = 0x80;  // control A:  waveform mode bits
const uint TCCR1B = 0x81;  // control B:  prescaler + waveform mode bits
const uint TCNT1L = 0x84;  // counter low  byte
const uint TCNT1H = 0x85;  // counter high byte
const uint OCR1AL = 0x88;  // compare A low  byte
const uint OCR1AH = 0x89;  // compare A high byte
const uint TIFR1  = 0x36;  // interrupt flags

// TIFR1 bit 1 = OCF1A (output compare A match flag).
// Writing a 1 to it CLEARS it (hardware behaviour).
const char OCF1A_BIT = 0x02;

// TCCR1B mode + prescaler constants:
//   WGM12 = bit 3 → CTC mode (count to OCR1A then reset)
//   CS1   = bits [2:0]
//     001 → prescaler 1   (16 MHz     → 62.5 ns/tick)
//     011 → prescaler 64  (250 kHz    → 4 µs/tick)
const char CTC_PS1  = 0x09;  // CTC + prescaler 1
const char CTC_PS64 = 0x0B;  // CTC + prescaler 64
const char STOP     = 0x00;  // timer stopped

fn void reg_write(uint addr, char val) {
    @volatile_store(*(char*)(uptr)addr, val);
}

fn char reg_read(uint addr) {
    return @volatile_load(*(char*)(uptr)addr);
}

// Wait for one CTC compare-match cycle.
// OCR1A must be set before calling.
fn void t1_wait(char mode) {
    reg_write(TCNT1H, 0);
    reg_write(TCNT1L, 0);
    reg_write(TIFR1, OCF1A_BIT);
    reg_write(TCCR1B, mode);
    while ((reg_read(TIFR1) & OCF1A_BIT) == 0) {}
    reg_write(TCCR1B, STOP);
}

// delay_us:
//   prescaler 1 → 16 ticks per µs
//   OCR1A = 16*us - 1
//   accurate for us >= 4 (setup overhead ≈ 3 µs)
fn void delay_us_impl(uint us) {
    if (us == 0) return;
    uint ticks = us * 16 - 1;
    reg_write(TCCR1A, 0x00);
    reg_write(OCR1AH, (char)(ticks >> 8));
    reg_write(OCR1AL, (char)(ticks & 0xFF));
    t1_wait(CTC_PS1);
}

// delay_ms: prescaler 64 → 4 µs per tick → 250 ticks per ms → OCR1A = 249
fn void delay_ms_impl(uint ms) {
    reg_write(TCCR1A, 0x00);
    reg_write(OCR1AH, 0x00);
    reg_write(OCR1AL, 249);
    for (uint i = 0; i < ms; i++) {
        t1_wait(CTC_PS64);
    }
}
