import Foundation

struct ParsedTaskDraft: Codable {
    var name: String
    var estimatedMinutes: Int?
    var priority: TaskPriority
    var deadlineRaw: String?
    var needsConfirmation: Bool
    var note: String?
    var taskType: TaskType

    enum CodingKeys: String, CodingKey {
        case name
        case estimatedMinutes = "estimated_minutes"
        case priority
        case deadlineRaw = "deadline"
        case needsConfirmation = "needs_confirmation"
        case note
        case taskType = "task_type"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = try c.decode(String.self, forKey: .name)
        estimatedMinutes = try c.decodeIfPresent(Int.self, forKey: .estimatedMinutes)
        priority = try c.decode(TaskPriority.self, forKey: .priority)
        deadlineRaw = try c.decodeIfPresent(String.self, forKey: .deadlineRaw)
        needsConfirmation = try c.decode(Bool.self, forKey: .needsConfirmation)
        note = try c.decodeIfPresent(String.self, forKey: .note)
        taskType = try c.decodeIfPresent(TaskType.self, forKey: .taskType) ?? .shallow
    }

    /// Parse deadlineRaw (ISO8601 đầy đủ hoặc date-only) sang Date nếu được.
    var deadlineDate: Date? {
        guard let raw = deadlineRaw, !raw.isEmpty else { return nil }
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = iso.date(from: raw) { return d }
        iso.formatOptions = [.withInternetDateTime]
        if let d = iso.date(from: raw) { return d }
        let dateOnly = DateFormatter()
        dateOnly.dateFormat = "yyyy-MM-dd"
        dateOnly.timeZone = TimeZone(identifier: "UTC")
        return dateOnly.date(from: raw)
    }
}

extension ParsedTaskDraft: Identifiable {
    var id: String { name }
}
