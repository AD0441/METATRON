import Foundation
import MetatronCore

public enum Simulation {
    public static func plan(inputs: [URL], recipe: Recipe) throws -> [SimulationRow] {
        guard !inputs.isEmpty, !recipe.steps.isEmpty else { throw WorkflowError.invalid("Añade archivos y al menos un paso.") }
        var reserved: Set<String> = []
        return try inputs.map { input in
            let stem = input.deletingPathExtension().lastPathComponent
            _ = try FileIntegrity.safeComponent(stem + recipe.suffix)
            var ext = input.pathExtension
            var warnings: [String] = []
            for step in recipe.steps {
                if step.action.hasPrefix("convert.") { ext = String(step.action.dropFirst(8)) }
                if ["tool.extractText", "tool.extractPDFText"].contains(step.action) { ext = "txt" }
                if step.action == "resize" { ext = "png" }
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
            return SimulationRow(id: input, name: input.lastPathComponent, destination: output.path, warnings: warnings)
        }
    }
}
