import Foundation
import UserNotifications

/// Điều phối phiên Pomodoro: engine (wall-clock) + notification hết phiên (hạ tầng issue 005)
/// + lưu phiên hoàn thành lên Supabase. UI tick gọi onTick() mỗi giây khi foreground —
/// remaining luôn derive từ Date() nên tự đúng lại sau khi app bị suspend.
@MainActor
final class PomodoroViewModel: ObservableObject {
    static let notificationId = "pomodoro-end"

    @Published private(set) var state: PomodoroState = .idle
    @Published private(set) var remainingText: String = ""
    @Published var errorMessage: String?

    private var engine: PomodoroEngine
    private let scheduler: NotificationScheduling
    private let repo = PomodoroSessionRepository()

    var progress: Double {
        engine.duration == 0 ? 0 : 1 - engine.remaining(now: Date()) / engine.duration
    }

    init(scheduler: NotificationScheduling = LiveNotificationScheduling()) {
        // UITEST_POMODORO_SECONDS: UITest rút ngắn phiên (convention UITEST_* như UITEST_RESET_USER_ALARMS).
        let secs = ProcessInfo.processInfo.environment["UITEST_POMODORO_SECONDS"]
            .flatMap(TimeInterval.init) ?? 25 * 60
        self.engine = PomodoroEngine(duration: secs)
        self.scheduler = scheduler
        syncPublished()
    }

    func start() {
        engine.start(now: Date())
        scheduleEndNotification()
        syncPublished()
    }

    func pause() {
        engine.pause(now: Date())
        scheduler.removePending(identifiers: [Self.notificationId])
        syncPublished()
    }

    func resume() {
        engine.resume(now: Date())
        scheduleEndNotification()
        syncPublished()
    }

    func stop() {
        scheduler.removePending(identifiers: [Self.notificationId])
        engine.reset()
        syncPublished()
    }

    /// View gọi mỗi giây (TimelineView) — phát hiện hết phiên khi đang foreground.
    func onTick() {
        if engine.isFinished(now: Date()) { completeSession() }
        syncPublished()
    }

    private func completeSession() {
        guard let startedAt = engine.startedAt else { engine.reset(); return }
        let payload = NewPomodoroSession(
            startedAt: ISO8601DateFormatter().string(from: startedAt),
            durationMinutes: Int(engine.duration / 60)
        )
        engine.reset()
        Task {
            do { _ = try await repo.create(payload) }
            catch { errorMessage = error.localizedDescription }
        }
    }

    private func scheduleEndNotification() {
        let remaining = engine.remaining(now: Date())
        guard remaining > 0 else { return }
        let content = UNMutableNotificationContent()
        content.title = "Hết phiên tập trung"
        content.body = "Bạn đã hoàn thành một phiên Pomodoro. Nghỉ một chút nhé!"
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: remaining, repeats: false)
        let req = UNNotificationRequest(identifier: Self.notificationId, content: content, trigger: trigger)
        Task { try? await scheduler.add(req) }
    }

    private func syncPublished() {
        state = engine.state
        let r = Int(engine.remaining(now: Date()).rounded())
        remainingText = String(format: "%02d:%02d", r / 60, r % 60)
    }
}
