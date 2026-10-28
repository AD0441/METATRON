import Foundation
import Metal
import CoreImage
import MetatronCore

public struct HardwareProfile: Sendable {
    public let deviceName: String
    public let unifiedMemory: Bool
    public let recommendedMemory: UInt64
    public let lowPower: Bool
    public static func current() -> HardwareProfile {
        let device = MTLCreateSystemDefaultDevice()
        return HardwareProfile(deviceName: device?.name ?? "CPU · Metal no disponible", unifiedMemory: device?.hasUnifiedMemory ?? false,
            recommendedMemory: device?.recommendedMaxWorkingSetSize ?? 0, lowPower: ProcessInfo.processInfo.isLowPowerModeEnabled)
    }
}

/// Reuses the thread-safe Core Image context and uses Metal when the host provides a device.
public enum MetalImages {
    public static let context: CIContext = Images.ciContext
    /// The measured M1 single-image resize is faster with Core Graphics than a GPU round trip.
    public static func resize(_ image: CGImage, longestEdge: Int) throws -> CGImage {
        guard longestEdge > 0 else { throw WorkflowError.invalid("El tamaño debe ser mayor que cero.") }
        return Images.fit(image, maxSide: longestEdge)
    }
    public static func resizeUsingMetal(_ image: CGImage, longestEdge: Int) throws -> CGImage {
        guard longestEdge > 0 else { throw WorkflowError.invalid("El tamaño debe ser mayor que cero.") }
        let scale = min(1, Double(longestEdge) / Double(max(image.width, image.height)))
        guard scale < 1 else { return image }
        let result = CIImage(cgImage: image).applyingFilter("CILanczosScaleTransform", parameters: ["inputScale": scale, "inputAspectRatio": 1.0])
        guard let output = context.createCGImage(result, from: CGRect(x: 0, y: 0, width: max(1, Int(Double(image.width) * scale)), height: max(1, Int(Double(image.height) * scale)))) else { throw WorkflowError.emptyResult }
        return output
    }
}
