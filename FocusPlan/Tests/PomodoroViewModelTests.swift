import XCTest
import UserNotifications
@testable import FocusPlan

@MainActor
final class PomodoroViewModelTests: XCTestCase {
    final class FakeCenter: NotificationScheduling, @unchecked Sendable {
        var added: [UNNotificationRequest] = []
        var removed: [String] = []
        func add(_ request: UNNotificationRequest) async throws { added.append(request) }
        func removePending(identifiers: [String]) { removed.append(contentsOf: identifiers) }
        func pendingIdentifiers() async -> [String] { added.map(\.identifier) }
    }

    func test_start_schedules_end_notification() async throws {
        let center = FakeCenter()
        let vm = PomodoroViewModel(scheduler: center)
        vm.start()
        // add() là async fire-and-forget trong Task — chờ nó chạy
        try await Task.sleep(nanoseconds: 200_000_000)
        XCTAssertEqual(center.added.map(\.identifier), [PomodoroViewModel.notificationId])
        let trigger = try XCTUnwrap(center.added.first?.trigger as? UNTimeIntervalNotificationTrigger)
        XCTAssertEqual(trigger.timeInterval, 25 * 60, accuracy: 2)
    }

    func test_pause_removes_pending_and_resume_reschedules() async throws {
        let center = FakeCenter()
        let vm = PomodoroViewModel(scheduler: center)
        vm.start()
        try await Task.sleep(nanoseconds: 200_000_000)
        vm.pause()
        XCTAssertEqual(center.removed, [PomodoroViewModel.notificationId])
        vm.resume()
        try await Task.sleep(nanoseconds: 200_000_000)
        XCTAssertEqual(center.added.count, 2)
    }

    func test_stop_removes_pending_and_resets() {
        let center = FakeCenter()
        let vm = PomodoroViewModel(scheduler: center)
        vm.start()
        vm.stop()
        XCTAssertTrue(center.removed.contains(PomodoroViewModel.notificationId))
        XCTAssertEqual(vm.state, .idle)
        XCTAssertEqual(vm.remainingText, "25:00")
    }
}
