module blink;

fn void main() @export("start") {
    asm("sbi 0x04, 5");

    while (true) {
        asm("sbi 0x05, 5");
        for (int i = 0; i < 80_000; i++) {}
        asm("cbi 0x05, 5");
        for (int i = 0; i < 80_000; i++) {}
    }
}