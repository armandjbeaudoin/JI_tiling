# Erv Wilson's Hexadic Diamond Derived from the A₄ Root System

## Overview

The notebook `hexadic_diamond_coxeter.ipynb` demonstrates that Erv Wilson's
Hexadic Diamond — a structure from just-intonation music theory — is fully
derivable from the Coxeter theory of the A₄ root system. Every element of the
diamond (its points, their projection to 2D, and the connectivity of its star
lines) emerges from a single SageMath object: `RootSystem(['A', 4]).ambient_space()`.

The only external input is the assignment of odd harmonics [3, 5, 7, 9, 11] to
the five basis vectors of the ambient space.

Reference: [Erv Wilson, *The Diamond Marimba*](https://www.anaphoria.com/diamond.pdf)

---

## Coxeter-Theoretic Elements Used in the Notebook

### 1. The A₄ Root System (`RootSystem(['A', 4])`)

The root system A₄ has rank 4, with 20 roots living in a 4-dimensional
hyperplane H = {x ∈ ℝ⁵ : Σxᵢ = 0} of 5-dimensional ambient space. The roots
are the 20 vectors **εᵢ − εⱼ** for i ≠ j ∈ {0,1,2,3,4}, where ε₀…ε₄ are
the standard basis vectors of ℝ⁵.

The four simple roots are:

    α₁ = ε₁ − ε₂,  α₂ = ε₂ − ε₃,  α₃ = ε₃ − ε₄,  α₄ = ε₄ − ε₅

These are the nodes of the A₄ Dynkin diagram ○—○—○—○. Every root is an
integer linear combination of simple roots.

The Cartan matrix encodes the inner products between simple roots:

    [ 2 -1  0  0]
    [-1  2 -1  0]
    [ 0 -1  2 -1]
    [ 0  0 -1  2]

**Role in the notebook:** The 20 roots provide the 20 combination-product
ratios of the Hexadic Diamond (e.g., 3/5, 7/9, 11/3). Each root εᵢ − εⱼ maps
to the musical ratio `rI[i] / rI[j]` under the harmonic assignment.

### 2. The Ambient Space and Its Basis Vectors

The ambient space for A₄ is ℝ⁵ with basis ε₀, …, ε₄. These basis vectors are
the weights of the standard 5-dimensional representation of the Weyl group S₅.

**Role in the notebook:** The 10 vectors ±εᵢ provide the otonal and utonal
intervals of the diamond:

- **+εᵢ** (otonal): the five harmonics {3, 5, 7, 9, 11}
- **−εᵢ** (utonal): the five subharmonics {1/3, 1/5, 1/7, 1/9, 1/11}

Together with the 20 roots and the origin (unison, 1/1), these form the 31
points of the Hexadic Diamond.

### 3. The Coxeter Element and Permutation Matrix

The Coxeter element is a distinguished element of the Weyl group W(A₄) = S₅,
defined as the product of all simple reflections taken in sequence:

    cox = s₁ · s₂ · s₃ · s₄

where sᵢ is the reflection swapping εᵢ ↔ εᵢ₊₁. This product is the cyclic
permutation (1 2 3 4 5), and its matrix P in the ε-basis is the 5×5 circulant
permutation matrix:

    [0 0 0 0 1]
    [1 0 0 0 0]
    P = [0 1 0 0 0]
    [0 0 1 0 0]
    [0 0 0 1 0]

P has order 5 (the Coxeter number h = 5).

**Role in the notebook:** P is obtained from the same ambient space object that
provides the roots: `ambient.weyl_group().simple_reflections()`. Its eigenstructure
determines the projection to 2D, and its action on roots generates the star-line
connectivity. This is the same permutation matrix used in the cut-and-project
construction of Penrose tilings.

### 4. Eigenspaces over the Cyclotomic Field Q(ζ₅)

The eigenvalues of P are the fifth roots of unity ωᵏ = e^(2πik/5). Defining
P over `CyclotomicField(5)` and calling `P.eigenspaces_right()` gives exact
eigenspaces. The five eigenspaces decompose ℝ⁵ as:

- **k = 0** (eigenvalue 1): the direction (1,1,1,1,1), orthogonal to the root
  hyperplane H.
- **k = 1, 4** (eigenvalues e^(±2πi/5)): real 2-plane **E∥**, where P acts as
  rotation by 72°. This is the physical space of the Penrose tiling.
- **k = 2, 3** (eigenvalues e^(±4πi/5)): real 2-plane **E⊥**, where P acts as
  rotation by 144°. This is the internal space of the Penrose tiling.

The notebook selects the eigenspace for eigenvalue ζ₅ = e^(2πi/5), extracts
the eigenvector **w** over Q(ζ₅), embeds it into ℂ via `K.complex_embedding()`,
and forms a 2×5 real projection matrix from Re(**w**) and Im(**w**). These two
vectors are orthogonal and equal in norm, spanning E∥.

**Role in the notebook:** Projection of all 31 diamond points to E∥ yields the
2D Hexadic Diamond figure. The verification that successive basis vectors are
separated by 2π/5 in the projected plane confirms the correct eigenspace was
selected.

### 5. The Symbolic Projection via Q(ζ₅)

The projection of any lattice vector **v** = (v₀, v₁, v₂, v₃, v₄) to E∥ can
be expressed as a single element of the cyclotomic field:

    z = v₀ + v₁·ζ + v₂·ζ² + v₃·ζ³ + v₄·ζ⁴  ∈  Q(ζ₅)

where Re(z) and Im(z) give the x and y coordinates. This works because the
eigenvector of P for eigenvalue ζ₅ is proportional to (1, ζ, ζ², ζ³, ζ⁴).

The notebook uses this representation for the golden ratio computation (see §7
below), staying in exact arithmetic until numerical values are needed for
plotting.

### 6. Coxeter Orbits and Star-Line Connectivity

The star lines of the Hexadic Diamond are generated by the action of the
Coxeter element P on roots. P acts on roots by shifting both indices:

    P · (εᵢ − εⱼ) = εᵢ₊₁ − εⱼ₊₁  (mod 5)

Starting from a base root and applying P repeatedly generates an orbit of five
roots. The notebook defines:

```python
def coxeter_orbit(base, n=5):
    orbit = [np.array(base)]
    for _ in range(n - 1):
        orbit.append(P_np @ orbit[-1])
    return orbit
```

The two star patterns use four Coxeter orbits:

- **Red star** — outer: orbit of ε₀ − ε₂ (non-adjacent, d=2); bridge: orbit
  of ε₁ − ε₂ (adjacent, d=1). The V-shape connects `outer[k] → bridge[k] →
  outer[k+1]`. Each leg shares a common negative index (denominator), so the
  red star groups ratios by shared utonal element.

- **Blue star** — outer: orbit of ε₂ − ε₀ (negated d=2); bridge: orbit of
  ε₂ − ε₁ (negated d=1). Each leg shares a common positive index (numerator),
  so the blue star groups ratios by shared otonal element.

The original notebook used a `cyclic()` function to permute coordinate lists.
This is equivalent to repeated application of P, since cyclic permutation of
coordinates *is* the Coxeter element acting on the ε-basis. The Coxeter orbit
formulation makes this provenance explicit.

### 7. The Golden Ratio from Cyclotomic Arithmetic

The 20 roots project to two distinct distances from the origin, depending on
cyclic distance between their indices:

- **d = 1** (adjacent: εᵢ − εᵢ₊₁): projected squared norm = |1 − ζ|² =
  (1 − ζ)(1 − ζ⁴) = 2 − ζ − ζ⁴
- **d = 2** (non-adjacent: εᵢ − εᵢ₊₂): projected squared norm = |1 − ζ²|² =
  (1 − ζ²)(1 − ζ³) = 2 − ζ² − ζ³

The ratio of squared norms is computed entirely within Q(ζ₅):

    τ² = (2 − ζ² − ζ³) / (2 − ζ − ζ⁴)

which evaluates to (1 + √5)² / 4 · 4 = ((1+√5)/2)² ≈ 2.618034, confirming
that the ratio of projected distances is the golden ratio τ = (1 + √5)/2.

This is not a coincidence but a direct consequence of the eigenvalue structure:
cos(2π/5) = (√5 − 1)/4 and cos(4π/5) = −(√5 + 1)/4 are both expressions in
the golden ratio, and they control the projected lengths through the Coxeter
eigenspace geometry.

---

## The 31 Points of the Hexadic Diamond

| Count | 5D vectors | Coxeter identity | Musical meaning | Projected ring |
|-------|-----------|-----------------|----------------|---------------|
| 1 | (0,0,0,0,0) | zero vector | unison 1/1 | origin |
| 5 | +εᵢ | standard rep weights | otonal: 3, 5, 7, 9, 11 | inner (r ≈ 0.447) |
| 5 | −εᵢ | dual weights | utonal: 1/3, 1/5, 1/7, 1/9, 1/11 | inner (r ≈ 0.447) |
| 10 | εᵢ − εᵢ₊₁ | adjacent roots (d=1) | neighbor ratios: 3/5, 5/7, … | middle (r ≈ 0.526) |
| 10 | εᵢ − εᵢ₊₂ | non-adjacent roots (d=2) | separated ratios: 3/7, 5/9, … | outer (r ≈ 0.851) |

The inner ring forms a decagon (two interleaved pentagons — otonal red, utonal
blue, offset by 36°). The middle and outer rings each form decagons at 36°
spacing. The outer/middle radius ratio is exactly τ.

---

## Relationship to Penrose Tilings

The Hexadic Diamond and Penrose tilings share the same Coxeter-theoretic
foundation:

| | Penrose tiling | Hexadic Diamond |
|---|---|---|
| **Source** | ℤ⁵ lattice | A₄ roots + weights + origin |
| **Coxeter pair** | {I₂⁵, A₄}, degree N = 2 | same |
| **Field extension** | ℚ(√5), Galois conjugation √5 → −√5 | same |
| **Selection** | geometric window in E⊥ | combinatorial (at most 1 pos, 1 neg exponent) |
| **Projection space** | E∥ (72° eigenplane) | E∥ (same eigenplane) |
| **Internal space** | E⊥ (144° eigenplane), phason degrees of freedom | E⊥ (same eigenplane), controls radius ratio |
| **Result** | infinite aperiodic tiling | finite 31-point diagram |
| **Golden ratio appears as** | tile length ratio, inflation factor λ₊ = τ | outer/middle root ring ratio |
| **Galois conjugate appears as** | ⊥-space contraction λ₋ = σ | inner ring angular offset |
| **Coxeter element role** | defines E∥ / E⊥ decomposition | defines projection + star orbits |
| **Root vectors become** | tile edge directions | musical interval ratios |
| **Translation vector **q**₀** | parallel part = rigid shift; ⊥ part = phason | not applicable (finite selection, no window) |

Both constructions begin with the same permutation matrix P (the Coxeter
element of A₄), diagonalize it to obtain E∥, and project lattice structures
to this plane. The Penrose tiling uses the full lattice with a geometric filter;
the Hexadic Diamond uses a finite, algebraically natural subset of the root
system.

---

## The Coxeter Pair {I₂⁵, A₄} and the Cut-and-Project Construction

The relationship between the Hexadic Diamond and Penrose tilings can be made
fully precise through the theory of *Coxeter pairs* developed by Boyle and
Steinhardt (Phys. Rev. B 106, 144113, 2022). This section develops the
connection in detail, including the Galois conjugation that relates the
parallel and perpendicular spaces, the role of the translation vector **q**₀,
and worked numerical examples.

### The Coxeter Pair

A Coxeter pair consists of a noncrystallographic root system θ∥ (of lower
rank d∥) paired with a crystallographic root system θ (of higher rank d) such
that:

1. Both have the same rational rank (they live in the same ℚ-vector space).
2. The maximally symmetric projection of the θ roots onto d∥ dimensions
   yields N copies of the θ∥ roots.

For the Penrose tiling and the Hexadic Diamond, the relevant pair is
{I₂⁵, A₄}, which is a *quadratic* Coxeter pair of degree N = 2. The
noncrystallographic root system I₂⁵ has rank 2 (its 10 roots are the edge
midpoints of a regular pentagon in 2D), and its crystallographic partner A₄
has rank 4 (its 20 roots live in the hyperplane Σxᵢ = 0 of ℝ⁵). Under the
Coxeter-plane projection, the 20 A₄ roots project onto *two* concentric
copies of the 10 I₂⁵ roots — an inner ring and an outer ring longer by the
golden ratio τ.

The complete list of quadratic Coxeter pairs is:

| θ∥   | θ        | Field 𝕂     | Relevant symmetry     |
|------|----------|-------------|-----------------------|
| I₂⁵  | A₄       | ℚ(√5)       | 5-fold / 10-fold (Penrose) |
| I₂⁸  | B₄/C₄    | ℚ(√2)       | 8-fold (Ammann-Beenker) |
| I₂¹² | F₄       | ℚ(√3)       | 12-fold              |
| H₃   | D₆       | ℚ(√5)       | Icosahedral (3D)     |
| H₄   | E₈       | ℚ(√5)       | Hyper-icosahedral (4D) |

### Galois Conjugation: Relating E∥ and E⊥

For a quadratic Coxeter pair, the field extension is 𝕂 = ℚ(√D) where D is a
square-free positive integer (D = 5 for the Penrose case). The embedding space
splits into two subspaces of equal dimension:

- **E∥** (parallel space, "+"), where the physical tiling lives
- **E⊥** (perpendicular space, "−"), the internal/phason space

These two spaces are related by the Galois conjugation √D → −√D. In the
Penrose case this sends √5 → −√5, which is equivalent to:

    τ = (1 + √5)/2  ↦  σ = (1 − √5)/2

This conjugation appears concretely in the eigenspaces of the Coxeter element
P. As described in §4 above, P has eigenvalues e^(±2πi/5) (spanning E∥) and
e^(±4πi/5) (spanning E⊥). The doubling 2π/5 → 4π/5 *is* the Galois
conjugation acting on the roots of unity: since cos 2π/5 = (√5 − 1)/4, 
replacing √5 → −√5 gives cos 4π/5 = −(√5 + 1)/4.

The projection bases for the two subspaces are:

    E∥: (P⁺)ᵢ = √(2/5) (cos 2πi/5, sin 2πi/5)

    E⊥: (P⁻)ᵢ = √(2/5) (cos 4πi/5, sin 4πi/5)

Any rational point **x** in the embedding space splits as **x** = P⁺**x** + P⁻**x**,
and the two sets of 2D coordinates are related by √5 → −√5: if the parallel
coordinates involve expressions like (√5 − 1)/4, the perpendicular coordinates
involve (−√5 − 1)/4.

This is the same Galois conjugation that produces the two rings of projected
roots in the Hexadic Diamond: the outer/middle radius ratio τ arises because
the d = 2 roots (εᵢ − εᵢ₊₂) involve cos 4π/5 while the d = 1 roots
(εᵢ − εᵢ₊₁) involve cos 2π/5, and these are Galois conjugates of each other.

### Self-Similar 1D Quasilattices and the Substitution Rule

The Ammann pattern underlying the Penrose tiling is built from five families
of parallel lines, each spaced according to a 1D Fibonacci quasilattice. These
quasilattices are described by the floor form (Eq. 1 of Boyle & Steinhardt,
arXiv:1608.08220):

    xₙ = S(n − α) + (L − S)⌊κ(n − β)⌋

where L and S are the long and short intervals, κ = 1/τ is the frequency
parameter, α is the translational phase, and β is the phason phase. The
parameters for the Penrose case (Case 1, Table I of the 1D paper) are:

| Parameter | Value | Expression |
|-----------|-------|------------|
| λ₊ (scale factor) | 1.6180… | (1 + √5)/2 = τ |
| λ₋ (⊥ contraction) | −0.6180… | (1 − √5)/2 = σ |
| m₂⁺/m₁⁺ (tile ratio) | τ | (1 + √5)/2 |
| m₂⁻/m₁⁻ (frequency ratio) | σ | (1 − √5)/2 |
| m₁⁺ | 0.2764… | (5 − √5)/10 |
| m₂⁺ | 0.4472… | 1/√5 |
| κ₁ | 0.6180… | 1/τ |
| κ₂ | 0.3820… | 2 − τ |

The substitution matrix τ = [[0,1],[1,1]] has eigenvalues λ₊ = τ and λ₋ = σ.
The eigenvector for λ₊ determines tile length ratios in E∥; the eigenvector
for λ₋ determines tile frequency ratios in E⊥. These are Galois conjugates.

The canonical substitution rule is:

    S′ → (L/2)(L/2)
    L′ → (L/2)S(L/2)

### The Star Vectors and Their Galois Conjugates

The Ammann pattern is constructed from a star of unit vectors in E∥:

    **a**ⱼ⁺ = (cos 2πj/5, sin 2πj/5)    j = 0, …, 4

Each 2D vector lifts to a 4D vector **a**ⱼ in the A₄ embedding space, and the
perpendicular projection gives the Galois conjugate:

    **a**ⱼ⁻ = (cos 4πj/5, sin 4πj/5)

A second set of vectors is defined by **b**ⱼ⁺ = −(m₁⁻/m₂⁻) **a**ⱼ⁺ = τ **a**ⱼ⁺, with
the perpendicular counterpart **b**ⱼ⁻ = σ **a**ⱼ⁻. For j = 1:

| Vector | E∥ components | E⊥ components |
|--------|--------------|--------------|
| **a**₁ | (cos 2π/5, sin 2π/5) ≈ (0.3090, 0.9511) | (cos 4π/5, sin 4π/5) ≈ (−0.8090, 0.5878) |
| **b**₁ | τ(cos 2π/5, sin 2π/5) ≈ (0.5000, 1.5388) | σ(cos 4π/5, sin 4π/5) ≈ (0.5000, −0.3633) |

These satisfy the decoupling identity (Eq. 20 of the Coxeter paper):

    m₁± **a**ⱼ∓ + m₂± **b**ⱼ∓ = 0

This can be verified directly: **b**ⱼ⁻ = σ **a**ⱼ⁻, so
m₁⁺ **a**ⱼ⁻ + m₂⁺ **b**ⱼ⁻ = m₁⁺ **a**ⱼ⁻ + τ m₁⁺ σ **a**ⱼ⁻ = m₁⁺(1 + τσ) **a**ⱼ⁻ = 0
since τσ = −1. This identity ensures that the translational phase χ⁺ and the
phason phase χ⁻ decouple completely in Eq. (18).

### The Translation Vector **q**₀ and the Cut-and-Project Scheme

The vector **q**₀ in Eq. (12) of the Coxeter paper is the offset of the cut
surface from the origin of the A₄ lattice. It is the translation vector of
the standard cut-and-project construction. Its decomposition into parallel and
perpendicular parts plays two distinct roles:

- **q**₀⁺ (parallel part): translates the tiling rigidly in physical space.
  This appears in Eq. (18) through χ⁺, which shifts the argument (n − χ⁺)
  in the floor form — a uniform slide of all Ammann lines that does not
  change the combinatorial structure.

- **q**₀⁻ (perpendicular part): the phason degree of freedom. This appears
  through χ⁻, which shifts the argument inside the floor function
  ⌊κ(n − χ⁻)⌋, changing where the floor function jumps and thereby
  rearranging the L/S ordering. Different values of **q**₀⁻ give tilings
  that are locally isomorphic but globally distinct.

Under inflation, the phases transform as χ± → χ±/λ± (Eq. 21). The condition
for a self-same tiling (one identical to itself after inflation, up to
rescaling) is that **q**₀ is a fixed point of this transformation modulo the
A₄ lattice.

The star vectors **a**ⱼ⁺ in 2D serve as an overcomplete frame (five vectors
spanning ℝ²). They are the projections of directions that form a proper basis
in the 4D embedding space. In the dualization formula (Eq. 32), each cell of
the multigrid is labeled by five integer coordinates (ν₁, …, ν₅), and the
dual vertex is:

    **x**′ = −**q**₀∥ + (m̄⁺/γ) Σⱼ νⱼ **e**ⱼ

where m̄⁺ is the average step size, γ = 5/2, and the representation is
overcomplete (five coordinates for a 2D space), with the redundancy resolved
by the pentagrid constraints.

### Worked Example: Decomposing **q**₀

Consider a specific translation vector expressed as a rational linear
combination of the A₄ fundamental roots:

    **q**₀ = (1/3) **f**₁ + (1/7) **f**₂ + (1/5) **f**₃ + (2/5) **f**₄

Using the fundamental roots from Eq. (36) of the Coxeter paper:

    **f**₁ = (−1, +1, 0, 0, 0),  **f**₂ = (0, −1, +1, 0, 0)
    **f**₃ = (0, 0, −1, +1, 0),  **f**₄ = (0, 0, 0, −1, +1)

this gives in ℝ⁵:

    **q**₀ = (−0.3333, 0.1905, −0.0571, −0.2000, 0.4000)

Projecting onto E∥ and E⊥ using the orthonormalized bases:

    **q**₀⁺ = (0.0362, −0.0729)      (small — translational phase)
    **q**₀⁻ = (−0.5633, −0.1638)     (large — phason phase)

The striking asymmetry illustrates how the Galois conjugation redistributes
the same rational coefficients very differently between the two subspaces.

### Computing the Phase Parameters χ±

From Eq. (18), with ({α}, {β}) = (0, 0), the phase parameters for each
Ammann direction j = 0, …, 4 are:

    χ₁,ⱼ± = (1 + (m₂±/m₁±)²) **a**ⱼ± · **q**₀±

Since m₂⁺/m₁⁺ = τ, the parallel prefactor is 1 + τ² = 2 + τ ≈ 3.618.
Since m₂⁻/m₁⁻ = σ, the perpendicular prefactor is 1 + σ² = 2 + σ ≈ 1.382.

The computed values are:

| j | χ₁,ⱼ⁺ (translational) | χ₁,ⱼ⁻ (phason) |
|---|----------------------|----------------|
| 0 | +0.1308 | −0.7783 |
| 1 | −0.2105 | +0.4966 |
| 2 | −0.2609 | −0.0252 |
| 3 | +0.0492 | −0.4558 |
| 4 | +0.2913 | +0.7627 |

The χ⁺ values are all small (comparable to **q**₀⁺) and produce only a rigid
shift of the Ammann lines. The χ⁻ values are much larger and enter the floor
function ⌊κ₁(n − χ₁,ⱼ⁻)⌋, where they control the L/S ordering of intervals
along each direction — the structural content of the tiling.

### Connection to the Hexadic Diamond

The Hexadic Diamond uses the *same* Coxeter-plane projection (E∥, the 72°
eigenplane) and the *same* decomposition E∥ ⊕ E⊥ as the Penrose tiling
cut-and-project scheme. The difference lies in what is projected:

- **Penrose tiling**: projects all A₄ lattice points within a geometric
  acceptance window in E⊥, producing an infinite aperiodic pattern.
- **Hexadic Diamond**: projects a finite algebraically-selected subset
  (the 20 roots, 10 weights, and origin), producing a finite 31-point
  diagram.

The golden ratio τ that appears as the outer/middle radius ratio in the
Hexadic Diamond is the *same* τ that appears as the inflation scale factor
λ₊ in the Penrose tiling, and both arise from the eigenvalue structure of the
Coxeter element of A₄ acting on E∥ vs E⊥ — related by the Galois conjugation
√5 → −√5.

---

## The Single External Input

The only element of the construction not derived from A₄ is the harmonic
assignment:

    ε₀ → 3,  ε₁ → 5,  ε₂ → 7,  ε₃ → 9,  ε₄ → 11

This maps each basis vector to an odd harmonic, so that a lattice vector
(a, b, c, d, e) represents the ratio 3ᵃ · 5ᵇ · 7ᶜ · 9ᵈ · 11ᵉ. Everything
else — the projection geometry, the golden ratio in the radial structure, the
star-line connectivity, the otonal/utonal duality — follows from the Coxeter
theory of A₄.
