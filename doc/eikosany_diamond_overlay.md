# Erv Wilson's Eikosany on the Hexadic Diamond — A Coxeter-Theoretic Account

## Overview

Notebook `hexadicDiamond.ipynb` shows that Erv Wilson's 20-note Eikosany
overlays on the 31-point Hexadic Diamond in exactly **10 distinct variants**,
each obtained by dividing all Eikosany notes by one of 10 specific Eikosany
ratios. This note records why there are exactly 10, why each variant shares
exactly 10 of its 20 points with the Hexadic Diamond, and why the 10 variants
together cover the diamond's 31 points without exception.

The structure is fully accounted for by the Coxeter theory of the **A₄** root
system together with its noncrystallographic partner **I₂⁵** under the
quadratic Coxeter pair {I₂⁵, A₄} (Boyle & Steinhardt, *Phys. Rev. B* **106**,
144113, 2022). The companion document `hexadic_diamond_coxeter.md` develops
the A₄/I₂⁵ derivation of the Hexadic Diamond itself; the present note builds
on that to explain the Eikosany overlay.

**Implementations.** Two notebooks compute the overlay:
- `hexadicDiamond.ipynb` — numpy-based, identifies the 10 outer-ring divisors
  by projection-distance.
- `eikosany_diamond_coxeter.ipynb` — SageMath / A₄ Coxeter-machinery version
  that constructs everything from W(A₄)-orbits and generates the 10 divisors
  by iterating the Coxeter element c = s₁s₂s₃s₄ on two seeds (no projection
  geometry until the final plot).

---

## 1. The Eikosany as an A₅ Object — Pascal's Triangle Origin

The Eikosany is the combination product set C(6, 3) = 20: the 6 generators
{1, 3, 5, 7, 9, 11} taken three at a time. Geometrically, its 20 points are
the **vertices of the birectified 5-simplex**, i.e. the centroids of the
2-faces of the regular 5-simplex. Their natural symmetry group is **A₅ = S₆**.

Pascal's triangle row 6 enumerates all face counts of the 5-simplex:

| k | C(6, k) | A₅ object                              |
|---|--------|----------------------------------------|
| 0 | 1      | empty face                             |
| 1 | 6      | vertices of 5-simplex                  |
| 2 | 15     | edges (rectified 5-simplex vertices)   |
| **3** | **20** | **2-faces (Eikosany — birectified 5-simplex vertices)** |
| 4 | 15     | 3-faces (dual of edges)                |
| 5 | 6      | 4-faces (dual of vertices)             |
| 6 | 1      | the simplex itself                     |

The Eikosany sits at the *centre* of the row, exactly because C(6, 3) is the
self-dual middle entry of row 6.

---

## 2. The A₄ ⊂ A₅ Branching — How the Eikosany Splits

A projection, adopted from Penrose Tiling, embeds **A₄ ⊂ A₅** by treating the
harmonic "1" as the trivial generator: in 5D, the exponent of "1" is identically
zero. Concretely, in `eiko_6` the first column is dropped to give `eiko_5 = eiko_6[:,1:]`, the 5D embedding used for the projection.

Under this branching, Pascal's identity

$$C(6,3) \;=\; C(5,2) \;+\; C(5,3) \;=\; 10 + 10$$

is exactly the decomposition of the Eikosany into its two **A₄ fundamental-
weight orbits**:

| Eikosany piece | Count | A₄ orbit | Description                      |
|---|---|---|---|
| Notes containing "1" (e.g. 1·3·5)    | C(5,2) = 10 | **Λ₂** | 2-sums of distinct εᵢ |
| Notes not containing "1" (e.g. 3·5·7) | C(5,3) = 10 | **Λ₃** | 3-sums of distinct εᵢ |

So in A₄ coordinates,

$$\text{Eikosany} \;=\; \Lambda_2 \;\sqcup\; \Lambda_3.$$

The Pascal recurrence C(n+1,k) = C(n,k−1) + C(n,k) *is* the branching rule
for the standard A_{n} subgroup of A_{n+1} — recasting the row 6 / row 5
identity as a Coxeter-theoretic statement.

---

## 3. The Diagram Automorphism — Pascal's Symmetry as Otonal/Utonal Duality

Pascal row 5 is symmetric: C(5, k) = C(5, 5−k). On the A₄ side, this symmetry
is the **diagram automorphism** of the Dynkin diagram

    α₁    α₂    α₃    α₄
    ○ ─── ○ ─── ○ ─── ○

— the unique non-trivial involution that flips it left-to-right.
Equivalently it is the map **x ↦ −w₀(x)**, where w₀ ∈ W(A₄) is the longest
Weyl-group element (the permutation reversing all 5 indices). On standard
basis vectors it acts as εᵢ ↔ −ε_{4−i}, intertwining fundamental weights as

$$\Lambda_k \;\longleftrightarrow\; \Lambda_{n+1-k} \quad (\text{for } A_n).$$

For A₄ the involution induces the following pairing on the small W-orbits:

| Pascal entry | paired with     | A₄ orbit pair | Musical meaning |
|---|---|---|---|
| C(5, 0) = 1  | C(5, 5) = 1     | {0} ↔ {0}     | unison ↔ unison |
| C(5, 1) = 5  | C(5, 4) = 5     | **Λ₁ ↔ Λ₄**   | **otonal ↔ utonal** |
| C(5, 2) = 10 | C(5, 3) = 10    | **Λ₂ ↔ Λ₃**   | **Eikosany "with 1" ↔ Eikosany "no 1"** |

Pascal row 5 is *self-conjugate* under this involution, and that
self-conjugacy is the same fact as the otonal/utonal duality.

### The (1,1,1,1,0) ≡ −εᵢ identity

The pairing C(5, 4) ↔ C(5, 1) is concrete in the ambient-space realisation.
The A₄ weight space is the quotient

$$\mathbb{R}^5 \big/ \mathbb{R}\cdot\mathbf{1}, \qquad \mathbf{1} = (1,1,1,1,1),$$

i.e. two ambient vectors represent the same A₄ weight iff they differ by a
multiple of **1**. The projection to E∥ is built from the eigenvector for
ζ₅, which is orthogonal to **1**, so the projection annihilates **1** —
equivalent ambient vectors land on the same 2D point.

A C(5, 4) vector has the form **1** − εᵢ (four 1's and a single 0). Modulo
**1** this is

$$\mathbf{1} - \varepsilon_i \;\equiv\; -\varepsilon_i \pmod{\mathbf{1}}.$$

So the five C(5, 4) vectors are *the same A₄ weights* as the five utonal
harmonics −εᵢ (musically 1/3, 1/5, 1/7, 1/9, 1/11). Concretely, in the
Bourbaki normalisation used in `hexadic_diamond_coxeter.md`:

    Λ₁ = ε₀                              ≡  ε₀         (otonal)
    Λ₄ = ε₀ + ε₁ + ε₂ + ε₃ − (4/5)·𝟏    ≡  −ε₄        (utonal)

and similarly **Λ₂ ≡ −Λ₃ (mod 1)** ties the two halves of the Eikosany
together: the inner-ring Λ₂ orbit and the outer-ring Λ₃ orbit are
diagram-conjugate to one another.

In `hexadicDiamond.ipynb` the 5 utonals are stored in 5D as the literal −εᵢ
vectors (e.g. `(-1, 0, 0, 0, 0)`) rather than as **1** − εᵢ. Both forms
project to the same 2D points; the notebook's choice just makes the
otonal/utonal duality typographically obvious.

### Geometric consequence in the diamond and the Eikosany

Wilson's placement of otonals (Λ₁) and utonals (Λ₄) on the **same inner
ring** of the Hexadic Diamond is exactly the geometric realisation of the
diagram automorphism: |Λ₁| = |Λ₄| in E∥ because they are the *same orbit
modulo* **1**. The two interleaved pentagons (otonal red, utonal blue) at
the inner radius differ by a 36° rotation — the I₂⁵ rotation by π/5, which
realises the diagram automorphism as a physical rotation of the Coxeter
plane.

The same automorphism organises the Eikosany. Its inner ring (Λ₂) and outer
ring (Λ₃) are related by Λ₂ ↔ Λ₃ under the diagram involution; their projected
radii sit in ratio τ² because the involution acts on E∥ together with the
Galois conjugation √5 → −√5 of the {I₂⁵, A₄} Coxeter pair (the τ² factor
is Galois conjugation applied twice, i.e., once on each ring). The
interleaving of Λ₂- and Λ₃-vertices around the outer-ring decagon (§5
below) is then the same kind of geometric duality: a 36° rotation of E∥
swaps the Λ₂ pentagon with the Λ₃ pentagon at the same outer radius.

So: every otonal/utonal-style pairing in the construction — diamond inner
ring, outer-ring decagon interleaving, Λ₂/Λ₃ ring-radius duality — is one
and the same diagram automorphism, presented in different geometric guises.

---

## 4. Complementarity with the Hexadic Diamond

`hexadic_diamond_coxeter.md` establishes that the Hexadic Diamond decomposes
in A₄ as

$$\text{Hexadic Diamond} \;=\; \{0\} \;\sqcup\; \Lambda_1 \;\sqcup\; \Lambda_4 \;\sqcup\; \Phi(A_4)$$

— the origin, the otonal weights (Λ₁ ≅ +εᵢ, 5 points), the utonal weights
(Λ₄ ≅ −εᵢ, 5 points), and the 20 A₄ roots εᵢ − εⱼ. Thus

| A₄ piece           | In the Diamond? | In the Eikosany? |
|--------------------|:---:|:---:|
| origin {0}         | ✓ | — |
| Λ₁ (otonal weights) | ✓ | — |
| Λ₂ (= "with 1" Eikosany) | — | ✓ |
| Λ₃ (= "no 1" Eikosany)   | — | ✓ |
| Λ₄ (utonal weights) | ✓ | — |
| Φ (20 roots)        | ✓ | — |

The Eikosany and the Hexadic Diamond are **combinatorial complements** within
the small A₄ orbit families: together they exhaust {0} ⊔ Λ₁ ⊔ Λ₂ ⊔ Λ₃ ⊔ Λ₄ ⊔ Φ
— i.e. every fundamental-weight orbit and the root orbit. The two musical
constructions are two halves of the same Coxeter-theoretic object.

---

## 5. The {I₂⁵, A₄} Coxeter Pair and the Two Concentric Decagons

Under projection to E∥ (the 72° eigenplane of the Coxeter element), each A₄
orbit produces **N = 2 scaled copies of an I₂⁵ orbit** — the defining property
of the Coxeter pair {I₂⁵, A₄} (Boyle–Steinhardt 2022, §"Coxeter Pair";
companion doc §"The Coxeter Pair"). The two copies are Galois conjugates: their
radii differ by **τ = (1 + √5)/2**.

| A₄ piece          | In E∥                                         |
|------|------|
| 20 roots Φ        | 10 I₂⁵-roots × 2 scales (radii in ratio τ): diamond's *middle* and *outer* rings |
| Λ₁ ⊔ Λ₄ (10 weights) | 10 weights = decagon at single radius (diamond's *inner* ring) |
| Λ₂ ⊔ Λ₃ (Eikosany, 20 weights) | 10 + 10, two decagons at radii in ratio τ² |

The Eikosany's two rings sit at radii proportional to **1/τ** and **τ**.
Empirically, with the user's projection normalisation:

```
Outer ring: |·| ≈ 1.0233   (10 points)
Inner ring: |·| ≈ 0.3909   (10 points)
ratio      : 2.6180         (= τ², matches theory exactly)
```

The 10 outer-ring Eikosany points form **a single I₂⁵ orbit** — a regular
decagon at radius τ in E∥. They are precisely the 10 ratios used as divisors.

### The orbit interleaves Λ₂ and Λ₃

Sorting the 10 outer-ring points by polar angle reveals that they alternate
between the two A₄ orbits:

```
angle  ratio   A₄ orbit
─────  ─────   ────────
…      315     Λ₃ (5·7·9)
…      35      Λ₂ (1·5·7)
…      105     Λ₃ (3·5·7)
…      15      Λ₂ (1·3·5)
…      165     Λ₃ (3·5·11)
…      33      Λ₂ (1·3·11)
…      297     Λ₃ (3·9·11)
…      99      Λ₂ (1·9·11)
…      693     Λ₃ (7·9·11)
…      63      Λ₂ (1·7·9)
```

That is, the I₂⁵ decagon at the outer radius is the **interleaving** of the
5-element Λ₂-adjacent set with the 5-element Λ₃-complement-adjacent set.
Geometrically this is the standard "double-cover" structure of a regular
decagon viewed as two interlocked pentagons.

In Wilson's notation the 5 Λ₂ outer points are products `1·a·b` with primes
a, b adjacent in the cycle (3, 5, 7, 9, 11), while the 5 Λ₃ outer points are
products `a·b·c` whose complement {x, y} ⊂ {3, 5, 7, 9, 11} is an adjacent
pair.

---

## 6. The 10 Variants — Why 10

Dividing all Eikosany notes by an outer-ring ratio P translates the Eikosany
in 5D by **−P** (in the additive lattice of prime exponents). The 10 outer-ring
P's are an I₂⁵ orbit, so the 10 translations are an I₂⁵ orbit of overlays.

Equivalently: the dihedral I₂⁵ ≅ D₁₀ symmetry of the Coxeter plane acts
transitively on the 10 outer-ring points; each variant is one orbit element.
**There are 10 because |I₂⁵| roots = 10.**

---

## 7. Each Variant Shares Exactly 10/20 Points With the Diamond

For a translation by P, an Eikosany note Q lands on a Hexadic Diamond point
iff the difference Q − P is one of {0, ±εᵢ, εᵢ − εⱼ}. The combinatorics depend
only on the cardinalities |P|, |Q| and the overlap |Q ∩ P| in the 5D
representation (where Λ₂ has |·|=2 and Λ₃ has |·|=3):

### Divisor P ∈ Λ₂ (|P| = 2, e.g. P = 1·3·5 → P_5D = (1,1,0,0,0))

| Q ∈ | |Q∩P| | |Q\P| | |P\Q| | Q − P shape          | Diamond? | # such Q |
|-----|:---:|:---:|:---:|----------------------|:---:|:---:|
| Λ₂ | 2 | 0 | 0 | 0 (origin)             | ✓ | 1 |
| Λ₂ | 1 | 1 | 1 | one +1, one −1 (root)  | ✓ | 6 |
| Λ₂ | 0 | 2 | 2 | two +1, two −1         | ✗ | 3 |
| Λ₃ | 2 | 1 | 0 | one +1 (otonal weight) | ✓ | 3 |
| Λ₃ | 1 | 2 | 1 | two +1, one −1         | ✗ | 6 |
| Λ₃ | 0 | 3 | 2 | three +1, two −1       | ✗ | 1 |

**Hits = 1 + 6 + 3 = 10.**

### Divisor P ∈ Λ₃ (|P| = 3, e.g. P = 3·5·7 → P_5D = (1,1,1,0,0))

| Q ∈ | |Q∩P| | |Q\P| | |P\Q| | Q − P shape          | Diamond? | # such Q |
|-----|:---:|:---:|:---:|----------------------|:---:|:---:|
| Λ₂ | 2 | 0 | 1 | one −1 (utonal weight) | ✓ | 3 |
| Λ₂ | 1 | 1 | 2 | one +1, two −1         | ✗ | 6 |
| Λ₂ | 0 | 2 | 3 | two +1, three −1       | ✗ | 1 |
| Λ₃ | 3 | 0 | 0 | 0 (origin)             | ✓ | 1 |
| Λ₃ | 2 | 1 | 1 | one +1, one −1 (root)  | ✓ | 6 |
| Λ₃ | 1 | 2 | 2 | two +1, two −1         | ✗ | 3 |

**Hits = 3 + 1 + 6 = 10.**

### Universal hit pattern

Both kinds of divisor produce the same total — and the same breakdown:

$$10 \;=\; \underbrace{1}_{\text{origin}} \;+\; \underbrace{6}_{\text{roots}} \;+\; \underbrace{3}_{\text{otonal or utonal weights}}$$

A Λ₂ divisor produces 3 *otonal* hits (positive single-εᵢ); a Λ₃ divisor
produces 3 *utonal* hits (negative single-εᵢ). The 6 root hits and the 1
origin hit are common to both.

This is purely Coxeter-theoretic: it is the multiplicity decomposition of the
fundamental-weight orbit-difference $\Lambda_i - \Lambda_j$ inside the small
weights and roots of A₄.

---

## 8. The Union of the 10 Variants Covers the Entire Hexadic Diamond

Aggregating the 10 × 20 = 200 translated Eikosany points and reducing in 5D:

```
Total Eikosany-points across 10 variants : 200  (= 10 × 20)
Distinct points (5D)                     : 111
  ↳ coincident with Hexadic Diamond      : 31  / 31 diamond points
  ↳ outside the Hexadic Diamond          : 80
```

**Every one of the 31 Hexadic Diamond points is covered.** None is missed.

That this is exactly 31/31 is a symmetry statement: the 10 outer-ring divisors
form an I₂⁵ orbit, and the diamond is itself I₂⁵-symmetric (5-fold rotation +
reflection in E∥). Any single variant's 10 hits are a "sector"; rotating
through the full I₂⁵ orbit of 10 variants saturates the diamond. The
universal 10 = 1 + 6 + 3 hit pattern scaled by 10 variants gives 100 hits,
spread across 31 points with the following multiplicity:

| Diamond piece                  | # points | hits / point | total hits |
|--------------------------------|:---:|:---:|:---:|
| origin {0}                     | 1   | 10  | 10  |
| otonal weights (Λ₁ = +εᵢ)      | 5   | 3   | 15  |
| utonal weights (Λ₄ = −εᵢ)      | 5   | 3   | 15  |
| middle-ring roots (d = 1, |·|=τ⁻¹·…) | 10  | 2   | 20  |
| outer-ring roots (d = 2, |·|=τ·…)    | 10  | **4**   | **40**  |
| **Total**                      | **31** |     | **100** |

A striking feature: the **outer-ring roots are hit twice as often as the
middle-ring roots** — a further τ-signature in the multiplicity, distinct
from but parallel to the τ-ratio in the radii. The 10 weights (otonal +
utonal) are hit uniformly because the I₂⁵ rotation by π/5 swaps the otonal
pentagon with the utonal pentagon, equalising their hit counts.

The 80 distinct points lying *outside* the Hexadic Diamond are A₄ lattice
points the construction reaches but which the diamond's combinatorial filter
("at most one positive and at most one negative exponent") excludes — they
are the residue of richer A₄ structure not encoded in the 31-point Diamond.

---

## 9. Summary Table

| Quantity | Value | Coxeter origin |
|---|---|---|
| Eikosany size                                 | C(6, 3) = 20 | Birectified 5-simplex, A₅ |
| Branching A₄ ⊂ A₅                             | C(6,3) = C(5,2) + C(5,3) | Pascal recurrence |
| Eikosany A₄ pieces                            | Λ₂ ⊔ Λ₃ (10 + 10) | Fundamental-weight orbits |
| Otonal/utonal duality                         | Λ₁ ↔ Λ₄, Λ₂ ↔ Λ₃ | Diagram automorphism of A₄ (Λₖ ↔ Λ_{n+1−k}); equivalently Pascal row 5 self-conjugacy |
| Hexadic Diamond size                          | 31 | {0} ⊔ Λ₁ ⊔ Λ₄ ⊔ Φ |
| Number of overlay variants                    | 10 | I₂⁵ orbit (Coxeter pair {I₂⁵, A₄}) |
| Outer/inner Eikosany radius ratio             | τ² = 2.618… | Galois conjugation √5 → −√5 |
| Diamond outer/middle radius ratio             | τ = 1.618… | Same Galois pair |
| Hits per variant                              | 10 = 1 + 6 + 3 | origin + roots + weights (depends only on \|P\|) |
| Diamond points covered by either ring alone   | 31 / 31 | I₂⁵ symmetry of diamond + variants |
| Distinct 5D points (outer or inner alone)     | 111 | 31 in diamond + 80 outside |
| Distinct 5D points (inner ∪ outer)            | 141 | 81 shared + 30 unique each ring |
| Distinct ratios after 9 = 3² dedup (combined) | 115 | 29 on diamond + 86 off-diamond |
| Galois multiplicity swap (root rows)          | 4 ↔ 2 | τ ↔ 1/τ on hits/pt for d=1 vs d=2 roots |
| Combined hits/pt on non-origin diamond pts    | 6 (uniform) | Galois-symmetric coverage of inner + outer |

---

## 10. The Inner-Ring Overlay and Galois-Conjugate Coverage

The 10 outer-ring divisors (radius τ) form one C₅-orbit pair under the
Coxeter element c. The 10 **inner-ring** Eikosany points (radius 1/τ) form
the *other* C₅-orbit pair, generated by switching adjacent seeds for
non-adjacent ones:

| Ring | Λ₂ seed | Λ₃ seed | Generated divisors (musical) |
|---|---|---|---|
| outer (radius τ)   | ε₀ + ε₁    | ε₀ + ε₁ + ε₂  | 15, 35, 63, 99, 33  /  105, 315, 693, 297, 165 |
| inner (radius 1/τ) | ε₀ + ε₂    | ε₀ + ε₁ + ε₃  | 21, 45, 77, 27, 55  /  135, 385, 189, 495, 231 |

Translating the Eikosany by each inner-ring divisor produces a parallel
family of 10 overlay variants — **20 variants total** between the two rings.

### 10.1 Per-variant hit count is identical: 10 / 20

The §7 orbit-difference combinatorics depend only on |P| ∈ {2, 3} (whether
the divisor is Λ₂ or Λ₃), *not* on cyclic adjacency. So each inner-ring
variant decomposes as

$$10 \;=\; \underbrace{1}_{\text{origin}} \;+\; \underbrace{6}_{\text{roots}} \;+\; \underbrace{3}_{\text{weights}}$$

exactly like the outer-ring variants. Only the *positions* of the 6 root
hits and 3 weight hits among the 31 diamond points differ between the two
ring families — and that difference is the next observation.

### 10.2 The Galois multiplicity swap

The two ring families differ in *which* roots they emphasise. Counting hits
per diamond point across the 10 variants of each family:

| Diamond piece                       | # pts | inner hits/pt | outer hits/pt | combined |
|---|:---:|:---:|:---:|:---:|
| origin                              | 1     | 10  | 10  | 20 |
| otonals (Λ₁)                        | 5     | 3   | 3   | 6  |
| utonals (Λ₄)                        | 5     | 3   | 3   | 6  |
| middle-ring roots (d=1, length 1)   | 10    | **4** | **2** | 6 |
| outer-ring roots (d=2, length τ)    | 10    | **2** | **4** | 6 |
| **Total hits**                      | **31**| **100** | **100** | **200** |

The 4 ↔ 2 swap on the two root rows *is* the τ ↔ 1/τ Galois conjugation
acting on the multiplicity distribution: each ring of divisors privileges
the ring of root hits at the **same radius scale**. The outer ring (at τ)
over-counts d=2 (length-τ) roots; the inner ring (at 1/τ) over-counts d=1
(length-1) roots.

Adding the two families together gives a perfectly **uniform 6-hit
multiplicity** on every non-origin diamond point — fully Galois-symmetric
coverage in which the τ ↔ 1/τ conjugation has been integrated out.

### 10.3 Combined coverage: the 20-variant overlay

Each ring **independently** saturates the 31-point Hexadic Diamond:

| Family | Distinct 5D positions | On diamond | Off diamond |
|---|:---:|:---:|:---:|
| inner alone           | 111  | 31 / 31 | 80  |
| outer alone           | 111  | 31 / 31 | 80  |
| **inner ∪ outer**     | **141**  | **31 / 31** | **110** |
| (shared)              | 81   | — | — |

Each ring contributes 30 unique off-diamond points, for 60 new points
beyond the 81 they share.

After deduping by *prime form* (Wilson-redundant 9 = 3² collisions merged):

| Family | Distinct ratios | On diamond | Off diamond |
|---|:---:|:---:|:---:|
| outer alone           | 93   | 29 | 64 |
| inner alone           | 93   | 29 | 64 |
| **inner ∪ outer**     | **115** | **29** | **86** |

The inner ring contributes **22 new pitch classes** beyond the 93 the outer
ring alone reaches. The diamond's 31 5D vectors collapse to 29 distinct
ratios because the same 9 = 3² collisions (`ε₃ − ε₀ ≡ ε₀`,
`ε₀ − ε₃ ≡ −ε₀`) merge two roots with two weights — and including the inner
ring does not change this number.

Implemented in `eikosany_diamond_coxeter.ipynb` cells 18–25 (inner-ring
construction, multiplicity-swap table, joint coverage figure, 20-variant
overlay, combined prime-form HEJI listing).

---

## 11. Open Direction: Other Quadratic Coxeter Pairs

The same machinery — finite W-orbits + a Coxeter element generating a
cyclic refinement that survives projection — applies to every quadratic
Coxeter pair. From the `hexadic_diamond_coxeter.md` table:

| θ∥   | θ          | Field 𝕂   | Symmetry                | Musical analogue |
|------|------------|-----------|-------------------------|-----|
| I₂⁵  | A₄         | ℚ(√5)     | 5-fold (Penrose)        | this work |
| I₂⁸  | B₄ / C₄    | ℚ(√2)     | 8-fold (Ammann–Beenker) | 4 odd-prime / 8-CPS variant? |
| I₂¹² | F₄         | ℚ(√3)     | 12-fold                 | — |
| H₃   | D₆         | ℚ(√5)     | Icosahedral 3D          | 6-prime CPS, three-dimensional |
| H₄   | E₈         | ℚ(√5)     | Hyper-icosahedral 4D    | — |

Two specific ports are worth working out:

**{I₂⁸, B₄/C₄}.** Replace A₄ with B₄ (rank 4, 32 short + 8 long = 40 roots,
W = signed permutations on 4 letters). Pick a 4-prime harmonic assignment
(say {3, 5, 7, 11}). The Hexadic-Diamond analogue would be
{0} ⊔ Λ₁ ⊔ Λ_n ⊔ Φ(B₄), and the Eikosany analogue would be a
fundamental-weight pair Λᵢ ⊔ Λⱼ chosen so that their union is preserved by
the Coxeter element. The projection lands in an 8-fold-symmetric Coxeter
plane (the I₂⁸ partner), and the τ from ℚ(√5) is replaced by 1 + √2 from
ℚ(√2) — the silver ratio. The "10 variants" count would change to whatever
the dihedral-8 orbit cardinality demands.

**{H₃, D₆}.** Three-dimensional icosahedral analogue. D₆ has rank 6, 60
roots, and W of order 23040. Pick six odd primes; the Eikosany analogue is
again a sum-of-fundamental-weight-orbits chosen to match the Coxeter
element's cyclic refinement. The "diamond" would be a 3D figure rather than
a 2D one, and the I₂⁵-style 10-fold dihedral symmetry is replaced by the
icosahedral group H₃.

In every case the construction template is the same:

1. Build the Coxeter system in Sage: `RootSystem(['B', 4])`, etc.
2. Identify the analogue of "Λ₂ ⊔ Λ₃" — a union of fundamental-weight
   orbits that gives a self-paired CPS-like set under the Coxeter element.
3. Identify "diamond" pieces from {0} + minuscule weights + Φ.
4. Generate translation seeds by Coxeter-element iteration on chosen
   representatives.
5. Project to the Coxeter plane (or 3D Coxeter cone for H₃) via the
   appropriate cyclotomic eigenvector and render.

The combinatorial bookkeeping (per-variant hit count, joint coverage of the
diamond, what Galois-conjugate scale relates inner and outer rings) will be
specific to each case but should follow from the same orbit-difference
combinatorics worked out in §7 above.

---

## 12. The Two Sentences

**The Eikosany overlay on the Hexadic Diamond is the A₄ ⊂ A₅ branching of
C(6, 3) into Λ₂ ⊔ Λ₃, projected through the {I₂⁵, A₄} Coxeter pair; each of
the two C₅-orbit pairs of divisors (10 outer-ring at radius τ from adjacent
seeds, 10 inner-ring at radius 1/τ from non-adjacent seeds) independently
saturates the diamond, with every variant's 10 shared points decomposing as
1 origin + 6 roots + 3 weights from orbit-difference combinatorics in A₄.**

**Combining both ring families gives 20 variants whose root multiplicities
are τ ↔ 1/τ Galois conjugates (the 4 ↔ 2 swap between d=1 and d=2 roots),
summing to a uniform 6-hit multiplicity per non-origin diamond point —
Galois-symmetric coverage that reaches 115 distinct JI ratios in 141
distinct 5D positions (29 on the Hexadic Diamond, 86 outside).**
