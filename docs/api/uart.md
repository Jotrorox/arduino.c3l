# UART

Module: `arduino::uart`

USART0 serial helpers.

## Functions

```c3
macro void begin(uint baud);
macro bool can_read();
macro char read();
macro usz read_buf(char[] buf);
macro usz read_buf_exact(char[] buf);
macro usz read_line(char[] buf);
macro print(x);
macro printn(x);
macro printf(fmt, args...);
macro printfn(fmt, args...);
```

`print`/`printn` support common scalar and string-like values. `printfn` appends CR+LF.

## Example

```c3
import arduino::uart;

uart::begin(9600);
uart::printn("hello");
```
