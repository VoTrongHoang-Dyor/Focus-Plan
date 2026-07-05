import Foundation

struct AlarmPlanner {
    struct Config {
        var repeatCount: Int = 6
        var intervalMinutes: Int = 2
        var maxPendingBudget: Int = 60
    }

    func plan(taskId: UUID, taskName: String, start: Date, now: Date,
              config: Config = Config()) -> [PlannedAlarm] {
        (0..<config.repeatCount).compactMap { i in
            let fire = start.addingTimeInterval(TimeInterval(i * config.intervalMinutes * 60))
            guard fire > now else { return nil }
            return PlannedAlarm(
                identifier: "alarm-\(taskId.uuidString)-\(i)",
                fireDate: fire,
                title: Self.title(index: i),
                body: Self.body(taskName: taskName))
        }
    }

    /// Nhiều task: sort theo giờ bắt đầu, gom chùm, cắt theo budget tổng (né 64-limit).
    func planMany(_ items: [(id: UUID, name: String, start: Date)], now: Date,
                  config: Config = Config()) -> [PlannedAlarm] {
        let ordered = items.sorted { $0.start < $1.start }
        var out: [PlannedAlarm] = []
        for item in ordered {
            let chunk = plan(taskId: item.id, taskName: item.name, start: item.start, now: now, config: config)
            for a in chunk {
                if out.count >= config.maxPendingBudget { return out }
                out.append(a)
            }
        }
        return out
    }

    private static func title(index: Int) -> String {
        switch index {
        case 0: return "⏰ Đến giờ rồi"
        case 1: return "Bắt đầu ngay nào"
        case 2: return "Bạn đang trễ…"
        case 3: return "Đừng trì hoãn nữa!"
        case 4: return "😤 Nghiêm túc nào"
        default: return "⏰⏰ LÀM NGAY"
        }
    }

    private static func body(taskName: String) -> String {
        "Task: \(taskName)"
    }
}
