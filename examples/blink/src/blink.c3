module blink;

fn void main() {
    asm("sbi 0x04, 5");          // DDRB |= (1<<5) — PB5 as output

    while (true) {
        asm("sbi 0x05, 5");      // LED on
        for (int i = 0; i < 30000; i++) {}
        asm("cbi 0x05, 5");      // LED off
        for (int i = 0; i < 30000; i++) {}
    }
}
