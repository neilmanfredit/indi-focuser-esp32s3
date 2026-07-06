# Getting Started

This guide takes you from unboxed parts to a working motorised focuser connected to PHD2 or KStars/Ekos. Follow the steps in order.

---

## What you need

- Arduino Nano ESP32 (ESP32-S3R8)
- 28BYJ-48 stepper motor + ULN2003 driver board (sold as a kit, ~£3)
- USB-C cable
- Linux machine (desktop, laptop, or Raspberry Pi)
- 3D printed motor mount for your telescope (see [3d_files/](../3d_files/))

---

## 1. Wire the hardware

Connect the ULN2003 board to the Nano ESP32:

| ULN2003 pin | Nano ESP32 pin |
|-------------|---------------|
| IN1 | D2 |
| IN2 | D3 |
| IN3 | D4 |
| IN4 | D5 |
| VCC | **5V** (not 3.3V) |
| GND | GND |

Plug the 28BYJ-48 motor directly into the ULN2003 board's 5-pin socket.

**Do not power the motor from the 3.3V pin.** The motor needs 5V. The GPIO signals at 3.3V are fine — the ULN2003 input threshold is about 1V.

---

## 2. Flash the firmware

1. Download and install the [Arduino IDE](https://www.arduino.cc/en/software)
2. Open **Boards Manager**, search `esp32`, install **Arduino ESP32 Boards** by Arduino
3. Set board to **Arduino ESP32 Boards → Arduino Nano ESP32**
4. Open `firmware/oag_focuser_firmware.ino`
5. Connect the Nano ESP32 via USB-C
6. Click **Upload**

If the upload fails: double-tap the reset button until the RGB LED pulses green, then try again.

---

## 3. Verify it works

```bash
pip install pyserial
python3 scripts/oag_focuser_test.py --port /dev/ttyACM0 --test
```

You should see the motor turn and return, with a `PASS` result. If it hums but doesn't turn, check the 5V wiring.

---

## 4. Install the stable device symlink

```bash
sudo cp scripts/99-oag-focuser.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules && sudo udevadm trigger
ls -la /dev/focuser
```

From this point you can use `/dev/focuser` instead of `/dev/ttyACM0`.

---

## 5. Install the INDI driver

```bash
# Debian / Ubuntu / Raspberry Pi OS
sudo apt install libindi-dev libnova-dev cmake build-essential

# Arch / Garuda
sudo pacman -S indi libnova cmake base-devel

cd indi_driver
mkdir build && cd build
cmake .. && make -j$(nproc) && sudo make install
```

---

## 6. Calibrate the focuser

```bash
python3 scripts/oag_focuser_test.py --port /dev/focuser -i
```

1. Manually rotate your focuser to its physical inward end stop
2. Type `zero` to set that as position 0
3. Type `move 500` and watch the focuser move — if it goes the wrong way, type `rev on` and re-zero
4. Type `quit`

See [calibration.md](calibration.md) for backlash measurement.

---

## 7. Connect to KStars/Ekos or PHD2

Start the INDI server:

```bash
indiserver -v indi_oag_focuser
```

**KStars/Ekos:**
1. Tools → Ekos → New Profile (or edit existing)
2. Add Focuser → OAG Focuser
3. Connect, set port to `/dev/focuser`

**PHD2:**
PHD2 does not command the focuser directly. Use Ekos as the primary imaging application; PHD2 guides while Ekos handles focus.

---

## Done

Your focuser should now respond to commands from your imaging software. If anything doesn't work, check the [Troubleshooting](../README.md#troubleshooting) section in the main README or open an issue.
