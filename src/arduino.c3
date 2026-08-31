module arduino;

extern fn void start();
extern fn void arduino_time_init();

extern char _sdata;
extern char _edata;
extern char _sbss;
extern char _ebss;
extern char _etext;

fn void __bad_interrupt() @export("__bad_interrupt") @noreturn {
    abort();
}

fn void __vectors() @naked @export("__vectors") @section(".vectors") {
    // ATmega328P vectors are 2 words wide. Use rjmp+nop to match JMP-sized slots.
    asm("rjmp __init");
    asm("nop");
    asm("rjmp __vector_1");
    asm("nop");
    asm("rjmp __vector_2");
    asm("nop");
    asm("rjmp __bad_interrupt");
    asm("nop");
    asm("rjmp __bad_interrupt");
    asm("nop");
    asm("rjmp __bad_interrupt");
    asm("nop");
    asm("rjmp __bad_interrupt");
    asm("nop");
    asm("rjmp __bad_interrupt");
    asm("nop");
    asm("rjmp __bad_interrupt");
    asm("nop");
    asm("rjmp __bad_interrupt");
    asm("nop");
    asm("rjmp __bad_interrupt");
    asm("nop");
    asm("rjmp __bad_interrupt");
    asm("nop");
    asm("rjmp __bad_interrupt");
    asm("nop");
    asm("rjmp __bad_interrupt");
    asm("nop");
    asm("rjmp __bad_interrupt");
    asm("nop");
    asm("rjmp __bad_interrupt");
    asm("nop");
    asm("rjmp __vector_16");
    asm("nop");
    asm("rjmp __bad_interrupt");
    asm("nop");
    asm("rjmp __bad_interrupt");
    asm("nop");
    asm("rjmp __bad_interrupt");
    asm("nop");
    asm("rjmp __bad_interrupt");
    asm("nop");
    asm("rjmp __bad_interrupt");
    asm("nop");
    asm("rjmp __bad_interrupt");
    asm("nop");
    asm("rjmp __bad_interrupt");
    asm("nop");
    asm("rjmp __bad_interrupt");
    asm("nop");
    asm("rjmp __bad_interrupt");
    asm("nop");
}

fn void abort() @export("abort") @noreturn {
    asm("rjmp .-2");
}

fn void arduino_init() {
    arduino_time_init();
}

fn void __init() @naked @noreturn @export("__init") @section(".init") {
    asm("ldi r28, 0xFF");
    asm("out 0x3d, r28");
    asm("ldi r29, 0x08");
    asm("out 0x3e, r29");
    asm("eor r1, r1");

    // Copy .data from flash to SRAM.
    // The C3 compiler generates data-space load for *src, but _etext
    // is a flash address. We must use LPM instead.
    asm("ldi r26, lo8(_sdata)");
    asm("ldi r27, hi8(_sdata)");
    asm("ldi r30, lo8(_etext)");
    asm("ldi r31, hi8(_etext)");
    asm("ldi r25, hi8(_edata)");
    asm("rjmp 2f");
    asm("1:");
    asm("lpm");
    asm("adiw r30, 1");
    asm("st X+, r0");
    asm("2:");
    asm("cpi r26, lo8(_edata)");
    asm("cpc r27, r25");
    asm("brne 1b");

    // Zero .bss without C locals. This function is naked, so it has no stack
    // frame; unoptimized C code would otherwise spill these pointers above
    // RAMEND and leave globals (including the Timer0 counters) uninitialized.
    asm("ldi r26, lo8(_sbss)");
    asm("ldi r27, hi8(_sbss)");
    asm("ldi r24, lo8(_ebss)");
    asm("ldi r25, hi8(_ebss)");
    asm("rjmp 2f");
    asm("1:");
    asm("st X+, r1");
    asm("2:");
    asm("cp r26, r24");
    asm("cpc r27, r25");
    asm("brne 1b");

    // Keep startup calls local enough for AVR RCALL by calling the small init
    // routines directly. Calling arduino_init() itself can be out of range in
    // larger programs.
    arduino_time_init();
    start();
    abort();
}
