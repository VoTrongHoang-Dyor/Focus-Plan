import Foundation

/// Báo thức user tạo từ AlarmFormView (template Smart Alarm — assets/4.jpg).
/// vibrate/systemVolumeMax: persist-only — iOS không có public API per-notification
/// (rung/âm lượng đi theo cài đặt hệ thống); xem plan 2026-07-06.
struct UserAlarm: Codable, Equatable, Identifiable {
    var id: UUID = UUID()
    var hour: Int                     // 0-23
    var minute: Int                   // 0-59
    var repeatDays: Set<Int> = []     // Calendar weekday: 1=CN … 7=T7. Rỗng = one-shot.
    var loopAudio: Bool = true        // true: chùm escalating 6 mốc/2'; false: 1 notification
    var vibrate: Bool = true          // persist-only
    var systemVolumeMax: Bool = true  // persist-only
    var showNotification: Bool = true // false: chỉ lưu, không arm
}
