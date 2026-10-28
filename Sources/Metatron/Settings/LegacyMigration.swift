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
        guard directory.lastPathComponent == "METATRON", !fm.fileExists(atPath: directory.appendingPathComponent("workspace.json").path), fm.fileExists(atPath: legacy.appendingPathComponent("workspace.json").path) else { return }
        try fm.createDirectory(at:directory,withIntermediateDirectories:true)
        let children=try fm.contentsOfDirectory(at:legacy,includingPropertiesForKeys:nil).sorted { $0.lastPathComponent == "workspace.json" ? false : $1.lastPathComponent == "workspace.json" }
        for source in children where source.lastPathComponent != "instance.lock" {
            let target=directory.appendingPathComponent(source.lastPathComponent)
            if !fm.fileExists(atPath:target.path) {try fm.copyItem(at:source,to:target)}
        }
    }
}
