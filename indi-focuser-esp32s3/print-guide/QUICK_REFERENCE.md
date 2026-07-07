# Print Quick Reference

One-page cheat sheet. Full details in [PRINT_GUIDE.md](PRINT_GUIDE.md).

---

## Filament: PETG — all parts, all telescopes

| Setting | Value |
|---------|-------|
| Nozzle | 240°C |
| Bed | 70°C |
| Plate | Textured PEI |
| Fan | 40–60% |

---

## Infill

| Part type | Infill | Pattern |
|-----------|--------|---------|
| Gears | **45%** | Gyroid |
| Everything else | 30% | Gyroid |

---

## Speed

| Part type | Outer wall | Inner wall | Infill |
|-----------|-----------|-----------|--------|
| Gears | **40 mm/s** | 60 mm/s | 120 mm/s |
| Structural | 60 mm/s | 80 mm/s | 150 mm/s |

---

## Walls / layers — all parts

- Wall loops: **4**
- Top layers: **5**
- Bottom layers: **5**
- Supports: **None**

---

## RVO Horizon 60 ED — parts list

| # | Part | Qty | Settings | Flat face down |
|---|------|-----|----------|---------------|
| 1 | Clamp body | 1 | Structural | Back face |
| 2 | Clamp lid | 1 | Structural | Outer face |
| 3 | Focuser knob gear | 1 | **Gears** | Non-herringbone face |
| 4 | Motor pinion | 1 | **Gears** | Flat face |
| 5 | Electronics box | 1 | Structural | Open top up |
| 6 | Electronics lid | 1 | Structural | Outer face |

---

## Celestron NexStar 8SE — parts list

| # | Part | Qty | Settings | Orientation |
|---|------|-----|----------|------------|
| 1 | Rear cell plate | 1 | Structural | Flat back on bed |
| 2 | Friction sleeve + gear | 1 | **Gears** | Gear face flat on bed |
| 3 | Motor pinion | 1 | **Gears** | Flat face |
| 4 | Electronics box | 1 | Structural | Open top up |
| 5 | Electronics lid | 1 | Structural | Outer face |

> ⚠ Measure `focus_shaft_od` with calipers before printing part 2. Default 13.1 mm.

---

## SkyWatcher Explorer 200P — parts list

| # | Part | Qty | Settings | Orientation |
|---|------|-----|----------|------------|
| 1 | Side bracket | 1 | Structural | Face plate flat on bed |
| 2 | Drive gear | 1 | **Gears** | Flat face on bed |
| 3 | Motor pinion | 1 | **Gears** | Flat face |
| 4 | Electronics box | 1 | Structural | Open top up |
| 5 | Electronics lid | 1 | Structural | Outer face |

> ⚠ Measure `focuser_body_w` with calipers before printing part 1. Default 76 mm.

---

## Print order (recommended)

1. Print gears first — quick dimensional test before committing to longer prints
2. Test shaft bore fit and gear mesh by hand
3. Print structural parts once gears are confirmed good
4. Insert heat-set inserts last, after all test-fits pass
