module arduino::driver::sensor::dht11 @private;

import arduino::gpio;
import arduino::time;

fn bool wait_for(Pin pin, PinState state, int timeout_us) {
    for (int i = 0; i < timeout_us; i++) {
        if (gpio::digital_read(pin) == state) return true;
        time::delay_us(1);
    }
    return false;
}

fn Reading read_impl(Pin pin) {
    // Ensure line is high before start signal
    gpio::pin_mode(pin, INPUT_PULLUP);
    time::delay_ms(1);

    // Disable interrupts so UART/timer ISRs don't disturb the ~70us bit windows
    asm("cli");

    // Start signal: pull low for 20 ms, then high for 40 us
    gpio::pin_mode(pin, OUTPUT);
    gpio::digital_write(pin, LOW);
    time::delay_ms(20);
    gpio::digital_write(pin, HIGH);
    time::delay_us(40);

    // Release the line and enable pull-up
    gpio::pin_mode(pin, INPUT_PULLUP);

    // Wait for DHT11 response: low ~80us, high ~80us, then low before data
    if (!wait_for(pin, LOW, 200)) {
        asm("sei");
        return { .valid = 0, .error = 1 };
    }
    if (!wait_for(pin, HIGH, 200)) {
        asm("sei");
        return { .valid = 0, .error = 2 };
    }
    if (!wait_for(pin, LOW, 200)) {
        asm("sei");
        return { .valid = 0, .error = 3 };
    }

    // Read 40 bits (5 bytes)
    char[5] data;
    for (int byte_idx = 0; byte_idx < 5; byte_idx++) {
        char b = 0;
        for (int bit_idx = 0; bit_idx < 8; bit_idx++) {
            // Wait for rising edge (start of bit, ~50us low already passed)
            if (!wait_for(pin, HIGH, 150)) {
                asm("sei");
                return { .valid = 0, .error = 4 };
            }
            // Sample after ~30us:
            //   '0' -> high for ~26-28us (already low at 30us)
            //   '1' -> high for ~70us (still high at 30us)
            time::delay_us(30);
            if (gpio::digital_read(pin) == HIGH) {
                b = (char)(b | (char)(0x80 >> bit_idx));
            }
            // Wait for falling edge (end of bit)
            if (!wait_for(pin, LOW, 150)) {
                asm("sei");
                return { .valid = 0, .error = 5 };
            }
        }
        data[byte_idx] = b;
    }

    asm("sei");

    // Verify checksum
    if ((char)(data[0] + data[1] + data[2] + data[3]) != data[4]) {
        return { .valid = 0, .error = 6 };
    }

    // DHT11: integer values only, scale to hundredths for uniform interface
    int humidity    = (int)data[0] * 100;
    int temperature = (int)data[2] * 100;

    return {
        .temperature = temperature,
        .humidity    = humidity,
        .valid       = 1,
        .error       = 0
    };
}
