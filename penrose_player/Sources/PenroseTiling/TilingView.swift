import AppKit

final class TilingView: NSView {
    var tiles: [Tile] = []
    var selectedTile: Int = -1
    var onTileClicked: ((_ tileIndex: Int, _ point: CGPoint) -> Void)?

    // Y increases downward — matches SC's pre-flipped stored coordinates
    override var isFlipped: Bool { true }

    // 10-color table from tiling.scd:652-663
    private static let baseColors: [NSColor] = [
        NSColor(red: 161/255, green: 161/255, blue: 161/255, alpha: 1),
        NSColor(red:  50/255, green: 205/255, blue:  50/255, alpha: 1),
        NSColor(red: 255/255, green: 140/255, blue:   0/255, alpha: 1),
        NSColor(red: 141/255, green: 141/255, blue: 141/255, alpha: 1),
        NSColor(red: 122/255, green: 122/255, blue: 122/255, alpha: 1),
        NSColor(red: 148/255, green:   0/255, blue: 211/255, alpha: 1),
        NSColor(red:   0/255, green: 191/255, blue: 255/255, alpha: 1),
        NSColor(red: 161/255, green: 161/255, blue: 161/255, alpha: 1),
        NSColor(red: 178/255, green:  34/255, blue:  34/255, alpha: 1),
        NSColor(red: 161/255, green: 161/255, blue: 161/255, alpha: 1),
    ]

    override func draw(_ dirtyRect: NSRect) {
        NSColor.white.setFill()
        dirtyRect.fill()

        for (i, tile) in tiles.enumerated() {
            let alpha: CGFloat
            if selectedTile < 0 {
                alpha = 200/255
            } else {
                alpha = i == selectedTile ? 1.0 : 80/255
            }

            let color = TilingView.baseColors[tile.faceIndex].withAlphaComponent(alpha)
            color.setFill()
            NSColor.white.setStroke()

            // Winding order [0,1,3,2] mirrors SC draw (tiling.scd:682-686)
            let pts = [tile.corners[0], tile.corners[1], tile.corners[3], tile.corners[2]]
            let path = NSBezierPath()
            path.move(to: pts[0])
            for p in pts.dropFirst() { path.line(to: p) }
            path.close()
            path.fill()
            path.stroke()
        }
    }

    override func mouseDown(with event: NSEvent) {
        let pt = convert(event.locationInWindow, from: nil)
        for (i, tile) in tiles.enumerated() {
            // Same polygon order as draw
            let poly = [tile.corners[0], tile.corners[1], tile.corners[3], tile.corners[2]]
            if isInsideConvexPolygon(pt, poly) {
                onTileClicked?(i, pt)
                return
            }
        }
    }
}
