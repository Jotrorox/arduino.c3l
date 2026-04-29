module ssd1306_i2c;

import arduino::time;
import arduino::i2c;
import arduino::driver::output::ssd1306;

fn void main() @export("start") {
    i2c::begin();

    // Initialise 128x64 OLED at I2C address 0x3C
    if (!ssd1306::init(0x3C, 64)) {
        while (true) {}
    }

    ssd1306::clear();
    ssd1306::draw_string(0, 0, "SSD1306 Demo");
    ssd1306::draw_hline(0, 10, 128);
    ssd1306::draw_string(0, 14, "Hello, World!");
    ssd1306::draw_rect(0, 28, 128, 36);
    ssd1306::fill_rect(2, 30, 124, 32);
    ssd1306::display();

    while (true) {
        time::delay(1000);
    }
}
