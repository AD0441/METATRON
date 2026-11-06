import SwiftUI
import UniformTypeIdentifiers
import MetatronCore
import MetatronWorkflow

struct WorkspaceView: View {
    @Bindable var store: WorkspaceStore
    @ObservedObject private var preferences = SettingsStore.shared
    var body: some View {
        NavigationSplitView {
            List(selection: $store.selectedSection) {
                Section("Tu espacio") {
                    Label("Convertir", systemImage: "arrow.triangle.2.circlepath").tag("convert")
                    Label("Recetas", systemImage: "square.stack.3d.up").tag("recipes")
                    Label("Automatización", systemImage: "bolt").tag("automation")
                    Label("Actividad", systemImage: "clock.arrow.circlepath").tag("activity")
                }
                Section("Herramientas") {
                    Label("Comparar PDF", systemImage: "doc.on.doc").tag("compare")
                    Label("Biblioteca", systemImage: "books.vertical").tag("library")
                    Label("Asistente local", systemImage: "sparkles").tag("assistant")
                    Label("Rendimiento y motores", systemImage: "cpu").tag("performance")
                }
            }
            .listStyle(.sidebar)
            .safeAreaInset(edge: .bottom) {
                VStack(alignment: .leading, spacing: 7) {
                    HStack(spacing: 8) { MetatronMark().frame(width: 22, height: 22); Text(Brand.name).font(.headline) }.foregroundStyle(MetatronStyle.accent)
                    Label("Archivos en tu Mac", systemImage: "lock.shield").font(.caption).foregroundStyle(.secondary)
                    SettingsLink { Label("Ajustes", systemImage: "gearshape") }.buttonStyle(.plain)
                    Text(Brand.author).font(.system(size: 10)).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                }.padding().frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationSplitViewColumnWidth(min: 210, ideal: 230)
        } detail: {
            Group {
                switch store.selectedSection {
                case "recipes": RecipeLibraryView(store: store)
                case "activity": ActivityView(store: store)
                case "automation": AutomationView(store: store)
                case "compare": PDFCompareView()
                case "library": LibraryView(store: store)
                case "assistant": LocalAssistantView(store: store)
                case "performance": PerformanceView(store: store)
                default: ConvertWorkspaceView(store: store)
                }
            }
            .safeAreaInset(edge: .bottom) { StatusStrip(store: store) }
        }
        .background(WorkbenchWindowCapture().frame(width:0,height:0))
        .toolbar {
            ToolbarItemGroup {
                Button { RingController.shared.show(files: store.files, at: NSEvent.mouseLocation, mode: .click) } label: { Label("Acciones", systemImage: "slider.horizontal.3") }.disabled(store.files.isEmpty)
                Button { store.pasteFiles() } label: { Label("Portapapeles", systemImage: "doc.on.clipboard") }
                Button { store.chooseFiles() } label: { Label("Añadir archivos", systemImage: "plus") }
            }
        }
        .dropDestination(for: URL.self) { urls, _ in store.addFiles(urls); store.selectedSection = "convert"; return !urls.isEmpty }
        .alert("METATRON", isPresented: Binding(get: { store.notice != nil }, set: { if !$0 { store.notice = nil } })) {
            Button("Aceptar", role: .cancel) { store.notice = nil }
        } message: { Text(store.notice ?? "") }
        .onChange(of: preferences.activityRetentionDays) { _, _ in store.applyRetention() }
        .onReceive(NotificationCenter.default.publisher(for: .metatronShowWorkbench)) { _ in WorkbenchPresentation.show() }
    }
}
struct StatusStrip: View {
    let store: WorkspaceStore
    var body: some View {
        HStack(spacing: 10) {
            if store.isRunning { ProgressView().controlSize(.small) }
            else { Image(systemName: "checkmark.circle").foregroundStyle(.green) }
            Text(store.activity).lineLimit(1)
            Spacer()
            Text("\(store.completed) completados").foregroundStyle(.secondary)
        }.font(.caption).padding(.horizontal, 22).padding(.vertical, 10).background(.bar)
    }
}
struct ConvertWorkspaceView: View {
    @Bindable var store: WorkspaceStore
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 7) {
                    Text("Prepara tus archivos").font(.system(size: 25, weight: .semibold))
                    Text("Convierte con una receta o envía tus archivos a un destino guardado.").foregroundStyle(.secondary)
                }
                InputFilesView(store: store)
                DestinationFavoritesView(store: store)
                HStack(alignment: .top, spacing: 22) {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Qué quieres hacer").font(.title3.bold())
                        if let recipe = store.conversionRecipe {
                            Picker("Receta", selection: Binding(get: { store.conversionRecipe?.id }, set: { store.selectedRecipeID = $0 })) {
                                ForEach(store.compatibleRecipes) { Text($0.name).tag(Optional($0.id)) }
                            }.labelsHidden()
                            RecipeStepsSummary(steps: recipe.steps)
                        } else {
                            Text("No hay recetas compatibles con esta selección. Puedes crear una en Recetas.").foregroundStyle(.secondary)
                        }
                        Toggle("Copiar resultado al terminar", isOn: $store.copyAfterRun)
                        HStack {
                            Button("Simular", systemImage: "eye") { store.simulate() }
                            Button("Ejecutar receta", systemImage: "play.fill") { store.enqueue() }.buttonStyle(.borderedProminent)
                        }.disabled(store.files.isEmpty || store.conversionRecipe == nil)
                        Text("⌘↩ ejecutar · ⇧⌘R simular").font(.caption).foregroundStyle(.secondary)
                    }.frame(maxWidth: .infinity, alignment: .leading)
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Conserva tus originales", systemImage: "checkmark.shield").font(.headline)
                        Text("Cada receta trabaja en un espacio temporal. La salida se verifica antes de publicarse y queda registrada en Actividad.").foregroundStyle(.secondary)
                        Button("Editar esta receta") { store.selectedRecipeID = store.conversionRecipe?.id; store.selectedSection = "recipes" }.disabled(store.conversionRecipe == nil)
                        Button("Indexar para buscar") { store.indexFiles() }.disabled(!store.canIndexFiles)
                        Button("Restaurar portapapeles") { store.restoreClipboard() }.disabled(!store.canRestoreClipboard)
                    }.padding(18).frame(maxWidth: .infinity, alignment: .leading).background(MetatronStyle.panel, in: RoundedRectangle(cornerRadius: 12))
                }
                if !store.simulation.isEmpty { SimulationView(rows: store.simulation) }
            }.padding(30)
        }.navigationTitle("Convertir")
    }
}
struct InputFilesView: View {
    let store: WorkspaceStore
    @State private var targeted = false
    var body: some View {
        VStack(spacing: 14) {
            if store.files.isEmpty {
                Image(systemName: "tray.and.arrow.down").font(.system(size: 40)).foregroundStyle(MetatronStyle.accent)
                Text("Arrastra tus archivos aquí").font(.title3.bold())
                Text("Imágenes, PDF, documentos, hojas de cálculo, audio y vídeo").foregroundStyle(.secondary)
                Button("Elegir archivos…") { store.chooseFiles() }
            } else {
                HStack { Text(store.files.count == 1 ? "1 archivo preparado" : "\(store.files.count) archivos preparados").font(.headline); Spacer(); Button("Quitar todos") { store.files = []; store.simulation = [] } }
                Menu("Conversión o herramienta rápida") {
                    if store.directActions.isEmpty { Text("No hay conversiones o herramientas compatibles con esta selección.") }
                    ForEach(store.directActions, id: \.id) { action in
                        Button(action.title) { ActionRunner.shared.start(action, files: store.files) }
                    }
                }
                ScrollView { LazyVStack(spacing: 12) { ForEach(store.files, id: \.self) { file in
                    HStack {
                        Image(systemName: fileIcon(file)).foregroundStyle(MetatronStyle.accent).frame(width: 24)
                        VStack(alignment: .leading) { Text(file.lastPathComponent); Text(file.deletingLastPathComponent().path).font(.caption).foregroundStyle(.secondary).lineLimit(1).truncationMode(.middle) }
                        Spacer()
                        Button { store.files.removeAll { $0 == file }; store.simulation = [] } label: { Image(systemName: "xmark.circle.fill") }.buttonStyle(.plain).accessibilityLabel("Quitar \(file.lastPathComponent)")
                    }
                }
                } }.frame(height: min(220, CGFloat(store.files.count) * 48))
            }
        }.padding(22).frame(maxWidth: .infinity, minHeight: 148)
            .background(MetatronStyle.panel, in: RoundedRectangle(cornerRadius: 12))
            .overlay { RoundedRectangle(cornerRadius: 12).strokeBorder(targeted ? MetatronStyle.accent : MetatronStyle.divider, style: StrokeStyle(lineWidth: targeted ? 2 : 1, dash: store.files.isEmpty ? [5,4] : [])) }
            .dropDestination(for: URL.self) { urls, _ in store.addFiles(urls); return !urls.isEmpty } isTargeted: { targeted = $0 }
    }
    private func fileIcon(_ file: URL) -> String {
        switch FileKind.of(file) { case .image: "photo"; case .pdf: "doc.richtext"; case .video: "film"; case .audio: "waveform"; case .data: "tablecells"; default: "doc" }
    }
}
struct RecipeStepsSummary: View {
    let steps: [RecipeStep]
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(steps) { step in
                HStack(alignment: .top, spacing: 10) { Image(systemName: "arrow.turn.down.right").foregroundStyle(MetatronStyle.accent); Text(step.title) }
            }
        }.padding(.vertical, 5)
    }
}
struct SimulationView: View {
    let rows: [SimulationRow]
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Simulación · sin modificar archivos", systemImage: "eye").font(.title3.bold())
            ForEach(rows) { row in
                VStack(alignment: .leading, spacing: 5) {
                    Text(row.name).bold()
                    ForEach(row.facts,id:\.self) {Text($0).font(.caption).foregroundStyle(.secondary)}
                    Text(row.destination).font(.caption.monospaced()).textSelection(.enabled)
                    ForEach(row.warnings, id: \.self) { Text("· " + $0).font(.caption).foregroundStyle(.secondary) }
                }.frame(maxWidth: .infinity, alignment: .leading).padding(12).background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 8))
            }
        }
    }
}
extension WorkspaceStore {
    func chooseFiles() {
        let panel = NSOpenPanel(); panel.allowsMultipleSelection = true; panel.canChooseDirectories = true; panel.message = "Añade archivos a tu mesa de trabajo"
        if panel.runModal() == .OK { addFiles(panel.urls) }
    }
}
