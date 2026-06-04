# Calibration Procedure

Run through these steps in order before using the focuser for imaging.

## Step 1 — Verify the motor turns

```bash
python3 scripts/oag_focuser_test.py --port /dev/ttyACM0 -i
focuser> move 500
focuser> pos
```

The motor should turn. If it hums but does not move, check that ULN2003 VCC is connected to the 5V pin, not 3.3V.

## Step 2 — Set zero position

Manually rotate the focuser to its physical end stop (fully inward). Then:

```bash
focuser> zero
```

The firmware stores this to flash. It persists across power cycles.

## Step 3 — Check direction

Move the focuser outward manually by rotating the focus knob, then command a move toward zero:

```bash
focuser> move 0
```

If the motor turns the focuser further outward instead of inward, reverse direction:

```bash
focuser> rev on
```

Re-zero after reversing.

## Step 4 — Measure backlash

Backlash comes from three places: the stepper motor gearbox, the 3D-printed gear mesh, and the focuser mechanism itself.

1. Move outward: `focuser> move 2000`
2. Attach a dial indicator to the focuser draw tube.
3. Move inward in 10-step increments: `focuser> move 1990`, `move 1980`, etc.
4. Note the step count at which the dial indicator first moves.
5. That count is your backlash. Set `BACKLASH_STEPS` if you add compensation logic, or note it for your imaging application.

Typical backlash with this hardware: 50–150 steps.

## Step 5 — Measure steps-per-unit (optional, for Ekos)

Ekos benefits from knowing how many focuser steps correspond to a known physical movement. Use the dial indicator:

1. Note current position.
2. Command 1000 steps: `focuser> move <current + 1000>`
3. Measure draw-tube movement in mm.
4. Enter steps-per-mm in the Ekos Focus module.

For the 28BYJ-48 in half-step mode with a 1.5-module gear train, expect roughly 4–8 steps per 0.01 mm depending on gear ratio.

## Step 6 — Test from INDI

```bash
indiserver -v indi_oag_focuser
```

Connect Ekos or PHD2, move the focuser from the UI, and confirm the draw tube moves the expected amount.
