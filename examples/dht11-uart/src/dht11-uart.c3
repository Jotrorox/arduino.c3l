module dht11_uart;

import arduino::time;
import arduino::uart;
import arduino::gpio;
import arduino::driver::sensor::dht11;

fn void println(char[] msg) {
    uart::write_line(msg);
}

fn void print_int(short value) {
    if (value == 0) {
        uart::write('0');
        return;
    }
    if (value < 0) {
        uart::write('-');
        value = -value;
    }
    char[5] buf;
    int i = 0;
    while (value > 0) {
        buf[i] = (char)(value % 10 + '0');
        value /= 10;
        i++;
    }
    for (int j = i - 1; j >= 0; j--) {
        uart::write(buf[j]);
    }
}

fn void print_fixed(int value) {
    short v = (short)value;
    if (v < 0) {
        uart::write('-');
        v = (short)(0 - v);
    }
    short whole = v / 100;
    short frac = v % 100;
    print_int(whole);
    uart::write('.');
    char d1 = 0;
    while (frac >= 10) {
        frac = (short)(frac - 10);
        d1 = (char)(d1 + 1);
    }
    uart::write((char)(d1 + '0'));
    uart::write((char)(frac + '0'));
}

fn void main() @export("start") {
    uart::begin(9600);
    time::delay(1000);

    println("=== DHT11 Sensor ===");

    while (true) {
        dht11::Reading r = { .valid = 0 };

        // Retry up to 3 times
        for (int attempt = 0; attempt < 3; attempt++) {
            r = dht11::read(D2);
            if (r.valid) break;
            time::delay_ms(100);
        }

        if (!r.valid) {
            uart::write_string("Read failed! err=");
            print_int((short)r.error);
            uart::write_crlf();
        } else {
            uart::write_string("Temp: ");
            print_fixed(r.temperature);
            uart::write_string(" C, Hum: ");
            print_fixed(r.humidity);
            uart::write_string(" %RH");
            uart::write_crlf();
        }
        time::delay(2000);
    }
}
