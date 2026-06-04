# 3D Printing Guide

## Why PETG

All mounts are designed for **PETG**. Do not use PLA for any part that will be left attached to a telescope outdoors.

| Property | PLA | PETG |
|----------|-----|------|
| Heat resistance | ~60°C — warps in summer sun on a dark OTA | ~80°C |
| Cold brittleness | Brittle below ~5°C | Flexible to −20°C |
| UV resistance | Degrades in 6–12 months outdoors | Adequate |
| Layer adhesion | Good | Excellent — critical for gear teeth |
| Moisture | Weakens over time | Largely resistant |

ASA is preferable if you have it dialled in on your printer. ABS is not recommended — poor layer adhesion and warping risk.

## Print settings

| Parameter | Value |
|-----------|-------|
| Layer height | 0.2 mm |
| Perimeters / walls | 4 |
| Top/bottom layers | 5 |
| Infill | 30% structural parts; 45% gears |
| Infill pattern | Gyroid or grid |
| Nozzle temp | 235–245°C (PETG) |
| Bed temp | 70–80°C |
| Bed surface | Textured PEI |
| Fan cooling | 30–50% (reducing cooling improves PETG layer bonding) |
| First layer speed | 20 mm/s |
| Wall speed | 25–30 mm/s for gears; 40–50 mm/s elsewhere |
| Supports | None — all parts are support-free in stated orientation |

**Dry your filament before printing gears.** Wet PETG strings between teeth and produces weak, rough gear faces. Dry at 65°C for 4–6 hours in a filament dryer or oven.

## Bambu Labs H2S specific

- AMS: PETG in slot 1, single-material print
- Plate: textured PEI
- Seam: rear (hidden on gear face)
- Enable "Slow down for overhangs" — helps gear tooth tops
- Wall generator: Classic mode for gears (more predictable seam placement)

## Part orientations

### Clamp / bracket bodies
Flat mounting face down. The internal focuser slot faces down and acts as its own bridge.

### Gears
Flat face down. No supports needed. The herringbone tooth profile prints cleanly because each layer is fully supported by the previous one.

### Electronics boxes
Open top facing up. No supports.

## Heat-set inserts

All bolt holes use knurled M3 or M2 heat-set inserts.

1. Heat your soldering iron to 180–200°C.
2. Use a pointed brass tip (dedicated insert tip is ideal).
3. Place the insert on the hole and press gently and perpendicularly.
4. Stop when the insert is flush with or 0.2 mm below the surface.
5. Let cool fully (60 seconds minimum) before applying any load.

Do not use a flat iron tip — it pushes material sideways and produces a weak, crooked insert.

## Post-print checks

After printing gears:
1. Test-mesh the large and small gear by hand before installing the motor.
2. The mesh should be smooth with a small, consistent gap — not tight, not sloppy.
3. If tight: increase `centre_dist` in the SCAD file by 0.1 mm and reprint the bracket.
4. If loose/rattly: decrease by 0.1 mm.

After printing the clamp or bracket:
1. Test-fit on the focuser before inserting heat-sets.
2. The clamping slot or bracket face should contact the focuser body without forcing.
3. If tight: light filing or sanding on the contact face. Do not reprint — PETG can be eased much faster than reprinting.

## Electronics box assembly

The Nano ESP32 fits the standard Arduino Nano form factor.
The ULN2003 board sits beside it in the box.
Route the motor cable out through the rear slot; the USB-C cable exits through the front cutout.
