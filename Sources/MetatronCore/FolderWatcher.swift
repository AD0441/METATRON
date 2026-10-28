import Foundation
import Darwin

/// Reports new regular files after size and modification time stay unchanged
/// for three samples. Pausing invalidates every pending stability check.
public final class FolderWatcher: @unchecked Sendable {
    public let folder: URL
    private let onFile: @Sendable (URL) -> Void
    private let onError: @Sendable (String) -> Void
    private let interval: TimeInterval
    private let queue = DispatchQueue(label: "metatron.watch", qos: .utility)
    private let queueKey = DispatchSpecificKey<Bool>()
    private var source: DispatchSourceFileSystemObject?
    private var known: Set<String> = []
    private var ignored: Set<String> = []
    private var pending: Set<String> = []
    private var generation = 0

    public convenience init(folder: URL, onError: @escaping @Sendable (String) -> Void = { _ in }, onFile: @escaping @Sendable (URL) -> Void) {
        self.init(folder: folder, interval: 1, onError: onError, onFile: onFile)
    }
    init(folder: URL, interval: TimeInterval, onError: @escaping @Sendable (String) -> Void = { _ in }, onFile: @escaping @Sendable (URL) -> Void) {
        self.folder = folder; self.interval = interval; self.onFile = onFile; self.onError = onError
        queue.setSpecific(key: queueKey, value: true)
    }
    deinit { stop() }

    /// Existing files are a baseline, including arrivals made while paused.
    @discardableResult public func start() -> Bool {
        synchronized {
            guard source == nil else { return true }
            do {
                known = Set(try FileManager.default.contentsOfDirectory(atPath: folder.path))
                let values = try folder.resourceValues(forKeys: [.isDirectoryKey])
                guard values.isDirectory == true else { throw MetatronError.unreadable(folder) }
            } catch { onError("No se pudo vigilar \(folder.lastPathComponent): \(error.localizedDescription)"); return false }
            let fd = open(folder.path, O_EVTONLY | O_CLOEXEC)
            guard fd >= 0 else { onError("No se pudo abrir la carpeta \(folder.lastPathComponent)."); return false }
            generation += 1
            let src = DispatchSource.makeFileSystemObjectSource(fileDescriptor: fd, eventMask: [.write, .rename, .delete, .revoke, .link], queue: queue)
            src.setEventHandler { [weak self] in
                guard let self else { return }
                if !src.data.intersection([.rename, .delete, .revoke]).isEmpty {
                    self.stop()
                    self.onError("La carpeta \(self.folder.lastPathComponent) se movió o dejó de estar disponible. Vuelve a seleccionarla en Ajustes.")
                } else { self.scan() }
            }
            src.setCancelHandler { close(fd) }
            source = src; src.resume()
            // Covers arrivals between the baseline read and event registration.
            scan()
            return true
        }
    }
    public func stop() {
        synchronized {
            generation += 1
            source?.setEventHandler {}; source?.cancel(); source = nil
            pending.removeAll()
        }
    }
    public func ignore(_ urls: [URL]) { synchronized { ignored.formUnion(urls.map(\.lastPathComponent)) } }

    private func synchronized<T>(_ body: () -> T) -> T {
        if DispatchQueue.getSpecific(key: queueKey) == true { return body() }
        return queue.sync(execute: body)
    }
    private func scan() {
        guard source != nil else { return }
        guard let entries = try? FileManager.default.contentsOfDirectory(atPath: folder.path) else {
            stop(); onError("No se puede leer la carpeta \(folder.lastPathComponent)."); return
        }
        let names = Set(entries)
        let fresh = names.subtracting(known).filter { !$0.hasPrefix(".") && !ignored.contains($0) }
        known = names
        for name in fresh where pending.insert(name).inserted {
            sample(folder.appendingPathComponent(name), previous: nil, stable: 0, attempts: 0, generation: generation)
        }
    }
    private struct Stamp: Equatable { let bytes: Int; let modified: Date? }
    private func sample(_ url: URL, previous: Stamp?, stable: Int, attempts: Int, generation expected: Int) {
        queue.asyncAfter(deadline: .now() + interval) { [weak self] in
            guard let self, self.source != nil, expected == self.generation else { return }
            let name = url.lastPathComponent
            guard !self.ignored.contains(name),
                  !["download", "crdownload", "part", "tmp"].contains(url.pathExtension.lowercased()),
                  let values = try? url.resourceValues(forKeys: [.isRegularFileKey, .isSymbolicLinkKey, .fileSizeKey, .contentModificationDateKey]),
                  values.isRegularFile == true, values.isSymbolicLink != true else {
                self.pending.remove(name); return
            }
            let stamp = Stamp(bytes: values.fileSize ?? 0, modified: values.contentModificationDate)
            let count = stamp == previous ? stable + 1 : 0
            if count >= 2, stamp.bytes > 0 {
                self.pending.remove(name); self.onFile(url)
            } else if attempts < 600 {
                self.sample(url, previous: stamp, stable: count, attempts: attempts + 1, generation: expected)
            } else { self.pending.remove(name); self.onError("El archivo \(name) no terminó de copiarse dentro del tiempo límite.") }
        }
    }
}

/// A folder plus what to do with files that arrive in it.
public struct WatchRule: Codable, Hashable, Identifiable, Sendable {
    public var id = UUID()
    public var folder: String
    /// A `KQAction.id`, e.g. "convert.jpg" or "tool.compress".
    public var action: String
    /// Move each original into an "Originals" subfolder after converting.
    public var moveOriginals: Bool = false
    public var enabled: Bool = true

    public init(folder: String, action: String, moveOriginals: Bool = false) {
        self.folder = folder
        self.action = action
        self.moveOriginals = moveOriginals
    }

    /// Whether this rule's action makes sense for the file (a JPG rule ignores PDFs, etc.).
    public func applies(to url: URL, engines: Engines = .current) -> KQAction? {
        let urls = [url]
        let all = ActionCatalog.convertActions(for: urls, engines: engines) + ActionCatalog.toolActions(for: urls, engines: engines)
        return all.first { $0.id == action }
    }
}

extension KQAction {
    /// The action for a stored id such as "convert.jpg".
    public init?(id: String) {
        let parts = id.split(separator: ".", maxSplits: 1).map(String.init)
        guard parts.count == 2 else { return nil }
        switch parts[0] {
        case "convert": guard let f = OutputFormat(rawValue: parts[1]) else { return nil }; self = .convert(f)
        case "tool": guard let t = ToolID(rawValue: parts[1]) else { return nil }; self = .tool(t)
        default: return nil
        }
    }
}
