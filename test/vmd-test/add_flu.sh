#!/bin/bash

#PROTOCOLO PARA INSERTAR SOLUTE


# 1. Assign arguments
input_file="$1"
solute="$2"
topology="${3:-}"
remove_script="remove_close_water.tcl"
snap_script="snapshots.tcl"


# 2. Check required arguments

if [ -z "$remove_script" ] || [ -z "$snap_script" ]; then
    echo "Error: Required TCL scripts missing not found in current directory."
    exit 1
fi

if [ -z "$input_file" ] || [ -z "$solute" ]; then
    echo "Error: Missing required arguments."
    echo "Usage: bash $0 <membrane.gro/pdb> <solute.gro/pdb> [topology.top]"
    exit 1
fi

# ------------------------------------------------------------------------------
# 3. START LOGGING (Place right here)
# ------------------------------------------------------------------------------
LOG_FILE="output.log"
exec > >(tee -i "$LOG_FILE") 2>&1
# ------------------------------------------------------------------------------

# 4a. Check existence of required files
if [ ! -f "$input_file" ]; then
    echo "Error: File '$input_file' not found."
    exit 1
fi

if [ ! -f "$solute" ]; then
    echo "Error: File '$solute' not found."
    exit 1
fi

# 4b. Check optional topology file
if [ -z "$topology" ] || [ ! -f "$topology" ]; then
    echo "Topology file was not provided, make sure to update topology manually"
    topology=""
fi

# 5. Validate solute and topology file formats
if [[ "$solute" != *.gro && "$solute" != *.pdb ]]; then
    echo "Error: Solute file '$solute' must be a .gro or .pdb file."
    exit 1
fi

if [[ -n "$topology" && "$topology" != *.top ]]; then
    echo "Error: Topology file '$topology' must be a .top file."
    exit 1
fi

# 6. Process input structure file conditionally
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


#-----------COPIAR Y PEGAR EL PDB DE SOLUTE AL FINAL DEL PDB BOX1, RENOMBRAR COMO BOX2

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

extension="${solute##*.}"


if [[ "$extension" == "gro" ]]; then
    # Extracts column 1 of line 3 and removes all numeric characters
    mol_name=$(awk 'NR==3 {print $1; exit}' "$solute" | tr -d '0-9')
elif [[ "$extension" == "pdb" ]]; then
    # Extracts column 4 from the first ATOM/HETATM record
    mol_name=$(awk '/^ATOM|^HETATM/ {print $4; exit}' "$solute")
fi

printf "%s\t%d\n" "$mol_name" "$total" >> system.top


rm *tmp.pdb

vmd -dispdev none -e "$remove_script" -args pre-removed.pdb pre-removed.pdb removed.pdb $mol_name system.top

vmd -dispdev none -e "$snap_script" removed.pdb


