module aht20_uart;

import arduino::time;
import arduino::uart;
import arduino::i2c;
import arduino::driver::sensor::aht20;

fn void main() @export("start") {
    uart::begin(9600);
    time::delay(1000);

    i2c::begin();

    uart::printfn("=== AHT20 Sensor ===");

    if (!aht20::init()) {
        uart::printfn("AHT20 init failed!");
        while (true) {}
    }
    uart::printfn("AHT20 ready.");

    while (true) {
        aht20::Reading r = aht20::read();
        if (!r.valid) {
            uart::printfn("Read failed!");
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
