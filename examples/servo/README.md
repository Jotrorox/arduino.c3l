# Servo example

Sweeps a hobby servo on Arduino Uno pin D9 between 0, 90, and 180 degrees.

```c3
servo::attach(D9);
servo::write_angle(D9, 90);
```

The servo driver uses Timer1, so it supports D9 and D10 and takes over normal PWM on those pins.
