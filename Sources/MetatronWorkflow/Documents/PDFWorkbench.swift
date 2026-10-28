import Foundation
import PDFKit
import AppKit
import Vision
import CoreImage
import MetatronCore

public struct PDFDifference: Codable, Identifiable, Sendable {
    public var id: Int
    public var fraction: Double
    public var preview: URL
}
public enum PDFWorkbench {
    @concurrent public static func compare(_ first: URL, _ second: URL, destination: URL) async throws -> [PDFDifference] {
        let a = try PDFs.open(first), b = try PDFs.open(second)
        defer { withExtendedLifetime((a, b)) {} }
        guard !a.isLocked, !b.isLocked else { throw WorkflowError.invalid("Desbloquea los PDF antes de compararlos.") }
        try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)
        var result: [PDFDifference] = []
        for index in 0..<max(a.pageCount, b.pageCount) {
            try Task.checkCancellation()
            let row: PDFDifference = try autoreleasepool {
                let pa = a.page(at: index), pb = b.page(at: index)
                let ia = pa.flatMap { PDFs.render($0, dpi: 90) }.map { Images.fit($0, maxSide: 1500) }
                let ib = pb.flatMap { PDFs.render($0, dpi: 90) }.map { Images.fit($0, maxSide: 1500) }
                guard let reference = ia ?? ib else { throw WorkflowError.emptyResult }
                let width = max(ia?.width ?? 1, ib?.width ?? 1), height = max(ia?.height ?? 1, ib?.height ?? 1)
                let extent = CGRect(x: 0, y: 0, width: width, height: height)
                let white = CIImage(color: .white).cropped(to: extent)
                let ca = ia.map { CIImage(cgImage: $0).composited(over: white) } ?? white
                let cb = ib.map { CIImage(cgImage: $0).composited(over: white) } ?? white
                let difference = ca.applyingFilter("CIDifferenceBlendMode", parameters: [kCIInputBackgroundImageKey: cb]).cropped(to: extent)
                guard let raw = MetalImages.context.createCGImage(difference, from: extent) else { throw WorkflowError.emptyResult }
                let fraction = ia == nil || ib == nil ? 1.0 : changedFraction(raw)
                let red = difference.applyingFilter("CIColorMatrix", parameters: [
                    "inputRVector": CIVector(x: 4, y: 4, z: 4, w: 0),
                    "inputGVector": CIVector(x: 0, y: 0, z: 0, w: 0),
                    "inputBVector": CIVector(x: 0, y: 0, z: 0, w: 0),
                    "inputAVector": CIVector(x: 3, y: 3, z: 3, w: 0)])
                let overlay = red.composited(over: CIImage(cgImage: reference).composited(over: white)).cropped(to: extent)
                guard let image = MetalImages.context.createCGImage(overlay, from: extent) else { throw WorkflowError.emptyResult }
                let out = destination.appendingPathComponent(String(format: "pagina-%03d.png", index + 1))
                try Images.write(image, to: out, format: .png, quality: 1)
                return PDFDifference(id: index + 1, fraction: fraction, preview: out)
            }
            result.append(row)
        }
        try JSONEncoder().encode(result).write(to: destination.appendingPathComponent("comparacion.json"))
        return result
    }
    private static func changedFraction(_ image: CGImage) -> Double {
        let width = image.width, height = image.height
        guard let ctx = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue), let data = ctx.data else { return 1 }
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        let pixels = data.bindMemory(to: UInt8.self, capacity: width * height * 4)
        var changed = 0
        for index in stride(from: 0, to: width * height * 4, by: 4) { if max(pixels[index], pixels[index + 1], pixels[index + 2]) > 12 { changed += 1 } }
        return Double(changed) / Double(width * height)
    }
    public static func research(_ input: URL, into destination: URL) throws -> URL {
        try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)
        var markdown = "# \(input.deletingPathExtension().lastPathComponent)\n\nExtracción local de Metatron. Revisa tablas, fórmulas y orden de lectura.\n"
        var records: [[String: String]] = []
        if FileKind.of(input) == .pdf {
            let document = try PDFs.open(input)
            guard !document.isLocked else { throw WorkflowError.invalid("El PDF está protegido.") }
            for index in 0..<document.pageCount {
                try Task.checkCancellation()
                try autoreleasepool {
                    guard let page = document.page(at: index) else { return }
                    let native = page.string?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    let preview = PDFs.render(page, dpi: 100)
                    let text = native.isEmpty ? try preview.map(VisionTools.recognizeText) ?? "" : native
                    markdown += "\n## Página \(index + 1)\n\n\(text)\n"
                    records.append(["page": String(index + 1), "text": text, "method": native.isEmpty ? "Vision OCR" : "PDF text layer"])
                    if let preview { try Images.write(preview, to: destination.appendingPathComponent(String(format: "pagina-%03d.jpg", index + 1)), format: .jpg, quality: 0.8) }
                }
            }
        } else if FileKind.of(input) == .image {
            let text = try VisionTools.recognizeText(Images.load(input).image)
            markdown += "\n\(text)\n"; records.append(["page":"1", "text":text, "method":"Vision OCR"])
        } else {
            let text = try String(contentsOf: input, encoding: .utf8)
            markdown += "\n" + text; records.append(["page":"1", "text":text, "method":"UTF-8"])
        }
        try Data(markdown.utf8).write(to: destination.appendingPathComponent("documento.md"))
        let encoder = JSONEncoder(); encoder.outputFormatting = .prettyPrinted
        try encoder.encode(records).write(to: destination.appendingPathComponent("estructura.json"))
        return destination
    }
    public static func tableRows(_ input: URL, into folder: URL) throws -> URL {
        let doc = try PDFs.open(input)
        var csv = "pagina,fila,celdas\n"
        for index in 0..<doc.pageCount {
            try Task.checkCancellation()
            guard let page = doc.page(at: index), let image = PDFs.render(page, dpi: 160) else { continue }
            let request = VNRecognizeTextRequest(); request.recognitionLevel = .accurate; request.recognitionLanguages = ["es-ES", "en-US"]; request.automaticallyDetectsLanguage = false
            try VNImageRequestHandler(cgImage: image).perform([request])
            let boxes = (request.results ?? []).sorted { $0.boundingBox.midY > $1.boundingBox.midY }
            var rows: [[VNRecognizedTextObservation]] = []
            for box in boxes {
                if let last = rows.last, let anchor = last.first, abs(anchor.boundingBox.midY - box.boundingBox.midY) < 0.012 {
                    rows[rows.count - 1].append(box)
                } else { rows.append([box]) }
            }
            for (row, cells) in rows.enumerated() {
                let values = cells.sorted { $0.boundingBox.minX < $1.boundingBox.minX }.compactMap { $0.topCandidates(1).first?.string }
                csv += "\(index + 1),\(row + 1)," + values.map { "\"" + $0.replacingOccurrences(of: "\"", with: "\"\"") + "\"" }.joined(separator: ",") + "\n"
            }
        }
        let out = folder.appendingPathComponent(input.deletingPathExtension().lastPathComponent + ".csv")
        try Data(csv.utf8).write(to: out); return out
    }
    public static func reorder(_ input: URL, pages: String, into folder: URL) throws -> URL {
        let document = try PDFs.open(input)
        let indexes = pages.split(separator: ",").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
        guard !indexes.isEmpty, indexes.count == pages.split(separator: ",").count, indexes.allSatisfy({ $0 > 0 && $0 <= document.pageCount }) else { throw WorkflowError.invalid("Indica páginas válidas separadas por comas; por ejemplo 3,1,2.") }
        let result = PDFDocument()
        for index in indexes { if let page = document.page(at: index - 1)?.copy() as? PDFPage { result.insert(page, at: result.pageCount) } }
        let out = folder.appendingPathComponent(input.lastPathComponent)
        guard result.write(to: out) else { throw WorkflowError.emptyResult }; return out
    }
    public static func redact(_ input: URL, terms: [String], into folder: URL) throws -> URL {
        let terms = terms.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        guard !terms.isEmpty else { throw WorkflowError.invalid("Escribe los textos que deseas retirar, separados por comas.") }
        let doc = try PDFs.open(input), result = PDFDocument()
        var matches = 0
        for index in 0..<doc.pageCount {
            try Task.checkCancellation()
            guard let page = doc.page(at: index), page.rotation % 360 == 0 else { throw WorkflowError.invalid("Gira las páginas a orientación normal antes de anonimizar.") }
            guard let image = PDFs.render(page, dpi: 150), let ctx = CGContext(data: nil, width: image.width, height: image.height, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { throw WorkflowError.emptyResult }
            ctx.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
            ctx.setFillColor(CGColor.black)
            let bounds = page.bounds(for: .mediaBox)
            var rectangles: [CGRect] = []
            let sx = CGFloat(image.width) / bounds.width
            let sy = CGFloat(image.height) / bounds.height
            for term in terms {
                let selections = doc.findString(term, withOptions: .caseInsensitive)
                for selection in selections where selection.pages.contains(page) {
                    for line in selection.selectionsByLine() {
                        let box = line.bounds(for: page)
                        let rect = CGRect(x: (box.minX - bounds.minX) * sx, y: (box.minY - bounds.minY) * sy, width: box.width * sx, height: box.height * sy)
                        rectangles.append(rect.insetBy(dx: -3, dy: -3))
                    }
                }
            }
            if (page.string ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                let request = VNRecognizeTextRequest(); request.recognitionLevel = .accurate
                try VNImageRequestHandler(cgImage: image).perform([request])
                rectangles += (request.results ?? []).filter { observation in
                    let text = observation.topCandidates(1).first?.string ?? ""
                    return terms.contains { text.localizedCaseInsensitiveContains($0) }
                }.map { CGRect(x: $0.boundingBox.minX * Double(image.width), y: $0.boundingBox.minY * Double(image.height), width: $0.boundingBox.width * Double(image.width), height: $0.boundingBox.height * Double(image.height)).insetBy(dx: -3, dy: -3) }
            }
            matches += rectangles.count
            rectangles.forEach { ctx.fill($0) }
            guard let redacted = ctx.makeImage(), let outPage = PDFPage(image: NSImage(cgImage: redacted, size: bounds.size)) else { throw WorkflowError.emptyResult }
            result.insert(outPage, at: result.pageCount)
        }
        guard matches > 0 else { throw WorkflowError.invalid("No se encontró el texto indicado. No se ha creado una copia anonimizada.") }
        result.documentAttributes = [:]
        let out = folder.appendingPathComponent(input.lastPathComponent)
        guard result.write(to: out) else { throw WorkflowError.emptyResult }; return out
    }
}
