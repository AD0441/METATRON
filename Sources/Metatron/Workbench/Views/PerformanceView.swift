import SwiftUI
import MetatronCore
import MetatronWorkflow
struct PerformanceView: View {
    let store: WorkspaceStore
    @State private var benchmark: BenchmarkResult?
    @State private var busy = false
    @State private var error: String?
    @State private var engines = Engines()
    var body: some View {
        Form {
            Section("Apple Silicon") {
                LabeledContent("Metal", value: store.hardware.deviceName)
                LabeledContent("Memoria unificada", value: store.hardware.unifiedMemory ? "Sí" : "No disponible")
                LabeledContent("Memoria física", value: ByteCountFormatter.string(fromByteCount: Int64(ProcessInfo.processInfo.physicalMemory), countStyle: .memory))
                LabeledContent("Ejecución", value: "Una tarea pesada a la vez · una página PDF a la vez")
                Text("Core Image usa Metal para composición y diferencias. La reducción simple usa Core Graphics, la ruta más rápida en la medición de referencia del M1. Vision decide qué recursos del sistema utilizar para OCR y recorte de sujetos; no se fuerza ni se presupone el uso del Neural Engine.").foregroundStyle(.secondary)
            }
            Section("Motores disponibles") {
                engineRow("ImageIO / PDFKit / AVFoundation", path: "Integrados en macOS")
                engineRow("Vision OCR y recorte de sujetos", path: "Procesamiento local")
                engineRow("FFmpeg", path: engines.ffmpeg?.path)
                engineRow("LibreOffice", path: engines.soffice?.path)
                engineRow("Ghostscript", path: engines.ghostscript?.path)
                engineRow("WebP", path: engines.cwebp?.path)
                Button("Volver a detectar") { Task { engines = await detectEngines() } }
            }
            Section("Medición en este equipo") {
                Text("Compara dos rutas de reducción de una imagen sintética de 4000 × 3000 px. Tres repeticiones después del calentamiento. La calidad del filtro puede variar; estos tiempos no representan todas las conversiones.")
                Button("Medir CPU y Metal") { measure() }.disabled(busy)
                if busy { ProgressView("Midiendo…") }
                if let benchmark {
                    LabeledContent("Core Graphics", value: "\((benchmark.cpuSeconds * 1000).formatted(.number.precision(.fractionLength(2)))) ms")
                    LabeledContent("Core Image / Metal", value: "\((benchmark.metalSeconds * 1000).formatted(.number.precision(.fractionLength(2)))) ms")
                }
                if let error { Text(error).foregroundStyle(.red) }
            }
        }.formStyle(.grouped).navigationTitle("Rendimiento y motores").task { engines = await detectEngines() }
    }
    private func engineRow(_ name: String, path: String?) -> some View {
        LabeledContent { Text(path ?? "Opcional · no instalado").foregroundStyle(path == nil ? .secondary : .primary).textSelection(.enabled) } label: { Label(name, systemImage: path == nil ? "circle.dashed" : "checkmark.circle.fill") }
    }
    @concurrent private func detectEngines() async -> Engines { Engines.refresh() }
    private func measure() {
        busy = true; error = nil
        Task { defer { busy = false }; do { benchmark = try await ImageBenchmark.run() } catch { self.error = error.localizedDescription } }
    }
}
