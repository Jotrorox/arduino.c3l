module lcd1602_i2c;

import arduino::time;
import arduino::driver::output::lcd1602;

fn void main() @export("start") {
    // 16x2 LCD with PCF8574 I2C backpack at address 0x3F.
    if (!lcd1602::init(0x3F, 16, 2)) {
        while (true) {}
    }

    lcd1602::clear();
    lcd1602::set_cursor(0, 0);
    lcd1602::print("Hello from C3!");
    lcd1602::set_cursor(0, 1);
    lcd1602::print("LCD @ 0x3F");

    while (true) {
        time::delay_ms(1000);
    }
}
