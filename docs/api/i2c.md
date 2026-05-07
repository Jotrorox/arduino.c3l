# I2C

Module: `arduino::i2c`

I2C/TWI master helpers for 7-bit slave addresses.

## Functions

```c3
macro void begin_transmission(char addr);
macro void write_byte(char b);
macro void write_bytes(char[] data);
macro char end_transmission();
macro char request_from(char addr, char quantity);
macro char available();
macro char read_byte();
macro bool scan(char addr);
```

`end_transmission()` returns `0` on success, `2` on address NACK, and `3` on data NACK.

## Example

```c3
import arduino::i2c;

if (i2c::scan(0x3C)) {
    // device found
}
```
