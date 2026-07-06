import SwiftUI
import UserNotifications

@main
struct FocusPlanApp: App {
    @UIApplicationDelegateAdaptor(AlarmAppDelegate.self) private var appDelegate
    @Environment(\.scenePhase) private var scenePhase

    init() {
        // Seam cho AlarmFlowUITests: đảm bảo state UserAlarmStore sạch ở lần launch đầu
        // của test, bất kể app đã cài/relaunch bao nhiêu lần trên simulator trước đó.
        if ProcessInfo.processInfo.environment["UITEST_RESET_USER_ALARMS"] != nil {
            UserAlarmStore.reset()
        }
    }

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
