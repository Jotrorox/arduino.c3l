# Build & Flash

This page explains how the example projects are built and uploaded.

::: warning Nightly C3 compiler required
Use a recent nightly `c3c`. The current library and examples target AVR and may not build correctly with stable C3 releases.
:::

## Build an example

Use blink as the first test:

```sh
cd examples/blink
c3c build
```

The build uses `examples/blink/project.json`. The important settings are:

- `dependencies: ["arduino"]` — imports this library.
- `dependency-search-paths: ["../../.."]` — lets the example find the library from inside `examples/blink`.
- `cpu: "atmega328p"` — selects the target MCU.
- `target: "elf-avr"` — builds an AVR ELF file.
- `use-stdlib: false` and `link-libc: false` — keeps the binary freestanding.
- `no-entry: true` — uses the exported `start` symbol instead of a hosted entry point.

Output:

```text
build/blink.elf
```

## Flash with the helper script

```sh
./scripts/flash.sh
```

The script runs `c3c build` and then uploads with `avrdude`:

```sh
avrdude -c arduino -p atmega328p -P /dev/ttyACM0 -b 115200 \
    -U flash:w:build/blink.elf:e
```

## Change the serial port

If your board is not on `/dev/ttyACM0`, edit `scripts/flash.sh`.

Common Linux device names:

- `/dev/ttyACM0`
- `/dev/ttyUSB0`

You can often find the device with:

```sh
ls /dev/ttyACM* /dev/ttyUSB*
```

## Permissions

On Linux, your user may need access to the serial device. Depending on your distribution, adding the user to `dialout`, `uucp`, or a similar group may be required.

## Troubleshooting

- Confirm that `c3c --version` reports a nightly build.
- Confirm the board is an ATmega328P-compatible Arduino Uno style board.
- Check the serial port in `scripts/flash.sh`.
- Make sure no serial monitor is currently using the port.
