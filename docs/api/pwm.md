# PWM

Module: `arduino::pwm`

## Constants

Supported PWM pins on ATmega328P / Arduino Uno:

- `D3`
- `D5`
- `D6`
- `D9`
- `D10`
- `D11`

Duty constants:

- `MIN_DUTY = 0x00`
- `MAX_DUTY = 0xFF`

## Functions

```c3
macro void analog_write(PWMPin pin, char duty);
```

`duty` is an 8-bit value from `0` to `255`.

## Example

```c3
import arduino::pwm;

pwm::analog_write(D9, 128);
```
