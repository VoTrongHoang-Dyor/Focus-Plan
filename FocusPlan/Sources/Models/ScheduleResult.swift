import Foundation

struct ScheduleResult: Equatable {
    let scheduled: [ScheduledBlock]
    let unscheduled: [UUID]   // task không đủ chỗ trong ngày
}
