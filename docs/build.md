# Building the INDI Driver

## Dependencies

### Debian / Ubuntu / Raspberry Pi OS

```bash
sudo apt update
sudo apt install libindi-dev libnova-dev cmake build-essential
```

### Arch Linux / Garuda Linux

```bash
sudo pacman -S indi libnova cmake base-devel
```

### Fedora / RHEL

```bash
sudo dnf install libindi-devel libnova-devel cmake gcc-c++
```

## Build

```bash
cd indi_driver
mkdir build && cd build
cmake ..
make -j$(nproc)
```

## Install

```bash
sudo make install
```

This installs:
- `/usr/local/bin/indi_oag_focuser` — the driver binary
- `/usr/share/indi/indi_oag_focuser.xml` — the device descriptor (tells INDI clients this driver exists)

## Run

```bash
indiserver -v indi_oag_focuser
```

Default serial port is `/dev/ttyACM0`. Change it in the INDI client connection settings, or install the udev rule to get a stable `/dev/oag_focuser` symlink.

## Using with KStars / Ekos

1. Start `indiserver` as above.
2. In KStars: Tools → Ekos → New Profile.
3. Add **Focuser → OAG Focuser** to the profile.
4. Connect, set port to `/dev/ttyACM0`.

## Using with PHD2

PHD2 does not drive the focuser directly. Connect via Ekos or use a separate INDI client. PHD2 monitors the guide star while the imaging application commands focus changes.

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `indi_oag_focuser: command not found` | Run `sudo make install` again; check `/usr/local/bin` is on your PATH |
| Driver not listed in INDI client | Check `/usr/share/indi/indi_oag_focuser.xml` exists |
| `No response to handshake` | Check port name; confirm firmware flashed; try `python3 scripts/oag_focuser_test.py` first |
| Build fails: `libindi not found` | Install `libindi-dev` (Debian) or `indi` (Arch) |
