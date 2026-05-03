# AHT20 UART Example

Reads temperature and humidity from an AHT20 sensor over I2C and prints the values over UART at 9600 baud.

## Wiring

Connect the AHT20 to your Arduino (ATmega328P):

| AHT20 | Arduino |
|-------|---------|
| VIN   | 5V      |
| GND   | GND     |
| SCL   | A5      |
| SDA   | A4      |

## Build & Flash

```bash
cd examples/aht20-uart
./scripts/flash.sh
```
