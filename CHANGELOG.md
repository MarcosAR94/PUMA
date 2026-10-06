# Changelog

## [1.2.2] - 2026-10-06

### Changed
- Changes into <README.md>
    - Clean up of hardcoded terms
    - Show of use
    - Warning regarding solvent residue name

## [1.2.1] - 2026-10-06

### Added
- Additions to <add_solute.sh>
    - Section 3 to check if dependencies are installed
    - If GROMACS is installed, parse PATH to be sourced

### Changed
- Changes in <add_solute.sh>
    - Loging from Section 2 to 3
    - Files parsed as arguments now Section 4
    - Script functionality now Section 5
    - Section 8 to 6
    - Section 9 to 7

## [1.2.0] - 2026-10-06

### Changed
- Changes in <add_solute.sh>
    - Functionality of TCL scripts were imported into main script to ease utilization up 

### Deteleted
- Files <remove_close_water.tcl> and <snapshots.tcl> were removed from all directories

## [1.1.3] - 2026-10-05

### Changed
- Change in file name <add_flu.sh> to <add_solute.sh>
- Only test directory remains containing both gro and pdb files and not being run

### Added
- Addition in <add_solute.sh>
    -Line 201 now discards excesive render progress that was getting log

### Deleted
- Directory test/vmd-test
- Directory test/gro-test
- Directory test/pdb-test

## [1.1.2] - 2026-10-05

### Added
- Addition in <add_flu.sh>
    - A Help function and flag handling was added

## [1.1.1] - 2026-10-05

### Added
- Addition of <snapshots.tcl> script
    - Directory test/vmd-test added
    - Snapshot Functionality added "curret_directory/snaps/"

### Changed
- Changes in file <remove_close_water_v2.tcl> to <remove_close_water.tcl>
    - Topology updates with current residue name of solute molecule

## [1.1.0] - 2026-10-02
### Added
- Native support for `.pdb` input structures.
- Support for optional topology files (`.top`).
- Corrected topoly update regarding solute
- Execution logging via `tee`.
- Script check for `remove_close_water_v2.tcl` before launching VMD.

### Changed
- Standardized coordinate conversions from Ångströms to nanometers for PDB parsing.
