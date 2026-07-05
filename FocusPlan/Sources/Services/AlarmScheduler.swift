import Foundation
import UserNotifications

protocol NotificationScheduling {
    func add(_ request: UNNotificationRequest) async throws
    func removePending(identifiers: [String])
    func pendingIdentifiers() async -> [String]
}

struct LiveNotificationScheduling: NotificationScheduling {
    private let center = UNUserNotificationCenter.current()
    func add(_ request: UNNotificationRequest) async throws { try await center.add(request) }
    func removePending(identifiers: [String]) {
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }
    func pendingIdentifiers() async -> [String] {
        await center.pendingNotificationRequests().map(\.identifier)
    }
}

struct AlarmScheduler {
    let center: NotificationScheduling
    private let alarmPrefix = "alarm-"

    func arm(_ planned: [PlannedAlarm], calendar: Calendar = .current) async {
        for p in planned {
            let content = UNMutableNotificationContent()
            content.title = p.title
            content.body = p.body
            content.sound = .default
            content.categoryIdentifier = AlarmNotification.categoryId
            let comps = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second],
                                                from: p.fireDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            let req = UNNotificationRequest(identifier: p.identifier, content: content, trigger: trigger)
            try? await center.add(req)
        }
    }

    func cancel(taskId: UUID) async {
        let prefix = "\(alarmPrefix)\(taskId.uuidString)-"
        let ids = await center.pendingIdentifiers().filter { $0.hasPrefix(prefix) }
        center.removePending(identifiers: ids)
    }

    func cancelAllAlarms() async {
        let ids = await center.pendingIdentifiers().filter { $0.hasPrefix(alarmPrefix) }
        center.removePending(identifiers: ids)
    }
}
