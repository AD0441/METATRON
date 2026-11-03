import Testing
import Foundation
import MetatronCore
@testable import MetatronWorkflow

struct ConversionStabilityTests {
    @Test func reusedJobIdentifierDoesNotReplaceAnExistingReceipt() async throws {
        let fixture = try Fixtures(); defer { fixture.clean() }
        let source = try fixture.image()
        let recipe = Recipe(name: "JPEG", steps: [.init(action: "convert.jpg")])
        let id = UUID()
        let first = try await RecipeExecutor.execute(inputs: [source], recipe: recipe, id: id)
        let receipt = try #require(first.files.last)
        let bytes = try Data(contentsOf: receipt.url)
        let second = try await RecipeExecutor.execute(inputs: [source], recipe: recipe, id: id)
        #expect(first.files.last?.url != second.files.last?.url)
        #expect(try Data(contentsOf: receipt.url) == bytes)
        #expect(first.files.allSatisfy { FileManager.default.fileExists(atPath: $0.url.path) })
    }

    @Test func corruptedImageCannotPublishOrModifyItsSource() async throws {
        let fixture = try Fixtures(); defer { fixture.clean() }
        let source = fixture.directory.appendingPathComponent("broken.png")
        try Data("not an image".utf8).write(to: source)
        let before = try FileIntegrity.digest(source)
        let destination = fixture.directory.appendingPathComponent("output")
        await #expect(throws: (any Error).self) {
            try await RecipeExecutor.execute(inputs: [source], recipe: Recipe(name: "JPEG", steps: [.init(action: "convert.jpg")], folderPath: destination.path))
        }
        #expect(FileManager.default.fileExists(atPath: destination.path) == false)
        #expect(try FileIntegrity.digest(source) == before)
    }

    @Test func invalidDestinationLeavesNoStagingDirectoryOrAlteredFiles() async throws {
        let fixture = try Fixtures(); defer { fixture.clean() }
        let source = try fixture.image()
        let before = try FileIntegrity.digest(source)
        let destination = fixture.directory.appendingPathComponent("file-not-folder")
        let existing = Data("existing file".utf8)
        try existing.write(to: destination)
        let id = UUID()
        await #expect(throws: (any Error).self) {
            try await RecipeExecutor.execute(inputs: [source], recipe: Recipe(name: "JPEG", steps: [.init(action: "convert.jpg")], folderPath: destination.path), id: id)
        }
        #expect(try FileIntegrity.digest(source) == before)
        #expect(try Data(contentsOf: destination) == existing)
        #expect(FileManager.default.fileExists(atPath: FileManager.default.temporaryDirectory.appendingPathComponent("metatron-job-" + id.uuidString).path) == false)
    }

    @Test func cancellationAtPublicationLeavesNoPartialOutputOrReceipt() async throws {
        let fixture = try Fixtures(); defer { fixture.clean() }
        let source = try fixture.image()
        let before = try FileIntegrity.digest(source)
        let destination = fixture.directory.appendingPathComponent("output")
        let recipe = Recipe(name: "JPEG", steps: [.init(action: "convert.jpg")], folderPath: destination.path)
        let operation = Task {
            try await RecipeExecutor.execute(inputs: [source], recipe: recipe) { message in
                if message == "Verificando y publicando" { withUnsafeCurrentTask { $0?.cancel() } }
            }
        }
        await #expect(throws: CancellationError.self) { try await operation.value }
        #expect((try? FileManager.default.contentsOfDirectory(atPath: destination.path))?.isEmpty ?? true)
        #expect(try FileIntegrity.digest(source) == before)
    }
}
