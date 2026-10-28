import SwiftUI
import MetatronWorkflow
struct ActivityView: View {
    let store: WorkspaceStore
    @ObservedObject private var preferences = SettingsStore.shared
    @State private var query = ""
    @State private var state: JobState?
    @State private var confirmClear = false
    private var visibleJobs: [WorkJob] {
        store.jobs.filter { job in
            (state == nil || state == job.state) && (query.isEmpty || job.inputs.contains { $0.lastPathComponent.localizedCaseInsensitiveContains(query) } || job.recipe.name.localizedCaseInsensitiveContains(query))
        }
    }
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                Picker("Mostrar", selection: $state) {
                    Text("Todos").tag(JobState?.none)
                    Text("Completados").tag(Optional(JobState.completed))
                    Text("Fallidos").tag(Optional(JobState.failed))
                    Text("Pendientes").tag(Optional(JobState.queued))
                }.frame(maxWidth: 220)
                Spacer()
                Picker("Historial", selection: $preferences.activityRetentionDays) {
                    ForEach(ActivityRetention.choices, id: \.self) { Text(ActivityRetention.label($0)).tag($0) }
                }.frame(maxWidth: 260)
            }.padding(20)
            Divider()
            if store.jobs.isEmpty {
                ContentUnavailableView("Tu actividad aparecerá aquí", systemImage: "clock.arrow.circlepath", description: Text("Aquí puedes revisar resultados, reintentar trabajos y deshacer las salidas que aún conservan su registro."))
            } else if visibleJobs.isEmpty {
                ContentUnavailableView.search(text: query)
            } else {
                List(visibleJobs) { job in JobRow(job: job, store: store) }
            }
        }.navigationTitle("Actividad")
        .searchable(text: $query, prompt: "Buscar archivo o receta")
        .toolbar {
            Button("Deshacer movimiento", systemImage: "arrow.uturn.backward") { undoMove() }
            Menu {
                Button("Exportar historial…", systemImage: "square.and.arrow.up") { store.exportActivity() }.disabled(store.jobs.isEmpty)
                Button("Borrar todo el historial…", systemImage: "trash", role: .destructive) { confirmClear = true }.disabled(!store.jobs.contains { !ActivityRetention.isActive($0) })
            } label: { Label("Gestionar historial", systemImage: "ellipsis.circle") }
            if store.isRunning { Button("Cancelar trabajo", systemImage: "stop.fill") { store.cancel() } }
        }
        .alert("¿Borrar el historial?", isPresented: $confirmClear) {
            Button("Cancelar", role: .cancel) {}
            Button("Borrar registros", role: .destructive) { store.clearActivity() }
        } message: { Text("Conserva los archivos originales y generados. Se retiran los registros terminados y sus accesos a Deshacer; los trabajos pendientes siguen en la cola.") }
        .task { store.applyRetention() }
        .onChange(of: preferences.activityRetentionDays) { _, _ in store.applyRetention() }
    }
    private func undoMove() {
        Task {
            do {
                let path = store.directory.appendingPathComponent("last-move.json")
                let records = try JSONDecoder().decode([MovedFile].self, from: Data(contentsOf: path))
                try await FileMoveTransaction.undo(records)
                try FileManager.default.removeItem(at: path)
                store.activity = "Movimiento deshecho"
            } catch { store.notice = error.localizedDescription }
        }
    }
}
struct JobRow: View {
    let job: WorkJob
    let store: WorkspaceStore
    @State private var transfer: TransferSelection?
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: symbol).foregroundStyle(color)
                Text(job.inputs.map(\.lastPathComponent).joined(separator: ", ")).font(.headline).lineLimit(1)
                Spacer()
                Text(job.created, format: .dateTime.day().month().hour().minute()).foregroundStyle(.secondary).font(.caption)
            }
            Text(job.recipe.name).foregroundStyle(.secondary)
            Text(job.message).font(.caption).textSelection(.enabled)
            if job.duration > 0 { Text("\(job.duration, format: .number.precision(.fractionLength(2))) s · \(job.outputs.count) resultados").font(.caption.monospaced()).foregroundStyle(.secondary) }
            HStack {
                if job.state == .completed {
                    Button("Mostrar resultados") { NSWorkspace.shared.activateFileViewerSelecting(job.outputs.map(\.url)) }
                    Button("Copiar") { store.copyResult(job.outputs) }
                    Button("Compartir…") { SharePanel.show(job.outputs.map(\.url)) }
                    Button("Enviar por LAN") { if let file = job.outputs.first { transfer = TransferSelection(file: file.url) } }
                    Button("Deshacer") { store.undo(job) }
                }
                if [.failed,.cancelled,.interrupted,.undone].contains(job.state) { Button("Reintentar") { store.retry(job) } }
            }.controlSize(.small)
        }.padding(.vertical, 10).sheet(item: $transfer) { LocalTransferView(file: $0.file) }
    }
    private var symbol: String { switch job.state { case .completed: "checkmark.circle.fill"; case .failed: "exclamationmark.triangle.fill"; case .running: "arrow.triangle.2.circlepath"; case .undone: "arrow.uturn.backward.circle"; default: "clock" } }
    private var color: Color { switch job.state { case .completed: .green; case .failed: .red; case .running: MetatronStyle.accent; default: .secondary } }
}
enum SharePanel {
    static func show(_ urls: [URL]) {
        guard let view = NSApp.keyWindow?.contentView else { return }
        NSSharingServicePicker(items: urls).show(relativeTo: NSRect(x: view.bounds.midX, y: view.bounds.midY, width: 1, height: 1), of: view, preferredEdge: .minY)
    }
}
