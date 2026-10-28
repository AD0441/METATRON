import AppKit
import SwiftUI
import MetatronWorkflow

enum FileActionID: String, CaseIterable, Identifiable {
    case airDrop, float, copy, move, copyPath, terminal, annotate, configureDestinations
    var id: String { rawValue }
    var title: String { switch self { case .configureDestinations: "Configurar destinos"; case .airDrop: "AirDrop"; case .float: "Bandeja flotante"; case .copy: "Copiar archivos"; case .move: "Mover a carpeta"; case .copyPath: "Copiar rutas"; case .terminal: "Abrir Terminal"; case .annotate: "Anotar imagen" } }
    var symbol: String { switch self { case .configureDestinations: "folder.badge.gearshape"; case .airDrop: "airplayaudio"; case .float: "rectangle.on.rectangle"; case .copy: "doc.on.doc"; case .move: "folder"; case .copyPath: "link"; case .terminal: "terminal"; case .annotate: "pencil.and.outline" } }
    func perform(_ files: [URL]) {
        guard !files.isEmpty else { return }
        switch self {
        case .configureDestinations: SettingsWindowController.shared.show(.organization)
        case .annotate: ImageMarkupWindow.show(files[0])
        case .airDrop:
            guard let service = NSSharingService(named: .sendViaAirDrop) else { return }
            service.perform(withItems: files)
        case .copy: NSPasteboard.general.clearContents(); NSPasteboard.general.writeObjects(files.map { $0 as NSURL })
        case .copyPath: NSPasteboard.general.clearContents(); NSPasteboard.general.setString(files.map(\.path).joined(separator: "\n"), forType: .string)
        case .float: FloatingShelf.show(files)
        case .terminal:
            let app = URL(fileURLWithPath: "/System/Applications/Utilities/Terminal.app")
            NSWorkspace.shared.open([files[0].deletingLastPathComponent()], withApplicationAt: app, configuration: NSWorkspace.OpenConfiguration())
        case .move:
            let panel = NSOpenPanel(); panel.canChooseFiles = false; panel.canChooseDirectories = true; panel.message = "Mover los archivos seleccionados a esta carpeta"
            guard panel.runModal() == .OK, let destination = panel.url else { return }
            FileActions.move(files, to: destination)
        }
    }
}
enum FileActions {
    private static var moving = false
    static func move(_ files: [URL], to destination: URL) {
        guard !files.isEmpty else { return }
        guard !moving else { WorkspaceStore.shared.notice = "Espera a que termine el movimiento actual."; return }
        moving = true
        Task {
            defer { moving = false }
            do {
                let records = try await FileMoveTransaction.move(files, into: destination)
                let store = WorkspaceStore.shared
                let path = store.directory.appendingPathComponent("last-move.json")
                do { try JSONEncoder().encode(records).write(to: path, options: .atomic) }
                catch { try await FileMoveTransaction.undo(records); throw error }
                store.files.removeAll { files.contains($0) }; store.simulation = []
                store.activity = "Movido a \(destination.lastPathComponent) · Deshacer movimiento en Actividad"
            } catch { WorkspaceStore.shared.notice = error.localizedDescription }
        }
    }
}
enum FloatingShelf {
    private static var panels: [NSPanel] = []
    static func show(_ files: [URL]) {
        let panel = NSPanel(contentRect: NSRect(x: 0,y: 0,width: 340,height: 320), styleMask: [.titled,.closable,.resizable,.utilityWindow], backing: .buffered, defer: false)
        panel.title = "Bandeja METATRON"; panel.level = .floating; panel.isReleasedWhenClosed = false
        panel.contentView = NSHostingView(rootView: ShelfView(files: files)); panel.center(); panel.makeKeyAndOrderFront(nil); panels.append(panel)
    }
}
struct ShelfView: View {
    let files: [URL]
    var body: some View {
        VStack(alignment: .leading) {
            Text("Arrastra donde los necesites").font(.headline).padding()
            List(files, id: \.self) { file in
                Label(file.lastPathComponent, systemImage: "doc").draggable(file).contextMenu { Button("Abrir") { NSWorkspace.shared.open(file) }; Button("Mostrar en Finder") { NSWorkspace.shared.activateFileViewerSelecting([file]) } }
            }
        }
    }
}
