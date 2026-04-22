# JI_tiling

This work begins with projection of a five-dimensional integer lattice onto a 2D plane using the "cut and project" method, producing Penrose-like quasicrystal tilings. The lattice coordinates are then interpreted as exponents of harmonics, connecting the geometric structure of the tiling to just intonation pitch ratios. The resulting tiling is used to generate four note chords in SuperCollider; each tile is defined by four nodes, defining the chord. Different options, selected through global variables at the beginning of `tiling.scd`, allow for tones in the chord to be on continuously, have an envelope, or passed through a vocoder (with common modulation for the four tones).

A particular tile may be selected using a mouse in a (SuperCollider) window. Alternatively, TouchOsc may be used to send OSC messages to SuperCollider.  Use of TouchOsc requires a setup procedure outlined in `touchosc_buttons.ipynb`. 

Erv Wilson explored the connection between just intonation and Penrose tiling in [D'ALESSANDRO, LIKE A HURRICANE](https://www.anaphoria.com/dal.pdf).

## Mathematical overview

A 5×5 cyclic permutation matrix is diagonalized; its complex eigenvectors define two orthogonal 2D planes in R⁵. Points of the Z⁵ lattice whose perpendicular-space projections fall inside a convex hull "window" are selected and projected onto the principal plane, forming the quasicrystal tiling. Each rhombus tile vertex corresponds to a rational frequency ratio built from the primes {3, 5, 7, 9, 11}. [Different integer sequences may be selected in `tiling.scd`.]

As an aside, the notebook `hexadicDiamond.ipynb` demonstrates that Erv Wilson's Hexadic Diamond may be generated through use of this same projection to the principal plane.  Notebooks are also available that explore the connection of the hexadic diamond and tiling to Coxeter theory.

## Prerequisites

- Python 3.9+
- SuperCollider (for `tiling.scd`)

## Setup

```bashxsx
pip install -r requirements.txt
```

Then launch JupyterLab or Jupyter Notebook from the repo root:

```bash
jupyter lab
```

## Notebooks

| Notebook | Description |
|----------|-------------|
| `notebooks/penrose5D.ipynb` | Core notebook. Builds the 5D rotation, selects lattice points via convex-hull cut window, constructs the Penrose tiling, and writes the `Data/` files used by SuperCollider. |
| `notebooks/hexadicDiamond.ipynb` | Derives Erv Wilson's Hexadic Diamond from the same 5D projection, annotating projected points with their JI pitch ratios. |
| `notebooks/HypercubeOnPlane.ipynb` | Symbolic derivation of the eigenvectors using SymPy; verifies the projection geometry. |

## Data pipeline

1. Run `notebooks/penrose5D.ipynb` end-to-end.
2. Three CSV files are written to `Data/`:
   - `verts_5Dprojection.txt` — 2D coordinates of each tile's four corners
   - `indices_5Dprojection.txt` — corresponding 5D lattice indices
   - `faces_5Dprojection.txt` — face-direction index (determines tile shape/color)
3. Open `tiling.scd` in SuperCollider and evaluate the setup block to load these files.

## SuperCollider usage

Open `tiling.scd` in the SuperCollider IDE.  Execute blocks as detailed at beginning of file.

The file is organized into named blocks separated by `//===` comments:

## Shared utilities

`ji_tiling.py` at the repo root contains functions used across multiple notebooks:

- `basis2D` — construct 2D projection matrix from eigenvector pair
- `subSet` — length-n subsets of an iterable
- `in_hull` — convex-hull membership test
- `unitVector`, `polygonDataFunction`, `nMemberQ` — tile construction helpers
