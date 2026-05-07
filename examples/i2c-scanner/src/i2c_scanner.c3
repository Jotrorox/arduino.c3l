module i2c_scanner;

import arduino::i2c;
import arduino::time;
import arduino::uart;

fn void print_hex_nibble(int n) {
    if (n < 10) {
        uart::print((char)('0' + n));
    } else {
        uart::print((char)('A' + (n - 10)));
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

    while (true) {
		uart::printn("Scanning I2C bus...");

    	int found = 0;
    	for (int addr = 0x08; addr <= 0x77; addr++) {
    	    if (i2c::scan((char)addr)) {
    	        found++;
    	        uart::print("  device found at ");
    	        print_hex_addr(addr);
    	        uart::printn("");
    	    }
    	    time::delay_ms(2);
    	}

    	if (found == 0) {
    	    uart::printn("  no devices found");
    	}

    	uart::printn("Done. Halting.");
		time::delay(1000);
	}
}
