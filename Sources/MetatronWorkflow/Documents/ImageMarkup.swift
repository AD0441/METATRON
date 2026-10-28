import Foundation
import CoreGraphics
import CoreText
import MetatronCore

public struct MarkPoint: Codable, Hashable, Sendable {
    public var x: Double
    public var y: Double
    public init(x: Double, y: Double) { self.x = x; self.y = y }
}
public struct MarkStroke: Codable, Hashable, Identifiable, Sendable {
    public var id: UUID
    public var kind: String
    public var points: [MarkPoint]
    public var text: String
    public init(kind: String, points: [MarkPoint], text: String = "") { id = UUID(); self.kind = kind; self.points = points; self.text = text }
}
public enum ImageMarkup {
    public static func render(_ image: CGImage, strokes: [MarkStroke]) throws -> CGImage {
        let width = CGFloat(image.width), height = CGFloat(image.height)
        guard let ctx = CGContext(data: nil, width: image.width, height: image.height, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { throw WorkflowError.emptyResult }
        ctx.draw(image, in: CGRect(x: 0,y: 0,width: width,height: height))
        for stroke in strokes {
            try Task.checkCancellation()
            guard !stroke.points.isEmpty, stroke.points.allSatisfy({ $0.x.isFinite && $0.y.isFinite && (0...1).contains($0.x) && (0...1).contains($0.y) }) else { throw WorkflowError.invalid("La anotación contiene coordenadas no válidas.") }
            let points = stroke.points.map { CGPoint(x: $0.x * width, y: (1 - $0.y) * height) }
            guard let first = points.first, let last = points.last else { continue }
            ctx.setStrokeColor(CGColor(srgbRed: 1,green: 0.27,blue: 0.05,alpha: 1))
            ctx.setLineWidth(max(2,width * 0.005)); ctx.setLineCap(.round); ctx.setLineJoin(.round)
            let rect = CGRect(x: min(first.x,last.x), y: min(first.y,last.y), width: abs(last.x-first.x), height: abs(last.y-first.y))
            switch stroke.kind {
            case "rectangle": ctx.stroke(rect)
            case "redact": ctx.setFillColor(.black); ctx.fill(rect)
            case "text":
                let size = max(14,width * 0.025)
                let text = NSAttributedString(string: stroke.text, attributes: [NSAttributedString.Key(kCTFontAttributeName as String): CTFontCreateWithName("Helvetica-Bold" as CFString, size, nil), NSAttributedString.Key(kCTForegroundColorAttributeName as String): CGColor(srgbRed: 1,green: 0.27,blue: 0.05,alpha: 1)])
                ctx.textPosition = CGPoint(x: first.x,y: first.y - size); CTLineDraw(CTLineCreateWithAttributedString(text), ctx)
            default:
                ctx.beginPath(); ctx.move(to: first); for point in points.dropFirst() { ctx.addLine(to: point) }; ctx.strokePath()
            }
        }
        guard let image = ctx.makeImage() else { throw WorkflowError.emptyResult }; return image
    }
}
