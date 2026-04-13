module fade;

import arduino::pwm;
import arduino::gpio;
import arduino::time;

fn void main() @export("start") {
	int duty = 0;
	int dir  = 1;
	while (true) {
		pwm::analog_write(gpio::D5, (char) duty);
		duty += dir;
		if (duty == 255) dir = -1;
		if (duty == 0) dir = 1;
        time::delay(10);
    }
}