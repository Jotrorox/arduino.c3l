# GPIO

Module: `arduino::gpio`

## Constants

### `PinMode`

- `OUTPUT`
- `INPUT`
- `INPUT_PULLUP`

### `PinState`

- `HIGH`
- `LOW`

### `Pin`

Digital aliases: `D0` through `D13`.

Analog header aliases as digital pins: `A0` through `A5`.

### `AnalogPin`

ADC-safe aliases: `A0` through `A5` mapped to analog channels `0` through `5`.

## Functions

```c3
macro void pin_mode(Pin pin, PinMode mode);
macro void digital_write(Pin pin, PinState value);
macro PinState digital_read(Pin pin);
```

## Example

```c3
import arduino::gpio;

gpio::pin_mode(D13, OUTPUT);
gpio::digital_write(D13, HIGH);
```
