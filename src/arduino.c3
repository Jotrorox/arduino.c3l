module arduino;

extern fn void start();

extern char _sdata;
extern char _edata;
extern char _sbss;
extern char _ebss;
extern char _etext;

fn void abort() @export("abort") @noreturn {
    asm("rjmp .-2");
}

fn void __init() @naked @noreturn @export("__init") @section(".init") {
    asm("ldi r28, 0xFF");
    asm("out 0x3d, r28");
    asm("ldi r29, 0x08");
    asm("out 0x3e, r29");
    asm("eor r1, r1");

    // Copy .data from flash to SRAM
    char* src  = &_etext;
    char* dst  = &_sdata;
    char* dend = &_edata;
    while (dst < dend) {
        *dst = *src;
        dst++;
        src++;
    }

    // Zero .bss
    char* bss  = &_sbss;
    char* bend = &_ebss;
    while (bss < bend) {
        *bss = 0;
        bss++;
    }

    start();
    abort();
}