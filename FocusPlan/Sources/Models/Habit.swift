import Foundation

struct Habit: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var timeOfDay: String        // Postgres `time` -> "HH:mm:ss" (vd "06:00:00")
    var durationMinutes: Int
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, name
        case timeOfDay = "time_of_day"
        case durationMinutes = "duration_minutes"
        case createdAt = "created_at"
    }

    /// Tách giờ:phút từ timeOfDay ("06:00:00" -> (6, 0)).
    var timeComponents: (hour: Int, minute: Int)? {
        let parts = timeOfDay.split(separator: ":")
        guard parts.count >= 2, let h = Int(parts[0]), let m = Int(parts[1]) else { return nil }
        return (h, m)
    }
}

/// Payload insert — bỏ id/user_id/created_at (DB default; user_id = auth.uid()).
struct NewHabit: Encodable {
    var name: String
    var timeOfDay: String
    var durationMinutes: Int
    enum CodingKeys: String, CodingKey {
        case name
        case timeOfDay = "time_of_day"
        case durationMinutes = "duration_minutes"
    }
}

struct HabitUpdate: Encodable {
    var name: String
    var timeOfDay: String
    var durationMinutes: Int
    enum CodingKeys: String, CodingKey {
        case name
        case timeOfDay = "time_of_day"
        case durationMinutes = "duration_minutes"
    }
}
