import UIKit
import UserNotifications

enum AlarmNotification {
    static let categoryId = "FOCUS_ALARM"
    static let doneAction = "ALARM_DONE"
    static let snoozeAction = "ALARM_SNOOZE"
}

final class AlarmAppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        registerCategories(center)
        return true
    }

    private func registerCategories(_ center: UNUserNotificationCenter) {
        let done = UNNotificationAction(identifier: AlarmNotification.doneAction,
                                        title: "Xong", options: [.foreground])
        let snooze = UNNotificationAction(identifier: AlarmNotification.snoozeAction,
                                          title: "Hoãn 10'", options: [])
        let category = UNNotificationCategory(identifier: AlarmNotification.categoryId,
                                              actions: [done, snooze], intentIdentifiers: [],
                                              options: [])
        center.setNotificationCategories([category])
    }

    // Hiện banner + sound cả khi app đang foreground.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async
        -> UNNotificationPresentationOptions { [.banner, .sound] }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse) async {
        let id = response.notification.request.identifier          // "alarm-<uuid>-<i>"
        guard let taskId = Self.taskId(from: id) else { return }
        let scheduler = AlarmScheduler(center: LiveNotificationScheduling())

        switch response.actionIdentifier {
        case AlarmNotification.snoozeAction:
            await scheduler.cancel(taskId: taskId)                  // dừng chùm hiện tại
            let name = response.notification.request.content.userInfo["taskName"] as? String ?? ""
            let planned = AlarmPlanner().plan(taskId: taskId, taskName: name,
                start: Date().addingTimeInterval(10 * 60), now: Date())   // arm lại từ +10'
            await scheduler.arm(planned)
        default:
            // Done, hoặc user tap mở app từ notification → dừng chuỗi của task này.
            await scheduler.cancel(taskId: taskId)
        }
    }

    private static func taskId(from identifier: String) -> UUID? {
        // "alarm-<uuid>-<index>" → uuid.
        let parts = identifier.split(separator: "-")
        // uuid gồm 5 nhóm ngăn bởi '-'; identifier = alarm + 5 nhóm + index = 7 phần.
        guard parts.count == 7, parts.first == "alarm" else { return nil }
        let uuidStr = parts[1...5].joined(separator: "-")
        return UUID(uuidString: uuidStr)
    }
}
