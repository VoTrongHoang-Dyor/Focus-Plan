import XCTest
@testable import FocusPlan

final class HabitBusyBlockServiceTests: XCTestCase {
    private func makeCalendar() -> Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh")!
        return cal
    }

    private func habit(_ time: String, _ minutes: Int) -> Habit {
        Habit(id: UUID(), name: "H", timeOfDay: time, durationMinutes: minutes,
              createdAt: Date(timeIntervalSince1970: 0))
    }

    func test_busyBlock_start_end_match_time_and_duration() {
        let cal = makeCalendar()
        let date = cal.date(from: DateComponents(year: 2026, month: 7, day: 4))!
        let blocks = HabitBusyBlockService().busyBlocks(
            habits: [habit("06:00:00", 20)], on: date, calendar: cal)
        XCTAssertEqual(blocks.count, 1)
        let expectedStart = cal.date(from: DateComponents(year: 2026, month: 7, day: 4, hour: 6, minute: 0))!
        XCTAssertEqual(blocks[0].start, expectedStart)
        XCTAssertEqual(blocks[0].end, expectedStart.addingTimeInterval(20 * 60))
    }

    func test_multiple_habits_produce_block_each() {
        let cal = makeCalendar()
        let date = cal.date(from: DateComponents(year: 2026, month: 7, day: 4))!
        let blocks = HabitBusyBlockService().busyBlocks(
            habits: [habit("06:00:00", 20), habit("21:30:00", 15)], on: date, calendar: cal)
        XCTAssertEqual(blocks.count, 2)
    }

    func test_invalid_time_is_skipped() {
        let cal = makeCalendar()
        let date = cal.date(from: DateComponents(year: 2026, month: 7, day: 4))!
        let blocks = HabitBusyBlockService().busyBlocks(
            habits: [habit("not-a-time", 30)], on: date, calendar: cal)
        XCTAssertTrue(blocks.isEmpty)
    }
}
