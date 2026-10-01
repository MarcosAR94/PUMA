#!/bin/bash

#PROTOCOLO PARA INSERTAR FLURA


# 1. Check if argument was passed
if [ -z "$1" ]; then
    echo "Error: Missing input file."
    echo "Usage: bash $0 <filename.gro>"
    exit 1
fi

gro_file="$1"

# 2. Check if file exists
if [ ! -f "$gro_file" ]; then
    echo "Error: File '$gro_file' not found."
    exit 1
fi

# 3. Check if the file extension is .gro
if [[ "$gro_file" != *.gro ]]; then
    echo "Error: '$gro_file' is not a .gro file! Please provide a .gro file."
    exit 1
fi

# 4. Extract x, y, z from the last non-empty line (ignores insane.py trailing newlines)
box_line=$(grep . "$gro_file" | tail -n 1)
read -r x y z _ <<< "$box_line"

# Define fixed geometric parameters
box_h=2.000    # Insert box height in Z
gap=1.000      # Distance from top/bottom boundaries

# 5. Perform floating-point math dynamically
# Calculate translation shift directly with sign included
shift_z=$(echo "scale=3; $z - $gap - $box_h - 1.0" | bc)

# Number of Solute molecules to be added per water slab via gmx insert-molecules
nmol=50
total=$((nmol * 2))
resnr=$((nmol + 1))

gmx editconf -f $gro_file -box $x $y $box_h -c no -translate 0 0 -1 -o lower_box_tmp.pdb

#FABRICAR CAJA DE FLURAS

gmx insert-molecules -ci FLU_CG.pdb -nmol ${nmol} -box $x $y $box_h -o flura-lower_tmp.pdb


#-----------COPIAR Y PEGAR EL PDB DE FLURA AL FINAL DEL PDB BOX1, RENOMBRAR COMO BOX2

# Variables
skip_end=2      # number of lines to skip at end of file1
skip_start=4    # number of lines to skip at start of file2

# Count total lines in file1 and cut the part you need
head -n -$skip_end lower_box_tmp.pdb > combined-tmp.pdb

# Append file2 but skip the first M lines
tail -n +$((skip_start + 1)) flura-lower_tmp.pdb >> combined-tmp.pdb 
mv combined-tmp.pdb lower_flura_box_tmp.pdb

# Translate to upper slab (shift_z carries its own sign, no explicit '-' needed)

gmx editconf -f lower_flura_box_tmp.pdb -translate 0 0 -$shift_z -o upper_box_tmp.pdb

gmx insert-molecules -ci FLU_CG.pdb -nmol ${nmol} -box $x $y $box_h -o flura-upper_1_tmp.pdb
gmx editconf -f flura-upper_1_tmp.pdb -resnr ${resnr} -o flura-upper_tmp.pdb


# Count total lines in file1 and cut the part you need
head -n -$skip_end upper_box_tmp.pdb > combined-tmp.pdb

# Append file2 but skip the first M lines
tail -n +$((skip_start + 1)) flura-upper_tmp.pdb >> combined-tmp.pdb

gmx editconf -f combined-tmp.pdb -box $x $y $z -o pre-removed.pdb

printf "FLU\t%d\n" "$total" >> system.top

rm *tmp.pdb

vmd -dispdev none -e remove_close_water_v2.tcl -args pre-removed.pdb pre-remove.pdb removed.pdb system.top


