import AVFoundation
import ImageIO
import UniformTypeIdentifiers

/// Video and audio with AVFoundation and the built-in `afconvert`.
public enum Media {
    public static func exportVideo(_ url: URL, to output: URL, format: OutputFormat, preset: String = AVAssetExportPresetHighestQuality, removeAudio: Bool = false) async throws {
        let asset = AVURLAsset(url: url)
        var source: AVAsset = asset
        if removeAudio {
            let comp = AVMutableComposition()
            let duration = try await asset.load(.duration)
            for track in try await asset.loadTracks(withMediaType: .video) {
                let t = comp.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
                try t?.insertTimeRange(CMTimeRange(start: .zero, duration: duration), of: track, at: .zero)
                t?.preferredTransform = try await track.load(.preferredTransform)
            }
            source = comp
        }
        let fileType: AVFileType
        switch format {
        case .mp4: fileType = .mp4
        case .mov: fileType = .mov
        case .m4v: fileType = .m4v
        case .m4a: fileType = .m4a
        default: throw MetatronError.unsupported(format.label)
        }
        let chosenPreset = format == .m4a ? AVAssetExportPresetAppleM4A : preset
        guard let session = AVAssetExportSession(asset: source, presetName: chosenPreset) else {
            throw MetatronError.unsupported(format.label)
        }
        session.outputURL = output
        session.outputFileType = fileType
        session.shouldOptimizeForNetworkUse = true
        try await finishExport(session, output: output)
    }

    /// Turns a clip into an animated GIF.
    public static func gif(_ url: URL, to output: URL, fps: Int, maxWidth: Int, maxSeconds: Double = 15) async throws {
        let asset = AVURLAsset(url: url)
        let duration = try await asset.load(.duration).seconds
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero
        generator.maximumSize = CGSize(width: maxWidth, height: maxWidth * 4)

        let frameCount = max(1, Int(min(duration, maxSeconds) * Double(fps)))
        guard let dest = CGImageDestinationCreateWithURL(output as CFURL, UTType.gif.identifier as CFString, frameCount, nil) else {
            throw MetatronError.writeFailed(output)
        }
        CGImageDestinationSetProperties(dest, [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFLoopCount: 0]] as CFDictionary)
        let frameProps = [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFDelayTime: 1.0 / Double(fps)]] as CFDictionary
        for i in 0..<frameCount {
            try Task.checkCancellation()
            let time = CMTime(seconds: Double(i) / Double(fps), preferredTimescale: 600)
            if let image = try? await generator.image(at: time).image {
                CGImageDestinationAddImage(dest, image, frameProps)
            }
        }
        guard CGImageDestinationFinalize(dest) else { throw MetatronError.writeFailed(output) }
    }

    /// Saves frames as JPEGs into `folder`: every frame, or `fps` per second. Stops at 5,000.
    public static func frames(_ url: URL, into folder: URL, fps: Double?) async throws -> Int {
        let asset = AVURLAsset(url: url)
        guard let track = try await asset.loadTracks(withMediaType: .video).first else { throw MetatronError.unsupported("A file without video") }
        let duration = try await asset.load(.duration).seconds
        let nominal = Double(try await track.load(.nominalFrameRate))
        let rate = min(fps ?? (nominal > 0 ? nominal : 30), nominal > 0 ? nominal : 60)
        let count = min(5000, max(1, Int(duration * rate)))
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        var written = 0
        for i in 0..<count {
            try Task.checkCancellation()
            let time = CMTime(seconds: Double(i) / rate, preferredTimescale: 600)
            guard let image = try? await generator.image(at: time).image else { continue }
            let out = folder.appendingPathComponent(String(format: "frame_%05d.jpg", i + 1))
            try Images.write(image, to: out, format: .jpg, quality: 0.92)
            written += 1
        }
        return written
    }

    public static func convertAudio(_ url: URL, to output: URL, format: OutputFormat) async throws {
        let args: [String]
        switch format {
        case .m4a: args = ["-f", "m4af", "-d", "aac", "-b", "256000"]
        case .wav: args = ["-f", "WAVE", "-d", "LEI16"]
        case .aiff: args = ["-f", "AIFF", "-d", "BEI16"]
        case .flac: args = ["-f", "flac", "-d", "flac"]
        case .caf: args = ["-f", "caff", "-d", "aac"]
        default: throw MetatronError.unsupported(format.label)
        }
        try await run("/usr/bin/afconvert", args + [url.path, output.path])
    }

    static func run(_ tool: String, _ arguments: [String]) async throws {
        try await Engines.run(URL(fileURLWithPath: tool), arguments)
    }

    static func finishExport(_ session: AVAssetExportSession, output: URL) async throws {
        try await withTaskCancellationHandler {
            try Task.checkCancellation()
            await session.export()
            try Task.checkCancellation()
            if session.status != .completed { throw session.error ?? MetatronError.writeFailed(output) }
        } onCancel: { session.cancelExport() }
    }
}
