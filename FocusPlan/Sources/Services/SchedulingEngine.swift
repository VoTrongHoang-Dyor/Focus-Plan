import Foundation

struct SchedulingEngine {
    struct Config {
        var dayStartHour: Int = 8
        var dayEndHour: Int = 22
        var bufferMinutes: Int = 10
        var defaultDurationMinutes: Int = 30
    }

    func schedule(tasks: [TaskItem], busyBlocks: [BusyBlock], on date: Date,
                  calendar: Calendar = .current, config: Config = Config()) -> ScheduleResult {
        guard let dayStart = calendar.date(bySettingHour: config.dayStartHour, minute: 0, second: 0, of: date),
              let dayEnd = calendar.date(bySettingHour: config.dayEndHour, minute: 0, second: 0, of: date)
        else { return ScheduleResult(scheduled: [], unscheduled: tasks.map(\.id)) }

        // Busy-block giao trong ngày, sort theo start.
        let busy = busyBlocks
            .filter { $0.end > dayStart && $0.start < dayEnd }
            .sorted { $0.start < $1.start }

        let ordered = tasks.sorted { a, b in
            if a.taskType.energyOrder != b.taskType.energyOrder {
                return a.taskType.energyOrder < b.taskType.energyOrder
            }
            if a.priority.sortRank != b.priority.sortRank {
                return a.priority.sortRank < b.priority.sortRank
            }
            let da = a.estimatedMinutes ?? config.defaultDurationMinutes
            let db = b.estimatedMinutes ?? config.defaultDurationMinutes
            if da != db { return da > db }                 // dài trước
            if a.createdAt != b.createdAt { return a.createdAt < b.createdAt }
            return a.id.uuidString < b.id.uuidString        // chốt total order
        }

        var scheduled: [ScheduledBlock] = []
        var unscheduled: [UUID] = []
        let buffer = TimeInterval(config.bufferMinutes * 60)
        var cursor = dayStart

        for task in ordered {
            let duration = TimeInterval((task.estimatedMinutes ?? config.defaultDurationMinutes) * 60)
            if let placedStart = earliestFit(from: cursor, duration: duration,
                                             dayEnd: dayEnd, busy: busy) {
                let placedEnd = placedStart.addingTimeInterval(duration)
                scheduled.append(ScheduledBlock(taskId: task.id, start: placedStart, end: placedEnd))
                cursor = placedEnd.addingTimeInterval(buffer)
            } else {
                unscheduled.append(task.id)
            }
        }
        return ScheduleResult(scheduled: scheduled, unscheduled: unscheduled)
    }

    /// Tìm start sớm nhất >= from để [start, start+duration] không giao busy & <= dayEnd.
    private func earliestFit(from: Date, duration: TimeInterval, dayEnd: Date,
                             busy: [BusyBlock]) -> Date? {
        var start = from
        while start.addingTimeInterval(duration) <= dayEnd {
            if let hit = busy.first(where: { $0.start < start.addingTimeInterval(duration) && $0.end > start }) {
                start = hit.end                              // nhảy qua busy-block đang chắn
            } else {
                return start
            }
        }
        return nil
    }
}
