import Foundation

enum TaskPriority: String, Codable, CaseIterable, Identifiable {
    case low, medium, high
    var id: String { rawValue }
    var label: String {
        switch self {
        case .low: return "Thấp"
        case .medium: return "Trung bình"
        case .high: return "Cao"
        }
    }
    /// Rank cho sort của SchedulingEngine: cao (high) xếp trước.
    var sortRank: Int {
        switch self {
        case .high: return 0
        case .medium: return 1
        case .low: return 2
        }
    }
}
