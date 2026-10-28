import Foundation

public enum ActivityRetention {
    public static let choices = [0, 7, 14, 30]
    public static func retained(_ jobs: [WorkJob], days: Int, now: Date = Date()) -> [WorkJob] {
        guard choices.contains(days), days > 0 else { return jobs }
        let cutoff = now.addingTimeInterval(-Double(days) * 86400)
        return jobs.filter { isActive($0) || $0.created >= cutoff }
    }
    public static func isActive(_ job: WorkJob) -> Bool { job.state == .queued || job.state == .running }
    public static func label(_ days: Int) -> String { days == 0 ? "Conservar todo" : "Conservar \(days) días" }
}
public struct SavedDestination: Codable, Hashable, Identifiable, Sendable {
    public var id: UUID
    public var name: String
    public var folder: URL
    public init(name: String, folder: URL) { id = UUID(); self.name = name; self.folder = folder }
}
