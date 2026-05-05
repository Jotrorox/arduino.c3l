module arduino::adc @private;

import arduino::gpio;

// ADC registers (ATmega328P data-space addresses)
const uint ADMUX_REG  = 0x7C;   // Multiplexer selection + reference
const uint ADCSRA_REG = 0x7A;   // Control and status A
const uint ADCL_REG   = 0x78;   // Result low byte (must be read first)
const uint ADCH_REG   = 0x79;   // Result high byte
const uint ADCSRB_REG = 0x7B;   // Control and status B

// ADCSRA bits
const char ADEN = 0x80;   // ADC Enable             (bit 7)
const char ADSC = 0x40;   // ADC Start Conversion   (bit 6)
const char ADPS = 0x07;   // Prescaler mask 111 → /128 = 125 kHz @ 16 MHz

// ADMUX: REFS0=1 selects AVCC as voltage reference
const char AVCC_REF = 0x40;

bool initialized = false;

fn void reg_write(uint addr, char val) {
    @volatile_store(*(char*)(uptr)addr, val);
}

fn char reg_read(uint addr) {
    return @volatile_load(*(char*)(uptr)addr);
}

fn void arduino_adc_init() @export("arduino_adc_init") {
    if (initialized) return;
    reg_write(ADMUX_REG,  AVCC_REF);
    reg_write(ADCSRA_REG, (char)(ADEN | ADPS));
    reg_write(ADCSRB_REG, 0);
    initialized = true;
}

fn ushort analog_read_impl(AnalogPin pin) {
    arduino_adc_init();

    // AnalogPin values are ADC channels 0-5 directly.
    int channel = (int)pin;
    if (channel < 0 || channel > 5) return 0;

    // Select channel, keep AVCC reference
    reg_write(ADMUX_REG, (char)(AVCC_REF | (char)channel));

    // Start conversion
    char ctrl = reg_read(ADCSRA_REG);
    reg_write(ADCSRA_REG, (char)(ctrl | ADSC));

    // ADSC is cleared by hardware when conversion is complete
    while ((reg_read(ADCSRA_REG) & ADSC) != 0) {}

    // ADCL must be read before ADCH to latch the 10-bit result
    char lo = reg_read(ADCL_REG);
    char hi = reg_read(ADCH_REG);

    return (ushort)(((ushort)hi << 8) | (ushort)lo);
}

