#!/bin/bash
set -e

c3c build

avr-objcopy -O ihex -R .eeprom build/blink.elf blink.hex

avrdude -c arduino -p atmega328p -P /dev/ttyACM0 -b 115200 \
    -U flash:w:blink.hex