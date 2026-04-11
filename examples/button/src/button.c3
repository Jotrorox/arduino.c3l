module button;

import arduino::gpio;
import arduino::time;

fn void main() @export("start") {
    gpio::pin_mode(gpio::D13, gpio::OUTPUT);
    gpio::pin_mode(gpio::D2, gpio::INPUT_PULLUP);

    bool led = false;
    bool last_btn = true;

    while (true) {
        bool btn = gpio::digital_read(gpio::D2) == gpio::HIGH;

        if (!btn && last_btn) {
            led = !led;
            gpio::digital_write(gpio::D13, led ? gpio::HIGH : gpio::LOW);
        }

        last_btn = btn;
        time::delay_ms(20);
    }
}