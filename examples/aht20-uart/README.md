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

> Make sure `/dev/ttyACM0` matches your Arduino's serial port.

## Read Output

```bash
python3 -m serial.tools.miniterm /dev/ttyACM0 9600
```

Requires **pyserial**:
```bash
pip install pyserial
```

## Expected Output

```
=== AHT20 Sensor ===
AHT20 ready.
Temp: 23.50 C, Hum: 45.67 %RH
Temp: 23.52 C, Hum: 45.65 %RH
...
```
