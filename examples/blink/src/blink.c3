module blink;

import arduino::gpio;
import arduino::time;

fn void main() @export("start") {
    gpio::pin_mode(gpio::D13, gpio::OUTPUT);
    while (true) {
        gpio::digital_write(gpio::D13, gpio::HIGH);
        time::delay(500);
        gpio::digital_write(gpio::D13, gpio::LOW);
        time::delay(500);
    }
}