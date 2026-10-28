import Foundation
import CoreGraphics

public struct OrbitGeometry: Sendable {
    public enum Layout: Sendable { case metatron, bubbles }
    public enum Hit: Equatable, Sendable { case hub, action(Int), outside }
    public let scale: CGFloat
    public let layout: Layout
    public init(size: Double = 300, layout: Layout) {
        scale = CGFloat(min(1.25, max(0.9, size / 300)))
        self.layout = layout
    }
    public var side: CGFloat { 480 * scale }
    public var nodeRadius: CGFloat { 37 * scale }
    public var hubRadius: CGFloat { 39 * scale }
    public func radius(count: Int) -> CGFloat { (layout == .bubbles && count <= 8 ? 132 : 166) * scale }
    /// Positions relative to the selected file/cursor, with y pointing down.
    public func center(for index: Int, count: Int) -> CGPoint? {
        guard count > 0, index >= 0, index < min(count, 12) else { return nil }
        if layout == .metatron {
            let p = MetatronGeometry.centers[index + 1]
            return CGPoint(x:p.x * radius(count:count), y:p.y * radius(count:count))
        }
        let angle = Double(index) * 2 * .pi / Double(min(count,12)) - .pi / 2
        let r = radius(count:count)
        return CGPoint(x:cos(angle) * r,y:sin(angle) * r)
    }
    public func hit(_ point: CGPoint, count: Int) -> Hit {
        if hypot(point.x,point.y) <= hubRadius { return .hub }
        for index in 0..<min(max(count,0),12) {
            guard let p=center(for:index,count:count) else {continue}
            if hypot(point.x-p.x,point.y-p.y) <= nodeRadius + 3 * scale {return .action(index)}
        }
        return .outside
    }
}
