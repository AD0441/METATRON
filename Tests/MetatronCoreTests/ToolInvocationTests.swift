import Testing
import Foundation
import Darwin
@testable import MetatronCore

struct ToolInvocationTests {
    private let shell = URL(fileURLWithPath: "/bin/sh")

    @Test func capturesOutputEnvironmentAndWorkingDirectory() async throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let result = try await Engines.run(shell, ["-c", "printf '%s\\n' \"$METATRON_TEST_VALUE\"; pwd"], currentDirectory: folder, environment: ["METATRON_TEST_VALUE": "hello world"])
        #expect(result.contains("hello world"))
        #expect(result.contains(folder.resolvingSymlinksInPath().path))
    }

    @Test func reportsTheLastErrorLines() async {
        do { try await Engines.run(shell, ["-c", "printf 'first\\nsecond\\nthird\\n' >&2; exit 7"]); Issue.record("Expected failure") }
        catch MetatronError.toolFailed(let tool, let message) {
            #expect(tool == "sh"); #expect(message == "second third")
        } catch { Issue.record("Unexpected error: \(error)") }
    }

    @Test func drainsLargeSimultaneousStreamsWithoutHanging() async throws {
        let output = try await Engines.run(shell, ["-c", "i=0; while [ $i -lt 20000 ]; do printf '1234567890123456789012345678901234567890123456789012345678901234567890\\n'; printf 'error-line\\n' >&2; i=$((i+1)); done"], timeout: 15)
        #expect(output.utf8.count <= 1_048_576)
        #expect(output.hasSuffix("\n"))
    }

    @Test func missingExecutableDoesNotLeaveAContinuationOrTimer() async {
        await #expect(throws: (any Error).self) {
            try await Engines.run(URL(fileURLWithPath: "/nonexistent/metatron-test-tool"), [], timeout: 1)
        }
    }

    @Test(.timeLimit(.minutes(1))) func cancellationBeforeLaunchHasNoSideEffects() async throws {
        let marker = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await Engines.run(shell, ["-c", "touch \"$1\"", "test", marker.path])
        }
        await #expect(throws: CancellationError.self) { try await task.value }
        #expect(FileManager.default.fileExists(atPath: marker.path) == false)
    }

    @Test(.timeLimit(.minutes(1)), arguments: [false, true])
    func stopsTheProcessAndItsHelperEvenWhenTheyIgnoreTERM(timeout: Bool) async throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let marker = folder.appendingPathComponent("pids")
        let command = "trap '' TERM; (trap '' TERM; exec /bin/sleep 60) & child=$!; printf '%s %s' \"$$\" \"$child\" > \"$1\"; wait"
        let task = Task { try await Engines.run(shell, ["-c", command, "test", marker.path], timeout: timeout ? 1 : 30) }
        defer { task.cancel() }
        try await waitUntil { FileManager.default.fileExists(atPath: marker.path) }
        let pids = try String(contentsOf: marker, encoding: .utf8).split(separator: " ").compactMap { Int32($0) }
        #expect(pids.count == 2)
        let start = ContinuousClock.now
        if !timeout { task.cancel() }
        do { _ = try await task.value; Issue.record("The process should stop with an error") }
        catch is CancellationError { #expect(timeout == false) }
        catch MetatronError.toolTimedOut { #expect(timeout) }
        catch { Issue.record("Unexpected error: \(error)") }
        #expect(start.duration(to: .now) < .seconds(5))
        try await waitUntil { pids.allSatisfy { kill($0, 0) == -1 && errno == ESRCH } }
        #expect(pids.allSatisfy { kill($0, 0) == -1 })
    }

    private func waitUntil(_ predicate: () -> Bool) async throws {
        let limit = ContinuousClock.now.advanced(by: .seconds(5))
        while !predicate(), ContinuousClock.now < limit { try await Task.sleep(for: .milliseconds(20)) }
        try #require(predicate(), "Expected process/file state was not reached")
    }
}
