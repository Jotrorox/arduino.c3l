# Blink Walkthrough

The blink example is the smallest useful `arduino.c3l` program. It configures the built-in LED pin as an output and toggles it once per second.

## Open the example

```sh
cd examples/blink
```

Important files:

```text
examples/blink/
├─ project.json
├─ scripts/flash.sh
└─ src/blink.c3
```

## Source code

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

## Explanation

### Module declaration

```c3
module blink;
```

Every C3 source file belongs to a module. The example uses its own `blink` module.

### Imports

```c3
import arduino::gpio;
import arduino::time;
```

`arduino::gpio` provides `pin_mode`, `digital_write`, pin aliases like `D13`, and constants like `OUTPUT`, `HIGH`, and `LOW`.

`arduino::time` provides blocking delay helpers such as `delay_ms`.

### Entry point

```c3
fn void main() @export("start") {
```

The AVR target is configured without the standard library entry point. Exporting `main` as `start` gives the minimal runtime a known symbol to call.

### Configure the LED pin

```c3
gpio::pin_mode(D13, OUTPUT);
```

On Arduino Uno style boards, `D13` is connected to the built-in LED.

### Toggle forever

```c3
while (true) {
    gpio::digital_write(D13, HIGH);
    time::delay_ms(1000);
    gpio::digital_write(D13, LOW);
    time::delay_ms(1000);
}
```

The loop turns the LED on, waits one second, turns it off, and waits another second.

## Build and flash

```sh
c3c build
./scripts/flash.sh
```

If flashing fails, check the serial port in `scripts/flash.sh` and see [Build & Flash](/guide/build-and-flash).
