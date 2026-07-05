import Foundation

@MainActor
final class TodayScheduleService {
    static let shared = TodayScheduleService()
    private let scheduler = AlarmScheduler(center: LiveNotificationScheduling())

    /// Recompute lịch hôm nay (deterministic) rồi arm lại toàn bộ alarm cho task còn tương lai.
    /// Gọi khi app trở active → cũng chính là điểm "mở app dừng chuỗi đang chạy"
    /// (cancel hết alarm-* rồi arm lại theo lịch, mốc đã qua bị bỏ).
    func refreshAndArm(now: Date = Date(), calendar: Calendar = .current) async {
        await scheduler.cancelAllAlarms()
        guard let tasks = try? await TaskRepository().fetchAll(),
              let habits = try? await HabitRepository().fetchHabits() else { return }

        let busy = HabitBusyBlockService().busyBlocks(habits: habits, on: now, calendar: calendar)
        let result = SchedulingEngine().schedule(tasks: tasks, busyBlocks: busy, on: now,
                                                 calendar: calendar, config: .init())
        let byId = Dictionary(tasks.map { ($0.id, $0.name) }, uniquingKeysWith: { a, _ in a })
        let items: [(id: UUID, name: String, start: Date)] = result.scheduled.compactMap { blk in
            guard let name = byId[blk.taskId] else { return nil }
            return (blk.taskId, name, blk.start)
        }
        let planned = AlarmPlanner().planMany(items, now: now)
        await scheduler.arm(planned, calendar: calendar)
    }
}
