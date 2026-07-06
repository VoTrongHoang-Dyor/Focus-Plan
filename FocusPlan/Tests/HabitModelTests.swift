import XCTest
@testable import FocusPlan

final class HabitModelTests: XCTestCase {
    /// created_at là timestamptz (ISO8601). JSONDecoder mặc định (.deferredToDate) không đọc được
    /// chuỗi ISO → dùng .iso8601 để khớp shape Supabase trả về.
    private func decoder() -> JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }

    func test_habit_decodes_snake_case() throws {
        let json = """
        {"id":"11111111-1111-1111-1111-111111111111","name":"Thiền",
         "time_of_day":"06:00:00","duration_minutes":20,
         "created_at":"2026-07-04T00:00:00Z"}
        """
        let h = try decoder().decode(Habit.self, from: Data(json.utf8))
        XCTAssertEqual(h.name, "Thiền")
        XCTAssertEqual(h.durationMinutes, 20)
        XCTAssertEqual(h.timeComponents?.hour, 6)
        XCTAssertEqual(h.timeComponents?.minute, 0)
    }

    func test_habitLog_decodes_and_status() throws {
        let json = """
        {"id":"22222222-2222-2222-2222-222222222222",
         "habit_id":"11111111-1111-1111-1111-111111111111",
         "log_date":"2026-07-04","status":"done"}
        """
        let log = try decoder().decode(HabitLog.self, from: Data(json.utf8))
        XCTAssertEqual(log.status, .done)
        XCTAssertEqual(log.logDate, "2026-07-04")
    }

    func test_dayPart_boundaries_match_flutter_demo() {
        // demo models/habit.dart:43-47 — <12h sáng, <18h chiều, còn lại tối
        XCTAssertEqual(DayPart.from(hour: 0), .morning)
        XCTAssertEqual(DayPart.from(hour: 11), .morning)
        XCTAssertEqual(DayPart.from(hour: 12), .afternoon)
        XCTAssertEqual(DayPart.from(hour: 17), .afternoon)
        XCTAssertEqual(DayPart.from(hour: 18), .evening)
        XCTAssertEqual(DayPart.from(hour: 23), .evening)
    }

    func test_habit_dayPart_derived_from_timeOfDay() throws {
        let json = """
        {"id":"11111111-1111-1111-1111-111111111111","name":"Đọc sách",
         "time_of_day":"18:30:00","duration_minutes":15,
         "created_at":"2026-07-04T00:00:00Z"}
        """
        let h = try decoder().decode(Habit.self, from: Data(json.utf8))
        XCTAssertEqual(h.dayPart, .evening)
    }
}
