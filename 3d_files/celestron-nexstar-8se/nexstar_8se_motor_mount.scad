// ============================================================================
// Celestron NexStar 8SE — 28BYJ-48 Motor Focuser Mount   (rev 2 — corrected)
// ============================================================================
//
// REV 2 CHANGES (pre-print geometry review):
//   - Centre distance fixed: was pitch radii + focus_shaft_od/2 — a 6.55 mm
//     gap meaning the gears never touched. Now exactly the pitch radii sum.
//   - Large gear reduced 36T -> 24T. A 36T gear (Ø60 mm) collides with the
//     mounting bosses on the fixed 52 mm bolt circle. 24T (Ø39) clears them.
//   - Added 14 mm standoff bosses at the 3 bolt positions, creating a gear
//     chamber between the rear cell and the plate. Previously the plate sat
//     flush with nowhere for the gear to rotate.
//   - Motor now recessed into the plate, shaft pointing DOWN into the gear
//     chamber so pinion and gear are coplanar. M2 heat-sets that previously
//     floated above the housing removed; motor retained by two horizontal
//     M3 self-tap pinch screws through the housing wall.
//   - Sleeve compression slot changed to a single-sided slit; grub screw
//     moved to the opposite side (previously drilled through the slot).
//   - gear_width 8 -> 6 mm to suit the 28BYJ-48 shaft length through the plate.
//
// MEASURE focus_shaft_od WITH CALIPERS BEFORE PRINTING. Default 13.1 mm.
//
// Print:  PETG · 0.2 mm · 4 walls · 30% (45% gears) · no supports
//         Plate: flat top face DOWN on bed (standoffs point up as printed).
//         Sleeve: gear face down. Pinion: flat face down.
// ============================================================================

$fn = 72;

// ── Rear cell (fixed by the telescope) ──────────────────────────────────────
rear_cell_plate_d = 85.0;
cover_bolt_circle = 52.0;   // PCD of the 3 cover screws — fixed
cover_bolt_count  = 3;
plate_t           = 4.0;
standoff_h        = 14.0;   // gear chamber height
standoff_d        = 10.0;

// ── Focus shaft — VERIFY ─────────────────────────────────────────────────────
focus_shaft_od    = 13.1;
focus_shaft_gap   = 0.15;
sleeve_hub_l      = 7;      // hub below gear (grub screw lives here)

// ── Motor (28BYJ-48) ─────────────────────────────────────────────────────────
motor_body_d      = 28.2;
motor_body_l      = 19.5;
motor_shaft_d     = 5.0;
motor_boss_d      = 10.2;

// ── Gears ────────────────────────────────────────────────────────────────────
gear_module       = 1.5;
gear_teeth_large  = 24;     // rev2: was 36 — see notes above
gear_teeth_small  = 10;
gear_width        = 6;
herring_angle     = 30;

gear_r_large      = (gear_module * gear_teeth_large) / 2;  // 18.0
gear_r_small      = (gear_module * gear_teeth_small) / 2;  //  7.5
centre_distance   = gear_r_large + gear_r_small;           // 25.5

motor_cx          = centre_distance;   // motor axis X (shaft at origin)

// ── Electronics box ──────────────────────────────────────────────────────────
ebox_w = 52;  ebox_h = 28;  ebox_d = 18;  ebox_wall = 2.5;
usb_w  = 12;  usb_h  = 6;

// ── Helpers ──────────────────────────────────────────────────────────────────
module m3_heatset(h=6) { cylinder(d=4.5, h=h); }
module m3_clear(h=20)  { cylinder(d=3.4, h=h); }
module m3_selftap(h=8) { cylinder(d=2.8, h=h); }

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

module hb_gear(teeth, mod, width, helix) {
    half = width / 2;
    tw   = hb_twist(teeth, mod, half, helix);
    translate([0, 0, half])
        for (h = [0, 1]) mirror([0, 0, h])
            linear_extrude(height=half, twist=tw, slices=6, convexity=6)
                gear_2d(teeth, mod);
}

// ── PART 1: Rear-cell motor plate ─────────────────────────────────────────────
// z=0 is the plate underside. Standoffs extend z = -standoff_h .. 0 and rest
// on the rear cell. Gear chamber occupies that gap. Motor sits in the housing
// above the plate, shaft pointing down through it into the chamber.
module rear_cell_plate() {
    housing_od = motor_body_d + 12;
    housing_h  = plate_t + 2 + motor_body_l;   // pocket floor 2 mm above plate base

    difference() {
        union() {
            cylinder(d=rear_cell_plate_d, h=plate_t);
            // Motor housing
            translate([motor_cx, 0, 0]) cylinder(d=housing_od, h=housing_h);
        }

        // Focus shaft clearance through plate centre
        translate([0, 0, -1])
            cylinder(d=focus_shaft_od + 1.5, h=housing_h + 2);

        // Motor pocket — opens at the top, 2 mm floor above plate base
        translate([motor_cx, 0, plate_t + 2])
            cylinder(d=motor_body_d + 0.4, h=motor_body_l + 2);

        // Boss + shaft passage down through the floor into the chamber
        translate([motor_cx, 0, -1])
            cylinder(d=motor_boss_d, h=plate_t + 3 + 1);

        // Motor pinch screws — 2 × M3 self-tap, horizontal, through housing wall
        for (a = [90, 270])
            translate([motor_cx + cos(a)*(housing_od/2 + 1),
                       sin(a)*(housing_od/2 + 1),
                       plate_t + 2 + motor_body_l/2])
                rotate([0, 90, 0]) rotate([0, 0, a])
                    translate([0, 0, -housing_od/2 - 2]) m3_selftap(housing_od/2 + 3);

        // Cover bolts — through the plate (standoffs are separate spacers)
        for (i = [0:cover_bolt_count-1]) {
            a = i * 120 + 60;
            translate([cos(a)*cover_bolt_circle/2, sin(a)*cover_bolt_circle/2, -1])
                m3_clear(plate_t + 2);
        }

        // Electronics box attachment heat-sets, plate edge
        for (y = [-12, 12])
            translate([-rear_cell_plate_d/2 + 6, y, plate_t - 0.1])
                rotate([180, 0, 0]) m3_heatset(6);
    }
}

// ── PART 1b: Standoff spacer — PRINT 3 ───────────────────────────────────────
// Separate spacers so the plate prints flat with no supports.
module standoff_spacer() {
    difference() {
        cylinder(d=standoff_d, h=standoff_h);
        translate([0, 0, -1]) m3_clear(standoff_h + 2);
    }
}

// ── PART 2: Friction sleeve + gear (lives in the chamber) ────────────────────
// z=0 = gear bottom face (on the bed). Hub sits ABOVE the gear — no
// overhangs, no supports. In the chamber the hub faces the plate; it clears
// the pinion (hub r 9.7 vs nearest pinion point 16.5 from the shaft axis).
module friction_sleeve_with_gear() {
    sleeve_od = focus_shaft_od + focus_shaft_gap*2 + 6;
    bore_d    = focus_shaft_od + focus_shaft_gap*2;

    difference() {
        union() {
            hb_gear(gear_teeth_large, gear_module, gear_width, herring_angle);
            translate([0, 0, gear_width]) cylinder(d=sleeve_od, h=sleeve_hub_l);
        }
        // Bore
        translate([0, 0, -0.1])
            cylinder(d=bore_d, h=sleeve_hub_l + gear_width + 0.2);
        // Compression slit — hub only, ONE side (+Y)
        translate([-0.8, 0, gear_width - 0.1])
            cube([1.6, sleeve_od/2 + 1, sleeve_hub_l + 0.2]);
        // M3 grub — opposite side (-Y), into the hub
        translate([0, -(sleeve_od/2 + 2), gear_width + sleeve_hub_l/2])
            rotate([-90, 0, 0]) cylinder(d=2.5, h=sleeve_od/2 + 3);
    }
}

// ── PART 3: Motor pinion ──────────────────────────────────────────────────────
module motor_pinion() {
    difference() {
        hb_gear(gear_teeth_small, gear_module, gear_width, herring_angle);
        translate([0, 0, -0.1]) d_shaft(motor_shaft_d, 1.2, gear_width + 0.2);
        translate([0, gear_r_small + 2, gear_width/2])
            rotate([90, 0, 0]) cylinder(d=1.6, h=gear_r_small + 3);
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
rear_cell_plate();
translate([60, 60, 0]) standoff_spacer();
translate([75, 60, 0]) standoff_spacer();
translate([90, 60, 0]) standoff_spacer();
translate([120, 0, 0]) friction_sleeve_with_gear();
translate([170, 0, 0]) motor_pinion();
translate([0, 110, 0]) electronics_box();
translate([70, 110, 0]) electronics_lid();

// ── Assembly ─────────────────────────────────────────────────────────────────
// 1. Pull off the rubber focus knob; remove the 3 cover screws.
// 2. Slide the sleeve (hub first, toward the rear cell) onto the focus shaft.
//    Tighten the M3 grub against the shaft flat.
// 3. Fit the pinion to the motor D-shaft. Drop the motor into the housing,
//    shaft down; the pinion hangs in the chamber. Nip up the two M3 pinch
//    screws against the motor body.
// 4. Offer the plate up so the pinion meshes with the gear; the three spacers sit
//    between plate and rear cell. Fit the 3 cover screws through plate + spacers — you
//    will need M3 screws ~20 mm longer than the originals (standoff adds
//    14 mm). Check backlash: just measurable, not tight.
// 5. Fit the electronics box to the edge heat-sets.
