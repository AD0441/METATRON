import SwiftUI
import MetatronCore

enum Brand {
    static let name = "METATRON"
    static let author = "Creado por Sebastián Pastén F."
    static let donation = URL(string: "https://ko-fi.com/C0C51WQ1T0")!
    static let repository = URL(string: "https://github.com/AD0441/METATRON")!
}
struct MetatronMark: View {
    var lineWidth: CGFloat = 1.2
    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            let radius = side * 0.37
            let center = CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)
            Path { path in
                for edge in MetatronGeometry.edges {
                    let a = MetatronGeometry.centers[edge.0], b = MetatronGeometry.centers[edge.1]
                    path.move(to: CGPoint(x: center.x + a.x * radius, y: center.y + a.y * radius))
                    path.addLine(to: CGPoint(x: center.x + b.x * radius, y: center.y + b.y * radius))
                }
            }.stroke(.primary.opacity(0.42), lineWidth: lineWidth * 0.65)
            Path { path in
                for p in MetatronGeometry.centers {
                    let r = radius * 0.25
                    path.addEllipse(in: CGRect(x: center.x + p.x * radius - r, y: center.y + p.y * radius - r, width: 2*r, height: 2*r))
                }
            }.stroke(.primary, lineWidth: lineWidth)
        }.accessibilityLabel("Símbolo geométrico de METATRON").accessibilityHidden(true)
    }
}
struct DonationLink: View {
    var body: some View {
        Link(destination: Brand.donation) {
            Label("Apoyar en Ko-fi", systemImage: "cup.and.saucer.fill")
        }.help("Abre la página de aportes voluntarios en Ko-fi")
    }
}
