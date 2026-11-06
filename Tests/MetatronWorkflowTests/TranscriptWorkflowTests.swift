import Testing
import Foundation
import MetatronCore
@testable import MetatronWorkflow

struct TranscriptWorkflowTests {
    @Test func audioRecipeSimulationRespectsDeviceSupportAndPredictsTextWhenAvailable() throws {
        let input = URL(fileURLWithPath: "/tmp/recording.m4a")
        let recipe = Recipe(name: "Speech", steps: [.init(action: "tool.transcribeAudio")])
        if !AppleSpeech.isSupported {
            #expect(throws: WorkflowError.self) { try Simulation.plan(inputs: [input], recipe: recipe) }
            #expect(RecipeCompatibility.issue(inputs: [input], recipe: recipe) != nil)
            return
        }
        let result = try Simulation.plan(inputs: [input], recipe: recipe)
        #expect(result.first?.destination.hasSuffix(".txt") == true)
        #expect(result.first?.warnings.contains { $0.contains("Apple Speech") } == true)
    }
}
