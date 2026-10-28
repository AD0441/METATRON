import AppKit
import PDFKit

/// Native, offline Markdown export. PDF layout is represented by page sections, not inferred semantics.
public enum MarkdownExport {
    public static func convert(_ input: URL, to output: URL) async throws {
        let title = escape(input.deletingPathExtension().lastPathComponent)
        let body: String
        switch FileKind.of(input) {
        case .pdf:
            let doc = try PDFs.open(input)
            var pages: [String] = []
            for index in 0..<doc.pageCount {
                try Task.checkCancellation()
                let text: String = try autoreleasepool {
                    guard let page = doc.page(at: index) else { throw MetatronError.unreadable(input) }
                    let layer = page.string?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    if !layer.isEmpty { return layer }
                    guard let image = PDFs.render(page, dpi: 200) else { throw MetatronError.unreadable(input) }
                    return try VisionTools.recognizeText(image)
                }
                pages.append("## Página \(index + 1)\n\n" + text)
            }
            body = pages.joined(separator: "\n\n")
        case .image:
            body = try VisionTools.recognizeText(Images.load(input).image)
        case .document:
            if ["md", "markdown"].contains(input.pathExtension.lowercased()) {
                try FileManager.default.copyItem(at: input, to: output); return
            }
            body = try await MainActor.run { render(try Documents.read(input)) }
        case .data:
            body = table(try await DataFiles.readTable(input))
        case .subtitle:
            // Preserve the readable transcription through the existing subtitle writer.
            let temp = FileManager.default.temporaryDirectory.appendingPathComponent("metatron-markdown-" + UUID().uuidString + ".txt")
            defer { try? FileManager.default.removeItem(at: temp) }
            try Subtitles.write(try Subtitles.read(input), to: temp, format: .txt)
            body = try String(contentsOf: temp, encoding: .utf8)
        default: throw MetatronError.unsupported("\(input.pathExtension) → Markdown")
        }
        guard !body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw MetatronError.noText }
        try Data(("# " + title + "\n\n" + body + "\n").utf8).write(to: output)
    }

    public static func escape(_ text: String) -> String {
        text.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "*", with: "\\*")
            .replacingOccurrences(of: "_", with: "\\_").replacingOccurrences(of: "[", with: "\\[")
            .replacingOccurrences(of: "]", with: "\\]").replacingOccurrences(of: "#", with: "\\#")
    }
    public static func table(_ rows: [[String]]) -> String {
        guard let first = rows.first else { return "" }
        let width = rows.map(\.count).max() ?? first.count
        guard width > 0 else { return "" }
        func row(_ values: [String]) -> String {
            "| " + (0..<width).map { i in
                i < values.count ? escape(values[i]).replacingOccurrences(of: "|", with: "\\|").replacingOccurrences(of: "\n", with: "<br>") : ""
            }.joined(separator: " | ") + " |"
        }
        return ([row(first), "| " + Array(repeating: "---", count: width).joined(separator: " | ") + " |"] + rows.dropFirst().map(row)).joined(separator: "\n")
    }
    @MainActor public static func render(_ attributed: NSAttributedString) -> String {
        let text = attributed.string as NSString
        var result = ""
        var position = 0
        while position < text.length {
            let paragraph = text.paragraphRange(for: NSRange(location: position, length: 0))
            let content = text.substring(with: paragraph).trimmingCharacters(in: .newlines)
            if content.isEmpty { result += "\n"; position = NSMaxRange(paragraph); continue }
            let font = attributed.attribute(.font, at: position, effectiveRange: nil) as? NSFont
            let prefix = (font?.pointSize ?? 12) >= 22 ? "## " : (font?.pointSize ?? 12) >= 17 ? "### " : ""
            var line = ""
            attributed.enumerateAttributes(in: NSRange(location: position, length: (content as NSString).length)) { attrs, range, _ in
                var fragment = escape(text.substring(with: range))
                if let link = attrs[.link] {
                    let url = (link as? URL)?.absoluteString ?? String(describing: link)
                    fragment = "[\(fragment)](\(url.replacingOccurrences(of: ")", with: "%29")))"
                } else if let font = attrs[.font] as? NSFont {
                    let traits = font.fontDescriptor.symbolicTraits
                    if traits.contains(.bold) { fragment = "**" + fragment + "**" }
                    if traits.contains(.italic) { fragment = "_" + fragment + "_" }
                }
                line += fragment
            }
            result += prefix + line + "\n\n"
            position = NSMaxRange(paragraph)
        }
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
