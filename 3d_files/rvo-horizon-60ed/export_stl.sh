#!/usr/bin/env bash
# =============================================================================
# export_stl.sh
# RVO Horizon 60 ED — Export all parts to STL via OpenSCAD CLI
#
# Usage:
#   chmod +x export_stl.sh
#   ./export_stl.sh
#
# Requirements:
#   OpenSCAD must be installed and on your PATH.
#
#   Linux (Arch/Garuda):  sudo pacman -S openscad
#   Linux (Debian/Ubuntu): sudo apt install openscad
#   Or download from: https://openscad.org/downloads.html
#
# Output:
#   STL files are written to ./stl/
#   Each file is named for the part and includes print orientation notes.
#
# OpenSCAD CLI flags used:
#   -o <file>         output file path
#   --export-format binstl   binary STL (smaller, faster to import)
#   --render          force full render (equivalent to F6 in the GUI)
#   -D 'var=value'    override a SCAD variable from the command line
# =============================================================================

set -euo pipefail

SCAD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/scad"
STL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/stl"

mkdir -p "$STL_DIR"

# Detect OpenSCAD binary name (differs between platforms/snap installs)
if command -v openscad &>/dev/null; then
    OPENSCAD="openscad"
elif command -v openscad-nightly &>/dev/null; then
    OPENSCAD="openscad-nightly"
else
    echo "ERROR: OpenSCAD not found. Install it first:"
    echo "  Arch/Garuda:   sudo pacman -S openscad"
    echo "  Debian/Ubuntu: sudo apt install openscad"
    exit 1
fi

echo "Using: $($OPENSCAD --version 2>&1 | head -1)"
echo "Output dir: $STL_DIR"
echo ""

# =============================================================================
# Export function
# =============================================================================
export_part() {
    local part_num="$1"
    local part_name="$2"
    local scad_file="$3"
    local stl_file="$STL_DIR/$4"
    local orientation_note="$5"

    echo "[$part_num/6] $part_name"
    echo "      → $stl_file"
    echo "      Orientation: $orientation_note"

    "$OPENSCAD" \
        --render \
        --export-format binstl \
        -o "$stl_file" \
        "$SCAD_DIR/$scad_file" \
        2>&1 | grep -v "^$" | sed 's/^/      /'

    if [[ -f "$stl_file" ]]; then
        size=$(du -h "$stl_file" | cut -f1)
        echo "      Done — $size"
    else
        echo "      ERROR: STL not created — check OpenSCAD output above"
        exit 1
    fi
    echo ""
}

# =============================================================================
# Export all 6 parts
# Each part SCAD file renders the module at Z=0 (flat face on bed)
# so Bambu Studio can import directly without repositioning
# =============================================================================

export_part 1 "Clamp body" \
    "part1_clamp_body.scad" \
    "rvo_p1_clamp_body.stl" \
    "Flat back face on bed — import as-is"

export_part 2 "Clamp lid" \
    "part2_clamp_lid.scad" \
    "rvo_p2_clamp_lid.stl" \
    "Flat outer face on bed — import as-is"

export_part 3 "Focuser knob gear (large)" \
    "part3_focuser_knob_gear.scad" \
    "rvo_p3_focuser_knob_gear.stl" \
    "Flat bottom face on bed — herringbone faces up — import as-is"

export_part 4 "Motor pinion (small)" \
    "part4_motor_pinion.scad" \
    "rvo_p4_motor_pinion.stl" \
    "Flat bottom face on bed — import as-is"

export_part 5 "Electronics box" \
    "part5_electronics_box.scad" \
    "rvo_p5_electronics_box.stl" \
    "Solid base on bed, open top faces up — import as-is"

export_part 6 "Electronics lid" \
    "part6_electronics_lid.scad" \
    "rvo_p6_electronics_lid.stl" \
    "Flat outer face on bed — import as-is"

# =============================================================================
# Summary
# =============================================================================
echo "============================================================"
echo "All parts exported to: $STL_DIR"
echo ""
echo "Part          File                            Bed orientation"
echo "──────────────────────────────────────────────────────────────"
echo "Clamp body    rvo_p1_clamp_body.stl           flat back face down"
echo "Clamp lid     rvo_p2_clamp_lid.stl            flat outer face down"
echo "Knob gear     rvo_p3_focuser_knob_gear.stl    flat bottom face down"
echo "Motor pinion  rvo_p4_motor_pinion.stl         flat bottom face down"
echo "Ebox          rvo_p5_electronics_box.stl      base down, open top up"
echo "Ebox lid      rvo_p6_electronics_lid.stl      flat outer face down"
echo ""
echo "Bambu Studio: drag all STL files onto the build plate."
echo "No rotation needed — all parts export in correct print orientation."
echo ""
echo "Plate layout suggestion:"
echo "  Plate 1 (gears):      p3 + p4  → use gear process preset"
echo "  Plate 2 (structural): p1 + p5  → use structural process preset"
echo "  Plate 3 (lids):       p2 + p6  → use structural process preset"
echo "============================================================"
