import Foundation
import CoreGraphics

struct Tile {
    // 4 corners in screen coords (pre-scaled and Y-flipped), raw order [c0,c1,c2,c3]
    var corners: [CGPoint]  // count=4
    // 5D lattice indices, flat: [v0i0..v0i4, v1i0..v1i4, v2i0..v2i4, v3i0..v3i4]
    var indices: [Int]      // count=20
    var faceIndex: Int      // 0-9
}

enum TileDataLoader {
    static func load() throws -> [Tile] {
        let vertsURL    = Bundle.module.url(forResource: "verts_5Dprojection",   withExtension: "txt")!
        let indicesURL  = Bundle.module.url(forResource: "indices_5Dprojection", withExtension: "txt")!
        let facesURL    = Bundle.module.url(forResource: "faces_5Dprojection",   withExtension: "txt")!

        let rawVerts   = try parseDoubles(vertsURL)   // 206 × 8
        let rawIndices = try parseInts(indicesURL)    // 206 × 20
        let rawFaces   = try parseInts(facesURL)      // 206 × 1

        // Compute bounding box for scale/flip (mirrors ~lattice_limit + ~lattice_scale in SC)
        var xmn = Double.infinity, xmx = -Double.infinity
        var ymn = Double.infinity, ymx = -Double.infinity
        for row in rawVerts {
            for j in 0..<4 {
                let x = row[2*j], y = row[2*j+1]
                if x < xmn { xmn = x }; if x > xmx { xmx = x }
                if y < ymn { ymn = y }; if y > ymx { ymx = y }
            }
        }
        let b: Double = 600
        let sx = (b - 1) / (xmx - xmn)
        let sy = (b - 1) / (ymx - ymn)
        let scl = min(sx, sy)
        let ofstX = (b - scl * (xmx - xmn)) / 2
        let ofstY = (b - scl * (ymx - ymn)) / 2

        var tiles = [Tile]()
        tiles.reserveCapacity(rawVerts.count)
        for i in 0..<rawVerts.count {
            let row = rawVerts[i]
            var corners = [CGPoint]()
            corners.reserveCapacity(4)
            for j in 0..<4 {
                let xScreen = ofstX + scl * (row[2*j]   - xmn)
                let yScreen = ofstY + scl * (ymx - row[2*j+1])  // Y flip
                corners.append(CGPoint(x: xScreen, y: yScreen))
            }
            let tile = Tile(
                corners: corners,
                indices: rawIndices[i],
                faceIndex: rawFaces[i][0]
            )
            tiles.append(tile)
        }
        return tiles
    }

    private static func parseDoubles(_ url: URL) throws -> [[Double]] {
        let text = try String(contentsOf: url, encoding: .utf8)
        return text.components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            .map { line in line.components(separatedBy: ",").compactMap { Double($0.trimmingCharacters(in: .whitespaces)) } }
    }

    private static func parseInts(_ url: URL) throws -> [[Int]] {
        let text = try String(contentsOf: url, encoding: .utf8)
        return text.components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            .map { line in line.components(separatedBy: ",").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) } }
    }
}
