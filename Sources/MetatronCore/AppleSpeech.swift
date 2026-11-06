import Foundation
import AVFoundation
import Speech

public struct SpeechLanguageStatus: Sendable, Codable {
    public let locale: String
    public let supported: Bool
    public let installed: Bool
    public let message: String
}
public struct SpeechTranscript: Sendable {
    public let text: String
    public let locale: String
    public let duration: Double
}
public enum AppleSpeechError: LocalizedError, Equatable {
    case unavailable, unsupportedLanguage(String), missingLanguage(String), noSpeech, invalidAudio, tooLong
    public var errorDescription: String? {
        switch self {
        case .unavailable: "Audio a texto requiere macOS 26 y un Mac compatible con Apple Speech."
        case .unsupportedLanguage(let id): "Apple Speech no admite el idioma \(id) en este equipo. Elige otro idioma en Ajustes → Documentos."
        case .missingLanguage(let id): "Falta el modelo local \(id). Descárgalo en Ajustes → Documentos → Audio a texto, o con speech-install --locale \(id). No se ha enviado el audio."
        case .noSpeech: "No se reconoció voz en el audio. Revisa el idioma y la grabación."
        case .invalidAudio: "No se pudo leer el audio o su duración no es válida."
        case .tooLong: "La transcripción supera el límite de cuatro horas o un millón de caracteres. Divide la grabación."
        }
    }
}
/// Apple Speech is on-device. This type never substitutes SFSpeechRecognizer,
/// uploads audio, or downloads a missing language as a side effect of conversion.
public enum AppleSpeech {
    public static var isSupported: Bool {
        if #available(macOS 26, *) { SpeechTranscriber.isAvailable } else { false }
    }
    public static func languageStatus(_ identifier: String) async -> SpeechLanguageStatus {
        guard #available(macOS 26, *), SpeechTranscriber.isAvailable else {
            return .init(locale: identifier, supported: false, installed: false, message: AppleSpeechError.unavailable.localizedDescription)
        }
        guard let locale = await SpeechTranscriber.supportedLocale(equivalentTo: Locale(identifier: identifier)) else {
            return .init(locale: identifier, supported: false, installed: false, message: AppleSpeechError.unsupportedLanguage(identifier).localizedDescription)
        }
        let module = SpeechTranscriber(locale: locale, preset: .transcription)
        let state = await AssetInventory.status(forModules: [module])
        // Unreserved installed models can report `supported` until first use.
        // Read the installed locale inventory without reserving from this UI query.
        let installedLocales = await SpeechTranscriber.installedLocales
        let installed = state == .installed || installedLocales.contains(locale)
        return .init(locale: locale.identifier, supported: true, installed: installed,
                     message: installed ? "Modelo instalado · transcripción local" : state == .downloading ? "El sistema está descargando el idioma" : "Idioma compatible · requiere descargar el modelo de Apple")
    }
    public static func languages() async -> [String] {
        guard #available(macOS 26, *), SpeechTranscriber.isAvailable else { return [] }
        return await SpeechTranscriber.supportedLocales.map(\.identifier).sorted()
    }
    /// Only the settings button or the explicit CLI command calls this method.
    public static func installLanguage(_ identifier: String) async throws {
        guard #available(macOS 26, *), SpeechTranscriber.isAvailable else { throw AppleSpeechError.unavailable }
        guard let locale = await SpeechTranscriber.supportedLocale(equivalentTo: Locale(identifier: identifier)) else { throw AppleSpeechError.unsupportedLanguage(identifier) }
        try Task.checkCancellation()
        let module = SpeechTranscriber(locale: locale, preset: .transcription)
        let wasReserved = await AssetInventory.reservedLocales.contains(locale)
        try await AssetInventory.reserve(locale: locale)
        do {
            if let request = try await AssetInventory.assetInstallationRequest(supporting: [module]) { try await request.downloadAndInstall() }
            try Task.checkCancellation()
        } catch {
            if !wasReserved { await AssetInventory.release(reservedLocale: locale) }
            throw error
        }
    }
    public static func transcribe(_ source: URL, locale identifier: String = "es-CL", progress: @escaping @Sendable (String) async -> Void = { _ in }) async throws -> SpeechTranscript {
        try Task.checkCancellation()
        guard isSupported else { throw AppleSpeechError.unavailable }
        guard FileKind.of(source) == .audio, FileManager.default.isReadableFile(atPath: source.path) else { throw AppleSpeechError.invalidAudio }
        guard #available(macOS 26, *) else { throw AppleSpeechError.unavailable }
        guard let locale = await SpeechTranscriber.supportedLocale(equivalentTo: Locale(identifier: identifier)) else { throw AppleSpeechError.unsupportedLanguage(identifier) }
        let transcriber = SpeechTranscriber(locale: locale, preset: .transcription)
        let reserved = await AssetInventory.reservedLocales.contains(locale)
        try await AssetInventory.reserve(locale: locale)
        do {
            guard await AssetInventory.status(forModules: [transcriber]) == .installed else { throw AppleSpeechError.missingLanguage(locale.identifier) }
            let temp = FileManager.default.temporaryDirectory.appendingPathComponent("metatron-speech-" + UUID().uuidString + ".wav")
            defer { try? FileManager.default.removeItem(at: temp) }
            let audio: AVAudioFile
            do { audio = try AVAudioFile(forReading: source) }
            catch {
                guard let ffmpeg = Engines.current.ffmpeg else { throw MetatronError.needsEngine("FFmpeg para leer este formato de audio") }
                try await Engines.run(ffmpeg, ["-nostdin", "-v", "error", "-n", "-i", source.path, "-vn", "-t", "14401", "-ac", "1", "-ar", "16000", "-c:a", "pcm_s16le", temp.path])
                audio = try AVAudioFile(forReading: temp)
            }
            let duration = Double(audio.length) / audio.processingFormat.sampleRate
            guard duration.isFinite, duration > 0 else { throw AppleSpeechError.invalidAudio }
            guard duration <= 14_400 else { throw AppleSpeechError.tooLong }
            try Task.checkCancellation()
            let text = try await analyze(audio, transcriber: transcriber, progress: progress)
            if !reserved { await AssetInventory.release(reservedLocale: locale) }
            return SpeechTranscript(text: text, locale: locale.identifier, duration: duration)
        } catch {
            if !reserved { await AssetInventory.release(reservedLocale: locale) }
            throw error
        }
    }
    @available(macOS 26, *)
    private static func analyze(_ audio: AVAudioFile, transcriber: SpeechTranscriber, progress: @escaping @Sendable (String) async -> Void) async throws -> String {
        let analyzer = SpeechAnalyzer(modules: [transcriber])
        return try await withTaskCancellationHandler {
            try await withThrowingTaskGroup(of: String.self) { group in
                group.addTask {
                    var parts: [String] = []
                    var count = 0
                    for try await result in transcriber.results {
                        try Task.checkCancellation()
                        guard result.isFinal else { continue }
                        let text = String(result.text.characters)
                        count += text.count
                        guard count <= 1_000_000 else { throw AppleSpeechError.tooLong }
                        parts.append(text)
                        let seconds = CMTimeGetSeconds(CMTimeRangeGetEnd(result.range))
                        if seconds.isFinite { await progress("Transcribiendo localmente · \(Int(seconds)) s") }
                    }
                    return parts.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
                }
                do {
                    try Task.checkCancellation()
                    try await analyzer.start(inputAudioFile: audio, finishAfterFile: true)
                    let text = try await group.next() ?? ""
                    try Task.checkCancellation()
                    guard !text.isEmpty else { throw AppleSpeechError.noSpeech }
                    return text
                } catch {
                    await analyzer.cancelAndFinishNow()
                    group.cancelAll()
                    throw error
                }
            }
        } onCancel: { Task { await analyzer.cancelAndFinishNow() } }
    }
    public static func write(_ transcript: SpeechTranscript, source: URL, to output: URL, format: OutputFormat) throws {
        guard [.txt, .md].contains(format) else { throw MetatronError.unsupported("Transcripción → " + format.label) }
        try Task.checkCancellation()
        let body: String
        if format == .md {
            body = "# " + MarkdownExport.escape(source.deletingPathExtension().lastPathComponent) + "\n\n> Transcripción automática · Apple Speech · " + transcript.locale + ". Revisa nombres y cifras.\n\n" + MarkdownExport.escape(transcript.text) + "\n"
        } else { body = transcript.text + "\n" }
        try Data(body.utf8).write(to: output, options: .atomic)
    }
}
