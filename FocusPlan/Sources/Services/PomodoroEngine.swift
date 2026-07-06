import Foundation

/// Trạng thái phiên Pomodoro.
enum PomodoroState: Equatable {
    case idle
    case running(endDate: Date)
    case paused(remaining: TimeInterval)
}

/// State machine thuần cho phiên Pomodoro — mọi tính toán theo wall clock (Date inject),
/// KHÔNG đếm tick → đúng cả khi app bị suspend/khoá màn hình. Hàm thuần, deterministic.
struct PomodoroEngine: Equatable {
    let duration: TimeInterval
    private(set) var state: PomodoroState = .idle
    /// Mốc bắt đầu phiên gốc (giữ nguyên qua pause/resume) — dùng khi lưu session.
    private(set) var startedAt: Date?

    init(duration: TimeInterval = 25 * 60) { self.duration = duration }

    mutating func start(now: Date) {
        guard case .idle = state else { return }
        startedAt = now
        state = .running(endDate: now.addingTimeInterval(duration))
    }

    mutating func pause(now: Date) {
        guard case .running(let end) = state else { return }
        state = .paused(remaining: max(0, end.timeIntervalSince(now)))
    }

    mutating func resume(now: Date) {
        guard case .paused(let remaining) = state else { return }
        state = .running(endDate: now.addingTimeInterval(remaining))
    }

    mutating func reset() {
        state = .idle
        startedAt = nil
    }

    func remaining(now: Date) -> TimeInterval {
        switch state {
        case .idle: return duration
        case .running(let end): return max(0, end.timeIntervalSince(now))
        case .paused(let remaining): return remaining
        }
    }

    func isFinished(now: Date) -> Bool {
        if case .running(let end) = state { return now >= end }
        return false
    }
}
