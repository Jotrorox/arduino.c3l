# I2C Scanner Example

Scans the I2C bus for all devices in the 7-bit address range (1-127) and prints the results over UART at 9600 baud.

## Build & Flash

```bash
cd examples/i2c-scanner
./scripts/flash.sh
```

> Make sure `/dev/ttyACM0` matches your Arduino's serial port.

## Read Output

```bash
python3 scripts/read_serial.py
```

Requires **pyserial**:
```bash
pip install pyserial
```

## Expected Output

```
=== I2C Scanner ===
  device at 0x38
  device at 0x76
  total: 2 device(s)
Done. Halting.
```
