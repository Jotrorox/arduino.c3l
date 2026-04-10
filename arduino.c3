// Application must provide this symbol.
extern fn void start();

fn void __init() @naked @noreturn @export("__init") @section(".init") {
    // Set stack pointer
    asm("ldi r28, 0xFF");
    asm("out 0x3d, r28");
    asm("ldi r29, 0x08");
    asm("out 0x3e, r29");

    // ABI requirement
    asm("eor r1, r1");

    // TODO:
    // - copy .data from flash to SRAM
    // - zero .bss

    start();

    asm("rjmp .-2");
}
