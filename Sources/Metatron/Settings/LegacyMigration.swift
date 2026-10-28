import Foundation

enum LegacyMigration {
    static func preferences() {
        let defaults = UserDefaults.standard
        guard Bundle.main.bundleIdentifier == "local.metatron.app", !defaults.bool(forKey: "migratedCitrinoPreferences") else { return }
        if defaults.data(forKey: "triggerKey") == nil,
           let legacy = defaults.persistentDomain(forName: "local.citrino.app") {
            for (key, value) in legacy where !key.hasPrefix("NS") && !key.hasPrefix("Apple") { defaults.set(value, forKey: key) }
            if let data = defaults.data(forKey: "themeID"), (try? JSONDecoder().decode(String.self, from: data)) == "citrino" {
                defaults.set(try? JSONEncoder().encode("metatron"), forKey: "themeID")
            }
        }
        defaults.set(true, forKey: "migratedCitrinoPreferences")
    }
    static func workspace(to directory: URL) throws {
        let legacy = URL.applicationSupportDirectory.appendingPathComponent("Citrino", isDirectory: true)
        let fm = FileManager.default
        guard directory.lastPathComponent == "METATRON", !fm.fileExists(atPath: directory.path), fm.fileExists(atPath: legacy.path) else { return }
        try fm.copyItem(at: legacy, to: directory)
    }
}
