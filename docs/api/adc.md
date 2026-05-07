# ADC

Module: `arduino::adc`

Uses `arduino::gpio::AnalogPin` for type-safe analog inputs.

## Functions

```c3
macro ushort analog_read(AnalogPin pin);
```

Returns a 10-bit value in the range `0..1023`.

## Example

```c3
import arduino::adc;
import arduino::gpio;

ushort value = adc::analog_read(A0);
```
