import Foundation
import PDFKit
import MetatronCore

public enum DocumentEngineID:String,Codable,CaseIterable,Sendable {
    case native,markitdown,docling
    public var title:String {switch self {case .native:"Nativo (Vision/PDFKit)";case .markitdown:"MarkItDown";case .docling:"Docling"}}
}
public enum DocumentProcessing {
    public static func executable(_ engine:DocumentEngineID,customPath:String?=nil)->URL? {
        guard engine != .native else{return nil}
        let executable=engine.rawValue
        let env=ProcessInfo.processInfo.environment["METATRON_"+engine.rawValue.uppercased()+"_PATH"]
        let project=Bundle.main.bundleURL.deletingLastPathComponent().deletingLastPathComponent()
        let candidates:[String?]=[customPath,env,
            project.appendingPathComponent(".engines/\(executable)/bin/\(executable)").path,
            URL(fileURLWithPath:FileManager.default.currentDirectoryPath).appendingPathComponent(".engines/\(executable)/bin/\(executable)").path,
            URL.applicationSupportDirectory.appendingPathComponent("METATRON/Engines/\(executable)/bin/\(executable)").path,
            "/opt/homebrew/bin/"+executable,"/usr/local/bin/"+executable,NSHomeDirectory()+"/.local/bin/"+executable]
        return candidates.compactMap{$0}.first { FileManager.default.isExecutableFile(atPath:$0) }.map { URL(fileURLWithPath:$0) }
    }
    @concurrent public static func structured(_ input:URL,engine:DocumentEngineID,customPath:String?=nil,into folder:URL) async throws ->URL {
        try Task.checkCancellation()
        guard FileIntegrity.bytes(input) <= 50_000_000 else {throw WorkflowError.invalid("El modo documental eficiente admite hasta 50 MB por archivo. Divide el documento antes de procesarlo.")}
        if FileKind.of(input) == .pdf {
            let pdf=try PDFs.open(input)
            guard !pdf.isLocked,pdf.pageCount <= 40 else {throw WorkflowError.invalid("El modo documental eficiente admite PDF desbloqueados de hasta 40 páginas. Divide el PDF para continuar.")}
        }
        try FileManager.default.createDirectory(at:folder,withIntermediateDirectories:true)
        var warnings:[String]=[]
        var method=engine.title
        if engine == .native {
            try await native(input,into:folder)
            warnings.append("Estructura básica por páginas; las tablas y el orden de lectura requieren revisión.")
        } else {
            guard let tool=executable(engine,customPath:customPath) else {throw WorkflowError.invalid("\(engine.title) no está configurado. Elige Nativo o configura el motor opcional en Ajustes → Documentos.")}
            let args:[String]
            if engine == .markitdown {args=[input.path,"-o",folder.appendingPathComponent("documento.md").path]}
            else {args=["--to","md","--to","json","--image-export-mode","referenced","--num-threads","2","--device","cpu","--output",folder.path,input.path]}
            _ = try await Engines.run(tool,args,timeout:180,environment:["HF_HUB_OFFLINE":"1","TRANSFORMERS_OFFLINE":"1","OMP_NUM_THREADS":"2","MKL_NUM_THREADS":"2","DOCLING_ENABLE_REMOTE_SERVICES":"false"])
            try Task.checkCancellation()
            let outputs=try FileManager.default.contentsOfDirectory(at:folder,includingPropertiesForKeys:nil)
            guard let markdown=outputs.first(where:{$0.pathExtension == "md"}) else {throw WorkflowError.emptyResult}
            let text=try String(contentsOf:markdown,encoding:.utf8)
            if text.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty {
                try await native(input,into:folder);method += " + extracción nativa/OCR";warnings.append("El motor no encontró texto; se utilizó extracción nativa.")
            }
            warnings.append("Revisa tablas, imágenes y orden de lectura. El motor opcional se ejecuta localmente y sin descarga automática de modelos.")
        }
        let files=try FileManager.default.contentsOfDirectory(at:folder,includingPropertiesForKeys:nil)
        guard files.contains(where:{$0.pathExtension == "md"}) else {throw WorkflowError.emptyResult}
        let record:[String:Any]=["schemaVersion":1,"source":input.lastPathComponent,"engine":method,"warnings":warnings,"files":files.map(\.lastPathComponent),"processedLocally":true]
        try JSONSerialization.data(withJSONObject:record,options:[.prettyPrinted,.sortedKeys]).write(to:folder.appendingPathComponent("procedencia.json"))
        return folder
    }
    private static func native(_ input:URL,into folder:URL) async throws {
        switch FileKind.of(input) {
        case .pdf,.image:
            _=try PDFWorkbench.research(input,into:folder)
            if FileKind.of(input) == .pdf {_ = try PDFEmbeddedImages.extract(input,into:folder.appendingPathComponent("imagenes-originales",isDirectory:true))}
        default:
            let output=folder.appendingPathComponent("documento.md")
            try await MarkdownExport.convert(input,to:output)
        }
    }
    @concurrent public static func combinePDF(_ inputs:[URL],into folder:URL) async throws ->URL {
        guard !inputs.isEmpty else {throw WorkflowError.emptyResult}
        let kinds:Set<FileKind>=[.image,.pdf,.document,.ebook,.data,.office]
        guard inputs.allSatisfy({kinds.contains(FileKind.of($0))}) else {throw WorkflowError.invalid("Combina imágenes, PDF, documentos y tablas. Audio, vídeo y archivos comprimidos requieren otro flujo.")}
        let staging=folder.appendingPathComponent("pages",isDirectory:true)
        try FileManager.default.createDirectory(at:staging,withIntermediateDirectories:true)
        defer {try? FileManager.default.removeItem(at:staging)}
        var pdfs:[URL]=[]
        for (index,input) in inputs.enumerated() {
            try Task.checkCancellation()
            if FileKind.of(input) == .pdf {pdfs.append(input);continue}
            let part=staging.appendingPathComponent(String(index),isDirectory:true)
            try FileManager.default.createDirectory(at:part,withIntermediateDirectories:true)
            let result=try await Engine(planner:OutputPlanner(location:.folder(part))).run(.convert(.pdf),on:[input])
            pdfs.append(contentsOf:result.outputs)
        }
        let output=folder.appendingPathComponent("documentos.pdf")
        try PDFs.merge(pdfs,into:output)
        return output
    }
}
