import SwiftUI
import AppKit
import MetatronWorkflow

struct DocumentEnginesPane:View {
    @AppStorage("documentEngine.markitdown") private var markitdown=""
    @AppStorage("documentEngine.docling") private var docling=""
    var body:some View {
        Form {
            Section("Procesamiento local") {
                Label("Nativo · siempre disponible",systemImage:"checkmark.circle.fill")
                Text("Vision reconoce texto y PDFKit conserva páginas y extrae contenido. La receta Documento para análisis genera Markdown, imágenes de página y procedencia. Las tablas y el orden de lectura requieren revisión.").foregroundStyle(.secondary)
            }
            SpeechSettingsSection()
            engine(.markitdown,path:$markitdown,detail:"Markdown para documentos Office, PDF y tablas. Un proceso separado se inicia solo cuando eliges este motor en una receta.")
            engine(.docling,path:$docling,detail:"Adaptador opcional para reconstrucción documental. Requiere una instalación y modelos locales preparados por el usuario; no se descargan desde METATRON.")
            Section("Límites para Apple Silicon") {
                Text("Un documento por vez · hasta 50 MB y 40 páginas PDF · 180 segundos por proceso. Los motores opcionales usan hasta dos hilos y se cierran al finalizar.")
                Text("Para instalar MarkItDown desde el código fuente: script/install_document_engine.sh markitdown").font(.caption.monospaced()).textSelection(.enabled)
                Link("Guía de motores documentales",destination:URL(string:"https://github.com/AD0441/METATRON/blob/main/docs/DOCUMENTS.md")!)
            }
        }
    }
    @ViewBuilder private func engine(_ id:DocumentEngineID,path:Binding<String>,detail:String)->some View {
        Section(id.title) {
            Text(detail).foregroundStyle(.secondary)
            TextField("Ruta del ejecutable (opcional)",text:path)
            if let executable=DocumentProcessing.executable(id,customPath:path.wrappedValue) {
                Label("Disponible",systemImage:"checkmark.circle.fill")
                Text(executable.path).font(.caption.monospaced()).textSelection(.enabled)
            } else {Label("Sin configurar",systemImage:"circle.dashed")}
            HStack {
                Button("Elegir ejecutable…") {let panel=NSOpenPanel();panel.canChooseDirectories=false;if panel.runModal() == .OK,let file=panel.url {path.wrappedValue=file.path}}
                Button("Detección automática") {path.wrappedValue=""}
            }
        }
    }
}
