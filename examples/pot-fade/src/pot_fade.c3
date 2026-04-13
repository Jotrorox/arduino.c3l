module pot_fade;

import arduino::gpio;
import arduino::adc;
import arduino::pwm;
import arduino::time;

fn void main() @export("start") {
    while (true) {
        ushort raw = adc::analog_read(A0);
        char duty = (char)(raw >> 2);
        pwm::analog_write(D6, duty);

        time::delay(10);
    }
}

