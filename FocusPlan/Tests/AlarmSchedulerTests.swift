import XCTest
import UserNotifications
@testable import FocusPlan

final class AlarmSchedulerTests: XCTestCase {
    // Fake thu thập request đã add + xử lý remove.
    final class FakeCenter: NotificationScheduling, @unchecked Sendable {
        var added: [UNNotificationRequest] = []
        func add(_ request: UNNotificationRequest) async throws { added.append(request) }
        func removePending(identifiers: [String]) { added.removeAll { identifiers.contains($0.identifier) } }
        func pendingIdentifiers() async -> [String] { added.map(\.identifier) }
    }

    private func planned(_ taskId: UUID, _ n: Int) -> [PlannedAlarm] {
        (0..<n).map { i in PlannedAlarm(identifier: "alarm-\(taskId.uuidString)-\(i)",
            fireDate: Date(timeIntervalSince1970: TimeInterval(10_000 + i * 120)),
            title: "T\(i)", body: "B") }
    }

    func test_arm_adds_one_request_per_planned() async {
        let id = UUID(); let fake = FakeCenter()
        let sched = AlarmScheduler(center: fake)
        await sched.arm(planned(id, 6), calendar: .current)
        XCTAssertEqual(fake.added.count, 6)
        XCTAssertEqual(Set(fake.added.map(\.identifier)),
                       Set((0..<6).map { "alarm-\(id.uuidString)-\($0)" }))
        // sound + category gắn đúng.
        XCTAssertEqual(fake.added.first?.content.categoryIdentifier, AlarmNotification.categoryId)
    }

    func test_cancel_taskId_removes_only_that_tasks_alarms() async {
        let a = UUID(); let b = UUID(); let fake = FakeCenter()
        let sched = AlarmScheduler(center: fake)
        await sched.arm(planned(a, 6), calendar: .current)
        await sched.arm(planned(b, 6), calendar: .current)
        await sched.cancel(taskId: a)
        let remaining = await fake.pendingIdentifiers()
        XCTAssertTrue(remaining.allSatisfy { $0.contains(b.uuidString) })
        XCTAssertEqual(remaining.count, 6)
    }

    func test_cancelAllAlarms_removes_all_alarm_prefixed() async {
        let a = UUID(); let fake = FakeCenter()
        let sched = AlarmScheduler(center: fake)
        await sched.arm(planned(a, 6), calendar: .current)
        await sched.cancelAllAlarms()
        let remaining = await fake.pendingIdentifiers()
        XCTAssertTrue(remaining.isEmpty)
    }
}
