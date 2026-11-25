import SwiftUI
import MetatronCore

/// The desktop remains visible between the independently masked circular controls.
struct MetatronOrbitView: View {
    @ObservedObject var model: RingModel
    @ObservedObject private var settings = SettingsStore.shared
    @Environment(\.colorScheme) private var systemScheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast
    private var geo: OrbitGeometry { OrbitGeometry(size: settings.ringSize, layout: settings.quickAccessStyle == .bubbles ? .bubbles : .metatron) }
    private var dark: Bool { (settings.theme.colorScheme ?? systemScheme) == .dark }
    private var theme: Theme { var value = settings.theme; value.drawsBackdrop = false; return value }
    private var selectedFill: Color { settings.theme.accent2 }

    var body: some View {
        let side = geo.side
        let origin = CGPoint(x: side / 2, y: side / 2)
        ZStack {
            if settings.quickAccessStyle == .metatron { connections }
            hub.position(origin)
            ForEach(Array(model.items.enumerated()), id: \.element.id) { index, item in
                if let point = geo.center(for: index, count: model.items.count) {
                    node(index, item).position(x: origin.x + point.x, y: origin.y + point.y)
                }
            }
            if model.progress == nil {
                HStack(spacing: 7) {
                    Text(model.pageTitle).fontWeight(.semibold)
                    Text("·").foregroundStyle(.secondary)
                    Text("Tab para cambiar").foregroundStyle(.secondary)
                }
                .font(.system(size: 11 * geo.scale))
                .padding(.horizontal, 12).padding(.vertical, 7)
                .background(Color(nsColor: .controlBackgroundColor), in: Capsule())
                .position(x: origin.x, y: origin.y + geo.radius(count: model.items.count) + geo.nodeRadius + 20 * geo.scale)
                .allowsHitTesting(false)
            }
        }
        .frame(width: side, height: side)
        .opacity(model.shown ? 1 : 0)
        .animation(nil, value: model.shown)
        .environment(\.colorScheme, theme.colorScheme ?? systemScheme)
    }

    private var connections: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = geo.radius(count: model.items.count)
            func point(_ index: Int) -> CGPoint {
                let point = MetatronGeometry.centers[index]
                return CGPoint(x: center.x + point.x * radius, y: center.y + point.y * radius)
            }
            var mesh = Path()
            for edge in MetatronGeometry.edges {
                mesh.move(to: point(edge.0)); mesh.addLine(to: point(edge.1))
            }
            context.stroke(mesh, with: .color(settings.interfaceAccent.opacity(contrast == .increased ? 0.30 : 0.16)), lineWidth: geo.scale)

            var structure = Path()
            for vertices in [[1, 3, 5, 1], [2, 4, 6, 2], [1, 2, 3, 4, 5, 6, 1]] {
                structure.move(to: point(vertices[0]))
                for index in vertices.dropFirst() { structure.addLine(to: point(index)) }
            }
            context.stroke(structure, with: .color(settings.interfaceAccent.opacity(0.85)), style: StrokeStyle(lineWidth: 2.1 * geo.scale, lineCap: .round, lineJoin: .round))

            var spokes = Path()
            for index in 1...6 { spokes.move(to: center); spokes.addLine(to: point(index)) }
            context.stroke(spokes, with: .color(settings.interfaceAccent.opacity(0.55)), lineWidth: 1.4 * geo.scale)
            var circles = Path()
            for index in 0..<13 {
                let p = point(index), radius = geo.nodeRadius
                circles.addEllipse(in: CGRect(x: p.x - radius, y: p.y - radius, width: 2 * radius, height: 2 * radius))
            }
            context.stroke(circles, with: .color(settings.interfaceAccent.opacity(0.32)), lineWidth: 1.2 * geo.scale)
        }
        .allowsHitTesting(false).accessibilityHidden(true)
    }

    @ViewBuilder private var circularSurface: some View {
        if reduceTransparency || settings.glassStyle == .solid {
            Circle().fill(Color(nsColor: .controlBackgroundColor))
        } else {
            BlurView(material: dark ? .hudWindow : .popover, dark: dark)
                .overlay(Circle().fill(Color(nsColor: .controlBackgroundColor).opacity(dark ? 0.38 : 0.50)))
        }
    }

    private var hub: some View {
        Button { RingController.shared.hubClicked() } label: {
            ZStack {
                circularSurface
                if let progress = model.progress {
                    RingProgress(progress: progress, finished: model.finished, theme: theme, scale: geo.scale,
                                 title: model.chosen.flatMap { model.items.indices.contains($0) ? model.items[$0].title : nil } ?? "")
                } else {
                    VStack(spacing: 4 * geo.scale) {
                        FileIcon(urls: model.files).frame(width: 30 * geo.scale, height: 30 * geo.scale)
                        Text(model.pageTitle).font(.system(size: 10 * geo.scale, weight: .semibold))
                        if model.files.count > 1 { Text("\(model.files.count) archivos").font(.system(size: 9 * geo.scale)).foregroundStyle(.secondary) }
                    }.foregroundStyle(.primary)
                }
            }
            .frame(width: 2 * geo.hubRadius, height: 2 * geo.hubRadius)
            .clipShape(Circle())
            .overlay(Circle().strokeBorder(settings.interfaceAccent.opacity(0.85), lineWidth: 1.5))
            .shadow(color: .black.opacity(dark ? 0.28 : 0.14), radius: 7, y: 3)
            .contentShape(Circle())
        }
        .buttonStyle(OrbitButtonStyle())
        .help("\(model.files.first?.lastPathComponent ?? "Archivos") · pulsa el centro para cambiar de categoría")
        .accessibilityLabel("\(model.pageTitle). Cambiar categoría")
    }

    private func node(_ index: Int, _ item: RingItem) -> some View {
        let hot = model.hovered == index || model.chosen == index
        return Button { RingController.shared.choose(index, files: []) } label: {
            ZStack {
                circularSurface
                if hot { Circle().fill(selectedFill) }
                VStack(spacing: 5 * geo.scale) {
                    if settings.labelStyle != .text {
                        Image(systemName: item.symbol).font(.system(size: (settings.labelStyle == .icon ? 23 : 17) * geo.scale, weight: .medium))
                    }
                    if settings.labelStyle != .icon {
                        Text(item.title).font(.system(size: 10.5 * geo.scale, weight: .semibold))
                            .lineLimit(2).minimumScaleFactor(0.85).multilineTextAlignment(.center)
                            .frame(width: 2 * geo.nodeRadius - 12 * geo.scale)
                    }
                }.foregroundStyle(hot ? Color.white : Color.primary)
            }
            .frame(width: 2 * geo.nodeRadius, height: 2 * geo.nodeRadius)
            .clipShape(Circle())
            .overlay(Circle().strokeBorder(hot ? settings.interfaceAccent : Color.primary.opacity(contrast == .increased ? 0.6 : 0.20), lineWidth: hot ? 1.5 : 1))
            .shadow(color: .black.opacity(dark ? 0.24 : 0.12), radius: 6, y: 3)
            .opacity(model.progress != nil && model.chosen != index ? 0.45 : 1)
            .contentShape(Circle())
        }
        .buttonStyle(OrbitButtonStyle())
        .onHover { hovering in if model.mode == .click { model.hovered = hovering ? index : nil } }
        .help(item.destination?.folder.path ?? item.title)
        .accessibilityLabel(item.destination == nil ? item.title : "Mover a " + item.title)
    }
}

private struct OrbitButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.scaleEffect(configuration.isPressed ? 0.97 : 1)
    }
}
