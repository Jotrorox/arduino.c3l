module i2c_scanner;

import arduino::time;
import arduino::uart;
import arduino::i2c;

fn void print_hex(char b) {
    char[] hex = "0123456789ABCDEF";
    uart::write(hex[(b >> 4) & 0x0F]);
    uart::write(hex[b & 0x0F]);
}

fn void println(char[] msg) {
    uart::write_line(msg);
}

fn void main() @export("start") {
    uart::begin(9600);
    time::delay(1000);

    i2c::begin();

    println("=== I2C Scanner ===");

    int found = 0;
    for (int addr = 1; addr <= 127; addr++) {
        if (i2c::scan((char)addr)) {
            found++;
            uart::write_string("  device at 0x");
            print_hex((char)addr);
            uart::write_crlf();
        }
    }

    if (found == 0) {
        println("  no devices found");
    }

    println("Done. Halting.");
    while (true) {}
}
