import AppKit

/// Opt-in documentation capture of this app's own views; never captures the desktop or another app.
enum DemoCapture {
    static var directory: URL? {
        guard let i = CommandLine.arguments.firstIndex(of: "--demo-capture-dir"), CommandLine.arguments.count > i + 1 else { return nil }
        return URL(fileURLWithPath:CommandLine.arguments[i+1],isDirectory:true)
    }
    static func take() {
        guard let directory, let window=RingController.shared.documentationWindow ?? NSApp.keyWindow ?? NSApp.windows.first(where: { $0.isVisible }),
              window.contentView != nil else{return}
        guard !(window is NSOpenPanel), !(window is NSSavePanel) else { return }
        let data: Data?
        // Capture only this application's selected window. The legacy function is dynamically
        // optional because recent SDKs removed its declaration; no permission setting is changed.
        if let handle=dlopen(nil,RTLD_NOW) {
            defer { dlclose(handle) }
            typealias Capture = @convention(c) (CGRect,UInt32,UInt32,UInt32)->Unmanaged<CGImage>?
            if let symbol=dlsym(handle,"CGWindowListCreateImage"),
               let image=unsafeBitCast(symbol,to:Capture.self)(.null,1 << 3,UInt32(window.windowNumber),1 << 0)?.takeRetainedValue() {
                data=NSBitmapImageRep(cgImage:image).representation(using:.png,properties:[:])
            } else { data=nil }
        } else { data=nil }
        guard let data else {
            NSLog("METATRON: own-window documentation capture unavailable; no partial image exported.")
            return
        }
        let name: String
        if window is RingPanel || window is ActionPanel {name="access-"+SettingsStore.shared.quickAccessStyle.rawValue}
        else if window.title.isEmpty || window.title.contains("Ajustes") || window.title == "Settings" {name="settings"}
        else {name=window.title.lowercased().replacingOccurrences(of:"[^a-z0-9]+",with:"-",options:.regularExpression)}
        do {try FileManager.default.createDirectory(at:directory,withIntermediateDirectories:true);try data.write(to:directory.appendingPathComponent(name+".png"),options:.atomic)}
        catch {NSLog("METATRON documentation capture: %@",error.localizedDescription)}
    }
}
