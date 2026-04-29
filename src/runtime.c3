module arduino::runtime @private;

// Signed 16-bit multiply.
fn short __mulhi3(short a, short b) @export("__mulhi3") {
    bool negative = (a < 0) != (b < 0);
    ushort ua = (ushort)(a < 0 ? -a : a);
    ushort ub = (ushort)(b < 0 ? -b : b);
    ushort ur = 0;

    while (ub != 0) {
        if (ub & 1) ur += ua;
        ua <<= 1;
        ub >>= 1;
    }

    short result = (short)ur;
    return negative ? -result : result;
}

// Signed 32-bit multiply.
fn int __mulsi3(int a, int b) @export("__mulsi3") {
    bool negative = (a < 0) != (b < 0);
    uint ua = (uint)(a < 0 ? -a : a);
    uint ub = (uint)(b < 0 ? -b : b);
    uint ur = 0;

    while (ub != 0) {
        if (ub & 1) ur += ua;
        ua <<= 1;
        ub >>= 1;
    }

    int result = (int)ur;
    return negative ? -result : result;
}
