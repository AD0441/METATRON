import AppKit
import Combine

/// Opens the project's releases on explicit request. No background networking
/// and no claim that the installed build is already the latest release.
final class UpdateChecker: ObservableObject {
    static let shared = UpdateChecker()
    static let releasesURL = URL(string: "https://github.com/AD0441/METATRON/releases")!
    @Published private(set) var available: String?
    var onChange: (() -> Void)?
    var current: String { Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "dev" }
    func startAutomaticChecks() {}
    func check(userInitiated: Bool) {
        guard userInitiated else { return }
        if !NSWorkspace.shared.open(Self.releasesURL) {
            ToastCenter.shared.showFailure("No se pudo abrir el navegador", detail: "Visita github.com/AD0441/METATRON/releases para consultar las versiones.")
        }
    }
    func installUpdate() { check(userInitiated: true) }
    static func isNewer(_ a: String, than b: String) -> Bool { a.compare(b, options: .numeric) == .orderedDescending }
}
