# SSD1306 I2C Example

Initialises an SSD1306 OLED display over I2C and draws text, lines and shapes.

## Wiring

Connect the SSD1306 to your Arduino (ATmega328P):

| SSD1306 | Arduino |
|---------|---------|
| VCC     | 5V      |
| GND     | GND     |
| SCL     | A5      |
| SDA     | A4      |

## Build & Flash

```bash
cd examples/ssd1306-i2c
./scripts/flash.sh
```

> Make sure `/dev/ttyACM0` matches your Arduino's serial port.

## Expected Output

The OLED display should show:
- "SSD1306 Demo" at the top
- A horizontal line
- "Hello, World!"
- A filled rectangle near the bottom
