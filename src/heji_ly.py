"""
heji_ly.py — Convert JI exponents to a heji-ly LilyPond string.

Primary entry point:
    exponents_to_heji_ly([i0, i1, i2, i3, i4], base_octave=4)
    → ratio = 3^i0 × 5^i1 × 7^i2 × 9^i3 × 11^i4

Secondary entry point (arbitrary ratio):
    ratio_to_heji_ly(numerator, denominator, base_octave=4)

Output format: heji-ly \\ji macro strings, e.g.  \\\\ji"u5" e'
Compatible with https://github.com/BridgeTheMasterBuilder/heji-ly

Derivation of integer constants
--------------------------------
n_fifths = (i0 + 2*i3) + 4*i1 − 2*i2 − i4

EFFECTIVE_EXP3 per prime (sign-corrected power of 3 when mapping JI → Pythagorean base):
  prime 5 (comma 81/80 = 3^4/…):  +4   Pyth = JI × comma,  3^+4 in comma
  prime 7 (comma 64/63 = …/3^2):  −2   Pyth = JI × comma,  3^−2 in comma
  prime 11 (comma 33/32 = 3×11/…):−1   Pyth = JI / comma, −3^+1 from inverse

heji-ly direction per prime (sign to apply to ratio exponent → heji_exp):
  prime 5 : −1  (5/4 is below Pythagorean E  → utonal "u5")
  prime 7 : −1  (7/4 is below Pythagorean Bb → utonal "u7")
  prime 11: +1  (11/8 is above Pythagorean F  → otonal  "11")
"""

from fractions import Fraction

# Circle-of-fifths diatonic order (index 0 = F, 1 = C, …)
_DIATONIC = ["F", "C", "G", "D", "A", "E", "B"]

# Fifths distance from C for each diatonic reference note
_REF_FIFTHS = {"F": -1, "C": 0, "G": 1, "D": 2, "A": 3, "E": 4, "B": 5}

# LilyPond note-name table: note_letter → accidental_int → ly_string
_LY_NOTE = {
    "C": {-2: "ceses", -1: "ces",  0: "c",  1: "cis",  2: "cisis"},
    "D": {-2: "deses", -1: "des",  0: "d",  1: "dis",  2: "disis"},
    "E": {-2: "eses",  -1: "es",   0: "e",  1: "eis",  2: "eisis"},
    "F": {-2: "feses", -1: "fes",  0: "f",  1: "fis",  2: "fisis"},
    "G": {-2: "geses", -1: "ges",  0: "g",  1: "gis",  2: "gisis"},
    "A": {-2: "aeses", -1: "aes",  0: "a",  1: "ais",  2: "aisis"},
    "B": {-2: "beses", -1: "bes",  0: "b",  1: "bis",  2: "bisis"},
}


def exponents_to_heji_ly(exponents, base_octave=4, ref_note="C", octave_window=None):
    """Return the heji-ly LilyPond string for the JI ratio encoded by *exponents*.

    exponents : sequence of 5 ints [i0, i1, i2, i3, i4]
                ratio = 3^i0 × 5^i1 × 7^i2 × 9^i3 × 11^i4
    base_octave : LilyPond octave number for an unshifted ratio near 1/1 (default 4 = c')
    ref_note   : diatonic note name that the unison [0,0,0,0,0] maps to (default "C")
                 any of "F","C","G","D","A","E","B"
    octave_window : if set, clamp the computed octave to [base_octave-window, base_octave+window]

    Returns a string such as  '\\ji"u5"e\''  or  "g'"  — paste directly into LilyPond.
    """
    i0, i1, i2, i3, i4 = exponents

    # the net exponent of prime 3, with the 9-factor folded in
    exp3 = i0 + 2 * i3

    # Pythagorean circle-of-fifths position, shifted by reference note
    n_fifths = exp3 + 4 * i1 - 2 * i2 - i4 + _REF_FIFTHS[ref_note.upper()]

    idx = (n_fifths + 1) % 7
    note = _DIATONIC[idx]
    py_acc = (n_fifths + 1) // 7

    # Octave: normalize 3^exp3 × 5^i1 × 7^i2 × 11^i4 to [1, 2)
    ratio = Fraction(3) ** exp3 * Fraction(5) ** i1 * Fraction(7) ** i2 * Fraction(11) ** i4
    octave = base_octave
    while ratio >= 2:
        ratio /= 2
        octave += 1
    while ratio < 1:
        ratio *= 2
        octave -= 1

    if octave_window is not None:
        while octave > base_octave + octave_window:
            octave -= 1
        while octave < base_octave - octave_window:
            octave += 1

    # heji-ly prime factors for 5, 7, 11
    prime_parts = []
    for prime, e, sign in [(5, i1, -1), (7, i2, -1), (11, i4, 1)]:
        h = e * sign
        if h == 0:
            continue
        prefix = "u" if h < 0 else ""
        exp_sfx = f"^{abs(h)}" if abs(h) > 1 else ""
        prime_parts.append(f"{prefix}{prime}{exp_sfx}")

    ly_name = _LY_NOTE[note][max(-2, min(2, py_acc))]
    octave_str = "'" * (octave - 3) if octave >= 3 else "," * (3 - octave)

    if not prime_parts:
        return f"{ly_name}{octave_str}"

    # Pythagorean accidental encoded as "3" factor for combined HEJI2 glyph
    parts = []
    if py_acc != 0:
        pfx3 = "u3" if py_acc < 0 else "3"
        sfx3 = f"^{abs(py_acc)}" if abs(py_acc) > 1 else ""
        parts.append(f"{pfx3}{sfx3}")
    parts.extend(prime_parts)

    return '\\ji"' + " ".join(parts) + '"' + ly_name + octave_str


def ratio_to_heji_ly(numerator, denominator=1, base_octave=4, ref_note="C"):
    """Return the heji-ly string for the ratio numerator/denominator.

    The ratio must factor entirely into primes {2, 3, 5, 7, 11}.
    Powers of 2 are handled via octave normalisation inside exponents_to_heji_ly.
    """
    def _extract(n, p):
        exp = 0
        while n % p == 0:
            n //= p
            exp += 1
        return n, exp

    num, den = int(numerator), int(denominator)
    # absorb denominator factors as negative exponents
    # work with num/den as separate positive integers
    exps = {2: 0, 3: 0, 5: 0, 7: 0, 11: 0}
    for p in (2, 3, 5, 7, 11):
        num, e = _extract(num, p)
        exps[p] += e
        den, e = _extract(den, p)
        exps[p] -= e
    if num != 1 or den != 1:
        raise ValueError(
            f"{numerator}/{denominator} contains primes other than {{2,3,5,7,11}}"
        )
    # Prime-2 content is purely octave; fold into base_octave offset
    adjusted_octave = base_octave + exps[2]
    return exponents_to_heji_ly([exps[3], exps[5], exps[7], 0, exps[11]], adjusted_octave, ref_note)


# ---------------------------------------------------------------------------
# Quick self-test
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    # ratio_to_heji_ly handles prime-2 octave shifts automatically
    tests = [
        (5,  4,  '\\ji"u5"e\'',        "5/4  → E  + 5↓"),
        (7,  4,  '\\ji"u3 u7"bes\'',   "7/4  → Bb + 7↓  (u3 encodes ♭ in HEJI2)"),
        (11, 8,  '\\ji"11"f\'',        "11/8 → F  + 11↑"),
        (3,  2,  "g'",                 "3/2  → G  (Pythagorean)"),
        (9,  8,  "d'",                 "9/8  → D  (Pythagorean)"),
        (35, 32, '\\ji"u5 u7"d\'',     "35/32 → D + 5↓ 7↓"),
        (55, 32, '\\ji"u5 11"a\'',     "55/32 → A + 5↓ 11↑"),
        (5,  3,  '\\ji"u5"a\'',        "5/3  → A  + 5↓"),
        (1,  1,  "c'",                 "1/1  → C"),
    ]

    all_ok = True
    for num, den, expected, label in tests:
        result = ratio_to_heji_ly(num, den)
        status = "✓" if result == expected else f"✗  expected {expected!r}"
        # print(f"  {label:40s}  {result!r:30s}  {status}")
        print(f"  {label:40s}  {status}   ",result)
        if result != expected:
            all_ok = False

    print()
    print("All tests passed." if all_ok else "SOME TESTS FAILED.")
