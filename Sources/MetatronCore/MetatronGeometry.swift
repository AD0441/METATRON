import Foundation
import CoreGraphics

/// A geometric construction: center, six outer centers, six inner centers.
public enum MetatronGeometry {
    public static let centers: [CGPoint] = {
        [CGPoint.zero] + [1.0, 0.5].flatMap { radius in
            (0..<6).map { index in
                let angle = Double(index) * .pi / 3 - .pi / 2
                return CGPoint(x: cos(angle) * radius, y: sin(angle) * radius)
            }
        }
    }()
    public static let edges: [(Int, Int)] = (0..<13).flatMap { a in ((a + 1)..<13).map { (a, $0) } }
    public static func actionCenter(_ index: Int, radius: CGFloat, center: CGPoint) -> CGPoint? {
        guard (0..<12).contains(index) else { return nil }
        let p = centers[index + 1]
        return CGPoint(x: center.x + p.x * radius, y: center.y + p.y * radius)
    }
}
