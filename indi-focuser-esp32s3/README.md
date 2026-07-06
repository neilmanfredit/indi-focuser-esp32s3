# indi-focuser-esp32s3

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Linux-lightgrey.svg)]()
[![Board](https://img.shields.io/badge/board-Arduino%20Nano%20ESP32--S3-red.svg)]()
[![INDI](https://img.shields.io/badge/INDI-compatible-green.svg)]()
[![PHD2](https://img.shields.io/badge/PHD2-compatible-green.svg)]()

**A low-cost, open-source motorised telescope focuser for Linux, PHD2, and KStars/Ekos.**

Built around a **28BYJ-48 stepper motor**, **ULN2003 driver board**, and an **Arduino Nano ESP32 (ESP32-S3R8)**. Controlled over USB from any Linux machine via a native INDI driver. No Windows required. No ASCOM required.

3D-printable motor mounts in PETG are included for three telescopes:

| Telescope | Focuser type |
|-----------|-------------|
| RVO Horizon 60 ED | Dual-speed rack-and-pinion |
| Celestron NexStar 8SE | SCT mirror-shift |
| SkyWatcher Explorer 200P | 2" Crayford Newtonian |

---

## Why this project exists

Commercial motorised focusers start at £150 and climb quickly. The hardware in this project costs under £15. Most DIY focuser projects target Windows with ASCOM. This one is built for Linux from the ground up — it runs directly on a Raspberry Pi, a mini PC, or any Debian/Arch machine driving your imaging rig.

This project was inspired by the hardware design of [jlecomte/ascom-oag-focuser](https://github.com/jlecomte/ascom-oag-focuser) — an excellent Windows/ASCOM project. The firmware, INDI driver, and 3D files here are independent, original work. See [NOTICE](NOTICE) for full attribution.

---

## What you need to build this

### Electronics (under £15 total)

| Part | Approx cost |
|------|------------|
| Arduino Nano ESP32 (ESP32-S3R8) | £8–12 |
| 28BYJ-48 stepper + ULN2003 board (sold as a kit) | £2–3 |
| USB-C cable | Already have one |

### 3D printing

- Any FDM printer
- PETG filament (mandatory for outdoor use — see [docs/3d_printing.md](docs/3d_printing.md))
- ~50g filament per mount

### Tools

- Soldering iron (for heat-set inserts)
- M3 and M2 heat-set inserts
- M3 and M2 socket cap screws (see each SCAD file for exact quantities)
- Calipers (to verify your focuser dimensions before printing)

---

## Repository layout

```
indi-focuser-esp32s3/
│
├── firmware/
│   └── oag_focuser_firmware.ino     Arduino firmware (ESP32-S3)
│
├── indi_driver/
│   ├── indi_oag_focuser.h           INDI driver header
│   ├── indi_oag_focuser.cpp         INDI driver implementation
│   ├── indi_oag_focuser.xml         INDI device descriptor
│   └── CMakeLists.txt               Build system
│
├── 3d_files/
│   ├── rvo-horizon-60ed/
│   │   └── rvo_horizon_60ed_motor_mount.scad
│   ├── celestron-nexstar-8se/
│   │   └── nexstar_8se_motor_mount.scad
│   └── skywatcher-explorer-200p/
│       └── sw_explorer_200p_motor_mount.scad
│
├── scripts/
│   ├── oag_focuser_test.py          Serial test and calibration utility
│   └── 99-oag-focuser.rules         udev stable device symlink
│
├── docs/
│   ├── wiring.md                    Wiring guide
│   ├── build.md                     INDI driver build instructions
│   ├── calibration.md               Focuser calibration procedure
│   └── 3d_printing.md               Print settings and assembly
│
├── LICENSE                          MIT
├── NOTICE                           Third-party attribution
├── CONTRIBUTING.md
└── README.md
```

---

## Wiring

```
Arduino Nano ESP32 (3.3V logic)      ULN2003 board         28BYJ-48 motor
────────────────────────────────     ─────────────          ──────────────
D2  ────────────────────────────►  IN1
D3  ────────────────────────────►  IN2
D4  ────────────────────────────►  IN3
D5  ────────────────────────────►  IN4
5V  ────────────────────────────►  VCC  ◄────────────────── motor +5V
GND ────────────────────────────►  GND
                                    OUT1-4 ─────────────►  motor coils
```

**Key points for the ESP32-S3:**
- The motor runs on **5V** — connect ULN2003 VCC to the board's 5V pin (VBUS), not 3.3V
- The 3.3V GPIO signals are sufficient to trigger the ULN2003 inputs (threshold ~1V)
- Use the **D-label pin names** (D2, D3, D4, D5) in code — bare integers map to raw GPIO numbers on ESP32, which are different from the silkscreen labels
- The board enumerates as `/dev/ttyACM0` on Linux — no CH340 driver needed

See [docs/wiring.md](docs/wiring.md) for the full pinout table and connector details.

---

## Quick start

### Step 1 — Flash the firmware

1. Install the [Arduino IDE](https://www.arduino.cc/en/software)
2. Add the ESP32 board package: **Boards Manager** → search `esp32` → install **Arduino ESP32 Boards** by Arduino
3. Select: **Tools → Board → Arduino ESP32 Boards → Arduino Nano ESP32**
4. Open `firmware/oag_focuser_firmware.ino`
5. Connect via USB-C and click **Upload**

> If the upload fails, double-tap the reset button to enter bootloader mode — the RGB LED will pulse green.

### Step 2 — Test the hardware (no INDI needed)

```bash
pip install pyserial
python3 scripts/oag_focuser_test.py --port /dev/ttyACM0 --test
```

Or interactive mode for manual calibration:

```bash
python3 scripts/oag_focuser_test.py --port /dev/ttyACM0 -i
```

Available commands in interactive mode:

| Command | Action |
|---------|--------|
| `pos` | Report current position |
| `move <n>` | Move to absolute position n |
| `halt` | Stop immediately |
| `zero` | Set current position as zero |
| `rev on/off` | Reverse motor direction |
| `test` | Run automated self-test |

### Step 3 — Install the udev rule

Gives the device a stable name (`/dev/focuser`) regardless of which USB port you use:

```bash
sudo cp scripts/99-oag-focuser.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules
sudo udevadm trigger
ls -la /dev/focuser   # should appear
```

### Step 4 — Build and install the INDI driver

```bash
# Debian / Ubuntu / Raspberry Pi OS
sudo apt install libindi-dev libnova-dev cmake build-essential

# Arch Linux / Garuda Linux
sudo pacman -S indi libnova cmake base-devel

cd indi_driver
mkdir build && cd build
cmake ..
make -j$(nproc)
sudo make install
```

### Step 5 — Run

```bash
indiserver -v indi_oag_focuser
```

Connect **KStars/Ekos** or **PHD2** to `localhost:7624` and select **OAG Focuser**. Set the serial port to `/dev/ttyACM0` (or `/dev/focuser` if the udev rule is installed).

---

## Serial protocol

The firmware speaks a simple newline-terminated text protocol over USB serial at 115200 baud. Compatible with the protocol used by jlecomte/ascom-oag-focuser, so any tooling built for that project will also work here.

| Command | Response |
|---------|----------|
| `COMMAND:FOCUSER:HANDSHAKE` | `REPLY:FOCUSER:READY` |
| `COMMAND:FOCUSER:GETPOSITION` | `REPLY:FOCUSER:POSITION:<n>` |
| `COMMAND:FOCUSER:ISMOVING` | `REPLY:FOCUSER:ISMOVING:<0\|1>` |
| `COMMAND:FOCUSER:GETMAXPOSITION` | `REPLY:FOCUSER:MAXPOSITION:32767` |
| `COMMAND:FOCUSER:MOVE:<n>` | `REPLY:FOCUSER:OK` |
| `COMMAND:FOCUSER:HALT` | `REPLY:FOCUSER:OK` |
| `COMMAND:FOCUSER:SETZERO` | `REPLY:FOCUSER:OK` |
| `COMMAND:FOCUSER:GETREVERSE` | `REPLY:FOCUSER:REVERSE:<0\|1>` |
| `COMMAND:FOCUSER:SETREVERSE:<0\|1>` | `REPLY:FOCUSER:OK` |

Position is stored to flash on every stop and survives power cycles.

---

## 3D files

All mounts are **OpenSCAD parametric models**. Open in [OpenSCAD](https://openscad.org/) (free), adjust the parameters at the top to match your focuser, press **F6** to render, then **File → Export → Export as STL**.

**Measure your focuser with calipers before printing.** The key dimension to check per telescope:

| Telescope | File | Key parameter | Default |
|-----------|------|--------------|---------|
| RVO Horizon 60 ED | `rvo_horizon_60ed_motor_mount.scad` | `focuser_body_w` | 58 mm |
| Celestron NexStar 8SE | `nexstar_8se_motor_mount.scad` | `focus_shaft_od` | 13.1 mm |
| SkyWatcher Explorer 200P | `sw_explorer_200p_motor_mount.scad` | `focuser_body_w` | 76 mm |

Each SCAD file produces all parts needed for that telescope: motor bracket/plate, drive gear, motor pinion, electronics box, and lid.

Print in **PETG**. See [docs/3d_printing.md](docs/3d_printing.md) for full print settings, Bambu Labs H2S notes, and assembly guidance.

---

## Calibration

See [docs/calibration.md](docs/calibration.md) for the full procedure. In summary:

1. Set zero at the mechanical end stop
2. Confirm motor direction (reverse if needed)
3. Measure backlash with a dial indicator
4. Test from INDI

---

## ESP32-S3 firmware notes

Several things behave differently on ESP32-S3 compared to an ATmega Nano. The firmware handles all of these but they are worth understanding:

| Issue | ATmega Nano | ESP32-S3 | Solution in firmware |
|-------|------------|----------|---------------------|
| EEPROM | Built-in hardware | Flash emulation | `EEPROM.begin()` + `EEPROM.commit()` |
| Pin defaults | Defined at startup | Float — no default state | Explicit `pinMode(x, OUTPUT)` for all motor pins |
| Pin numbering | Integer = physical label | Integer = raw GPIO number | D-label names used throughout |
| USB device | `/dev/ttyUSB0` (CH340) | `/dev/ttyACM0` (native CDC) | udev rule provided |
| Logic voltage | 5V | 3.3V | ULN2003 inputs work fine at 3.3V |

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| Motor hums but doesn't turn | ULN2003 VCC on 3.3V pin | Move VCC wire to 5V pin |
| Motor turns wrong way | Wiring or direction flag | `rev on` in test utility |
| `/dev/ttyACM0` missing | Board not in run mode | Double-tap reset; try different cable |
| Handshake fails | Wrong port | `ls /dev/ttyACM*`; check firmware flashed |
| INDI driver not found | XML not installed | Verify `/usr/share/indi/indi_oag_focuser.xml` |
| Position lost on restart | EEPROM not committing | Reflash firmware; do not modify EEPROM calls |
| Gear slips under load | Underpowered 28BYJ-48 | Increase `STEP_DELAY_US` to 1500 in firmware |

---

## Contributing

Pull requests are welcome. Adding a mount design for a new telescope is particularly useful — see [CONTRIBUTING.md](CONTRIBUTING.md).

---

## Licence

MIT — see [LICENSE](LICENSE).

This project is independent and not affiliated with Julien Lecomte's ascom-oag-focuser. See [NOTICE](NOTICE) for attribution.

---

## Acknowledgements

Hardware concept and serial protocol inspired by [jlecomte/ascom-oag-focuser](https://github.com/jlecomte/ascom-oag-focuser) by Julien Lecomte (DarkSkyGeek). Original work in all firmware, driver, and 3D files.
