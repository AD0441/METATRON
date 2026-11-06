import Testing
import Foundation
import MetatronCore
@testable import MetatronWorkflow

struct RecipeCompatibilityTests {
    private let native = Engines()
    private func url(_ ext: String) -> URL { URL(fileURLWithPath: "/tmp/input." + ext) }

    @Test(arguments: ["txt", "md", "xlsx", "csv", "pdf", "jpg", "zip", "mp4"])
    func audioPresetsNeverAppearForOtherTypes(_ ext: String) throws {
        let presets = Recipe.builtIns.filter { $0.name.hasPrefix("Audio a ") }
        #expect(presets.count == 2)
        for preset in presets {
            #expect(RecipeCompatibility.issue(inputs: [url(ext)], recipe: preset, engines: native) != nil)
            // Previously saved built-ins have no inputKinds field.
            let legacy = Recipe(name: preset.name, steps: preset.steps)
            #expect(RecipeCompatibility.issue(inputs: [url(ext)], recipe: legacy, engines: native) != nil)
        }
    }

    @Test func validatesOutputsBetweenStepsInsteadOfOnlyCheckingTheInput() {
        let good = Recipe(name: "OCR PDF", steps: [.init(action: "convert.pdf"), .init(action: "tool.extractPDFText")])
        let bad = Recipe(name: "Wrong OCR", steps: [.init(action: "convert.txt"), .init(action: "tool.extractPDFText")])
        #expect(RecipeCompatibility.issue(inputs: [url("png")], recipe: good, engines: native) == nil)
        let reason = RecipeCompatibility.issue(inputs: [url("pdf")], recipe: bad, engines: native)
        #expect(reason?.contains("Paso 2") == true)
    }

    @Test func reencodingTheSameImageFormatIsAllowedInsideARecipe() {
        let recipe = Recipe(name: "PNG", steps: [.init(action: "resize", number: 500), .init(action: "convert.png")])
        #expect(RecipeCompatibility.issue(inputs: [url("png")], recipe: recipe, engines: native) == nil)
    }

    @Test(arguments: ["resize", "targetSize", "pdfTables", "tool.transcribeAudio", "trimVideo", "tool.removeBackground"])
    func spreadsheetRejectsUnrelatedTools(_ action: String) {
        #expect(RecipeCompatibility.issue(inputs: [url("xlsx")], recipe: Recipe(name: "Invalid", steps: [.init(action: action)]), engines: native) != nil)
    }

    @Test func batchValidationChecksEveryFileAndOfficeSubtype() {
        let recipe = Recipe(name: "Images", steps: [.init(action: "resize")])
        #expect(RecipeCompatibility.issue(inputs: [url("png"), url("txt")], recipe: recipe, engines: native) != nil)
        let office = Engines(soffice: URL(fileURLWithPath: "/soffice"))
        let mixed = [url("xls"), url("pptx")]
        #expect(ActionCatalog.convertActions(for: mixed, engines: office).contains(.convert(.xlsx)) == false)
        #expect(ActionCatalog.convertActions(for: mixed.reversed(), engines: office) == ActionCatalog.convertActions(for: mixed, engines: office))
        #expect(ActionCatalog.convertActions(for: mixed, engines: office).contains(.convert(.pdf)))
    }

    @Test func batchConversionIsAnIntersectionIndependentOfInputOrder() {
        let inputs = [url("json"), url("csv")]
        let a = Set(ActionCatalog.convertActions(for: inputs, engines: native))
        let b = Set(ActionCatalog.convertActions(for: inputs.reversed(), engines: native))
        #expect(a == b)
        #expect(a.contains(.convert(.plist)) == false)
        #expect(a.contains(.convert(.md)))
        let media = [url("mp4"), url("webm")]
        #expect(ActionCatalog.convertActions(for: media, engines: native).isEmpty)
        #expect(ActionCatalog.toolActions(for: media, engines: native) == [.tool(.zip)])
    }

    @Test func mixedImageAndPDFKeepOnlySharedToolsAndPDFMerge() {
        let tools = ActionCatalog.toolActions(for: [url("png"), url("pdf")], engines: native)
        #expect(tools == [.tool(.merge), .tool(.zip)])
        #expect(ActionCatalog.toolActions(for: [], engines: native).isEmpty)
    }

    @Test func missingEnginesPreventRecipesFromBeingOffered() {
        let webp = Recipe(name: "WebP", steps: [.init(action: "convert.webp")])
        #expect(RecipeCompatibility.issue(inputs: [url("png")], recipe: webp, engines: native) != nil)
        let withWebP = Engines(cwebp: URL(fileURLWithPath: "/cwebp"))
        #expect(RecipeCompatibility.issue(inputs: [url("png")], recipe: webp, engines: withWebP) == nil)
        let doc = Recipe(name: "Office", steps: [.init(action: "convert.pdf")])
        #expect(RecipeCompatibility.issue(inputs: [url("xls")], recipe: doc, engines: native) != nil)
    }

    @Test func nativeDocumentProcessingDoesNotAcceptAudioOrAnOfficeBinary() {
        let recipe = Recipe(name: "Document", steps: [.init(action: "documentAdvanced", text: "native")])
        for ext in ["m4a", "xlsx", "pptx", "zip"] {
            let compatible = RecipeCompatibility.issue(inputs: [url(ext)], recipe: recipe, engines: native) == nil
            #expect(compatible == (ext == "xlsx"))
        }
        #expect(RecipeCompatibility.issue(inputs: [url("pdf")], recipe: recipe, engines: native) == nil)
    }

    @Test func settingsKeepTheUnionOfFamilyCapabilities() {
        let images = ActionCatalog.allActions(for: .image)
        #expect(images.convert.contains(.convert(.png)))
        #expect(images.tools.contains(.tool(.stripMetadata)))
        #expect(ActionCatalog.allActions(for: .pdf).convert.contains(.convert(.pdf)))
        let office = ActionCatalog.allActions(for: .office)
        #expect(office.convert.contains(.convert(.xlsx)))
        #expect(office.convert.contains(.convert(.pptx)))
        #expect(ActionCatalog.allActions(for: .data).convert.contains(.convert(.plist)))
    }

    @Test func customDocumentEnginePathsParticipateInCompatibility() {
        var recipe = Recipe(name: "External", steps: [.init(action: "documentAdvanced", text: "markitdown")])
        recipe.documentEnginePath = "/bin/echo"
        #expect(RecipeCompatibility.issue(inputs: [url("pptx")], recipe: recipe, engines: native) == nil)
        #expect(RecipeCompatibility.issue(inputs: [url("m4a")], recipe: recipe, engines: native) != nil)
    }

    @Test func editorOffersOnlyStepsThatAcceptThePreviousResult() {
        let empty = Recipe(name: "Table", steps: [])
        let tableChoices = RecipeCompatibility.nextSteps(inputs: [url("xlsx")], recipe: empty, engines: native).map(\.action)
        #expect(tableChoices.contains("tool.transcribeAudio") == false)
        #expect(tableChoices.contains("resize") == false)
        #expect(tableChoices.contains("convert.md"))
        let imageToPDF = Recipe(name: "PDF", steps: [.init(action: "convert.pdf")])
        let afterPDF = RecipeCompatibility.nextSteps(inputs: [url("png")], recipe: imageToPDF, engines: native).map(\.action)
        #expect(afterPDF.contains("tool.extractPDFText"))
        #expect(afterPDF.contains("resize") == false)
    }
    @Test func directEngineRejectsAnIncompatibleOperationBeforeWriting() async throws {
        let fixture = try Fixtures(); defer { fixture.clean() }
        let input = fixture.directory.appendingPathComponent("notes.txt")
        try Data("original".utf8).write(to: input)
        let output = fixture.directory.appendingPathComponent("output")
        let engine = Engine(planner: OutputPlanner(location: .folder(output)))
        await #expect(throws: MetatronError.self) { try await engine.run(.tool(.transcribeAudio), on: [input]) }
        #expect(FileManager.default.fileExists(atPath: output.path) == false)
        #expect(try String(contentsOf: input, encoding: .utf8) == "original")
    }
    @Test func aFolderOutputCannotBeTranscribedButCanBeZipped() {
        let zipped = Recipe(name: "Package", steps: [.init(action: "research"), .init(action: "tool.zip")])
        let invalid = Recipe(name: "Invalid", steps: [.init(action: "research"), .init(action: "tool.transcribeAudio")])
        #expect(RecipeCompatibility.issue(inputs: [url("pdf")], recipe: zipped, engines: native) == nil)
        #expect(RecipeCompatibility.issue(inputs: [url("pdf")], recipe: invalid, engines: native) != nil)
    }

    @Test func declaredInputKindsSurviveRecipeExportAndOldJSONStillDecodes() throws {
        let preset = try #require(Recipe.builtIns.first { $0.name == "Audio a Markdown · Apple local" })
        let restored = try JSONDecoder().decode(Recipe.self, from: JSONEncoder().encode(preset))
        #expect(restored.inputKinds == [.audio])
        var object = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(preset)) as? [String: Any])
        object.removeValue(forKey: "inputKinds")
        let legacy = try JSONDecoder().decode(Recipe.self, from: JSONSerialization.data(withJSONObject: object))
        #expect(legacy.inputKinds == nil)
        #expect(RecipeCompatibility.issue(inputs: [url("xlsx")], recipe: legacy, engines: native) != nil)
    }

    @Test func anInvalidChainIsRejectedBeforeTemporaryWorkOrPublication() async throws {
        let fixture = try Fixtures(); defer { fixture.clean() }
        let source = try fixture.image()
        let before = try FileIntegrity.digest(source)
        let destination = fixture.directory.appendingPathComponent("output")
        let id = UUID()
        let recipe = Recipe(name: "Impossible", steps: [.init(action: "convert.pdf"), .init(action: "tool.transcribeAudio")], folderPath: destination.path)
        await #expect(throws: WorkflowError.self) { try await RecipeExecutor.execute(inputs: [source], recipe: recipe, id: id) }
        #expect(try FileIntegrity.digest(source) == before)
        #expect(FileManager.default.fileExists(atPath: destination.path) == false)
        #expect(FileManager.default.fileExists(atPath: FileManager.default.temporaryDirectory.appendingPathComponent("metatron-job-" + id.uuidString).path) == false)
        #expect(throws: WorkflowError.self) { try Simulation.plan(inputs: [source], recipe: recipe) }
    }
}
