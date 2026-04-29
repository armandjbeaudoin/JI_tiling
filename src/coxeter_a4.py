"""
Shared SageMath utilities for A4 Coxeter theory.

Imported by hexadic_diamond_coxeter.ipynb and penrose_ammann_coxeter.ipynb via:
    import sys; sys.path.insert(0, '../src')
    from coxeter_a4 import build_a4_system, build_eigenspaces, eigenvec_to_proj, algebraic_constants
"""

import numpy as np
from sage.all import RootSystem, CyclotomicField, n as numerical


def build_a4_system():
    """Build the A4 root system, Weyl group, and Coxeter permutation matrix P.

    Returns
    -------
    R        : RootSystem('A4')
    ambient  : ambient space (5D, ε-basis)
    W        : Weyl group of the ambient space
    s        : simple reflections dict (1-indexed)
    cox      : Coxeter element s[1]*s[2]*s[3]*s[4]
    P        : 5×5 Coxeter permutation matrix (cyclic εᵢ → εᵢ₊₁)
    """
    R = RootSystem(['A', 4])
    ambient = R.ambient_space()
    W = ambient.weyl_group()
    s = W.simple_reflections()
    cox = s[1] * s[2] * s[3] * s[4]
    P = cox.matrix()
    return R, ambient, W, s, cox, P


def build_eigenspaces(P):
    """Diagonalize the Coxeter matrix P over Q(ζ₅) and return eigenvectors for E∥ and E⊥.

    Parameters
    ----------
    P : 5×5 integer matrix (from build_a4_system)

    Returns
    -------
    K      : CyclotomicField(5)
    zeta   : generator ζ₅ = e^(2πi/5)
    w_par  : E∥ eigenvector (eigenvalue ζ₅,  rotation by 2π/5 = 72°)
    w_perp : E⊥ eigenvector (eigenvalue ζ₅², rotation by 4π/5 = 144°)
    """
    K = CyclotomicField(5)
    zeta = K.gen()
    PK = P.change_ring(K)
    espaces = PK.eigenspaces_right()

    w_par = w_perp = None
    for ev, V in espaces:
        if ev == zeta:
            w_par = V.basis()[0]
        elif ev == zeta**2:
            w_perp = V.basis()[0]

    return K, zeta, w_par, w_perp


def eigenvec_to_proj(w, K):
    """Convert a Q(ζ₅) eigenvector to an orthonormal 2×5 real projection matrix.

    Sign convention: im[1] > 0, matching the standard star-vector ordering
    (row 0 = cosines, row 1 = sines with sin(2π/5) > 0).
    SageMath may return the conjugate eigenvector (negating im); this is corrected here.

    Parameters
    ----------
    w : eigenvector over K = CyclotomicField(5)
    K : CyclotomicField(5)

    Returns
    -------
    2×5 numpy array (orthonormal rows spanning the eigenplane)
    """
    emb = K.complex_embedding()
    w_cc = [emb(c) for c in w]
    re = np.array([float(c.real()) for c in w_cc])
    im = np.array([float(c.imag()) for c in w_cc])
    re /= np.linalg.norm(re)
    im /= np.linalg.norm(im)
    if im[1] < 0:
        im = -im
    return np.vstack([re, im])


def algebraic_constants(K, zeta):
    """Derive τ, σ, m₁±, m₂±, κ₁ algebraically in Q(ζ₅) and as floats.

    Parameters
    ----------
    K    : CyclotomicField(5)
    zeta : generator ζ₅

    Returns
    -------
    dict with keys:
        sqrt5, tau_exact, sigma_exact, kappa1_exact,
        m1_plus_exact, m2_plus_exact, m1_minus_exact, m2_minus_exact,
        TAU, SIGMA, KAPPA_1, M1_PLUS, M2_PLUS, M1_MINUS, M2_MINUS
    """
    sqrt5          = zeta + zeta**4 - zeta**2 - zeta**3   # real in Q(ζ₅)
    tau_exact      = (1 + sqrt5) / 2
    sigma_exact    = (1 - sqrt5) / 2
    kappa1_exact   = 1 / tau_exact                         # = 1/τ = τ − 1
    m1_plus_exact  = (5 - sqrt5) / 10
    m2_plus_exact  = 1 / sqrt5
    m1_minus_exact = (5 + sqrt5) / 10                     # Galois conjugate of m1+
    m2_minus_exact = -1 / sqrt5                            # Galois conjugate of m2+

    def to_float(x):
        return float(numerical(x).real())

    return dict(
        sqrt5=sqrt5,
        tau_exact=tau_exact,     sigma_exact=sigma_exact,
        kappa1_exact=kappa1_exact,
        m1_plus_exact=m1_plus_exact,   m2_plus_exact=m2_plus_exact,
        m1_minus_exact=m1_minus_exact, m2_minus_exact=m2_minus_exact,
        TAU=to_float(tau_exact),     SIGMA=to_float(sigma_exact),
        KAPPA_1=to_float(kappa1_exact),
        M1_PLUS=to_float(m1_plus_exact),   M2_PLUS=to_float(m2_plus_exact),
        M1_MINUS=to_float(m1_minus_exact), M2_MINUS=to_float(m2_minus_exact),
    )
