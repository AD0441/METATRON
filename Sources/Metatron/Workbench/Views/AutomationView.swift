import SwiftUI
import MetatronCore
struct AutomationView: View {
    let store: WorkspaceStore
    @ObservedObject private var settings = SettingsStore.shared
    var body: some View {
        Form {
            Section {
                Text("Una carpeta de entrada, una receta").font(.title2.bold())
                Text("Solo se procesan archivos nuevos, cuando su tamaño se estabiliza. Cada resultado pasa por la cola y la validación. Los archivos existentes y los originales se conservan.").foregroundStyle(.secondary)
            }
            Section("Crear una regla") {
                LabeledContent("Receta elegida", value: store.selectedRecipe.name)
                Button("Elegir carpeta de entrada…") {
                    let panel = NSOpenPanel(); panel.canChooseFiles = false; panel.canChooseDirectories = true
                    if panel.runModal() == .OK, let folder = panel.url {
                        let rule = WatchRule(folder: folder.path, action: "recipe." + store.selectedRecipe.id.uuidString)
                        settings.watchRules.append(rule)
                    }
                }
                Text("Cambia la receta seleccionada en Recetas antes de crear otra regla.").font(.caption).foregroundStyle(.secondary)
            }
            Section("Carpetas vigiladas") {
                ForEach(settings.watchRules) { rule in
                    VStack(alignment: .leading, spacing: 6) {
                        Toggle(rule.folder, isOn: Binding(get: { settings.watchRules.first(where: { $0.id == rule.id })?.enabled ?? false }, set: { enabled in if let i = settings.watchRules.firstIndex(where: { $0.id == rule.id }) { settings.watchRules[i].enabled = enabled } }))
                        Text(recipeName(rule)).font(.caption).foregroundStyle(.secondary)
                        Button("Quitar regla", role: .destructive) { settings.watchRules.removeAll { $0.id == rule.id } }
                    }
                }
                if settings.watchRules.isEmpty { Text("Todavía no hay reglas.").foregroundStyle(.secondary) }
            }
        }.formStyle(.grouped).navigationTitle("Automatización")
    }
    private func recipeName(_ rule: WatchRule) -> String {
        if rule.action.hasPrefix("recipe."), let id = UUID(uuidString: String(rule.action.dropFirst(7))) { return store.recipes.first { $0.id == id }?.name ?? "Receta no disponible" }
        return KQAction(id: rule.action)?.title ?? rule.action
    }
}
