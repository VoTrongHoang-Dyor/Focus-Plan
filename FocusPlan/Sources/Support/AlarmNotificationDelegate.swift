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

    // Task 4 sẽ điền xử lý action.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse) async { }
}
