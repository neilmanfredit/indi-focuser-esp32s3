// ── Part 2: Clamp lid ─────────────────────────────────────────────────────────
// Print orientation: flat outer face on bed (Z=0)
// The combined scene places this at Z=-15 (below bed) — corrected here.
// Dimensions: 66.0 x 30.0 x 5.0 mm (X x Y x Z)
// Supports: NONE
// Infill: 30%  Walls: 4  Layers: 0.20mm

use <rvo_horizon_60ed_motor_mount.scad>

// No translate needed — module origin is already at Z=0 flat face
clamp_lid();
