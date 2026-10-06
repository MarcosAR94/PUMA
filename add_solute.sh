#!/bin/bash

# ==============================================================================
# PUMA: Populate Upper/lower Membrane Aqueous-slabs
# ==============================================================================
# Ad-hoc solution tool to insert molecules to water slabs and providing
# practice of code review and documentation
# ==============================================================================


# ==============================================================================
# 1. Help Function & Flag Handling
# ==============================================================================
show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS] <membrane.gro|pdb> <solute.gro|pdb> [topology.top]

Description:
  Automates the insertion of solute molecules into the upper and lower solvent
  slabs of a membrane system using GROMACS and VMD.

Arguments:
  <membrane.gro|pdb>   Input membrane structure file (.gro or .pdb).
  <solute.gro|pdb>     Solute molecule structure file (.gro or .pdb).
  [topology.top]       (Optional) Topology file where solute count will be appended.

Options:
  -h, --help           Display this help message and exit.

Dependencies & Prerequisites:
  - GROMACS ('gmx') and VMD ('vmd') must be in your PATH.

Examples:
  bash $(basename "$0") membrane.pdb solute.gro
  bash $(basename "$0") system.gro solute.pdb system.top

EOF
}

# Catch help flag immediately
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    show_help
    exit 0
fi
# ------------------------------------------------------------------------------

# ==============================================================================
# 2. START LOGGING
#==============================================================================
LOG_FILE="output.log"
exec > >(tee -i "$LOG_FILE") 2>&1
# ------------------------------------------------------------------------------

# ==============================================================================
# 3. CHECK DEPENDENCIES AND VALIDATE ARGUMENTS
# ==============================================================================

# ------------------------------------------------------------------------------
# 3.1. GROMACS Pre-Environment Setup
# ------------------------------------------------------------------------------
if ! command -v gmx >/dev/null 2>&1; then
    # gmx is NOT in PATH. Try sourcing the default location as a fallback.
    if [ -f "/usr/local/gromacs/bin/GMXRC" ]; then
        source "/usr/local/gromacs/bin/GMXRC"
    fi
else
    # gmx IS in PATH. Sourcing its specific GMXRC ensures auxiliary 
    # environment variables are correctly loaded just in case.
    GMX_BIN_DIR=$(dirname "$(command -v gmx)")
    if [ -f "$GMX_BIN_DIR/GMXRC" ]; then
        source "$GMX_BIN_DIR/GMXRC"
    fi
fi

# ------------------------------------------------------------------------------
# 3.2. General Dependency Verification
# ------------------------------------------------------------------------------
REQUIRED_CMDS=("gmx" "vmd" "convert")

for cmd in "${REQUIRED_CMDS[@]}"; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "Error: Required command '$cmd' is not installed or not in PATH." >&2
        
        # Add a helpful hint specifically for GROMACS
        if [ "$cmd" = "gmx" ]; then
            echo "Hint: If GROMACS is installed in a custom location, run:" >&2
            echo "      source /path/to/your/gromacs/bin/GMXRC" >&2
        fi
        
        exit 1
    fi
done

echo "All dependencies loaded successfully. Proceeding..."

# ------------------------------------------------------------------------------
# 3.3. Arguments Verification
# ------------------------------------------------------------------------------

input_file="$1"
solute="$2"
topology="${3:-}"

if [ -z "$input_file" ] || [ -z "$solute" ]; then
    echo "Error: Missing required arguments."
    echo "Usage: bash $0 <membrane.gro/pdb> <solute.gro/pdb> [topology.top]"
    exit 1
fi
# ------------------------------------------------------------------------------

# ==============================================================================
# 4. CHECK FILES PASSED AS ARGUMENTS
# ==============================================================================

# ------------------------------------------------------------------------------
# 4.1. Check existence of required files
# ------------------------------------------------------------------------------
if [ ! -f "$input_file" ]; then
    echo "Error: File '$input_file' not found."
    exit 1
fi

if [ ! -f "$solute" ]; then
    echo "Error: File '$solute' not found."
    exit 1
fi

# ------------------------------------------------------------------------------
# 4.2. Check optional topology file
# ------------------------------------------------------------------------------

if [ -z "$topology" ] || [ ! -f "$topology" ]; then
    echo "Topology file was not provided, make sure to update topology manually"
    topology=""
fi

# ------------------------------------------------------------------------------
# 4.3. Validate solute and topology file formats
# ------------------------------------------------------------------------------

if [[ "$solute" != *.gro && "$solute" != *.pdb ]]; then
    echo -e "Error: Solute file '$solute' must be a .gro or .pdb file.\nCheck -h or --help if needed"
    exit 1
fi

if [[ -n "$topology" && "$topology" != *.top ]]; then
    echo "Error: Topology file '$topology' must be a .top file."
    exit 1
fi

# ------------------------------------------------------------------------------
# 4.4. Process input structure file conditionally
# ------------------------------------------------------------------------------

if [[ "$input_file" == *.gro ]]; then
    # A. Extract x, y, z from the last non-empty line (ignores insane.py trailing newlines)
    box_line=$(grep . "$input_file" | tail -n 1)
    read -r x y z _ <<< "$box_line"

elif [[ "$input_file" == *.pdb ]]; then
    # Parse CRYST1 line, convert Å to nm (divide by 10), and store x, y, z
    read -r x y z <<< $(awk '/^CRYST1/ {printf "%.5f %.5f %.5f", $2/10, $3/10, $4/10; exit}' "$input_file")
    
    # Check if box dimensions were successfully parsed
    if [ -z "$x" ] || [ -z "$y" ] || [ -z "$z" ]; then
        echo "Error: Could not find valid CRYST1 record in '$input_file'."
        exit 1
    fi

else
    echo "Error: Tool not compatible with formats different than .pdb or .gro. Please provide correct structure file."
    exit 1
fi
# ------------------------------------------------------------------------------

# ==============================================================================
# 5. PUMA CORE FUNCTIONALITY (Works but needs clean up)
# ==============================================================================

# Define fixed geometric parameters
box_h=2.000    # Insert box height in Z
gap=1.000      # Distance from top/bottom boundaries

# 7. Perform floating-point math dynamically
# Calculate translation shift directly with sign included
shift_z=$(echo "scale=3; $z - $gap - $box_h - 1.0" | bc)

# Number of Solute molecules to be added per water slab via gmx insert-molecules
nmol=50
total=$((nmol * 2))
resnr=$((nmol + 1))

gmx editconf -f $input_file -box $x $y $box_h -c no -translate 0 0 -1 -o lower_box_tmp.pdb

#FABRICAR CAJA DE SOLUTES

gmx insert-molecules -ci ${solute} -nmol ${nmol} -box $x $y $box_h -o solute-lower_tmp.pdb


#-----------COPIAR Y PEGAR EL PDB DE SOLUTE AL FINAL DEL PDB ------------------------------

# Variables
skip_end=2      # number of lines to skip at end of file1
skip_start=4    # number of lines to skip at start of file2

# Count total lines in file1 and cut the part you need
head -n -$skip_end lower_box_tmp.pdb > combined-tmp.pdb

# Append file2 but skip the first M lines
tail -n +$((skip_start + 1)) solute-lower_tmp.pdb >> combined-tmp.pdb 
mv combined-tmp.pdb lower_solute_box_tmp.pdb

# Translate to upper slab (shift_z carries its own sign, no explicit '-' needed)

gmx editconf -f lower_solute_box_tmp.pdb -translate 0 0 -$shift_z -o upper_box_tmp.pdb

gmx insert-molecules -ci ${solute} -nmol ${nmol} -box $x $y $box_h -o solute-upper_1_tmp.pdb
gmx editconf -f solute-upper_1_tmp.pdb -resnr ${resnr} -o solute-upper_tmp.pdb


# Count total lines in file1 and cut the part you need
head -n -$skip_end upper_box_tmp.pdb > combined-tmp.pdb

# Append file2 but skip the first M lines
tail -n +$((skip_start + 1)) solute-upper_tmp.pdb >> combined-tmp.pdb

gmx editconf -f combined-tmp.pdb -box $x $y $z -o pre-removed.pdb

# -------------------------------------------------------------------------------
# 5.#. Residue Name Catcher
# -------------------------------------------------------------------------------

extension="${solute##*.}"

if [[ "$extension" == "gro" ]]; then
    # Extracts column 1 of line 3 and removes all numeric characters
    mol_name=$(awk 'NR==3 {print $1; exit}' "$solute" | tr -d '0-9')
elif [[ "$extension" == "pdb" ]]; then
    # Extracts column 4 from the first ATOM/HETATM record
    mol_name=$(awk '/^ATOM|^HETATM/ {print $4; exit}' "$solute")
fi

# -------------------------------------------------------------------------------
# 5.#. Topology update in case of passed
# -------------------------------------------------------------------------------

if [[ -f "$topology" ]]; then
    printf "%s\t%d\n" "$mol_name" "$total" >> "$topology"
else
    echo "Warning: Topology file '$topology' does not exist. Skipping update." >&2
fi

# -------------------------------------------------------------------------------

rm *tmp.pdb

# ==============================================================================
# 6. REMOVE SOLVENT AROUND SOLUTE SECTION
# ==============================================================================
step_remove_waters() {
    
    echo ">>> Running VMD: Removing clashing waters..."

    vmd -dispdev none -e <(cat << 'EOF'
    set structfile   [lindex $argv 0]
    set coordfile    [lindex $argv 1]
    set outfile      [lindex $argv 2]
    set solute_resnm [lindex $argv 3]
    set topfile      [lindex $argv 4]

    mol new $structfile
    mol addfile $coordfile waitfor all

    set closeW [atomselect top "resname W and same residue as (within 3.5 of resname $solute_resnm)"]
    set rmres [lsort -unique -integer [$closeW get residue]]
    set nres  [llength $rmres]

    if {$nres == 0} {
        puts "No clashing waters detected. Writing full structure..."
        set all [atomselect top all]
        $all writepdb $outfile
        $all delete
        quit
    }

    set resstr [join $rmres " "]
    set keep [atomselect top "not (residue $resstr)"]
    $keep writepdb $outfile

    $closeW delete
    $keep delete

    # Update topology if supplied
    if {$topfile != "" && [file exists $topfile]} {
        set fp [open $topfile r]
        set content [read $fp]
        close $fp

        if {[regexp -line {^\s*W\s+([0-9]+)} $content match old_count]} {
            set new_count [expr {$old_count - $nres}]
            regsub -line {^(\s*W\s+)[0-9]+} $content "\\1$new_count" updated_content
            set fp [open $topfile w]
            puts -nonewline $fp $updated_content
            close $fp
        }
    }
    quit
EOF
    ) -args pre-removed.pdb pre-removed.pdb removed.pdb $mol_name $topology
}

step_remove_waters

# ------------------------------------------------------------------------------

# ==============================================================================
# 7. SNAPSHOTS CAPTURE FUNCTION
# ==============================================================================

snapshots () {

    echo ">>> Running VMD: Taking snapshots from system..."

    vmd -dispdev none -e <(cat << 'EOF'

    # snapshots.tcl
    #
    # Script to pre-eliminary corroborate if the insertion of solutes
    # may perhaps introduce some type of artifact to membrane system
    #
    
    # Define and create output directory
    set out_dir "snapshots"
    file mkdir $out_dir

    # 1.1. Top View
    display projection Orthographic
    display resetview
    render TachyonInternal [file join $out_dir top_view.tga]

    # 1.2. Front View
    rotate x by -90
    render TachyonInternal [file join $out_dir front_view.tga]

    # 1.3. Angle View
    rotate y by -45
    rotate x by 30
    render TachyonInternal [file join $out_dir angle_view.tga]

    # 2.1. Selection: Exclude residue W
    mol modselect 0 top "not resname W"    

    # 2.1. Top View
    display projection Orthographic
    display resetview
    render TachyonInternal [file join $out_dir top_view_solv.tga]

    # 2.2. Front View
    rotate x by -90
    render TachyonInternal [file join $out_dir front_view_solv.tga]

    # 2.3. Angle View
    rotate y by -45
    rotate x by 30
    render TachyonInternal [file join $out_dir angle_view_solv.tga]

    # 3.1. Convert TGA to PNG inside the target directory
    foreach view {top_view front_view angle_view} {
        set tga_path [file join $out_dir ${view}.tga]
        set png_path [file join $out_dir ${view}.png]
        exec convert $tga_path $png_path
        file delete -force $tga_path
    }

    quit
EOF
    ) removed.pdb 2>&1 | grep -v -i "tachyon"
}

snapshots

# ------------------------------------------------------------------------------

