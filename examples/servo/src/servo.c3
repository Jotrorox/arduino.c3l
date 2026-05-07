module servo_example;

import arduino::driver::motor::servo;
import arduino::time;

fn void main() @export("start") {
    servo::attach(D9);

    while (true) {
        servo::write_angle(D9, 0);
        time::delay_ms(1000);
        servo::write_angle(D9, 90);
        time::delay_ms(1000);
        servo::write_angle(D9, 180);
        time::delay_ms(1000);
    }
}
