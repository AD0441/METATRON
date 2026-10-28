import Foundation
import MetatronCore
import ImageIO
import PDFKit

public enum Simulation {
    @concurrent public static func inspect(inputs:[URL],recipe:Recipe) async throws ->[SimulationRow] {
        try Task.checkCancellation()
        return try plan(inputs:inputs,recipe:recipe)
    }

    public static func plan(inputs: [URL], recipe: Recipe) throws -> [SimulationRow] {
        guard !inputs.isEmpty, !recipe.steps.isEmpty else { throw WorkflowError.invalid("Añade archivos y al menos un paso.") }
        var reserved: Set<String> = []
        return try inputs.map { input in
            let stem = input.deletingPathExtension().lastPathComponent
            _ = try FileIntegrity.safeComponent(stem + recipe.suffix)
            var ext = input.pathExtension
            var warnings: [String] = []
            var facts:[String]=[]
            if FileManager.default.fileExists(atPath:input.path) {
                facts.append("Entrada: \(ByteCountFormatter.string(fromByteCount:FileIntegrity.bytes(input),countStyle:.file))")
            }
            var width:Int?,height:Int?
            if FileKind.of(input) == .image,let source=CGImageSourceCreateWithURL(input as CFURL,nil),let metadata=CGImageSourceCopyPropertiesAtIndex(source,0,nil) as? [CFString:Any] {
                width=(metadata[kCGImagePropertyPixelWidth] as? NSNumber)?.intValue
                height=(metadata[kCGImagePropertyPixelHeight] as? NSNumber)?.intValue
                if let width,let height {facts.append("Resolución: \(width) × \(height) px")}
                if CGImageSourceGetCount(source)>1 {warnings.append("El archivo tiene varias imágenes o fotogramas; un formato estático puede conservar solo uno.")}
                if (metadata[kCGImagePropertyHasAlpha] as? Bool) == true,recipe.steps.contains(where:{$0.action == "convert.jpg" || $0.action == "targetSize"}) {warnings.append("JPEG elimina la transparencia.")}
            }
            if FileKind.of(input) == .pdf,let pdf=PDFDocument(url:input) {facts.append("PDF: \(pdf.pageCount) páginas");if pdf.isLocked {warnings.append("El PDF está bloqueado; desbloquéalo antes de procesarlo.")}}

            for step in recipe.steps {
                if step.action.hasPrefix("convert.") { ext = String(step.action.dropFirst(8)) }
                if ["tool.extractText", "tool.extractPDFText", "tool.transcribeAudio"].contains(step.action) { ext = "txt" }
                if step.action == "tool.transcribeAudio" || (FileKind.of(input) == .audio && ["convert.txt", "convert.md"].contains(step.action)) {
                    warnings.append("Apple Speech local · macOS 26+ · requiere el idioma instalado. Revisa la transcripción automática.")
                }
                if step.action == "resize" {
                    ext = "png"
                    if let w=width,let h=height,step.number.isFinite,step.number>0 {
                        let scale=min(1,step.number/Double(max(w,h)))
                        width=max(1,Int(Double(w)*scale));height=max(1,Int(Double(h)*scale))
                    }
                }
                if step.action == "tool.stripMetadata" {warnings.append("Se retirarán los metadatos de la copia.")}
                if step.action == "documentAdvanced" {
                    ext=""
                    let engine=DocumentEngineID(rawValue:step.text) ?? .native
                    if engine != .native,DocumentProcessing.executable(engine,customPath:recipe.documentEnginePath) == nil {warnings.append("Requiere configurar \(engine.title).")}
                    warnings.append("Paquete Markdown con procedencia; revisa tablas, imágenes y orden de lectura.")
                }
                if step.action == "bundlePDF" {ext="pdf";warnings.append("Se combinarán \(inputs.count) entradas; los documentos editables pueden cambiar de diseño.")}

                if step.action == "targetSize" { ext = "jpg" }
                if step.action == "research" { ext = "" }
                if step.action == "pdfTables" { ext = "csv"; warnings.append("La estructura de las tablas requiere revisión.") }
                if FileKind.of(input) == .pdf, step.action.hasPrefix("convert."), ["docx", "rtf", "html", "epub"].contains(ext) {
                    warnings.append("La reconstrucción editable puede cambiar tablas, fuentes y posición. Conserva el original.")
                }
                if step.action == "redactPDF" { warnings.append("Se rasterizan las páginas redactadas: revisa la copia y la capa de texto antes de compartir.") }
                if step.action == "targetSize" { warnings.append("El límite se comprueba; el trabajo falla si no puede alcanzarse con calidad mínima.") }
                if ["normalizeAudio", "monoAudio"].contains(step.action), Engines.current.ffmpeg == nil { warnings.append("Requiere FFmpeg.") }
            }
            let directory = recipe.folderPath.map { URL(fileURLWithPath: $0, isDirectory: true) } ?? input.deletingLastPathComponent().appendingPathComponent("Metatron", isDirectory: true)
            var proposed = directory.appendingPathComponent(stem + recipe.suffix)
            if !ext.isEmpty { proposed.appendPathExtension(ext) }
            let output = FileIntegrity.unique(proposed, reserved: &reserved)
            if output != proposed { warnings.append("Se añadirá un número para evitar una colisión.") }
            warnings.append("La ruta es orientativa para pasos que generan varias páginas o recursos.")
            if let width,let height,recipe.steps.contains(where:{$0.action == "resize"}) {facts.append("Resolución prevista: \(width) × \(height) px")}
            if let target=recipe.steps.last(where:{$0.action == "targetSize"}) {facts.append("Límite comprobado: \(Int64(target.number.isFinite ? max(0,min(target.number,1_000_000))*1000 : 0)) bytes")}
            else {facts.append("Peso de salida: se conocerá tras convertir; depende del contenido y del formato.")}
            return SimulationRow(id: input, name: input.lastPathComponent, destination: output.path, warnings: warnings, facts:facts)
        }
    }
}
