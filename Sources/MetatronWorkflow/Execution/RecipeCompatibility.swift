import Foundation
import MetatronCore

/// Checks every step without opening or transforming the files. Projections keep
/// the original extension until a step actually changes it, including per-file
/// batches. All contextual presentations and the executor use this policy.
public enum RecipeCompatibility {
    public static func issue(inputs: [URL], recipe: Recipe, engines: Engines = .current) -> String? {
        do { try validate(inputs: inputs, recipe: recipe, engines: engines); return nil }
        catch { return error.localizedDescription }
    }
    public static func validate(inputs: [URL], recipe: Recipe, engines: Engines = .current) throws {
        guard !inputs.isEmpty, !recipe.steps.isEmpty else { throw WorkflowError.invalid("Añade archivos y al menos un paso.") }
        // Older saved built-ins predate explicit input restrictions. Infer only
        // unchanged named presets; custom recipes remain governed by their steps.
        if let allowed = inputKinds(for: recipe),
           !inputs.allSatisfy({ allowed.contains(FileKind.of($0)) }) {
            throw WorkflowError.invalid("«\(recipe.name)» no admite todos los archivos seleccionados. Esta receta requiere: " + allowed.map(kindName).sorted().joined(separator: ", ") + ".")
        }
        let groups = recipe.groupsInputs ? [inputs] : inputs.map { [$0] }
        for group in groups { try project(group, recipe: recipe, engines: engines) }
    }
    public static func inputKinds(for recipe: Recipe) -> Set<FileKind>? {
        recipe.inputKinds ?? Recipe.builtIns.first {
            $0.name == recipe.name && $0.steps.map(\.action) == recipe.steps.map(\.action)
        }?.inputKinds
    }
    public static func nextSteps(inputs: [URL], recipe: Recipe, engines: Engines = .current) -> [RecipeStep] {
        guard !inputs.isEmpty else { return RecipeStep.choices }
        return RecipeStep.choices.filter { step in
            var candidate = recipe
            candidate.steps.append(step)
            return issue(inputs: inputs, recipe: candidate, engines: engines) == nil
        }
    }
    private static func project(_ inputs: [URL], recipe: Recipe, engines: Engines) throws {
        var current = inputs
        for (index, step) in recipe.steps.enumerated() {
            let kinds = Set(current.map(FileKind.of))
            var allowed = false
            var outputExtension: String?
            var folder = false
            var collapse = false
            switch step.action {
            case "resize", "targetSize", "imageMarkup":
                allowed = ActionCatalog.supports(.tool(.resize), for: current, engines: engines)
                outputExtension = step.action == "targetSize" ? "jpg" : "png"
            case "research":
                allowed = current.allSatisfy { FileKind.of($0) == .pdf || (FileKind.of($0) == .image && ActionCatalog.supports(.convert(.md), for: [$0], engines: engines)) || ["txt", "text", "md", "markdown", "log", "xml", "yaml", "yml", "html", "htm", "csv", "tsv", "json"].contains($0.pathExtension.lowercased()) }
                folder = true
            case "documentAdvanced":
                let engine = DocumentEngineID(rawValue: step.text.isEmpty ? "native" : step.text)
                let native: Set<FileKind> = [.pdf, .image, .document, .data, .subtitle]
                if engine == .native { allowed = kinds.isSubset(of: native) && current.allSatisfy { ActionCatalog.supports(.convert(.md), for: [$0], engines: engines) } }
                else if let engine, DocumentProcessing.executable(engine, customPath: recipe.documentEnginePath) != nil {
                    allowed = kinds.isSubset(of: native.union([.office]))
                }
                folder = true
            case "bundlePDF":
                allowed = current.allSatisfy { FileKind.of($0) == .pdf || ActionCatalog.supports(.convert(.pdf), for: [$0], engines: engines) }
                outputExtension = "pdf"; collapse = true
            case "pdfTables", "reorderPDF", "redactPDF":
                allowed = kinds == [.pdf]
                outputExtension = step.action == "pdfTables" ? "csv" : "pdf"
            case "trimVideo", "joinVideo":
                allowed = kinds == [.video] && current.allSatisfy(FileKind.isNativeMedia)
                if step.action == "joinVideo" { allowed = allowed && current.count > 1; collapse = true }
                outputExtension = "mp4"
            case "normalizeAudio", "monoAudio":
                allowed = kinds.isSubset(of: [.audio, .video]) && engines.ffmpeg != nil
                outputExtension = "m4a"
            default:
                guard let action = KQAction(id: step.action) else { throw WorkflowError.unsupportedStep(step.action) }
                allowed = ActionCatalog.supports(action, for: current, engines: engines)
                switch action {
                case .convert(let format): outputExtension = format.fileExtension
                case .tool(let tool):
                    switch tool {
                    case .zip: outputExtension = "zip"; collapse = true
                    case .merge: outputExtension = "pdf"; collapse = true
                    case .extract, .frames: folder = true
                    case .extractText, .extractPDFText, .transcribeAudio: outputExtension = "txt"
                    case .compressPDF, .rotatePDF, .protect, .split: outputExtension = "pdf"
                    case .longImage, .removeBackground, .addBackground: outputExtension = "png"
                    case .compressVideo: outputExtension = "mp4"
                    case .mute:
                        current = current.map { url in
                            FileKind.isNativeMedia(url) ? projected(url, ext: url.pathExtension.lowercased() == "mov" ? "mov" : "mp4") : url
                        }
                    case .compress:
                        current = current.map { url in
                            ["jpg", "jpeg", "heic", "avif"].contains(url.pathExtension.lowercased()) ? url : projected(url, ext: "jpg")
                        }
                    case .resize, .crop, .rotate, .flip, .grayscale:
                        current = current.map { url in
                            OutputFormat.writableImageFormats.contains { $0.matches(url) } ? url : projected(url, ext: "png")
                        }
                    case .stripMetadata: break
                    }
                }
            }
            guard allowed else {
                let formats = Set(current.map { $0.pathExtension.isEmpty ? kindName(FileKind.of($0)) : $0.pathExtension.uppercased() }).sorted().joined(separator: ", ")
                throw WorkflowError.invalid("Paso \(index + 1) · \(step.title): no es compatible con \(formats) o falta el motor necesario.")
            }
            if folder { current = current.enumerated().map { URL(fileURLWithPath: "/metatron-projection/output-\($0.offset)/", isDirectory: true) } }
            else if let outputExtension { current = current.map { projected($0, ext: outputExtension) } }
            if collapse { current = Array(current.prefix(1)) }
        }
    }
    private static func projected(_ source: URL, ext: String) -> URL {
        URL(fileURLWithPath: "/metatron-projection/" + source.deletingPathExtension().lastPathComponent).appendingPathExtension(ext)
    }
    private static func kindName(_ kind: FileKind) -> String {
        switch kind {
        case .image: "imágenes"
        case .pdf: "PDF"
        case .document: "textos y documentos"
        case .data: "tablas y datos"
        case .ebook: "EPUB"
        case .subtitle: "subtítulos"
        case .office: "documentos Office"
        case .video: "vídeos"
        case .audio: "audios"
        case .archive: "archivos comprimidos"
        case .folder: "carpetas"
        case .other: "otros archivos"
        }
    }
}
