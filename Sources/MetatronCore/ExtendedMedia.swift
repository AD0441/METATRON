import AVFoundation
import Foundation

public enum ExtendedMedia {
    public static func run(_ operation: String, inputs: [URL], value: Double, text: String, directory: URL) async throws -> [URL] {
        guard let first = inputs.first else { throw MetatronError.badData("Añade archivos.") }
        if operation == "joinVideo" {
            let composition = AVMutableComposition()
            guard let video = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else { throw MetatronError.unsupported("Vídeo") }
            let audio = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
            var cursor = CMTime.zero
            var transform: CGAffineTransform?
            for url in inputs {
                try Task.checkCancellation()
                let asset = AVURLAsset(url: url)
                let duration = try await asset.load(.duration)
                guard let track = try await asset.loadTracks(withMediaType: .video).first else { throw MetatronError.unsupported("Archivo sin vídeo") }
                let currentTransform = try await track.load(.preferredTransform)
                if let transform, transform != currentTransform { throw MetatronError.badData("Los vídeos tienen orientaciones distintas. Conviértelos primero al mismo formato y orientación.") }
                transform = currentTransform
                try video.insertTimeRange(CMTimeRange(start: .zero, duration: duration), of: track, at: cursor)
                if let a = try await asset.loadTracks(withMediaType: .audio).first { try audio?.insertTimeRange(CMTimeRange(start: .zero, duration: duration), of: a, at: cursor) }
                cursor = cursor + duration
            }
            video.preferredTransform = transform ?? .identity
            let out = directory.appendingPathComponent("Videos.mp4")
            try await export(composition, output: out)
            return [out]
        }
        var outputs: [URL] = []
        for url in inputs {
            try Task.checkCancellation()
            if operation == "trimVideo" {
                let parts = text.split(separator: ",").compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }
                guard parts.count == 2, parts[0] >= 0, parts[1] > parts[0] else { throw MetatronError.badData("Indica inicio,fin en segundos; por ejemplo 0,10.") }
                let asset = AVURLAsset(url: url)
                let duration = try await asset.load(.duration).seconds
                guard parts[1] <= duration else { throw MetatronError.badData("El final excede la duración del vídeo.") }
                let out = directory.appendingPathComponent(url.deletingPathExtension().lastPathComponent + ".mp4")
                try await export(asset, output: out, range: CMTimeRange(start: CMTime(seconds: parts[0], preferredTimescale: 600), duration: CMTime(seconds: parts[1] - parts[0], preferredTimescale: 600)))
                outputs.append(out)
            } else {
                guard let ffmpeg = Engines.current.ffmpeg else { throw MetatronError.needsEngine("FFmpeg") }
                let out = directory.appendingPathComponent(url.deletingPathExtension().lastPathComponent + ".m4a")
                var args = ["-nostdin", "-n", "-i", url.path, "-vn"]
                if operation == "normalizeAudio" { args += ["-af", "loudnorm=I=-16:TP=-1.5:LRA=11"] }
                else { args += ["-ac", "1"] }
                try await Engines.run(ffmpeg, args + ["-c:a", "aac", out.path])
                outputs.append(out)
            }
        }
        _ = first; _ = value
        return outputs
    }
    private static func export(_ asset: AVAsset, output: URL, range: CMTimeRange? = nil) async throws {
        guard let session = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else { throw MetatronError.unsupported("Vídeo") }
        session.outputURL = output; session.outputFileType = .mp4; session.shouldOptimizeForNetworkUse = true
        if let range { session.timeRange = range }
        try await Media.finishExport(session, output: output)
    }
}
