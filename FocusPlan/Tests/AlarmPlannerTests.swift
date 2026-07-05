import XCTest
@testable import FocusPlan

final class AlarmPlannerTests: XCTestCase {
    private let id = UUID(uuidString: "AAAAAAAA-0000-0000-0000-000000000000")!
    private func t(_ s: TimeInterval) -> Date { Date(timeIntervalSince1970: s) }

    // Chùm 6 notification, cách 2', identifier theo taskId+index, giờ bắt đầu.
    func test_plan_creates_burst_of_six_two_minutes_apart() {
        let start = t(10_000)
        let alarms = AlarmPlanner().plan(taskId: id, taskName: "Học", start: start, now: t(0), config: .init())
        XCTAssertEqual(alarms.count, 6)
        XCTAssertEqual(alarms[0].fireDate, start)
        XCTAssertEqual(alarms[1].fireDate, start.addingTimeInterval(120))
        XCTAssertEqual(alarms[5].fireDate, start.addingTimeInterval(600))
        XCTAssertEqual(alarms[0].identifier, "alarm-\(id.uuidString)-0")
        XCTAssertEqual(alarms[5].identifier, "alarm-\(id.uuidString)-5")
    }

    // Escalating: title khác nhau, notification sau khẩn hơn (khác title[0]).
    func test_plan_titles_escalate() {
        let alarms = AlarmPlanner().plan(taskId: id, taskName: "Học", start: t(10_000), now: t(0), config: .init())
        XCTAssertNotEqual(alarms[0].title, alarms[5].title)
        XCTAssertTrue(alarms.allSatisfy { $0.body.contains("Học") })
    }

    // Bỏ các mốc đã ở quá khứ so với now.
    func test_plan_skips_past_fire_dates() {
        let start = t(10_000)
        // now = start + 5' → offset 0,2,4' đã qua; còn 6,8,10' (index 3,4,5).
        let alarms = AlarmPlanner().plan(taskId: id, taskName: "Học", start: start,
                                         now: start.addingTimeInterval(5 * 60), config: .init())
        XCTAssertEqual(alarms.count, 3)
        XCTAssertEqual(alarms.first?.identifier, "alarm-\(id.uuidString)-3")
    }

    // planMany: sort theo start, cắt theo budget tổng.
    func test_planMany_respects_budget_and_orders_by_start() {
        let a = UUID(); let b = UUID()
        let items = [(id: a, name: "A", start: t(20_000)), (id: b, name: "B", start: t(10_000))]
        var cfg = AlarmPlanner.Config(); cfg.maxPendingBudget = 8   // 6/task → chỉ đủ task sớm nhất + 2 của task sau
        let alarms = AlarmPlanner().planMany(items, now: t(0), config: cfg)
        XCTAssertEqual(alarms.count, 8)
        // B (start sớm hơn) phải nằm trước.
        XCTAssertTrue(alarms.prefix(6).allSatisfy { $0.identifier.contains(b.uuidString) })
    }
}
