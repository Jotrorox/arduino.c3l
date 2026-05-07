# Servo

Module: `arduino::driver::motor::servo`

Minimal hobby servo driver for ATmega328P / Arduino Uno.

::: warning Timer1 is used
The servo driver uses Timer1, so normal PWM on `D9` and `D10` is taken over while servos are attached.
:::

## Pins

Supported servo pins:

- `D9`
- `D10`

## Constants

- `MIN_PULSE_US = 544`
- `MAX_PULSE_US = 2400`
- `DEFAULT_PULSE_US = 1500`

## Functions

```c3
macro void attach(ServoPin pin);
macro void detach(ServoPin pin);
macro void write_angle(ServoPin pin, int angle);
macro void write_us(ServoPin pin, ushort pulse_us);
```

### `attach`

Enables servo output on the pin and moves it to the default center pulse, `1500 us`.

### `detach`

Stops driving the servo pin.

### `write_angle`

Moves a servo using an angle in degrees. Values are clamped to `0..180`.

### `write_us`

Moves a servo using a pulse width in microseconds. Values are clamped to `544..2400`.

## Example

```c3
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
```
