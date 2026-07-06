import XCTest
@testable import FocusPlan

final class UserAlarmPlannerTests: XCTestCase {
    private let planner = UserAlarmPlanner()
    private var cal: Calendar { var c = Calendar(identifier: .gregorian); c.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh")!; return c }

    // 2026-07-06 là Thứ 2 (weekday 2).
    private func date(_ y: Int, _ mo: Int, _ d: Int, _ h: Int, _ mi: Int) -> Date {
        cal.date(from: DateComponents(year: y, month: mo, day: d, hour: h, minute: mi))!
    }

    func test_nextFireDate_today_when_time_still_ahead() {
        let alarm = UserAlarm(hour: 16, minute: 26) // repeatDays rỗng = one-shot
        let now = date(2026, 7, 6, 10, 0)
        XCTAssertEqual(planner.nextFireDate(for: alarm, after: now, calendar: cal),
                       date(2026, 7, 6, 16, 26))
    }

    func test_nextFireDate_tomorrow_when_time_passed() {
        let alarm = UserAlarm(hour: 6, minute: 0)
        let now = date(2026, 7, 6, 10, 0)
        XCTAssertEqual(planner.nextFireDate(for: alarm, after: now, calendar: cal),
                       date(2026, 7, 7, 6, 0))
    }

    func test_nextFireDate_respects_repeat_days() {
        // Chỉ Thứ 4 (weekday 4). Now = Thứ 2 → nổ Thứ 4 2026-07-08.
        let alarm = UserAlarm(hour: 6, minute: 0, repeatDays: [4])
        let now = date(2026, 7, 6, 10, 0)
        XCTAssertEqual(planner.nextFireDate(for: alarm, after: now, calendar: cal),
                       date(2026, 7, 8, 6, 0))
    }

    func test_loopAudio_on_plans_escalating_burst() {
        let alarm = UserAlarm(hour: 16, minute: 0, loopAudio: true)
        let now = date(2026, 7, 6, 10, 0)
        let planned = planner.plannedAlarms(for: alarm, now: now, calendar: cal)
        XCTAssertEqual(planned.count, 6) // config mặc định issue 005
        XCTAssertTrue(planned[0].identifier.hasPrefix("alarm-\(alarm.id.uuidString)-"))
    }

    func test_loopAudio_off_plans_single_notification() {
        let alarm = UserAlarm(hour: 16, minute: 0, loopAudio: false)
        let now = date(2026, 7, 6, 10, 0)
        XCTAssertEqual(planner.plannedAlarms(for: alarm, now: now, calendar: cal).count, 1)
    }

    func test_showNotification_off_plans_nothing() {
        let alarm = UserAlarm(hour: 16, minute: 0, showNotification: false)
        let now = date(2026, 7, 6, 10, 0)
        XCTAssertTrue(planner.plannedAlarms(for: alarm, now: now, calendar: cal).isEmpty)
    }
}
