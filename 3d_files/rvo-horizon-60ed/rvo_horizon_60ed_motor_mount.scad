// ============================================================================
// RVO Horizon 60 ED — 28BYJ-48 Motor Focuser Mount
// ============================================================================
//
// Telescopes:  RVO Horizon 60 ED Doublet Refractor
// Focuser:     Dual-speed rack-and-pinion, 2" draw tube
//              Coarse knob shaft: ~8 mm round with flat (D-shaft)
//              Fine knob (10:1) shaft: ~6 mm
//              Focuser body outer width: ~58 mm
//
// Motor:       28BYJ-48 stepper (body Ø28 mm, shaft Ø5 mm)
// Driver PCB:  ULN2003 board (fits in electronics box below)
// MCU:         Arduino Nano ESP32 (Nano form factor)
//
// Design:      Clamp around focuser body. Motor sits beside coarse knob
//              axis, drives via herringbone gear + pinion on the knob shaft.
//              Electronics box clips onto the side of the clamp body.
//
// Print:       PETG, 0.2 mm layers, 4 perimeters, 30% infill minimum
//              Orientation: clamp flat side down (no supports needed)
//
// Parts:       Motor clamp body (×1)
//              Lid (×1)
//              Focuser knob gear (large, ×1) — replaces the coarse knob
//              Motor pinion (small, ×1)
//              Electronics box (×1)
//              Electronics lid (×1)
//
// Hardware:    M3×12 socket cap (×4) — clamp bolts
//              M3×6  socket cap (×2) — lid screws
//              M3 heat-set insert (×6)
//              M2×8  socket cap (×2) — motor mounting
//              M2 heat-set insert (×4)
//
// ============================================================================

$fn = 64;

// ── Key dimensions ────────────────────────────────────────────────────────────
focuser_body_w     = 58;   // focuser body outer width (mm)
focuser_body_h     = 30;   // focuser body outer height (mm)
focuser_shaft_d    = 8.2;  // coarse knob shaft diameter (clearance fit)
clamp_wall         = 4;    // wall thickness of clamp
clamp_length       = 30;   // clamp depth (along optical axis)

// Motor geometry (28BYJ-48)
motor_body_d       = 28.2;  // motor body OD (clearance)
motor_body_l       = 19.5;  // motor body length (excl. shaft boss)
motor_shaft_d      = 5.0;   // motor shaft diameter
motor_shaft_flat   = 3.0;   // chord of D-flat on motor shaft
motor_mount_hole_d = 2.2;   // M2 clearance for motor PCB holes
motor_boss_d       = 9.5;   // motor front boss diameter
motor_boss_h       = 1.5;   // motor front boss height
motor_hole_pitch   = 35;    // motor mounting hole pitch (28BYJ-48 standard)

// Gear dimensions (herringbone, matching jlecomte approach)
gear_module        = 1.5;   // module — coarser for strength in PETG
gear_teeth_large   = 40;    // focuser knob gear (large)
gear_teeth_small   = 10;    // motor pinion (small)
gear_width         = 8;     // gear face width
herring_angle      = 30;    // herringbone helix angle (degrees)

// Derived gear radii
gear_r_large       = (gear_module * gear_teeth_large) / 2;
gear_r_small       = (gear_module * gear_teeth_small) / 2;
centre_distance    = gear_r_large + gear_r_small;

// Electronics box (fits Arduino Nano ESP32 + ULN2003 board)
ebox_w             = 52;   // box inner width
ebox_h             = 28;   // box inner height
ebox_d             = 18;   // box inner depth
ebox_wall          = 2.5;
usb_cutout_w       = 12;   // USB-C cutout
usb_cutout_h       = 6;

// ── Module: D-shaft profile ───────────────────────────────────────────────────
module d_shaft(d, flat_chord, h) {
    flat_offset = d/2 - (d/2 - sqrt((d/2)^2 - (flat_chord/2)^2));
    intersection() {
        cylinder(d=d, h=h);
        translate([-d, -flat_chord/2, 0])
            cube([d + d/2 - flat_offset, flat_chord, h]);
    }
}

// ── Module: herringbone gear tooth profile (approximate involute) ─────────────
module herringbone_gear(teeth, mod, width, helix_deg, bore_d, bore_type="round") {
    pitch_r = (mod * teeth) / 2;
    addendum = mod;
    dedendum = 1.25 * mod;
    tooth_h  = addendum + dedendum;
    half_w   = width / 2;

    difference() {
        union() {
            // Approximate herringbone via two mirrored twisted extrusions
            for (half = [0, 1]) {
                mirror([0, 0, half])
                linear_extrude(height=half_w, twist=helix_deg, slices=8, convexity=4)
                    gear_2d_profile(teeth, mod);
            }
        }
        // Bore
        if (bore_type == "d_shaft") {
            translate([0, 0, -0.1])
                d_shaft(bore_d, bore_d * 0.6, width + 0.2);
        } else {
            translate([0, 0, -0.1])
                cylinder(d=bore_d + 0.2, h=width + 0.2);
        }
    }
}

// 2D gear profile (simplified involute approximation)
module gear_2d_profile(teeth, mod) {
    pitch_r  = (mod * teeth) / 2;
    add_r    = pitch_r + mod;
    ded_r    = pitch_r - 1.25 * mod;
    tooth_w  = PI * mod / 2;  // approximate tooth width at pitch circle

    difference() {
        circle(r=add_r);
        for (i = [0:teeth-1]) {
            rotate([0, 0, i * (360/teeth)])
                translate([0, ded_r, 0])
                    rotate([0, 0, 0])
                        square([tooth_w * 0.6, (add_r - ded_r) * 2.2], center=true);
        }
    }
    circle(r=ded_r);
}

// ── Module: motor pocket ──────────────────────────────────────────────────────
module motor_pocket() {
    union() {
        cylinder(d=motor_body_d + 0.4, h=motor_body_l);
        // shaft clearance
        translate([0, 0, -2])
            cylinder(d=motor_boss_d + 0.4, h=motor_boss_h + 2.2);
    }
}

// ── Module: M3 heat-set pocket ────────────────────────────────────────────────
module m3_heatset(h=6) {
    cylinder(d=4.5, h=h);  // 4.5 mm for M3 insert
}

// ── Module: M3 bolt clearance ─────────────────────────────────────────────────
module m3_clear(h=20) {
    cylinder(d=3.4, h=h);
}

// ── PART 1: Clamp body ────────────────────────────────────────────────────────
module clamp_body() {
    fw = focuser_body_w + clamp_wall * 2;
    fh = focuser_body_h + clamp_wall * 2;

    motor_offset_x = focuser_body_w/2 + clamp_wall + centre_distance;
    motor_offset_z = focuser_body_h/2; // centre of focuser shaft

    difference() {
        union() {
            // Main clamp block
            cube([fw, clamp_length, fh]);

            // Motor housing extension
            translate([fw, 0, motor_offset_z - motor_body_d/2 - clamp_wall])
                cube([motor_body_d + clamp_wall * 2, clamp_length, motor_body_d + clamp_wall * 2]);
        }

        // Focuser slot (open bottom for clamping)
        translate([clamp_wall, -1, clamp_wall])
            cube([focuser_body_w, clamp_length + 2, focuser_body_h + 5]);

        // Motor pocket in housing extension
        translate([fw + clamp_wall + motor_body_d/2, clamp_length/2, motor_offset_z]) {
            rotate([90, 0, 0])
                motor_pocket();
        }

        // Motor shaft hole through to gear space
        translate([fw + clamp_wall/2, clamp_length/2, motor_offset_z])
            rotate([90, 0, 0])
                cylinder(d=motor_boss_d + 1, h=clamp_length + 2, center=true);

        // Clamp split slot (bottom)
        translate([fw/2 - 1, -1, -1])
            cube([2, clamp_length + 2, clamp_wall + 2]);

        // M3 clamp bolt holes (side)
        for (pos = [clamp_length * 0.25, clamp_length * 0.75]) {
            translate([-1, pos, fh/2])
                rotate([0, 90, 0])
                    m3_clear(fw + motor_body_d + clamp_wall * 3 + 2);
        }

        // M3 heat-set pockets for lid
        for (pos = [clamp_length * 0.2, clamp_length * 0.8]) {
            translate([fw/4, pos, fh - 0.1])
                m3_heatset(6);
            translate([3*fw/4, pos, fh - 0.1])
                m3_heatset(6);
        }

        // USB cable routing notch (side)
        translate([fw + motor_body_d + clamp_wall * 2 - 1,
                   clamp_length/2 - usb_cutout_w/2,
                   motor_offset_z - usb_cutout_h/2])
            cube([4, usb_cutout_w, usb_cutout_h]);
    }
}

// ── PART 2: Clamp lid ─────────────────────────────────────────────────────────
module clamp_lid() {
    fw = focuser_body_w + clamp_wall * 2;
    fh = focuser_body_h + clamp_wall * 2;

    difference() {
        cube([fw, clamp_length, clamp_wall + 1]);

        // M3 lid bolt clearance (matching heat-sets in body)
        for (pos = [clamp_length * 0.2, clamp_length * 0.8]) {
            translate([fw/4, pos, -0.1])
                m3_clear(clamp_wall + 2);
            translate([3*fw/4, pos, -0.1])
                m3_clear(clamp_wall + 2);
        }
    }
}

// ── PART 3: Focuser knob gear (replaces coarse knob) ─────────────────────────
module focuser_knob_gear() {
    // Large herringbone gear with D-shaft bore for focuser shaft
    difference() {
        union() {
            // Gear body
            herringbone_gear(
                teeth      = gear_teeth_large,
                mod        = gear_module,
                width      = gear_width,
                helix_deg  = herring_angle,
                bore_d     = focuser_shaft_d,
                bore_type  = "d_shaft"
            );
            // Hub extension for grip and set-screw
            translate([0, 0, gear_width])
                cylinder(d=15, h=6);
        }
        // Set-screw hole (M3, radial)
        translate([0, 10, gear_width + 3])
            rotate([90, 0, 0])
                cylinder(d=2.5, h=12);  // M3 tapping size
        // Bore through hub
        translate([0, 0, gear_width - 0.1])
            d_shaft(focuser_shaft_d, focuser_shaft_d * 0.6, 7);
    }
}

// ── PART 4: Motor pinion ──────────────────────────────────────────────────────
module motor_pinion() {
    difference() {
        herringbone_gear(
            teeth      = gear_teeth_small,
            mod        = gear_module,
            width      = gear_width,
            helix_deg  = herring_angle,
            bore_d     = motor_shaft_d,
            bore_type  = "d_shaft"
        );
        // Set-screw (M2, radial, over the D-flat)
        translate([0, gear_r_small + 2, gear_width/2])
            rotate([90, 0, 0])
                cylinder(d=1.6, h=gear_r_small + 3);
    }
}

// ── PART 5: Electronics box ───────────────────────────────────────────────────
module electronics_box() {
    ew = ebox_w + ebox_wall * 2;
    eh = ebox_h + ebox_wall * 2;
    ed = ebox_d + ebox_wall;

    difference() {
        cube([ew, ed, eh]);

        // Interior cavity
        translate([ebox_wall, ebox_wall, ebox_wall])
            cube([ebox_w, ebox_d, ebox_h + 1]);

        // USB-C cutout in front face
        translate([ew/2 - usb_cutout_w/2, -0.1, eh/2 - usb_cutout_h/2])
            cube([usb_cutout_w, ebox_wall + 0.2, usb_cutout_h]);

        // Cable exit slot in rear
        translate([ew/2 - 6, ed - ebox_wall - 0.1, eh/2 - 4])
            cube([12, ebox_wall + 0.2, 8]);

        // Ventilation slots (top)
        for (i = [0:3]) {
            translate([ebox_wall + i * 11, ed/2, eh - 0.1])
                cube([6, 6, ebox_wall + 0.2]);
        }

        // M3 lid heat-sets
        for (x = [ebox_wall + 4, ew - ebox_wall - 4]) {
            for (y = [4, ed - 4]) {
                translate([x, y, eh - 0.1])
                    m3_heatset(4);
            }
        }
    }
}

// ── PART 6: Electronics lid ───────────────────────────────────────────────────
module electronics_lid() {
    ew = ebox_w + ebox_wall * 2;
    ed = ebox_d + ebox_wall;

    difference() {
        cube([ew, ed, ebox_wall + 1]);

        for (x = [ebox_wall + 4, ew - ebox_wall - 4]) {
            for (y = [4, ed - 4]) {
                translate([x, y, -0.1])
                    m3_clear(ebox_wall + 2);
            }
        }
    }
}

// ── Render selection — comment/uncomment as needed ────────────────────────────
// All parts laid out for review:

clamp_body();

translate([0, 0, -15])
    clamp_lid();

translate([100, 0, 0])
    focuser_knob_gear();

translate([130, 0, 0])
    motor_pinion();

translate([0, 60, 0])
    electronics_box();

translate([0, 60, -15])
    electronics_lid();

// ── Notes for printing ────────────────────────────────────────────────────────
// 1. Clamp body: flat back face down, no supports. Clamp slot faces down.
// 2. Gears: flat face down, no supports.
// 3. Electronics box: open top up, no supports.
// 4. PETG settings: 235-245°C nozzle, 70-80°C bed, 30-40 mm/s for walls.
//    Reduce speed to 20 mm/s for first layer on bed.
// 5. Heat-set inserts: use soldering iron at 180-200°C, press in slowly.
// 6. After printing: test-fit on focuser before inserting heat-sets.
//    The clamp slot width may need filing by 0.2-0.5 mm depending on your
//    printer's first-layer squish.
