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