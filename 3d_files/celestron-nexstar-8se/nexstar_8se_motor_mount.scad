// ============================================================================
// Celestron NexStar 8SE — 28BYJ-48 Motor Focuser Mount
// ============================================================================
//
// Telescope:   Celestron NexStar 8SE (Schmidt-Cassegrain)
// Focuser:     Mirror-shift SCT focuser
//              Focus shaft OD: ~13.1 mm (0.515") — knurled rubber knob pull-off
//              Rear cell: 3-screw cover plate, triangular-pattern back cell
//              Cover plate screws: M3 / #6-32, on a ~52 mm bolt circle
//              Rear cell flange OD: ~100 mm
//
// Motor:       28BYJ-48 (body Ø28 mm, shaft Ø5 mm D-type)
// Design:      Rear-cell plate replacement. The stock 3-screw cover plate is
//              removed. This part replaces it, incorporating:
//              - Motor housing with 28BYJ-48 pocket
//              - Herringbone drive gear for the focus shaft
//              - Motor pinion
//              - Side electronics box for Nano ESP32 + ULN2003
//
// IMPORTANT — SCT mirror focuser shaft note:
//   The focus shaft on the 8SE is the threaded brass tube that the rubber
//   knob sits on. It is ~13 mm OD. Rather than a gear coupling directly on
//   the brass thread (which would damage it), this design uses a friction
//   coupling sleeve that slips over the shaft and is locked with one M3
//   grub screw against the flat on the shaft.
//   MEASURE YOUR SHAFT before printing — some production runs vary ±0.5 mm.
//   Adjust `focus_shaft_od` below.
//
// Print:       PETG, 0.2 mm layers, 4 perimeters, 30% infill
//              Motor plate: flat face down, no supports
//              Gears: flat face down, no supports
//
// Hardware:    M3×12 socket cap (×3) — replaces rear-cell cover screws
//              M3×6  socket cap (×4) — electronics box screws
//              M3 heat-set insert (×7)
//              M2×8  socket cap (×2) — motor mounting
//              M2 heat-set insert (×4)
//              M3 grub/set screw (×1) — friction sleeve clamp
//
// ============================================================================

$fn = 72;

// ── Key dimensions ────────────────────────────────────────────────────────────
// Rear cell geometry
rear_cell_flange_od  = 100.0;  // rear cell flange outer diameter
rear_cell_plate_d    = 85.0;   // cover plate OD (inner shoulder register)
cover_bolt_circle    = 52.0;   // PCD of the 3 cover-plate screws
cover_bolt_d         = 3.4;    // M3 clearance
cover_bolt_count     = 3;      // always 3 on NexStar 8SE
plate_thickness      = 4.0;    // base plate thickness

// Focus shaft geometry
focus_shaft_od       = 13.1;   // shaft OD — VERIFY ON YOUR SCOPE
focus_shaft_sleeve_l = 18;     // length of friction sleeve
focus_shaft_gap      = 0.15;   // clearance on sleeve bore (tight slip fit)

// Motor geometry (28BYJ-48)
motor_body_d         = 28.2;
motor_body_l         = 19.5;
motor_shaft_d        = 5.0;
motor_boss_d         = 9.5;
motor_boss_h         = 1.5;
motor_hole_pitch     = 35;

// Gear
gear_module          = 1.5;
gear_teeth_large     = 36;
gear_teeth_small     = 10;
gear_width           = 8;
herring_angle        = 30;

gear_r_large         = (gear_module * gear_teeth_large) / 2;
gear_r_small         = (gear_module * gear_teeth_small) / 2;
centre_distance      = gear_r_large + gear_r_small;

// Motor plate geometry — motor positioned tangentially to focus shaft axis
// SCT focus shaft is centred in the rear cell (offset from plate centre)
focus_shaft_centre_x =  0;    // shaft is on scope optical axis (plate centre)
focus_shaft_centre_y =  0;

motor_centre_x       = gear_r_large + gear_r_small + focus_shaft_od/2;
motor_centre_y       = 0;

// Electronics box
ebox_w               = 52;
ebox_h               = 28;
ebox_d               = 18;
ebox_wall            = 2.5;
usb_w                = 12;
usb_h                = 6;

// ── Helper modules ─────────────────────────────────────────────────────────────
module m3_heatset(h=6)  { cylinder(d=4.5, h=h); }
module m3_clear(h=20)   { cylinder(d=3.4, h=h); }
module m2_clear(h=10)   { cylinder(d=2.4, h=h); }
module m2_heatset(h=4)  { cylinder(d=3.5, h=h); }

module d_shaft_profile(od, flat_depth, h) {
    // flat_depth = depth of the D-flat from the outer surface
    intersection() {
        cylinder(d=od, h=h);
        translate([-(od/2 - flat_depth), -od/2, 0])
            cube([od, od, h]);
    }
}

// ── Module: herringbone gear 2D profile (spur involute approximation) ─────────
module gear_2d(teeth, mod) {
    pitch_r = (mod * teeth) / 2;
    add_r   = pitch_r + mod;
    ded_r   = pitch_r - 1.25 * mod;
    step    = 360 / teeth;

    difference() {
        circle(r=add_r);
        for (i = [0:teeth-1]) {
            rotate([0, 0, i * step + step/2])
                translate([0, ded_r + (add_r - ded_r)/2, 0])
                    rotate([0, 0, 18])
                        ellipse_approx(
                            (add_r - ded_r) * 0.85,
                            (add_r - ded_r) * 1.1
                        );
        }
    }
    circle(r=ded_r);  // dedendum circle fill
}

module ellipse_approx(rx, ry) {
    scale([rx, ry]) circle(r=1);
}

// ── Module: herringbone gear body ─────────────────────────────────────────────
module hb_gear(teeth, mod, width, helix) {
    half = width / 2;
    for (h = [0, 1]) mirror([0, 0, h])
        linear_extrude(height=half, twist=helix, slices=8, convexity=6)
            gear_2d(teeth, mod);
}

// ── PART 1: Rear-cell motor plate ─────────────────────────────────────────────
module rear_cell_plate() {
    wall_h = plate_thickness + gear_width + 6;  // tall enough for motor housing

    difference() {
        union() {
            // Main circular plate
            cylinder(d=rear_cell_plate_d, h=plate_thickness);

            // Motor housing boss
            translate([motor_centre_x, motor_centre_y, 0])
                cylinder(d=motor_body_d + 8, h=wall_h);

            // Gear bridge (connects shaft centre to motor boss)
            hull() {
                translate([focus_shaft_centre_x, focus_shaft_centre_y, 0])
                    cylinder(d=focus_shaft_od + 14, h=wall_h * 0.6);
                translate([motor_centre_x, motor_centre_y, 0])
                    cylinder(d=motor_body_d + 8, h=wall_h * 0.6);
            }
        }

        // Focus shaft clearance (friction sleeve passes through plate)
        translate([focus_shaft_centre_x, focus_shaft_centre_y, -1])
            cylinder(d=focus_shaft_od + focus_shaft_gap * 2 + 1, h=wall_h + 2);

        // Motor pocket
        translate([motor_centre_x, motor_centre_y, plate_thickness + 2])
            cylinder(d=motor_body_d + 0.4, h=motor_body_l + 2);

        // Motor boss clearance
        translate([motor_centre_x, motor_centre_y, plate_thickness])
            cylinder(d=motor_boss_d + 0.4, h=motor_boss_h + 1);

        // Motor shaft hole
        translate([motor_centre_x, motor_centre_y, -1])
            cylinder(d=motor_boss_d + 1, h=plate_thickness + 2);

        // Cover plate bolt holes (3 screws on PCD)
        for (i = [0:cover_bolt_count-1]) {
            angle = i * (360 / cover_bolt_count) + 60;  // offset to clear motor
            translate([
                cos(angle) * cover_bolt_circle/2,
                sin(angle) * cover_bolt_circle/2,
                -1
            ])
                m3_clear(plate_thickness + 2);
        }

        // Motor mounting holes (M2, on 28BYJ-48 35 mm pitch)
        for (i = [0:1]) {
            rotate([0, 0, i * 180])
            translate([motor_centre_x + motor_hole_pitch/2, motor_centre_y,
                       plate_thickness + motor_body_l + 1.5])
                rotate([180, 0, 0])
                    m2_heatset(4);
        }

        // Electronics box attachment screws (side)
        translate([rear_cell_plate_d/2 - 2, -ebox_w/4, plate_thickness + wall_h/2 - 5])
            rotate([0, 90, 0])
                for (z = [0, ebox_h/2]) {
                    translate([z, 0, 0])
                        m3_heatset(6);
                }
    }
}

// ── PART 2: Friction sleeve (slips over SCT focus shaft) ─────────────────────
// This replaces the rubber focus knob. The large herringbone gear is integrated
// onto this sleeve. The motor drives the gear; the sleeve turns the focus shaft.
module friction_sleeve_with_gear() {
    sleeve_od = focus_shaft_od + focus_shaft_gap * 2 + 6;  // outer of sleeve

    difference() {
        union() {
            // Gear portion
            hb_gear(gear_teeth_large, gear_module, gear_width, herring_angle);

            // Sleeve hub (below gear)
            translate([0, 0, -focus_shaft_sleeve_l])
                cylinder(d=sleeve_od, h=focus_shaft_sleeve_l);

            // Top cap
            translate([0, 0, gear_width])
                cylinder(d=sleeve_od, h=4);
        }

        // Bore (shaft clearance)
        translate([0, 0, -focus_shaft_sleeve_l - 0.1])
            cylinder(d=focus_shaft_od + focus_shaft_gap * 2,
                     h=focus_shaft_sleeve_l + gear_width + 4 + 0.2);

        // Grub screw hole (M3, radial, at sleeve midpoint)
        translate([0, sleeve_od/2 + 2, -focus_shaft_sleeve_l/2])
            rotate([90, 0, 0])
                cylinder(d=2.5, h=sleeve_od/2 + 3);  // M3 tapping

        // Slot to allow slight compression (clamp action)
        translate([-0.8, -sleeve_od/2, -focus_shaft_sleeve_l - 0.1])
            cube([1.6, sleeve_od, focus_shaft_sleeve_l + 0.2]);
    }
}

// ── PART 3: Motor pinion ──────────────────────────────────────────────────────
module motor_pinion() {
    difference() {
        hb_gear(gear_teeth_small, gear_module, gear_width, herring_angle);

        // D-shaft bore (motor shaft)
        translate([0, 0, -0.1])
            d_shaft_profile(motor_shaft_d, 1.2, gear_width + 0.2);

        // M2 grub screw hole
        translate([0, gear_r_small + 2, gear_width/2])
            rotate([90, 0, 0])
                cylinder(d=1.6, h=gear_r_small + 3);
    }
}

// ── PART 4: Electronics box (identical design to RVO version) ─────────────────
module electronics_box() {
    ew = ebox_w + ebox_wall * 2;
    eh = ebox_h + ebox_wall * 2;
    ed = ebox_d + ebox_wall;

    difference() {
        cube([ew, ed, eh]);
        translate([ebox_wall, ebox_wall, ebox_wall])
            cube([ebox_w, ebox_d, ebox_h + 1]);
        // USB-C
        translate([ew/2 - usb_w/2, -0.1, eh/2 - usb_h/2])
            cube([usb_w, ebox_wall + 0.2, usb_h]);
        // Cable exit
        translate([ew/2 - 6, ed - ebox_wall - 0.1, eh/2 - 4])
            cube([12, ebox_wall + 0.2, 8]);
        // Vents
        for (i = [0:3])
            translate([ebox_wall + i * 11, ed/2, eh - 0.1])
                cube([6, 6, ebox_wall + 0.2]);
        // Lid inserts
        for (x = [ebox_wall + 4, ew - ebox_wall - 4])
            for (y = [4, ed - 4])
                translate([x, y, eh - 0.1])
                    m3_heatset(4);
    }
}

module electronics_lid() {
    ew = ebox_w + ebox_wall * 2;
    ed = ebox_d + ebox_wall;
    difference() {
        cube([ew, ed, ebox_wall + 1]);
        for (x = [ebox_wall + 4, ew - ebox_wall - 4])
            for (y = [4, ed - 4])
                translate([x, y, -0.1])
                    m3_clear(ebox_wall + 2);
    }
}

// ── Render ────────────────────────────────────────────────────────────────────
rear_cell_plate();

translate([120, 0, 0])
    friction_sleeve_with_gear();

translate([160, 0, 0])
    motor_pinion();

translate([0, 120, 0])
    electronics_box();

translate([0, 120, -15])
    electronics_lid();

// ── Notes ─────────────────────────────────────────────────────────────────────
// Installation order:
// 1. Remove rubber focus knob (just pull off).
// 2. Remove the 3-screw cover plate from the rear cell.
// 3. Thread the friction sleeve onto the focus shaft until it sits flush
//    where the knob used to be.
// 4. Install rear-cell motor plate, aligning gear mesh. Reuse the 3 cover
//    screws. Check gear backlash — should be just measurable, not tight.
// 5. Tighten the M3 grub screw on the sleeve against the shaft flat.
// 6. Attach electronics box to the side pegs.
// 7. Connect motor leads to ULN2003 board; USB-C to Nano ESP32.
//
// Gear mesh note: The gear centre distance is calculated from the gear module.
// If your mesh is too tight or too loose, adjust `gear_module` by ±0.1 and
// reprint. The herringbone pattern self-centres under load.
