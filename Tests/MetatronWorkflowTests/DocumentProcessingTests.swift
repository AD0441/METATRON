import Testing
import Foundation
import PDFKit
import CoreGraphics
import MetatronCore
@testable import MetatronWorkflow

struct DocumentProcessingTests {
    @Test func mixedInputsBecomeOneVerifiedPDFWithoutChangingOriginals() async throws {
        let fixture=try Fixtures()
        defer {try? FileManager.default.removeItem(at:fixture.directory)}
        let image=try fixture.image()
        let pdf=try fixture.pdf(name:"original.pdf")
        let hashes=try [image,pdf].map {try FileIntegrity.digest($0)}
        let recipe=Recipe(name:"Combinar",steps:[.init(action:"bundlePDF")],folderPath:fixture.directory.appendingPathComponent("out").path)
        let result=try await RecipeExecutor.execute(inputs:[image,pdf],recipe:recipe)
        let output=try #require(result.files.first(where:{$0.url.pathExtension == "pdf"}))
        #expect(PDFDocument(url:output.url)?.pageCount == 2)
        #expect(try [image,pdf].map {try FileIntegrity.digest($0)} == hashes)
        #expect(result.inputBytes>0)
        #expect(try FileIntegrity.digest(output.url) == output.digest)
    }
    @Test func embeddedRasterIsExportedSeparatelyFromPagePreviews() throws {
        let fixture=try Fixtures()
        defer {try? FileManager.default.removeItem(at:fixture.directory)}
        let source=try fixture.image(width:80,height:60)
        let pdf=fixture.directory.appendingPathComponent("embedded.pdf")
        var rect=CGRect(x:0,y:0,width:200,height:200)
        let context=try #require(CGContext(pdf as CFURL,mediaBox:&rect,nil))
        context.beginPDFPage(nil);context.draw(try Images.load(source).image,in:rect);context.endPDFPage();context.closePDF()
        let folder=fixture.directory.appendingPathComponent("rasters")
        let report=try PDFEmbeddedImages.extract(pdf,into:folder)
        try #require(report.extracted>0)
        let files=try FileManager.default.contentsOfDirectory(at:folder,includingPropertiesForKeys:nil)
        let output=try #require(files.first { ["png","jpg","jp2"].contains($0.pathExtension) })
        let image=try Images.load(output).image
        #expect(image.width == 80)
        #expect(image.height == 60)
    }
    @Test func nativeAnalysisExportsMarkdownAndProvenance() async throws {
        let fixture=try Fixtures()
        defer {try? FileManager.default.removeItem(at:fixture.directory)}
        let input=try fixture.pdf(name:"informe.pdf")
        let folder=fixture.directory.appendingPathComponent("analysis")
        let output=try await DocumentProcessing.structured(input,engine:.native,into:folder)
        let children=try FileManager.default.contentsOfDirectory(at:output,includingPropertiesForKeys:nil)
        #expect(children.contains {$0.pathExtension == "md"})
        let provenance=try JSONSerialization.jsonObject(with:Data(contentsOf:folder.appendingPathComponent("procedencia.json"))) as? [String:Any]
        #expect(provenance?["processedLocally"] as? Bool == true)
        #expect((provenance?["warnings"] as? [String])?.isEmpty == false)
    }
    @Test func optionalAdapterRunsOnlyTheExplicitExecutable() async throws {
        let fixture=try Fixtures()
        defer {try? FileManager.default.removeItem(at:fixture.directory)}
        let input=fixture.directory.appendingPathComponent("tabla.csv")
        try "Nombre,Valor\nEjemplo,42".write(to:input,atomically:true,encoding:.utf8)
        let adapter=fixture.directory.appendingPathComponent("adapter")
        try "#!/bin/sh\nprintf '# Tabla\\n\\n| Valor |\\n| --- |\\n| 42 |\\n' > \"$3\"\n".write(to:adapter,atomically:true,encoding:.utf8)
        try FileManager.default.setAttributes([.posixPermissions:0o700],ofItemAtPath:adapter.path)
        let folder=fixture.directory.appendingPathComponent("structured")
        _=try await DocumentProcessing.structured(input,engine:.markitdown,customPath:adapter.path,into:folder)
        let markdown=try String(contentsOf:folder.appendingPathComponent("documento.md"),encoding:.utf8)
        #expect(markdown.contains("42"))
        #expect(FileManager.default.fileExists(atPath:input.path))
    }
    @Test func preflightReadsDimensionsAndPredictsResizeWithoutWritingOutputs() throws {
        let fixture=try Fixtures()
        defer {try? FileManager.default.removeItem(at:fixture.directory)}
        let image=try fixture.image(width:800,height:600)
        let destination=fixture.directory.appendingPathComponent("untouched")
        let recipe=Recipe(name:"Entrega",steps:[.init(action:"resize",number:400),.init(action:"convert.jpg"),.init(action:"tool.stripMetadata")],folderPath:destination.path)
        let rows=try Simulation.plan(inputs:[image],recipe:recipe)
        let row=try #require(rows.first)
        #expect(row.facts.contains {$0.contains("800 × 600")})
        #expect(row.facts.contains {$0.contains("400 × 300")})
        #expect(row.warnings.contains {$0.contains("metadatos")})
        #expect(!FileManager.default.fileExists(atPath:destination.path))
    }
}
