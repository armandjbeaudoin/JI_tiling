import Foundation
import Darwin

// 4 sine oscillators with 1-pole IIR smoothers.
// This class is accessed from both the main thread (to set targets)
// and the audio render thread (to produce samples).
// Synchronization uses os_unfair_lock.

final class OscillatorBank: @unchecked Sendable {
    private let sampleRate: Double
    private var phases:      [Double]  // running phase in [0,1)
    private var curFreqs:    [Double]  // smoothed current frequency
    private var curAmps:     [Double]  // smoothed current amplitude
    private var tgtFreqs:    [Double]  // target frequency (written by main thread)
    private var tgtAmps:     [Double]  // target amplitude (written by main thread)
    private let freqCoeff:   Double    // 1-pole coeff for frequency
    private let ampCoeff:    Double    // 1-pole coeff for amplitude
    private var lock        = os_unfair_lock_s()

    init(sampleRate: Double, baseFreq: Double = 130.815) {
        self.sampleRate = sampleRate
        self.phases   = [Double](repeating: 0, count: 4)
        self.curFreqs = [Double](repeating: baseFreq, count: 4)
        self.curAmps  = [Double](repeating: 0, count: 4)
        self.tgtFreqs = [Double](repeating: baseFreq, count: 4)
        self.tgtAmps  = [Double](repeating: 0, count: 4)
        // 1-pole smoother: coeff = 1 - exp(-2π * cutoff / sampleRate)
        freqCoeff = 1.0 - exp(-2.0 * .pi * 5.0  / sampleRate) // ~200 ms glide
        ampCoeff  = 1.0 - exp(-2.0 * .pi * 15.0 / sampleRate) // ~67 ms amp ramp
    }

    /// Called from main thread to update targets.
    func setTargets(freqs: [Double], amps: [Double]) {
        os_unfair_lock_lock(&lock)
        for i in 0..<4 {
            tgtFreqs[i] = freqs[i]
            tgtAmps[i]  = amps[i]
        }
        os_unfair_lock_unlock(&lock)
    }

    /// Called from audio render thread for each frame. Returns mixed mono sample.
    func nextSample() -> Float {
        // Snapshot targets without holding the lock during the math
        os_unfair_lock_lock(&lock)
        let tf0 = tgtFreqs[0], tf1 = tgtFreqs[1], tf2 = tgtFreqs[2], tf3 = tgtFreqs[3]
        let ta0 = tgtAmps[0],  ta1 = tgtAmps[1],  ta2 = tgtAmps[2],  ta3 = tgtAmps[3]
        os_unfair_lock_unlock(&lock)

        var out = 0.0
        let targets: [(f: Double, a: Double)] = [(tf0,ta0),(tf1,ta1),(tf2,ta2),(tf3,ta3)]
        for i in 0..<4 {
            curFreqs[i] += freqCoeff * (targets[i].f - curFreqs[i])
            curAmps[i]  += ampCoeff  * (targets[i].a - curAmps[i])
            phases[i]   += curFreqs[i] / sampleRate
            if phases[i] >= 1.0 { phases[i] -= 1.0 }
            out += curAmps[i] * sin(2.0 * .pi * phases[i])
        }
        return Float(out)
    }
}
