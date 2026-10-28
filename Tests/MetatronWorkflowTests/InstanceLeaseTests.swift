import Testing
import Foundation
@testable import MetatronWorkflow

struct InstanceLeaseTests {
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
