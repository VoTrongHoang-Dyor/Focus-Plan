import SwiftUI
import UserNotifications

@main
struct FocusPlanApp: App {
    @UIApplicationDelegateAdaptor(AlarmAppDelegate.self) private var appDelegate
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .task { await requestNotificationPermission() }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                Task { await TodayScheduleService.shared.refreshAndArm() }
            }
        }
    }

    private func requestNotificationPermission() async {
        _ = try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge])
    }
}
