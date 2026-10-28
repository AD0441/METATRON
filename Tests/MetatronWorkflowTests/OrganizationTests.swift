import Testing
import Foundation
import PDFKit
import CoreGraphics
import MetatronCore
@testable import MetatronWorkflow

struct RetentionTests {
    @Test(arguments: [7, 14, 30]) func retentionPreservesActiveAndRecent(days: Int) {
        let now = Date()
        var old = WorkJob(inputs: [], recipe: Recipe.builtIns[0]); old.state = .completed; old.created = now.addingTimeInterval(-Double(days + 1) * 86400)
        var current = old; current.id = UUID(); current.created = now
        var running = old; running.id = UUID(); running.state = .running
        var waiting = old; waiting.id = UUID(); waiting.state = .queued
        let result = ActivityRetention.retained([old, current, running, waiting], days: days, now: now)
        #expect(result.map(\.id) == [current.id, running.id, waiting.id])
        #expect(ActivityRetention.retained([old], days: 0, now: now).count == 1)
    }
    @Test func destinationRoundTrip() throws {
        let original = SavedDestination(name: "Investigación", folder: URL(fileURLWithPath: "/tmp/Papers"))
        #expect(try JSONDecoder().decode(SavedDestination.self, from: JSONEncoder().encode(original)) == original)
    }
}
struct MarkdownTests {
    @Test func markdownIsOfferedForDocumentsImagesAndTables() {
        for name in ["a.pdf", "a.docx", "a.png", "a.csv"] {
            #expect(ActionCatalog.convertActions(for: [URL(fileURLWithPath: "/tmp/" + name)]).contains(.convert(.md)))
        }
    }
    @Test func pdfExportsPagesAndPreservesSource() async throws {
        let fixture = try Fixtures(); defer { fixture.clean() }
        let input = try fixture.pdf(name: "paper.pdf")
        let before = try FileIntegrity.digest(input)
        let result = try await RecipeExecutor.execute(inputs: [input], recipe: Recipe(name: "Markdown", steps: [.init(action: "convert.md")]))
        let output = try #require(result.files.first { $0.url.pathExtension == "md" })
        let text = try String(contentsOf: output.url, encoding: .utf8)
        #expect(text.contains("## Página 1")); #expect(text.contains("CONFIDENTIAL"))
        #expect(try FileIntegrity.digest(input) == before)
    }
    @Test func markdownEscapesTableSeparatorsAndPadsCells() async throws {
        let fixture = try Fixtures(); defer { fixture.clean() }
        let input = fixture.directory.appendingPathComponent("table.csv")
        try Data("Nombre,Valor\nA|B,42\nSolo\n".utf8).write(to: input)
        let result = try await RecipeExecutor.execute(inputs: [input], recipe: Recipe(name: "Tabla Markdown", steps: [.init(action: "convert.md")]))
        let text = try String(contentsOf: #require(result.files.first).url, encoding: .utf8)
        #expect(text.contains("| Nombre | Valor |")); #expect(text.contains("A\\|B")); #expect(text.contains("| Solo |  |"))
    }
}
struct BoundedPDFTests {
    @Test func longImageUsesBudgetAndPreservesPageOrder() throws {
        let fixture = try Fixtures(); defer { fixture.clean() }
        let input = fixture.directory.appendingPathComponent("pages.pdf")
        var box = CGRect(x: 0, y: 0, width: 200, height: 300)
        let context = try #require(CGContext(input as CFURL, mediaBox: &box, nil))
        for index in 0..<12 {
            context.beginPDFPage(nil)
            context.setFillColor(CGColor(gray: index == 0 ? 0 : 1, alpha: 1)); context.fill(box)
            context.endPDFPage()
        }
        context.closePDF()
        let doc = try PDFs.open(input)
        let image = try PDFs.longImage(doc, dpi: 200, maxHeight: 1200, maxPixels: 300_000)
        #expect(image.height <= 1200); #expect(image.width * image.height <= 300_000)
        let pixels = try #require(CGContext(data: nil, width: image.width, height: image.height, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        pixels.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        let data = try #require(pixels.data).assumingMemoryBound(to: UInt8.self)
        #expect(data[(image.height / 24) * pixels.bytesPerRow + image.width / 2 * 4] < 20)
        #expect(data[(image.height - image.height / 24 - 1) * pixels.bytesPerRow + image.width / 2 * 4] > 230)
        withExtendedLifetime(doc) {}
    }
}
