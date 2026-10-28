import AppKit
import Observation
import MetatronCore
import MetatronWorkflow
import os

struct LibraryItem: Codable, Identifiable {
    var id = UUID()
    var url: URL
    var title: String
    var text: String
    var tag: String
}
struct WorkspaceSnapshot: Codable {
    var recipes: [Recipe]
    var jobs: [WorkJob]
    var library: [LibraryItem]
}
extension Notification.Name { static let metatronShowWorkbench = Notification.Name("Metatron.showWorkbench") }

@Observable @MainActor final class WorkspaceStore {
    static let shared = WorkspaceStore()
    var files: [URL] = []
    var recipes: [Recipe] = Recipe.builtIns
    var selectedRecipeID: UUID?
    var jobs: [WorkJob] = []
    var library: [LibraryItem] = []
    var simulation: [SimulationRow] = []
    var notice: String?
    var activity = "Listo para trabajar"
    var selectedSection = "convert"
    var search = ""
    var copyAfterRun = false
    private(set) var canRestoreClipboard = false
    var hardware = HardwareProfile.current()
    var isRunning = false
    let directory: URL
    @ObservationIgnored private var queueTask: Task<Void, Never>?
    @ObservationIgnored private var transientParameters: [UUID: ToolParameters] = [:]
    @ObservationIgnored private var completions: [UUID: (Result<RecipeResult, Error>) -> Void] = [:]
    @ObservationIgnored private var previousClipboard: [[NSPasteboard.PasteboardType: Data]] = []
    @ObservationIgnored private let logger = Logger(subsystem: "local.metatron.app", category: "workspace")

    var selectedRecipe: Recipe { recipes.first { $0.id == selectedRecipeID } ?? recipes.first ?? Recipe.builtIns[0] }
    var directActions: [KQAction] { files.isEmpty ? [] : ActionCatalog.convertActions(for: files) + ActionCatalog.toolActions(for: files) }
    var completed: Int { jobs.count { $0.state == .completed } }
    var filteredLibrary: [LibraryItem] { search.isEmpty ? library : library.filter { $0.title.localizedCaseInsensitiveContains(search) || $0.text.localizedCaseInsensitiveContains(search) || $0.tag.localizedCaseInsensitiveContains(search) } }
    init(directory: URL? = nil) {
        if let directory { self.directory = directory }
        else if let index = CommandLine.arguments.firstIndex(of: "--data-dir"), CommandLine.arguments.count > index + 1 {
            self.directory = URL(fileURLWithPath: CommandLine.arguments[index + 1], isDirectory: true)
        } else { self.directory = URL.applicationSupportDirectory.appendingPathComponent("METATRON", isDirectory: true) }
        do {
            try LegacyMigration.workspace(to: self.directory)
            try FileManager.default.createDirectory(at: self.directory, withIntermediateDirectories: true)
            let file = self.directory.appendingPathComponent("workspace.json")
            if FileManager.default.fileExists(atPath: file.path) {
                let saved = try JSONDecoder().decode(WorkspaceSnapshot.self, from: Data(contentsOf: file))
                recipes = saved.recipes.isEmpty ? Recipe.builtIns : saved.recipes
                for preset in Recipe.builtIns where !recipes.contains(where: {$0.name == preset.name}) {recipes.append(preset)}
                jobs = saved.jobs.map { job in var copy = job; if [.queued,.running].contains(copy.state) { copy.state = .interrupted; copy.message = "Interrumpido al cerrar. Puedes reintentar." }; return copy }
                library = saved.library
            }
        } catch { notice = "No se pudo leer el espacio de trabajo: \(error.localizedDescription). El archivo original se conserva." }
        jobs = ActivityRetention.retained(jobs, days: SettingsStore.shared.activityRetentionDays)
        selectedRecipeID = recipes.first?.id
    }
    func persist() {
        do {
            let encoder = JSONEncoder(); encoder.outputFormatting = [.sortedKeys]
            try encoder.encode(WorkspaceSnapshot(recipes: recipes, jobs: jobs, library: library)).write(to: directory.appendingPathComponent("workspace.json"), options: .atomic)
        } catch { notice = "No se pudo guardar la actividad: \(error.localizedDescription)" }
    }
    func applyRetention() {
        jobs = ActivityRetention.retained(jobs, days: SettingsStore.shared.activityRetentionDays)
        persist()
    }
    func clearActivity() {
        jobs.removeAll { !ActivityRetention.isActive($0) }
        persist()
        activity = "Historial limpiado · archivos conservados"
    }
    func exportActivity() {
        let panel = NSSavePanel(); panel.nameFieldStringValue = "Metatron-actividad.json"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do { let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]; try encoder.encode(jobs).write(to: url, options: .atomic) }
        catch { notice = error.localizedDescription }
    }
    func addFiles(_ urls: [URL]) {
        var seen = Set(files.map(\.standardizedFileURL))
        for url in urls where url.isFileURL {
            if seen.insert(url.standardizedFileURL).inserted { files.append(url) }
        }
        simulation = []
    }
    func simulate() {
        let inputs=files,recipe=selectedRecipe
        Task {
            do {
                let rows=try await Simulation.inspect(inputs:inputs,recipe:recipe)
                guard inputs == files,recipe == selectedRecipe else {return}
                simulation=rows;activity="Simulación lista · no se han cambiado archivos"
            } catch {notice=error.localizedDescription}
        }
    }
    func enqueue() { enqueue(inputs: files, recipe: selectedRecipe) }
    func enqueue(inputs: [URL], recipe: Recipe, parameters: ToolParameters = .none, completion: ((Result<RecipeResult, Error>) -> Void)? = nil) {
        guard !inputs.isEmpty, !recipe.steps.isEmpty else { notice = "Añade archivos y al menos un paso."; return }
        let groups = recipe.groupsInputs ? [inputs] : inputs.map { [$0] }
        for group in groups {
            var configured=recipe
            if let engine=recipe.steps.first(where: {$0.action == "documentAdvanced"}), let id=DocumentEngineID(rawValue:engine.text), id != .native {configured.documentEnginePath=UserDefaults.standard.string(forKey:"documentEngine."+id.rawValue)}
            let job = WorkJob(inputs: group, recipe: configured)
            transientParameters[job.id] = parameters
            if let completion { completions[job.id] = completion }
            jobs.insert(job, at: 0)
        }
        simulation = []
        persist(); startQueue()
    }
    func runRecipe(inputs:[URL],recipe:Recipe) async throws ->[PublishedFile] {
        guard !inputs.isEmpty,!recipe.steps.isEmpty else {throw WorkflowError.invalid("Añade archivos y pasos.")}
        return try await withCheckedThrowingContinuation { continuation in
            var remaining=recipe.groupsInputs ? 1 : inputs.count
            var outputs:[PublishedFile]=[]
            var failure:Error?
            enqueue(inputs:inputs,recipe:recipe) {result in
                switch result {case .success(let value):outputs.append(contentsOf:value.files);case .failure(let error):if failure == nil {failure=error}}
                remaining -= 1
                if remaining == 0 {if let failure {continuation.resume(throwing:failure)} else {continuation.resume(returning:outputs)}}
            }
        }
    }
    private func startQueue() {
        guard queueTask == nil else { return }
        isRunning = true
        queueTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled, let job = jobs.last(where: { $0.state == .queued }) {
                update(job.id) { $0.state = .running; $0.message = "Comprobando entradas" }
                let parameters = transientParameters[job.id] ?? .none
                do {
                    let result = try await RecipeExecutor.execute(inputs: job.inputs, recipe: job.recipe, id: job.id, parameters: parameters) { [weak self] message in
                        await self?.progress(job.id, message: message)
                    }
                    update(job.id) { $0.sourceBytes=result.inputBytes; $0.outputs = result.files; $0.duration = result.elapsed; $0.state = .completed; $0.message = result.warnings.isEmpty ? "Salida verificada" : result.warnings.joined(separator: " · ") }
                    if copyAfterRun { copyResult(result.files) }
                    completions.removeValue(forKey: job.id)?(.success(result))
                    logger.notice("Job completed in \(result.elapsed) seconds")
                } catch {
                    let cancelled = Task.isCancelled || error is CancellationError
                    update(job.id) { $0.state = cancelled ? .cancelled : .failed; $0.message = cancelled ? "Cancelado. Los originales se conservan." : error.localizedDescription }
                    completions.removeValue(forKey: job.id)?(.failure(error))
                }
                transientParameters.removeValue(forKey: job.id)
                jobs = ActivityRetention.retained(jobs, days: SettingsStore.shared.activityRetentionDays)
                persist()
            }
            queueTask = nil; isRunning = false; activity = "Listo para trabajar"
            if jobs.contains(where: { $0.state == .queued }) { startQueue() }
        }
    }
    private func update(_ id: UUID, mutation: (inout WorkJob) -> Void) {
        if let index = jobs.firstIndex(where: { $0.id == id }) { mutation(&jobs[index]); persist() }
    }
    private func progress(_ id: UUID, message: String) {
        activity = message
        if let index = jobs.firstIndex(where: { $0.id == id }) { jobs[index].message = message }
    }
    func cancel() { queueTask?.cancel(); activity = "Cancelando después del paso en curso…" }
    func retry(_ job: WorkJob) {
        guard !job.recipe.steps.contains(where: { $0.action == "tool.protect" || $0.action == "tool.crop" || $0.action == "tool.resize" || $0.action == "tool.addBackground" }) else { notice = "Esta operación requiere parámetros. Iníciala desde la rueda."; return }
        enqueue(inputs: job.inputs, recipe: job.recipe)
    }
    func undo(_ job: WorkJob) {
        Task {
            do {
                try await RecipeExecutor.undo(job.outputs, directory: directory.appendingPathComponent("Undo/" + job.id.uuidString, isDirectory: true))
                update(job.id) { $0.state = .undone; $0.message = "Salidas retiradas y conservadas en el archivo de recuperación." }
            } catch { notice = error.localizedDescription }
        }
    }
    func addRecipe() {
        let recipe = Recipe(name: "Nueva receta", steps: [.init(action: "convert.jpg")])
        recipes.append(recipe); selectedRecipeID = recipe.id; persist()
    }
    func updateRecipe(_ recipe: Recipe) {
        if let index = recipes.firstIndex(where: { $0.id == recipe.id }) { recipes[index] = recipe; simulation = []; persist() }
    }
    func exportRecipe() {
        let panel = NSSavePanel(); panel.nameFieldStringValue = "\(selectedRecipe.name).metatron.json"
        if panel.runModal() == .OK, let url = panel.url {
            do { try JSONEncoder().encode(selectedRecipe).write(to: url) } catch { notice = error.localizedDescription }
        }
    }
    func importRecipe() {
        let panel = NSOpenPanel(); panel.allowedContentTypes = [.json]
        if panel.runModal() == .OK, let url = panel.url {
            do { var recipe = try JSONDecoder().decode(Recipe.self, from: Data(contentsOf: url)); recipe.id = UUID(); recipes.append(recipe); selectedRecipeID = recipe.id; persist() }
            catch { notice = error.localizedDescription }
        }
    }
    func pasteFiles() {
        let board = NSPasteboard.general
        if let urls = board.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL], !urls.isEmpty { addFiles(urls); return }
        guard let image = NSImage(pasteboard: board), let data = image.tiffRepresentation else { notice = "El portapapeles no contiene archivos ni imágenes."; return }
        do {
            let inbox = directory.appendingPathComponent("Clipboard", isDirectory: true)
            try FileManager.default.createDirectory(at: inbox, withIntermediateDirectories: true)
            let file = inbox.appendingPathComponent("Captura-\(UUID().uuidString.prefix(8)).tiff")
            try data.write(to: file); addFiles([file]); copyAfterRun = true
        } catch { notice = error.localizedDescription }
    }
    func copyResult(_ files: [PublishedFile]) {
        guard let first = files.first(where: { !$0.url.lastPathComponent.hasPrefix("metatron-") }) else { return }
        let board = NSPasteboard.general
        if !canRestoreClipboard {
            previousClipboard = (board.pasteboardItems ?? []).map { item in Dictionary(uniqueKeysWithValues: item.types.compactMap { type in item.data(forType: type).map { (type, $0) } }) }
            canRestoreClipboard = true
        }
        board.clearContents()
        if FileKind.of(first.url) == .image, let image = NSImage(contentsOf: first.url) { board.writeObjects([image]) }
        else { board.writeObjects([first.url as NSURL]) }
        activity = "Resultado en el portapapeles"
    }
    func restoreClipboard() {
        guard canRestoreClipboard else { return }
        let board = NSPasteboard.general; board.clearContents()
        let items = previousClipboard.map { values in let item = NSPasteboardItem(); for (type,data) in values { item.setData(data, forType: type) }; return item }
        board.writeObjects(items); previousClipboard = []; canRestoreClipboard = false; activity = "Portapapeles anterior restaurado"
    }
    func indexFiles() {
        let inputs = files
        Task {
            for input in inputs {
                do {
                    let text = try await DocumentIndex.extract(input)
                    let item = LibraryItem(url: input, title: input.lastPathComponent, text: String(text.prefix(100_000)), tag: DocumentIndex.suggestTag(text: text, filename: input.lastPathComponent))
                    library.removeAll { $0.url == input }; library.insert(item, at: 0)
                } catch { notice = error.localizedDescription }
            }
            persist(); selectedSection = "library"
        }
    }
}
