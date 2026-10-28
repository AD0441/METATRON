import Foundation
import MetatronCore
public enum DocumentIndex {
    @concurrent public static func extract(_ url: URL) async throws -> String {
        switch FileKind.of(url) {
        case .pdf: try PDFs.text(of: PDFs.open(url))
        case .image: try VisionTools.recognizeText(Images.load(url).image)
        case .document: try await MainActor.run { try Documents.read(url).string }
        default: try String(contentsOf: url, encoding: .utf8)
        }
    }
    public static func suggestTag(text: String, filename: String) -> String {
        let text = (filename + " " + text.prefix(5000)).lowercased()
        for (word,tag) in [("rúbrica","Evaluación"),("evaluación","Evaluación"),("diagnóstico","Diagnóstico"),("asignatura","Docencia"),("abstract","Investigación"),("referencias","Investigación"),("informe","Informe")] { if text.contains(word) { return tag } }
        return "Documento"
    }
}
