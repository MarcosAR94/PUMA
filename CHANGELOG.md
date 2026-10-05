# Changelog

## [1.1.0] - 2026-10-02
### Added
- Native support for `.pdb` input structures.
- Support for optional topology files (`.top`).
- Corrected topoly update regarding solute
- Execution logging via `tee`.
- Script check for `remove_close_water_v2.tcl` before launching VMD.

### Changed
- Standardized coordinate conversions from Ångströms to nanometers for PDB parsing.

## [1.1.1] - 2026-10-05

### Added
- Addition of <snapshots.tcl> script
- Directory test/vmd-test added
- Snapshot Functionality added "curret_directory/snaps/"

### Changed
- Changes in file <remove_close_water_v2.tcl> to <remove_close_water.tcl>
- Topology updates with current residue name of solute molecule