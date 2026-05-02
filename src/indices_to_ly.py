"""
indices_to_ly.py — Read Data/indices_5Dprojection.txt and print LilyPond chords.

Each line: 20 comma-separated integers = 4 vertices × 5 exponents [i0,i1,i2,i3,i4]
  ratio = 3^i0 × 5^i1 × 7^i2 × 9^i3 × 11^i4

heji-ly hard limits (from lib.scm validate):
  prime 5 : |exp| ≤ 4
  prime 7 : |exp| ≤ 2
  prime 11: |exp| ≤ 1

Notes that exceed any limit are skipped. Chords with no valid notes are omitted.

Output: one LilyPond chord per line, e.g.  <c' \\ji"u5"e' g' \\ji"u3 u7"bes'>1
"""

import sys
import os

sys.path.insert(0, os.path.dirname(__file__))
from heji_ly import exponents_to_heji_ly

DATA_FILE = os.path.join(os.path.dirname(__file__), "../Data/indices_5Dprojection.txt")

# heji-ly maximum |exponent| per prime (from lib.scm)
_HEJI_MAX = {1: 4, 2: 2, 4: 1}  # index in [i0,i1,i2,i3,i4] → max abs value


def valid_for_heji(exponents):
    """Return True iff all prime exponents are within heji-ly rendering limits."""
    _, i1, i2, i3, i4 = exponents
    return abs(i1) <= 4 and abs(i2) <= 2 and abs(i4) <= 1


def tile_to_chord(exps_list, base_octave=0, ref_note="C", octave_window=2):
    notes = []
    for e in exps_list:
        if not valid_for_heji(e):
            continue
        notes.append(exponents_to_heji_ly(e, base_octave, ref_note, octave_window))
    if not notes:
        return None
    return "< " + " ".join(notes) + " >1"


if __name__ == "__main__":
    with open(DATA_FILE) as f:
        for line in f:
            vals = list(map(int, line.strip().split(",")))
            exps_list = [vals[i*5:(i+1)*5] for i in range(4)]
            chord = tile_to_chord(exps_list)
            if chord:
                print(chord)
