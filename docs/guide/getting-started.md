# Getting Started

This guide gets you from an empty checkout to building the included blink example for an ATmega328P/Arduino Uno style board.

## Current compiler requirement

::: warning Nightly C3 compiler required
`arduino.c3l` currently needs a recent **nightly** C3 compiler. Stable releases do not
yet have AVR support built in. So please go to the releases and select the nightly/pre-release.
:::

Install or update to the latest nightly C3 compiler and make sure `c3c` is on your `PATH`:

```sh
c3c --version
```

You also need AVR upload tooling if you want to flash a board:

- `avrdude`
- an Arduino Uno / ATmega328P compatible board
- a USB serial port such as `/dev/ttyACM0` or `/dev/ttyUSB0`

## Clone the project

```sh
git clone https://github.com/jotrorox/arduino.c3l.git
cd arduino.c3l
```

## Build the blink example

The examples are standalone C3 projects. Start with `examples/blink`:

```sh
cd examples/blink
c3c build
```

The blink example project declares the important AVR settings in `project.json`:

```json
{
  "dependencies": ["arduino"],
  "cpu": "atmega328p",
  "targets": {
    "blink": {
      "target": "elf-avr",
      "use-stdlib": false,
      "link-libc": false,
      "no-entry": true
    }
  }
}
```

The output ELF is written to:

```text
examples/blink/build/blink.elf
```

## Flash the board

Connect the board and check the serial device. The included helper defaults to `/dev/ttyACM0`:

```sh
./scripts/flash.sh
```

If your board appears on another port, edit `examples/blink/scripts/flash.sh` and change `-P /dev/ttyACM0` to the correct device.

## What to read next

- [Blink Walkthrough](/guide/blink) explains the code line by line.
- [Build & Flash](/guide/build-and-flash) covers the build files and uploader in more detail.
- [GPIO](/api/gpio) and [Time](/api/time) document the APIs used by blink.
