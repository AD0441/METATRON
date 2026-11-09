import AppKit
import Combine
import MetatronCore
import MetatronWorkflow

/// Keeps unchanged watchers alive when another rule is edited. A token prevents
/// an already-delivered callback from enqueueing after pause/removal/replacement.
final class WatchService {
    static let shared = WatchService()
    private struct Entry { let rule: WatchRule; let token: UUID; let watcher: FolderWatcher }
    private var watchers: [UUID: Entry] = [:]
    private var cancellable: AnyCancellable?
    func start() {
        cancellable = Publishers.CombineLatest(SettingsStore.shared.$watchRules.removeDuplicates(), SettingsStore.shared.$paused.removeDuplicates())
            .sink { [weak self] rules, paused in self?.apply(paused ? [] : rules) }
    }
    func stop() {
        cancellable?.cancel(); cancellable = nil
        watchers.values.forEach { $0.watcher.stop() }; watchers = [:]
    }
    private func apply(_ rules: [WatchRule]) {
        let enabled = rules.filter(\.enabled)
        for (id, entry) in watchers where !enabled.contains(entry.rule) {
            entry.watcher.stop(); watchers.removeValue(forKey: id)
        }
        for rule in enabled where watchers[rule.id] == nil {
            let token = UUID()
            let watcher = FolderWatcher(folder: URL(fileURLWithPath: rule.folder, isDirectory: true), onError: { [weak self] message in
                Task { @MainActor [weak self] in
                    guard self?.watchers[rule.id]?.token == token else { return }
                    WorkspaceStore.shared.notice = message
                }
            }) { [weak self] url in
                Task { @MainActor [weak self] in
                    guard let self, self.watchers[rule.id]?.token == token, !SettingsStore.shared.paused else { return }
                    self.receive(url, rule: rule)
                }
            }
            watchers[rule.id] = Entry(rule: rule, token: token, watcher: watcher)
            if !watcher.start() {
                WorkspaceStore.shared.notice = "No se pudo vigilar \(URL(fileURLWithPath: rule.folder).lastPathComponent). Revisa la carpeta y sus permisos."
                watchers.removeValue(forKey: rule.id)
            }
        }
    }
    private func receive(_ url: URL, rule: WatchRule) {
        guard FileKind.of(url) != .folder else { return }
        let recipe: Recipe
        if rule.action.hasPrefix("recipe."), let id = UUID(uuidString: String(rule.action.dropFirst(7))),
           let found = WorkspaceStore.shared.recipes.first(where: { $0.id == id }) { recipe = found }
        else if let action = rule.applies(to: url) { recipe = Recipe(name: "Carpeta · " + action.title, steps: [.init(action: action.id)]) }
        else { return }
        if let path = recipe.folderPath {
            let output = URL(fileURLWithPath: path).resolvingSymlinksInPath().standardizedFileURL
            // Reject cycles through any watched input, including symlink aliases.
            if watchers.values.contains(where: { URL(fileURLWithPath: $0.rule.folder).resolvingSymlinksInPath().standardizedFileURL == output }) {
                WorkspaceStore.shared.notice = "La salida de una regla debe estar fuera de las carpetas de entrada vigiladas para evitar ciclos."
                return
            }
        }
        WorkspaceStore.shared.enqueue(inputs: [url], recipe: recipe)
    }
}
