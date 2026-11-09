import SwiftUI
import MetatronCore

struct SpeechSettingsSection: View {
    @AppStorage("speech.locale") private var locale = "es-CL"
    @State private var languages: [String] = []
    @State private var status: SpeechLanguageStatus?
    @State private var installation: Task<Void, Never>?
    @State private var message: String?
    var body: some View {
        Section("Audio a texto · Apple local") {
            Text("Transcribe grabaciones a TXT o Markdown con Apple Speech. El audio se procesa en tu Mac; no se utiliza reconocimiento en la nube. Requiere macOS 26 y hardware compatible.").foregroundStyle(.secondary)
            Picker("Idioma del audio", selection: $locale) {
                ForEach(Array(Set(languages + [locale])).sorted(), id: \.self) { id in
                    Text(Locale.current.localizedString(forIdentifier: id) ?? id).tag(id)
                }
            }.disabled(installation != nil)
            if let status {
                Label(status.message, systemImage: status.installed ? "checkmark.circle.fill" : "info.circle")
                if status.supported && !status.installed && installation == nil {
                    Button("Descargar idioma desde Apple…") { install() }
                }
            } else { ProgressView("Comprobando idioma local…") }
            if installation != nil {
                HStack {
                    ProgressView().controlSize(.small)
                    Text("Descargando modelo de Apple…")
                    Button("Cancelar") { installation?.cancel() }
                }
            }
            if let message { Text(message).font(.caption).foregroundStyle(.secondary) }
            Text("La descarga del modelo requiere Internet y no incluye tus grabaciones. Una vez instalado, las transcripciones funcionan localmente.").font(.caption).foregroundStyle(.secondary)
        }
        .task(id: locale) {
            let selected = locale
            let found = await AppleSpeech.languages().map { $0.replacingOccurrences(of: "_", with: "-") }
            let state = await AppleSpeech.languageStatus(selected)
            guard !Task.isCancelled, selected == locale else { return }
            languages = found; status = state
        }
    }
    private func install() {
        let selected = locale
        message = nil
        installation = Task {
            do { try await AppleSpeech.installLanguage(selected); message = "Idioma preparado para transcribir localmente." }
            catch is CancellationError { message = "Descarga cancelada. Apple gestiona los modelos compartidos con otras aplicaciones." }
            catch { message = error.localizedDescription }
            status = await AppleSpeech.languageStatus(selected)
            installation = nil
        }
    }
}
