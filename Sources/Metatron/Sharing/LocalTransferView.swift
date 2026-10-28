import SwiftUI
struct TransferSelection: Identifiable { let id = UUID(); let file: URL }
struct LocalTransferView: View {
    let file: URL
    @State private var transfer = LocalTransfer()
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Label("Enviar por red local", systemImage: "wifi").font(.title2.bold())
            Text(file.lastPathComponent).font(.headline)
            Text("El otro dispositivo abrirá el enlace en su navegador. El enlace permite descargar este archivo durante diez minutos. Usa una red de confianza: esta transferencia HTTP no está cifrada.").foregroundStyle(.secondary)
            if let link = transfer.link {
                Text(link).font(.callout.monospaced()).textSelection(.enabled)
                HStack {
                    Button("Copiar enlace") { NSPasteboard.general.clearContents(); NSPasteboard.general.setString(link, forType: .string) }
                    Button("Detener transferencia", role: .destructive) { transfer.stop() }
                }
            } else { Button("Activar enlace de este archivo") { transfer.start(file) }.buttonStyle(.borderedProminent) }
            Text(transfer.status).font(.caption).foregroundStyle(.secondary)
        }.padding(28).frame(width: 510).onDisappear { transfer.stop() }
    }
}
