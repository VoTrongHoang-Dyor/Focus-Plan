import Foundation

struct HabitBusyBlockService {
    /// Xuất busy-block cho từng habit vào ngày `date`. Hàm thuần, deterministic.
    /// Là interface Scheduling Engine (issue 004) sẽ đọc để tránh xếp task đè lên habit.
    func busyBlocks(habits: [Habit], on date: Date, calendar: Calendar = .current) -> [BusyBlock] {
        habits.compactMap { habit in
            guard let (hour, minute) = habit.timeComponents,
                  let start = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: date)
            else { return nil }
            let end = start.addingTimeInterval(TimeInterval(habit.durationMinutes * 60))
            return BusyBlock(habitId: habit.id, start: start, end: end)
        }
    }
}
