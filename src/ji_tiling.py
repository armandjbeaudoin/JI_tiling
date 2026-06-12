"""
Shared utility functions for JI_tiling notebooks.
"""

import numpy as np
from itertools import chain, combinations
from scipy.spatial import ConvexHull, Delaunay


# ---------------------------------------------------------------------------
# Hexadic Diamond — 31 interval ratios as (numerator, denominator) pairs.
# Import and build as needed:
#   from sympy import Rational
#   diamond_ratios = set(Rational(n, d) for n, d in DIAMOND_RATIOS)
# or:
#   diamond_float = np.array([n/d for n, d in DIAMOND_RATIOS])
#
# NOTE: the 31 entries mirror the 31 Diamond lattice points, but there are only
# 29 distinct pitch values: (12,9) ≡ (4,3) and (9,6) ≡ (3,2) are the 9 = 3²
# doubles (9/3 and 3/1 octave-reduce to the same pitch, likewise 3/9 and 1/3).
# Do not "deduplicate" — the entry count is deliberate.
# ---------------------------------------------------------------------------
DIAMOND_RATIOS = [
    (3,2),(16,9),(5,4),(16,11),(7,4),(4,3),(9,8),(8,5),(11,8),(8,7),
    (10,7),(12,11),(14,9),(5,3),(18,11),(7,5),(11,6),(9,7),(6,5),(11,9),
    (12,9),(10,9),(20,11),(14,11),(7,6),(9,6),(9,5),(11,10),(11,7),(12,7),
    (1,1),
]


# ---------------------------------------------------------------------------
# Helmholtz-Ellis notation limits, as rendered by heji-ly (lib.scm validate):
#   prime 5 : |exp| <= 4,  prime 7 : |exp| <= 2,  prime 11 : |exp| <= 1.
# The 3- and 9-exponents are unconstrained (9 = 3^2 folds into the 3-axis,
# which Pythagorean accidentals handle freely).
# ---------------------------------------------------------------------------
HE_LIMITS = {5: 4, 7: 2, 11: 1}   # prime → max |exponent|


def he_representable(exps):
    """True iff a (3, 5, 7, 9, 11)-exponent vector fits the HE notation limits."""
    _, i1, i2, _, i4 = exps
    return (abs(i1) <= HE_LIMITS[5]
            and abs(i2) <= HE_LIMITS[7]
            and abs(i4) <= HE_LIMITS[11])


def basis2D(eigenVectors, k, l):
    """Construct a 2D projection basis from two eigenvectors of the 5D rotation matrix.

    Returns a (2, 5) matrix `p` such that `p @ x` projects a 5D point onto the plane.
    Also prints the rotation angle between the projected standard basis vectors.
    """
    pi_unicode = "\u03C0"

    u, v = (eigenVectors[:, k] + eigenVectors[:, l]).real, \
           (1j * (eigenVectors[:, k] - eigenVectors[:, l])).real
    u /= np.linalg.norm(u)
    v /= np.linalg.norm(v)
    p = np.vstack((u, v))

    e1 = p @ np.array([0, 1, 0, 0, 0])
    e2 = p @ np.array([0, 0, 1, 0, 0])
    e1 = e1 / np.linalg.norm(e1)
    e2 = e2 / np.linalg.norm(e2)

    p_rotation = np.round(np.arccos(np.dot(e1, e2)) * (5 / np.pi), 6)
    print(f'-->5D basis vectors are rotated in 2D plane by ({p_rotation}{pi_unicode})/5')

    return p


def setup_a4_projection():
    """Build the A4 Coxeter projection matrices from the standard cyclic permutation matrix.

    Eigenvalues are sorted by angle so column assignments are deterministic regardless
    of numpy's eig ordering:
      col 0: e^{-4πi/5}  col 1: e^{-2πi/5}  col 2: 1
      col 3: e^{+2πi/5}  col 4: e^{+4πi/5}

    Returns
    -------
    eigenVectors : (5, 5) complex ndarray — sorted eigenvectors
    p            : (2, 5) real ndarray    — E∥ projection (2D tiling plane)
    y            : (3, 5) real ndarray    — E⊥ + uniform (3D acceptance-window space)
    """
    rotationMatrix = np.array([
        [0., 0., 0., 0., 1.],
        [1., 0., 0., 0., 0.],
        [0., 1., 0., 0., 0.],
        [0., 0., 1., 0., 0.],
        [0., 0., 0., 1., 0.],
    ])
    eigenValues, eigenVectors = np.linalg.eig(rotationMatrix)
    sort_idx = np.argsort(np.angle(eigenValues))
    eigenVectors = eigenVectors[:, sort_idx]

    print('2D projection plane (E∥):')
    p = basis2D(eigenVectors, 1, 3)   # conjugate pair at ±2π/5

    print('3D acceptance-window space (E⊥ + uniform):')
    e_perp = basis2D(eigenVectors, 4, 0)   # conjugate pair at ±4π/5
    uniform = np.ones(5) / np.linalg.norm(np.ones(5))
    y = np.vstack((e_perp, uniform))

    return eigenVectors, p, y


def make_acceptance_hull(y, s=0.999, centered=False):
    """Build the convex-hull acceptance window for the cut-and-project method.

    Projects the 32 corners of the scaled unit hypercube into E⊥ via `y`, then
    computes the ConvexHull and a Delaunay triangulation for fast point-in-hull
    queries.

    Window geometry (terminology per Senechal, "Quasicrystals and Geometry"):
      centered=False — window = π⊥ of the Delaunay (Delone) cell [0, s]^5 of Z^5
                       (unit cube with corners on lattice points); with a generic
                       ("regular") shift vector this gives the usual Penrose tiling.
      centered=True  — window = π⊥ of the (half-open) Voronoi cell, the same cube
                       shifted by -0.5 per coordinate to center on zero; with zero
                       shift vector this gives the singular tenfold-symmetric
                       ("defective") tiling. Equivalent to centered=False with
                       +0.5*(1,...,1) added to the lattice points; a -0.5 shift
                       yields the same tiling with 5D representatives translated
                       by the full trace vector (1,1,1,1,1) — which changes the
                       JI ratio attached to each vertex.

    NOTE: the returned scipy.spatial.Delaunay object is a triangulation used only
    for fast point-location queries; that usage of "Delaunay" is unrelated to the
    lattice's Delaunay cell above.

    Parameters
    ----------
    y : (3, 5) array — projection matrix into E⊥ (e.g. from setup_a4_projection)
    s : float        — scale factor for the unit cell (default 0.999 gives a
                       half-open window: closed at the anchor faces, open at the
                       far faces)
    centered : bool  — Voronoi-cell window (True) vs Delaunay-cell window (False);
                       see above.

    Returns
    -------
    hull     : scipy.spatial.ConvexHull
    hull_del : scipy.spatial.Delaunay  — built on hull.vertices for fast in_hull queries
    """
    cell = np.array([
        [i1, i2, i3, i4, i5]
        for i5 in range(2) for i4 in range(2) for i3 in range(2)
        for i2 in range(2) for i1 in range(2)
    ], dtype=float) * s
    if centered:
        cell -= 0.5
    convexHullSeed = (y @ cell.T).T
    hull     = ConvexHull(convexHullSeed)
    hull_del = Delaunay(convexHullSeed[hull.vertices])
    return hull, hull_del


def make_int_grid(d, ndim=5):
    """Return all ndim-D integer lattice points with each coordinate in [-d, d].

    Column order matches the penrose5D nested-loop convention: column 0 corresponds
    to the innermost loop variable (varies fastest).

    Parameters
    ----------
    d    : int — half-width of the grid; produces (2d+1)^ndim points
    ndim : int — number of dimensions (default 5)

    Returns
    -------
    grid : ((2d+1)^ndim, ndim) int ndarray
    """
    assert ndim == 5, "Only ndim=5 is currently supported"
    pts = []
    for i5 in range(-d, d + 1):
        for i4 in range(-d, d + 1):
            for i3 in range(-d, d + 1):
                for i2 in range(-d, d + 1):
                    for i1 in range(-d, d + 1):
                        pts.append([i1, i2, i3, i4, i5])
    return np.array(pts)


def subSet(iterable, n):
    """Return all subsets of length n from iterable.

    Example: subSet([1,2,3], 2) --> (1,2) (1,3) (2,3)
    """
    s = list(iterable)
    return chain.from_iterable(combinations(s, r) for r in range(n, n + 1))


def in_hull(p, hull):
    """Test if points in `p` are in `hull`.

    `p` should be an NxK array of N points in K dimensions.
    `hull` is either a scipy.spatial.Delaunay object or an MxK array of points
    for which Delaunay triangulation will be computed.

    Reference: https://stackoverflow.com/questions/16750618/
    """
    if not isinstance(hull, Delaunay):
        hull = Delaunay(hull)
    return hull.find_simplex(p) >= 0


def unitVector(l, d):
    """Return a unit vector of length `l` with a 1 at index `d`."""
    u = np.zeros(l)
    u[d] = 1.0
    return u


def polygonDataFunction(point, dir_):
    """Return the four 5D corners of a rhombus tile.

    `point` is the base corner; `dir_` is a 2-tuple of axis indices.
    """
    return np.array([
        point,
        point + unitVector(5, dir_[0]),
        point + unitVector(5, dir_[0]) + unitVector(5, dir_[1]),
        point + unitVector(5, dir_[1]),
    ])


def nMemberQ(set_, point_):
    """Return True if `point_` is contained in `set_` (within tolerance 1e-6)."""
    return np.any(np.sum(np.abs(set_ - point_), 1) < 1e-6)
