# Time

Module: `arduino::time`

## Functions

```c3
macro uint millis();
macro uint micros();
macro void delay_us(uint us);
macro void delay_ms(uint ms);
macro void delay(uint ms);
```

`delay(ms)` is an alias for `delay_ms(ms)`.

## Example

```c3
import arduino::time;

time::delay_ms(1000);
uint now = time::millis();
```
