import XCTest
@testable import FocusPlan

final class PomodoroSessionModelTests: XCTestCase {
    private func decoder() -> JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }

    func test_session_decodes_snake_case() throws {
        let json = """
        {"id":"33333333-3333-3333-3333-333333333333",
         "started_at":"2026-07-06T09:00:00Z","duration_minutes":25,
         "created_at":"2026-07-06T09:25:00Z"}
        """
        let s = try decoder().decode(PomodoroSession.self, from: Data(json.utf8))
        XCTAssertEqual(s.durationMinutes, 25)
        XCTAssertEqual(s.startedAt, ISO8601DateFormatter().date(from: "2026-07-06T09:00:00Z"))
    }

    func test_newSession_encodes_snake_case() throws {
        let payload = NewPomodoroSession(startedAt: "2026-07-06T09:00:00Z", durationMinutes: 25)
        let data = try JSONEncoder().encode(payload)
        let obj = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertEqual(obj["started_at"] as? String, "2026-07-06T09:00:00Z")
        XCTAssertEqual(obj["duration_minutes"] as? Int, 25)
    }
}
