# Interrupts

Module: `arduino::interrupt`

## Constants

### `ExternalInterrupt`

- `INT0` — digital pin 2
- `INT1` — digital pin 3

### `InterruptMode`

- `LOW`
- `CHANGE`
- `FALLING`
- `RISING`

## Types

```c3
alias InterruptHandler = fn void();
```

## Functions

```c3
macro void interrupts();
macro void no_interrupts();
macro void attach_interrupt(ExternalInterrupt interrupt, InterruptMode mode, InterruptHandler handler);
macro void detach_interrupt(ExternalInterrupt interrupt);
```
