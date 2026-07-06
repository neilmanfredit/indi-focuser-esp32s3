# Contributing

Contributions are welcome and appreciated. This is a small open-source project maintained in spare time, so the bar for a useful contribution is low — even fixing a typo in the docs matters.

## What makes a useful contribution

**New telescope mount (most valuable)**
If you have a telescope not already covered, a new OpenSCAD file under `3d_files/<telescope-name>/` is a direct benefit to other users. Include:
- A comment block at the top of the SCAD file describing the telescope, focuser type, and all key dimensions
- A note in this README's telescope table (in your PR description if not in the file itself)
- Confirmation that you have physically printed and tested the design

**Firmware improvements**
- Bug fixes
- Improvements to step timing or backlash handling
- Support for a different microcontroller (keep the ESP32-S3 as the primary target)

**INDI driver improvements**
- Bug fixes
- Additional INDI properties (temperature compensation, speed control, etc.)

**Documentation**
- Wiring diagrams as images
- Build photos
- Corrections to any instructions that are unclear or wrong

## How to submit

1. Fork the repository on GitHub
2. Create a branch: `git checkout -b my-change`
3. Make your changes
4. Test what you can (flash firmware, run the Python test utility, build the driver)
5. Commit with a clear message: `git commit -m "Add mount for Sky-Watcher Esprit 80ED"`
6. Push and open a pull request against `main`

## Coding style

**Firmware (Arduino / C++):**
- 4-space indent
- Descriptive variable names
- Comments on anything non-obvious, especially ESP32-specific behaviour
- Keep serial commands and responses exactly matching the existing protocol

**INDI driver (C++):**
- Follow the existing style
- No new external dependencies beyond libindi and libnova

**OpenSCAD:**
- All key dimensions in a named variable block at the top — never hardcoded inside geometry
- Comments stating the real-world measurement source for each dimension (i.e. "measured with calipers" vs "manufacturer spec")
- Print orientation and support requirements noted in a comment block at the bottom

**Python:**
- PEP 8
- Only `pyserial` as an external dependency
- Docstrings on all functions

## Licence

By submitting a pull request you confirm your contribution is your own original work and you agree it will be published under the MIT licence that covers this project.

## Issues

Use the issue templates for bug reports and feature requests. For questions about building the hardware, a GitHub Discussion is more appropriate than an issue.
