import Foundation

struct ScheduledBlock: Equatable {
    let taskId: UUID
    let start: Date
    let end: Date
}
