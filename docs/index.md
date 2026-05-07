# arduino.c3l

`arduino.c3l` is a small C3 library for Arduino/AVR projects, focused on ATmega328P boards such as the Arduino Uno.

::: warning Nightly C3 compiler required
This library currently requires a recent nightly C3 compiler.
:::

## What is included

- GPIO: configure pins and read/write digital values.
- Time: `delay_ms`, `delay_us`, `millis`, and `micros`.
- ADC: read analog inputs A0-A5.
- PWM: write 8-bit duty cycles on supported PWM pins.
- Servo: simple hobby servo control on D9/D10.
- UART: serial input/output helpers.
- I2C: master transmit/receive helpers.
- Interrupts: external interrupt attach/detach helpers.
- SSD1306: a small I2C OLED framebuffer driver.
- Minimal AVR startup/runtime support.

## Quick example

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

Start with [Getting Started](/guide/getting-started), then follow the [Blink Walkthrough](/guide/blink).
