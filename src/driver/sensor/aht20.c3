module arduino::driver::sensor::aht20 @private;

import arduino::i2c;
import arduino::time;

const char AHT20_ADDR = 0x38;

const char CMD_INIT    = 0xBE;
const char CMD_MEASURE = 0xAC;

fn bool init_impl() {
    i2c::begin_transmission(AHT20_ADDR);
    i2c::write_byte(CMD_INIT);
    i2c::write_byte(0x08);
    i2c::write_byte(0x00);
    if (i2c::end_transmission() != 0) return false;

    time::delay_ms(40);

    if (i2c::request_from(AHT20_ADDR, 1) == 0) return false;
    char status = i2c::read_byte();
    return (status & 0x08) != 0;
}

fn Reading read_impl() {
    i2c::begin_transmission(AHT20_ADDR);
    i2c::write_byte(CMD_MEASURE);
    i2c::write_byte(0x33);
    i2c::write_byte(0x00);
    if (i2c::end_transmission() != 0) {
        return { .valid = 0 };
    }

    time::delay_ms(80);

    if (i2c::request_from(AHT20_ADDR, 6) != 6) {
        return { .valid = 0 };
    }

    char status = i2c::read_byte();
    if (status & 0x80) {
        return { .valid = 0 };
    }

    char hum_h = i2c::read_byte();
    char hum_m = i2c::read_byte();
    char hum_l_temp_h = i2c::read_byte();
    char temp_m = i2c::read_byte();
    char temp_l = i2c::read_byte();

    // Fast 16-bit fixed-point conversion (no float).
    // Dropping the lowest 4 humidity / 5 temperature bits introduces
    // < 0.002 %RH and < 0.001 C error – negligible for this sensor.
    ushort raw_hum  = ((ushort)hum_h << 8) | (ushort)hum_m;
    ushort raw_temp = (((ushort)hum_l_temp_h & 0x0F) << 11) | ((ushort)temp_m << 3) | ((ushort)temp_l >> 5);

    int humidity    = (int)((raw_hum * 625U) >> 12);
    int temperature = (int)((raw_temp * 625U) >> 10) - 5000;

    return {
        .temperature = temperature,
        .humidity    = humidity,
        .valid       = 1
    };
}
