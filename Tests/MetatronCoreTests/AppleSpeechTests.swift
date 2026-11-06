import Testing
import Foundation
@testable import MetatronCore

struct AppleSpeechTests {
    @Test func oldRecipeOptionsDecodeWithoutASpeechLocale() throws {
        var json = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(ConversionOptions())) as? [String: Any])
        json.removeValue(forKey: "speechLocale")
        let decoded = try JSONDecoder().decode(ConversionOptions.self, from: JSONSerialization.data(withJSONObject: json))
        #expect(decoded.speechLocale == nil)
        #expect(decoded.imageQuality == 0.9)
    }
    @Test func textAndMarkdownExportPreserveTranscriptAndEscapeTheTitle() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let transcript = SpeechTranscript(text: "Hola, mañana comienza la reunión. Revisa *esta cifra*.", locale: "es_CL", duration: 5)
        let source = folder.appendingPathComponent("Clase [uno].m4a")
        let txt = folder.appendingPathComponent("texto.txt"), md = folder.appendingPathComponent("texto.md")
        try AppleSpeech.write(transcript, source: source, to: txt, format: .txt)
        try AppleSpeech.write(transcript, source: source, to: md, format: .md)
        #expect(try String(contentsOf: txt, encoding: .utf8) == transcript.text + "\n")
        let markdown = try String(contentsOf: md, encoding: .utf8)
        #expect(markdown.contains("# Clase \\[uno\\]"))
        #expect(markdown.contains("Apple Speech · es_CL"))
        #expect(markdown.contains("\\*esta cifra\\*"))
    }
    @Test func audioCatalogOffersTranscriptionOnlyWhenTheDeviceSupportsIt() {
        let audio = URL(fileURLWithPath: "/tmp/recording.m4a")
        let actions = ActionCatalog.convertActions(for: [audio], engines: Engines())
        let tools = ActionCatalog.toolActions(for: [audio], engines: Engines())
        #expect(actions.contains(.convert(.txt)) == AppleSpeech.isSupported)
        #expect(actions.contains(.convert(.md)) == AppleSpeech.isSupported)
        #expect(tools.contains(.tool(.transcribeAudio)) == AppleSpeech.isSupported)
        #expect(ActionCatalog.toolActions(for: [URL(fileURLWithPath: "/tmp/image.png")], engines: Engines()).contains(.tool(.transcribeAudio)) == false)
    }
    @Test func cancelledTranscriptionDoesNotOpenOrPrepareAnAudioFile() async {
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await AppleSpeech.transcribe(URL(fileURLWithPath: "/nonexistent/audio.m4a"))
        }
        await #expect(throws: CancellationError.self) { try await task.value }
    }
    @Test func missingAudioHasAClearFailureBeforeModelPreparation() async {
        do { _ = try await AppleSpeech.transcribe(URL(fileURLWithPath: "/nonexistent/audio.m4a")); Issue.record("Expected missing audio failure") }
        catch let error as AppleSpeechError { #expect(error == .invalidAudio || error == .unavailable) }
        catch { Issue.record("Unexpected error: \(error)") }
    }
}
