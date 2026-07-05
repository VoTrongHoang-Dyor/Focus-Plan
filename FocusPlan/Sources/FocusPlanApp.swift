import SwiftUI
import UserNotifications

@main
struct FocusPlanApp: App {
    @UIApplicationDelegateAdaptor(AlarmAppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            RootView()
                .task { await requestNotificationPermission() }
        }
    }

    private func requestNotificationPermission() async {
        _ = try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge])
    }
}
