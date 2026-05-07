module i2c_scanner;

import arduino::i2c;
import arduino::time;
import arduino::uart;

fn void print_hex_nibble(int n) {
    if (n < 10) {
        uart::write((char)('0' + n));
    } else {
        uart::write((char)('A' + (n - 10)));
    }
}

fn void print_hex_addr(int addr) {
    uart::print("0x");
    print_hex_nibble((addr >> 4) & 0x0F);
    print_hex_nibble(addr & 0x0F);
}

fn void main() @export("start") {
    uart::begin(9600);
    time::delay(1000);

    uart::write_line("=== I2C Scanner ===");

    int found = 0;
    for (int addr = 0x08; addr <= 0x77; addr++) {
        if (i2c::scan((char)addr)) {
            found++;
            uart::print("  device found at ");
            print_hex_addr(addr);
            uart::write_line("");
        }
        time::delay_ms(2);
    }

    if (found == 0) {
        uart::write_line("  no devices found");
    }

    uart::write_line("Done. Halting.");
    while (true) {}
}
