import SwiftUI
import MetatronWorkflow
struct RecipeLibraryView: View {
    @Bindable var store: WorkspaceStore
    var body: some View {
        HSplitView {
            List(selection: $store.selectedRecipeID) {
                ForEach(store.recipes) { recipe in Label(recipe.name, systemImage: "square.stack.3d.up").tag(Optional(recipe.id)) }
            }.frame(minWidth: 200, idealWidth: 240, maxWidth: 300)
            RecipeEditor(recipe: store.selectedRecipe, save: store.updateRecipe)
        }
        .navigationTitle("Recetas")
        .toolbar { ToolbarItemGroup { Button("Importar", systemImage: "square.and.arrow.down") { store.importRecipe() }; Button("Exportar", systemImage: "square.and.arrow.up") { store.exportRecipe() }; Button("Nueva receta", systemImage: "plus") { store.addRecipe() } } }
    }
}
struct RecipeEditor: View {
    let recipe: Recipe
    let save: (Recipe) -> Void
    @State private var chosenAction = "convert.jpg"
    private func binding<Value>(_ key: WritableKeyPath<Recipe,Value>) -> Binding<Value> {
        Binding(get: { recipe[keyPath: key] }, set: { value in var copy = recipe; copy[keyPath: key] = value; save(copy) })
    }
    var body: some View {
        Form {
            Section("Nombre") { TextField("Nombre de la receta", text: binding(\.name)) }
            Section("Pasos · se ejecutan en este orden") {
                ForEach(recipe.steps) { step in RecipeStepRow(step: step, update: { replacement in var copy = recipe; if let i = copy.steps.firstIndex(where: { $0.id == step.id }) { copy.steps[i] = replacement }; save(copy) }, remove: { var copy = recipe; copy.steps.removeAll { $0.id == step.id }; save(copy) }, move: { direction in var copy = recipe; if let i = copy.steps.firstIndex(where: { $0.id == step.id }), copy.steps.indices.contains(i + direction) { copy.steps.swapAt(i, i + direction); save(copy) } }) }
                HStack {
                    Picker("Añadir paso", selection: $chosenAction) { ForEach(RecipeStep.choices) { Text($0.title).tag($0.action) } }
                    Button("Añadir") { var copy = recipe; copy.steps.append(RecipeStep(action: chosenAction, number: chosenAction == "targetSize" ? 500 : 1920)); save(copy) }
                }
            }
            Section("Salida") {
                TextField("Sufijo", text: binding(\.suffix))
                Slider(value: binding(\.quality), in: 0.3...1) { Text("Calidad") }
                Toggle("Conservar metadatos cuando el formato lo permita", isOn: binding(\.preserveMetadata))
                LabeledContent("Carpeta") {
                    Text(recipe.folderPath ?? "Subcarpeta Metatron junto al original").lineLimit(1).truncationMode(.middle)
                    Button("Elegir…") { let panel = NSOpenPanel(); panel.canChooseDirectories = true; panel.canChooseFiles = false; if panel.runModal() == .OK, let url = panel.url { var copy = recipe; copy.folderPath = url.path; save(copy) } }
                    Button("Restablecer") { var copy = recipe; copy.folderPath = nil; save(copy) }
                }
            }
        }.formStyle(.grouped)
    }
}
struct RecipeStepRow: View {
    let step: RecipeStep
    let update: (RecipeStep) -> Void
    let remove: () -> Void
    let move: (Int) -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(step.title).fontWeight(.medium)
                Spacer()
                Button { move(-1) } label: { Image(systemName: "arrow.up") }.accessibilityLabel("Subir paso")
                Button { move(1) } label: { Image(systemName: "arrow.down") }.accessibilityLabel("Bajar paso")
                Button(role: .destructive, action: remove) { Image(systemName: "minus.circle") }.accessibilityLabel("Quitar paso")
            }
            if step.action == "documentAdvanced" {
                Picker("Motor documental",selection:Binding(get:{step.text.isEmpty ? "native" : step.text},set:{var copy=step;copy.text=$0;update(copy)})) {
                    ForEach(DocumentEngineID.allCases,id:\.self) {Text($0.title).tag($0.rawValue)}
                }
            }
            if step.action == "tool.transcribeAudio" {
                TextField("Idioma del audio (vacío = Ajustes; ej. es-CL)", text: Binding(get: { step.text }, set: { var copy = step; copy.text = $0; update(copy) }))
                Text("Apple Speech · macOS 26+ · modelo instalado. El audio se procesa en este Mac.").font(.caption).foregroundStyle(.secondary)
            }
            if ["resize","targetSize"].contains(step.action) {
                TextField(step.action == "resize" ? "Lado mayor (px)" : "Máximo (KB)", value: Binding(get: { step.number }, set: { var copy = step; copy.number = $0; update(copy) }), format: .number)
            }
            if ["reorderPDF","redactPDF","trimVideo"].contains(step.action) {
                TextField(step.action == "reorderPDF" ? "Páginas: 3,1,2" : step.action == "trimVideo" ? "Inicio,fin en segundos: 0,10" : "Textos que se retirarán, separados por comas", text: Binding(get: { step.text }, set: { var copy = step; copy.text = $0; update(copy) }))
            }
        }.padding(.vertical, 3)
    }
}
