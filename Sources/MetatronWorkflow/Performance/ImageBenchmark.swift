import Foundation
import CoreGraphics
import MetatronCore
public struct BenchmarkResult: Sendable {
    public let cpuSeconds: Double
    public let metalSeconds: Double
    public let width: Int
    public let height: Int
}
public enum ImageBenchmark {
    @concurrent public static func run() async throws -> BenchmarkResult {
        let width = 4000, height = 3000
        guard let ctx = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { throw WorkflowError.emptyResult }
        ctx.setFillColor(CGColor(srgbRed: 0.95, green: 0.5, blue: 0.12, alpha: 1)); ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))
        for index in 0..<150 { ctx.setFillColor(CGColor(srgbRed: Double(index % 10) / 10, green: 0.4, blue: 0.6, alpha: 1)); ctx.fillEllipse(in: CGRect(x: index * 17, y: index * 13, width: 800, height: 600)) }
        guard let image = ctx.makeImage() else { throw WorkflowError.emptyResult }
        _ = try MetalImages.resizeUsingMetal(image, longestEdge: 1200)
        _ = Images.fit(image, maxSide: 1200)
        var cpu = 0.0, gpu = 0.0
        for _ in 0..<3 {
            try Task.checkCancellation()
            let start = Date(); let resized = Images.fit(image, maxSide: 1200); _ = resized.dataProvider?.data
            cpu += Date().timeIntervalSince(start)
            let next = Date(); let accelerated = try MetalImages.resizeUsingMetal(image, longestEdge: 1200); _ = accelerated.dataProvider?.data
            gpu += Date().timeIntervalSince(next)
        }
        return BenchmarkResult(cpuSeconds: cpu / 3, metalSeconds: gpu / 3, width: width, height: height)
    }
}
