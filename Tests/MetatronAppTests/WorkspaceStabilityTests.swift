import Testing
import Foundation
import MetatronCore
import MetatronWorkflow
@testable import Metatron

@MainActor struct WorkspaceStabilityTests {
    @Test(.timeLimit(.minutes(1))) func shutdownCancelsActiveAndPendingWorkAndDrainsCallbacks() async throws {
        let folder = try makeDirectory(); defer { try? FileManager.default.removeItem(at: folder) }
        let store = slowStore(folder)
        var callbacks = 0
        store.enqueue(inputs: [folder.appendingPathComponent("one.txt"), folder.appendingPathComponent("two.txt")], recipe: recipe) { _ in callbacks += 1 }
        try await waitUntil { store.jobs.contains { $0.state == .running } }
        await store.shutDown()
        #expect(store.isRunning == false)
        #expect(store.jobs.count == 2)
        #expect(store.jobs.allSatisfy { $0.state == .cancelled })
        #expect(callbacks == 2)
        #expect(store.enqueue(inputs: [folder.appendingPathComponent("three.txt")], recipe: recipe).isEmpty)
        #expect(store.jobs.count == 2)
        let recovered = WorkspaceStore(directory: folder)
        #expect(recovered.jobs.allSatisfy { $0.state == .cancelled })
    }

    @Test(.timeLimit(.minutes(1))) func cancellingAnIntentOnlyCancelsItsOwnBatch() async throws {
        let folder = try makeDirectory(); defer { try? FileManager.default.removeItem(at: folder) }
        let store = slowStore(folder)
        let task = Task { try await store.runRecipe(inputs: [folder.appendingPathComponent("one.txt"), folder.appendingPathComponent("two.txt")], recipe: recipe) }
        try await waitUntil { store.jobs.contains { $0.state == .running } }
        store.enqueue(inputs: [folder.appendingPathComponent("independent.txt")], recipe: recipe)
        task.cancel()
        await #expect(throws: CancellationError.self) { try await task.value }
        try await waitUntil { store.jobs.contains { $0.inputs.first?.lastPathComponent == "independent.txt" && $0.state == .running } }
        #expect(store.jobs.filter { $0.state == .cancelled }.count == 2)
        await store.shutDown()
    }

    @Test(.timeLimit(.minutes(1))) func cancellingCurrentJobContinuesTheIndependentQueue() async throws {
        let folder = try makeDirectory(); defer { try? FileManager.default.removeItem(at: folder) }
        let store = slowStore(folder)
        store.enqueue(inputs: [folder.appendingPathComponent("first.txt"), folder.appendingPathComponent("second.txt")], recipe: recipe)
        try await waitUntil { store.jobs.contains { $0.inputs.first?.lastPathComponent == "first.txt" && $0.state == .running } }
        store.cancel()
        try await waitUntil { store.jobs.contains { $0.inputs.first?.lastPathComponent == "second.txt" && $0.state == .running } }
        #expect(store.jobs.filter { $0.state == .cancelled }.count == 1)
        await store.shutDown()
    }

    @Test func unreadableSnapshotIsBackedUpBeforeAnySave() throws {
        let folder = try makeDirectory(); defer { try? FileManager.default.removeItem(at: folder) }
        let bytes = Data("{ damaged snapshot".utf8)
        let original = folder.appendingPathComponent("workspace.json")
        try bytes.write(to: original)
        let store = WorkspaceStore(directory: folder)
        #expect(store.notice != nil)
        #expect(try Data(contentsOf: original) == bytes)
        store.persist()
        let backups = try FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil).filter { $0.lastPathComponent.hasPrefix("workspace-recovery-") }
        #expect(backups.count == 1)
        #expect(try Data(contentsOf: #require(backups.first)) == bytes)
        let restored = WorkspaceStore(directory: folder)
        #expect(restored.notice == nil)
        #expect(restored.recipes.isEmpty == false)
    }

    @Test func restartPreservesRecipesAndMarksInterruptedJobs() throws {
        let folder = try makeDirectory(); defer { try? FileManager.default.removeItem(at: folder) }
        let store = WorkspaceStore(directory: folder)
        var custom = recipe; custom.name = "My saved recipe"
        store.recipes.append(custom)
        var job = WorkJob(inputs: [folder.appendingPathComponent("source.txt")], recipe: custom)
        job.state = .running
        store.jobs = [job]; store.persist()
        let restored = WorkspaceStore(directory: folder)
        #expect(restored.recipes.contains { $0.id == custom.id && $0.name == custom.name })
        #expect(restored.jobs.first?.state == .interrupted)
    }
    private var recipe: Recipe { Recipe(name: "test", steps: [.init(action: "convert.md")]) }
    private func slowStore(_ directory: URL) -> WorkspaceStore {
        WorkspaceStore(directory: directory) { _, _, _ in
            try await Task.sleep(for: .seconds(60))
            throw CancellationError()
        }
    }
    private func makeDirectory() throws -> URL {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true); return folder
    }
    private func waitUntil(_ predicate: () -> Bool) async throws {
        let limit = ContinuousClock.now.advanced(by: .seconds(5))
        while !predicate(), ContinuousClock.now < limit { try await Task.sleep(for: .milliseconds(10)) }
        try #require(predicate())
    }
}
