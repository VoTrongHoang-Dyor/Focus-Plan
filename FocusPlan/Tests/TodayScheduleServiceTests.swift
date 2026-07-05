import XCTest
@testable import FocusPlan

final class TodayScheduleServiceTests: XCTestCase {
    private func t(_ s: TimeInterval) -> Date { Date(timeIntervalSince1970: s) }

    // Task đã bắt đầu (start <= now) = chùm đang chạy → KHÔNG arm lại (mở app dừng chuỗi).
    // Task tương lai (start > now) → giữ để arm.
    func test_futureItems_skips_started_tasks() {
        let started = UUID(); let future = UUID()
        let now = t(1000)
        let scheduled = [
            ScheduledBlock(taskId: started, start: now.addingTimeInterval(-60), end: now),
            ScheduledBlock(taskId: future, start: now.addingTimeInterval(120),
                           end: now.addingTimeInterval(1920)),
        ]
        let names = [started: "Đang chạy", future: "Sắp tới"]
        let items = TodayScheduleService.futureItems(scheduled: scheduled, names: names, now: now)
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.id, future)
        XCTAssertEqual(items.first?.name, "Sắp tới")
    }

    // start == now cũng coi là đã bắt đầu (không arm lại).
    func test_futureItems_treats_start_equal_now_as_started() {
        let id = UUID()
        let now = t(1000)
        let scheduled = [ScheduledBlock(taskId: id, start: now, end: now.addingTimeInterval(600))]
        let items = TodayScheduleService.futureItems(scheduled: scheduled, names: [id: "X"], now: now)
        XCTAssertTrue(items.isEmpty)
    }
}
