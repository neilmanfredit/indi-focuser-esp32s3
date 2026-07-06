# RVO Horizon 60 ED — STL Export & Bambu Studio Guide

## Quick start

```bash
chmod +x export_stl.sh
./export_stl.sh
```

STL files are written to `stl/`. Drag them into Bambu Studio — no rotation needed.

---

## What the script does

OpenSCAD's original file renders all parts in a single scene, some at negative Z positions (below the virtual bed). This folder contains one SCAD file per part, each placing the part at Z=0 in the correct print orientation. The export script renders each one via the OpenSCAD CLI and writes a binary STL.

---

## Part files

| File | Part | Dimensions (mm) | Z on bed |
|------|------|----------------|---------|
| `scad/part1_clamp_body.scad` | Clamp body | 102.2 × 30.0 × 38.0 | flat back face |
| `scad/part2_clamp_lid.scad` | Clamp lid | 66.0 × 30.0 × 5.0 | flat outer face |
| `scad/part3_focuser_knob_gear.scad` | Focuser knob gear | 63.0 × 63.0 × 14.0 | flat bottom |
| `scad/part4_motor_pinion.scad` | Motor pinion | 18.0 × 18.0 × 8.0 | flat bottom |
| `scad/part5_electronics_box.scad` | Electronics box | 57.0 × 20.5 × 33.0 | solid base down |
| `scad/part6_electronics_lid.scad` | Electronics lid | 57.0 × 20.5 × 3.5 | flat outer face |

---

## Bambu Studio plate layout

All STL files import flat on the bed — no manual rotation required.

**Plate 1 — Gears** (use `indi-focuser-PETG-gears` process preset)
- `rvo_p3_focuser_knob_gear.stl`
- `rvo_p4_motor_pinion.stl`

**Plate 2 — Structural** (use `indi-focuser-PETG-structural` process preset)
- `rvo_p1_clamp_body.stl`
- `rvo_p5_electronics_box.stl`

**Plate 3 — Lids** (use `indi-focuser-PETG-structural` process preset)
- `rvo_p2_clamp_lid.stl`
- `rvo_p6_electronics_lid.stl`

---

## Adjusting dimensions before export

If your focuser body width differs from 58 mm, edit `scad/rvo_horizon_60ed_motor_mount.scad`:

```openscad
focuser_body_w  = 58;   // ← change to your measured width
focuser_shaft_d = 8.2;  // ← change to your shaft OD + 0.2mm clearance
```

Then re-run `./export_stl.sh` — all parts regenerate with the new dimensions.

---

## Manual export (no script)

If you prefer to use the OpenSCAD GUI:

1. Open one of the `scad/part*.scad` files
2. Press **F6** to render
3. **File → Export → Export as STL**
4. Import the STL into Bambu Studio

The part SCAD files use `use <>` to include the main file so all modules and parameters are available without duplication.

---

## OpenSCAD render times (approximate, i7/Ryzen)

| Part | Render time |
|------|------------|
| Clamp body | 5–10 s |
| Clamp lid | 2–3 s |
| Focuser knob gear | 20–40 s |
| Motor pinion | 5–10 s |
| Electronics box | 3–5 s |
| Electronics lid | 2–3 s |

The gears are the slowest due to the herringbone twist computation. This is normal.
