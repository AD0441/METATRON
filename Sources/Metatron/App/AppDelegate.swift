import AppKit
import Combine
import MetatronCore
import MetatronWorkflow
import SwiftUI
import os

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    static weak var current:AppDelegate?
    private let logger=Logger(subsystem:"local.metatron.app",category:"lifecycle")
    private let monitor = DragMonitor()
    private var instanceLease: InstanceLease?
    private var duplicateLaunch = false
    private var reopenObserver: NSObjectProtocol?
    private var statusItem: NSStatusItem?
    private var cancellables: Set<AnyCancellable> = []
    private let settings = SettingsStore.shared
    private let statusDrop = StatusDropTarget()

    func applicationWillFinishLaunching(_ notification:Notification) {
        Self.current=self
        claimInstance()
    }
    private func claimInstance() {
        guard instanceLease == nil,!duplicateLaunch else {return}
        do { instanceLease=try InstanceLease(url:URL.applicationSupportDirectory.appendingPathComponent("METATRON/instance.lock")) }
        catch {
            duplicateLaunch=true
            DistributedNotificationCenter.default().postNotificationName(.init("local.metatron.reopen"),object:nil,userInfo:nil,deliverImmediately:true)
            NSRunningApplication.runningApplications(withBundleIdentifier:Bundle.main.bundleIdentifier ?? "local.metatron.app")
                .first { $0.processIdentifier != ProcessInfo.processInfo.processIdentifier }?.activate()
            NSApp.terminate(nil)
        }
    }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender:NSApplication)->Bool {false}
    func applicationWillTerminate(_ notification:Notification) {if !duplicateLaunch {WorkspaceStore.shared.persist()}}
    func menuNeedsUpdate(_ menu:NSMenu) {
        guard menu === statusItem?.menu else{return}
        let current=makeMenu()
        menu.removeAllItems()
        for entry in current.items {current.removeItem(entry);menu.addItem(entry)}
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        Self.current=self
        claimInstance()
        guard !duplicateLaunch else { NSApp.terminate(nil);return }
        NSApp.setActivationPolicy(settings.showDockIcon ? .regular : .accessory)
        reopenObserver=DistributedNotificationCenter.default().addObserver(forName:.init("local.metatron.reopen"),object:nil,queue:.main) { _ in MainActor.assumeIsolated { WorkbenchPresentation.show() } }
        // Look for optional engines early, off the main thread.
        DispatchQueue.global(qos: .utility).async { _ = Engines.current }
        setUpStatusItem()
        setUpMonitor()
        NSApp.servicesProvider = self
        NSUpdateDynamicServices()
        if #available(macOS 15, *) {MetatronShortcuts.updateAppShortcutParameters()}

        WatchService.shared.start()
        RingController.shared.prepare()
        Hotkey.shared.setEnabled(settings.hotkeyEnabled)
        UpdateChecker.shared.onChange = { [weak self] in self?.statusItem?.menu = self?.makeMenu() }


        // Rebuild the menu when the language changes.
        settings.objectWillChange
            .debounce(for: .milliseconds(50), scheduler: RunLoop.main)
            .sink { [weak self] in self?.statusItem?.menu = self?.makeMenu() }
            .store(in: &cancellables)
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        WorkbenchPresentation.show()
        return true
    }

    /// "Open With → Metatron" and drops on the Dock icon show the ring in click mode.
    func application(_ application: NSApplication, open urls: [URL]) {
        RingController.shared.show(files: urls, at: NSEvent.mouseLocation, mode: .click)
    }

    // MARK: Drag gesture

    private func setUpMonitor() {
        monitor.onTriggerDown = { urls in
            guard !SettingsStore.shared.paused else { return }
            let ring = RingController.shared
            if ring.isVisible, self.monitor.requestedPage == 0 {
                ring.togglePage()
            } else {
                ring.show(files: urls, at: NSEvent.mouseLocation, mode: .drag)
                ring.model.page = self.monitor.requestedPage
            }
        }
        monitor.onTriggerUp = {
            if SettingsStore.shared.triggerMode == .hold, !RingController.shared.isBusy { RingController.shared.hide() }
        }
        monitor.onDragEnded = {
            // Give the drop a moment to land before the ring goes away.
            let ring = RingController.shared
            if ring.model.mode == .drag, !ring.isBusy {
                // Hide unless the drop just started an action shown in the ring.
                let presentation = ring.presentationID
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { if !ring.isBusy, ring.presentationID == presentation { ring.hide() } }
            }
        }
        monitor.start()
    }

    // MARK: Menu bar

    private func setUpStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = StatusIcon.make()
        item.button?.toolTip = "METATRON"
        item.menu = makeMenu()
        statusItem = item
        // Files dropped on the menu bar icon open the ring.
        if let window = item.button?.window {
            window.registerForDraggedTypes([.fileURL])
            window.delegate = statusDrop
        }
    }

    private func makeMenu() -> NSMenu {
        let menu = NSMenu()
        menu.delegate=self
        let header = NSMenuItem(title: settings.paused ? L("Metatron is paused") : L("Drag a file a little, then tap %@", settings.triggerKey.symbol), action: nil, keyEquivalent: "")
        header.isEnabled = false
        menu.addItem(header)
        menu.addItem(.separator())
        if let version = UpdateChecker.shared.available {
            let update = item(L("Update to Metatron %@…", version), #selector(installUpdate), "")
            update.image = NSImage(systemSymbolName: "arrow.down.circle.fill", accessibilityDescription: nil)
            menu.addItem(update)
            menu.addItem(.separator())
        }
        menu.addItem(item("Abrir METATRON", #selector(openWorkbench), "1"))
        menu.addItem(item("Recetas…", #selector(openRecipes), "r"))
        menu.addItem(item("Actividad…", #selector(openActivity), ""))
        let jobs=WorkspaceStore.shared.jobs.count { $0.state == .queued || $0.state == .running }
        if jobs > 0 { let summary=NSMenuItem(title:"\(jobs) trabajos en curso o pendientes",action:nil,keyEquivalent:"");summary.isEnabled=false;menu.addItem(summary) }
        menu.addItem(item(L("Convert a File…"), #selector(chooseFile), "o"))
        menu.addItem(item(L("Convert Finder Selection") + (settings.hotkeyEnabled ? "  " + Hotkey.display : ""), #selector(convertSelection), ""))
        let recent = NSMenuItem(title: L("Recent"), action: nil, keyEquivalent: "")
        let sub = NSMenu()
        let paths = settings.recents.filter { FileManager.default.fileExists(atPath: $0) }
        for path in paths.prefix(10) {
            let entry = NSMenuItem(title: (path as NSString).lastPathComponent, action: #selector(revealRecent(_:)), keyEquivalent: "")
            entry.target = self
            entry.representedObject = path
            entry.image = NSWorkspace.shared.icon(forFile: path)
            entry.image?.size = NSSize(width: 16, height: 16)
            entry.toolTip = path
            sub.addItem(entry)
        }
        if paths.isEmpty {
            let none = NSMenuItem(title: L("Nothing yet"), action: nil, keyEquivalent: "")
            none.isEnabled = false
            sub.addItem(none)
        } else {
            sub.addItem(.separator())
            sub.addItem(item(L("Clear"), #selector(clearRecents), ""))
        }
        recent.submenu = sub
        menu.addItem(recent)
        menu.addItem(item(settings.paused ? "Reanudar automatizaciones" : "Pausar automatizaciones", #selector(togglePause), "p"))
        menu.addItem(.separator())
        menu.addItem(item("Dejar en segundo plano (ocultar Dock)",#selector(background),""))
        menu.addItem(item(settings.showDockIcon ? "Ocultar icono del Dock" : "Mostrar icono en el Dock",#selector(toggleDock),""))
        menu.addItem(item(L("Settings…"), #selector(openSettings), ","))
        menu.addItem(item(L("Welcome Screen"), #selector(openWelcome), ""))
        menu.addItem(item(L("Check for Updates…"), #selector(checkUpdates), ""))
        menu.addItem(.separator())
        menu.addItem(item("Salir METATRON completamente", #selector(quit), "q"))
        return menu
    }

    private func item(_ title: String, _ action: Selector, _ key: String) -> NSMenuItem {
        let i = NSMenuItem(title: title, action: action, keyEquivalent: key)
        i.target = self
        return i
    }

    @objc private func chooseFile() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.prompt = L("Choose")
        NSApp.activate(ignoringOtherApps: true)
        guard panel.runModal() == .OK, !panel.urls.isEmpty else { return }
        RingController.shared.show(files: panel.urls, at: NSEvent.mouseLocation, mode: .click)
    }

    func showStatusMenu() {
        logger.notice("Status controls requested; status item available: \(self.statusItem != nil)")
        let menu=makeMenu()
        let frame=statusItem?.button?.window?.frame
        let point=frame.map {NSPoint(x:$0.minX,y:$0.minY)} ?? NSEvent.mouseLocation
        // Finish tracking the application menu before opening the status controls.
        DispatchQueue.main.async {menu.popUp(positioning:nil,at:point,in:nil)}
    }

    @objc private func openWorkbench() { WorkbenchPresentation.show() }
    @objc private func openRecipes() { WorkbenchPresentation.show(section:"recipes") }
    @objc private func openActivity() { WorkbenchPresentation.show(section:"activity") }
    @objc private func background() { WorkbenchPresentation.enterBackground() }
    @objc private func toggleDock() { settings.showDockIcon.toggle();NSApp.setActivationPolicy(settings.showDockIcon ? .regular : .accessory) }
    @objc private func togglePause() { settings.paused.toggle() }
    @objc private func openSettings() { SettingsWindowController.shared.show() }
    @objc private func openWelcome() { OnboardingWindow.show() }
    @objc private func checkUpdates() { UpdateChecker.shared.check(userInitiated: true) }
    @objc private func installUpdate() { UpdateChecker.shared.installUpdate() }
    @objc private func convertSelection() { Hotkey.openForFinderSelection() }
    @objc private func clearRecents() { settings.recents = [] }
    @objc private func revealRecent(_ sender: NSMenuItem) {
        guard let path = sender.representedObject as? String else { return }
        NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: path)])
    }
    @objc private func quit() { NSApp.terminate(nil) }

    // MARK: Services ("Convert with Metatron" in Finder's right-click menu)

    @objc func convertFiles(_ pboard: NSPasteboard, userData: String?, error: AutoreleasingUnsafeMutablePointer<NSString?>) {
        let urls = (pboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL]) ?? []
        guard !urls.isEmpty else { return }
        DispatchQueue.main.async {
            RingController.shared.show(files: urls, at: NSEvent.mouseLocation, mode: .click)
        }
    }
}

/// Receives files dropped on the menu bar icon.
final class StatusDropTarget: NSObject, NSWindowDelegate, NSDraggingDestination {
    func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation { .copy }

    func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let urls = (sender.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL]) ?? []
        guard !urls.isEmpty else { return false }
        DispatchQueue.main.async {
            // Open just below the icon so the ring doesn't cover the menu bar.
            var point = NSEvent.mouseLocation
            point.y -= SettingsStore.shared.ringSize / 2 + 20
            RingController.shared.show(files: urls, at: point, mode: .click)
        }
        return true
    }
}

/// The menu bar glyph: a little segmented ring.
enum StatusIcon {
    static func make() -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: false) { rect in
            let c = NSPoint(x:rect.midX,y:rect.midY), radius:CGFloat=5.8
            let points = Array(MetatronGeometry.centers.prefix(7)).map {NSPoint(x:c.x+$0.x*radius,y:c.y+$0.y*radius)}
            let lines=NSBezierPath();lines.lineWidth=0.55
            for a in 0..<points.count {for b in (a+1)..<points.count {lines.move(to:points[a]);lines.line(to:points[b])}}
            NSColor.black.withAlphaComponent(0.7).setStroke();lines.stroke()
            NSColor.black.setStroke()
            for point in points {let circle=NSBezierPath(ovalIn:NSRect(x:point.x-1.45,y:point.y-1.45,width:2.9,height:2.9));circle.lineWidth=0.8;circle.stroke()}
            return true
        }
        image.isTemplate = true
        return image
    }
}
