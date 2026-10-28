import SwiftUI
import MetatronCore
import MetatronWorkflow

enum ImageMarkupWindow {
    private static var windows: [NSWindow] = []
    static func show(_ file: URL) {
        let window = NSWindow(contentRect: NSRect(x: 0,y: 0,width: 960,height: 760), styleMask: [.titled,.closable,.resizable,.miniaturizable], backing: .buffered, defer: false)
        window.title = "Anotar · " + file.lastPathComponent
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(rootView: ImageMarkupEditor(file: file))
        window.center(); window.makeKeyAndOrderFront(nil); NSApp.activate(ignoringOtherApps: true)
        windows.append(window)
        NotificationCenter.default.addObserver(forName: NSWindow.willCloseNotification, object: window, queue: .main) { note in
            let closed = note.object as? NSWindow
            MainActor.assumeIsolated { windows.removeAll { $0 === closed } }
        }
    }
}
struct ImageMarkupEditor: View {
    let file: URL
    @State private var image: CGImage?
    @State private var loadFailed = false
    @State private var strokes: [MarkStroke] = []
    @State private var current: [MarkPoint] = []
    @State private var mode = "pen"
    @State private var text = "Nota"
    @State private var message = "El original se conserva. La copia PNG se publicará desde la cola."
    var body: some View {
        VStack(spacing: 14) {
            HStack {
                Picker("Herramienta", selection: $mode) { Text("Lápiz").tag("pen"); Text("Rectángulo").tag("rectangle"); Text("Ocultar región").tag("redact"); Text("Texto").tag("text") }.pickerStyle(.segmented)
                Button("Deshacer trazo") { if !strokes.isEmpty { strokes.removeLast() } }.disabled(strokes.isEmpty)
                Button("Guardar copia") { save() }.buttonStyle(.borderedProminent).disabled(strokes.isEmpty)
            }
            if mode == "text" { TextField("Texto de la anotación", text: $text) }
            if let image {
                GeometryReader { proxy in
                    let size = fitted(image, within: proxy.size)
                    ZStack(alignment: .topLeading) {
                        Image(decorative: image, scale: 1).resizable().frame(width: size.width,height: size.height)
                        Canvas { context, _ in
                            for stroke in strokes + (current.isEmpty ? [] : [MarkStroke(kind: mode, points: current, text: text)]) { draw(stroke, context: &context, size: size) }
                        }.frame(width: size.width,height: size.height)
                        .contentShape(Rectangle())
                        .gesture(DragGesture(minimumDistance: 0).onChanged { value in
                            let point = MarkPoint(x: max(0,min(1,value.location.x / size.width)), y: max(0,min(1,value.location.y / size.height)))
                            if current.isEmpty { current = [point] }
                            else if mode == "pen" { if current.count < 10_000 { current.append(point) } }
                            else { current = [current[0],point] }
                        }.onEnded { _ in if !current.isEmpty { strokes.append(MarkStroke(kind: mode, points: current, text: text)); current = [] } })
                    }.frame(maxWidth: .infinity,maxHeight: .infinity)
                }
            } else if loadFailed { ContentUnavailableView("No se pudo leer la imagen", systemImage: "photo.badge.exclamationmark") }
            else { ProgressView("Preparando vista previa…") }
            Text(message).font(.caption).foregroundStyle(.secondary)
        }.padding(20).frame(minWidth: 700,minHeight: 500)
        .task { image = await thumbnail(file); loadFailed = image == nil }
    }
    private func fitted(_ image: CGImage, within size: CGSize) -> CGSize {
        let scale = min(size.width / CGFloat(image.width),size.height / CGFloat(image.height))
        return CGSize(width: CGFloat(image.width)*scale,height: CGFloat(image.height)*scale)
    }
    private func draw(_ stroke: MarkStroke, context: inout GraphicsContext, size: CGSize) {
        let points = stroke.points.map { CGPoint(x: $0.x*size.width,y: $0.y*size.height) }
        guard let first = points.first, let last = points.last else { return }
        let rect = CGRect(x: min(first.x,last.x),y: min(first.y,last.y),width: abs(last.x-first.x),height: abs(last.y-first.y))
        if stroke.kind == "redact" { context.fill(Path(rect),with: .color(.black)) }
        else if stroke.kind == "rectangle" { context.stroke(Path(rect),with: .color(.orange),lineWidth: max(2,size.width*0.005)) }
        else if stroke.kind == "text" { context.draw(Text(stroke.text).font(.system(size: max(14,size.width*0.025),weight: .bold)).foregroundStyle(.orange),at: first,anchor: .topLeading) }
        else { var path = Path(); path.move(to: first); for point in points.dropFirst() { path.addLine(to: point) }; context.stroke(path,with: .color(.orange),style: StrokeStyle(lineWidth: max(2,size.width*0.005),lineCap: .round,lineJoin: .round)) }
    }
    @concurrent private func thumbnail(_ file: URL) async -> CGImage? { Images.thumbnail(file,maxPixel: 1400) }
    private func save() {
        do {
            let json = String(decoding: try JSONEncoder().encode(strokes),as: UTF8.self)
            let recipe = Recipe(name: "Anotar imagen",steps: [.init(action: "imageMarkup",text: json)],preserveMetadata: false)
            WorkspaceStore.shared.enqueue(inputs: [file],recipe: recipe)
            message = "Copia añadida a Actividad. Revisa la salida antes de compartir."
        } catch { message = error.localizedDescription }
    }
}
