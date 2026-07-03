import Foundation

enum HabitStatus: String, Codable {
    case done, missed
}

struct HabitLog: Codable, Identifiable, Equatable {
    let id: UUID
    let habitId: UUID
    let logDate: String          // Postgres `date` -> "yyyy-MM-dd"
    var status: HabitStatus

    enum CodingKeys: String, CodingKey {
        case id
        case habitId = "habit_id"
        case logDate = "log_date"
        case status
    }
}

/// Payload upsert log theo (habit_id, log_date). user_id = DB default.
struct NewHabitLog: Encodable {
    var habitId: UUID
    var logDate: String
    var status: HabitStatus
    enum CodingKeys: String, CodingKey {
        case habitId = "habit_id"
        case logDate = "log_date"
        case status
    }
}
