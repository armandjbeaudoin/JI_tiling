import AVFoundation

final class AudioEngine {
    private let engine = AVAudioEngine()
    private var sourceNode: AVAudioSourceNode!
    private let bank: OscillatorBank

    init() {
        let sr = 48000.0
        bank = OscillatorBank(sampleRate: sr)
        let format = AVAudioFormat(standardFormatWithSampleRate: sr, channels: 2)!
        let bankRef = bank  // local capture to avoid ARC in render block via self
        sourceNode = AVAudioSourceNode(format: format) { _, _, frameCount, audioBufferList in
            let abl = UnsafeMutableAudioBufferListPointer(audioBufferList)
            for frame in 0..<Int(frameCount) {
                let sample = bankRef.nextSample()
                for buf in abl {
                    buf.mData!.assumingMemoryBound(to: Float.self)[frame] = sample
                }
            }
            return noErr
        }
        engine.attach(sourceNode)
        engine.connect(sourceNode, to: engine.mainMixerNode, format: format)
        engine.mainMixerNode.outputVolume = 0.25
    }

    func start() throws {
        try engine.start()
    }

    /// Called from main thread on tile click.
    func play(freqs: [Double], amps: [Double]) {
        bank.setTargets(freqs: freqs, amps: amps)
    }
}
