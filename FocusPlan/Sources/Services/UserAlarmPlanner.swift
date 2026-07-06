import Foundation

/// Map UserAlarm → [PlannedAlarm] tái dùng hạ tầng issue 005.
/// Identifier dùng CHUNG prefix "alarm-<uuid>-<i>" với task alarm → snooze/done/
/// mở-app-dừng-chuỗi (AlarmAppDelegate, AlarmScheduler.cancel*) chạy nguyên vẹn.
struct UserAlarmPlanner {
    /// Occurrence kế tiếp sau `now` tại hour:minute thuộc repeatDays (rỗng = ngày bất kỳ).
    func nextFireDate(for alarm: UserAlarm, after now: Date,
                      calendar: Calendar = .current) -> Date? {
        for dayOffset in 0...7 {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: now),
                  let fire = calendar.date(bySettingHour: alarm.hour, minute: alarm.minute,
                                           second: 0, of: day),
                  fire > now else { continue }
            let weekday = calendar.component(.weekday, from: fire)
            if alarm.repeatDays.isEmpty || alarm.repeatDays.contains(weekday) { return fire }
        }
        return nil
    }

    /// PlannedAlarm cho occurrence kế tiếp. showNotification=false → rỗng.
    /// loopAudio=true → chùm escalating mặc định (6 mốc/2'); false → 1 notification.
    func plannedAlarms(for alarm: UserAlarm, now: Date,
                       calendar: Calendar = .current) -> [PlannedAlarm] {
        guard alarm.showNotification,
              let fire = nextFireDate(for: alarm, after: now, calendar: calendar) else { return [] }
        var config = AlarmPlanner.Config()
        if !alarm.loopAudio { config.repeatCount = 1 }
        return AlarmPlanner().plan(taskId: alarm.id, taskName: "Báo thức",
                                   start: fire, now: now, config: config)
    }

    func plannedAlarms(for alarms: [UserAlarm], now: Date,
                       calendar: Calendar = .current) -> [PlannedAlarm] {
        alarms.flatMap { plannedAlarms(for: $0, now: now, calendar: calendar) }
    }
}
