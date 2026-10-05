# snapshots.tcl
#
# Script to pre-eliminary corroborate if the insertion of solutes
# may perhaps introduce some type of artifact to membrane system
#
# Usage:
#    vmd -dispdev none -e snapshots.tcl <struct> 

# Define and create output directory
set out_dir "snapshots"
file mkdir $out_dir

# 1. Selection: Exclude residue W
mol modselect 0 top "not resname W"

# 2. Top View
display projection Orthographic
display resetview
render TachyonInternal [file join $out_dir top_view.tga]

# 3. Front View
rotate x by -90
render TachyonInternal [file join $out_dir front_view.tga]

# 4. Angle View
rotate y by -45
rotate x by 30
render TachyonInternal [file join $out_dir angle_view.tga]

# 5. Convert TGA to PNG inside the target directory
foreach view {top_view front_view angle_view} {
    set tga_path [file join $out_dir ${view}.tga]
    set png_path [file join $out_dir ${view}.png]
    exec convert $tga_path $png_path
}

quit