import SwiftUI
struct LibraryView: View {
    @Bindable var store: WorkspaceStore
    @State private var selection: UUID?
    var body: some View {
        HSplitView {
            List(selection: $selection) {
                ForEach(store.filteredLibrary) { item in
                    VStack(alignment: .leading) { Text(item.title); Text(item.tag).font(.caption).foregroundStyle(.secondary) }.tag(item.id)
                }
            }.frame(minWidth: 230, idealWidth: 280)
            if let item = store.library.first(where: { $0.id == selection }) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(item.title).font(.title2.bold())
                        Label(item.tag, systemImage: "tag").foregroundStyle(MetatronStyle.accent)
                        Text(item.url.path).font(.caption.monospaced()).foregroundStyle(.secondary).textSelection(.enabled)
                        HStack { Button("Abrir original") { NSWorkspace.shared.open(item.url) }; Button("Mostrar en Finder") { NSWorkspace.shared.activateFileViewerSelecting([item.url]) } }
                        Divider()
                        Text(item.text).textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading)
                    }.padding(25)
                }
            } else { ContentUnavailableView("Busca dentro de tus documentos", systemImage: "text.magnifyingglass", description: Text("Añade archivos en Convertir y pulsa «Indexar para buscar». El índice se guarda en este Mac.")) }
        }.navigationTitle("Biblioteca")
        .searchable(text: $store.search, prompt: "Nombre, etiqueta o texto del documento")
    }
}
