import SwiftUI
import MetatronCore

struct MetatronOrbitView: View {
    @ObservedObject var model: RingModel
    @ObservedObject private var settings = SettingsStore.shared
    @State private var hovered: String?
    private let side: CGFloat = 440
    private let radius: CGFloat = 166
    private let nodeSize: CGFloat = 74
    private let categories = ["Convertir", "Herramientas", "Acciones", "Destinos"]
    var body: some View {
        VStack(spacing: 0) {
            Picker("Categoría", selection: $model.page) { ForEach(0..<4) { Text(categories[$0]).tag($0) } }
                .pickerStyle(.segmented).padding(.horizontal, 20).padding(.vertical, 10)
            if settings.quickAccessStyle == .bubbles { bubbleGrid }
            else { constellation }
            HStack {
                Text("\(model.items.count) acciones").font(.caption).foregroundStyle(.secondary)
                Spacer()
                Button("Siguiente categoría", systemImage: "arrow.right") { model.togglePage() }.controlSize(.small).keyboardShortcut(.rightArrow, modifiers: .option)
            }.padding(.horizontal, 20).padding(.bottom, 12)
        }

    }
    private var constellation: some View {
        ZStack {
            Canvas { context, size in
                let c = CGPoint(x: size.width / 2, y: size.height / 2)
                func point(_ index: Int) -> CGPoint { let p = MetatronGeometry.centers[index]; return CGPoint(x: c.x+p.x*radius, y: c.y+p.y*radius) }
                var lines = Path()
                for edge in MetatronGeometry.edges { lines.move(to: point(edge.0)); lines.addLine(to: point(edge.1)) }
                context.stroke(lines, with: .color(MetatronStyle.accent.opacity(0.14)), lineWidth: 0.7)
                var circles = Path()
                for index in 0..<13 { let p=point(index); circles.addEllipse(in: CGRect(x:p.x-nodeSize/2,y:p.y-nodeSize/2,width:nodeSize,height:nodeSize)) }
                context.stroke(circles, with: .color(MetatronStyle.accent.opacity(0.13)), lineWidth: 1)
            }.allowsHitTesting(false).accessibilityHidden(true)
            Button { model.togglePage() } label: {
                VStack(spacing: 3) { MetatronMark(lineWidth: 0.8).frame(width: 26, height: 26); Text(categories[min(model.page,3)]).font(.system(size: 10, weight: .semibold)) }
                    .frame(width: nodeSize, height: nodeSize).background(MetatronStyle.panel, in: Circle())
                    .overlay(Circle().strokeBorder(MetatronStyle.accent, lineWidth: 1.3))
            }.buttonStyle(.plain).help("Cambiar categoría · ⌥→").position(x:side/2,y:side/2)
            ForEach(Array(model.items.enumerated()), id: \.element.id) { index, item in
                if let p = MetatronGeometry.actionCenter(index, radius: radius, center: CGPoint(x: side/2,y:side/2)) { node(item).position(p) }
            }
        }.frame(width: side,height: side).frame(maxWidth:.infinity)
    }
    private var bubbleGrid: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 3), spacing: 18) {
                ForEach(model.items) { item in node(item) }
            }.padding(24)
        }.frame(height:260)
    }
    private func node(_ item: RingItem) -> some View {
        Button { QuickAccessController.perform(item, files: model.files) } label: {
            VStack(spacing: 5) {
                Image(systemName:item.symbol).font(.system(size:16, weight:.medium))
                Text(item.title).font(.system(size:10,weight:.medium)).multilineTextAlignment(.center).lineLimit(3).frame(width:nodeSize-12)
            }.foregroundStyle(hovered == item.id ? Color.white : settings.interfaceAccent)
                .frame(width:nodeSize,height:nodeSize)
                .background(hovered == item.id ? settings.interfaceAccent : MetatronStyle.panel, in:Circle())
                .overlay(Circle().strokeBorder(hovered == item.id ? settings.interfaceAccent : MetatronStyle.divider,lineWidth:1))
                .contentShape(Circle())
        }.buttonStyle(.plain).onHover { hovered = $0 ? item.id : nil }
            .help(item.destination?.folder.path ?? item.title)
            .accessibilityLabel(item.destination == nil ? item.title : "Mover a " + item.title)
            .dropDestination(for:URL.self) { urls,_ in guard !urls.isEmpty else{return false}; QuickAccessController.perform(item,files:urls);return true } isTargeted: { hovered = $0 ? item.id : nil }
    }
}
