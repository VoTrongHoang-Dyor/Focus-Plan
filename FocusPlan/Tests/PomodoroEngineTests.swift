import XCTest
@testable import FocusPlan

final class PomodoroEngineTests: XCTestCase {
    private let t0 = Date(timeIntervalSince1970: 1_800_000_000)

    func test_start_runs_full_duration_from_now() {
        var e = PomodoroEngine(duration: 25 * 60)
        e.start(now: t0)
        XCTAssertEqual(e.state, .running(endDate: t0.addingTimeInterval(25 * 60)))
        XCTAssertEqual(e.startedAt, t0)
        XCTAssertEqual(e.remaining(now: t0.addingTimeInterval(60)), 24 * 60)
    }

    func test_remaining_correct_after_long_background_gap() {
        // App suspend 10 phút — remaining derive từ wall clock, không tick.
        var e = PomodoroEngine(duration: 25 * 60)
        e.start(now: t0)
        XCTAssertEqual(e.remaining(now: t0.addingTimeInterval(10 * 60)), 15 * 60)
        XCTAssertFalse(e.isFinished(now: t0.addingTimeInterval(24 * 60)))
        XCTAssertTrue(e.isFinished(now: t0.addingTimeInterval(25 * 60)))
        XCTAssertEqual(e.remaining(now: t0.addingTimeInterval(26 * 60)), 0) // clamp, không âm
    }

    func test_pause_freezes_remaining_and_resume_continues() {
        var e = PomodoroEngine(duration: 25 * 60)
        e.start(now: t0)
        e.pause(now: t0.addingTimeInterval(5 * 60))
        XCTAssertEqual(e.state, .paused(remaining: 20 * 60))
        // đứng yên khi pause, kể cả qua 1 giờ
        XCTAssertEqual(e.remaining(now: t0.addingTimeInterval(65 * 60)), 20 * 60)
        let t1 = t0.addingTimeInterval(65 * 60)
        e.resume(now: t1)
        XCTAssertEqual(e.state, .running(endDate: t1.addingTimeInterval(20 * 60)))
        XCTAssertEqual(e.startedAt, t0) // startedAt giữ mốc bắt đầu gốc
    }

    func test_reset_returns_to_idle() {
        var e = PomodoroEngine(duration: 25 * 60)
        e.start(now: t0)
        e.reset()
        XCTAssertEqual(e.state, .idle)
        XCTAssertNil(e.startedAt)
        XCTAssertEqual(e.remaining(now: t0), 25 * 60)
    }

    func test_invalid_transitions_are_noops() {
        var e = PomodoroEngine(duration: 25 * 60)
        e.pause(now: t0)   // pause khi idle
        XCTAssertEqual(e.state, .idle)
        e.resume(now: t0)  // resume khi idle
        XCTAssertEqual(e.state, .idle)
        e.start(now: t0)
        e.start(now: t0.addingTimeInterval(60)) // start khi đang chạy → giữ phiên cũ
        XCTAssertEqual(e.state, .running(endDate: t0.addingTimeInterval(25 * 60)))
    }
}
