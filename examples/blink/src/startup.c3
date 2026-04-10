module startup;

import blink;

// __init is placed first in flash by the linker script.
// @naked suppresses LLVM's prologue/epilogue — essential because
// the stack pointer is invalid until we set it ourselves.
fn void __init() @naked @noreturn @export("__init") @section(".init") {
    // Set stack pointer to top of SRAM (RAMEND = 0x08FF)
    // SPH = I/O 0x3E, SPL = I/O 0x3D
    asm("ldi r28, 0xFF");
    asm("out 0x3d, r28");
    asm("ldi r29, 0x08");
    asm("out 0x3e, r29");

    // r1 must be zero (GCC/LLVM calling convention)
    asm("eor r1, r1");

    // Call the application
    blink::main();

    // Halt if main ever returns
    asm("rjmp .-2");
}
