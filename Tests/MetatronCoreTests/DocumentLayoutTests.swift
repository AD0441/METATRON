import AppKit
import PDFKit
import Testing
@testable import MetatronCore

@MainActor struct DocumentLayoutTests {
    @Test(.timeLimit(.minutes(2)))
    func wordPDFPreservesHeaderFooterTableAndPageDimensions() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("metatron-layout-" + UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let package = root.appendingPathComponent("package")
        let types = "http://schemas.openxmlformats.org/package/2006/content-types"
        let relationships = "http://schemas.openxmlformats.org/package/2006/relationships"
        let word = "http://schemas.openxmlformats.org/wordprocessingml/2006/main"
        let office = "http://schemas.openxmlformats.org/officeDocument/2006/relationships"
        let parts = [
            "[Content_Types].xml": """
            <Types xmlns="\(types)"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/><Override PartName="/word/header1.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.header+xml"/><Override PartName="/word/footer1.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.footer+xml"/></Types>
            """,
            "_rels/.rels": "<Relationships xmlns=\"\(relationships)\"><Relationship Id=\"main\" Type=\"\(office)/officeDocument\" Target=\"word/document.xml\"/></Relationships>",
            "word/_rels/document.xml.rels": "<Relationships xmlns=\"\(relationships)\"><Relationship Id=\"header\" Type=\"\(office)/header\" Target=\"header1.xml\"/><Relationship Id=\"footer\" Type=\"\(office)/footer\" Target=\"footer1.xml\"/></Relationships>",
            "word/header1.xml": "<w:hdr xmlns:w=\"\(word)\"><w:p><w:r><w:t>HEADER_FIXTURE</w:t></w:r></w:p></w:hdr>",
            "word/footer1.xml": "<w:ftr xmlns:w=\"\(word)\"><w:p><w:r><w:t>FOOTER_FIXTURE</w:t></w:r></w:p></w:ftr>",
            "word/document.xml": """
            <w:document xmlns:w="\(word)" xmlns:r="\(office)"><w:body>
            <w:tbl><w:tblPr><w:tblW w:w="6800" w:type="dxa"/></w:tblPr><w:tblGrid><w:gridCol w:w="3400"/><w:gridCol w:w="3400"/></w:tblGrid><w:tr><w:tc><w:tcPr><w:shd w:fill="1F2F46"/></w:tcPr><w:p><w:r><w:rPr><w:color w:val="FFFFFF"/></w:rPr><w:t>TABLE_FIXTURE</w:t></w:r></w:p></w:tc><w:tc><w:p><w:r><w:t>Value</w:t></w:r></w:p></w:tc></w:tr></w:tbl>
            \((1...90).map { "<w:p><w:r><w:t>ROW_\($0)_END</w:t></w:r></w:p>" }.joined())
            <w:p><w:r><w:t>FINAL_FIXTURE</w:t></w:r></w:p>
            <w:sectPr><w:headerReference w:type="default" r:id="header"/><w:footerReference w:type="default" r:id="footer"/><w:pgSz w:w="8391" w:h="11906"/><w:pgMar w:top="720" w:right="720" w:bottom="720" w:left="720" w:header="200" w:footer="200"/></w:sectPr>
            </w:body></w:document>
            """
        ]
        for (name, text) in parts {
            let path = package.appendingPathComponent(name)
            try FileManager.default.createDirectory(at: path.deletingLastPathComponent(), withIntermediateDirectories: true)
            try Data(text.utf8).write(to: path)
        }
        let source = root.appendingPathComponent("form.docx")
        try await Engines.run(URL(fileURLWithPath: "/usr/bin/zip"), ["-qr", source.path, "."], currentDirectory: package)
        let before = try Data(contentsOf: source)
        var options = ConversionOptions()
        options.preferLibreOffice = false
        let engine = Engine(options: options, planner: OutputPlanner(location: .folder(root)))
        let outcome = try await engine.run(.convert(.pdf), on: [source])
        let output = try #require(outcome.outputs.first)
        let pdf = try #require(PDFDocument(url: output))
        #expect(pdf.pageCount > 1)
        for index in 0..<pdf.pageCount {
            let bounds = try #require(pdf.page(at: index)).bounds(for: .mediaBox)
            #expect(abs(bounds.width - 419.55) < 1)
            #expect(abs(bounds.height - 595.3) < 1)
        }
        let text = pdf.string ?? ""
        for marker in ["HEADER_FIXTURE", "FOOTER_FIXTURE", "TABLE_FIXTURE", "FINAL_FIXTURE"] {
            #expect(text.contains(marker), "Missing \(marker)")
        }
        for index in 1...90 { #expect(text.contains("ROW_\(index)_END")) }
        #expect(try Data(contentsOf: source) == before)
    }
}
