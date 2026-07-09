# AlarmFormView — Smart Alarm Template Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Màn SwiftUI mới `AlarmFormView` theo template "Smart Alarm" (ảnh tham khảo `assets/4.jpg`), nút "Create Alarm" có tác dụng THẬT qua hạ tầng alarm issue 005, cấu hình persist qua relaunch, phủ `accessibilityIdentifier` chuẩn issue 019.

**Architecture:** Model `UserAlarm` (Codable) persist qua `UserAlarmStore` (UserDefaults/JSON). `UserAlarmPlanner` (pure) map alarm → `[PlannedAlarm]` tái dùng nguyên `AlarmPlanner`; identifier dùng CHUNG prefix `alarm-<uuid>-<i>` với task alarm nên toàn bộ hành vi snooze/done/mở-app-dừng-chuỗi (AlarmAppDelegate, AlarmScheduler) chạy nguyên vẹn không sửa. `TodayScheduleService.refreshAndArm` arm thêm user alarms mỗi lần app active → relaunch tự re-arm. UI là sheet mở từ nút chuông mới trên toolbar HomeView.

**Tech Stack:** SwiftUI (iOS 17), XcodeGen (`FocusPlan/project.yml` — KHÔNG cần sửa, `Sources`/`Tests`/`UITests` include theo folder; chỉ chạy `xcodegen generate` sau khi thêm file), XCTest + XCUITest, UserDefaults.

## Quyết định chốt tại plan (issue 021 yêu cầu "chốt ở plan")

**Map cấu hình → hành vi alarm thật:**

| Toggle | Hiệu ứng runtime | Ghi chú |
|---|---|---|
| Loop alarm audio | **THẬT** — ON: chùm escalating mặc định issue 005 (6 notification / 2 phút); OFF: đúng 1 notification | map qua `AlarmPlanner.Config.repeatCount` |
| Show notification | **THẬT** — ON: alarm được arm qua UNUserNotificationCenter; OFF: alarm chỉ lưu, không arm | |
| Vibrate | **Persist-only** — iOS KHÔNG có public API bật/tắt rung riêng cho từng notification (rung đi theo sound + cài đặt hệ thống) | UI hiển thị caption "Theo cài đặt hệ thống" |
| System volume max | **Persist-only** — iOS KHÔNG có public API ép âm lượng hệ thống cho notification | UI hiển thị caption "Theo cài đặt hệ thống" |

Giữ đủ 4 toggle trên UI để trung thành template; 2 toggle persist-only ghi rõ giới hạn ngay trên UI — không hứa quá khả năng OS.

**Các quyết định khác:**
- Repeat 7 ngày = `Set<Int>` weekday chuẩn `Calendar` (1=CN … 7=T7). Rỗng = one-shot (occurrence kế tiếp của HH:mm).
- Alarm chỉ arm occurrence **kế tiếp**; mỗi lần app active `refreshAndArm` tính lại occurrence mới → alarm lặp tuần duy trì qua mỗi lần mở app. Giới hạn biết trước (chấp nhận): nếu user không mở app nhiều ngày, chỉ occurrence đã arm gần nhất nổ.
- Entry point: nút chuông (`systemImage: "alarm"`) toolbar `topBarLeading` của HomeView → sheet `AlarmFormView`.
- Persist hiển thị được: form **prefill từ alarm lưu gần nhất** → UITest chứng minh persist qua relaunch bằng UI thật.
- Task 1 của plan này hoàn thành `Theme.swift` — **bắt buộc** vì `FocusPlan/Tests/ThemeTests.swift` đang tồn tại (untracked, leftover của plan `2026-07-05-swift-ui-polish-flutter-parity.md` Task 1 bước red) tham chiếu `Theme` chưa có → test target hiện KHÔNG compile. Phần Assets/BrandLogo của polish plan KHÔNG làm ở đây.

## Global Constraints

- **Reference visual = `assets/4.jpg`** (repo root) — template Smart Alarm: header "Today", giờ lớn giữa card trắng, hàng Repeat 7 nút ngày, 4 hàng toggle nền tối chữ trắng toggle tím, CTA tím lớn "Create Alarm", hint text dưới CTA. ĐỌC ảnh này trước khi code UI.
- Nhãn ngày tiếng Việt **T2 T3 T4 T5 T6 T7 CN** (thứ tự hiển thị bắt đầu Thứ 2), copy UI tiếng Việt trừ "Create Alarm" + hint "You can do it" giữ nguyên template.
- Màu/bo góc dùng token `Theme.*` (Task 1): CTA + toggle tint = `Theme.primary` (#4F46E5), CTA cao `Theme.ctaHeight` (52) bo `Theme.radiusInput` (14), day chip bo `Theme.radiusChip` (16), card giờ bo `Theme.radiusCard` (20), hàng toggle nền `Color(hex: 0x111827)` chữ trắng bo `Theme.radiusChip`. Chi tiết thẩm mỹ còn lại (shadow, spacing nhỏ, animation) coder tự quyết bằng skill `ui-ux-pro-max` (stack SwiftUI).
- **KHÔNG đụng:** mascot (issue 022 riêng — không import mascot asset, không tạo MascotView; hint text là chỗ mascot sẽ vào sau), các view/identifier hiện có (chỉ THÊM vào HomeView + A11yID, không đổi cái cũ), `FocusPlan/McpDriver/`, `tools/focusplan-mcp/`.
- Mọi control mới có `accessibilityIdentifier` qua `A11yID` (không magic string trong view) — convention `{screen}.{element}-{type}` (xem `FocusPlan/docs/accessibility-identifiers.md`).
- Test suite phải xanh sau MỖI task. Lệnh chạy trong `FocusPlan/`:
  - Generate + build: `xcodegen generate && xcodebuild -project FocusPlan.xcodeproj -scheme FocusPlan -destination 'generic/platform=iOS Simulator' build`
  - Unit test nhanh: `xcodebuild -project FocusPlan.xcodeproj -scheme FocusPlan -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test -only-testing:FocusPlanTests`
  - Full suite (unit + UITest): bỏ `-only-testing`
- Commit sau mỗi task, message tiếng Anh, prefix `feat(ios):` (Task 1 dùng `style(ui):`).

---

### Task 1: Hoàn thành Theme token layer (gỡ ThemeTests đang đỏ)

**Files:**
- Create: `FocusPlan/Sources/Support/Theme.swift`
- Test: `FocusPlan/Tests/ThemeTests.swift` (ĐÃ TỒN TẠI — untracked, không sửa)

**Interfaces:**
- Produces: `enum Theme` (`Theme.primary`, `Theme.primaryContainer`, `Theme.onPrimaryContainer`, `Theme.secondaryContainer`, `Theme.done`, `Theme.surfaceVariant`, `Theme.onSurfaceVariant`, `Theme.radiusInput`, `Theme.radiusChip`, `Theme.radiusCard`, `Theme.ctaHeight`), `Color(hex: UInt32)` — Task 5 và toàn bộ polish plan sau này dùng.

- [ ] **Step 1: Xác nhận test đỏ** — Run: `xcodegen generate && xcodebuild -project FocusPlan.xcodeproj -scheme FocusPlan -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test -only-testing:FocusPlanTests/ThemeTests`
Expected: FAIL/compile error "cannot find 'Theme'".

- [ ] **Step 2: Implement `Theme.swift`** (spec khớp polish plan Task 1 — KHÔNG chệch giá trị):

```swift
import SwiftUI

/// Design tokens port từ focus_plan_ui_demo (Material 3, seed #4F46E5).
/// Mọi view dùng token này — không hardcode màu/radius trong view.
enum Theme {
    static let primary = Color(hex: 0x4F46E5)
    static let primaryContainer = Color(hex: 0xE0E7FF)   // indigo 100
    static let onPrimaryContainer = Color(hex: 0x312E81) // indigo 900
    static let secondaryContainer = Color(hex: 0xE0E7FF)
    static let done = Color(hex: 0x059669)               // emerald 600
    static let surfaceVariant = Color(.secondarySystemBackground)
    static let onSurfaceVariant = Color(.secondaryLabel)

    static let radiusInput: CGFloat = 14
    static let radiusChip: CGFloat = 16
    static let radiusCard: CGFloat = 20
    static let ctaHeight: CGFloat = 52
}

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}
```

- [ ] **Step 3: Run test → PASS** — lệnh Step 1, expected PASS cả 2 test của ThemeTests; các unit test cũ vẫn xanh.
- [ ] **Step 4: Commit**

```bash
git add FocusPlan/Sources/Support/Theme.swift FocusPlan/Tests/ThemeTests.swift
git commit -m "style(ui): add Theme design tokens (unblocks pre-written ThemeTests)"
```

---

### Task 2: UserAlarm model + UserAlarmStore (persist UserDefaults)

**Files:**
- Create: `FocusPlan/Sources/Models/UserAlarm.swift`
- Create: `FocusPlan/Sources/Services/UserAlarmStore.swift`
- Test: `FocusPlan/Tests/UserAlarmStoreTests.swift`

**Interfaces:**
- Produces: `struct UserAlarm: Codable, Equatable, Identifiable` (fields như code dưới); `struct UserAlarmStore` — `init(defaults: UserDefaults = .standard)`, `func load() -> [UserAlarm]`, `func append(_ alarm: UserAlarm)`, `var latest: UserAlarm?`. Task 3/4/5 dùng đúng các tên này.

- [ ] **Step 1: Viết failing test** — `FocusPlan/Tests/UserAlarmStoreTests.swift`:

```swift
import XCTest
@testable import FocusPlan

final class UserAlarmStoreTests: XCTestCase {
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "UserAlarmStoreTests")!
        defaults.removePersistentDomain(forName: "UserAlarmStoreTests")
    }

    func test_append_then_load_roundtrips_all_fields() {
        let store = UserAlarmStore(defaults: defaults)
        let alarm = UserAlarm(hour: 16, minute: 26, repeatDays: [2, 4, 6],
                              loopAudio: true, vibrate: false,
                              systemVolumeMax: true, showNotification: true)
        store.append(alarm)
        // Store MỚI cùng defaults → chứng minh persist (không phải cache in-memory).
        let reloaded = UserAlarmStore(defaults: defaults).load()
        XCTAssertEqual(reloaded, [alarm])
    }

    func test_latest_returns_last_appended() {
        let store = UserAlarmStore(defaults: defaults)
        store.append(UserAlarm(hour: 7, minute: 0))
        store.append(UserAlarm(hour: 22, minute: 30))
        XCTAssertEqual(store.latest?.hour, 22)
        XCTAssertEqual(store.latest?.minute, 30)
    }

    func test_load_empty_when_nothing_saved() {
        XCTAssertEqual(UserAlarmStore(defaults: defaults).load(), [])
    }
}
```

- [ ] **Step 2: Run → FAIL** — `xcodegen generate` rồi chạy `-only-testing:FocusPlanTests/UserAlarmStoreTests`. Expected: compile error "cannot find 'UserAlarmStore'".

- [ ] **Step 3: Implement** — `FocusPlan/Sources/Models/UserAlarm.swift`:

```swift
import Foundation

/// Báo thức user tạo từ AlarmFormView (template Smart Alarm — assets/4.jpg).
/// vibrate/systemVolumeMax: persist-only — iOS không có public API per-notification
/// (rung/âm lượng đi theo cài đặt hệ thống); xem plan 2026-07-06.
struct UserAlarm: Codable, Equatable, Identifiable {
    var id: UUID = UUID()
    var hour: Int                     // 0-23
    var minute: Int                   // 0-59
    var repeatDays: Set<Int> = []     // Calendar weekday: 1=CN … 7=T7. Rỗng = one-shot.
    var loopAudio: Bool = true        // true: chùm escalating 6 mốc/2'; false: 1 notification
    var vibrate: Bool = true          // persist-only
    var systemVolumeMax: Bool = true  // persist-only
    var showNotification: Bool = true // false: chỉ lưu, không arm
}
```

`FocusPlan/Sources/Services/UserAlarmStore.swift`:

```swift
import Foundation

/// Persist UserAlarm qua UserDefaults (JSON) — local, single-device, đủ cho alarm form.
struct UserAlarmStore {
    private static let key = "user-alarms-v1"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) { self.defaults = defaults }

    func load() -> [UserAlarm] {
        guard let data = defaults.data(forKey: Self.key) else { return [] }
        return (try? JSONDecoder().decode([UserAlarm].self, from: data)) ?? []
    }

    func append(_ alarm: UserAlarm) {
        var all = load()
        all.append(alarm)
        if let data = try? JSONEncoder().encode(all) {
            defaults.set(data, forKey: Self.key)
        }
    }

    var latest: UserAlarm? { load().last }
}
```

- [ ] **Step 4: Run → PASS** (3 test mới + toàn bộ FocusPlanTests xanh).
- [ ] **Step 5: Commit** — `git commit -m "feat(ios): UserAlarm model + UserDefaults-backed store"`

---

### Task 3: UserAlarmPlanner (pure) — map UserAlarm → PlannedAlarm

**Files:**
- Create: `FocusPlan/Sources/Services/UserAlarmPlanner.swift`
- Test: `FocusPlan/Tests/UserAlarmPlannerTests.swift`
- Đọc trước (không sửa): `FocusPlan/Sources/Services/AlarmPlanner.swift`, `FocusPlan/Sources/Models/PlannedAlarm.swift`

**Interfaces:**
- Consumes: `AlarmPlanner` (`plan(taskId:taskName:start:now:config:)`, `Config(repeatCount:intervalMinutes:maxPendingBudget:)`), `UserAlarm` (Task 2).
- Produces: `struct UserAlarmPlanner` — `func nextFireDate(for:after:calendar:) -> Date?`, `func plannedAlarms(for alarm: UserAlarm, now: Date, calendar: Calendar) -> [PlannedAlarm]`, `func plannedAlarms(for alarms: [UserAlarm], now: Date, calendar: Calendar) -> [PlannedAlarm]`. Task 4 dùng overload mảng.

- [ ] **Step 1: Viết failing test** — `FocusPlan/Tests/UserAlarmPlannerTests.swift`:

```swift
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
```

- [ ] **Step 2: Run → FAIL** ("cannot find 'UserAlarmPlanner'").

- [ ] **Step 3: Implement** — `FocusPlan/Sources/Services/UserAlarmPlanner.swift`:

```swift
import Foundation

/// Map UserAlarm → [PlannedAlarm] tái dùng hạ tầng issue 005.
/// Identifier dùng CHUNG prefix "alarm-<uuid>-<i>" với task alarm → snooze/done/
/// mở-app-dừng-chuỗi (AlarmAppDelegate, AlarmScheduler.cancel*) chạy nguyên vẹn.
struct UserAlarmPlanner {
    /// Occurrence kế tiếp sau `now` tại hour:minute thuộc repeatDays (rỗng = ngày bất kỳ).
    func nextFireDate(for alarm: UserAlarm, after now: Date,
                      calendar: Calendar = .current) -> Date? {
        for dayOffset in 0...7 {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: now),
                  let fire = calendar.date(bySettingHour: alarm.hour, minute: alarm.minute,
                                           second: 0, of: day),
                  fire > now else { continue }
            let weekday = calendar.component(.weekday, from: fire)
            if alarm.repeatDays.isEmpty || alarm.repeatDays.contains(weekday) { return fire }
        }
        return nil
    }

    /// PlannedAlarm cho occurrence kế tiếp. showNotification=false → rỗng.
    /// loopAudio=true → chùm escalating mặc định (6 mốc/2'); false → 1 notification.
    func plannedAlarms(for alarm: UserAlarm, now: Date,
                       calendar: Calendar = .current) -> [PlannedAlarm] {
        guard alarm.showNotification,
              let fire = nextFireDate(for: alarm, after: now, calendar: calendar) else { return [] }
        var config = AlarmPlanner.Config()
        if !alarm.loopAudio { config.repeatCount = 1 }
        return AlarmPlanner().plan(taskId: alarm.id, taskName: "Báo thức",
                                   start: fire, now: now, config: config)
    }

    func plannedAlarms(for alarms: [UserAlarm], now: Date,
                       calendar: Calendar = .current) -> [PlannedAlarm] {
        alarms.flatMap { plannedAlarms(for: $0, now: now, calendar: calendar) }
    }
}
```

- [ ] **Step 4: Run → PASS** (6 test mới + suite unit xanh).
- [ ] **Step 5: Commit** — `git commit -m "feat(ios): UserAlarmPlanner maps user alarms onto issue-005 alarm chain"`

---

### Task 4: Tích hợp TodayScheduleService — re-arm user alarms mỗi lần app active

**Files:**
- Modify: `FocusPlan/Sources/Services/TodayScheduleService.swift` (hàm `refreshAndArm`, ~dòng 11-23)

**Interfaces:**
- Consumes: `UserAlarmStore().load()` (Task 2), `UserAlarmPlanner().plannedAlarms(for:now:calendar:)` overload mảng (Task 3).
- Produces: không API mới — chỉ mở rộng hành vi `refreshAndArm`.

- [ ] **Step 1: Sửa `refreshAndArm`** — thay 2 dòng cuối:

```swift
// TRƯỚC:
//     let planned = AlarmPlanner().planMany(items, now: now)
//     await scheduler.arm(planned, calendar: calendar)
// SAU:
        let planned = AlarmPlanner().planMany(items, now: now)
        let userAlarms = UserAlarmPlanner()
            .plannedAlarms(for: UserAlarmStore().load(), now: now, calendar: calendar)
        await scheduler.arm(planned + userAlarms, calendar: calendar)
```

Lưu ý: KHÔNG đổi gì khác trong hàm. `cancelAllAlarms()` đầu hàm xoá theo prefix `alarm-` nên user alarm cũng được cancel-rồi-arm-lại — đúng semantics "mở app dừng chuỗi đang chạy" cho cả user alarm (occurrence đã bắt đầu có `fire ≤ now` bị `AlarmPlanner.plan` bỏ, occurrence kế tiếp được arm mới).

Giới hạn chấp nhận (đã chốt): `guard let tasks/habits` fail (chưa đăng nhập/mất mạng) → return sớm, user alarm cũng không arm lần đó — alarm form nằm sau auth nên chấp nhận; KHÔNG thêm xử lý riêng.

- [ ] **Step 2: Verify** — logic thuần đã test ở Task 3; dòng glue verify bằng build + unit suite: `xcodegen generate && xcodebuild ... test -only-testing:FocusPlanTests`. Expected: PASS toàn bộ (TodayScheduleServiceTests hiện có không đổi).
- [ ] **Step 3: Commit** — `git commit -m "feat(ios): refreshAndArm re-arms persisted user alarms alongside task alarms"`

---

### Task 5: A11yID + AlarmFormView + entry point HomeView

**Files:**
- Modify: `FocusPlan/Sources/Support/A11yID.swift` (THÊM enum `AlarmForm` + `alarmButton` vào enum `Home`; không đổi identifier cũ)
- Create: `FocusPlan/Sources/Views/AlarmFormView.swift`
- Modify: `FocusPlan/Sources/Views/HomeView.swift` (thêm toolbar button + sheet; không đổi gì khác)
- Reference visual: `assets/4.jpg` — ĐỌC ảnh trước khi code.

**Interfaces:**
- Consumes: `Theme.*` (Task 1), `UserAlarm`/`UserAlarmStore` (Task 2), `TodayScheduleService.shared.refreshAndArm()` (Task 4).
- Produces: identifiers cho Task 6 (UITest) — literal: `home.alarm-button`, `alarmform.time-text`, `alarmform.time-picker`, `alarmform.day-toggle-{1…7}`, `alarmform.loop-audio-toggle`, `alarmform.vibrate-toggle`, `alarmform.volume-max-toggle`, `alarmform.show-notification-toggle`, `alarmform.create-button`, `alarmform.cancel-button`, `alarmform.hint-text`.

- [ ] **Step 1: Thêm A11yID** — trong `enum Home` thêm `static let alarmButton = "home.alarm-button"`; thêm enum mới:

```swift
    enum AlarmForm {
        static let timeText = "alarmform.time-text"
        static let timePicker = "alarmform.time-picker"
        /// weekday chuẩn Calendar: 1=CN … 7=T7.
        static func dayToggle(_ weekday: Int) -> String { "alarmform.day-toggle-\(weekday)" }
        static let loopAudioToggle = "alarmform.loop-audio-toggle"
        static let vibrateToggle = "alarmform.vibrate-toggle"
        static let volumeMaxToggle = "alarmform.volume-max-toggle"
        static let showNotificationToggle = "alarmform.show-notification-toggle"
        static let createButton = "alarmform.create-button"
        static let cancelButton = "alarmform.cancel-button"
        static let hintText = "alarmform.hint-text"
    }
```

- [ ] **Step 2: Implement `AlarmFormView.swift`:**

```swift
import SwiftUI

/// Màn tạo báo thức theo template "Smart Alarm" (assets/4.jpg).
/// Vibrate / System volume max: persist-only (iOS không có public API per-notification)
/// → caption "Theo cài đặt hệ thống". Xem plan 2026-07-06-alarm-form-view.
struct AlarmFormView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var time: Date
    @State private var repeatDays: Set<Int>
    @State private var loopAudio: Bool
    @State private var vibrate: Bool
    @State private var systemVolumeMax: Bool
    @State private var showNotification: Bool
    @State private var showTimePicker = false

    private let store: UserAlarmStore
    // Hiển thị bắt đầu Thứ 2; giá trị = weekday chuẩn Calendar.
    private let days: [(weekday: Int, label: String)] = [
        (2, "T2"), (3, "T3"), (4, "T4"), (5, "T5"), (6, "T6"), (7, "T7"), (1, "CN")
    ]

    init(store: UserAlarmStore = UserAlarmStore()) {
        self.store = store
        let cal = Calendar.current
        let last = store.latest                          // prefill = bằng chứng persist
        let now = Date()
        let h = last?.hour ?? cal.component(.hour, from: now)
        let m = last?.minute ?? cal.component(.minute, from: now)
        _time = State(initialValue: cal.date(bySettingHour: h, minute: m, second: 0, of: now) ?? now)
        _repeatDays = State(initialValue: last?.repeatDays ?? [])
        _loopAudio = State(initialValue: last?.loopAudio ?? true)
        _vibrate = State(initialValue: last?.vibrate ?? true)
        _systemVolumeMax = State(initialValue: last?.systemVolumeMax ?? true)
        _showNotification = State(initialValue: last?.showNotification ?? true)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    timeCard
                    repeatSection
                    settingsSection
                    createButton
                    Text("You can do it")
                        .font(.subheadline)
                        .foregroundStyle(Theme.onSurfaceVariant)
                        .accessibilityIdentifier(A11yID.AlarmForm.hintText)
                }
                .padding(16)
            }
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Đóng") { dismiss() }
                        .accessibilityIdentifier(A11yID.AlarmForm.cancelButton)
                }
            }
        }
    }

    // MARK: - Sections

    private var timeCard: some View {
        VStack(spacing: 8) {
            Button {
                withAnimation { showTimePicker.toggle() }
            } label: {
                Text(time.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.primary)
            }
            .accessibilityIdentifier(A11yID.AlarmForm.timeText)
            .accessibilityLabel("Chọn giờ báo thức")

            if showTimePicker {
                DatePicker("Giờ báo thức", selection: $time, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .accessibilityIdentifier(A11yID.AlarmForm.timePicker)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: Theme.radiusCard))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }

    private var repeatSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Lặp lại").font(.headline)
            HStack(spacing: 8) {
                ForEach(days, id: \.weekday) { day in
                    dayChip(day.weekday, day.label)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func dayChip(_ weekday: Int, _ label: String) -> some View {
        let isOn = repeatDays.contains(weekday)
        return Button {
            if isOn { repeatDays.remove(weekday) } else { repeatDays.insert(weekday) }
        } label: {
            Text(label)
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: 40)
                .background(isOn ? Theme.primary : Theme.surfaceVariant,
                            in: RoundedRectangle(cornerRadius: Theme.radiusChip))
                .foregroundStyle(isOn ? Color.white : Color.primary)
        }
        .accessibilityIdentifier(A11yID.AlarmForm.dayToggle(weekday))
        .accessibilityLabel("Lặp lại \(label)")
        .accessibilityAddTraits(isOn ? [.isSelected] : [])
    }

    private var settingsSection: some View {
        VStack(spacing: 10) {
            settingRow("Loop alarm audio", isOn: $loopAudio,
                       id: A11yID.AlarmForm.loopAudioToggle)
            settingRow("Vibrate", caption: "Theo cài đặt hệ thống", isOn: $vibrate,
                       id: A11yID.AlarmForm.vibrateToggle)
            settingRow("System volume max", caption: "Theo cài đặt hệ thống", isOn: $systemVolumeMax,
                       id: A11yID.AlarmForm.volumeMaxToggle)
            settingRow("Show notification", isOn: $showNotification,
                       id: A11yID.AlarmForm.showNotificationToggle)
        }
    }

    private func settingRow(_ title: String, caption: String? = nil,
                            isOn: Binding<Bool>, id: String) -> some View {
        Toggle(isOn: isOn) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).foregroundStyle(Color.white)
                if let caption {
                    Text(caption).font(.caption).foregroundStyle(Color.white.opacity(0.6))
                }
            }
        }
        .tint(Theme.primary)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(hex: 0x111827), in: RoundedRectangle(cornerRadius: Theme.radiusChip))
        .accessibilityIdentifier(id)
    }

    private var createButton: some View {
        Button {
            createAlarm()
        } label: {
            Text("Create Alarm")
                .font(.headline)
                .frame(maxWidth: .infinity, minHeight: Theme.ctaHeight)
                .background(Theme.primary, in: RoundedRectangle(cornerRadius: Theme.radiusInput))
                .foregroundStyle(Color.white)
        }
        .accessibilityIdentifier(A11yID.AlarmForm.createButton)
    }

    // MARK: - Actions

    private func createAlarm() {
        let cal = Calendar.current
        let alarm = UserAlarm(hour: cal.component(.hour, from: time),
                              minute: cal.component(.minute, from: time),
                              repeatDays: repeatDays,
                              loopAudio: loopAudio, vibrate: vibrate,
                              systemVolumeMax: systemVolumeMax,
                              showNotification: showNotification)
        store.append(alarm)
        dismiss()
        Task { await TodayScheduleService.shared.refreshAndArm() }  // arm thật (Task 4)
    }
}
```

- [ ] **Step 3: Entry point HomeView** — trong `.toolbar { ... }` hiện có, THÊM (không đổi nút sign-out):

```swift
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showAlarmForm = true
                    } label: {
                        Image(systemName: "alarm")
                    }
                    .accessibilityLabel("Tạo báo thức")
                    .accessibilityIdentifier(A11yID.Home.alarmButton)
                }
```

và thêm state + sheet vào `HomeView`:

```swift
    @State private var showAlarmForm = false
    // ... trên NavigationStack closing brace:
            .sheet(isPresented: $showAlarmForm) { AlarmFormView() }
```

- [ ] **Step 4: Build + suite unit xanh** — `xcodegen generate && xcodebuild ... build` rồi `-only-testing:FocusPlanTests`. Expected: build PASS, unit xanh. Chi tiết thẩm mỹ cuối (spacing/shadow) đối chiếu `assets/4.jpg` bằng skill `ui-ux-pro-max` nếu cần chỉnh.
- [ ] **Step 5: Commit** — `git commit -m "feat(ios): AlarmFormView (Smart Alarm template) with real alarm arming + a11y ids"`

---

### Task 6: AlarmFlowUITests — flow tạo alarm + persist qua relaunch

**Files:**
- Create: `FocusPlan/UITests/AlarmFlowUITests.swift`
- Pattern copy từ: `FocusPlan/UITests/A11yIdentifierUITests.swift` (helper seedUser/typeInto/pasteInto/dismissSavePasswordDialog/anyEl — COPY tối thiểu, không refactor file cũ; identifier dùng LITERAL vì UITest target không link app module)

- [ ] **Step 1: Viết UITest:**

```swift
import XCTest
import UIKit

/// Issue 021: tạo alarm qua UI hoàn toàn bằng identifier + chứng minh persist qua relaunch
/// (form prefill từ alarm lưu gần nhất — vibrate OFF sống sót sau terminate/relaunch).
final class AlarmFlowUITests: XCTestCase {

    private let app = XCUIApplication(bundleIdentifier: "com.votronghoang.focusplan")
    private let supabaseURL = "https://njwmpikyqghniqqiweao.supabase.co"
    private let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5qd21waWt5cWdobmlxcWl3ZWFvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODMwNzE3OTIsImV4cCI6MjA5ODY0Nzc5Mn0.gB8a3wg86lBqwh7ltYJ0_tsJOED6O9Vk14DRP3vXjag"
    private let password = "secret123"

    override func setUp() { continueAfterFailure = false }

    // MARK: - Helpers (copy tối thiểu từ A11yIdentifierUITests)

    private func postJSON(_ path: String, body: [String: Any], bearer: String) -> [String: Any]? {
        var req = URLRequest(url: URL(string: supabaseURL + path)!)
        req.httpMethod = "POST"
        req.setValue(anonKey, forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(bearer)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "content-type")
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        var result: [String: Any]?
        let sem = DispatchSemaphore(value: 0)
        URLSession.shared.dataTask(with: req) { data, _, _ in
            if let data, let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                result = obj
            }
            sem.signal()
        }.resume()
        _ = sem.wait(timeout: .now() + 20)
        return result
    }

    private func seedUser() -> String {
        let email = "alarmqa\(Int(Date().timeIntervalSince1970))_\(UInt32.random(in: 0 ..< 1_000_000))@gmail.com"
        let signup = postJSON("/auth/v1/signup", body: ["email": email, "password": password], bearer: anonKey)
        XCTAssertNotNil(signup?["access_token"] as? String, "Seed: signup không trả token")
        return email
    }

    private func typeInto(_ field: XCUIElement, _ text: String) {
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap(); field.typeText(text)
    }

    private func pasteInto(_ field: XCUIElement, _ text: String) {
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        UIPasteboard.general.string = text
        field.tap(); field.press(forDuration: 1.3)
        let paste = app.menuItems["Paste"].firstMatch
        XCTAssertTrue(paste.waitForExistence(timeout: 5))
        paste.tap()
    }

    @discardableResult
    private func dismissSavePasswordDialog() -> Bool {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        for label in ["Để sau", "Not Now", "Lúc khác"] {
            let appBtn = app.buttons[label]
            if appBtn.exists { appBtn.tap(); return true }
            let sbBtn = springboard.buttons[label]
            if sbBtn.exists { sbBtn.tap(); return true }
        }
        return false
    }

    private func signIn(email: String) {
        let signOut = app.buttons["home.sign-out-button"]
        if signOut.waitForExistence(timeout: 5) { signOut.tap() }
        XCTAssertTrue(app.textFields["signin.email-field"].waitForExistence(timeout: 10))
        typeInto(app.textFields["signin.email-field"], email)
        pasteInto(app.secureTextFields["signin.password-field"], password)
        app.buttons["signin.submit-button"].tap()
        for _ in 0..<8 { if dismissSavePasswordDialog() { break }; Thread.sleep(forTimeInterval: 1) }
        XCTAssertTrue(app.buttons["home.alarm-button"].waitForExistence(timeout: 20),
                      "home.alarm-button không xuất hiện sau đăng nhập")
    }

    /// Mở AlarmFormView (retry tap như pattern add-button các test cũ).
    private func openAlarmForm() {
        let alarmBtn = app.buttons["home.alarm-button"]
        let createBtn = app.buttons["alarmform.create-button"]
        for _ in 0..<3 {
            dismissSavePasswordDialog()
            alarmBtn.tap()
            if createBtn.waitForExistence(timeout: 5) { break }
        }
        XCTAssertTrue(createBtn.exists, "AlarmFormView chưa mở (create-button không thấy)")
    }

    // MARK: - Test

    func test_create_alarm_via_identifiers_and_persist_across_relaunch() {
        let email = seedUser()
        app.launch()
        signIn(email: email)

        // --- Mở form, đủ control qua identifier ---
        openAlarmForm()
        XCTAssertTrue(app.buttons["alarmform.time-text"].exists)
        XCTAssertTrue(app.buttons["alarmform.day-toggle-2"].exists)   // T2
        XCTAssertTrue(app.buttons["alarmform.day-toggle-1"].exists)   // CN
        XCTAssertTrue(app.switches["alarmform.loop-audio-toggle"].exists)
        XCTAssertTrue(app.switches["alarmform.show-notification-toggle"].exists)
        XCTAssertTrue(app.staticTexts["alarmform.hint-text"].exists)

        // --- Cấu hình đặc trưng: chọn T2 + T4, tắt Vibrate ---
        app.buttons["alarmform.day-toggle-2"].tap()
        app.buttons["alarmform.day-toggle-4"].tap()
        let vibrate = app.switches["alarmform.vibrate-toggle"]
        XCTAssertEqual(vibrate.value as? String, "1", "Vibrate mặc định phải ON")
        vibrate.switches.firstMatch.tap()   // SwiftUI Toggle: tap switch con
        XCTAssertEqual(vibrate.value as? String, "0")

        // --- Create Alarm → sheet đóng ---
        app.buttons["alarmform.create-button"].tap()
        XCTAssertTrue(app.buttons["home.alarm-button"].waitForExistence(timeout: 10),
                      "Sheet chưa đóng sau Create Alarm")

        // --- Relaunch: session Supabase còn, form prefill từ alarm đã lưu ---
        app.terminate()
        app.launch()
        XCTAssertTrue(app.buttons["home.alarm-button"].waitForExistence(timeout: 20),
                      "Session không persist sau relaunch")
        openAlarmForm()
        XCTAssertEqual(app.switches["alarmform.vibrate-toggle"].value as? String, "0",
                       "Vibrate OFF không persist qua relaunch")
        // Day chip đã chọn persist (trait isSelected).
        XCTAssertTrue(app.buttons["alarmform.day-toggle-2"].isSelected,
                      "Ngày T2 đã chọn không persist qua relaunch")
    }
}
```

Lưu ý cho coder: nếu assertion `value`/`isSelected` của SwiftUI Toggle/Button khác trên iOS 17 thực tế (switch expose lồng nhau, trait không truyền), điều chỉnh CÁCH ĐỌC trạng thái trong test (vd `descendants(matching: .switch)`), KHÔNG hạ yêu cầu persist — trạng thái sau relaunch bắt buộc phải assert được.

- [ ] **Step 2: Run → PASS** — `xcodebuild -project FocusPlan.xcodeproj -scheme FocusPlan -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test -only-testing:FocusPlanUITests/AlarmFlowUITests`
- [ ] **Step 3: Commit** — `git commit -m "test(ios): UITest creates alarm via identifiers and proves persistence across relaunch"`

---

### Task 7: Docs identifier + full suite

**Files:**
- Modify: `FocusPlan/docs/accessibility-identifiers.md` (THÊM bảng identifier màn AlarmForm + `home.alarm-button`, format khớp các bảng hiện có — MCP agent (issue 020) tra bảng này để điều khiển)

- [ ] **Step 1:** Thêm section "AlarmForm (issue 021)" vào doc: liệt kê 11 identifier mới + loại XCUIElement thật của từng cái (Button/Switch/DatePicker/StaticText — điền theo kết quả UITest Task 6).
- [ ] **Step 2: Full suite** — `xcodegen generate && xcodebuild -project FocusPlan.xcodeproj -scheme FocusPlan -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test`
Expected: PASS toàn bộ (unit cũ + 9 unit mới + UITest cũ + AlarmFlowUITests). Đây là tiêu chí done cuối của issue 021.
- [ ] **Step 3: Commit** — `git commit -m "docs(ios): document alarmform accessibility identifiers for MCP control"`

---

## Acceptance criteria mapping (issue 021)

| Criteria | Task |
|---|---|
| AlarmFormView đúng cấu trúc template (giờ lớn, Repeat 7 ngày, 4 toggle, CTA) | Task 5 (reference `assets/4.jpg`) |
| Create Alarm → persist qua relaunch + ảnh hưởng thật chuỗi alarm | Task 2 (store) + Task 3 (map đã chốt) + Task 4 (arm) + Task 6 (proof relaunch) |
| Mọi control có accessibilityIdentifier chuẩn issue 019 | Task 5 (A11yID) + Task 7 (docs) |
| Test suite xanh; test logic map (thuần) + XCUITest flow | Task 1 (gỡ ThemeTests đỏ) + Task 3 + Task 6 + Task 7 (full suite) |
