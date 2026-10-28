import AppKit
import SwiftUI
import MetatronWorkflow

struct OrganizationPane: View {
    @EnvironmentObject var settings: SettingsStore
    var body: some View {
        Form {
            Section("Destinos favoritos") {
                Text("Guarda carpetas para mover archivos desde Favoritos, las acciones rápidas o la cuarta página de la ruleta.").foregroundStyle(.secondary)
                if settings.savedDestinations.isEmpty {
                    Text("Todavía no hay destinos. Añade una carpeta como Investigación, Docencia o Archivo.").font(.callout).foregroundStyle(.secondary)
                }
                ForEach($settings.savedDestinations) { $destination in
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Image(systemName: "folder").foregroundStyle(settings.interfaceAccent)
                            TextField("Nombre del destino", text: $destination.name)
                            Button { move(destination.id, by: -1) } label: { Image(systemName: "chevron.up") }.help("Subir destino")
                            Button { move(destination.id, by: 1) } label: { Image(systemName: "chevron.down") }.help("Bajar destino")
                            Button(role: .destructive) { settings.savedDestinations.removeAll { $0.id == destination.id } } label: { Image(systemName: "minus.circle") }.help("Quitar favorito; conserva la carpeta")
                        }
                        Text(destination.folder.path).font(.caption).foregroundStyle(.secondary).lineLimit(2).textSelection(.enabled)
                    }
                }
                Button("Añadir carpeta…", systemImage: "folder.badge.plus") { addDestination() }
                if settings.savedDestinations.count > 12 { Text("La ruleta muestra los primeros 12 destinos; los otros modos incluyen todos.").font(.caption).foregroundStyle(.secondary) }
            }
            Section("Actividad") {
                Picker("Retención del historial", selection: $settings.activityRetentionDays) {
                    ForEach(ActivityRetention.choices, id: \.self) { Text(ActivityRetention.label($0)).tag($0) }
                }
                Text("Retira registros antiguos al abrir Actividad, cambiar esta opción o terminar un trabajo. Conserva los archivos de salida y los trabajos pendientes.").font(.caption).foregroundStyle(.secondary)
            }
        }.onChange(of: settings.activityRetentionDays) { _, _ in WorkspaceStore.shared.applyRetention() }
    }
    private func addDestination() {
        let panel = NSOpenPanel(); panel.canChooseFiles = false; panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true; panel.prompt = "Guardar destinos"
        guard panel.runModal() == .OK else { return }
        for folder in panel.urls where !settings.savedDestinations.contains(where: { $0.folder.standardizedFileURL == folder.standardizedFileURL }) {
            settings.savedDestinations.append(SavedDestination(name: folder.lastPathComponent, folder: folder))
        }
    }
    private func move(_ id: UUID, by delta: Int) {
        guard let index = settings.savedDestinations.firstIndex(where: { $0.id == id }) else { return }
        let next = index + delta
        guard settings.savedDestinations.indices.contains(next) else { return }
        settings.savedDestinations.swapAt(index, next)
    }
}
struct DestinationFavoritesView: View {
    let store: WorkspaceStore
    @ObservedObject private var preferences = SettingsStore.shared
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Mover a favoritos").font(.headline)
                Spacer()
                Button("Configurar…") { SettingsWindowController.shared.show(.organization) }.buttonStyle(.link)
            }
            if preferences.savedDestinations.isEmpty {
                Text("Guarda tus carpetas habituales en Ajustes para ordenar con un clic.").font(.callout).foregroundStyle(.secondary)
            } else {
                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        ForEach(preferences.savedDestinations) { destination in
                            Button { FileActions.move(store.files, to: destination.folder) } label: { Label(destination.name.isEmpty ? destination.folder.lastPathComponent : destination.name, systemImage: "folder") }
                                .help(destination.folder.path).disabled(store.files.isEmpty)
                        }
                    }.padding(.vertical, 2)
                }
            }
        }.padding(.vertical, 2)
    }
}
