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
    typealias JobExecution = @Sendable (WorkJob, ToolParameters, @escaping @Sendable (String) async -> Void) async throws -> RecipeResult
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
    private(set) var isShuttingDown = false
    @ObservationIgnored private let executeJob: JobExecution
    @ObservationIgnored private var runningJobID: UUID?
    @ObservationIgnored private var batches: [UUID: UUID] = [:]
    @ObservationIgnored private var unreadableSnapshot = false
    let directory: URL
    @ObservationIgnored private var queueTask: Task<Void, Never>?
    @ObservationIgnored private var transientParameters: [UUID: ToolParameters] = [:]
    @ObservationIgnored private var completions: [UUID: (Result<RecipeResult, Error>) -> Void] = [:]
    @ObservationIgnored private var previousClipboard: [[NSPasteboard.PasteboardType: Data]] = []
    @ObservationIgnored private let logger = Logger(subsystem: "local.metatron.app", category: "workspace")

    var selectedRecipe: Recipe { recipes.first { $0.id == selectedRecipeID } ?? recipes.first ?? Recipe.builtIns[0] }
    var compatibleRecipes: [Recipe] { files.isEmpty ? recipes : recipes.map(configuredRecipe).filter { RecipeCompatibility.issue(inputs: files, recipe: $0) == nil } }
    /// Resolve user-configured engines before availability checks and execution.
    func configuredRecipe(_ recipe: Recipe) -> Recipe {
        var configured = recipe
        if let step = recipe.steps.first(where: { $0.action == "documentAdvanced" }),
           let engine = DocumentEngineID(rawValue: step.text), engine != .native,
           let path = UserDefaults.standard.string(forKey: "documentEngine." + engine.rawValue), !path.isEmpty {
            configured.documentEnginePath = path
        }
        return configured
    }
    var conversionRecipe: Recipe? { compatibleRecipes.first { $0.id == selectedRecipeID } ?? compatibleRecipes.first }
    var canIndexFiles: Bool { !files.isEmpty && files.allSatisfy(DocumentIndex.supports) }
    var directActions: [KQAction] { files.isEmpty ? [] : ActionCatalog.convertActions(for: files) + ActionCatalog.toolActions(for: files) }
    var completed: Int { jobs.count { $0.state == .completed } }
    var filteredLibrary: [LibraryItem] { search.isEmpty ? library : library.filter { $0.title.localizedCaseInsensitiveContains(search) || $0.text.localizedCaseInsensitiveContains(search) || $0.tag.localizedCaseInsensitiveContains(search) } }
    init(directory: URL? = nil, executeJob: @escaping JobExecution = { job, parameters, progress in
        try await RecipeExecutor.execute(inputs: job.inputs, recipe: job.recipe, id: job.id, parameters: parameters, progress: progress)
    }) {
        self.executeJob = executeJob
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
        } catch { unreadableSnapshot = true; notice = "No se pudo leer el espacio de trabajo: \(error.localizedDescription). El archivo original se conserva." }
        jobs = ActivityRetention.retained(jobs, days: SettingsStore.shared.activityRetentionDays)
        selectedRecipeID = recipes.first?.id
    }
    func persist() {
        do {
            // Preserve a corrupt/incompatible snapshot before allowing any save.
            // If the backup fails, the original must remain untouched.
            if unreadableSnapshot {
                let original = directory.appendingPathComponent("workspace.json")
                if FileManager.default.fileExists(atPath: original.path) {
                    try FileManager.default.copyItem(at: original, to: directory.appendingPathComponent("workspace-recovery-" + UUID().uuidString + ".json"))
                }
                unreadableSnapshot = false
            }
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
        guard let recipe = conversionRecipe else { notice = "No hay recetas compatibles con los archivos preparados."; return }
        let inputs=files
        Task {
            do {
                let rows=try await Simulation.inspect(inputs:inputs,recipe:recipe)
                guard inputs == files,recipe == conversionRecipe else {return}
                simulation=rows;activity="Simulación lista · no se han cambiado archivos"
            } catch {notice=error.localizedDescription}
        }
    }
    func enqueue() {
        guard let recipe = conversionRecipe else { notice = "No hay recetas compatibles con los archivos preparados."; return }
        enqueue(inputs: files, recipe: recipe)
    }
    @discardableResult func enqueue(inputs: [URL], recipe: Recipe, parameters: ToolParameters = .none, batch: UUID? = nil, completion: ((Result<RecipeResult, Error>) -> Void)? = nil) -> [UUID] {
        guard !inputs.isEmpty, !recipe.steps.isEmpty else { notice = "Añade archivos y al menos un paso."; return [] }
        let recipe = configuredRecipe(recipe)
        let groups = recipe.groupsInputs ? [inputs] : inputs.map { [$0] }
        guard !isShuttingDown else { for _ in groups { completion?(.failure(CancellationError())) }; return [] }
        do { try RecipeCompatibility.validate(inputs: inputs, recipe: recipe) }
        catch {
            notice = error.localizedDescription
            for _ in groups { completion?(.failure(error)) }
            return []
        }
        var ids: [UUID] = []
        for group in groups {
            var configured=recipe
            var options = configured.conversionOptions ?? ConversionOptions()
            if options.speechLocale == nil { options.speechLocale = UserDefaults.standard.string(forKey: "speech.locale") ?? "es-CL" }
            configured.conversionOptions = options
            let job = WorkJob(inputs: group, recipe: configured)
            ids.append(job.id)
            if let batch { batches[job.id] = batch }
            transientParameters[job.id] = parameters
            if let completion { completions[job.id] = completion }
            jobs.insert(job, at: 0)
        }
        simulation = []
        persist(); startQueue()
        return ids
    }
    func runRecipe(inputs:[URL],recipe:Recipe) async throws ->[PublishedFile] {
        guard !inputs.isEmpty,!recipe.steps.isEmpty else {throw WorkflowError.invalid("Añade archivos y pasos.")}
        guard !isShuttingDown else { throw CancellationError() }
        try Task.checkCancellation()
        let recipe = configuredRecipe(recipe)
        try RecipeCompatibility.validate(inputs: inputs, recipe: recipe)
        let batch = UUID()
        let result = try await withTaskCancellationHandler {
            try Task.checkCancellation()
            return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[PublishedFile], Error>) in
                var remaining = recipe.groupsInputs ? 1 : inputs.count
                var outputs: [PublishedFile] = []
                var failure: Error?
                enqueue(inputs: inputs, recipe: recipe, batch: batch) { result in
                    switch result {
                    case .success(let value): outputs.append(contentsOf: value.files)
                    case .failure(let error): if failure == nil { failure = error }
                    }
                    remaining -= 1
                    if remaining == 0 {
                        if let failure { continuation.resume(throwing: failure) }
                        else { continuation.resume(returning: outputs) }
                    }
                }
            }
        } onCancel: {
            Task { @MainActor in self.cancelJobs(Set(self.batches.filter { $0.value == batch }.keys)) }
        }
        try Task.checkCancellation()
        return result
    }
    private func startQueue() {
        guard queueTask == nil, !isShuttingDown else { return }
        isRunning = true
        queueTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled, let job = jobs.last(where: { $0.state == .queued }) {
                runningJobID = job.id
                update(job.id) { $0.state = .running; $0.message = "Comprobando entradas" }
                let parameters = transientParameters[job.id] ?? .none
                do {
                    let result = try await executeJob(job, parameters) { [weak self] message in
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
                runningJobID = nil
                batches.removeValue(forKey: job.id)
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
    /// Cancels the current job; independent queued work continues afterwards.
    func cancel() {
        guard let runningJobID else { return }
        cancelJobs([runningJobID])
    }
    private func cancelJobs(_ ids: Set<UUID>) {
        for id in ids {
            guard let job = jobs.first(where: { $0.id == id }) else { continue }
            if job.state == .queued {
                update(id) { $0.state = .cancelled; $0.message = "Cancelado. Los originales se conservan." }
                transientParameters.removeValue(forKey: id); batches.removeValue(forKey: id)
                completions.removeValue(forKey: id)?(.failure(CancellationError()))
            } else if job.state == .running {
                queueTask?.cancel(); activity = "Cancelando el trabajo actual…"
            }
        }
    }
    /// No new jobs can enter while quitting. Await the active conversion and its
    /// rollback before replying to macOS, so helpers cannot outlive the app.
    func shutDown() async {
        isShuttingDown = true
        cancelJobs(Set(jobs.filter { ActivityRetention.isActive($0) }.map(\.id)))
        let pending = queueTask
        queueTask?.cancel()
        await pending?.value
        persist()
    }
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
        guard canIndexFiles else { notice = "La biblioteca admite PDF, imágenes, documentos y tablas; convierte primero los audios a texto."; return }
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
