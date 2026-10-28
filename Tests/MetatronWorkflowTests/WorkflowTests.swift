import Testing
import Foundation
import CoreGraphics
import CoreText
import PDFKit
import ImageIO
@testable import MetatronWorkflow
import MetatronCore

struct Fixtures {
    let directory: URL
    init() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent("metatron-test-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }
    func image(name: String = "photo.png", width: Int = 800, height: Int = 600) throws -> URL {
        let ctx = try #require(CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        ctx.setFillColor(CGColor(srgbRed: 0.9, green: 0.4, blue: 0.1, alpha: 1)); ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))
        ctx.setFillColor(.black); ctx.fillEllipse(in: CGRect(x: 50, y: 50, width: 200, height: 180))
        let url = directory.appendingPathComponent(name)
        try Images.write(#require(ctx.makeImage()), to: url, format: .png, quality: 1)
        return url
    }
    func pdf(name: String, changed: Bool = false) throws -> URL {
        let url = directory.appendingPathComponent(name)
        var rect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let ctx = try #require(CGContext(url as CFURL, mediaBox: &rect, nil))
        ctx.beginPDFPage(nil)
        ctx.setFillColor(.white); ctx.fill(rect)
        let text = NSAttributedString(string: "CONFIDENTIAL Metatron document", attributes: [.init(kCTFontAttributeName as String): CTFontCreateWithName("Helvetica" as CFString, 22, nil)])
        ctx.textPosition = CGPoint(x: 72, y: 700)
        CTLineDraw(CTLineCreateWithAttributedString(text), ctx)
        if changed { ctx.setFillColor(CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 1)); ctx.fill(CGRect(x: 100, y: 300, width: 150, height: 100)) }
        ctx.endPDFPage(); ctx.closePDF()
        return url
    }
    func clean() { try? FileManager.default.removeItem(at: directory) }
}

struct SimulationTests {
    @Test func `simulation does not create output folders or modify inputs`() throws {
        let fixture = try Fixtures(); defer { fixture.clean() }
        let source = try fixture.image()
        let before = try FileIntegrity.digest(source)
        let destination = fixture.directory.appendingPathComponent("not-created")
        let recipe = Recipe(name: "test", steps: [.init(action: "convert.jpg")], folderPath: destination.path)
        let rows = try Simulation.plan(inputs: [source], recipe: recipe)
        #expect(rows.count == 1)
        #expect(rows[0].destination.hasSuffix("photo-metatron.jpg"))
        #expect(!FileManager.default.fileExists(atPath: destination.path))
        #expect(try FileIntegrity.digest(source) == before)
    }
    @Test(arguments: ["../escape", "folder/name", "bad:name", "\0"])
    func `unsafe names are rejected`(_ suffix: String) throws {
        let fixture = try Fixtures(); defer { fixture.clean() }
        let source = try fixture.image()
        let recipe = Recipe(name: "bad", steps: [.init(action: "convert.jpg")], suffix: suffix)
        #expect(throws: WorkflowError.self) { try Simulation.plan(inputs: [source], recipe: recipe) }
    }
    @Test func `batch planning reserves duplicate names`() throws {
        let fixture = try Fixtures(); defer { fixture.clean() }
        let a = fixture.directory.appendingPathComponent("a/photo.png")
        let b = fixture.directory.appendingPathComponent("b/photo.png")
        let recipe = Recipe(name: "test", steps: [.init(action: "convert.jpg")], folderPath: fixture.directory.appendingPathComponent("out").path)
        let rows = try Simulation.plan(inputs: [a,b], recipe: recipe)
        #expect(rows[0].destination != rows[1].destination)
    }
}
struct RecipeExecutionTests {
    @Test func `conversion validates output and preserves original`() async throws {
        let fixture = try Fixtures(); defer { fixture.clean() }
        let source = try fixture.image()
        let original = try FileIntegrity.digest(source)
        let recipe = Recipe(name: "JPEG", steps: [.init(action: "convert.jpg")])
        let result = try await RecipeExecutor.execute(inputs: [source], recipe: recipe)
        let output = try #require(result.files.first)
        #expect(output.url.pathExtension == "jpg")
        #expect(try Images.load(output.url).image.width == 800)
        #expect(try FileIntegrity.digest(source) == original)
        #expect(result.files.contains { $0.url.lastPathComponent.hasPrefix("metatron-") })
    }
    @Test func `repeated conversions never overwrite a prior output`() async throws {
        let fixture = try Fixtures(); defer { fixture.clean() }
        let source = try fixture.image()
        let recipe = Recipe(name: "JPEG", steps: [.init(action: "convert.jpg")])
        let a = try await RecipeExecutor.execute(inputs: [source], recipe: recipe)
        let b = try await RecipeExecutor.execute(inputs: [source], recipe: recipe)
        #expect(a.files[0].url != b.files[0].url)
        #expect(try FileIntegrity.digest(a.files[0].url) == a.files[0].digest)
    }
    @Test func `multi step recipe resizes and meets the byte limit`() async throws {
        let fixture = try Fixtures(); defer { fixture.clean() }
        let source = try fixture.image(width: 2000, height: 1500)
        let recipe = Recipe(name: "delivery", steps: [.init(action: "resize", number: 600), .init(action: "tool.stripMetadata"), .init(action: "targetSize", number: 30)])
        let result = try await RecipeExecutor.execute(inputs: [source], recipe: recipe)
        let output = try #require(result.files.first)
        #expect(output.bytes <= 30_000)
        #expect(try Images.load(output.url).image.width <= 600)
    }
    @Test func `undo refuses changed output without moving any other result`() async throws {
        let fixture = try Fixtures(); defer { fixture.clean() }
        let source = try fixture.image()
        let result = try await RecipeExecutor.execute(inputs: [source], recipe: Recipe(name: "JPEG", steps: [.init(action: "convert.jpg")]))
        try Data("edited".utf8).write(to: result.files[0].url)
        await #expect(throws: WorkflowError.changedOutput(result.files[0].url.lastPathComponent)) {
            try await RecipeExecutor.undo(result.files, directory: fixture.directory.appendingPathComponent("undo"))
        }
        #expect(result.files.allSatisfy { FileManager.default.fileExists(atPath: $0.url.path) })
    }
    @Test func `undo archives generated files and keeps the source`() async throws {
        let fixture = try Fixtures(); defer { fixture.clean() }
        let source = try fixture.image()
        let result = try await RecipeExecutor.execute(inputs: [source], recipe: Recipe(name: "JPEG", steps: [.init(action: "convert.jpg")]))
        let undo = fixture.directory.appendingPathComponent("undo")
        try await RecipeExecutor.undo(result.files, directory: undo)
        #expect(result.files.allSatisfy { !FileManager.default.fileExists(atPath: $0.url.path) })
        #expect(try FileManager.default.contentsOfDirectory(atPath: undo.path).count == result.files.count)
        #expect(FileManager.default.fileExists(atPath: source.path))
    }
    @Test func `unsupported steps never publish results`() async throws {
        let fixture = try Fixtures(); defer { fixture.clean() }
        let source = try fixture.image()
        let output = fixture.directory.appendingPathComponent("out")
        let recipe = Recipe(name: "bad", steps: [.init(action: "convert.jpg"), .init(action: "bogus")], folderPath: output.path)
        await #expect(throws: WorkflowError.unsupportedStep("bogus")) { try await RecipeExecutor.execute(inputs: [source], recipe: recipe) }
        #expect(!FileManager.default.fileExists(atPath: output.path))
    }
}
struct PDFWorkbenchTests {
    @Test func `PDF comparison detects a changed page and identical pages`() async throws {
        let fixture = try Fixtures(); defer { fixture.clean() }
        let a = try fixture.pdf(name: "a.pdf"), b = try fixture.pdf(name: "b.pdf", changed: true)
        let same = try await PDFWorkbench.compare(a, a, destination: fixture.directory.appendingPathComponent("same"))
        let different = try await PDFWorkbench.compare(a, b, destination: fixture.directory.appendingPathComponent("different"))
        #expect(same[0].fraction == 0)
        #expect(different[0].fraction > 0.01)
    }
    @Test func `redacted PDF has no recoverable text layer and original remains intact`() throws {
        let fixture = try Fixtures(); defer { fixture.clean() }
        let source = try fixture.pdf(name: "confidential.pdf")
        let output = fixture.directory.appendingPathComponent("redacted", isDirectory: true)
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        let result = try PDFWorkbench.redact(source, terms: ["CONFIDENTIAL"], into: output)
        #expect(try PDFs.open(source).string?.contains("CONFIDENTIAL") == true)
        #expect(try PDFs.open(result).string?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != false)
        #expect(try PDFs.open(result).pageCount == 1)
    }
    @Test func `invalid page order fails rather than dropping pages silently`() throws {
        let fixture = try Fixtures(); defer { fixture.clean() }
        let source = try fixture.pdf(name: "a.pdf")
        #expect(throws: WorkflowError.self) { try PDFWorkbench.reorder(source, pages: "3,1", into: fixture.directory) }
    }
    @Test func `recipe JSON preserves step order and options`() throws {
        let recipe = Recipe(name: "roundtrip", steps: [.init(action: "resize", number: 1600), .init(action: "convert.jpg")], quality: 0.7, preserveMetadata: false)
        let decoded = try JSONDecoder().decode(Recipe.self, from: JSONEncoder().encode(recipe))
        #expect(decoded == recipe)
    }
}

struct MoveTransactionTests {
    @Test func `move and undo preserve content and resolve collisions`() async throws {
        let fixture = try Fixtures(); defer { fixture.clean() }
        let source = try fixture.image()
        let destination = fixture.directory.appendingPathComponent("destination", isDirectory: true)
        try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)
        try Data("existing".utf8).write(to: destination.appendingPathComponent(source.lastPathComponent))
        let digest = try FileIntegrity.digest(source)
        let moved = try await FileMoveTransaction.move([source], into: destination)
        #expect(moved[0].destination.lastPathComponent != source.lastPathComponent)
        #expect(try FileIntegrity.digest(moved[0].destination) == digest)
        try await FileMoveTransaction.undo(moved)
        #expect(try FileIntegrity.digest(source) == digest)
        #expect(try String(contentsOf: destination.appendingPathComponent(source.lastPathComponent), encoding: .utf8) == "existing")
    }
}

struct AdditionalIntegrityTests {
    @Test func `password protection is validated without persisting the password`() async throws {
        let fixture = try Fixtures(); defer { fixture.clean() }
        let source = try fixture.pdf(name: "source.pdf")
        let recipe = Recipe(name: "Protected", steps: [.init(action: "tool.protect")])
        let result = try await RecipeExecutor.execute(inputs: [source], recipe: recipe, parameters: .password("test-only-123"))
        let protected = try #require(PDFDocument(url: result.files[0].url))
        #expect(protected.isEncrypted)
        #expect(protected.unlock(withPassword: "test-only-123"))
        let receipt = try #require(result.files.last)
        #expect(try String(contentsOf: receipt.url, encoding: .utf8).contains("test-only-123") == false)
    }
    @Test func `redaction paints the selected text region black`() throws {
        let fixture = try Fixtures(); defer { fixture.clean() }
        let source = try fixture.pdf(name: "source.pdf")
        let doc = try PDFs.open(source)
        let selection = try #require(doc.findString("CONFIDENTIAL", withOptions: []).first)
        let page = try #require(doc.page(at: 0))
        let bounds = selection.bounds(for: page)
        let folder = fixture.directory.appendingPathComponent("out", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let output = try PDFWorkbench.redact(source, terms: ["CONFIDENTIAL"], into: folder)
        let outputDocument = try PDFs.open(output)
        defer { withExtendedLifetime(outputDocument) {} }
        let resultPage = try #require(outputDocument.page(at: 0))
        let image = try #require(PDFs.render(resultPage, dpi: 72))
        let crop = CGRect(x: bounds.midX - 3, y: CGFloat(image.height) - bounds.midY - 3, width: 6, height: 6)
        let sample = try #require(image.cropping(to: crop))
        let ctx = try #require(CGContext(data: nil, width: 6, height: 6, bitsPerComponent: 8, bytesPerRow: 24, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        ctx.draw(sample, in: CGRect(x: 0,y: 0,width: 6,height: 6))
        let data = try #require(ctx.data).bindMemory(to: UInt8.self, capacity: 144)
        var maximum = 0
        for pixel in 0..<36 {
            let offset = pixel * 4
            let red = Int(data[offset])
            let green = Int(data[offset + 1])
            let blue = Int(data[offset + 2])
            maximum = max(maximum, red + green + blue)
        }
        #expect(maximum < 60, "The selected content must actually be blacked out, not only lose its text layer")
    }
}

struct ImageMarkupTests {
    @Test func `raster redaction is baked into pixels and preserves the source`() async throws {
        let fixture = try Fixtures(); defer { fixture.clean() }
        let source = try fixture.image()
        let hash = try FileIntegrity.digest(source)
        let strokes = [MarkStroke(kind: "redact", points: [.init(x: 0.5,y: 0.5),.init(x: 0.75,y: 0.75)])]
        let json = String(decoding: try JSONEncoder().encode(strokes),as: UTF8.self)
        let result = try await RecipeExecutor.execute(inputs: [source],recipe: Recipe(name: "markup",steps: [.init(action: "imageMarkup",text: json)],preserveMetadata: false))
        let image = try Images.load(result.files[0].url).image
        let crop = try #require(image.cropping(to: CGRect(x: 475,y: 355,width: 5,height: 5)))
        let ctx = try #require(CGContext(data: nil,width: 5,height: 5,bitsPerComponent: 8,bytesPerRow: 20,space: CGColorSpaceCreateDeviceRGB(),bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        ctx.draw(crop,in: CGRect(x: 0,y: 0,width: 5,height: 5))
        let bytes = try #require(ctx.data).bindMemory(to: UInt8.self,capacity: 100)
        #expect(bytes[0] == 0 && bytes[1] == 0 && bytes[2] == 0)
        #expect(try FileIntegrity.digest(source) == hash)
    }
}
