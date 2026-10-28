import SwiftUI
import MetatronWorkflow
import MetatronCore
struct PDFCompareView: View {
    @State private var first: URL?
    @State private var second: URL?
    @State private var differences: [PDFDifference] = []
    @State private var busy = false
    @State private var error: String?
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Qué cambió en tu informe").font(.largeTitle.bold())
                Text("Compara dos PDF por página. Las diferencias se resaltan en rojo; el porcentaje mide píxeles distintos, no cambios de significado.").foregroundStyle(.secondary)
                HStack {
                    Button(first?.lastPathComponent ?? "Elegir PDF original…") { first = choosePDF() }
                    Image(systemName: "arrow.right")
                    Button(second?.lastPathComponent ?? "Elegir PDF revisado…") { second = choosePDF() }
                    Spacer()
                    Button("Comparar", systemImage: "doc.on.doc") { compare() }.buttonStyle(.borderedProminent).disabled(first == nil || second == nil || busy)
                }
                if busy { ProgressView("Comparando una página a la vez…") }
                if let error { Text(error).foregroundStyle(.red) }
                LazyVStack(alignment: .leading, spacing: 20) {
                    ForEach(differences) { page in PDFDifferenceCard(page: page) }
                }
            }.padding(30)
        }.navigationTitle("Comparar PDF")
    }
    private func choosePDF() -> URL? { let panel = NSOpenPanel(); panel.allowedContentTypes = [.pdf]; return panel.runModal() == .OK ? panel.url : nil }
    private func compare() {
        guard let first, let second else { return }
        let panel = NSOpenPanel(); panel.canChooseFiles = false; panel.canChooseDirectories = true; panel.message = "Elige dónde guardar la comparación"
        guard panel.runModal() == .OK, let folder = panel.url else { return }
        busy = true; error = nil
        Task {
            defer { busy = false }
            do { differences = try await PDFWorkbench.compare(first, second, destination: folder.appendingPathComponent("Comparación-\(UUID().uuidString.prefix(8))", isDirectory: true)) }
            catch { self.error = error.localizedDescription }
        }
    }
}

struct PDFDifferenceCard: View {
    let page: PDFDifference
    @State private var image: NSImage?
    @Environment(\.displayScale) private var displayScale
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack { Text("Página \(page.id)").font(.headline); Text(page.fraction, format: .percent.precision(.fractionLength(2))).foregroundStyle(page.fraction > 0.001 ? .orange : .green); Spacer(); Button("Abrir imagen") { NSWorkspace.shared.open(page.preview) } }
            if let image { Image(nsImage: image).resizable().scaledToFit().frame(maxHeight: 500).accessibilityLabel("Diferencias visuales de la página \(page.id)") }
            else { ProgressView().frame(height: 180) }
        }.padding(16).background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 12))
        .task(id: page.preview) { if let cg = await loadThumbnail(page.preview, pixels: Int(700 * displayScale)) { image = NSImage(cgImage: cg, size: .zero) } }
    }
    @concurrent private func loadThumbnail(_ url: URL, pixels: Int) async -> CGImage? { MetatronCore.Images.thumbnail(url, maxPixel: pixels) }
}
