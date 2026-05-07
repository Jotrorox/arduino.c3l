# arduino.c3l

A small C3 library for Arduino/AVR projects, focused on ATmega328P boards such as the Arduino Uno.


## Features

- GPIO (`pin_mode`, `digital_write`, `digital_read`)
- Timing (`delay_ms`, `delay_us`, `millis`, `micros`)
- ADC (`analog_read`)
- PWM (`analog_write`)
- Servo motor driver (`servo::attach`, `servo::write_angle`, `servo::write_us`)
- UART, I2C, interrupts, SSD1306 OLED, and LCD1602 I2C display drivers
- Minimal AVR startup/runtime code

## Example

```c3
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
```

More examples are available in the `examples/` directory.

## Status

This project is minimal and experimental. APIs may change.


If there are at any time problems with this library, 
feel free to open an issue of if you need help with something feel free to message me,
either through discord(@jotrorox) or matrix(@jotrorox:matrix.org).

## License

Made in 2026 by Johannes (jotrorox) Müller and published under the MIT License.
