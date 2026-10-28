import AppIntents
import UniformTypeIdentifiers
import MetatronWorkflow

nonisolated enum PreparationGoal:String,AppEnum {
    case web,analysis,combinedPDF
    static let typeDisplayRepresentation:TypeDisplayRepresentation="Objetivo"
    static let caseDisplayRepresentations:[Self:DisplayRepresentation]=[.web:"Preparar para la web",.analysis:"Documento para análisis",.combinedPDF:"Combinar en un PDF"]
    var recipeName:String {switch self {case .web:"Preparar para la web";case .analysis:"Documento para análisis";case .combinedPDF:"Combinar documentos en un PDF"}}
}
@available(macOS 15, *)
struct PrepareFilesIntent:AppIntent {
    static let title:LocalizedStringResource="Preparar archivos con METATRON"
    static let description=IntentDescription("Aplica un flujo local, conserva los originales y devuelve salidas verificadas.")
    static let openAppWhenRun=false
    @Parameter(title:"Archivos",supportedContentTypes:[.item],inputConnectionBehavior:.connectToPreviousIntentResult)
    var files:[IntentFile]
    @Parameter(title:"Objetivo",default:.web) var goal:PreparationGoal
    @MainActor func perform() async throws ->some IntentResult & ReturnsValue<[IntentFile]> {
        guard let recipe=Recipe.builtIns.first(where:{$0.name == goal.recipeName}) else {throw WorkflowError.emptyResult}
        return .result(value:try await IntentFileWorkflow.run(files:files,recipe:recipe))
    }
}
@available(macOS 15, *)
struct RunRecipeIntent:AppIntent {
    static let title:LocalizedStringResource="Ejecutar receta METATRON"
    static let description=IntentDescription("Ejecuta una receta JSON exportada desde METATRON con uno o más archivos.")
    static let openAppWhenRun=false
    @Parameter(title:"Archivos",supportedContentTypes:[.item],inputConnectionBehavior:.connectToPreviousIntentResult)
    var files:[IntentFile]
    @Parameter(title:"Receta JSON",supportedContentTypes:[.json]) var recipeFile:IntentFile
    @MainActor func perform() async throws ->some IntentResult & ReturnsValue<[IntentFile]> {
        guard recipeFile.data.count<=1_000_000 else {throw WorkflowError.invalid("La receta supera 1 MB.")}
        let recipe=try JSONDecoder().decode(Recipe.self,from:recipeFile.data)
        return .result(value:try await IntentFileWorkflow.run(files:files,recipe:recipe))
    }
}
nonisolated struct OpenMetatronIntent:AppIntent {
    static let title:LocalizedStringResource="Abrir METATRON"
    static let openAppWhenRun=true
    @MainActor func perform() async throws ->some IntentResult {WorkbenchPresentation.show();return .result()}
}
@available(macOS 15, *)
nonisolated struct MetatronShortcuts:AppShortcutsProvider {
    static var appShortcuts:[AppShortcut] {
        AppShortcut(intent:PrepareFilesIntent(),phrases:["Preparar archivos con \(.applicationName)"],shortTitle:"Preparar archivos",systemImageName:"square.stack.3d.up")
        AppShortcut(intent:RunRecipeIntent(),phrases:["Ejecutar receta con \(.applicationName)"],shortTitle:"Ejecutar receta",systemImageName:"arrow.triangle.branch")
        AppShortcut(intent:OpenMetatronIntent(),phrases:["Abrir \(.applicationName)"],shortTitle:"Abrir METATRON",systemImageName:"circle.hexagongrid")
    }
}
nonisolated private enum IntentFileWorkflow {
    @concurrent static func run(files:[IntentFile],recipe:Recipe) async throws ->[IntentFile] {
        guard !files.isEmpty,files.count<=100 else {throw WorkflowError.invalid("Elige entre 1 y 100 archivos.")}
        let staging=FileManager.default.temporaryDirectory.appendingPathComponent("metatron-shortcuts-"+UUID().uuidString,isDirectory:true)
        try FileManager.default.createDirectory(at:staging,withIntermediateDirectories:true)
        defer {try? FileManager.default.removeItem(at:staging)}
        var inputs:[URL]=[]
        for (index,file) in files.enumerated() {
            try Task.checkCancellation()
            let name=try FileIntegrity.safeComponent(file.filename)
            let target=staging.appendingPathComponent("\(index)-"+name)
            if let source=file.fileURL {
                let scoped=source.startAccessingSecurityScopedResource()
                defer {if scoped {source.stopAccessingSecurityScopedResource()}}
                try FileManager.default.copyItem(at:source,to:target)
            } else {try file.data.write(to:target)}
            inputs.append(target)
        }
        var configured=recipe
        configured.folderPath=await WorkspaceStore.shared.directory.appendingPathComponent("Shortcuts/"+UUID().uuidString,isDirectory:true).path
        let outputs=try await WorkspaceStore.shared.runRecipe(inputs:inputs,recipe:configured)
        return outputs.map {IntentFile(fileURL:$0.url,filename:$0.url.lastPathComponent,type:UTType(filenameExtension:$0.url.pathExtension))}
    }
}
