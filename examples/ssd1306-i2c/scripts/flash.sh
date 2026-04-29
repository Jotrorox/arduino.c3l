#!/bin/bash
set -e

c3c build

avrdude -c arduino -p atmega328p -P /dev/ttyACM0 -b 115200 \
    -U flash:w:build/ssd1306-i2c.elf:e
