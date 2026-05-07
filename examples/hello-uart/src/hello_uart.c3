module hello_uart;

import arduino::time;
import arduino::uart;

fn void main() @export("start") {
    uart::begin(9600);
    time::delay(1000);

    while (true) {
        uart::printn("Hello, World!");
        time::delay(1000);
    }
}
