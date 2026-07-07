// ── Part 6: Electronics lid ───────────────────────────────────────────────────
// Print orientation: flat outer face on bed (Z=0)
// The combined scene places this at Z=-15 (below bed) — corrected here.
// Dimensions: 57.0 x 20.5 x 3.5 mm (X x Y x Z)
// Supports: NONE
// Infill: 30%  Walls: 4  Layers: 0.20mm

use <rvo_horizon_60ed_motor_mount.scad>

// Module origin is at Z=0 flat face — correct for bed placement
electronics_lid();
