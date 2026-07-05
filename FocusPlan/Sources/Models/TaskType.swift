import Foundation

enum TaskType: String, Codable, CaseIterable, Identifiable {
    case deep, shallow
    var id: String { rawValue }
    var label: String {
        switch self {
        case .deep: return "Deep work"
        case .shallow: return "Việc nhẹ"
        }
    }
    /// Thứ tự năng lượng cho sort của engine: deep xếp trước (buổi sáng).
    var energyOrder: Int {
        switch self {
        case .deep: return 0
        case .shallow: return 1
        }
    }
}
