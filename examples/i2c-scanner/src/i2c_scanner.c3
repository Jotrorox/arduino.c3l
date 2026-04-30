module i2c_scanner;

import arduino::time;
import arduino::uart;
import arduino::i2c;

fn void main() @export("start") {
    uart::begin(9600);
    time::delay(1000);

    i2c::begin();

    uart::printfn("=== I2C Scanner ===");

    int found = 0;
    for (int addr = 1; addr <= 127; addr++) {
        if (i2c::scan((char)addr)) {
            found++;
            uart::printfn("  device at 0x%02X", addr);
        }
    }

    if (found == 0) {
        uart::printfn("  no devices found");
    }

    uart::printfn("Done. Halting.");
    while (true) {}
}
