module button;

import arduino::gpio;
import arduino::time;

fn void main() @export("start") {
    gpio::pin_mode(D13, OUTPUT);
    gpio::pin_mode(D2, INPUT_PULLUP);

    bool led = false;
    bool last_btn = true;

    while (true) {
        bool btn = gpio::digital_read(D2) == HIGH;

        if (!btn && last_btn) {
            led = !led;
            gpio::digital_write(D13, led ? HIGH : LOW);
        }

        last_btn = btn;
        time::delay_ms(20);
    }
}