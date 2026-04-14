import CoreGraphics

// Port of ~v_sub, ~cross_product, ~get_side, ~inside_convex_polygon from tiling.scd:200-260

private func vsub(_ a: CGPoint, _ b: CGPoint) -> CGVector {
    CGVector(dx: a.x - b.x, dy: a.y - b.y)
}

private func crossZ(_ a: CGVector, _ b: CGVector) -> CGFloat {
    a.dx * b.dy - a.dy * b.dx
}

private func getSide(_ seg: CGVector, _ pt: CGVector) -> Int {
    let c = crossZ(seg, pt)
    if c > 0 { return 1 }
    if c < 0 { return -1 }
    return 0
}

/// Returns true if `point` is strictly inside the convex polygon defined by `vertices`.
/// Vertices must be in consistent winding order (CW or CCW).
/// Direct port of SC ~inside_convex_polygon.
func isInsideConvexPolygon(_ point: CGPoint, _ vertices: [CGPoint]) -> Bool {
    let n = vertices.count
    var previousSide = 0
    for i in 0..<n {
        let a = vertices[i]
        let b = vertices[(i + 1) % n]
        let seg = vsub(b, a)
        let pt  = vsub(point, a)
        let currentSide = getSide(seg, pt)
        if currentSide == 0 { return false }
        if previousSide == 0 {
            previousSide = currentSide
        } else if previousSide != currentSide {
            return false
        }
    }
    return true
}
