import AppKit
import MetatronCore
import SwiftUI

/// Borderless floating panel that hosts the ring right under the cursor.
final class RingPanel: NSPanel {
    var allowsKey = false
    override var canBecomeKey: Bool { allowsKey }
    override var canBecomeMain: Bool { false }
}

private struct RingContainer: View {
    @ObservedObject var settings = SettingsStore.shared
    @ObservedObject var model: RingModel

    private var ringTheme: Theme { var t=settings.theme;t.drawsBackdrop=false;return t }
    @ViewBuilder var body: some View {
        if settings.quickAccessStyle == .metatron || settings.quickAccessStyle == .bubbles {
            MetatronOrbitView(model:model)
        } else {
            RingView(model:model,theme:ringTheme)
        }
    }
}

/// Shows, hides and routes input for the ring.
final class RingController {
    static let shared = RingController()

    let model = RingModel()
    private(set) var presentationID = UUID()
    private var panel: RingPanel?
    private var dropView: RingDropView?
    /// The frosted glass, drawn by AppKit with a round mask (SwiftUI-hosted blur showed a square).
    private let glass = RoundBlurView()
    private var hideWork: DispatchWorkItem?
    private var outsideClickMonitor: Any?

    /// Room around the disc for the shadow and the hint pill.
    private var margin: CGFloat { max(60, geometry.diameter * (RingGeometry.canvasScale - 1) / 2 + 10) }
    var documentationWindow: NSWindow? { panel?.isVisible == true && model.shown ? panel : nil }
    var isVisible: Bool { (panel?.isVisible == true && model.shown) || QuickAccessController.shared.isVisible }

    var isOrbit: Bool { [.metatron,.bubbles].contains(SettingsStore.shared.quickAccessStyle) }
    var orbit: OrbitGeometry { OrbitGeometry(size:SettingsStore.shared.ringSize,layout:SettingsStore.shared.quickAccessStyle == .bubbles ? .bubbles : .metatron) }

    var geometry: RingGeometry { RingGeometry(diameter: SettingsStore.shared.ringSize) }

    // MARK: Show / hide

    func show(files: [URL], at point: NSPoint, mode: RingModel.Mode) {
        hideWork?.cancel()
        presentationID = UUID()
        model.load(files: files)
        guard !model.isEmpty else {
            ToastCenter.shared.showInfo(L("Nothing to do with this file"), detail: files.first?.lastPathComponent)
            return
        }
        model.mode = mode
        if ![.ring,.metatron,.bubbles].contains(SettingsStore.shared.quickAccessStyle) {
            panel?.orderOut(nil)
            QuickAccessController.shared.show(model: model, at: point, style: SettingsStore.shared.quickAccessStyle, mode: mode)
            return
        }
        QuickAccessController.shared.hide()
        let panel = makePanelIfNeeded()
        panel.title = SettingsStore.shared.quickAccessStyle.title
        panel.acceptsMouseMovedEvents = true
        let side = isOrbit ? orbit.side : geometry.diameter + margin * 2
        var frame = NSRect(x: point.x - side / 2, y: point.y - side / 2, width: side, height: side)
        if let screen = NSScreen.screens.first(where: { NSMouseInRect(point, $0.frame, false) }) ?? NSScreen.main {
            let vf = screen.visibleFrame.insetBy(dx: isOrbit ? 8 : -margin + 8, dy: isOrbit ? 8 : -margin + 8)
            frame.origin.x = min(max(frame.minX, vf.minX), vf.maxX - side)
            frame.origin.y = min(max(frame.minY, vf.minY), vf.maxY - side)
        }
        panel.setFrame(frame, display: false)
        updateGlass()
        dropView?.resetModifierTracking()
        panel.allowsKey = mode == .click
        model.shown = false
        if mode == .click {
            if !isOrbit { NSApp.activate(ignoringOtherApps: true) }
            panel.makeKeyAndOrderFront(nil)
            panel.makeFirstResponder(dropView)
            installOutsideClickMonitor()
        } else {
            panel.orderFrontRegardless()
        }
        DispatchQueue.main.async { self.model.shown = true }
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0
            glass.animator().alphaValue = 1
        }
    }

    func hide(after delay: TimeInterval = 0) {
        if delay == 0 { QuickAccessController.shared.hide() }
        hideWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.model.shown = false
            self.removeOutsideClickMonitor()
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = 0
                self.glass.animator().alphaValue = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now()) {
                if !self.model.shown {
                    self.panel?.orderOut(nil)
                    self.model.progress = nil
                    self.model.finished = nil
                }
            }
        }
        hideWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }

    func togglePage() {
        model.togglePage()
        haptic()
    }

    // MARK: Input from the drop view

    func hover(_ hit: RingGeometry.Hit) {
        let index: Int?
        if case .slice(let i) = hit { index = i } else { index = nil }
        guard index != model.hovered else { return }
        model.hovered = index
        dropView?.toolTip = index.map { model.items[$0].title }
        if index != nil { haptic() }
    }

    func choose(_ index: Int, files: [URL]) {
        guard model.items.indices.contains(index), model.progress == nil else { return }
        let item = model.items[index]
        if let destination = item.destination { hide(); FileActions.move(files.isEmpty ? model.files : files, to: destination.folder); return }
        if let fileAction = item.fileAction { hide(); fileAction.perform(files.isEmpty ? model.files : files); return }
        if let recipe=item.recipe {hide();WorkspaceStore.shared.enqueue(inputs:files.isEmpty ? model.files : files,recipe:recipe);ToastCenter.shared.showInfo("Receta en cola",detail:recipe.name,actionTitle:"Ver actividad",action:{WorkbenchPresentation.show(section:"activity")});return}
        guard let action = item.action else { return }
        let files = files.isEmpty ? model.files : files
        model.chosen = index
        let needsEditor: Bool = { if case .tool(let t) = action { return t.needsEditor } else { return false } }()
        guard SettingsStore.shared.progressInRing, !needsEditor else {
            hide(after: 0.12)
            ActionRunner.shared.start(action, files: files)
            return
        }
        // Keep the ring up and show progress in its center, like a download ring.
        model.progress = -1
        removeOutsideClickMonitor()
        ActionRunner.shared.start(action, files: files, progress: { [weak self] fraction in
            self?.model.progress = fraction
        }, completion: { [weak self] success in
            guard let self else { return }
            self.model.finished = success
            self.hide(after: success ? 0.7 : 1.0)
        })
    }

    /// True while the ring is showing an action's progress (it must not close on mouse-up).
    var isBusy: Bool { model.progress != nil && model.finished == nil }

    func hubClicked() {
        if model.mode == .click { togglePage() }
    }

    // MARK: Helpers

    private func haptic() {
        guard SettingsStore.shared.haptics else { return }
        NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
    }

    /// Debug helper: saves what the ring window looks like on screen.
    func captureWindow(to url: URL) {
        guard let number = panel?.windowNumber,
              let handle = dlopen(nil, RTLD_NOW),
              let sym = dlsym(handle, "CGWindowListCreateImage") else { return }
        typealias Fn = @convention(c) (CGRect, UInt32, UInt32, UInt32) -> Unmanaged<CGImage>?
        let create = unsafeBitCast(sym, to: Fn.self)
        // Include what's below the ring so the glass and its edges are visible as users see them.
        guard let image = create(.null, 1 << 2 /* onScreenBelowWindow */ | 1 << 3 /* includingWindow */, UInt32(number), 1 << 0)?.takeRetainedValue() else { return }
        let rep = NSBitmapImageRep(cgImage: image)
        try? rep.representation(using: .png, properties: [:])?.write(to: url)
    }

    /// Builds the panel ahead of time so the first ⇧ shows the ring instantly.
    func prepare() {
        _ = makePanelIfNeeded()
    }

    private func updateGlass() {
        let settings = SettingsStore.shared
        if isOrbit { glass.isHidden=true;return }
        let d = geometry.diameter
        // Centered with constraints so it always sits exactly under the disc.
        glass.removeConstraints(glass.constraints)
        if let root = glass.superview {
            glass.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.deactivate(root.constraints.filter { $0.firstItem === glass || $0.secondItem === glass })
            NSLayoutConstraint.activate([
                glass.centerXAnchor.constraint(equalTo: root.centerXAnchor),
                glass.centerYAnchor.constraint(equalTo: root.centerYAnchor),
                glass.widthAnchor.constraint(equalToConstant: d),
                glass.heightAnchor.constraint(equalToConstant: d),
            ])
        }
        // A rounded layer is what actually clips a behind-window blur to a circle here
        // (maskImage is ignored in this transparent panel).
        glass.wantsLayer = true
        glass.layer?.cornerRadius = d / 2
        glass.layer?.cornerCurve = .circular
        glass.layer?.masksToBounds = true
        let dark: Bool = {
            switch settings.ringScheme {
            case .dark: return true
            case .light: return false
            case .system: return NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            }
        }()
        var native = settings.glassStyle == .frosted
        if settings.glassStyle == .liquid {
            // Liquid Glass is drawn by SwiftUI on macOS 26; older systems fall back to frosted.
            if #available(macOS 26.0, *) { native = false } else { native = true }
        }
        glass.isHidden = !native
        glass.material = dark ? .hudWindow : .popover
        glass.appearance = NSAppearance(named: dark ? .vibrantDark : .vibrantLight)
    }

    private func makePanelIfNeeded() -> RingPanel {
        if let panel { return panel }
        let p = RingPanel(contentRect: .init(x: 0, y: 0, width: 400, height: 400),
                          styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        p.isOpaque = false
        p.backgroundColor = .clear
        p.hasShadow = false
        p.level = .popUpMenu
        p.isFloatingPanel = true
        p.hidesOnDeactivate = false
        p.isReleasedWhenClosed = false
        p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        p.animationBehavior = .none

        let root = NSView()
        glass.blendingMode = .behindWindow
        glass.state = .active
        glass.alphaValue = 0
        root.addSubview(glass)
        let host = NSHostingView(rootView: RingContainer(model: model))
        host.translatesAutoresizingMaskIntoConstraints = false
        let drop = RingDropView(controller: self)
        drop.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(host)
        root.addSubview(drop)
        for v in [host, drop] {
            NSLayoutConstraint.activate([
                v.leadingAnchor.constraint(equalTo: root.leadingAnchor),
                v.trailingAnchor.constraint(equalTo: root.trailingAnchor),
                v.topAnchor.constraint(equalTo: root.topAnchor),
                v.bottomAnchor.constraint(equalTo: root.bottomAnchor),
            ])
        }
        p.contentView = root
        panel = p
        dropView = drop
        return p
    }

    private func installOutsideClickMonitor() {
        removeOutsideClickMonitor()
        outsideClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.hide()
        }
    }

    func removeOutsideClickMonitor() {
        if let m = outsideClickMonitor { NSEvent.removeMonitor(m) }
        outsideClickMonitor = nil
    }
}

/// Transparent view on top of the ring: receives the drop, hover and clicks.
final class RingDropView: NSView {
    private unowned let controller: RingController
    private var tracking: NSTrackingArea?
    private var triggerKeyDown = false
    func resetModifierTracking() { triggerKeyDown=NSEvent.modifierFlags.contains(SettingsStore.shared.triggerKey.flag) }

    init(controller: RingController) {
        self.controller = controller
        super.init(frame: .zero)
        registerForDraggedTypes([.fileURL])
    }

    required init?(coder: NSCoder) { fatalError() }

    override var isFlipped: Bool { true }
    override var acceptsFirstResponder: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let tracking { removeTrackingArea(tracking) }
        let t = NSTrackingArea(rect: .zero, options: [.mouseMoved, .mouseEnteredAndExited, .activeAlways, .inVisibleRect], owner: self)
        addTrackingArea(t)
        tracking = t
    }

    private func hit(_ windowPoint: NSPoint) -> RingGeometry.Hit {
        let p = convert(windowPoint, from: nil)
        let rel = CGPoint(x: p.x - bounds.midX, y: p.y - bounds.midY)
        if controller.isOrbit {
            switch controller.orbit.hit(rel,count:controller.model.items.count) {
            case .hub:return .hub
            case .action(let index):return .slice(index)
            case .outside:return .outside
            }
        }
        return controller.geometry.hit(rel, count: controller.model.items.count)
    }

    // Dragging
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        let target=hit(sender.draggingLocation)
        controller.hover(target)
        if controller.isOrbit { if case .slice = target { return .copy }; return [] }
        return .copy
    }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        let target=hit(sender.draggingLocation)
        controller.hover(target)
        if controller.isOrbit { if case .slice = target { return .copy }; return [] }
        return .copy
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        controller.hover(.outside)
    }

    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool { true }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        guard case .slice(let index) = hit(sender.draggingLocation) else {
            controller.hide()
            return false
        }
        let urls = (sender.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL]) ?? []
        controller.choose(index, files: urls)
        return true
    }

    // Clicking (Open With, menu bar, Services)
    override func mouseMoved(with event: NSEvent) {
        controller.hover(hit(event.locationInWindow))
    }

    override func mouseExited(with event: NSEvent) {
        controller.hover(.outside)
    }

    override func mouseDown(with event: NSEvent) {
        switch hit(event.locationInWindow) {
        case .slice(let i): controller.choose(i, files: [])
        case .hub: controller.hubClicked()
        case .outside: controller.hide()
        }
    }

    override func rightMouseDown(with event: NSEvent) {
        controller.togglePage()
    }

    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 53: controller.hide() // Esc
        case 48, 49: controller.togglePage() // Tab, Space
        default: super.keyDown(with: event)
        }
    }

    override func flagsChanged(with event: NSEvent) {
        let flag=SettingsStore.shared.triggerKey.flag
        let down=event.modifierFlags.contains(flag)
        let modifiers=event.modifierFlags.intersection([.shift,.option,.command,.control])
        if down && !triggerKeyDown && modifiers == flag { controller.togglePage() }
        triggerKeyDown=down
    }
}
