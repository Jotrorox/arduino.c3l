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
=== DHT11 Sensor ===
Temp: 23.00 C, Hum: 45.00 %RH
Temp: 23.00 C, Hum: 45.00 %RH
...
```
