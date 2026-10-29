import Foundation
import MetatronCore
public enum DocumentIndex {
    public static func supports(_ url: URL) -> Bool {
        switch FileKind.of(url) {
        case .image: ActionCatalog.supports(.tool(.extractText), for: [url])
        case .pdf, .document, .data, .subtitle: true
        default: false
        }
    }
    @concurrent public static func extract(_ url: URL) async throws -> String {
        guard supports(url) else { throw WorkflowError.invalid("Este tipo de archivo no puede indexarse como texto. Convierte primero el audio a TXT o Markdown.") }
        switch FileKind.of(url) {
        case .pdf: return try PDFs.text(of: PDFs.open(url))
        case .image: return try VisionTools.recognizeText(Images.load(url).image)
        case .document: return try await MainActor.run { try Documents.read(url).string }
        case .data: return MarkdownExport.table(try await DataFiles.readTable(url))
        default: return try String(contentsOf: url, encoding: .utf8)
        }
    }
    public static func suggestTag(text: String, filename: String) -> String {
        let text = (filename + " " + text.prefix(5000)).lowercased()
        for (word,tag) in [("rúbrica","Evaluación"),("evaluación","Evaluación"),("diagnóstico","Diagnóstico"),("asignatura","Docencia"),("abstract","Investigación"),("referencias","Investigación"),("informe","Informe")] { if text.contains(word) { return tag } }
        return "Documento"
    }
}
