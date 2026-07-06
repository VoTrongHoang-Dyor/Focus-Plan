import Foundation

/// Một phiên Pomodoro ĐÃ HOÀN THÀNH (chạy hết duration). Nguồn dữ liệu cho
/// gamification (009), reflection (008), energy matching (013).
struct PomodoroSession: Codable, Identifiable, Equatable {
    let id: UUID
    let startedAt: Date
    let durationMinutes: Int
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case startedAt = "started_at"
        case durationMinutes = "duration_minutes"
        case createdAt = "created_at"
    }
}

/// Payload insert — startedAt gửi dạng chuỗi ISO8601 (tránh phụ thuộc date-encoding
/// strategy của client); id/user_id/created_at để DB default.
struct NewPomodoroSession: Encodable {
    var startedAt: String
    var durationMinutes: Int
    enum CodingKeys: String, CodingKey {
        case startedAt = "started_at"
        case durationMinutes = "duration_minutes"
    }
}
