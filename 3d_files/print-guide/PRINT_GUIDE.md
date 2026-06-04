# Bambu Studio Print Guide

Complete slicing instructions for all motor mount parts.
Printer: Bambu Lab H2S (also works on X1C, P1S, A1).
Filament: PETG — mandatory for outdoor use.

---

## Before you start

### 1. Export STL files from OpenSCAD

The files in `3d_files/` are `.scad` source files. You need to export STL before slicing.

1. Install [OpenSCAD](https://openscad.org/downloads.html) (free)
2. Open your telescope's `.scad` file
3. To export parts individually, comment out all parts except the one you want:

```openscad
// Example — export only the drive gear:
drive_gear();

// Comment out everything else:
// motor_bracket();
// motor_pinion();
// electronics_box();
// electronics_lid();
```

4. Press **F6** to render (10–30 seconds for gears)
5. **File → Export → Export as STL**
6. Repeat for each part

### 2. Dry your filament

PETG must be dry before printing gears. Wet filament strings between teeth and produces weak, rough tooth surfaces.

Dry at **65°C for 4–6 hours** in a filament dryer or low-temperature oven before printing any gear parts.

### 3. Import presets (optional)

Three JSON preset files are included in `print-guide/process-presets/`:

| File | Use for |
|------|---------|
| `indi-focuser-PETG-filament.json` | Filament settings |
| `indi-focuser-PETG-structural.json` | Clamp body, brackets, electronics box |
| `indi-focuser-PETG-gears.json` | All gears and the friction sleeve |

To import in Bambu Studio:
**Settings → Filament / Process → Import** → select the JSON file.

If you prefer to set manually, all values are listed in the tables below.

---

## Slicer settings

### Filament (PETG)

| Parameter | Value |
|-----------|-------|
| Nozzle temp | 240°C |
| Bed temp | 70°C |
| Plate type | Textured PEI (not smooth — PETG sticks too aggressively) |
| Fan speed | 40–60% |
| Retraction | 0.8 mm at 35 mm/s |

### Structural parts

Applies to: clamp body, clamp lid, side bracket, electronics box, electronics lid, rear cell plate, friction sleeve hub.

| Parameter | Value |
|-----------|-------|
| Layer height | 0.20 mm |
| First layer height | 0.20 mm |
| Wall loops | 4 |
| Top/bottom layers | 5 |
| Infill density | 30% |
| Infill pattern | Gyroid |
| Outer wall speed | 60 mm/s |
| Inner wall speed | 80 mm/s |
| Infill speed | 150 mm/s |
| First layer speed | 30 mm/s |
| Support | **None** |
| Seam position | Rear |
| Brim | None |

### Gears

Applies to: focuser knob gear, motor pinion, drive gear.

| Parameter | Value |
|-----------|-------|
| Layer height | 0.20 mm |
| First layer height | 0.20 mm |
| Wall loops | 4 |
| Top/bottom layers | 5 |
| Infill density | **45%** |
| Infill pattern | Gyroid |
| Outer wall speed | **40 mm/s** — slower for tooth accuracy |
| Inner wall speed | 60 mm/s |
| Infill speed | 120 mm/s |
| First layer speed | 25 mm/s |
| Support | **None** |
| Seam position | Rear |
| Brim | None |

---

## Part orientations

Correct orientation is critical — wrong orientation produces weak layer lines across stress points.

### RVO Horizon 60 ED

| Part | Orientation | Notes |
|------|------------|-------|
| Clamp body | Flat back face on bed | Focuser slot opening faces up |
| Clamp lid | Flat outer face on bed | |
| Focuser knob gear | Flat face (non-herringbone side) on bed | |
| Motor pinion | Flat face on bed | |
| Electronics box | Open top facing up | |
| Electronics lid | Flat outer face on bed | |

### Celestron NexStar 8SE

| Part | Orientation | Notes |
|------|------------|-------|
| Rear cell plate | Flat back face on bed | Motor housing boss faces up |
| Friction sleeve + gear | Gear face flat on bed | Sleeve hub points up |
| Motor pinion | Flat face on bed | |
| Electronics box | Open top facing up | |
| Electronics lid | Flat outer face on bed | |

### SkyWatcher Explorer 200P

| Part | Orientation | Notes |
|------|------------|-------|
| Side bracket | Face plate flat on bed | Motor housing points up |
| Drive gear | Flat face on bed | Grip hub points up |
| Motor pinion | Flat face on bed | |
| Electronics box | Open top facing up | |
| Electronics lid | Flat outer face on bed | |

---

## Plate layout suggestions

You can print multiple parts together to save time. Suggested groupings for a 256×256 mm build plate:

**Plate 1 — Gears (slow settings)**
- Focuser knob gear (or drive gear)
- Motor pinion
- Use the gear preset (40 mm/s outer wall)

**Plate 2 — Structural (faster settings)**
- Clamp body / side bracket / rear cell plate
- Electronics box
- Use the structural preset (60 mm/s outer wall)

**Plate 3 — Small parts**
- Clamp lid / electronics lid
- Any spare pinions

Do not mix gears and structural parts on the same plate if using different speed profiles — Bambu Studio applies one process profile per plate (unless using multi-process mode).

---

## Post-print checks

### Gears
After printing, before installing heat-set inserts:

1. Test-mesh the large and small gear by hand
2. Mesh should be smooth — slight resistance is fine, grinding or binding is not
3. If binding: increase `gear_module` by 0.1 in the SCAD file, re-export, reprint
4. If too loose/rattly: decrease `gear_module` by 0.1

### Shaft bores
1. The focuser shaft should slip into the gear bore with light finger pressure
2. Not forced (too tight — ream gently with a round file or drill bit)
3. Not loose/wobbly (too loose — reprint with bore diameter reduced by 0.1 mm)

### Clamp / bracket
1. Test-fit on the focuser before inserting any heat-set inserts
2. The clamping slot should contact the focuser body without forcing
3. Minor tightness: lightly file the contact faces — faster than reprinting

### Heat-set inserts
1. Soldering iron at 180–200°C, pointed brass tip
2. Press slowly and perpendicular to the surface
3. Stop flush with or 0.2 mm below the surface
4. Let cool 60 seconds before applying any load

---

## Troubleshooting

| Problem | Cause | Fix |
|---------|-------|-----|
| Gear teeth have strings between them | Wet filament | Dry filament, reprint |
| Gear bore too tight | Printer over-extruding slightly | Calibrate e-steps or reduce bore dia by 0.1 mm in SCAD |
| First layer not sticking | Dirty PEI plate | Clean with IPA, re-level |
| PETG stringing on overhangs | Fan too low | Increase fan to 70% for overhangs only |
| Electronics box walls thin/weak | Infill too low | Use 4 walls minimum — already in preset |
| Layer delamination on bracket | Fan too high, poor bonding | Reduce fan to 40%, increase temp to 245°C |

---

## H2S-specific tips

- **AMS**: Load PETG in one slot, single-material print — no colour changes needed
- **Lidar calibration**: The H2S scans before printing; PETG on textured PEI reads reliably
- **First layer**: If first layer looks rough, wipe the plate with IPA and re-run first layer calibration
- **Plate adhesion**: If parts lift at corners (rare with PETG on textured PEI), add a 3 mm brim to structural parts only — not gears
- **AMS humidity**: Keep PETG in the AMS with desiccant. If the AMS humidity indicator turns pink, dry the filament before printing gears
