import Testing
import Foundation
@testable import MetatronWorkflow

struct InstanceLeaseTests {
    @Test func unavailablePathIsNotReportedAsAnotherInstance() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        try Data("file, not directory".utf8).write(to: root)
        do { _ = try InstanceLease(url: root.appendingPathComponent("instance.lock")); Issue.record("Expected an unavailable path") }
        catch { #expect((error as? InstanceLeaseError) != .alreadyRunning) }
    }
    @Test func onlyOneLeaseCanOwnTheInstanceLock() throws {
        let root=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer {try? FileManager.default.removeItem(at:root)}
        let lock=root.appendingPathComponent("instance.lock")
        var first:InstanceLease?=try InstanceLease(url:lock)
        _ = withExtendedLifetime(first) { #expect(throws:InstanceLeaseError.alreadyRunning) {try InstanceLease(url:lock)} }
        first=nil
        let restarted=try InstanceLease(url:lock)
        withExtendedLifetime(restarted) {}
        #expect(first == nil)
    }
}
