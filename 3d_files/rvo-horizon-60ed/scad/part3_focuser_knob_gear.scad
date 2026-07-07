// ── Part 3: Focuser knob gear (large) ────────────────────────────────────────
// Print orientation: flat bottom face on bed (Z=0)
// Herringbone faces point UP — each layer fully supported by previous
// Dimensions: 63.0 x 63.0 x 14.0 mm (X x Y x Z)
//   gear_width=8mm body + 6mm hub cap on top
// Supports: NONE — herringbone self-supports
// Infill: 45%  Walls: 4  Outer wall speed: 40mm/s  Layers: 0.20mm
// DRY FILAMENT before printing

use <rvo_horizon_60ed_motor_mount.scad>

// Gear module origin is at Z=0 flat face — correct for bed placement
focuser_knob_gear();
