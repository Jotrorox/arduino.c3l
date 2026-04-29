module arduino::driver::sensor::aht20 @private;

import arduino::i2c;
import arduino::time;

const char AHT20_ADDR = 0x38;

const char CMD_INIT    = 0xBE;
const char CMD_MEASURE = 0xAC;

fn bool init_impl() {
    i2c::begin_transmission(AHT20_ADDR);
    i2c::write_byte(0xBA);
    i2c::end_transmission();

    time::delay_ms(20);

    for (int i = 0; i < 100; i++) {
        if (i2c::request_from(AHT20_ADDR, 1) == 0) return false;
        char status = i2c::read_byte();
        if ((status & 0x80) == 0) break;
        time::delay_ms(10);
    }

    i2c::begin_transmission(AHT20_ADDR);
    i2c::write_byte(CMD_INIT);
    i2c::write_byte(0x08);
    i2c::write_byte(0x00);
    if (i2c::end_transmission() != 0) return false;

    for (int i = 0; i < 100; i++) {
        if (i2c::request_from(AHT20_ADDR, 1) == 0) return false;
        char status = i2c::read_byte();
        if ((status & 0x80) == 0) {
            return (status & 0x08) != 0;
        }
        time::delay_ms(10);
    }
    return false;
}

fn Reading read_impl() {
    i2c::begin_transmission(AHT20_ADDR);
    i2c::write_byte(CMD_MEASURE);
    i2c::write_byte(0x33);
    i2c::write_byte(0x00);
    if (i2c::end_transmission() != 0) {
        return { .valid = 0 };
    }

    for (int i = 0; i < 100; i++) {
        if (i2c::request_from(AHT20_ADDR, 1) == 0) return { .valid = 0 };
        char status = i2c::read_byte();
        if ((status & 0x80) == 0) break;
        time::delay_ms(10);
    }

    if (i2c::request_from(AHT20_ADDR, 6) != 6) {
        return { .valid = 0 };
    }

    char status = i2c::read_byte();
    char hum_h = i2c::read_byte();
    char hum_m = i2c::read_byte();
    char hum_l_temp_h = i2c::read_byte();
    char temp_m = i2c::read_byte();
    char temp_l = i2c::read_byte();

    uint hum  = ((uint)hum_h << 12) | ((uint)hum_m << 4) | ((uint)hum_l_temp_h >> 4);
    uint temp = ((uint)hum_l_temp_h & 0x0F) << 16 | ((uint)temp_m << 8) | (uint)temp_l;

    int humidity    = (int)((hum * 100U) / 1024 / 1024 * 100);
    int temperature = (int)((temp * 200U) / 1024 / 1024 * 100) - 5000;

    return {
        .temperature = temperature,
        .humidity    = humidity,
        .valid       = 1
    };
}
