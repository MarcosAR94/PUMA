# PUMA: Populate Upper/lower Membrane Aqueous-slabs

**PUMA** (**P**opulate **U**pper/lower **M**embrane **A**queous-slabs) is an automated pipeline for inserting solute molecules symmetrically into both aqueous solvent slabs surrounding a lipid bilayer. It coordinates molecular insertion using GROMACS, removes steric clashes with surrounding water using VMD, and automatically updates system topology files.

---

## Workflow Overview

1. **Box Dimension Extraction:** Reads the simulation box dimensions along the $X$, $Y$, and $Z$ axes from the input coordinate file (`.gro`).
2. **Slab Target & Insertion:** Calculates translation vectors and populates target solute molecules into both the lower and upper solvent slabs using `gmx insert-molecules`.
3. **Topology Registration:** Appends the total count of inserted solute molecules directly to `system.top`.
4. **Water Clash Cleanup:** Uses VMD (`remove_close_water_v2.tcl`) to identify and remove water residues (`W`) located within $3.5\text{ \AA}$ of any inserted solute molecule.
5. **Topology Synchronization:** Dynamically recalculates remaining water residue counts and updates `system.top`.

---

## Dependencies

Ensure the following tools are available in your system path:

* **GROMACS** (`gmx editconf`, `gmx insert-molecules`)
* **VMD** (Visual Molecular Dynamics, executable in batch mode `-dispdev none`)
* **GNU `bc`** (Arbitrary precision calculator language)
* **Bash** shell environment

---

## Required Files

Place the following files in your working directory:

* `add_flu.sh` – Main pipeline execution script.
* `remove_close_water_v2.tcl` – VMD script for distance-based water removal.
* `FLU_CG.pdb` – Coordinate file template for the solute molecule to be inserted.
* `system.top` – GROMACS system topology file containing a target `W <count>` entry.

---

## Usage

Execute the pipeline script by providing your input membrane coordinate file (`.gro`):

```bash
bash add_flu.sh system.gro
```

---

## Output Files

* `removed.pdb` – Final structure file containing the updated bilayer, inserted solutes, and clash-filtered water molecules.
* `system.top` – Updated topology file reflecting the addition of solute molecules and the reduction of removed water residues.

---

## License

This project is open-source and available under the [MIT License](LICENSE).
