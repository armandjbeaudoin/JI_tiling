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
# ---------------------------------------------------------------------------
DIAMOND_RATIOS = [
    (3,2),(16,9),(5,4),(16,11),(7,4),(4,3),(9,8),(8,5),(11,8),(8,7),
    (10,7),(12,11),(14,9),(5,3),(18,11),(7,5),(11,6),(9,7),(6,5),(11,9),
    (12,9),(10,9),(20,11),(14,11),(7,6),(9,6),(9,5),(11,10),(11,7),(12,7),
    (1,1),
]


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

    p_rotation = np.arccos(np.dot(e1, e2)) * (5 / np.pi)
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


def make_acceptance_hull(y, s=0.999):
    """Build the convex-hull acceptance window for the cut-and-project method.

    Projects the 32 corners of the scaled unit hypercube [0, s]^5 into E⊥ via `y`,
    then computes the ConvexHull and a Delaunay triangulation for fast point-in-hull
    queries.

    Parameters
    ----------
    y : (3, 5) array — projection matrix into E⊥ (e.g. from setup_a4_projection)
    s : float        — scale factor for the unit cell (default 0.999 gives a
                       half-open acceptance window)

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
