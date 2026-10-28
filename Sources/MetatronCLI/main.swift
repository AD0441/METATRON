import Foundation
import CoreGraphics
import FoundationModels
import MetatronCore
import MetatronWorkflow

@main struct MetatronCommand {
    static func main() async {
        let args = Array(CommandLine.arguments.dropFirst())
        do {
            guard let command = args.first, command != "help" else { help(); return }
            func option(_ flag: String) -> String? { args.firstIndex(of: flag).flatMap { $0 + 1 < args.count ? args[$0 + 1] : nil } }
            if command == "engines" {
                let engines = Engines.current
                print("Metal: \(HardwareProfile.current().deviceName)\nFFmpeg: \(engines.ffmpeg?.path ?? "no instalado")\nLibreOffice: \(engines.soffice?.path ?? "no instalado")\nGhostscript: \(engines.ghostscript?.path ?? "no instalado")\nWebP: \(engines.cwebp?.path ?? "no instalado")")
                return
            }
            if command == "run" || command == "goal" || command == "document" {
                let flags:Set<String>=["--recipe","--goal","--engine","--engine-path","-o"]
                var paths:[URL]=[];var index=1
                while index<args.count {
                    if flags.contains(args[index]) {index += 2;continue}
                    if args[index] == "--json" {index += 1;continue}
                    paths.append(URL(fileURLWithPath:args[index]));index += 1
                }
                var recipe:Recipe
                if command == "run" {
                    guard let file=option("--recipe") else {throw WorkflowError.invalid("Usa --recipe receta.metatron.json")}
                    recipe=try JSONDecoder().decode(Recipe.self,from:Data(contentsOf:URL(fileURLWithPath:file)))
                } else if command == "document" {
                    guard let engine=DocumentEngineID(rawValue:option("--engine") ?? "native") else {throw WorkflowError.invalid("Motor desconocido. Usa native, markitdown o docling.")}
                    recipe=Recipe(name:"Documento para análisis",steps:[.init(action:"documentAdvanced",text:engine.rawValue)])
                } else {
                    guard ["web","analysis"].contains(option("--goal") ?? "") else {throw WorkflowError.invalid("Elige --goal web o --goal analysis.")}
                    let name=option("--goal") == "web" ? "Preparar para la web" : "Documento para análisis"
                    guard let preset=Recipe.builtIns.first(where:{$0.name == name}) else {throw WorkflowError.emptyResult}
                    recipe=preset
                }
                guard !paths.isEmpty else {throw WorkflowError.invalid("Añade uno o más archivos.")}
                if let output=option("-o") {recipe.folderPath=output}
                recipe.documentEnginePath=option("--engine-path") ?? recipe.documentEnginePath
                let result=try await RecipeExecutor.execute(inputs:paths,recipe:recipe)
                if args.contains("--json") {
                    let data=try JSONEncoder().encode(result.files);print(String(decoding:data,as:UTF8.self))
                } else {result.files.forEach {print($0.url.path)}}
                return
            }
            if command == "assist" {
                guard #available(macOS 26, *), SystemLanguageModel.default.availability == .available else { throw WorkflowError.invalid("El modelo local de Apple no está disponible.") }
                let prompt = args.dropFirst().joined(separator: " ")
                let session = LanguageModelSession(instructions: "Responde en español. Sugiere pasos breves de conversión de archivos. No ejecutes acciones ni comandos.")
                print(try await session.respond(to: String(prompt.prefix(6000)), options: GenerationOptions(maximumResponseTokens: 180)).content)
                return
            }
            if command == "benchmark" {
                let result = try await ImageBenchmark.run()
                let profile = HardwareProfile.current()
                let json: [String: Any] = ["device": profile.deviceName, "unifiedMemory": profile.unifiedMemory, "cpuMilliseconds": result.cpuSeconds * 1000, "metalMilliseconds": result.metalSeconds * 1000, "inputWidth": result.width, "inputHeight": result.height, "repetitions": 3]
                print(String(decoding: try JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted,.sortedKeys]), as: UTF8.self)); return
            }
            guard args.count > 1 else { help(); throw WorkflowError.invalid("Falta el archivo o carpeta de entrada.") }
            if command == "make-fixture" { try makeFixture(URL(fileURLWithPath: args[1], isDirectory: true)); return }
            if command == "formats" {
                let actions = ActionCatalog.convertActions(for: [URL(fileURLWithPath: args[1])]) + ActionCatalog.toolActions(for: [URL(fileURLWithPath: args[1])])
                actions.forEach { print($0.id) }; return
            }
            let sourceIndex = command == "tool" ? 2 : 1
            guard args.count > sourceIndex else { throw WorkflowError.invalid("Falta el archivo de entrada.") }
            let input = URL(fileURLWithPath: args[sourceIndex])
            let format = option("--to") ?? "jpg"
            let action: String
            switch command {
            case "research": action = "research"
            case "ocr": action = FileKind.of(input) == .pdf ? "tool.extractPDFText" : "tool.extractText"
            case "tool": action = args[1] == "resize" ? "resize" : "tool." + args[1]
            case "convert", "simulate", "watch": action = "convert." + format
            default: throw WorkflowError.invalid("Comando desconocido: \(command)")
            }
            let recipe = Recipe(name: "CLI", steps: [.init(action: action, number: Double(option("--size") ?? "1920") ?? 1920)], quality: Double(option("--quality") ?? "0.85") ?? 0.85, folderPath: option("-o"))
            if command == "simulate" { for row in try Simulation.plan(inputs: [input], recipe: recipe) { print(row.destination); row.warnings.forEach { print("· " + $0) } }; return }
            if command == "watch" {
                let (stream, continuation) = AsyncStream<URL>.makeStream()
                let watcher = FolderWatcher(folder: input) { continuation.yield($0) }
                watcher.start(); defer { watcher.stop(); continuation.finish() }
                print("Vigilando \(input.path). Ctrl+C para terminar.")
                for await file in stream where FileKind.of(file) != .folder {
                    do { let result = try await RecipeExecutor.execute(inputs: [file], recipe: recipe); result.files.forEach { print($0.url.path) } }
                    catch { FileHandle.standardError.write(Data((error.localizedDescription + "\n").utf8)) }
                }
                return
            }
            let result = try await RecipeExecutor.execute(inputs: [input], recipe: recipe)
            result.files.forEach { print($0.url.path) }
        } catch { FileHandle.standardError.write(Data((error.localizedDescription + "\n").utf8)); exit(1) }
    }
    private static func help() {
        print("""
        Metatron · archivos locales, originales conservados
        convert <archivo> --to jpg [-o carpeta] [--quality 0.85]
        tool compress|resize|stripMetadata|extractText|zip <archivo> [--size 1920]
        ocr <archivo> | research <pdf> | simulate <archivo> --to png
        formats <archivo> | engines | watch <carpeta> --to jpg
        run <archivos…> --recipe receta.metatron.json [-o carpeta] [--json]
        goal <archivos…> --goal web|analysis [-o carpeta]
        document <archivo> --engine native|markitdown|docling [--engine-path ejecutable] [-o carpeta]
        benchmark | assist <pregunta>
        """)
    }
    private static func makeFixture(_ folder: URL) throws {
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        guard let ctx = CGContext(data: nil, width: 1600, height: 1200, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { throw WorkflowError.emptyResult }
        ctx.setFillColor(CGColor(srgbRed: 0.98, green: 0.6, blue: 0.12, alpha: 1)); ctx.fill(CGRect(x: 0,y: 0,width: 1600,height: 1200))
        ctx.setFillColor(.black); ctx.fillEllipse(in: CGRect(x: 300,y: 300,width: 600,height: 600))
        guard let image = ctx.makeImage() else { throw WorkflowError.emptyResult }
        try Images.write(image, to: folder.appendingPathComponent("Prueba-Metatron.png"), format: .png, quality: 1)
        print(folder.path)
    }
}
