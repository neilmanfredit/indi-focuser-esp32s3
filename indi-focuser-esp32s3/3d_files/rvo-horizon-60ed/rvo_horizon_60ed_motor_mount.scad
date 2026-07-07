// ============================================================================
// RVO Horizon 60 ED — 28BYJ-48 Motor Focuser Mount   (rev 2 — corrected)
// ============================================================================
//
// REV 2 CHANGES (pre-print geometry review):
//   - Motor axis now PARALLEL to the focuser knob shaft (was perpendicular —
//     gears could never mesh). Motor mounts on a separate flat side plate.
//   - Clamp bolts removed from mid-height (they passed through the focuser
//     body). Clamp is now a closed-top channel with a bolted bottom plate.
//   - Focuser slot no longer cuts through the top face.
//   - gear_width reduced 8 → 6 mm so the pinion fits on the 28BYJ-48 shaft
//     behind the 4 mm motor plate.
//
// Parts:  1. clamp_body        — closed-top channel, open bottom
//         2. clamp_lid         — bottom plate, bolts up into the walls
//         3. focuser_knob_gear — 40T herringbone, replaces coarse knob
//         4. motor_pinion      — 10T herringbone on motor D-shaft
//         5. electronics_box / 6. electronics_lid
//         7. motor_plate       — flat plate bolted to the clamp side wall,
//                                carries the motor at 37.5 mm centre distance
//
// Hardware: M3×10 ×4 (bottom plate) · M3×10 ×2 (motor plate)
//           M3 heat-set ×6 · M2×8 ×2 (motor tabs, self-tap) · M3 grub ×1
//
// Print:   PETG · 0.2 mm · 4 walls · 30% (45% gears) · no supports
//          clamp_body: TOP face on bed. All other parts: flat face on bed.
// ============================================================================

$fn = 64;

// ── Focuser dimensions — VERIFY WITH CALIPERS ────────────────────────────────
focuser_body_w   = 58;    // focuser body width (across, knob-to-knob faces)
focuser_body_h   = 30;    // focuser body height
focuser_shaft_d  = 27.9;  // MEASURED 27.60 coarse hollow shaft + 0.3 clearance
knob_axis_y      = 15;    // knob shaft position along clamp depth (mid)
clamp_length     = 30;    // clamp depth along optical axis
clamp_wall       = 8;     // side wall thickness (houses heat-sets)
clamp_top        = 6;     // top wall thickness
slot_clear       = 0.4;   // clearance around focuser body

// ── Motor (28BYJ-48) ─────────────────────────────────────────────────────────
motor_body_d     = 28.2;
motor_boss_d     = 10.2;  // front boss clearance
motor_boss_h     = 2.0;   // counterbore depth for boss
motor_shaft_d    = 5.0;
motor_hole_pitch = 35;    // tab hole spacing

// ── Gears — herringbone, module 1.5 ──────────────────────────────────────────
gear_module      = 1.5;
gear_teeth_large = 40;
gear_teeth_small = 10;
gear_width       = 6;     // rev2: was 8 — must not exceed usable shaft length
herring_angle    = 30;

gear_r_large     = (gear_module * gear_teeth_large) / 2;   // 30.0
gear_r_small     = (gear_module * gear_teeth_small) / 2;   //  7.5
centre_distance  = gear_r_large + gear_r_small;            // 37.5

// ── Derived clamp dims ───────────────────────────────────────────────────────
fw      = focuser_body_w + slot_clear + clamp_wall * 2;    // 74.4 outer width
slot_h  = focuser_body_h + slot_clear;                     // 30.4 inner height
fh      = slot_h + clamp_top;                              // 36.4 outer height
knob_z  = slot_h / 2;                                      // knob axis height

// ── Motor plate ──────────────────────────────────────────────────────────────
plate_t          = 4;     // motor plate thickness (shaft protrudes ~6.5 mm)
plate_w          = 44;    // plate width (covers motor housing)
plate_bolt_z     = 28;    // height of the two plate-to-wall bolts
motor_z          = knob_z + centre_distance;   // motor axis height = 52.5

// ── Electronics box ──────────────────────────────────────────────────────────
ebox_w = 52;  ebox_h = 28;  ebox_d = 18;  ebox_wall = 2.5;
usb_w  = 12;  usb_h  = 6;

// ── Helpers ──────────────────────────────────────────────────────────────────
module m3_heatset(h=6) { cylinder(d=4.5, h=h); }
module m3_clear(h=20)  { cylinder(d=3.4, h=h); }
module m2_selftap(h=8) { cylinder(d=1.8, h=h); }

module d_shaft(d, flat_depth, h) {
    intersection() {
        cylinder(d=d, h=h);
        translate([-(d/2 - flat_depth), -d/2, 0]) cube([d, d, h]);
    }
}

module gear_2d(teeth, mod) {
    // Additive trapezoidal tooth profile — robust for FDM printing
    pitch_r = (mod * teeth) / 2;
    add_r   = pitch_r + mod;
    ded_r   = pitch_r - 1.25 * mod;
    tw_root = PI * mod * 0.62;   // tooth width at root
    tw_tip  = PI * mod * 0.34;   // tooth width at tip
    union() {
        circle(r=ded_r);
        for (i = [0:teeth-1])
            rotate([0, 0, i * 360/teeth])
                polygon([[-tw_root/2, ded_r-0.2], [tw_root/2, ded_r-0.2],
                         [ tw_tip/2,  add_r],     [-tw_tip/2, add_r]]);
    }
}

// Herringbone: twist derived from the helix angle for THIS gear's size.
// (rev 3 fix — twist was previously a fixed 30 deg, shearing teeth to ~87
//  deg overhangs and forcing supports. Correct twist = helix arc / pitch
//  circumference, ~3.3 deg on the 40T, ~13 deg on the 10T.)
function hb_twist(teeth, mod, half_w, helix) =
    tan(helix) * half_w / (PI * mod * teeth) * 360;

module hb_gear(teeth, mod, width, helix) {
    half = width / 2;
    tw   = hb_twist(teeth, mod, half, helix);
    translate([0, 0, half])
        for (h = [0, 1]) mirror([0, 0, h])
            linear_extrude(height=half, twist=tw, slices=6, convexity=6)
                gear_2d(teeth, mod);
}

// ── PART 1: Clamp body — closed top, open bottom ─────────────────────────────
// PRINT: top face (z = fh) on the bed. Slot walls vertical, no supports.
module clamp_body() {
    difference() {
        cube([fw, clamp_length, fh]);

        // Focuser slot — open at the bottom, closed at the top
        translate([clamp_wall, -1, -1])
            cube([focuser_body_w + slot_clear, clamp_length + 2, slot_h + 1]);

        // Knob shaft clearance holes — BOTH side walls (choose either side)
        for (sx = [0, 1])
            translate([sx * fw, knob_axis_y, knob_z])
                rotate([0, 90, 0])
                    translate([0, 0, -fw/2]) cylinder(d=20, h=fw);

        // Bottom-plate heat-sets: vertical, up into the wall bottoms
        for (x = [clamp_wall/2, fw - clamp_wall/2])
            for (y = [clamp_length * 0.25, clamp_length * 0.75])
                translate([x, y, -0.1]) m3_heatset(6);

        // Motor-plate heat-sets: horizontal, into BOTH side wall outer faces
        for (sx = [0, 1])
            for (y = [clamp_length * 0.25, clamp_length * 0.75])
                translate([sx == 0 ? 6 : fw - 6, y, plate_bolt_z])
                    rotate([0, sx == 0 ? -90 : 90, 0])
                        m3_heatset(6);
    }
}

// ── PART 2: Clamp lid (bottom plate) ─────────────────────────────────────────
// Closes the slot from below; the focuser is clamped between body and plate.
module clamp_lid() {
    difference() {
        cube([fw, clamp_length, 4]);
        for (x = [clamp_wall/2, fw - clamp_wall/2])
            for (y = [clamp_length * 0.25, clamp_length * 0.75])
                translate([x, y, -0.1]) m3_clear(6);
    }
}

// ── PART 3: Focuser knob gear — 40T ──────────────────────────────────────────
module focuser_knob_gear() {
    hub_d = 36;   // must exceed the 27.9 bore; ~4 mm wall
    difference() {
        union() {
            hb_gear(gear_teeth_large, gear_module, gear_width, herring_angle);
            translate([0, 0, gear_width]) cylinder(d=hub_d, h=8);   // hub
        }
        // Plain bore — shaft is round, clamped by grub screws
        translate([0, 0, -0.1])
            cylinder(d=focuser_shaft_d, h=gear_width + 8 + 0.2);
        // 3 x M3 grubs at 120 deg into the hub for a large plain shaft
        for (a = [0, 120, 240])
            rotate([0, 0, a])
                translate([0, hub_d/2 + 2, gear_width + 4])
                    rotate([90, 0, 0]) cylinder(d=2.5, h=hub_d/2 - focuser_shaft_d/2 + 4);
    }
}

// ── PART 4: Motor pinion — 10T ───────────────────────────────────────────────
module motor_pinion() {
    difference() {
        hb_gear(gear_teeth_small, gear_module, gear_width, herring_angle);
        translate([0, 0, -0.1]) d_shaft(motor_shaft_d, 1.2, gear_width + 0.2);
        translate([0, gear_r_small + 2, gear_width/2])
            rotate([90, 0, 0]) cylinder(d=1.6, h=gear_r_small + 3);
    }
}

// ── PART 7: Motor plate ──────────────────────────────────────────────────────
// Flat plate, bolts to the clamp side wall. Motor mounts on the OUTER face,
// shaft through the plate; pinion sits between plate and knob gear.
// PRINT: flat on the bed.
// Local coords: X = plate width (maps to clamp Y), Y = plate height (clamp Z).
module motor_plate() {
    plate_h = motor_z + motor_body_d/2 + 8;    // ≈ 74.6

    difference() {
        // Plate with rounded top
        hull() {
            cube([plate_w, 10, plate_t]);
            translate([plate_w/2, plate_h - plate_w/2, 0])
                cylinder(d=plate_w, h=plate_t);
        }

        // Knob shaft / gear-hub clearance
        translate([plate_w/2 - (clamp_length/2 - knob_axis_y), knob_z, -1])
            cylinder(d=32, h=plate_t + 2);  // 27.6 shaft clearance

        // Bolt holes to the clamp wall heat-sets
        for (x = [plate_w/2 - (clamp_length/2 - clamp_length*0.25),
                  plate_w/2 + (clamp_length*0.75 - clamp_length/2)])
            translate([x, plate_bolt_z, -1]) m3_clear(plate_t + 2);

        // Motor boss counterbore (outer face) + through hole
        translate([plate_w/2, motor_z, plate_t - motor_boss_h])
            cylinder(d=motor_boss_d, h=motor_boss_h + 1);
        translate([plate_w/2, motor_z, -1])
            cylinder(d=motor_shaft_d + 3, h=plate_t + 2);

        // Motor tab screws (M2 self-tap) on the 35 mm pitch
        for (dx = [-motor_hole_pitch/2, motor_hole_pitch/2])
            translate([plate_w/2 + dx, motor_z, -1]) m2_selftap(plate_t + 2);
    }
}

// ── PART 5/6: Electronics box + lid ──────────────────────────────────────────
module electronics_box() {
    ew = ebox_w + ebox_wall*2;  eh = ebox_h + ebox_wall*2;  ed = ebox_d + ebox_wall;
    difference() {
        cube([ew, ed, eh]);
        translate([ebox_wall, ebox_wall, ebox_wall]) cube([ebox_w, ebox_d, ebox_h + 1]);
        translate([ew/2 - usb_w/2, -0.1, eh/2 - usb_h/2]) cube([usb_w, ebox_wall + 0.2, usb_h]);
        translate([ew/2 - 6, ed - ebox_wall - 0.1, eh/2 - 4]) cube([12, ebox_wall + 0.2, 8]);
        for (i = [0:3]) translate([ebox_wall + i*11, ed/2, eh - 0.1]) cube([6, 6, ebox_wall + 0.2]);
        for (x = [ebox_wall + 4, ew - ebox_wall - 4])
            for (y = [4, ed - 4])
                translate([x, y, eh - 0.1]) m3_heatset(4);
    }
}

module electronics_lid() {
    ew = ebox_w + ebox_wall*2;  ed = ebox_d + ebox_wall;
    difference() {
        cube([ew, ed, ebox_wall + 1]);
        for (x = [ebox_wall + 4, ew - ebox_wall - 4])
            for (y = [4, ed - 4])
                translate([x, y, -0.1]) m3_clear(ebox_wall + 2);
    }
}

// ── Render (review layout) ───────────────────────────────────────────────────
clamp_body();
translate([0, 45, 0])   clamp_lid();
translate([110, 0, 0])  focuser_knob_gear();
translate([160, 0, 0])  motor_pinion();
translate([110, 90, 0]) motor_plate();
translate([0, 95, 0])   electronics_box();
translate([70, 95, 0])  electronics_lid();

// ── Assembly ─────────────────────────────────────────────────────────────────
// 1. Remove the coarse focus knob from the shaft (loosen its grub screw).
// 2. Slide clamp_body over the focuser from below; fit clamp_lid, 4 × M3.
// 3. Bolt motor_plate to the clamp side wall (knob side), 2 × M3.
// 4. Fit motor to the plate outer face: boss into counterbore,
//    2 × M2 self-tap through the tab holes.
// 5. Pinion onto the motor D-shaft; knob gear onto the focuser shaft.
//    Slide both along their shafts until the herringbones align, then
//    tighten grub screws. Mesh should be smooth with slight play.
