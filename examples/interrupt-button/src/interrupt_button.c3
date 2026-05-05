module interrupt_button;

import arduino::gpio;
import arduino::interrupt;

bool led = false;
int counter = 0;

fn void on_button_falling() {
    led = !led;
    gpio::digital_write(D13, led ? HIGH : LOW);
}

fn void main() @export("start") {
    gpio::pin_mode(D13, OUTPUT);
    gpio::pin_mode(D2, INPUT_PULLUP);

    interrupt::attach_interrupt(INT0, FALLING, &on_button_falling);

    while (true) {
	}
}
