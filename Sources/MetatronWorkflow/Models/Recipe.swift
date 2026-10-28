import Foundation
import MetatronCore

public struct RecipeStep: Codable, Hashable, Identifiable, Sendable {
    public var id: UUID
    public var action: String
    public var number: Double
    public var text: String
    public init(action: String, number: Double = 1920, text: String = "") {
        id = UUID(); self.action = action; self.number = number; self.text = text
    }
    public var title: String {
        switch action {
        case "convert.md": return "Convertir a Markdown"
        case "imageMarkup": return "Anotar imagen"
        case "resize": return "Redimensionar · \(number.formatted(.number.precision(.fractionLength(0)))) px"
        case "targetSize": return "Limitar tamaño · \(number.formatted(.number.precision(.fractionLength(0)))) KB"
        case "research": return "Paquete de investigación"
        case "pdfTables": return "Extraer tablas a CSV"
        case "reorderPDF": return "Organizar páginas PDF"
        case "redactPDF": return "Anonimizar texto en PDF"
        case "trimVideo": return "Recortar vídeo"
        case "normalizeAudio": return "Normalizar audio"
        case "monoAudio": return "Audio mono"
        case "joinVideo": return "Unir vídeos"
        default:
            if action.hasPrefix("convert.") { return "Convertir a " + action.dropFirst(8).uppercased() }
            let names = ["compress":"Comprimir imagen", "stripMetadata":"Quitar metadatos", "removeBackground":"Quitar fondo con Vision", "extractText":"Reconocer texto (OCR)", "extractPDFText":"Extraer texto del PDF", "grayscale":"Blanco y negro", "merge":"Unir PDF", "split":"Separar páginas", "zip":"Crear ZIP", "extract":"Extraer archivo", "compressPDF":"Comprimir PDF", "compressVideo":"Comprimir vídeo", "mute":"Silenciar vídeo", "rotate":"Girar imagen", "rotatePDF":"Girar PDF", "flip":"Reflejar imagen", "frames":"Extraer fotogramas"]
            return names[action.replacingOccurrences(of: "tool.", with: "")] ?? action
        }
    }
    public static let choices: [RecipeStep] = ["convert.jpg","convert.png","convert.webp","convert.heic","convert.pdf","convert.docx","convert.txt","convert.md","convert.html","convert.epub","convert.xlsx","convert.csv","convert.json","convert.mp4","convert.mp3","convert.wav","convert.m4a","resize","targetSize","tool.compress","tool.stripMetadata","tool.removeBackground","tool.grayscale","tool.extractText","tool.extractPDFText","tool.merge","tool.split","tool.compressPDF","tool.compressVideo","tool.mute","tool.rotate","tool.rotatePDF","tool.flip","tool.zip","tool.extract","tool.frames","research","pdfTables","reorderPDF","redactPDF","trimVideo","normalizeAudio","monoAudio","joinVideo"].map { RecipeStep(action: $0, number: $0 == "targetSize" ? 500 : 1920) }
}

public struct Recipe: Codable, Hashable, Identifiable, Sendable {
    public var id: UUID
    public var name: String
    public var steps: [RecipeStep]
    public var suffix: String
    public var quality: Double
    public var preserveMetadata: Bool
    public var folderPath: String?
    public var conversionOptions: ConversionOptions? = nil
    public init(name: String, steps: [RecipeStep], suffix: String = "-metatron", quality: Double = 0.85, preserveMetadata: Bool = true, folderPath: String? = nil) {
        id = UUID(); self.name = name; self.steps = steps; self.suffix = suffix
        self.quality = quality; self.preserveMetadata = preserveMetadata; self.folderPath = folderPath
    }
    public static let builtIns = [
        Recipe(name: "Imágenes para entrega", steps: [.init(action: "resize"), .init(action: "convert.jpg"), .init(action: "tool.stripMetadata"), .init(action: "targetSize", number: 500)], preserveMetadata: false),
        Recipe(name: "Documento a Markdown", steps: [.init(action: "convert.md")]),
        Recipe(name: "PDF a texto editable", steps: [.init(action: "tool.extractPDFText")]),
        Recipe(name: "Paquete de investigación", steps: [.init(action: "research")]),
        Recipe(name: "Compartir vídeo", steps: [.init(action: "convert.mp4"), .init(action: "tool.compressVideo")]),
        Recipe(name: "Tabla para Excel", steps: [.init(action: "convert.xlsx")]),
        Recipe(name: "Copia de archivo ZIP", steps: [.init(action: "tool.zip")])
    ]
    public var groupsInputs: Bool { steps.first.map { ["tool.merge", "tool.zip", "joinVideo"].contains($0.action) } ?? false }
}

public enum JobState: String, Codable, Sendable { case queued, running, completed, failed, cancelled, interrupted, undone }
public struct PublishedFile: Codable, Hashable, Sendable {
    public var url: URL
    public var digest: String
    public var bytes: Int64
}
public struct WorkJob: Codable, Identifiable, Sendable {
    public var id: UUID
    public var inputs: [URL]
    public var recipe: Recipe
    public var created: Date
    public var state: JobState
    public var outputs: [PublishedFile]
    public var message: String
    public var duration: Double
    public init(inputs: [URL], recipe: Recipe) {
        id = UUID(); self.inputs = inputs; self.recipe = recipe; created = Date()
        state = .queued; outputs = []; message = "En espera"; duration = 0
    }
}
public struct SimulationRow: Identifiable, Sendable {
    public let id: URL
    public let name: String
    public let destination: String
    public let warnings: [String]
}
public enum WorkflowError: LocalizedError, Equatable {
    case invalid(String), changedOutput(String), emptyResult, unsupportedStep(String)
    public var errorDescription: String? {
        switch self {
        case .invalid(let s): s
        case .changedOutput(let s): "La salida cambió después de crearla: \(s). Se conserva."
        case .emptyResult: "El motor no produjo un resultado válido."
        case .unsupportedStep(let s): "Paso no compatible: \(s)"
        }
    }
}
