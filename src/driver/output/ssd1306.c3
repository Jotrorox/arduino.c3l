module arduino::driver::output::ssd1306 @private;

import arduino::i2c;
import arduino::time;

const char SSD1306_CMD       = 0x00;
const char SSD1306_DATA      = 0x40;
const char SSD1306_DISPLAYOFF         = 0xAE;
const char SSD1306_SETDISPLAYCLOCKDIV = 0xD5;
const char SSD1306_SETMULTIPLEX       = 0xA8;
const char SSD1306_SETDISPLAYOFFSET   = 0xD3;
const char SSD1306_SETSTARTLINE       = 0x40;
const char SSD1306_CHARGEPUMP         = 0x8D;
const char SSD1306_MEMORYMODE         = 0x20;
const char SSD1306_SEGREMAP           = 0xA1;
const char SSD1306_COMSCANDEC         = 0xC8;
const char SSD1306_SETCOMPINS         = 0xDA;
const char SSD1306_SETCONTRAST        = 0x81;
const char SSD1306_SETPRECHARGE       = 0xD9;
const char SSD1306_SETVCOMDETECT      = 0xDB;
const char SSD1306_DISPLAYALLON_RESUME= 0xA4;
const char SSD1306_NORMALDISPLAY      = 0xA6;
const char SSD1306_INVERTDISPLAY      = 0xA7;
const char SSD1306_DISPLAYON          = 0xAF;
const char SSD1306_COLUMNADDR         = 0x21;
const char SSD1306_PAGEADDR           = 0x22;

const char OLED_WIDTH = 128;
const char OLED_MAX_HEIGHT = 64;
const char OLED_PAGE_HEIGHT = 8;
const int OLED_MAX_PAGES = (int)OLED_MAX_HEIGHT / (int)OLED_PAGE_HEIGHT;
const int OLED_FRAMEBUFFER_BYTES = (int)OLED_WIDTH * OLED_MAX_PAGES;
const char I2C_TX_BUF_SIZE = 16;
const char OLED_DATA_CHUNK = I2C_TX_BUF_SIZE - 1;

char device_addr;
char display_width  = OLED_WIDTH;
char display_height = OLED_MAX_HEIGHT;
int cursor_x = 0;
int cursor_y = 0;
int text_scale = 1;

char[OLED_FRAMEBUFFER_BYTES] framebuffer_bits;

const char FONT_CHARS   = 96;
const char FONT_WIDTH   = 5;
const char FONT_HEIGHT  = 7;
const int FONT_BYTES = (int)FONT_CHARS * (int)FONT_WIDTH;

const char[FONT_BYTES] FONT5X7 @export("ssd1306_font5x7") @section(".text") = {
    0x00, 0x00, 0x00, 0x00, 0x00, // space
    0x00, 0x00, 0x5F, 0x00, 0x00, // !
    0x00, 0x07, 0x00, 0x07, 0x00, // "
    0x14, 0x7F, 0x14, 0x7F, 0x14, // #
    0x24, 0x2A, 0x7F, 0x2A, 0x12, // $
    0x23, 0x13, 0x08, 0x64, 0x62, // %
    0x36, 0x49, 0x55, 0x22, 0x50, // &
    0x00, 0x05, 0x03, 0x00, 0x00, // '
    0x00, 0x1C, 0x22, 0x41, 0x00, // (
    0x00, 0x41, 0x22, 0x1C, 0x00, // )
    0x08, 0x2A, 0x1C, 0x2A, 0x08, // *
    0x08, 0x08, 0x3E, 0x08, 0x08, // +
    0x00, 0x50, 0x30, 0x00, 0x00, // ,
    0x08, 0x08, 0x08, 0x08, 0x08, // -
    0x00, 0x60, 0x60, 0x00, 0x00, // .
    0x20, 0x10, 0x08, 0x04, 0x02, // /
    0x3E, 0x51, 0x49, 0x45, 0x3E, // 0
    0x00, 0x42, 0x7F, 0x40, 0x00, // 1
    0x42, 0x61, 0x51, 0x49, 0x46, // 2
    0x21, 0x41, 0x45, 0x4B, 0x31, // 3
    0x18, 0x14, 0x12, 0x7F, 0x10, // 4
    0x27, 0x45, 0x45, 0x45, 0x39, // 5
    0x3C, 0x4A, 0x49, 0x49, 0x30, // 6
    0x01, 0x71, 0x09, 0x05, 0x03, // 7
    0x36, 0x49, 0x49, 0x49, 0x36, // 8
    0x06, 0x49, 0x49, 0x29, 0x1E, // 9
    0x00, 0x36, 0x36, 0x00, 0x00, // :
    0x00, 0x56, 0x36, 0x00, 0x00, // ;
    0x00, 0x08, 0x14, 0x22, 0x41, // <
    0x14, 0x14, 0x14, 0x14, 0x14, // =
    0x41, 0x22, 0x14, 0x08, 0x00, // >
    0x02, 0x01, 0x51, 0x09, 0x06, // ?
    0x32, 0x49, 0x79, 0x41, 0x3E, // @
    0x7E, 0x11, 0x11, 0x11, 0x7E, // A
    0x7F, 0x49, 0x49, 0x49, 0x36, // B
    0x3E, 0x41, 0x41, 0x41, 0x22, // C
    0x7F, 0x41, 0x41, 0x22, 0x1C, // D
    0x7F, 0x49, 0x49, 0x49, 0x41, // E
    0x7F, 0x09, 0x09, 0x01, 0x01, // F
    0x3E, 0x41, 0x41, 0x51, 0x32, // G
    0x7F, 0x08, 0x08, 0x08, 0x7F, // H
    0x00, 0x41, 0x7F, 0x41, 0x00, // I
    0x20, 0x40, 0x41, 0x3F, 0x01, // J
    0x7F, 0x08, 0x14, 0x22, 0x41, // K
    0x7F, 0x40, 0x40, 0x40, 0x40, // L
    0x7F, 0x02, 0x04, 0x02, 0x7F, // M
    0x7F, 0x04, 0x08, 0x10, 0x7F, // N
    0x3E, 0x41, 0x41, 0x41, 0x3E, // O
    0x7F, 0x09, 0x09, 0x09, 0x06, // P
    0x3E, 0x41, 0x51, 0x21, 0x5E, // Q
    0x7F, 0x09, 0x19, 0x29, 0x46, // R
    0x46, 0x49, 0x49, 0x49, 0x31, // S
    0x01, 0x01, 0x7F, 0x01, 0x01, // T
    0x3F, 0x40, 0x40, 0x40, 0x3F, // U
    0x1F, 0x20, 0x40, 0x20, 0x1F, // V
    0x7F, 0x20, 0x18, 0x20, 0x7F, // W
    0x63, 0x14, 0x08, 0x14, 0x63, // X
    0x03, 0x04, 0x78, 0x04, 0x03, // Y
    0x61, 0x51, 0x49, 0x45, 0x43, // Z
    0x00, 0x00, 0x7F, 0x41, 0x41, // [
    0x02, 0x04, 0x08, 0x10, 0x20, // \
    0x41, 0x41, 0x7F, 0x00, 0x00, // ]
    0x04, 0x02, 0x01, 0x02, 0x04, // ^
    0x40, 0x40, 0x40, 0x40, 0x40, // _
    0x00, 0x01, 0x02, 0x04, 0x00, // `
    0x20, 0x54, 0x54, 0x54, 0x78, // a
    0x7F, 0x48, 0x44, 0x44, 0x38, // b
    0x38, 0x44, 0x44, 0x44, 0x20, // c
    0x38, 0x44, 0x44, 0x48, 0x7F, // d
    0x38, 0x54, 0x54, 0x54, 0x18, // e
    0x08, 0x7E, 0x09, 0x01, 0x02, // f
    0x08, 0x14, 0x54, 0x54, 0x3C, // g
    0x7F, 0x08, 0x04, 0x04, 0x78, // h
    0x00, 0x44, 0x7D, 0x40, 0x00, // i
    0x20, 0x40, 0x44, 0x3D, 0x00, // j
    0x00, 0x7F, 0x10, 0x28, 0x44, // k
    0x00, 0x41, 0x7F, 0x40, 0x00, // l
    0x7C, 0x04, 0x18, 0x04, 0x78, // m
    0x7C, 0x08, 0x04, 0x04, 0x78, // n
    0x38, 0x44, 0x44, 0x44, 0x38, // o
    0x7C, 0x14, 0x14, 0x14, 0x08, // p
    0x08, 0x14, 0x14, 0x18, 0x7C, // q
    0x7C, 0x08, 0x04, 0x04, 0x08, // r
    0x48, 0x54, 0x54, 0x54, 0x20, // s
    0x04, 0x3F, 0x44, 0x40, 0x20, // t
    0x3C, 0x40, 0x40, 0x20, 0x7C, // u
    0x1C, 0x20, 0x40, 0x20, 0x1C, // v
    0x3C, 0x40, 0x30, 0x40, 0x3C, // w
    0x44, 0x28, 0x10, 0x28, 0x44, // x
    0x0C, 0x50, 0x50, 0x50, 0x3C, // y
    0x44, 0x64, 0x54, 0x4C, 0x44, // z
    0x00, 0x08, 0x36, 0x41, 0x00, // {
    0x00, 0x00, 0x7F, 0x00, 0x00, // |
    0x00, 0x41, 0x36, 0x08, 0x00, // }
    0x08, 0x08, 0x2A, 0x1C, 0x08, // ~
    0x08, 0x1C, 0x2A, 0x08, 0x08  // DEL
};

ushort font_read_index @export("ssd1306_font_read_index");

fn char font5x7_read_flash() @naked @noinline {
    asm("lds r24, ssd1306_font_read_index");
    asm("lds r25, ssd1306_font_read_index+1");
    asm("ldi r30, lo8(ssd1306_font5x7)");
    asm("ldi r31, hi8(ssd1306_font5x7)");
    asm("add r30, r24");
    asm("adc r31, r25");
    asm("lpm");
    asm("mov r24, r0");
    asm("ret");
}

fn char font5x7_read(ushort idx) {
    font_read_index = idx;
    return font5x7_read_flash();
}

fn void send_cmd(char cmd) {
    i2c::begin_transmission(device_addr);
    i2c::write_byte(SSD1306_CMD);
    i2c::write_byte(cmd);
    i2c::end_transmission();
}

fn void set_address_window() {
    send_cmd(SSD1306_COLUMNADDR);
    send_cmd(0x00);
    send_cmd((char)(display_width - 1));

    send_cmd(SSD1306_PAGEADDR);
    send_cmd(0x00);
    send_cmd((char)(display_height / 8 - 1));
}

fn int page_count() {
    return (int)display_height / (int)OLED_PAGE_HEIGHT;
}

fn int framebuffer_len() {
    return (int)display_width * page_count();
}

fn int framebuffer_index(int x, int y) {
    return x + (y / (int)OLED_PAGE_HEIGHT) * (int)display_width;
}

fn char framebuffer_bit(int y) {
    return (char)(1 << (char)(y % (int)OLED_PAGE_HEIGHT));
}

fn char normalize_addr(char addr) {
    if (addr == 0x78 || addr == 0x7A) {
        return (char)(addr >> 1);
    }
    return addr;
}

fn bool init_impl(char addr, char height) {
    device_addr   = normalize_addr(addr);
    display_height = height;
    display_width  = OLED_WIDTH;

    clear_impl();

    send_cmd(SSD1306_DISPLAYOFF);
    send_cmd(SSD1306_SETDISPLAYCLOCKDIV); send_cmd(0x80);
    send_cmd(SSD1306_SETMULTIPLEX);       send_cmd((char)(height - 1));
    send_cmd(SSD1306_SETDISPLAYOFFSET);   send_cmd(0x00);
    send_cmd(SSD1306_SETSTARTLINE | 0x00);
    send_cmd(SSD1306_CHARGEPUMP);
    send_cmd(0x10);
    send_cmd(SSD1306_MEMORYMODE);         send_cmd(0x00); // horizontal
    send_cmd(SSD1306_SEGREMAP | 0x01);
    send_cmd(SSD1306_COMSCANDEC);
    send_cmd(SSD1306_SETCOMPINS);
    if (height == 32) {
        send_cmd(0x02);
    } else {
        send_cmd(0x12);
    }
    send_cmd(SSD1306_SETCONTRAST);
    send_cmd(0x7F);
    send_cmd(0xCF);
    send_cmd(SSD1306_SETPRECHARGE);
    send_cmd(0x22);
    send_cmd(0xF1);
    send_cmd(SSD1306_SETVCOMDETECT);
    send_cmd(0x34);
    send_cmd(0x40);
    send_cmd(SSD1306_DISPLAYALLON_RESUME);
    send_cmd(SSD1306_NORMALDISPLAY);
    set_address_window();
    clear_impl();
    display_impl();
    send_cmd(SSD1306_DISPLAYON);

    return true;
}

fn void clear_impl() {
    int len = framebuffer_len();
    for (int i = 0; i < len; i++) {
        framebuffer_bits[i] = 0;
    }
}

fn void display_impl() {
    int pages = page_count();

    for (int page = 0; page < pages; page++) {
        send_cmd(SSD1306_COLUMNADDR);
        send_cmd(0x00);
        send_cmd((char)(display_width - 1));

        send_cmd(SSD1306_PAGEADDR);
        send_cmd((char)page);
        send_cmd((char)page);

        int page_offset = page * (int)display_width;
        for (int x = 0; x < display_width; x += OLED_DATA_CHUNK) {
            int remaining = (int)display_width - x;
            if (remaining > OLED_DATA_CHUNK) remaining = OLED_DATA_CHUNK;

            i2c::begin_transmission(device_addr);
            i2c::write_byte(SSD1306_DATA);
            for (int i = 0; i < remaining; i++) {
                i2c::write_byte(framebuffer_bits[page_offset + x + i]);
            }
            i2c::end_transmission();
        }
    }
}

fn void draw_pixel_impl(int x, int y, bool color) {
    if (x < 0 || x >= display_width) return;
    if (y < 0 || y >= display_height) return;

    int idx = framebuffer_index(x, y);
    char bit = framebuffer_bit(y);

    if (color) {
        framebuffer_bits[idx] |= bit;
    } else {
        framebuffer_bits[idx] &= (char)~bit;
    }
}

fn void draw_char_impl(int x, int y, char c) {
    draw_char_scaled_impl(x, y, c, 1);
}

fn void draw_char_scaled_impl(int x, int y, char c, int scale) {
    if (c < 32 || c > 127) return;
    if (scale < 1) scale = 1;

    int idx = (int)(c - 32) * FONT_WIDTH;
    for (int col = 0; col < FONT_WIDTH; col++) {
        char line = font5x7_read((ushort)(idx + col));
        for (int row = 0; row < FONT_HEIGHT; row++) {
            if ((line & (char)(1 << row)) != 0) {
                fill_rect_impl(x + col * scale, y + row * scale, scale, scale);
            }
        }
    }
}

fn void draw_string_impl(int x, int y, char[] s) {
    for (usz i = 0; i < s.len; i++) {
        draw_char_impl(x + (int)i * 6, y, s[i]);
    }
}

fn void draw_string_scaled_impl(int x, int y, char[] s, int scale) {
    if (scale < 1) scale = 1;
    for (usz i = 0; i < s.len; i++) {
        draw_char_scaled_impl(x + (int)i * 6 * scale, y, s[i], scale);
    }
}

fn void set_cursor_impl(int x, int y) {
    cursor_x = x;
    cursor_y = y;
}

fn void set_text_scale_impl(int scale) {
    if (scale < 1) scale = 1;
    text_scale = scale;
}

fn void print_impl(char[] s) {
    draw_string_scaled_impl(cursor_x, cursor_y, s, text_scale);
    cursor_x += (int)s.len * 6 * text_scale;
}

fn void draw_hline_impl(int x, int y, int w) {
    for (int i = 0; i < w; i++) {
        draw_pixel_impl(x + i, y, true);
    }
}

fn void draw_vline_impl(int x, int y, int h) {
    for (int i = 0; i < h; i++) {
        draw_pixel_impl(x, y + i, true);
    }
}

fn void draw_line_impl(int x0, int y0, int x1, int y1) {
    int dx = x1 - x0;
    if (dx < 0) dx = -dx;
    int sx = -1;
    if (x0 < x1) sx = 1;

    int dy = y1 - y0;
    if (dy < 0) dy = -dy;
    dy = -dy;
    int sy = -1;
    if (y0 < y1) sy = 1;

    int err = dx + dy;
    while (true) {
        draw_pixel_impl(x0, y0, true);
        if (x0 == x1 && y0 == y1) return;
        int e2 = 2 * err;
        if (e2 >= dy) {
            err += dy;
            x0 += sx;
        }
        if (e2 <= dx) {
            err += dx;
            y0 += sy;
        }
    }
}

fn void draw_rect_impl(int x, int y, int w, int h) {
    draw_hline_impl(x, y, w);
    draw_hline_impl(x, y + h - 1, w);
    draw_vline_impl(x, y, h);
    draw_vline_impl(x + w - 1, y, h);
}

fn void fill_rect_impl(int x, int y, int w, int h) {
    for (int row = 0; row < h; row++) {
        for (int col = 0; col < w; col++) {
            draw_pixel_impl(x + col, y + row, true);
        }
    }
}

fn void draw_circle_impl(int x0, int y0, int r) {
    int x = r;
    int y = 0;
    int err = 0;
    while (x >= y) {
        draw_pixel_impl(x0 + x, y0 + y, true);
        draw_pixel_impl(x0 + y, y0 + x, true);
        draw_pixel_impl(x0 - y, y0 + x, true);
        draw_pixel_impl(x0 - x, y0 + y, true);
        draw_pixel_impl(x0 - x, y0 - y, true);
        draw_pixel_impl(x0 - y, y0 - x, true);
        draw_pixel_impl(x0 + y, y0 - x, true);
        draw_pixel_impl(x0 + x, y0 - y, true);
        y++;
        if (err <= 0) {
            err += 2 * y + 1;
        }
        if (err > 0) {
            x--;
            err -= 2 * x + 1;
        }
    }
}

fn void fill_circle_impl(int x0, int y0, int r) {
    for (int y = -r; y <= r; y++) {
        for (int x = -r; x <= r; x++) {
            if (x * x + y * y <= r * r) {
                draw_pixel_impl(x0 + x, y0 + y, true);
            }
        }
    }
}

fn void draw_bitmap_impl(int x, int y, char[] bitmap, int w, int h) {
    int byte_width = (w + 7) / 8;
    for (int row = 0; row < h; row++) {
        for (int col = 0; col < w; col++) {
            int idx = row * byte_width + col / 8;
            if (idx < (int)bitmap.len && (bitmap[idx] & (char)(0x80 >> (col % 8))) != 0) {
                draw_pixel_impl(x + col, y + row, true);
            }
        }
    }
}

fn void invert_impl(bool invert) {
    if (invert) {
        send_cmd(SSD1306_INVERTDISPLAY);
    } else {
        send_cmd(SSD1306_NORMALDISPLAY);
    }
}
