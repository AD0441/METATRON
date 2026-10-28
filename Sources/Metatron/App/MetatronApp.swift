import SwiftUI
import MetatronWorkflow

@main struct MetatronApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @ObservedObject private var preferences = SettingsStore.shared
    @State private var workspace = WorkspaceStore.shared
    @State private var settingsSelection = SettingsSelection()
    var body: some Scene {
        Window("METATRON", id: "workbench") {
            WorkspaceView(store: workspace)
                .frame(minWidth: 1000, minHeight: 680)
                .tint(preferences.interfaceAccent)
        }
        .defaultSize(width: 1220, height: 820)
        .commands {
            CommandGroup(after:.appVisibility) {
                Button("Controles de la barra de menús…") {AppDelegate.current?.showStatusMenu()}.keyboardShortcut("m",modifiers:[.command,.control,.option])
            }
            CommandGroup(after: .help) {
                if DemoCapture.directory != nil { Button("Guardar captura de demostración") { DemoCapture.take() }.keyboardShortcut("s", modifiers: [.command,.shift,.option]) }
            }
            CommandGroup(after: .newItem) {
                Button("Añadir archivos…") { workspace.chooseFiles() }.keyboardShortcut("o")
                Button("Añadir del portapapeles") { workspace.pasteFiles() }.keyboardShortcut("v", modifiers: [.command,.shift])
                Button("Mostrar acciones…") { RingController.shared.show(files: workspace.files, at: NSEvent.mouseLocation, mode: .click) }.keyboardShortcut("k").disabled(workspace.files.isEmpty)
                Divider()
                Button("Simular receta") { workspace.simulate() }.keyboardShortcut("r", modifiers: [.command,.shift])
                Button("Ejecutar receta") { workspace.enqueue() }.keyboardShortcut(.return, modifiers: .command)
            }
        }
        Settings { SettingsView(selection: settingsSelection).environmentObject(SettingsStore.shared).frame(width: 780, height: 600) }
    }
}
