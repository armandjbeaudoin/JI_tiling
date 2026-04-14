import AppKit

final class MainWindowController: NSWindowController {
    required init?(coder: NSCoder) { fatalError("init(coder:) not used") }
    override init(window: NSWindow?) {
        super.init(window: window)
        setup()
    }

    private var tilingView: TilingView!
    private var intervalButton: NSButton!
    private var tiles: [Tile] = []
    private var currentIntervalSet = 0
    private let audio = AudioEngine()
    private let baseFreq = 130.815  // 261.63 / 2 Hz  (tiling.scd:20)
    private let ampRef   = 0.25     // tiling.scd:21

    private func setup() {
        guard let window = window else { return }

        // Load tile data
        do {
            tiles = try TileDataLoader.load()
        } catch {
            fatalError("Failed to load tile data: \(error)")
        }

        // Tiling view fills the window
        let contentView = window.contentView!
        tilingView = TilingView(frame: contentView.bounds)
        tilingView.autoresizingMask = [.width, .height]
        tilingView.tiles = tiles
        contentView.addSubview(tilingView)

        // Interval button — top-left, matching SC Rect(10,550,120,40) in 600×600 bottom-left coords
        intervalButton = NSButton(frame: NSRect(x: 10, y: 10, width: 120, height: 40))
        intervalButton.title = IntervalSets.labels[currentIntervalSet]
        intervalButton.bezelStyle = .rounded
        intervalButton.target = self
        intervalButton.action = #selector(cycleInterval)
        contentView.addSubview(intervalButton)

        // Wire tile clicks
        tilingView.onTileClicked = { [weak self] tileIdx, point in
            self?.handleTileClick(tileIdx, at: point)
        }

        // Start audio
        do {
            try audio.start()
        } catch {
            print("Audio engine failed to start: \(error)")
        }
    }

    @objc private func cycleInterval() {
        currentIntervalSet = (currentIntervalSet + 1) % IntervalSets.values.count
        intervalButton.title = IntervalSets.labels[currentIntervalSet]
    }

    private func handleTileClick(_ tileIdx: Int, at point: CGPoint) {
        let tile = tiles[tileIdx]
        let intervals = IntervalSets.values[currentIntervalSet]

        // Bilinear amplitude interpolation (port of ~ampScale)
        let amps = bilinearShapeFunctions(corners: tile.corners, point: point)

        // Frequency for each vertex (port of ~freqScale + ~limitRange + baseFreq)
        var freqs = [Double](repeating: 0, count: 4)
        for v in 0..<4 {
            let ratio = limitRange(freqRatio(tile: tile, vertexIndex: v, intervals: intervals))
            freqs[v] = baseFreq * ratio
        }

        // Scale amps: sqrt(amp * ampRef) per tiling.scd:339
        let scaledAmps = amps.map { sqrt(max($0, 0) * ampRef) }

        audio.play(freqs: freqs, amps: scaledAmps)

        tilingView.selectedTile = tileIdx
        tilingView.needsDisplay = true
    }
}
