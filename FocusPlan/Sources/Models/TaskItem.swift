import Foundation

struct TaskItem: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var estimatedMinutes: Int?
    var priority: TaskPriority
    var deadline: Date?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, name
        case estimatedMinutes = "estimated_minutes"
        case priority, deadline
        case createdAt = "created_at"
    }
}

/// Payload insert — bỏ id/user_id/created_at để DB tự điền (user_id = default auth.uid()).
struct NewTask: Encodable {
    var name: String
    var estimatedMinutes: Int?
    var priority: TaskPriority
    var deadline: Date?
    enum CodingKeys: String, CodingKey {
        case name
        case estimatedMinutes = "estimated_minutes"
        case priority, deadline
    }
}

/// Payload update.
struct TaskUpdate: Encodable {
    var name: String
    var estimatedMinutes: Int?
    var priority: TaskPriority
    var deadline: Date?
    enum CodingKeys: String, CodingKey {
        case name
        case estimatedMinutes = "estimated_minutes"
        case priority, deadline
    }
}
