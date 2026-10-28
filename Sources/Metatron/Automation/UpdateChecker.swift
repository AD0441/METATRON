import AppKit
import Combine
/// Local build: updates are installed by rebuilding this project.
final class UpdateChecker: ObservableObject {
    static let shared = UpdateChecker()
    static let releasesURL = URL(string: "https://github.com/iandifilippo/Kumquat")!
    @Published private(set) var available: String?
    var onChange: (() -> Void)?
    var current: String { "1.0.0" }
    func startAutomaticChecks() {}
    func check(userInitiated: Bool) { ToastCenter.shared.showInfo("Metatron · compilación local", detail: "Usa el proyecto en CODEX para actualizar esta aplicación.") }
    func installUpdate() { check(userInitiated: true) }
    static func isNewer(_ a: String, than b: String) -> Bool { a.compare(b, options: .numeric) == .orderedDescending }
}
