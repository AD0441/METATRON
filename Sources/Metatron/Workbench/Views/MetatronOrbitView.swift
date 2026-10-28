import SwiftUI
import MetatronCore

/// A transparent desktop surface. Only the individual circular controls have a material.
struct MetatronOrbitView: View {
    @ObservedObject var model: RingModel
    @ObservedObject private var settings = SettingsStore.shared
    @Environment(\.colorScheme) private var systemScheme
    private var geo: OrbitGeometry { OrbitGeometry(size:settings.ringSize,layout:settings.quickAccessStyle == .bubbles ? .bubbles : .metatron) }
    private var dark: Bool { (settings.theme.colorScheme ?? systemScheme) == .dark }
    private var theme: Theme { var t=settings.theme;t.drawsBackdrop=false;return t }
    var body: some View {
        let side=geo.side, origin=CGPoint(x:side/2,y:side/2)
        ZStack {
            if settings.quickAccessStyle == .metatron { connections }
            hub.position(origin)
            ForEach(Array(model.items.enumerated()),id:\.element.id) { index,item in
                if let p=geo.center(for:index,count:model.items.count) {
                    node(index,item).position(x:origin.x+p.x,y:origin.y+p.y)
                }
            }
            if model.progress == nil {
                Text("\(model.pageTitle) · \(model.items.count) acciones · Tab para cambiar")
                    .font(.system(size:10*geo.scale,weight:.medium)).foregroundStyle(.primary)
                    .padding(.horizontal,10).padding(.vertical,5)
                    .background(Color(nsColor:.controlBackgroundColor).opacity(0.94),in:Capsule())
                    .position(x:origin.x,y:origin.y+geo.radius(count:model.items.count)+geo.nodeRadius+24*geo.scale)
                    .allowsHitTesting(false)
            }
        }
        .frame(width:side,height:side)
        .opacity(model.shown ? 1 : 0)
        .animation(nil,value:model.shown)
        .environment(\.colorScheme,theme.colorScheme ?? systemScheme)
    }
    private var connections: some View {
        Canvas { context,size in
            let c=CGPoint(x:size.width/2,y:size.height/2), r=geo.radius(count:model.items.count)
            func point(_ i:Int)->CGPoint {let p=MetatronGeometry.centers[i];return CGPoint(x:c.x+p.x*r,y:c.y+p.y*r)}
            var path=Path()
            for edge in MetatronGeometry.edges {path.move(to:point(edge.0));path.addLine(to:point(edge.1))}
            context.stroke(path,with:.color(settings.interfaceAccent.opacity(0.32)),lineWidth:0.8*geo.scale)
            var circles=Path()
            for index in 0..<13 {
                let p=point(index),radius=geo.nodeRadius
                circles.addEllipse(in:CGRect(x:p.x-radius,y:p.y-radius,width:2*radius,height:2*radius))
            }
            context.stroke(circles,with:.color(settings.interfaceAccent.opacity(0.18)),lineWidth:geo.scale)
        }.allowsHitTesting(false).accessibilityHidden(true)
    }
    private var hub: some View {
        Button { RingController.shared.hubClicked() } label: {
            ZStack {
                BlurView(material:dark ? .hudWindow : .popover,dark:dark)
                if let progress=model.progress {
                    RingProgress(progress:progress,finished:model.finished,theme:theme,scale:geo.scale,
                                 title:model.chosen.flatMap {model.items.indices.contains($0) ? model.items[$0].title : nil} ?? "")
                } else {
                    VStack(spacing:3*geo.scale) {
                        FileIcon(urls:model.files).frame(width:32*geo.scale,height:32*geo.scale)
                        Text(model.pageTitle).font(.system(size:9*geo.scale,weight:.semibold))
                        if model.files.count > 1 {Text("\(model.files.count) archivos").font(.system(size:8*geo.scale))}
                    }.foregroundStyle(.primary)
                }
            }.frame(width:2*geo.hubRadius,height:2*geo.hubRadius)
                .overlay(Circle().strokeBorder(settings.interfaceAccent.opacity(0.75),lineWidth:1.1))
        }.buttonStyle(.plain).help("\(model.files.first?.lastPathComponent ?? "Archivos") · pulsa el centro para cambiar de categoría")
    }
    private func node(_ index:Int,_ item:RingItem)->some View {
        let hot=model.hovered == index || model.chosen == index
        return Button {RingController.shared.choose(index,files:[])} label: {
            ZStack {
                BlurView(material:dark ? .hudWindow : .popover,dark:dark)
                if hot {Circle().fill(settings.interfaceAccent)}
                VStack(spacing:4*geo.scale) {
                    Image(systemName:item.symbol).font(.system(size:15*geo.scale,weight:.medium))
                    Text(item.title).font(.system(size:10*geo.scale,weight:.medium)).lineLimit(3)
                        .multilineTextAlignment(.center).frame(width:2*geo.nodeRadius-12*geo.scale)
                }.foregroundStyle(hot ? Color(nsColor:.textBackgroundColor) : Color.primary)
            }.frame(width:2*geo.nodeRadius,height:2*geo.nodeRadius)
                .overlay(Circle().strokeBorder(hot ? settings.interfaceAccent : Color.primary.opacity(0.14),lineWidth:1))
                .opacity(model.progress != nil && model.chosen != index ? 0.45 : 1)
                .contentShape(Circle())
        }.buttonStyle(.plain).help(item.destination?.folder.path ?? item.title)
            .accessibilityLabel(item.destination == nil ? item.title : "Mover a " + item.title)
    }
}
