# Pomodoro Timer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Tab "Tập trung" với timer Pomodoro 25 phút (start/pause/resume/stop), chạy đúng khi app bị suspend/khoá màn hình, hết phiên bắn local notification (tái dùng hạ tầng issue 005), phiên hoàn thành lưu Supabase — issue `.claude/wiki/issues/006-pomodoro-timer.md`.

**Architecture:** State machine thuần `PomodoroEngine` tính mọi thứ theo **wall clock** (Date inject, không tick-count) → tự đúng khi app suspend; `PomodoroViewModel` wire engine với `NotificationScheduling` (protocol có sẵn từ issue 005) và `PomodoroSessionRepository` (pattern y hệt `HabitRepository`); `PomodoroView` là tab thứ 3. Bảng mới `pomodoro_sessions` (RLS như habits) — migration SQL source-of-truth, user chạy tay trên SQL Editor (HITL).

**Tech Stack:** SwiftUI (iOS 17), supabase-swift, UserNotifications, XcodeGen, XCTest + XCUITest.

## Global Constraints

- **User đã chốt (2026-07-06):** phiên CỐ ĐỊNH 25 phút (không picker độ dài); entry point = tab thứ 3 "Tập trung" (icon `timer`), timer độc lập KHÔNG gắn task.
- **Tái dùng hạ tầng notification issue 005:** protocol `NotificationScheduling` + `LiveNotificationScheduling` (`FocusPlan/Sources/Services/AlarmScheduler.swift:4-19`). KHÔNG tạo cơ chế notification mới, KHÔNG xin permission mới (đã xin app-wide ở `FocusPlanApp.swift:31`).
- **Đúng khi chạy nền:** cấm dựa vào Timer tick để trừ giây — remaining LUÔN derive từ `endDate - now`. Notification hết phiên do hệ thống bắn (đã schedule trước), không cần app sống.
- **Phiên được lưu = phiên chạy hết 25 phút.** Stop giữa chừng KHÔNG lưu (criteria chỉ yêu cầu lưu "phiên hoàn thành"). `duration_minutes` lưu = duration cấu hình của engine (phút).
- **A11yID convention** (issue 019, `FocusPlan/Sources/Support/A11yID.swift`): `"{screen}.{element}-{type}"` lowercase kebab-case — thêm nhóm `Pomodoro` tập trung ở file đó, không magic string trong view.
- **UITest env override convention:** prefix `UITEST_*` (như `UITEST_RESET_USER_ALARMS`, `UITEST_MOCK_PARSE_DRAFT`) → dùng `UITEST_POMODORO_SECONDS`.
- **Theme tokens bắt buộc** (`Theme.primary`, `radiusCard`, `ctaHeight`, `authCTAStyle()`...); chi tiết thẩm mỹ coder tự quyết bằng skill `ui-ux-pro-max` (stack SwiftUI) — demo Flutter KHÔNG có màn timer, ring progress tham khảo `SummaryHeader` trong `HabitsView.swift:134-144`.
- **Test suite phải xanh sau MỖI task.** Lệnh trong `FocusPlan/`:
  - Build: `xcodegen generate && xcodebuild -project FocusPlan.xcodeproj -scheme FocusPlan -destination 'generic/platform=iOS Simulator' build`
  - Test: `xcodebuild -project FocusPlan.xcodeproj -scheme FocusPlan -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test`
- **HITL:** Task 5 cần bảng `pomodoro_sessions` tồn tại trên Supabase remote — coder DỪNG và báo leader sau Task 4 để user chạy SQL, rồi mới chạy Task 5.
- Commit sau mỗi task (`feat(ios): ...`). KHÔNG commit file `.claude/**` đang modified. Push chỉ khi leader/user duyệt.

---

### Task 1: Migration + Model + Repository (`pomodoro_sessions`)

**Files:**
- Create: `supabase/migrations/<YYYYMMDDHHMMSS>_create_pomodoro_sessions.sql` (timestamp thực tế: `date +%Y%m%d%H%M%S`)
- Create: `FocusPlan/Sources/Models/PomodoroSession.swift`
- Create: `FocusPlan/Sources/Services/PomodoroSessionRepository.swift`
- Test: `FocusPlan/Tests/PomodoroSessionModelTests.swift`

**Interfaces:**
- Produces: `struct PomodoroSession: Codable, Identifiable, Equatable { id: UUID, startedAt: Date, durationMinutes: Int, createdAt: Date }`; `struct NewPomodoroSession: Encodable { startedAt: String /* ISO8601 */, durationMinutes: Int }`; `struct PomodoroSessionRepository { func create(_:) async throws -> PomodoroSession; func fetchSessions() async throws -> [PomodoroSession] }`.

- [ ] **Step 1: Viết file migration** (idempotent, KHÔNG `db push` lên remote — user chạy tay, như bảng habits):

```sql
-- Source of truth cho bảng pomodoro_sessions (issue 006).
-- Bảng sẽ được user tạo tay trên remote qua SQL Editor; file này để version-control.
-- KHÔNG chạy `supabase db push` lên remote đang chạy.

create table if not exists public.pomodoro_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade default auth.uid(),
  started_at timestamptz not null,
  duration_minutes int not null,
  created_at timestamptz not null default now()
);
alter table public.pomodoro_sessions enable row level security;
drop policy if exists "pomodoro_sessions_select_own" on public.pomodoro_sessions;
drop policy if exists "pomodoro_sessions_insert_own" on public.pomodoro_sessions;
create policy "pomodoro_sessions_select_own" on public.pomodoro_sessions for select using (auth.uid() = user_id);
create policy "pomodoro_sessions_insert_own" on public.pomodoro_sessions for insert with check (auth.uid() = user_id);
```

(Session bất biến → chỉ select/insert, KHÔNG policy update/delete — YAGNI.)

- [ ] **Step 2: Viết failing test** — `PomodoroSessionModelTests.swift` (pattern y hệt `HabitModelTests.swift`):

```swift
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
```

- [ ] **Step 3: Run test → FAIL** ("cannot find 'PomodoroSession'").
- [ ] **Step 4: Implement model** — `PomodoroSession.swift`:

```swift
import Foundation

/// Một phiên Pomodoro ĐÃ HOÀN THÀNH (chạy hết duration). Nguồn dữ liệu cho
/// gamification (009), reflection (008), energy matching (013).
struct PomodoroSession: Codable, Identifiable, Equatable {
    let id: UUID
    let startedAt: Date
    let durationMinutes: Int
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case startedAt = "started_at"
        case durationMinutes = "duration_minutes"
        case createdAt = "created_at"
    }
}

/// Payload insert — startedAt gửi dạng chuỗi ISO8601 (tránh phụ thuộc date-encoding
/// strategy của client); id/user_id/created_at để DB default.
struct NewPomodoroSession: Encodable {
    var startedAt: String
    var durationMinutes: Int
    enum CodingKeys: String, CodingKey {
        case startedAt = "started_at"
        case durationMinutes = "duration_minutes"
    }
}
```

- [ ] **Step 5: Implement repository** — `PomodoroSessionRepository.swift` (pattern `HabitRepository`):

```swift
import Foundation
import Supabase

struct PomodoroSessionRepository {
    private let client = SupabaseManager.shared.client

    // RLS scope theo auth.uid(); user_id để DB default (không set ở client).

    func create(_ s: NewPomodoroSession) async throws -> PomodoroSession {
        try await client.from("pomodoro_sessions")
            .insert(s, returning: .representation).select().single()
            .execute().value
    }

    func fetchSessions() async throws -> [PomodoroSession] {
        try await client.from("pomodoro_sessions")
            .select().order("started_at", ascending: false)
            .execute().value
    }
}
```

- [ ] **Step 6: Run test → PASS**, `xcodegen generate` + build xanh, unit test cũ xanh.
- [ ] **Step 7: Commit** `feat(ios): pomodoro_sessions schema, model and repository`

---

### Task 2: `PomodoroEngine` — state machine wall-clock (TDD)

**Files:**
- Create: `FocusPlan/Sources/Services/PomodoroEngine.swift`
- Test: `FocusPlan/Tests/PomodoroEngineTests.swift`

**Interfaces:**
- Produces: `enum PomodoroState: Equatable { case idle; case running(endDate: Date); case paused(remaining: TimeInterval) }`; `struct PomodoroEngine { init(duration: TimeInterval = 25 * 60); var state: PomodoroState; var startedAt: Date?; mutating func start(now: Date); mutating func pause(now: Date); mutating func resume(now: Date); mutating func reset(); func remaining(now: Date) -> TimeInterval; func isFinished(now: Date) -> Bool }` (Task 3 dùng).

- [ ] **Step 1: Viết failing tests** — `PomodoroEngineTests.swift`:

```swift
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
```

- [ ] **Step 2: Run test → FAIL** ("cannot find 'PomodoroEngine'").
- [ ] **Step 3: Implement** — `PomodoroEngine.swift`:

```swift
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
```

- [ ] **Step 4: Run test → PASS**, build xanh.
- [ ] **Step 5: Commit** `feat(ios): PomodoroEngine wall-clock state machine`

---

### Task 3: `PomodoroViewModel` — wire engine + notification + save

**Files:**
- Create: `FocusPlan/Sources/ViewModels/PomodoroViewModel.swift`
- Test: `FocusPlan/Tests/PomodoroViewModelTests.swift`

**Interfaces:**
- Consumes: `PomodoroEngine`/`PomodoroState` (Task 2), `NotificationScheduling`/`LiveNotificationScheduling` (`AlarmScheduler.swift:4-19`), `PomodoroSessionRepository`/`NewPomodoroSession` (Task 1).
- Produces: `@MainActor final class PomodoroViewModel: ObservableObject { @Published private(set) var state: PomodoroState; @Published private(set) var remainingText: String; @Published var errorMessage: String?; var progress: Double; func start(); func pause(); func resume(); func stop(); func onTick() }` + `static let notificationId = "pomodoro-end"` (Task 4 dùng).

- [ ] **Step 1: Viết failing tests** — `PomodoroViewModelTests.swift` (FakeCenter pattern như `AlarmSchedulerTests.swift:7`):

```swift
import XCTest
@testable import FocusPlan

@MainActor
final class PomodoroViewModelTests: XCTestCase {
    final class FakeCenter: NotificationScheduling, @unchecked Sendable {
        var added: [UNNotificationRequest] = []
        var removed: [String] = []
        func add(_ request: UNNotificationRequest) async throws { added.append(request) }
        func removePending(identifiers: [String]) { removed.append(contentsOf: identifiers) }
        func pendingIdentifiers() async -> [String] { added.map(\.identifier) }
    }

    func test_start_schedules_end_notification() async throws {
        let center = FakeCenter()
        let vm = PomodoroViewModel(scheduler: center)
        vm.start()
        // add() là async fire-and-forget trong Task — chờ nó chạy
        try await Task.sleep(nanoseconds: 200_000_000)
        XCTAssertEqual(center.added.map(\.identifier), [PomodoroViewModel.notificationId])
        let trigger = try XCTUnwrap(center.added.first?.trigger as? UNTimeIntervalNotificationTrigger)
        XCTAssertEqual(trigger.timeInterval, 25 * 60, accuracy: 2)
    }

    func test_pause_removes_pending_and_resume_reschedules() async throws {
        let center = FakeCenter()
        let vm = PomodoroViewModel(scheduler: center)
        vm.start()
        try await Task.sleep(nanoseconds: 200_000_000)
        vm.pause()
        XCTAssertEqual(center.removed, [PomodoroViewModel.notificationId])
        vm.resume()
        try await Task.sleep(nanoseconds: 200_000_000)
        XCTAssertEqual(center.added.count, 2)
    }

    func test_stop_removes_pending_and_resets() {
        let center = FakeCenter()
        let vm = PomodoroViewModel(scheduler: center)
        vm.start()
        vm.stop()
        XCTAssertTrue(center.removed.contains(PomodoroViewModel.notificationId))
        XCTAssertEqual(vm.state, .idle)
        XCTAssertEqual(vm.remainingText, "25:00")
    }
}
```

- [ ] **Step 2: Run test → FAIL** ("cannot find 'PomodoroViewModel'").
- [ ] **Step 3: Implement** — `PomodoroViewModel.swift`:

```swift
import Foundation
import UserNotifications

/// Điều phối phiên Pomodoro: engine (wall-clock) + notification hết phiên (hạ tầng issue 005)
/// + lưu phiên hoàn thành lên Supabase. UI tick gọi onTick() mỗi giây khi foreground —
/// remaining luôn derive từ Date() nên tự đúng lại sau khi app bị suspend.
@MainActor
final class PomodoroViewModel: ObservableObject {
    static let notificationId = "pomodoro-end"

    @Published private(set) var state: PomodoroState = .idle
    @Published private(set) var remainingText: String = ""
    @Published var errorMessage: String?

    private var engine: PomodoroEngine
    private let scheduler: NotificationScheduling
    private let repo = PomodoroSessionRepository()

    var progress: Double {
        engine.duration == 0 ? 0 : 1 - engine.remaining(now: Date()) / engine.duration
    }

    init(scheduler: NotificationScheduling = LiveNotificationScheduling()) {
        // UITEST_POMODORO_SECONDS: UITest rút ngắn phiên (convention UITEST_* như UITEST_RESET_USER_ALARMS).
        let secs = ProcessInfo.processInfo.environment["UITEST_POMODORO_SECONDS"]
            .flatMap(TimeInterval.init) ?? 25 * 60
        self.engine = PomodoroEngine(duration: secs)
        self.scheduler = scheduler
        syncPublished()
    }

    func start() {
        engine.start(now: Date())
        scheduleEndNotification()
        syncPublished()
    }

    func pause() {
        engine.pause(now: Date())
        scheduler.removePending(identifiers: [Self.notificationId])
        syncPublished()
    }

    func resume() {
        engine.resume(now: Date())
        scheduleEndNotification()
        syncPublished()
    }

    func stop() {
        scheduler.removePending(identifiers: [Self.notificationId])
        engine.reset()
        syncPublished()
    }

    /// View gọi mỗi giây (TimelineView) — phát hiện hết phiên khi đang foreground.
    func onTick() {
        if engine.isFinished(now: Date()) { completeSession() }
        syncPublished()
    }

    private func completeSession() {
        guard let startedAt = engine.startedAt else { engine.reset(); return }
        let payload = NewPomodoroSession(
            startedAt: ISO8601DateFormatter().string(from: startedAt),
            durationMinutes: Int(engine.duration / 60)
        )
        engine.reset()
        Task {
            do { _ = try await repo.create(payload) }
            catch { errorMessage = error.localizedDescription }
        }
    }

    private func scheduleEndNotification() {
        let remaining = engine.remaining(now: Date())
        guard remaining > 0 else { return }
        let content = UNMutableNotificationContent()
        content.title = "Hết phiên tập trung"
        content.body = "Bạn đã hoàn thành một phiên Pomodoro. Nghỉ một chút nhé!"
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: remaining, repeats: false)
        let req = UNNotificationRequest(identifier: Self.notificationId, content: content, trigger: trigger)
        Task { try? await scheduler.add(req) }
    }

    private func syncPublished() {
        state = engine.state
        let r = Int(engine.remaining(now: Date()).rounded())
        remainingText = String(format: "%02d:%02d", r / 60, r % 60)
    }
}
```

(Lưu ý cho coder: notification khi phiên kết thúc lúc app bị suspend vẫn nổ đúng giờ vì đã schedule từ lúc start/resume — `completeSession()` chỉ lo phần LƯU khi user quay lại app. Duration ngắn trong UITest làm `durationMinutes` = 0 — chấp nhận được cho row test.)

- [ ] **Step 4: Run test → PASS**, build xanh, unit suite cũ xanh.
- [ ] **Step 5: Commit** `feat(ios): PomodoroViewModel with end notification and session save`

---

### Task 4: `PomodoroView` + tab "Tập trung" + A11yID

**Files:**
- Create: `FocusPlan/Sources/Views/PomodoroView.swift`
- Modify: `FocusPlan/Sources/Views/MainTabView.swift` (thêm tab thứ 3 sau HabitsView)
- Modify: `FocusPlan/Sources/Support/A11yID.swift` (thêm enum `Pomodoro` sau `TaskForm`)

**Interfaces:**
- Consumes: `PomodoroViewModel` (Task 3), `PomodoroState` (Task 2), `Theme.*`, `authCTAStyle()`.
- Produces: identifiers `pomodoro.time-text`, `pomodoro.start-button`, `pomodoro.pause-button`, `pomodoro.resume-button`, `pomodoro.stop-button` (Task 5 UITest query).

- [ ] **Step 1: Thêm A11yID** — vào `A11yID.swift`:

```swift
enum Pomodoro {
    static let timeText = "pomodoro.time-text"
    static let startButton = "pomodoro.start-button"
    static let pauseButton = "pomodoro.pause-button"
    static let resumeButton = "pomodoro.resume-button"
    static let stopButton = "pomodoro.stop-button"
}
```

- [ ] **Step 2: Implement `PomodoroView.swift`** (khung dưới là cấu trúc bắt buộc — spacing/shadow/màu phụ coder chốt bằng `ui-ux-pro-max`):

```swift
import SwiftUI

struct PomodoroView: View {
    @StateObject private var vm = PomodoroViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                ZStack {
                    Circle().stroke(Theme.primaryContainer, lineWidth: 10)
                    Circle()
                        .trim(from: 0, to: vm.progress)
                        .stroke(Theme.primary, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text(vm.remainingText)
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .accessibilityIdentifier(A11yID.Pomodoro.timeText)
                }
                .frame(width: 220, height: 220)

                controls
            }
            .padding(24)
            .navigationTitle("Tập trung")
            // TimelineView không tiện gọi hàm VM → dùng task lặp 1s khi view sống.
            .task {
                while !Task.isCancelled {
                    vm.onTick()
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                }
            }
            .alert("Lỗi", isPresented: .constant(vm.errorMessage != nil)) {
                Button("OK") { vm.errorMessage = nil }
            } message: { Text(vm.errorMessage ?? "") }
        }
    }

    @ViewBuilder
    private var controls: some View {
        switch vm.state {
        case .idle:
            Button { vm.start() } label: {
                Label("Bắt đầu", systemImage: "play.fill").font(.headline).frame(maxWidth: .infinity)
            }
            .authCTAStyle()
            .accessibilityIdentifier(A11yID.Pomodoro.startButton)
        case .running:
            HStack(spacing: 12) {
                Button { vm.pause() } label: {
                    Label("Tạm dừng", systemImage: "pause.fill").font(.headline).frame(maxWidth: .infinity)
                }
                .authCTAStyle()
                .accessibilityIdentifier(A11yID.Pomodoro.pauseButton)
                stopButton
            }
        case .paused:
            HStack(spacing: 12) {
                Button { vm.resume() } label: {
                    Label("Tiếp tục", systemImage: "play.fill").font(.headline).frame(maxWidth: .infinity)
                }
                .authCTAStyle()
                .accessibilityIdentifier(A11yID.Pomodoro.resumeButton)
                stopButton
            }
        }
    }

    private var stopButton: some View {
        Button(role: .destructive) { vm.stop() } label: {
            Label("Kết thúc", systemImage: "stop.fill").font(.headline).frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, minHeight: Theme.ctaHeight)
        .background(Theme.surfaceVariant, in: RoundedRectangle(cornerRadius: Theme.radiusInput))
        .foregroundStyle(.red)
        .accessibilityIdentifier(A11yID.Pomodoro.stopButton)
    }
}
```

- [ ] **Step 3: Thêm tab** — trong `MainTabView.swift` sau dòng HabitsView:

```swift
PomodoroView()
    .tabItem { Label("Tập trung", systemImage: "timer") }
```

- [ ] **Step 4: Verify** — `xcodegen generate` + build xanh + chạy full test hiện có (unit + UITest cũ) → PASS, 0 fail.
- [ ] **Step 5: Commit** `feat(ios): Pomodoro focus tab with 25-minute timer UI`
- [ ] **Step 6: DỪNG — HITL checkpoint.** Báo leader: cần user chạy SQL migration (file Task 1) trên Supabase SQL Editor trước khi làm Task 5 (UITest ghi row thật). CHỜ xác nhận rồi mới tiếp.

---

### Task 5: `PomodoroFlowUITests` + full suite (SAU khi user đã tạo bảng)

**Files:**
- Create: `FocusPlan/UITests/PomodoroFlowUITests.swift`

**Interfaces:**
- Consumes: identifiers `A11yID.Pomodoro.*` (Task 4), env `UITEST_POMODORO_SECONDS` (Task 3), REST helper pattern từ `HabitFlowUITests.swift` (signup + Supabase REST; copy supabaseURL/anonKey/password từ file đó — không đổi giá trị).

- [ ] **Step 1: Viết UITest** — flow: signup user mới qua REST → sign in UI → mở tab "Tập trung" → start (phiên 5s) → pause → resume → chờ hết phiên → poll REST xác nhận row `pomodoro_sessions` đã lưu:

```swift
import XCTest

final class PomodoroFlowUITests: XCTestCase {
    private let app = XCUIApplication()
    private let supabaseURL = "https://njwmpikyqghniqqiweao.supabase.co"
    private let anonKey = "<COPY nguyên văn từ HabitFlowUITests.swift>"
    private let password = "secret123"
    private var token = ""

    override func setUp() { continueAfterFailure = false }

    private func rest(_ method: String, _ path: String, body: [String: Any]?, bearer: String) -> Any? {
        var req = URLRequest(url: URL(string: supabaseURL + path)!)
        req.httpMethod = method
        req.setValue(anonKey, forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(bearer)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "content-type")
        req.setValue("return=representation", forHTTPHeaderField: "Prefer")
        if let body { req.httpBody = try? JSONSerialization.data(withJSONObject: body) }
        var out: Any?
        let sem = DispatchSemaphore(value: 0)
        URLSession.shared.dataTask(with: req) { data, _, _ in
            if let data { out = try? JSONSerialization.jsonObject(with: data) }
            sem.signal()
        }.resume()
        _ = sem.wait(timeout: .now() + 20)
        return out
    }

    private func signIn(_ email: String) {
        let signOut = app.buttons["home.sign-out-button"]
        if signOut.waitForExistence(timeout: 5) { signOut.tap() }
        XCTAssertTrue(app.textFields["signin.email-field"].waitForExistence(timeout: 10))
        app.textFields["signin.email-field"].tap()
        app.textFields["signin.email-field"].typeText(email)
        app.secureTextFields["signin.password-field"].tap()
        app.secureTextFields["signin.password-field"].typeText(password)
        app.buttons["signin.submit-button"].tap()
        XCTAssertTrue(app.buttons["home.alarm-button"].waitForExistence(timeout: 20))
    }

    func test_pomodoro_full_cycle_saves_session() {
        let email = "pomoqa\(Int(Date().timeIntervalSince1970))@gmail.com"
        let signup = rest("POST", "/auth/v1/signup", body: ["email": email, "password": password], bearer: anonKey) as? [String: Any]
        token = (signup?["access_token"] as? String) ?? ""
        XCTAssertFalse(token.isEmpty, "Signup không trả token")

        app.launchEnvironment["UITEST_POMODORO_SECONDS"] = "5"
        app.launch()
        signIn(email)

        app.tabBars.buttons["Tập trung"].tap()
        let timeText = app.staticTexts["pomodoro.time-text"]
        XCTAssertTrue(timeText.waitForExistence(timeout: 10))
        XCTAssertEqual(timeText.label, "00:05")

        // start → pause → resume
        app.buttons["pomodoro.start-button"].tap()
        XCTAssertTrue(app.buttons["pomodoro.pause-button"].waitForExistence(timeout: 5))
        app.buttons["pomodoro.pause-button"].tap()
        XCTAssertTrue(app.buttons["pomodoro.resume-button"].waitForExistence(timeout: 5))
        app.buttons["pomodoro.resume-button"].tap()

        // chờ hết phiên (5s + đệm) → UI quay về idle
        XCTAssertTrue(app.buttons["pomodoro.start-button"].waitForExistence(timeout: 20),
                      "Hết phiên không quay về trạng thái idle")

        // Row đã lưu trên Supabase (criteria 4)
        var saved = false
        for _ in 0..<10 {
            if let rows = rest("GET", "/rest/v1/pomodoro_sessions?select=id", body: nil, bearer: token) as? [[String: Any]],
               !rows.isEmpty { saved = true; break }
            Thread.sleep(forTimeInterval: 1)
        }
        XCTAssertTrue(saved, "Phiên hoàn thành không được lưu vào pomodoro_sessions")
    }
}
```

- [ ] **Step 2: Run** — `xcodebuild ... -only-testing:FocusPlanUITests/PomodoroFlowUITests test` → PASS.
- [ ] **Step 3: Full suite** — `xcodegen generate && xcodebuild -project FocusPlan.xcodeproj -scheme FocusPlan -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test` → toàn bộ xanh, 0 fail 0 skip.
- [ ] **Step 4: Commit** `feat(ios): Pomodoro flow UITest with Supabase session persistence check`

## Self-Review Notes

- Spec coverage: criterion 1 (start/pause/stop từ UI) → Task 4 + UITest Task 5; criterion 2 (đúng khi minimize/khoá) → wall-clock engine Task 2 (test background-gap) + notification schedule-trước Task 3; criterion 3 (local notification tái dùng issue 005) → Task 3 dùng `NotificationScheduling` có sẵn, không cơ chế mới; criterion 4 (lưu phiên gắn user) → Task 1 (RLS auth.uid) + Task 3 `completeSession()` + Task 5 REST check.
- Quyết định user 2026-07-06 phản ánh đủ: 25 phút cố định (Global Constraints + engine default), tab thứ 3 "Tập trung" (Task 4).
- Type consistency: `PomodoroState`/`PomodoroEngine` (T2) ↔ VM (T3) ↔ View (T4); `NewPomodoroSession(startedAt:durationMinutes:)` (T1) ↔ `completeSession()` (T3); identifiers `pomodoro.*` (T4) ↔ UITest (T5). Đã soát.
- HITL: checkpoint rõ ở Task 4 Step 6 — coder dừng chờ user chạy SQL trước Task 5.
