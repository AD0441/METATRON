import Foundation
import ImageIO
import MetatronCore

public struct RecipeResult: Sendable {
    public let files: [PublishedFile]
    public let inputBytes:Int64
    public let elapsed: Double
    public let warnings: [String]
}
public enum RecipeExecutor {
    /// Image decoding, hashing and conversion are bounded to one job; they must not block the UI actor.
    @concurrent public static func execute(inputs: [URL], recipe: Recipe, id: UUID = UUID(), parameters: ToolParameters = .none, progress: @escaping @Sendable (String) async -> Void = { _ in }) async throws -> RecipeResult {
        guard !inputs.isEmpty, !recipe.steps.isEmpty else { throw WorkflowError.invalid("Añade archivos y pasos.") }
        guard recipe.quality.isFinite, (0...1).contains(recipe.quality) else { throw WorkflowError.invalid("La calidad debe estar entre 0 y 1.") }
        try Task.checkCancellation()
        let start = Date()
        let sourceBytes=inputs.reduce(Int64(0)) {$0+FileIntegrity.bytes($1)}
        let fm = FileManager.default
        let staging = fm.temporaryDirectory.appendingPathComponent("metatron-job-" + id.uuidString, isDirectory: true)
        try fm.createDirectory(at: staging, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: staging) }
        var current = inputs
        var options = recipe.conversionOptions ?? ConversionOptions()
        options.imageQuality = recipe.quality
        options.keepMetadata = recipe.preserveMetadata
        var warnings: [String] = []
        for (index, step) in recipe.steps.enumerated() {
            try Task.checkCancellation()
            await progress("\(index + 1)/\(recipe.steps.count) · \(step.title)")
            let folder = staging.appendingPathComponent("step-\(index)", isDirectory: true)
            try fm.createDirectory(at: folder, withIntermediateDirectories: true)
            if step.action == "documentAdvanced" {
                let engine=DocumentEngineID(rawValue:step.text) ?? .native
                var structured:[URL]=[]
                for (part,input) in current.enumerated() {
                    let destination=folder.appendingPathComponent("documento-\(part+1)",isDirectory:true)
                    structured.append(try await DocumentProcessing.structured(input,engine:engine,customPath:recipe.documentEnginePath,into:destination))
                }
                current=structured
                warnings.append("Revisa la estructura documental y consulta procedencia.json en la salida.")
            } else if step.action == "bundlePDF" {
                current=[try await DocumentProcessing.combinePDF(current,into:folder)]
                warnings.append("Los documentos editables pueden cambiar de diseño al convertirse a PDF; verifica la combinación.")
            } else if step.action == "imageMarkup" {
                let strokes = try JSONDecoder().decode([MarkStroke].self, from: Data(step.text.utf8))
                current = try current.map { source in
                    let image = try ImageMarkup.render(Images.load(source).image, strokes: strokes)
                    let out = OutputPlanner.unique(folder.appendingPathComponent(source.deletingPathExtension().lastPathComponent + ".png"))
                    try Images.write(image, to: out, format: .png, quality: 1)
                    return out
                }
            } else if step.action == "resize" {
                guard step.number.isFinite, step.number >= 1, step.number <= 32768 else { throw WorkflowError.invalid("Tamaño de imagen fuera del rango 1…32768.") }
                current = try current.map { url in
                    let loaded = try Images.load(url)
                    let image = loaded.image
                    let resized = try MetalImages.resize(image, longestEdge: Int(step.number))
                    let out = OutputPlanner.unique(folder.appendingPathComponent(url.deletingPathExtension().lastPathComponent + ".png"))
                    try Images.write(resized, to: out, format: .png, quality: 1, properties: options.keepMetadata ? loaded.properties : nil)
                    return out
                }
            } else if step.action == "targetSize" {
                current = try current.map { try fitSize($0, kilobytes: step.number, directory: folder) }
            } else if step.action == "research" {
                current = try current.map { try PDFWorkbench.research($0, into: folder.appendingPathComponent($0.deletingPathExtension().lastPathComponent, isDirectory: true)) }
                warnings.append("La estructura se organiza por páginas; tablas y fórmulas necesitan revisión.")
            } else if step.action == "pdfTables" {
                current = try current.map { try PDFWorkbench.tableRows($0, into: folder) }
                warnings.append("Filas obtenidas mediante OCR; revisa alineación, encabezados y separadores decimales.")
            } else if step.action == "reorderPDF" {
                current = try current.map { try PDFWorkbench.reorder($0, pages: step.text, into: folder) }
            } else if step.action == "redactPDF" {
                current = try current.map { try PDFWorkbench.redact($0, terms: step.text.components(separatedBy: ","), into: folder) }
                warnings.append("Copia rasterizada sin capa de texto; comprueba visualmente todos los datos retirados.")
            } else if ["trimVideo", "joinVideo", "normalizeAudio", "monoAudio"].contains(step.action) {
                current = try await ExtendedMedia.run(step.action, inputs: current, value: step.number, text: step.text, directory: folder)
            } else {
                guard let action = KQAction(id: step.action) else { throw WorkflowError.unsupportedStep(step.action) }
                if step.action == "tool.transcribeAudio", !step.text.isEmpty { options.speechLocale = step.text }
                let engine = Engine(options: options, planner: OutputPlanner(location: .folder(folder)), speechProgress: progress)
                let result = try await engine.run(action, on: current, parameters: index == 0 ? parameters : .none)
                current = result.outputs
                if step.action == "tool.transcribeAudio" || (inputs.contains { FileKind.of($0) == .audio } && ["convert.txt", "convert.md"].contains(step.action)) {
                    warnings.append("Transcripción automática local de Apple. Revisa nombres, cifras y puntuación.")
                }
            }
            guard !current.isEmpty else { throw WorkflowError.emptyResult }
        }
        try Task.checkCancellation()
        let password: String? = { if case .password(let value) = parameters { value } else { nil } }()
        for output in current { try FileIntegrity.validate(output, password: password) }
        await progress("Verificando y publicando")
        let destination = recipe.folderPath.map { URL(fileURLWithPath: $0, isDirectory: true) } ?? inputs[0].deletingLastPathComponent().appendingPathComponent("Metatron", isDirectory: true)
        try fm.createDirectory(at: destination, withIntermediateDirectories: true)
        var published: [PublishedFile] = []
        do {
            for (index, output) in current.enumerated() {
                try Task.checkCancellation()
                let stem = inputs.count == 1 ? inputs[0].deletingPathExtension().lastPathComponent : output.deletingPathExtension().lastPathComponent
                let name = try FileIntegrity.safeComponent(stem + recipe.suffix + (current.count > 1 ? "-\(index + 1)" : ""))
                var proposed = destination.appendingPathComponent(name, isDirectory: output.hasDirectoryPath)
                if !output.hasDirectoryPath && !output.pathExtension.isEmpty { proposed.appendPathExtension(output.pathExtension) }
                let hash = try FileIntegrity.digest(output)
                var reserved: Set<String> = []
                var target = FileIntegrity.unique(proposed, reserved: &reserved)
                // moveItem refuses to replace a file created after planning. Re-plan on that race.
                while true {
                    do { try fm.moveItem(at: output, to: target); break }
                    catch where fm.fileExists(atPath: target.path) { target = FileIntegrity.unique(proposed, reserved: &reserved) }
                }
                published.append(PublishedFile(url: target, digest: hash, bytes: FileIntegrity.bytes(target)))
            }
            try Task.checkCancellation()
            let receiptName = "metatron-\(id.uuidString).json"
            let stagedReceipt = staging.appendingPathComponent(receiptName)
            let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            try encoder.encode(published).write(to: stagedReceipt, options: .atomic)
            let receiptHash = try FileIntegrity.digest(stagedReceipt)
            let receiptBytes = FileIntegrity.bytes(stagedReceipt)
            var reserved: Set<String> = []
            let proposed = destination.appendingPathComponent(receiptName)
            var receipt = FileIntegrity.unique(proposed, reserved: &reserved)
            while true {
                try Task.checkCancellation()
                do { try fm.moveItem(at: stagedReceipt, to: receipt); break }
                catch where fm.fileExists(atPath: receipt.path) { receipt = FileIntegrity.unique(proposed, reserved: &reserved) }
            }
            // The receipt is the commit point; cancellation after this returns a
            // completed transaction, never a half-published success.
            published.append(PublishedFile(url: receipt, digest: receiptHash, bytes: receiptBytes))
            return RecipeResult(files: published, inputBytes:sourceBytes, elapsed: Date().timeIntervalSince(start), warnings: warnings)
        } catch {
            // Only outputs just created by this transaction are removed on a publication failure.
            for item in published { try? fm.removeItem(at: item.url) }
            throw error
        }
    }
    private static func fitSize(_ source: URL, kilobytes: Double, directory: URL) throws -> URL {
        guard kilobytes.isFinite, kilobytes >= 1, kilobytes <= 1_000_000 else { throw WorkflowError.invalid("El límite de tamaño no es válido.") }
        let target = directory.appendingPathComponent(source.deletingPathExtension().lastPathComponent + ".jpg")
        let original = try Images.load(source).image
        var image = original
        let limit = Int64(kilobytes * 1000)
        for _ in 0..<5 {
            for quality in [0.9, 0.75, 0.6, 0.45, 0.3] {
                try Task.checkCancellation()
                try Images.write(image, to: target, format: .jpg, quality: quality)
                if FileIntegrity.bytes(target) <= limit { return target }
            }
            image = try MetalImages.resize(image, longestEdge: max(64, Int(Double(max(image.width, image.height)) * 0.75)))
        }
        throw WorkflowError.invalid("No se alcanzó el límite. Aumenta los KB o reduce las dimensiones.")
    }
    @concurrent public static func undo(_ files: [PublishedFile], directory: URL) async throws {
        let fm = FileManager.default
        for item in files {
            guard fm.fileExists(atPath: item.url.path), try FileIntegrity.digest(item.url) == item.digest else { throw WorkflowError.changedOutput(item.url.lastPathComponent) }
        }
        try fm.createDirectory(at: directory, withIntermediateDirectories: true)
        var moved: [(URL, URL)] = []
        do {
            for item in files {
                let target = directory.appendingPathComponent(item.url.lastPathComponent)
                try fm.moveItem(at: item.url, to: target)
                moved.append((item.url, target))
            }
        } catch {
            for (original, backup) in moved.reversed() { try? fm.moveItem(at: backup, to: original) }
            throw error
        }
    }
}
