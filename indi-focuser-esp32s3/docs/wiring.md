# Wiring Guide — Arduino Nano ESP32 + ULN2003 + 28BYJ-48

## Overview

The ESP32-S3 runs at 3.3 V. The 28BYJ-48 motor needs 5 V. The ULN2003 driver board sits between them and handles the voltage difference.

```
Arduino Nano ESP32          ULN2003 board         28BYJ-48 motor
─────────────────           ─────────────          ──────────────
D2  ──────────────────────► IN1
D3  ──────────────────────► IN2
D4  ──────────────────────► IN3
D5  ──────────────────────► IN4
5V  ──────────────────────► VCC                ◄── motor red wire
GND ──────────────────────► GND
                             OUT1-4 ──────────────► motor coil wires
```

## Pin mapping detail

| Nano ESP32 label | ESP32-S3 GPIO | Function |
|-----------------|--------------|---------|
| D2 | GPIO5 | Stepper IN1 |
| D3 | GPIO6 | Stepper IN2 |
| D4 | GPIO7 | Stepper IN3 |
| D5 | GPIO8 | Stepper IN4 |
| 5V | VBUS | Motor + ULN2003 power |
| GND | GND | Common ground |

**Always use the D-label names (D2, D3, D4, D5) in code, not raw GPIO numbers.** On the Nano ESP32, bare integers map to raw GPIO numbers which are different from the silkscreen labels.

## Power

- ULN2003 VCC must be 5 V. Connect to the board's **5V pin** (available when USB is connected).
- Do not connect ULN2003 VCC to the 3.3 V pin — the motor will not turn properly.
- The GPIO signals (3.3 V) are sufficient to trigger the ULN2003 inputs, which have a ~1 V threshold.

## Important ESP32-S3 differences from ATmega Nano

1. **Logic level is 3.3 V** — do not connect 5 V signals to GPIO pins.
2. **`pinMode(x, OUTPUT)` is mandatory** — pins do not default to a safe state.
3. **EEPROM requires `begin()` and `commit()`** — the firmware handles both.
4. **USB port is `/dev/ttyACM0`** not `/dev/ttyUSB0` — no CH340 chip on this board.

## 28BYJ-48 motor connector

The motor has a 5-pin JST connector. Pin order (left to right, looking at the socket):

| Pin | Colour | Function |
|-----|--------|----------|
| 1 | Orange | Coil A1 |
| 2 | Yellow | Coil A2 |
| 3 | Pink   | Coil B1 |
| 4 | Blue   | Coil B2 |
| 5 | Red    | +5V common |

The ULN2003 board has a matching socket — just plug the motor directly in.
