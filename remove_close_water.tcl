# remove_close_water.tcl
#
# Removes water (resname W) residues that have any atom within 3.5 A
# of resname FLU, using VMD's internal unique "residue" index rather
# than the PDB-file "resid" field.
#
# Usage:
#    vmd -dispdev none -e remove_close_water.tcl -args <struct> <coords> <output.pdb> <mol_name> [topfile]

set structfile    [lindex $argv 0]
set coordfile     [lindex $argv 1]
set outfile       [lindex $argv 2]
set solute_resnm  [lindex $argv 3] 
set topfile       [lindex $argv 4] ;# Optional topology file to modify

if {$outfile == ""} {
    puts "Usage: vmd -dispdev none -e remove_close_water.tcl -args <struct> <coords> <output.pdb> <mol_name> [topfile]"
    exit 1
}

mol new $structfile
mol addfile $coordfile waitfor all

# Select the offending water atoms
set closeW [atomselect top "resname W and same residue as (within 3.5 of resname $solute_resnm)"]

# Get the UNIQUE internal residue indices for those atoms
set rmres [lsort -unique -integer [$closeW get residue]]
set nres  [llength $rmres]
set natoms [$closeW num]

puts "Flagging $nres water residues ($natoms atoms) for removal"

if {$nres == 0} {
    puts "Nothing to remove - check your selection / cutoff / resnames."
    exit 1
}

# Build the complement selection using the same unique "residue" field
set resstr [join $rmres " "]
set keep [atomselect top "not (residue $resstr)"]

puts "Writing [$keep num] atoms to $outfile (from [[atomselect top all] num] total)"
$keep writepdb $outfile

$closeW delete
$keep delete

# ----------------------------------------------------------------------
# Topology File Update
# Reads "W <count>" line, subtracts $nres, and updates topology with sed
# ----------------------------------------------------------------------
if {$topfile != "" && [file exists $topfile]} {
    set fp [open $topfile r]
    set content [read $fp]
    close $fp

    if {[regexp -line {^\s*W\s+([0-9]+)} $content match old_count]} {
        set new_count [expr {$old_count - $nres}]
        puts "Updating topology: reducing W count from $old_count to $new_count"

        # Tcl native regex substitution (preserves leading spaces/tabs)
        regsub -line {^(\s*W\s+)[0-9]+} $content "\\1$new_count" updated_content

        set fp [open $topfile w]
        puts -nonewline $fp $updated_content
        close $fp

        puts "Topology file successfully updated."
    } else {
        puts "Warning: Line matching 'W <number>' not found in $topfile"
    }
}

exit