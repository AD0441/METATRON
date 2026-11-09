import Testing
import Foundation
@testable import MetatronCore

private final class WatchedFiles: @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [URL] = []
    func receive(_ url: URL) { lock.lock(); defer { lock.unlock() }; storage.append(url) }
    var files: [URL] { lock.lock(); defer { lock.unlock() }; return storage }
}
struct FolderWatcherTests {
    @Test(.timeLimit(.minutes(1))) func reportsStableArrivalsOnceAndIgnoresExistingOrTemporaryFiles() async throws {
        let root = try directory(); defer { try? FileManager.default.removeItem(at: root) }
        try Data("existing".utf8).write(to: root.appendingPathComponent("old.txt"))
        let received = WatchedFiles()
        let watcher = FolderWatcher(folder: root, interval: 0.05, onFile: received.receive)
        #expect(watcher.start()); #expect(watcher.start())
        defer { watcher.stop() }
        try Data("temporary".utf8).write(to: root.appendingPathComponent("partial.part"))
        try FileManager.default.createDirectory(at: root.appendingPathComponent("subfolder"), withIntermediateDirectories: true)
        let input = root.appendingPathComponent("new.txt")
        try Data("first".utf8).write(to: input)
        try await Task.sleep(for: .milliseconds(70))
        try Data("second-chunk".utf8).write(to: input)
        try await waitUntil { received.files.count == 1 }
        try await Task.sleep(for: .milliseconds(200))
        #expect(received.files == [input])
    }

    @Test(.timeLimit(.minutes(1))) func stoppingInvalidatesChecksAndRestartDoesNotReplayPausedArrivals() async throws {
        let root = try directory(); defer { try? FileManager.default.removeItem(at: root) }
        let received = WatchedFiles()
        let watcher = FolderWatcher(folder: root, interval: 0.05, onFile: received.receive)
        #expect(watcher.start()); defer { watcher.stop() }
        try Data("first".utf8).write(to: root.appendingPathComponent("cancel.txt"))
        try await Task.sleep(for: .milliseconds(60))
        watcher.stop()
        try Data("paused".utf8).write(to: root.appendingPathComponent("paused.txt"))
        try await Task.sleep(for: .milliseconds(200))
        #expect(received.files.isEmpty)
        #expect(watcher.start())
        let last = root.appendingPathComponent("after-resume.txt")
        try Data("new arrival".utf8).write(to: last)
        try await waitUntil { received.files.count == 1 }
        #expect(received.files == [last])
    }

    @Test(.timeLimit(.minutes(1))) func burstProducesOneEventPerFile() async throws {
        let root = try directory(); defer { try? FileManager.default.removeItem(at: root) }
        let received = WatchedFiles()
        let watcher = FolderWatcher(folder: root, interval: 0.03, onFile: received.receive)
        #expect(watcher.start()); defer { watcher.stop() }
        for index in 0..<25 { try Data("test".utf8).write(to: root.appendingPathComponent("\(index).txt")) }
        try await waitUntil { received.files.count == 25 }
        #expect(Set(received.files).count == 25)
    }

    @Test func unavailableFolderReportsStartupFailure() {
        let watcher = FolderWatcher(folder: URL(fileURLWithPath: "/nonexistent/metatron-watch-test")) { _ in Issue.record("No files expected") }
        #expect(watcher.start() == false)
        watcher.stop()
    }
    private func directory() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true); return url
    }
    private func waitUntil(_ predicate: () -> Bool) async throws {
        let limit = ContinuousClock.now.advanced(by: .seconds(5))
        while !predicate(), ContinuousClock.now < limit { try await Task.sleep(for: .milliseconds(20)) }
        try #require(predicate(), "The folder event was not delivered")
    }
}
