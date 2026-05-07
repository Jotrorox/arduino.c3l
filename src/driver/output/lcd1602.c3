module arduino::driver::output::lcd1602 @private;

import arduino::i2c;
import arduino::time;

// PCF8574 backpack wiring used by most 1602 I2C modules:
// P0=RS, P1=RW, P2=E, P3=backlight, P4..P7=LCD D4..D7.
const char LCD_RS = 0x01;
const char LCD_EN = 0x04;
const char LCD_BACKLIGHT = 0x08;

const char LCD_CLEARDISPLAY = 0x01;
const char LCD_RETURNHOME = 0x02;
const char LCD_ENTRYMODESET = 0x04;
const char LCD_DISPLAYCONTROL = 0x08;
const char LCD_FUNCTIONSET = 0x20;
const char LCD_SETDDRAMADDR = 0x80;

const char LCD_ENTRYLEFT = 0x02;
const char LCD_DISPLAYON = 0x04;
const char LCD_2LINE = 0x08;

char device_addr = 0x3F;
char display_cols = 16;
char display_rows = 2;
char backlight_mask = LCD_BACKLIGHT;
char display_control = LCD_DISPLAYON;

fn bool write_expander(char value) {
    i2c::begin_transmission(device_addr);
    i2c::write_byte((char)(value | backlight_mask));
    return i2c::end_transmission() == 0;
}

fn void pulse_enable(char value) {
    write_expander((char)(value | LCD_EN));
    time::delay_us(1);
    write_expander((char)(value & (char)~LCD_EN));
    time::delay_us(50);
}

fn void write4(char nibble, char mode) {
    char value = (char)((nibble & 0xF0) | mode);
    write_expander(value);
    pulse_enable(value);
}

fn void send(char value, char mode) {
    write4((char)(value & 0xF0), mode);
    write4((char)((value << 4) & 0xF0), mode);
}

fn void command(char value) {
    send(value, 0);
}

fn bool init_impl(char addr, char cols, char rows) {
    device_addr = addr;
    display_cols = cols;
    display_rows = rows;
    backlight_mask = LCD_BACKLIGHT;
    display_control = LCD_DISPLAYON;

    // Let the LCD controller finish power-up before the 4-bit reset sequence.
    time::delay_ms(50);
    if (!write_expander(0)) return false;

    write4(0x30, 0);
    time::delay_ms(5);
    write4(0x30, 0);
    time::delay_us(150);
    write4(0x30, 0);
    write4(0x20, 0); // 4-bit mode

    command((char)(LCD_FUNCTIONSET | LCD_2LINE));
    display_impl(true);
    clear_impl();
    command((char)(LCD_ENTRYMODESET | LCD_ENTRYLEFT));
    home_impl();
    return true;
}

fn void clear_impl() {
    command(LCD_CLEARDISPLAY);
    time::delay_ms(2);
}

fn void home_impl() {
    command(LCD_RETURNHOME);
    time::delay_ms(2);
}

fn void set_cursor_impl(char col, char row) {
    if (row >= display_rows) row = (char)(display_rows - 1);
    if (col >= display_cols) col = (char)(display_cols - 1);

    char row_offset = 0;
    if (row == 1) {
        row_offset = 0x40;
    } else if (row == 2) {
        row_offset = 0x14;
    } else if (row == 3) {
        row_offset = 0x54;
    }

    command((char)(LCD_SETDDRAMADDR | (col + row_offset)));
}

fn void write_char_impl(char c) {
    send(c, LCD_RS);
}

fn void print_impl(char[] s) {
    for (usz i = 0; i < s.len; i++) {
        write_char_impl(s[i]);
    }
}

fn void backlight_impl(bool enabled) {
    backlight_mask = enabled ? LCD_BACKLIGHT : 0;
    write_expander(0);
}

fn void display_impl(bool enabled) {
    display_control = enabled ? LCD_DISPLAYON : 0;
    command((char)(LCD_DISPLAYCONTROL | display_control));
}
