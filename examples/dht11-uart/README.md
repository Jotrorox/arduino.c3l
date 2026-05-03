# DHT11 UART Example

Reads temperature and humidity from a DHT11 sensor and prints the values over UART at 9600 baud.

## Wiring

Connect the DHT11 to your Arduino (ATmega328P):

| DHT11 | Arduino |
|-------|---------|
| VCC   | 5V      |
| GND   | GND     |
| DATA  | D2      |

> Some DHT11 modules have a built-in pull-up resistor. If yours does not, add a 4.7kΩ–10kΩ pull-up resistor between DATA and VCC.

## Build & Flash

```bash
cd examples/dht11-uart
./scripts/flash.sh
```
