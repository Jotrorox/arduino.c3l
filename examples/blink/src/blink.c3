module blink;

import arduino::gpio;
import arduino::time;

fn void main() @export("start") {
    gpio::pin_mode(D13, OUTPUT);

    while (true) {
        gpio::digital_write(D13, HIGH);
        time::delay_ms(1000);
        gpio::digital_write(D13, LOW);
        time::delay_ms(1000);
    }
}