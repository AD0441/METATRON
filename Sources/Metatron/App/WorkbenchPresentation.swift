import AppKit
import SwiftUI

@MainActor enum WorkbenchPresentation {
    private static var window:NSWindow?
    private static var pending=false
    static func attach(_ value:NSWindow) {
        window=value;value.isReleasedWhenClosed=false
        if pending {pending=false;show()}
        else if SettingsStore.shared.startInBackground {value.orderOut(nil)}
    }
    static func show(section:String?=nil) {
        if let section {WorkspaceStore.shared.selectedSection=section}
        guard let window else {pending=true;return}
        NSApp.setActivationPolicy(SettingsStore.shared.showDockIcon ? .regular : .accessory)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps:true)
    }
    static func hide() {window?.orderOut(nil)}
    static func enterBackground() {
        RingController.shared.hide()
        SettingsWindowController.shared.hide()
        hide()
        for window in NSApp.windows where window.styleMask.contains(.titled) {window.orderOut(nil)}
        SettingsStore.shared.startInBackground=true
        SettingsStore.shared.showDockIcon=false
        NSApp.setActivationPolicy(.accessory)
    }
}
struct WorkbenchWindowCapture:NSViewRepresentable {
    func makeNSView(context:Context)->WindowReferenceView {WindowReferenceView()}
    func updateNSView(_ view:WindowReferenceView,context:Context) {}
}
final class WindowReferenceView:NSView {
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if let window {WorkbenchPresentation.attach(window)}
    }
}
