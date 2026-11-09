import AppKit
import SwiftUI
import MetatronCore
import MetatronWorkflow

final class ActionPanel: NSPanel {
    var onDismiss: (() -> Void)?
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
    override func cancelOperation(_ sender: Any?) { onDismiss?() }
}
// A concrete hosting root avoids Swift 6.3's release optimizer crash when
// emitting the isolated destructor of a generic NSHostingView subclass.
struct QuickAccessRoot: View {
    let model: RingModel
    let style: QuickAccessStyle
    var body: some View {
        QuickAccessView(model: model, style: style).tint(SettingsStore.shared.interfaceAccent)
    }
}
final class ActionHostingView: NSHostingView<QuickAccessRoot> {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
}

final class QuickAccessController {
    static let shared = QuickAccessController()
    private var panel: NSPanel?
    var isVisible: Bool { panel?.isVisible == true }
    func show(model: RingModel, at point: NSPoint, style: QuickAccessStyle, mode: RingModel.Mode) {
        hide()
        let geometric = false
        let width: CGFloat = geometric ? 520 : style == .panel ? 540 : 420
        let height: CGFloat = style == .bubbles ? 430 : geometric ? 610 : style == .compact ? 460 : 500
        let p = ActionPanel(contentRect: NSRect(x: 0, y: 0, width: width, height: height), styleMask: [.titled, .closable, .utilityWindow], backing: .buffered, defer: false)
        p.onDismiss = { [weak self] in self?.hide() }
        p.hidesOnDeactivate = false
        p.title = style.title; p.level = .floating; p.isReleasedWhenClosed = false; p.animationBehavior = .none
        p.contentView = ActionHostingView(rootView: QuickAccessRoot(model: model, style: style))
        let screen = NSScreen.screens.first { $0.frame.contains(point) } ?? NSScreen.main
        let area = screen?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        p.setFrameOrigin(NSPoint(x: min(max(point.x - width / 2, area.minX + 8), area.maxX - width - 8), y: min(max(point.y - height / 2, area.minY + 8), area.maxY - height - 8)))
        panel = p
        if mode == .click { NSApp.activate(ignoringOtherApps: true); p.makeKeyAndOrderFront(nil) }
        else { p.orderFrontRegardless() }
    }
    func hide() { panel?.orderOut(nil); panel?.contentView = nil; panel = nil }
    static func perform(_ item: RingItem, files: [URL]) {
        shared.hide(); RingController.shared.hide()
        if let recipe=item.recipe {WorkspaceStore.shared.enqueue(inputs:files,recipe:recipe)}
        else if let destination = item.destination { FileActions.move(files, to: destination.folder) }
        else if let fileAction = item.fileAction { fileAction.perform(files) }
        else if let action = item.action { ActionRunner.shared.start(action, files: files) }
    }
}

struct QuickAccessView: View {
    @ObservedObject var model: RingModel
    let style: QuickAccessStyle
    @State private var query = ""
    @State private var selected: String?
    @FocusState private var searchFocused: Bool
    @ObservedObject private var preferences = SettingsStore.shared
    private let titles=RingModel.pageNames
    private var groups:[[RingItem]] {model.allPages}
    private var visible: [RingItem] {
        let source = style == .panel ? groups[min(model.page, groups.count-1)] : groups.flatMap { $0 }
        return source.filter { query.isEmpty || $0.title.localizedCaseInsensitiveContains(query) || ($0.action?.id.localizedCaseInsensitiveContains(query) ?? false) || ($0.destination?.folder.path.localizedCaseInsensitiveContains(query) ?? false) }
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: "doc.on.doc").foregroundStyle(.secondary)
                Text(model.files.count == 1 ? model.files[0].lastPathComponent : "\(model.files.count) archivos").font(.headline).lineLimit(1)
                Spacer()
                Button { QuickAccessController.shared.hide(); SettingsWindowController.shared.show(.general) } label: { Image(systemName: "gearshape") }.buttonStyle(.plain).help("Cambiar presentación")
            }.padding(16)
            if style == .panel {
                Picker("Categoría", selection: $model.page) { ForEach(0..<groups.count,id:\.self) { Text(titles[$0]).tag($0) } }.pickerStyle(.segmented).padding(.horizontal, 16).padding(.bottom, 12)
            }
            if style == .commands {
                TextField("Buscar formato, herramienta o destino", text: $query).textFieldStyle(.roundedBorder).focused($searchFocused)
                    .onSubmit { runSelection() }.padding(.horizontal, 16).padding(.bottom, 12)
                    .onKeyPress(.downArrow) { moveSelection(1); return .handled }
                    .onKeyPress(.upArrow) { moveSelection(-1); return .handled }
            }
            Divider()
            if visible.isEmpty { ContentUnavailableView.search(text: query) }
            else {
                ScrollViewReader { proxy in
                    List {
                        if style == .compact {
                            ForEach(0..<groups.count,id:\.self) { group in
                                if !groups[group].isEmpty { Section(titles[group]) { ForEach(groups[group]) { item in row(item) } } }
                            }
                        } else { ForEach(visible) { item in row(item) } }
                    }.listStyle(.inset)
                        .onChange(of: selected) { _, value in if let value { proxy.scrollTo(value) } }
                }
            }
            Divider()
            Text(style == .commands ? "↑↓ elegir · ↩ ejecutar · Esc cerrar" : "Haz clic o suelta los archivos sobre una acción.")
                .font(.caption).foregroundStyle(.secondary).padding(12)
        }.background(MetatronStyle.canvas)
            .onExitCommand { QuickAccessController.shared.hide() }
            .task { if style == .commands { searchFocused = true }; selected = visible.first?.id }
            .onChange(of: query) { _, _ in selected = visible.first?.id }
    }
    private func row(_ item: RingItem) -> some View {
        Button { QuickAccessController.perform(item, files: model.files) } label: {
            HStack(spacing: 12) {
                Image(systemName: item.symbol).foregroundStyle(MetatronStyle.accent).frame(width: 20)
                VStack(alignment: .leading, spacing: 3) {
                    Text(item.title).lineLimit(1)
                    if let destination = item.destination { Text(destination.folder.path).font(.caption).foregroundStyle(.secondary).lineLimit(1).truncationMode(.middle) }
                }
                Spacer()
                if style == .commands, item.id == selected { Image(systemName: "return").foregroundStyle(.secondary) }
            }.padding(.vertical, 7).contentShape(Rectangle())
        }.buttonStyle(.plain).id(item.id)
            .listRowBackground(style == .commands && selected == item.id ? MetatronStyle.accent.opacity(0.12) : Color.clear)
            .dropDestination(for: URL.self) { urls, _ in guard !urls.isEmpty else { return false }; QuickAccessController.perform(item, files: urls); return true }
            .help(item.destination?.folder.path ?? item.title)
    }
    private func runSelection() {
        guard let item = visible.first(where: { $0.id == selected }) ?? visible.first else { return }
        QuickAccessController.perform(item, files: model.files)
    }
    private func moveSelection(_ delta: Int) {
        guard !visible.isEmpty else { return }
        let index = visible.firstIndex { $0.id == selected } ?? 0
        selected = visible[min(max(0, index + delta), visible.count - 1)].id
    }
}
