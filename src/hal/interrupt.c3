module arduino::interrupt @private;

// ATmega328P external interrupt registers, data-space addresses.
const uint EIFR  = 0x3C; // flag register, write 1 to clear INTFx
const uint EIMSK = 0x3D; // mask register, INT0 bit 0, INT1 bit 1
const uint EICRA = 0x69; // sense control: ISC00/01 and ISC10/11

InterruptHandler int0_handler;
InterruptHandler int1_handler;

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

fn void interrupts_impl() {
    asm("sei");
}

fn void no_interrupts_impl() {
    asm("cli");
}

fn void attach_interrupt_impl(ExternalInterrupt interrupt, InterruptMode mode, InterruptHandler handler) {
    char line = (char)interrupt;
    if (line > 1) return;

    no_interrupts_impl();

    char shift = (char)(line * 2);
    char mask = (char)(0x03 << shift);
    char value = (char)((char)mode << shift);
    reg_write(EICRA, (char)((reg_read(EICRA) & (char)~mask) | value));

    if (line == 0) {
        int0_handler = handler;
    } else {
        int1_handler = handler;
    }

    reg_write(EIFR, (char)(1 << line)); // clear pending flag before enabling
    reg_set(EIMSK, (char)(1 << line));

    interrupts_impl();
}

fn void detach_interrupt_impl(ExternalInterrupt interrupt) {
    char line = (char)interrupt;
    if (line > 1) return;
    reg_clr(EIMSK, (char)(1 << line));
    if (line == 0) {
        int0_handler = null;
    } else {
        int1_handler = null;
    }
}

fn void __vector_1() @export("__vector_1") {
    if (int0_handler != null) int0_handler();
    asm("reti");
}

fn void __vector_2() @export("__vector_2") {
    if (int1_handler != null) int1_handler();
    asm("reti");
}
