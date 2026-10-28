import Testing
import Foundation
import MetatronCore
@testable import MetatronWorkflow

struct TranscriptWorkflowTests {
    @Test func audioRecipeSimulationPredictsTextAndWarnsAboutLanguageAssets() throws {
        let input = URL(fileURLWithPath: "/tmp/recording.m4a")
        let result = try Simulation.plan(inputs: [input], recipe: Recipe(name: "Speech", steps: [.init(action: "tool.transcribeAudio")]))
        #expect(result.first?.destination.hasSuffix(".txt") == true)
        #expect(result.first?.warnings.contains { $0.contains("Apple Speech") } == true)
    }
}
