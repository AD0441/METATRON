import SwiftUI

/// Restrained native surfaces; system text and backgrounds adapt to appearance and contrast.
enum MetatronStyle {
    static var accent: Color { SettingsStore.shared.interfaceAccent }
    static let panel = Color(nsColor: .controlBackgroundColor)
    static let canvas = Color(nsColor: .windowBackgroundColor)
    static let divider = Color(nsColor: .separatorColor)
}
