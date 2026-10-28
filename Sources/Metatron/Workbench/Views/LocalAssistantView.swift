import SwiftUI
import FoundationModels
struct LocalAssistantView: View {
    let store: WorkspaceStore
    @State private var prompt = "Sugiere una receta para preparar informes académicos para entregar por correo."
    @State private var answer = ""
    @State private var busy = false
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Label("Un asistente en tu Mac", systemImage: "sparkles").font(.largeTitle.bold())
                Text("Apple Intelligence puede ayudarte a elegir una receta. Solo recibe lo que escribas en este cuadro; no ejecuta operaciones sobre archivos.").foregroundStyle(.secondary)
                Text(availability).font(.callout).foregroundStyle(.secondary)
                TextEditor(text: $prompt).frame(minHeight: 140).padding(10).background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 10))
                Button("Pedir sugerencia", systemImage: "sparkles") { ask() }.buttonStyle(.borderedProminent).disabled(!available || busy || prompt.isEmpty)
                if busy { ProgressView("Preparando sugerencia local…") }
                if !answer.isEmpty { Text(answer).textSelection(.enabled).padding(20).frame(maxWidth: .infinity, alignment: .leading).background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 12)) }
                Divider()
                Text("OCR y eliminación de fondo con Vision funcionan independientemente del asistente. Puedes usarlos en las recetas y en la rueda.").foregroundStyle(.secondary)
            }.padding(30)
        }.navigationTitle("Asistente local")
    }
    private var available: Bool { if #available(macOS 26, *) { SystemLanguageModel.default.availability == .available } else { false } }
    private var availability: String {
        if #available(macOS 26, *) {
            switch SystemLanguageModel.default.availability {
            case .available: return "Modelo de Apple disponible en este dispositivo."
            case .unavailable(.appleIntelligenceNotEnabled): return "Activa Apple Intelligence en Ajustes del Sistema para usar el asistente."
            case .unavailable(.modelNotReady): return "El modelo local todavía no está preparado."
            default: return "El modelo generativo no está disponible en este dispositivo."
            }
        }
        return "El asistente generativo requiere macOS 26 o posterior. Las herramientas Vision siguen disponibles."
    }
    private func ask() {
        guard #available(macOS 26, *) else { return }
        busy = true
        Task {
            defer { busy = false }
            do {
                let session = LanguageModelSession(instructions: "Eres el asistente local de Metatron. Responde en español y recomienda pasos de conversión, OCR y organización. No inventes garantías de fidelidad y no proporciones comandos de shell. Tus respuestas son sugerencias; no ejecutas acciones.")
                answer = try await session.respond(to: String(prompt.prefix(6000))).content
            } catch { answer = "No se pudo generar la sugerencia: \(error.localizedDescription)" }
        }
    }
}
