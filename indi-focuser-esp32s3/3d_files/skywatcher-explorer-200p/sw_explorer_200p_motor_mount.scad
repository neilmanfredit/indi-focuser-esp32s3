// ============================================================================
// SkyWatcher Explorer 200P — 28BYJ-48 Motor Focuser Mount  (rev 2 — corrected)
// ============================================================================
//
// REV 2 CHANGES (pre-print geometry review):
//   - Motor offset was along the knob shaft axis (gears could never mesh at
//     the correct centre distance) and the bracket web occupied the drive
//     gear's rotation plane. Replaced with a flat motor plate: motor axis
//     parallel to the knob shaft, offset vertically by the centre distance.
//   - Knob shaft clearance hole added to the plate (was missing entirely).
//   - Gear extrusion re-based to z=0 (previously half the gear sat below the
//     bed in exported STLs).
//   - gear_width 8 -> 6 mm to suit the 28BYJ-48 shaft length behind the plate.
//
// Design:  One coarse knob is removed; the drive gear replaces it on the
//          8 mm shaft. The flat plate fixes to the focuser body side wall
//          (2 x M3 into tapped holes, or cable ties through the slots) and
//          carries the motor 31.5 mm above the knob axis. Other knob stays
//          on for manual focusing. Fully reversible.
//
// Parts:   1. motor_plate   2. drive_gear (32T)   3. motor_pinion (10T)
//          4. electronics_box   5. electronics_lid
//
// Hardware: M3x10 x2 (plate, if tapping focuser body) or 2 cable ties
//           M2x8 x2 self-tap (motor tabs) · M3 grub x1 · M2 grub x1
//
// MEASURE focuser_body_w and shaft dia with calipers before printing.
// Print: PETG · 0.2 mm · 4 walls · 30% (45% gears) · no supports · flat down
// ============================================================================

$fn = 64;

// ── Focuser — VERIFY WITH CALIPERS ───────────────────────────────────────────
focuser_shaft_d  = 8.2;    // knob shaft dia + clearance
knob_axis_h      = 20;     // knob axis height above plate bottom edge (adjust
                           // so the plate bottom clears the focuser base)

// ── Motor (28BYJ-48) ─────────────────────────────────────────────────────────
motor_body_d     = 28.2;
motor_boss_d     = 10.2;
motor_boss_h     = 2.0;    // boss counterbore depth
motor_shaft_d    = 5.0;
motor_hole_pitch = 35;

// ── Gears — herringbone, module 1.5 ──────────────────────────────────────────
gear_module      = 1.5;
gear_teeth_drive = 32;
gear_teeth_pinion= 10;
gear_width       = 6;      // rev2: was 8
herring_angle    = 30;

gear_r_drive     = (gear_module * gear_teeth_drive) / 2;   // 24.0
gear_r_pinion    = (gear_module * gear_teeth_pinion) / 2;  //  7.5
centre_dist      = gear_r_drive + gear_r_pinion;           // 31.5

// ── Plate ────────────────────────────────────────────────────────────────────
plate_t          = 4;
plate_w          = 44;
motor_h          = knob_axis_h + centre_dist;   // motor axis height = 51.5

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
    tw_root = PI * mod * 0.62;
    tw_tip  = PI * mod * 0.34;
    union() {
        circle(r=ded_r);
        for (i = [0:teeth-1])
            rotate([0, 0, i * 360/teeth])
                polygon([[-tw_root/2, ded_r-0.2], [tw_root/2, ded_r-0.2],
                         [ tw_tip/2,  add_r],     [-tw_tip/2, add_r]]);
    }
}

// Herringbone: twist derived from helix angle for THIS gear's size.
// (rev 3 fix — twist was a fixed helix-degree value passed straight to
// linear_extrude, shearing teeth to ~87 deg overhangs and forcing supports.)
function hb_twist(teeth, mod, half_w, helix) =
    tan(helix) * half_w / (PI * mod * teeth) * 360;

// rev2: extrusion re-based so the gear spans z = 0 .. width
module hb_gear(teeth, mod, width, helix) {
    half = width / 2;
    tw   = hb_twist(teeth, mod, half, helix);
    translate([0, 0, half])
        for (h = [0, 1]) mirror([0, 0, h])
            linear_extrude(height=half, twist=tw, slices=6, convexity=6)
                gear_2d(teeth, mod);
}

// ── PART 1: Motor plate ──────────────────────────────────────────────────────
// Flat plate against the focuser body side wall. Knob shaft passes through
// the lower hole; motor mounts on the outer face at the top, shaft through,
// pinion between plate and drive gear. PRINT: flat on the bed.
module motor_plate() {
    plate_h = motor_h + motor_body_d/2 + 8;   // ≈ 73.6

    difference() {
        hull() {
            cube([plate_w, 8, plate_t]);
            translate([plate_w/2, plate_h - plate_w/2, 0])
                cylinder(d=plate_w, h=plate_t);
        }

        // Knob shaft / gear-hub clearance
        translate([plate_w/2, knob_axis_h, -1])
            cylinder(d=22, h=plate_t + 2);

        // Focuser body screws (M3 clearance) — tap M3 in the focuser side wall
        for (x = [plate_w*0.2, plate_w*0.8])
            translate([x, 6, -1]) m3_clear(plate_t + 2);

        // Cable-tie slots (no-modification alternative to the screws)
        for (x = [4, plate_w - 10])
            translate([x, knob_axis_h + 14, -1])
                cube([6, 3.5, plate_t + 2]);

        // Motor boss counterbore (outer face) + shaft through hole
        translate([plate_w/2, motor_h, plate_t - motor_boss_h])
            cylinder(d=motor_boss_d, h=motor_boss_h + 1);
        translate([plate_w/2, motor_h, -1])
            cylinder(d=motor_shaft_d + 3, h=plate_t + 2);

        // Motor tab screws (M2 self-tap, 35 mm pitch)
        for (dx = [-motor_hole_pitch/2, motor_hole_pitch/2])
            translate([plate_w/2 + dx, motor_h, -1]) m2_selftap(plate_t + 2);
    }
}

// ── PART 2: Drive gear — 32T, replaces one coarse knob ───────────────────────
module drive_gear() {
    hub_h = 10;
    difference() {
        union() {
            hb_gear(gear_teeth_drive, gear_module, gear_width, herring_angle);
            translate([0, 0, gear_width]) cylinder(d=16, h=hub_h);  // grip hub
        }
        translate([0, 0, -0.1])
            cylinder(d=focuser_shaft_d, h=gear_width + hub_h + 0.2);
        // M3 grub, radial into the hub
        translate([0, 12, gear_width + hub_h/2])
            rotate([90, 0, 0]) cylinder(d=2.5, h=14);
        // Grip slots on the hub
        for (i = [0:7])
            rotate([0, 0, i*45])
                translate([6.5, -1, gear_width + 1]) cube([2, 2, hub_h - 2]);
    }
}

// ── PART 3: Motor pinion — 10T ───────────────────────────────────────────────
module motor_pinion() {
    difference() {
        hb_gear(gear_teeth_pinion, gear_module, gear_width, herring_angle);
        translate([0, 0, -0.1]) d_shaft(motor_shaft_d, 1.2, gear_width + 0.2);
        translate([0, gear_r_pinion + 2, gear_width/2])
            rotate([90, 0, 0]) cylinder(d=1.6, h=gear_r_pinion + 3);
    }
}

// ── PART 4/5: Electronics box + lid ──────────────────────────────────────────
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
motor_plate();
translate([90, 0, 0])  drive_gear();
translate([150, 0, 0]) motor_pinion();
translate([0, 95, 0])  electronics_box();
translate([70, 95, 0]) electronics_lid();

// ── Assembly ─────────────────────────────────────────────────────────────────
// 1. Loosen the M4 grub on ONE coarse knob and slide it off. The other knob
//    stays for manual focusing.
// 2. Slide drive_gear onto the shaft, hub outwards; tighten the M3 grub.
// 3. Fix motor_plate to the focuser side wall — 2 x M3 into tapped holes, or
//    cable ties through the slots around the focuser body.
// 4. Motor on the plate outer face: boss into the counterbore, 2 x M2
//    self-tap through the tabs. Pinion onto the D-shaft, align with the
//    drive gear, tighten the M2 grub.
// 5. Mesh check: smooth with slight play. Adjust knob_axis_h ±0.5 mm and
//    reprint the plate if tight or loose.
