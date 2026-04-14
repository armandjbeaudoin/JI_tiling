import Foundation

// Port of ~freqScale and ~limitRange from tiling.scd:117-163.

/// Compute frequency ratio for a single tile vertex using the current interval set.
/// Uses modulo2 mode: exponent = (|index| % 2) * sign(index)
func freqRatio(tile: Tile, vertexIndex: Int, intervals: [Double]) -> Double {
    var f = 1.0
    for i in 0..<5 {
        let raw = tile.indices[vertexIndex * 5 + i]
        // SC: (index % 2) * sign(index)
        // Swift % preserves sign of dividend, same as SC
        // let p = (abs(raw) % 2) * (raw < 0 ? -1 : 1)
        let p = raw
        f *= pow(intervals[i], Double(p))
    }
    return f
}

/// Clamp ratio to [0.25, 16.0) by halving/doubling.
/// Port of ~limitRange (tiling.scd:155-163).
func limitRange(_ f: Double) -> Double {
    var r = f
    while r >= 16.0 { r /= 2.0 }
    while r < 0.25  { r *= 2.0 }
    return r
}
