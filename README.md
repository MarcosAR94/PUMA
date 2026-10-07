# PUMA: Populate Upper/lower Membrane Aqueous-slabs

**PUMA** (**P**opulate **U**pper/lower **M**embrane **A**queous-slabs) is an automated pipeline for inserting solute molecules symmetrically into both aqueous solvent slabs surrounding a lipid bilayer. It coordinates molecular insertion using GROMACS, removes steric clashes with surrounding water using VMD, and automatically updates system topology files when provided.

---

## Workflow Overview

1. **Box Dimension Extraction:** Reads the simulation box dimensions along the $X$, $Y$, and $Z$ axes from the input structure file, supporting both `.gro` and `.pdb` formats.
2. **Slab Target & Insertion:** Calculates translation vectors and populates target solute molecules into both the lower and upper solvent slabs using `gmx insert-molecules`.
3. **Water Clash Cleanup:** Uses an embedded VMD script to identify and remove water residues located within $3.5\text{ \AA}$ of any inserted solute molecule.
4. **Topology Synchronization (Optional):** If a topology file is passed, the script appends the total count of inserted solute molecules directly to the file and dynamically recalculates the remaining water residue counts.

> **Warning [Open Issue]:** The water clash removal step currently only targets most common coarse-grained solvent molecules such as `W` `WF` `WP` `WT4`. Systems utilizing alternative water identifiers (such as `SOL` or `HOH`) will not have clashing waters removed correctly.

---

## Dependencies

Ensure the following tools are available in your system path:

* **GROMACS** (`gmx editconf`, `gmx insert-molecules`)
* **VMD** (Visual Molecular Dynamics, executable in batch mode `-dispdev none`)
* **Convert** (ImageMagick tool for conversion of `tga` files into `png`)
* **GNU `bc`** (Arbitrary precision calculator language)
* **Bash** shell environment

---

## Required Files

Place the following script in your working directory and prepare your inputs:

* `add_solute.sh` – Main pipeline execution script.
* **Membrane Structure File** – Coordinate file of the system (`.gro` or `.pdb`).
* **Solute Structure File** – Coordinate file for the solute molecule to be inserted (`.gro` or `.pdb`).
* **Topology File** *(Optional)* – GROMACS system topology file (`.top`) containing a target solvent entry.

---

## Usage

To view the help menu and available options:
```bash
bash add_solute.sh -h
```
To execute the pipeline, provide the membrane structure, the solute structure, and optionally the topology file:
```bash
bash add_solute.sh <membrane.gro|pdb> <solute.gro|pdb> [topology.top]
```

---

## Output Files

* `removed.pdb` – Final structure file containing the updated bilayer, inserted solutes, and clash-filtered water molecules.
* **Snapshots directory** - Extracted png images with and without solvent to pre-visualize `removed.pdb` and solute insertion from top, front and an angle view
* **Topology File** – Updated topology file reflecting the addition of solute molecules and the reduction of removed water residues if parsed.

---

## License

This project is open-source and available under the [MIT License](LICENSE).
