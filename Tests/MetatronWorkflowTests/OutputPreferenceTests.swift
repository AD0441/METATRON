import Foundation
import Testing
import MetatronCore
@testable import MetatronWorkflow

struct OutputPreferenceTests {
    @Test(arguments: ["same", "subfolder", "fixed"], [true, false])
    func destinationAndReceiptAreRespected(mode: String, receipt: Bool) async throws {
        let fixture = try Fixtures()
        defer { fixture.clean() }
        let source = try fixture.image()
        let before = try FileIntegrity.digest(source)
        let fixed = fixture.directory.appendingPathComponent("fixed")
        let location: OutputLocation
        let destination: URL
        switch mode {
        case "same": location = .nextToOriginal; destination = fixture.directory
        case "subfolder": location = .subfolder("Resultados"); destination = fixture.directory.appendingPathComponent("Resultados")
        default: location = .folder(fixed); destination = fixed
        }
        var recipe = Recipe(name: "Output", steps: [.init(action: "convert.jpg")])
        recipe.outputLocation = location
        recipe.writeReceipt = receipt
        recipe = try JSONDecoder().decode(Recipe.self, from: JSONEncoder().encode(recipe))
        let planned = try Simulation.plan(inputs: [source], recipe: recipe)
        #expect(try FileIntegrity.digest(source) == before)
        #expect(mode == "same" || FileManager.default.fileExists(atPath: destination.path) == false)
        let result = try await RecipeExecutor.execute(inputs: [source], recipe: recipe)
        let image = try #require(result.files.first)
        #expect(image.url.path == planned.first?.destination)
        #expect(image.url.deletingLastPathComponent().standardizedFileURL == destination.standardizedFileURL)
        #expect(result.files.count == (receipt ? 2 : 1))
        #expect(result.files.filter { $0.url.pathExtension == "json" }.count == (receipt ? 1 : 0))
        for file in result.files { #expect(try FileIntegrity.digest(file.url) == file.digest) }
        #expect(try FileIntegrity.digest(source) == before)
        try await RecipeExecutor.undo(result.files, directory: fixture.directory.appendingPathComponent("undo"))
        #expect(result.files.allSatisfy { FileManager.default.fileExists(atPath: $0.url.path) == false })
        #expect(try FileIntegrity.digest(source) == before)
    }

    @Test func legacyRecipesKeepTheirOutputContract() throws {
        let recipe = Recipe(name: "Legacy", steps: [.init(action: "convert.jpg")])
        let data = try JSONEncoder().encode(recipe)
        let restored = try JSONDecoder().decode(Recipe.self, from: data)
        #expect(restored.outputLocation == nil)
        #expect(restored.writeReceipt == nil)
        #expect(try restored.outputDirectory(for: URL(fileURLWithPath: "/tmp/input/photo.png")).path == "/tmp/input/Metatron")
    }

    @Test func explicitRecipeDirectoryOverridesTheDefault() throws {
        var recipe = Recipe(name: "Fixed", steps: [.init(action: "convert.jpg")], folderPath: "/tmp/fixed")
        recipe.outputLocation = .nextToOriginal
        #expect(try recipe.outputDirectory(for: URL(fileURLWithPath: "/tmp/input/photo.png")).path == "/tmp/fixed")
    }

    @Test func invalidSubfolderCannotEscapeTheInputDirectory() throws {
        var recipe = Recipe(name: "Invalid", steps: [.init(action: "convert.jpg")])
        recipe.outputLocation = .subfolder("../elsewhere")
        #expect(throws: WorkflowError.self) { try recipe.outputDirectory(for: URL(fileURLWithPath: "/tmp/input/photo.png")) }
    }

    @Test(arguments: [true, false])
    func cancellationPreservesTheSourceWithoutPartialFiles(receipt: Bool) async throws {
        let fixture = try Fixtures()
        defer { fixture.clean() }
        let source = try fixture.image()
        let before = try FileIntegrity.digest(source)
        let destination = fixture.directory.appendingPathComponent("output")
        var recipe = Recipe(name: "Cancel", steps: [.init(action: "convert.jpg")], folderPath: destination.path)
        recipe.writeReceipt = receipt
        let configured = recipe
        let operation = Task {
            try await RecipeExecutor.execute(inputs: [source], recipe: configured) { message in
                if message == "Verificando y publicando" { withUnsafeCurrentTask { $0?.cancel() } }
            }
        }
        await #expect(throws: CancellationError.self) { try await operation.value }
        #expect((try? FileManager.default.contentsOfDirectory(atPath: destination.path))?.isEmpty ?? true)
        #expect(try FileIntegrity.digest(source) == before)
    }
}
