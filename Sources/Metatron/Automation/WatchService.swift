import AppKit
import Combine
import MetatronCore
import MetatronWorkflow

/// Event-driven folder intake. Outputs go to a separate folder and use the same verified queue.
final class WatchService {
    static let shared = WatchService()
    private var watchers: [UUID: FolderWatcher] = [:]
    private var cancellable: AnyCancellable?
    func start() {
        apply(SettingsStore.shared.watchRules)
        cancellable = SettingsStore.shared.$watchRules.removeDuplicates().sink { [weak self] in self?.apply($0) }
    }
    private func apply(_ rules: [WatchRule]) {
        watchers.values.forEach { $0.stop() }; watchers = [:]
        for rule in rules where rule.enabled {
            let watcher = Self.watcher(for: rule) { _ in }
            watcher.start(); watchers[rule.id] = watcher
        }
    }
    static func watcher(for rule: WatchRule, log: @escaping @Sendable (String) -> Void) -> FolderWatcher {
        FolderWatcher(folder: URL(fileURLWithPath: rule.folder, isDirectory: true)) { url in
            Task { @MainActor in
                guard FileKind.of(url) != .folder else { return }
                let recipe: Recipe
                if rule.action.hasPrefix("recipe."), let id = UUID(uuidString: String(rule.action.dropFirst(7))), let found = WorkspaceStore.shared.recipes.first(where: { $0.id == id }) { recipe = found }
                else if let action = rule.applies(to: url) { recipe = Recipe(name: "Carpeta · " + action.title, steps: [.init(action: action.id)]) }
                else { return }
                if let path = recipe.folderPath, URL(fileURLWithPath: path).standardizedFileURL == URL(fileURLWithPath: rule.folder).standardizedFileURL {
                    WorkspaceStore.shared.notice = "La salida de una regla debe estar fuera de la carpeta de entrada para evitar ciclos."
                    return
                }
                WorkspaceStore.shared.enqueue(inputs: [url], recipe: recipe)
                log("Archivo añadido a la cola")
            }
        }
    }
}
