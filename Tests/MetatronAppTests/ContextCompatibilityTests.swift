import Testing
import Foundation
import MetatronCore
import MetatronWorkflow
@testable import Metatron

@MainActor struct ContextCompatibilityTests {
    @Test(arguments: ["txt", "xlsx", "csv"])
    func ringAndAllAlternativeMenusHideAudioRecipesForDocuments(_ ext: String) {
        let model = RingModel()
        model.load(files: [URL(fileURLWithPath: "/tmp/table." + ext)])
        let recipes = model.allPages.flatMap { $0 }.compactMap(\.recipe)
        #expect(recipes.contains { $0.name.hasPrefix("Audio a ") } == false)
        #expect(model.allPages.flatMap { $0 }.contains { $0.action == .tool(.transcribeAudio) } == false)
        #expect(recipes.contains { $0.name == "Documento a Markdown" })
    }
    @Test func workbenchSelectsACompatibleRecipeWithoutChangingTheLibrarySelection() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = WorkspaceStore(directory: root)
        let audio = try #require(store.recipes.first { $0.name == "Audio a Markdown · Apple local" })
        store.selectedRecipeID = audio.id
        store.files = [URL(fileURLWithPath: "/tmp/table.xlsx")]
        #expect(store.selectedRecipe.id == audio.id)
        #expect(store.conversionRecipe?.id != audio.id)
        #expect(store.compatibleRecipes.contains { $0.id == audio.id } == false)
        #expect(store.canIndexFiles)
    }
    @Test func recipesUseOutputPreferencesAndKeepTheirExplicitOverrides() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = WorkspaceStore(directory: root)
        var recipe = Recipe(name: "Output", steps: [.init(action: "convert.jpg")])
        let configured = store.configuredRecipe(recipe)
        #expect(configured.outputLocation == SettingsStore.shared.outputLocation)
        #expect(configured.writeReceipt == SettingsStore.shared.writeReceipt)
        recipe.outputLocation = .subfolder("Own folder")
        recipe.writeReceipt = false
        recipe.folderPath = "/tmp/recipe-destination"
        let overridden = store.configuredRecipe(recipe)
        #expect(overridden.outputLocation == recipe.outputLocation)
        #expect(overridden.writeReceipt == false)
        #expect(try overridden.outputDirectory(for: root.appendingPathComponent("input.png")).path == "/tmp/recipe-destination")
    }

    @Test func rejectingABatchCompletesEveryCallbackWithoutQueueingWork() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = WorkspaceStore(directory: root)
        let recipe = Recipe(name: "Audio only", steps: [.init(action: "tool.transcribeAudio")])
        var failed = 0
        let ids = store.enqueue(inputs: [URL(fileURLWithPath: "/tmp/a.txt"), URL(fileURLWithPath: "/tmp/b.xlsx")], recipe: recipe) { result in
            if case .failure = result { failed += 1 }
        }
        #expect(ids.isEmpty)
        #expect(failed == 2)
        #expect(store.jobs.isEmpty)
        #expect(store.isRunning == false)
    }
}
