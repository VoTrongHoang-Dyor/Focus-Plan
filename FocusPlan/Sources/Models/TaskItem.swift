import Foundation

struct TaskItem: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var estimatedMinutes: Int?
    var priority: TaskPriority
    var deadline: Date?
    var taskType: TaskType
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, name
        case estimatedMinutes = "estimated_minutes"
        case priority, deadline
        case taskType = "task_type"
        case createdAt = "created_at"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        estimatedMinutes = try c.decodeIfPresent(Int.self, forKey: .estimatedMinutes)
        priority = try c.decode(TaskPriority.self, forKey: .priority)
        deadline = try c.decodeIfPresent(Date.self, forKey: .deadline)
        taskType = try c.decodeIfPresent(TaskType.self, forKey: .taskType) ?? .shallow
        createdAt = try c.decode(Date.self, forKey: .createdAt)
    }

    // Init thường cho test/khởi tạo tay.
    init(id: UUID, name: String, estimatedMinutes: Int?, priority: TaskPriority,
         deadline: Date?, taskType: TaskType, createdAt: Date) {
        self.id = id; self.name = name; self.estimatedMinutes = estimatedMinutes
        self.priority = priority; self.deadline = deadline
        self.taskType = taskType; self.createdAt = createdAt
    }
}

/// Payload insert — bỏ id/user_id/created_at để DB tự điền (user_id = default auth.uid()).
struct NewTask: Encodable {
    var name: String
    var estimatedMinutes: Int?
    var priority: TaskPriority
    var deadline: Date?
    var taskType: TaskType = .shallow
    enum CodingKeys: String, CodingKey {
        case name
        case estimatedMinutes = "estimated_minutes"
        case priority, deadline
        case taskType = "task_type"
    }
}

/// Payload update.
struct TaskUpdate: Encodable {
    var name: String
    var estimatedMinutes: Int?
    var priority: TaskPriority
    var deadline: Date?
    var taskType: TaskType = .shallow
    enum CodingKeys: String, CodingKey {
        case name
        case estimatedMinutes = "estimated_minutes"
        case priority, deadline
        case taskType = "task_type"
    }
}
