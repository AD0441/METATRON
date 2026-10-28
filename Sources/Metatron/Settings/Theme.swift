import MetatronCore
import SwiftUI

struct ThemePreset: Identifiable, Hashable {
    let id: String
    let name: String
    let accent: String
    let accent2: String

    static let all: [ThemePreset] = [
        ThemePreset(id: "metatron", name: "Petróleo", accent: "#365D72", accent2: "#234A60"),
        ThemePreset(id: "forest", name: "Bosque", accent: "#476957", accent2: "#305340"),
        ThemePreset(id: "graphite", name: "Grafito", accent: "#58616B", accent2: "#3D4650"),
        ThemePreset(id: "slate", name: "Pizarra", accent: "#526987", accent2: "#3F5574"),
        ThemePreset(id: "burgundy", name: "Burdeos", accent: "#805564", accent2: "#683F4F"),
    ]

    var localizedName: String { L(name) }
}

/// Everything the ring needs to draw itself.
struct Theme {
    var accent: SwiftUI.Color
    var accent2: SwiftUI.Color
    var sliceOpacity: Double
    var glass: GlassStyle
    var size: Double
    var labels: LabelStyle
    var scheme: RingScheme
    /// False in the live ring, where the window draws the frosted blur itself (with a true round mask).
    var drawsBackdrop = true

    var gradient: LinearGradient {
        LinearGradient(colors: [accent, accent2], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    var colorScheme: ColorScheme? {
        switch scheme {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

extension SwiftUI.Color {
    init(hex: String) {
        let c = HexColor.components(hex)
        self.init(.sRGB, red: c.r, green: c.g, blue: c.b, opacity: c.a)
    }

    var hex: String {
        let ns = NSColor(self).usingColorSpace(.sRGB) ?? .orange
        return HexColor.hex(r: ns.redComponent, g: ns.greenComponent, b: ns.blueComponent)
    }
}
