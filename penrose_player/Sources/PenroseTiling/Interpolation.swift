import CoreGraphics

// Port of ~ampScale from tiling.scd:284-321.
//
// SC vertex labeling (confusingly not in order):
//   x1=v[2],y1=v[3]  → corners[1]
//   x2=v[0],y2=v[1]  → corners[0]
//   x3=v[4],y3=v[5]  → corners[2]
//   x4=v[6],y4=v[7]  → corners[3]
//
// Returns [N1,N2,N3,N4] corresponding to those SC vertices.
// Oscillator i uses amps[i] — mapping is preserved as-is from ~playTile.

func bilinearShapeFunctions(corners: [CGPoint], point: CGPoint) -> [Double] {
    // Map SC's unusual vertex ordering
    let x1 = Double(corners[1].x), y1 = Double(corners[1].y)
    let x2 = Double(corners[0].x), y2 = Double(corners[0].y)
    let x3 = Double(corners[2].x), y3 = Double(corners[2].y)
    let x4 = Double(corners[3].x), y4 = Double(corners[3].y)
    let px = Double(point.x), py = Double(point.y)

    // Initial guess s=t=0
    var s = 0.0, t = 0.0

    // Shape functions at (s,t)
    let n1 = ((1-s)*(1-t))/4
    let n2 = ((1+s)*(1-t))/4
    let n3 = ((1+s)*(1+t))/4
    let n4 = ((1-s)*(1+t))/4

    // Residuals
    let f1 = (n1*x1 + n2*x2 + n3*x3 + n4*x4) - px
    let f2 = (n1*y1 + n2*y2 + n3*y3 + n4*y4) - py

    // Jacobian (evaluated at s=t=0)
    let j00 = ((x1*(t-1))/4) - ((x2*(t-1))/4) + ((x3*(t+1))/4) - ((x4*(t+1))/4)
    let j01 = ((x1*(s-1))/4) - ((x2*(s+1))/4) + ((x3*(s+1))/4) - ((x4*(s-1))/4)
    let j10 = ((y1*(t-1))/4) - ((y2*(t-1))/4) + ((y3*(t+1))/4) - ((y4*(t+1))/4)
    let j11 = ((y1*(s-1))/4) - ((y2*(s+1))/4) + ((y3*(s+1))/4) - ((y4*(s-1))/4)

    // 2×2 inverse: (1/det) * [[j11,-j01],[-j10,j00]]
    let det = j00*j11 - j01*j10
    guard abs(det) > 1e-12 else { return [0.25, 0.25, 0.25, 0.25] }
    let inv00 =  j11 / det, inv01 = -j01 / det
    let inv10 = -j10 / det, inv11 =  j00 / det

    // Newton step
    s -= (inv00*f1 + inv01*f2)
    t -= (inv10*f1 + inv11*f2)

    // Final shape functions
    return [
        ((1-s)*(1-t))/4,
        ((1+s)*(1-t))/4,
        ((1+s)*(1+t))/4,
        ((1-s)*(1+t))/4,
    ]
}
