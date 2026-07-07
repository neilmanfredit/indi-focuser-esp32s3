# Changelog

All notable changes will be documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [1.0.0] — Initial release

### Added
- Arduino firmware for ESP32-S3 (Arduino Nano ESP32)
  - Half-step 28BYJ-48 drive sequence
  - Flash-based EEPROM emulation with `begin()` and `commit()`
  - Explicit `pinMode()` calls (required on ESP32-S3)
  - Motor de-energisation after every move
  - Full serial command protocol
- INDI focuser driver (C++) targeting Linux / libindi
  - Absolute and relative move
  - Abort
  - Reverse direction toggle
  - Set zero position
  - 500ms position polling while moving
- Python serial test and calibration utility
- udev rule for stable `/dev/focuser` symlink (Arduino Nano ESP32 USB CDC VID/PID)
- OpenSCAD parametric 3D mounts for:
  - RVO Horizon 60 ED (clamping bracket)
  - Celestron NexStar 8SE (rear-cell plate replacement)
  - SkyWatcher Explorer 200P (non-invasive side bracket)
- Documentation: wiring, build, calibration, 3D printing
- GitHub Actions CI: INDI driver build check on Ubuntu
