import XCTest
@testable import FocusPlan

final class SchedulingEngineTests: XCTestCase {
    private func cal() -> Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh")!
        return c
    }
    private let day = DateComponents(year: 2026, month: 7, day: 6)

    private func at(_ h: Int, _ m: Int, _ c: Calendar) -> Date {
        c.date(from: DateComponents(year: 2026, month: 7, day: 6, hour: h, minute: m))!
    }

    private func task(_ name: String, _ minutes: Int?, _ p: TaskPriority,
                      _ type: TaskType, created: TimeInterval = 0) -> TaskItem {
        TaskItem(id: UUID(uuidString: String(format: "%08X-0000-0000-0000-000000000000",
                 abs(name.hashValue) & 0xFFFFFFFF))!,
                 name: name, estimatedMinutes: minutes, priority: p, deadline: nil,
                 taskType: type, createdAt: Date(timeIntervalSince1970: created))
    }

    // Criteria 1: cho task list → trả slot cụ thể trong ngày.
    func test_schedules_tasks_into_concrete_slots() {
        let c = cal()
        let date = c.date(from: day)!
        let tasks = [task("A", 60, .high, .deep), task("B", 30, .medium, .shallow)]
        let r = SchedulingEngine().schedule(tasks: tasks, busyBlocks: [], on: date,
                                            calendar: c, config: .init())
        XCTAssertEqual(r.scheduled.count, 2)
        XCTAssertEqual(r.scheduled[0].start, at(8, 0, c))          // bắt đầu 08:00
        XCTAssertEqual(r.scheduled[0].end, at(9, 0, c))            // 60'
        XCTAssertTrue(r.unscheduled.isEmpty)
    }

    // Criteria 2: energy-matching + determinism (2 lần cùng input → giống hệt).
    func test_deep_before_shallow_and_deterministic() {
        let c = cal()
        let date = c.date(from: day)!
        let tasks = [task("shallow1", 30, .high, .shallow), task("deep1", 30, .low, .deep)]
        let r1 = SchedulingEngine().schedule(tasks: tasks, busyBlocks: [], on: date,
                                             calendar: c, config: .init())
        let r2 = SchedulingEngine().schedule(tasks: tasks, busyBlocks: [], on: date,
                                             calendar: c, config: .init())
        XCTAssertEqual(r1, r2)                                     // deterministic
        // deep xếp trước dù priority thấp hơn → chiếm slot sáng đầu tiên.
        XCTAssertEqual(r1.scheduled[0].taskId, tasks[1].id)       // deep1
        XCTAssertEqual(r1.scheduled[0].start, at(8, 0, c))
    }

    // Criteria 3: buffer 10' giữa 2 block liên tiếp.
    func test_inserts_fixed_buffer_between_blocks() {
        let c = cal()
        let date = c.date(from: day)!
        let tasks = [task("A", 60, .high, .deep), task("B", 30, .high, .deep, created: 1)]
        let r = SchedulingEngine().schedule(tasks: tasks, busyBlocks: [], on: date,
                                            calendar: c, config: .init())
        // A: 08:00-09:00; buffer 10' → B bắt đầu 09:10.
        XCTAssertEqual(r.scheduled[1].start, at(9, 10, c))
    }

    // Criteria 4: né busy-block habit, không xếp đè.
    func test_avoids_busy_blocks() {
        let c = cal()
        let date = c.date(from: day)!
        let busy = [BusyBlock(habitId: UUID(), start: at(8, 0, c), end: at(8, 30, c))]  // 08:00-08:30
        let tasks = [task("A", 30, .high, .deep)]
        let r = SchedulingEngine().schedule(tasks: tasks, busyBlocks: busy, on: date,
                                            calendar: c, config: .init())
        // task phải bắt đầu >= 08:30 (sau habit), không giao busy-block.
        XCTAssertEqual(r.scheduled[0].start, at(8, 30, c))
        XCTAssertEqual(r.scheduled[0].end, at(9, 0, c))
    }

    // Overflow: task không đủ chỗ trong ngày → unscheduled.
    func test_overflow_goes_to_unscheduled() {
        let c = cal()
        let date = c.date(from: day)!
        // ngày 08:00-22:00 = 840'. 1 task 900' không vừa.
        let tasks = [task("Big", 900, .high, .deep)]
        let r = SchedulingEngine().schedule(tasks: tasks, busyBlocks: [], on: date,
                                            calendar: c, config: .init())
        XCTAssertTrue(r.scheduled.isEmpty)
        XCTAssertEqual(r.unscheduled, [tasks[0].id])
    }
}
