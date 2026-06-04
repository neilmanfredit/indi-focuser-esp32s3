// ============================================================================
// SkyWatcher Explorer 200P — 28BYJ-48 Motor Focuser Mount
// ============================================================================
//
// Telescope:   SkyWatcher Explorer 200P (200mm f/6 Newtonian reflector)
// Focuser:     Single-speed Crayford (rack-and-pinion on some units)
//              The 200P ships with a 2" single-speed Crayford focuser.
//              Focuser body outer width: ~76 mm
//              Coarse knob shaft: ~8 mm round, M4 grub-screw secured
//              Focuser body depth (front-to-back, optical axis): ~34 mm
//              Standard Skywatcher Crayford focuser knob rubber OD: ~25.5 mm
//
// Motor:       28BYJ-48 (body Ø28 mm, 5V, shaft Ø5 mm D-type)
// Design:      Non-invasive bracket. One of the two coarse focus knobs is
//              removed. The bracket replaces it on the focuser shaft.
//              The motor sits beside the bracket and drives a gear glued to
//              the focuser knob shaft.
//
//              This is the simplest, most reversible design — no glue, no
//              permanent modification to the focuser.
//
// Print:       PETG, 0.2 mm layers, 4 perimeters, 25%+ infill
//              Motor bracket: flat mounting face down, no supports needed
//              Gears: flat down, no supports
//
// Hardware:    M3×20 socket cap (×1) — replaces focuser knob retaining screw
//              M3×10 socket cap (×2) — bracket to focuser body
//              M3 heat-set insert (×4)
//              M2×8  socket cap (×2) — motor PCB mounting
//              M2 heat-set insert (×4)
//              M3 grub screw ×1 — drive gear clamp
//
// ============================================================================

$fn = 64;

// ── Focuser body dimensions ────────────────────────────────────────────────────
focuser_body_w     = 76;    // outer width of Crayford focuser body
focuser_body_h     = 40;    // outer height (top to bottom of body)
focuser_body_d     = 34;    // depth (front to back, along optical axis)
focuser_shaft_d    = 8.2;   // focuser knob shaft OD (clearance)
knob_rubber_od     = 25.5;  // original rubber knob OD

// Wall and clamp
clamp_wall         = 4.0;
clamp_depth        = 20;    // how much of the focuser body the clamp grips

// Motor geometry (28BYJ-48)
motor_body_d       = 28.2;
motor_body_l       = 19.5;
motor_shaft_d      = 5.0;
motor_boss_d       = 9.5;
motor_boss_h       = 1.5;
motor_hole_pitch   = 35;    // 28BYJ-48 mounting hole PCD

// Gear dimensions
gear_module        = 1.5;
gear_teeth_drive   = 32;    // gear on focuser knob shaft
gear_teeth_pinion  = 10;    // gear on motor shaft
gear_width         = 8;
herring_angle      = 30;

gear_r_drive       = (gear_module * gear_teeth_drive) / 2;
gear_r_pinion      = (gear_module * gear_teeth_pinion) / 2;
centre_dist        = gear_r_drive + gear_r_pinion;

// Electronics box
ebox_w             = 52;
ebox_h             = 28;
ebox_d             = 18;
ebox_wall          = 2.5;
usb_w              = 12;
usb_h              = 6;

// ── Helper modules ─────────────────────────────────────────────────────────────
module m3_heatset(h=6)  { cylinder(d=4.5, h=h); }
module m3_clear(h=20)   { cylinder(d=3.4, h=h); }
module m2_clear(h=10)   { cylinder(d=2.4, h=h); }
module m2_heatset(h=4)  { cylinder(d=3.5, h=h); }

module d_shaft_profile(od, flat_depth, h) {
    intersection() {
        cylinder(d=od, h=h);
        translate([-(od/2 - flat_depth), -od/2, 0])
            cube([od, od, h]);
    }
}

// ── 2D involute gear approximation ────────────────────────────────────────────
module gear_2d(teeth, mod) {
    pitch_r = (mod * teeth) / 2;
    add_r   = pitch_r + mod;
    ded_r   = pitch_r - 1.25 * mod;
    step    = 360 / teeth;

    difference() {
        circle(r=add_r);
        for (i = [0:teeth-1]) {
            rotate([0, 0, i * step + step/2])
                translate([0, ded_r + (add_r - ded_r)/2])
                    scale([(add_r-ded_r)*0.45, (add_r-ded_r)*0.6])
                        circle(r=1);
        }
    }
    circle(r=ded_r);
}

// ── Herringbone gear body ─────────────────────────────────────────────────────
module hb_gear(teeth, mod, width, helix) {
    half = width/2;
    for (h = [0,1]) mirror([0,0,h])
        linear_extrude(height=half, twist=helix, slices=8, convexity=6)
            gear_2d(teeth, mod);
}

// ── PART 1: Side-bracket motor mount ─────────────────────────────────────────
// This mounts to the side of the focuser body (where one knob was removed).
// It positions the motor so the gears mesh at the correct centre distance.
module motor_bracket() {
    // Bracket body dimensions
    bw = motor_body_d + clamp_wall * 2 + 10;  // bracket width
    bh = focuser_body_h + clamp_wall;           // bracket height
    bd = clamp_depth;                            // bracket depth (grip on focuser)

    // Motor is positioned so its shaft is at centre_dist from focuser shaft
    // Focuser shaft is at [focuser_body_w/2, 0] (left face of focuser)
    // The bracket attaches to the left face, so in our local coords
    // focuser shaft is at x=0 and motor shaft is at x=centre_dist
    motor_x = centre_dist;
    motor_z = focuser_body_h / 2;  // vertically centred on focuser

    difference() {
        union() {
            // Flat face plate (mounts to focuser side)
            cube([clamp_wall, bd, bh]);

            // Motor housing
            translate([clamp_wall, bd/2, motor_z])
                rotate([90, 0, 0])
                    cylinder(d=motor_body_d + 8, h=bd + 0.001, center=true);

            // Structural web between face plate and motor housing
            translate([0, 0, motor_z - motor_body_d/2 - clamp_wall/2])
                cube([motor_x + motor_body_d/2 + clamp_wall, bd, motor_body_d + clamp_wall]);
        }

        // Motor pocket (from the right side)
        translate([motor_x + motor_body_d/2 + clamp_wall, bd/2, motor_z])
            rotate([90, 0, 0])
                cylinder(d=motor_body_d + 0.4, h=motor_body_l + 2, center=true);

        // Motor shaft clearance hole (through to gear side)
        translate([-1, bd/2, motor_z])
            rotate([0, 90, 0])
                cylinder(d=motor_boss_d + 1, h=motor_x + motor_body_d + clamp_wall * 2 + 2);

        // Motor boss recess (front of motor)
        translate([clamp_wall + motor_body_l - motor_boss_h, bd/2, motor_z])
            rotate([90, 0, 0])
                cylinder(d=motor_boss_d + 0.4, h=bd + 2, center=true);

        // Motor mounting holes (M2 heat-set, front face of motor pocket)
        for (i = [-1, 1]) {
            translate([motor_x - 2, bd/2 + i * motor_hole_pitch/2, motor_z])
                rotate([0, 90, 0])
                    m2_heatset(5);
        }

        // Focuser body face-plate screw holes (M3 clearance into focuser body)
        // These go through the flat face plate into M3 holes you tap in the focuser
        for (pos = [bd * 0.25, bd * 0.75]) {
            translate([-0.1, pos, bh/2])
                rotate([0, 90, 0])
                    m3_clear(clamp_wall + 1);
        }

        // Cable routing slot
        translate([motor_x, bd - 3, motor_z - usb_h/2])
            cube([usb_w, 4, usb_h]);
    }
}

// ── PART 2: Drive gear (slips on focuser knob shaft) ─────────────────────────
// Herringbone gear with hub; replaces the focus knob.
// The focuser knob shaft has an M4 grub-screw hole — the hub here uses an
// M3 radial grub screw to clamp against the shaft.
module drive_gear() {
    hub_h = 10;  // extra hub below gear for grip

    difference() {
        union() {
            // Herringbone gear body
            hb_gear(gear_teeth_drive, gear_module, gear_width, herring_angle);

            // Lower hub (grips the shaft)
            translate([0, 0, -hub_h])
                cylinder(d=14, h=hub_h);

            // Upper grip cap
            translate([0, 0, gear_width])
                cylinder(d=14, h=5);
        }

        // Shaft bore (full height)
        translate([0, 0, -hub_h - 0.1])
            cylinder(d=focuser_shaft_d, h=gear_width + hub_h + 5 + 0.2);

        // Grub screw hole (M3, radial, into lower hub, aimed at shaft flat)
        translate([0, 10, -hub_h/2])
            rotate([90, 0, 0])
                cylinder(d=2.5, h=12);   // M3 tap size

        // Grip texture slots (top cap)
        for (i = [0:7]) {
            rotate([0, 0, i * 45])
                translate([5, 0, gear_width + 0.5])
                    cube([2, 1.5, 5]);
        }
    }
}

// ── PART 3: Motor pinion ──────────────────────────────────────────────────────
module motor_pinion() {
    difference() {
        hb_gear(gear_teeth_pinion, gear_module, gear_width, herring_angle);

        // D-shaft bore
        translate([0, 0, -0.1])
            d_shaft_profile(motor_shaft_d, 1.2, gear_width + 0.2);

        // M2 grub screw
        translate([0, gear_r_pinion + 2, gear_width/2])
            rotate([90, 0, 0])
                cylinder(d=1.6, h=gear_r_pinion + 3);
    }
}

// ── PART 4: Electronics box ───────────────────────────────────────────────────
module electronics_box() {
    ew = ebox_w + ebox_wall * 2;
    eh = ebox_h + ebox_wall * 2;
    ed = ebox_d + ebox_wall;

    difference() {
        cube([ew, ed, eh]);
        translate([ebox_wall, ebox_wall, ebox_wall])
            cube([ebox_w, ebox_d, ebox_h + 1]);
        translate([ew/2 - usb_w/2, -0.1, eh/2 - usb_h/2])
            cube([usb_w, ebox_wall + 0.2, usb_h]);
        translate([ew/2 - 6, ed - ebox_wall - 0.1, eh/2 - 4])
            cube([12, ebox_wall + 0.2, 8]);
        for (i = [0:3])
            translate([ebox_wall + i * 11, ed/2, eh - 0.1])
                cube([6, 6, ebox_wall + 0.2]);
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
motor_bracket();

translate([100, 0, 0])
    drive_gear();

translate([140, 0, 0])
    motor_pinion();

translate([0, 80, 0])
    electronics_box();

translate([0, 80, -15])
    electronics_lid();

// ── Notes ─────────────────────────────────────────────────────────────────────
// Installation:
// 1. Loosen the M4 grub screw on ONE of the two coarse focus knobs.
//    Slide the knob off the shaft. The other knob (opposite side) stays on.
//
// 2. Slide the drive_gear onto the vacated shaft, align the flat in the
//    bore with the shaft flat, and tighten the M3 grub screw firmly.
//
// 3. Attach the motor_bracket to the focuser body side plate. You can use
//    two M3 screws through the face plate holes into the focuser body
//    (tap M3 in the focuser body side wall if no holes are present), OR
//    use a cable tie through the bracket holes around the focuser body.
//
// 4. Slide the motor into the motor pocket from the focuser side.
//    Secure with two M2 screws into the heat-set inserts.
//
// 5. Slide the motor_pinion onto the motor D-shaft. Adjust axial position
//    so it aligns with the drive_gear, then tighten the M2 grub screw.
//
// 6. Check gear mesh — should be smooth with minimal backlash.
//    If tight: add 0.1 mm to `centre_dist` and reprint bracket.
//    If loose: reduce `centre_dist` by 0.1 mm.
//
// 7. Attach electronics box, route motor cable and USB-C.
//
// PETG note: PETG is slightly flexible which helps the gears self-align.
// Do not use PLA outdoors — it becomes brittle in cold UK weather and
// warps if left in direct sunlight in summer.
