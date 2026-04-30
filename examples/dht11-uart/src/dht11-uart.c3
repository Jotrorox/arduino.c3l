module dht11_uart;

import arduino::time;
import arduino::uart;
import arduino::gpio;
import arduino::driver::sensor::dht11;

fn void main() @export("start") {
    uart::begin(9600);
    time::delay(1000);

    uart::printfn("=== DHT11 Sensor ===");

    while (true) {
        dht11::Reading r = { .valid = 0 };

        // Retry up to 3 times
        for (int attempt = 0; attempt < 3; attempt++) {
            r = dht11::read(D2);
            if (r.valid) break;
            time::delay_ms(100);
        }

        if (!r.valid) {
            uart::printfn("Read failed! err=%d", r.error);
        } else {
            int temp = r.temperature;
            int hum = r.humidity;
            uart::printfn("Temp: %d.%02d C, Hum: %d.%02d %%RH",
                temp / 100, temp < 0 ? -(temp % 100) : temp % 100,
                hum / 100, hum < 0 ? -(hum % 100) : hum % 100);
        }
        time::delay(2000);
    }
}
