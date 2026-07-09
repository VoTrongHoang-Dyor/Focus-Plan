# Local Escalating Alarm Loop Implementation Plan

> **For agentic workers:** Trong team này coder thực thi toàn bộ plan task-by-task rồi bàn giao reviewer — KHÔNG tự dispatch subagent. Steps dùng checkbox (`- [ ]`).

**Goal:** Khi đến giờ task đã được Scheduling Engine (issue 004) xếp lịch, app bắn 1 chùm local notification lặp lại (~6 lần, cách 2 phút, trong ~10 phút) với nội dung khẩn dần (escalating), best-effort — KHÔNG Critical Alerts entitlement; user tương tác (mở app / Done / Snooze) thì chuỗi dừng.

**Architecture:** Tách phần thuần test được (lập kế hoạch chùm alarm) khỏi phần OS. `AlarmPlanner` (pure) sinh danh sách `PlannedAlarm` từ (task, giờ bắt đầu) — offset 0/2/4/6/8/10', text khẩn dần, chỉ giờ tương lai, có budget ≤ giới hạn 64 pending của iOS. `AlarmScheduler` bọc `UNUserNotificationCenter` qua protocol inject được (test bằng fake). `TodayScheduleService` load task + habit → `HabitBusyBlockService` → `SchedulingEngine` → `[ScheduledBlock]` → arm alarm. Delegate xử lý action Done/Snooze + re-arm khi app active (đây là điểm "mở app → chuỗi dừng"). System default sound (user chốt v1, escalation qua copy).

**Tech Stack:** Swift/SwiftUI iOS 17, `UserNotifications` (`UNUserNotificationCenter`, `UNCalendarNotificationTrigger`, `UNNotificationCategory`/actions), `@UIApplicationDelegateAdaptor`. Tích hợp `SchedulingEngine`/`TaskRepository`/`HabitRepository` (issue 002/003/004).

## Global Constraints

- **Nối tiếp app `FocusPlan/`.** SwiftUI, XcodeGen recursive `Sources/`, source mới vào `FocusPlan/Sources/...`, test vào `FocusPlan/Tests/`, chạy `xcodegen generate`.
- **Best-effort, KHÔNG Critical Alerts** (Decision Log): dùng local notification thường (`.default` sound), KHÔNG xin entitlement Critical Alerts, KHÔNG background mode. Chấp nhận iOS có thể gộp/độ trễ — đúng tinh thần best-effort.
- **Cơ chế lặp = pre-schedule 1 chùm** `UNNotificationRequest` định giờ trước (offset 0,2,4,6,8,10'), KHÔNG dùng background task tự bắn tiếp (user chốt; iOS background không tin cậy).
- **Escalating = nội dung text khẩn dần** + system default sound (user chốt v1 — KHÔNG bundle asset âm thanh).
- **Giới hạn 64 pending của iOS:** tổng notification arm phải ≤ budget (mặc định 60), ưu tiên task có giờ bắt đầu sớm nhất.
- **Identifier scheme:** `alarm-<taskId.uuidString>-<index>` để cancel theo từng task.
- **Interaction dừng chuỗi (criteria 3):** (a) app trở active → cancel toàn bộ `alarm-*` pending rồi re-arm theo lịch còn tương lai; (b) action "Done" → cancel chùm của đúng task; (c) action "Snooze" → cancel chùm của task đó rồi arm chùm mới từ now+10'.
- **KHÔNG persist schedule vào DB** — recompute deterministic mỗi lần active (engine đã deterministic, YAGNI).
- **"Done" chỉ dừng chuỗi**, KHÔNG cập nhật trạng thái task vào Supabase (bảng `tasks` chưa có cột done — ngoài scope issue 005).
- **Criteria 4 (device thật):** môi trường team KHÔNG có iPhone thật → verify tối đa trên simulator + unit test logic; criteria 4 giao user QA trên device (leader ghi rõ giới hạn, KHÔNG coi simulator = device).
- **Naming:** không đặt type Swift tên `Task`.

## File Structure

```
FocusPlan/
├── Sources/
│   ├── FocusPlanApp.swift                      # (modify) @UIApplicationDelegateAdaptor + scenePhase re-arm
│   ├── Models/
│   │   └── PlannedAlarm.swift                   # (create) value: identifier/fireDate/title/body
│   ├── Services/
│   │   ├── AlarmPlanner.swift                   # (create) pure: sinh [PlannedAlarm] (chùm, escalating, budget)
│   │   ├── AlarmScheduler.swift                 # (create) bọc UNUserNotificationCenter qua protocol
│   │   └── TodayScheduleService.swift           # (create) load→engine→arm; @MainActor
│   └── Support/
│       └── AlarmNotificationDelegate.swift      # (create) UNUserNotificationCenterDelegate + actions + AppDelegate
└── Tests/
    ├── AlarmPlannerTests.swift                  # (create) chùm/offset/escalation/skip-past/budget
    └── AlarmSchedulerTests.swift                # (create) arm/cancel identifiers (fake center)
```

**Quyết định phân rã:** `AlarmPlanner` (Task 2) + `AlarmScheduler` (Task 3) là phần test tự động được — cốt lõi. Delegate/actions (Task 4) + wiring engine (Task 5) là glue OS, verify build + simulator + device QA thủ công. Permission + scaffold delegate (Task 1) làm nền.

---

### Task 1: AppDelegate + notification permission + delegate scaffold

**Files:**
- Create: `FocusPlan/Sources/Support/AlarmNotificationDelegate.swift`
- Modify: `FocusPlan/Sources/FocusPlanApp.swift`

**Interfaces:**
- Produces:
  - `final class AlarmAppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate` — set làm delegate của notification center, đăng ký category actions, xử lý response (điền đủ ở Task 4; Task 1 chỉ scaffold + permission).
  - `enum AlarmNotification { static let categoryId = "FOCUS_ALARM"; static let doneAction = "ALARM_DONE"; static let snoozeAction = "ALARM_SNOOZE" }`

- [ ] **Step 1: Viết scaffold `AlarmNotificationDelegate.swift`**

```swift
import UIKit
import UserNotifications

enum AlarmNotification {
    static let categoryId = "FOCUS_ALARM"
    static let doneAction = "ALARM_DONE"
    static let snoozeAction = "ALARM_SNOOZE"
}

final class AlarmAppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        registerCategories(center)
        return true
    }

    private func registerCategories(_ center: UNUserNotificationCenter) {
        let done = UNNotificationAction(identifier: AlarmNotification.doneAction,
                                        title: "Xong", options: [.foreground])
        let snooze = UNNotificationAction(identifier: AlarmNotification.snoozeAction,
                                          title: "Hoãn 10'", options: [])
        let category = UNNotificationCategory(identifier: AlarmNotification.categoryId,
                                              actions: [done, snooze], intentIdentifiers: [],
                                              options: [])
        center.setNotificationCategories([category])
    }

    // Hiện banner + sound cả khi app đang foreground.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async
        -> UNNotificationPresentationOptions { [.banner, .sound] }

    // Task 4 sẽ điền xử lý action.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse) async { }
}
```

- [ ] **Step 2: Sửa `FocusPlanApp.swift`** — gắn AppDelegate + xin permission:

```swift
import SwiftUI

@main
struct FocusPlanApp: App {
    @UIApplicationDelegateAdaptor(AlarmAppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            RootView()
                .task { await requestNotificationPermission() }
        }
    }

    private func requestNotificationPermission() async {
        _ = try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge])
    }
}
```
(Thêm `import UserNotifications` nếu cần cho `UNUserNotificationCenter`.)

- [ ] **Step 3: Build**

Run (trong `FocusPlan/`): `xcodegen generate && xcodebuild -project FocusPlan.xcodeproj -scheme FocusPlan -destination 'generic/platform=iOS Simulator' build`
Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 4: Commit**

```bash
git add FocusPlan/Sources/Support/AlarmNotificationDelegate.swift FocusPlan/Sources/FocusPlanApp.swift
git commit -m "feat(ios): notification permission + alarm delegate scaffold"
```

---

### Task 2: AlarmPlanner (pure) + unit tests — chùm escalating

**Files:**
- Create: `FocusPlan/Sources/Models/PlannedAlarm.swift`
- Create: `FocusPlan/Sources/Services/AlarmPlanner.swift`
- Create: `FocusPlan/Tests/AlarmPlannerTests.swift`

**Interfaces:**
- Produces:
  - `struct PlannedAlarm: Equatable { let identifier: String; let fireDate: Date; let title: String; let body: String }`
  - `struct AlarmPlanner { struct Config { var repeatCount: Int = 6; var intervalMinutes: Int = 2; var maxPendingBudget: Int = 60 }; func plan(taskId: UUID, taskName: String, start: Date, now: Date, config: Config) -> [PlannedAlarm]; func planMany(_ items: [(id: UUID, name: String, start: Date)], now: Date, config: Config) -> [PlannedAlarm] }`

- [ ] **Step 1: Viết `PlannedAlarm.swift`**

```swift
import Foundation

struct PlannedAlarm: Equatable {
    let identifier: String
    let fireDate: Date
    let title: String
    let body: String
}
```

- [ ] **Step 2: Viết failing test `AlarmPlannerTests.swift`**

```swift
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
```

- [ ] **Step 3: Chạy test để xác nhận FAIL**

Run: `xcodegen generate && xcodebuild -project FocusPlan.xcodeproj -scheme FocusPlan -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:FocusPlanTests/AlarmPlannerTests test`
Expected: FAIL (chưa có `AlarmPlanner`).

- [ ] **Step 4: Viết `AlarmPlanner.swift`**

```swift
import Foundation

struct AlarmPlanner {
    struct Config {
        var repeatCount: Int = 6
        var intervalMinutes: Int = 2
        var maxPendingBudget: Int = 60
    }

    func plan(taskId: UUID, taskName: String, start: Date, now: Date,
              config: Config = Config()) -> [PlannedAlarm] {
        (0..<config.repeatCount).compactMap { i in
            let fire = start.addingTimeInterval(TimeInterval(i * config.intervalMinutes * 60))
            guard fire > now else { return nil }
            return PlannedAlarm(
                identifier: "alarm-\(taskId.uuidString)-\(i)",
                fireDate: fire,
                title: Self.title(index: i),
                body: Self.body(taskName: taskName))
        }
    }

    /// Nhiều task: sort theo giờ bắt đầu, gom chùm, cắt theo budget tổng (né 64-limit).
    func planMany(_ items: [(id: UUID, name: String, start: Date)], now: Date,
                  config: Config = Config()) -> [PlannedAlarm] {
        let ordered = items.sorted { $0.start < $1.start }
        var out: [PlannedAlarm] = []
        for item in ordered {
            let chunk = plan(taskId: item.id, taskName: item.name, start: item.start, now: now, config: config)
            for a in chunk {
                if out.count >= config.maxPendingBudget { return out }
                out.append(a)
            }
        }
        return out
    }

    private static func title(index: Int) -> String {
        switch index {
        case 0: return "⏰ Đến giờ rồi"
        case 1: return "Bắt đầu ngay nào"
        case 2: return "Bạn đang trễ…"
        case 3: return "Đừng trì hoãn nữa!"
        case 4: return "😤 Nghiêm túc nào"
        default: return "⏰⏰ LÀM NGAY"
        }
    }

    private static func body(taskName: String) -> String {
        "Task: \(taskName)"
    }
}
```

- [ ] **Step 5: Chạy test PASS**

Run: `xcodegen generate && xcodebuild -project FocusPlan.xcodeproj -scheme FocusPlan -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:FocusPlanTests/AlarmPlannerTests test`
Expected: `** TEST SUCCEEDED **` (4 test).

- [ ] **Step 6: Commit**

```bash
git add FocusPlan/Sources/Models/PlannedAlarm.swift FocusPlan/Sources/Services/AlarmPlanner.swift \
  FocusPlan/Tests/AlarmPlannerTests.swift
git commit -m "feat(ios): AlarmPlanner builds escalating notification burst (pure, tested)"
```

---

### Task 3: AlarmScheduler (bọc UNUserNotificationCenter) + unit tests

**Files:**
- Create: `FocusPlan/Sources/Services/AlarmScheduler.swift`
- Create: `FocusPlan/Tests/AlarmSchedulerTests.swift`

**Interfaces:**
- Consumes: `PlannedAlarm` (Task 2).
- Produces:
  - `protocol NotificationScheduling { func add(_ request: UNNotificationRequest) async throws; func removePending(identifiers: [String]); func pendingIdentifiers() async -> [String] }`
  - `struct LiveNotificationScheduling: NotificationScheduling` (bọc `UNUserNotificationCenter.current()`).
  - `struct AlarmScheduler { let center: NotificationScheduling; func arm(_ planned: [PlannedAlarm], calendar: Calendar) async; func cancel(taskId: UUID) async; func cancelAllAlarms() async }`

- [ ] **Step 1: Viết failing test `AlarmSchedulerTests.swift`** (fake center)

```swift
import XCTest
import UserNotifications
@testable import FocusPlan

final class AlarmSchedulerTests: XCTestCase {
    // Fake thu thập request đã add + xử lý remove.
    final class FakeCenter: NotificationScheduling, @unchecked Sendable {
        var added: [UNNotificationRequest] = []
        func add(_ request: UNNotificationRequest) async throws { added.append(request) }
        func removePending(identifiers: [String]) { added.removeAll { identifiers.contains($0.identifier) } }
        func pendingIdentifiers() async -> [String] { added.map(\.identifier) }
    }

    private func planned(_ taskId: UUID, _ n: Int) -> [PlannedAlarm] {
        (0..<n).map { i in PlannedAlarm(identifier: "alarm-\(taskId.uuidString)-\(i)",
            fireDate: Date(timeIntervalSince1970: TimeInterval(10_000 + i * 120)),
            title: "T\(i)", body: "B") }
    }

    func test_arm_adds_one_request_per_planned() async {
        let id = UUID(); let fake = FakeCenter()
        let sched = AlarmScheduler(center: fake)
        await sched.arm(planned(id, 6), calendar: .current)
        XCTAssertEqual(fake.added.count, 6)
        XCTAssertEqual(Set(fake.added.map(\.identifier)),
                       Set((0..<6).map { "alarm-\(id.uuidString)-\($0)" }))
        // sound + category gắn đúng.
        XCTAssertEqual(fake.added.first?.content.categoryIdentifier, AlarmNotification.categoryId)
    }

    func test_cancel_taskId_removes_only_that_tasks_alarms() async {
        let a = UUID(); let b = UUID(); let fake = FakeCenter()
        let sched = AlarmScheduler(center: fake)
        await sched.arm(planned(a, 6), calendar: .current)
        await sched.arm(planned(b, 6), calendar: .current)
        await sched.cancel(taskId: a)
        let remaining = await fake.pendingIdentifiers()
        XCTAssertTrue(remaining.allSatisfy { $0.contains(b.uuidString) })
        XCTAssertEqual(remaining.count, 6)
    }

    func test_cancelAllAlarms_removes_all_alarm_prefixed() async {
        let a = UUID(); let fake = FakeCenter()
        let sched = AlarmScheduler(center: fake)
        await sched.arm(planned(a, 6), calendar: .current)
        await sched.cancelAllAlarms()
        let remaining = await fake.pendingIdentifiers()
        XCTAssertTrue(remaining.isEmpty)
    }
}
```

- [ ] **Step 2: Chạy test FAIL**

Run: `xcodegen generate && xcodebuild ... -only-testing:FocusPlanTests/AlarmSchedulerTests test` (destination iPhone 17 Pro)
Expected: FAIL (chưa có `AlarmScheduler`/`NotificationScheduling`).

- [ ] **Step 3: Viết `AlarmScheduler.swift`**

```swift
import Foundation
import UserNotifications

protocol NotificationScheduling {
    func add(_ request: UNNotificationRequest) async throws
    func removePending(identifiers: [String])
    func pendingIdentifiers() async -> [String]
}

struct LiveNotificationScheduling: NotificationScheduling {
    private let center = UNUserNotificationCenter.current()
    func add(_ request: UNNotificationRequest) async throws { try await center.add(request) }
    func removePending(identifiers: [String]) {
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }
    func pendingIdentifiers() async -> [String] {
        await center.pendingNotificationRequests().map(\.identifier)
    }
}

struct AlarmScheduler {
    let center: NotificationScheduling
    private let alarmPrefix = "alarm-"

    func arm(_ planned: [PlannedAlarm], calendar: Calendar = .current) async {
        for p in planned {
            let content = UNMutableNotificationContent()
            content.title = p.title
            content.body = p.body
            content.sound = .default
            content.categoryIdentifier = AlarmNotification.categoryId
            let comps = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second],
                                                from: p.fireDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            let req = UNNotificationRequest(identifier: p.identifier, content: content, trigger: trigger)
            try? await center.add(req)
        }
    }

    func cancel(taskId: UUID) async {
        let prefix = "\(alarmPrefix)\(taskId.uuidString)-"
        let ids = await center.pendingIdentifiers().filter { $0.hasPrefix(prefix) }
        center.removePending(identifiers: ids)
    }

    func cancelAllAlarms() async {
        let ids = await center.pendingIdentifiers().filter { $0.hasPrefix(alarmPrefix) }
        center.removePending(identifiers: ids)
    }
}
```

- [ ] **Step 4: Chạy test PASS**

Run: `xcodegen generate && xcodebuild ... -only-testing:FocusPlanTests/AlarmSchedulerTests test`
Expected: `** TEST SUCCEEDED **` (3 test).

- [ ] **Step 5: Commit**

```bash
git add FocusPlan/Sources/Services/AlarmScheduler.swift FocusPlan/Tests/AlarmSchedulerTests.swift
git commit -m "feat(ios): AlarmScheduler wraps UNUserNotificationCenter (arm/cancel, tested via fake)"
```

---

### Task 4: Action Done/Snooze + dừng chuỗi trong delegate

**Files:**
- Modify: `FocusPlan/Sources/Support/AlarmNotificationDelegate.swift`

**Interfaces:**
- Consumes: `AlarmScheduler` (Task 3), `AlarmPlanner` (Task 2).

- [ ] **Step 1: Điền xử lý `didReceive` + helper taskId từ identifier** — thay body rỗng ở Task 1:

```swift
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse) async {
        let id = response.notification.request.identifier          // "alarm-<uuid>-<i>"
        guard let taskId = Self.taskId(from: id) else { return }
        let scheduler = AlarmScheduler(center: LiveNotificationScheduling())

        switch response.actionIdentifier {
        case AlarmNotification.snoozeAction:
            await scheduler.cancel(taskId: taskId)                  // dừng chùm hiện tại
            let name = response.notification.request.content.body
                .replacingOccurrences(of: "Task: ", with: "")
            let planned = AlarmPlanner().plan(taskId: taskId, taskName: name,
                start: Date().addingTimeInterval(10 * 60), now: Date())   // arm lại từ +10'
            await scheduler.arm(planned)
        default:
            // Done, hoặc user tap mở app từ notification → dừng chuỗi của task này.
            await scheduler.cancel(taskId: taskId)
        }
    }

    private static func taskId(from identifier: String) -> UUID? {
        // "alarm-<uuid>-<index>" → uuid.
        let parts = identifier.split(separator: "-")
        // uuid gồm 5 nhóm ngăn bởi '-'; identifier = alarm + 5 nhóm + index = 7 phần.
        guard parts.count == 7, parts.first == "alarm" else { return nil }
        let uuidStr = parts[1...5].joined(separator: "-")
        return UUID(uuidString: uuidStr)
    }
```

- [ ] **Step 2: Build**

Run: `xcodegen generate && xcodebuild -project FocusPlan.xcodeproj -scheme FocusPlan -destination 'generic/platform=iOS Simulator' build`
Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 3: Commit**

```bash
git add FocusPlan/Sources/Support/AlarmNotificationDelegate.swift
git commit -m "feat(ios): handle Done/Snooze actions to stop or reschedule alarm chain"
```

---

### Task 5: TodayScheduleService — engine → arm; re-arm khi app active

**Files:**
- Create: `FocusPlan/Sources/Services/TodayScheduleService.swift`
- Modify: `FocusPlan/Sources/FocusPlanApp.swift`

**Interfaces:**
- Consumes: `TaskRepository.fetchAll()` (issue 002), `HabitRepository.fetchHabits()` (issue 003), `HabitBusyBlockService` (issue 003), `SchedulingEngine` (issue 004), `AlarmPlanner`/`AlarmScheduler` (Task 2/3).
- Produces: `@MainActor final class TodayScheduleService { static let shared: TodayScheduleService; func refreshAndArm() async }`.

- [ ] **Step 1: Viết `TodayScheduleService.swift`**

```swift
import Foundation

@MainActor
final class TodayScheduleService {
    static let shared = TodayScheduleService()
    private let scheduler = AlarmScheduler(center: LiveNotificationScheduling())

    /// Recompute lịch hôm nay (deterministic) rồi arm lại toàn bộ alarm cho task còn tương lai.
    /// Gọi khi app trở active → cũng chính là điểm "mở app dừng chuỗi đang chạy"
    /// (cancel hết alarm-* rồi arm lại theo lịch, mốc đã qua bị bỏ).
    func refreshAndArm(now: Date = Date(), calendar: Calendar = .current) async {
        await scheduler.cancelAllAlarms()
        guard let tasks = try? await TaskRepository().fetchAll(),
              let habits = try? await HabitRepository().fetchHabits() else { return }

        let busy = HabitBusyBlockService().busyBlocks(habits: habits, on: now, calendar: calendar)
        let result = SchedulingEngine().schedule(tasks: tasks, busyBlocks: busy, on: now,
                                                 calendar: calendar, config: .init())
        let byId = Dictionary(tasks.map { ($0.id, $0.name) }, uniquingKeysWith: { a, _ in a })
        let items: [(id: UUID, name: String, start: Date)] = result.scheduled.compactMap { blk in
            guard let name = byId[blk.taskId] else { return nil }
            return (blk.taskId, name, blk.start)
        }
        let planned = AlarmPlanner().planMany(items, now: now)
        await scheduler.arm(planned, calendar: calendar)
    }
}
```

- [ ] **Step 2: Wire scenePhase trong `FocusPlanApp.swift`** — thêm `@Environment(\.scenePhase)` + gọi re-arm khi `.active`:

```swift
import SwiftUI
import UserNotifications

@main
struct FocusPlanApp: App {
    @UIApplicationDelegateAdaptor(AlarmAppDelegate.self) private var appDelegate
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .task { await requestNotificationPermission() }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                Task { await TodayScheduleService.shared.refreshAndArm() }
            }
        }
    }

    private func requestNotificationPermission() async {
        _ = try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge])
    }
}
```

- [ ] **Step 3: Build**

Run: `xcodegen generate && xcodebuild -project FocusPlan.xcodeproj -scheme FocusPlan -destination 'generic/platform=iOS Simulator' build`
Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 4: Commit**

```bash
git add FocusPlan/Sources/Services/TodayScheduleService.swift FocusPlan/Sources/FocusPlanApp.swift
git commit -m "feat(ios): compute today schedule and arm alarms on app active"
```

---

### Task 6: Full-suite verify + manual device QA checklist

**Files:** (không tạo file app)

- [ ] **Step 1: Chạy full suite**

Run (trong `FocusPlan/`):
```bash
xcodegen generate
xcodebuild -project FocusPlan.xcodeproj -scheme FocusPlan \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
```
Expected: `** TEST SUCCEEDED **` — unit cũ (model/engine) + `AlarmPlannerTests` (4) + `AlarmSchedulerTests` (3) + UITest cũ (Auth/Habit/Task) đều pass, không hồi quy.

- [ ] **Step 2: Smoke simulator (thủ công, không bắt buộc CI)** — build & run trên simulator, đăng nhập, xác nhận: app xin quyền notification; tạo 1 task có giờ bắt đầu gần (engine xếp) → nền/khoá màn hình → notification đầu bắn (trên simulator local notification vẫn hiện). Ghi nhận: escalation/lặp/nền có giới hạn trên simulator.

- [ ] **Step 3: Ghi checklist QA device thật vào báo cáo** (criteria 4 — leader chuyển user). KHÔNG tự tick criteria 4:
  1. Trên iPhone thật: đến giờ task → notification đầu bắn.
  2. Không tương tác → lặp mỗi 2', trong ~10', title khẩn dần.
  3. Mở app / Done / Snooze → chuỗi dừng (Snooze arm lại +10').
  4. Khoá màn hình / app nền → vẫn nhận (best-effort).

- [ ] **Step 4: Commit** (nếu có chỉnh gì ở Step 1)

```bash
git add -A
git commit -m "test(ios): keep suite green with alarm module"
```

---

## Self-Review (đã chạy)

- **Spec coverage (4 acceptance criteria):**
  - Criteria 1 (đến giờ task, notification đầu bắn): `AlarmPlanner.plan` sinh mốc index 0 = start (Task 2 test `test_plan_creates_burst...`) + `AlarmScheduler.arm` submit (Task 3) + `TodayScheduleService` arm theo lịch engine (Task 5). Delivery thật = device QA (Task 6). ✔ (logic tested)
  - Criteria 2 (lặp 1-2'/lần ~10', tone tăng dần): chùm 6 × 2' = 10' (Task 2), title escalate (`test_plan_titles_escalate`). Sound = system default (v1 user chốt). Delivery/âm thanh thật = device. ✔
  - Criteria 3 (tương tác → dừng): app active re-arm cancel-all (Task 5), Done cancel task (Task 4), Snooze cancel+re-arm (Task 4); `AlarmScheduler.cancel/cancelAllAlarms` tested (Task 3). ✔
  - Criteria 4 (device thật): KHÔNG verify được ở CI/simulator → checklist QA device cho user (Task 6 Step 3), leader ghi rõ giới hạn. ✔ (đã surface, không tự tick)
- **Full scope (user chốt):** wiring engine 004 → app (`TodayScheduleService`, Task 5) tính lịch + arm cho mọi task hôm nay; recompute deterministic, không persist DB. ✔
- **Type consistency:** `PlannedAlarm{identifier,fireDate,title,body}`, `AlarmPlanner.plan/planMany`, `NotificationScheduling`/`LiveNotificationScheduling`/`AlarmScheduler.arm/cancel/cancelAllAlarms`, `AlarmNotification.categoryId/doneAction/snoozeAction`, identifier `alarm-<uuid>-<index>` (parse 7 phần ở Task 4 khớp scheme Task 2), `TodayScheduleService.refreshAndArm`. Dùng `TaskRepository.fetchAll`/`HabitRepository.fetchHabits`/`HabitBusyBlockService.busyBlocks`/`SchedulingEngine.schedule` đúng chữ ký hiện có. ✔
- **Rủi ro đã ghi:**
  - 64-pending limit → `maxPendingBudget=60` cắt ở `planMany` (Task 2, `test_planMany_respects_budget`).
  - iOS background/best-effort → không background mode, chấp nhận độ trễ; delivery device-only.
  - "Done" chỉ dừng chuỗi, không cập nhật DB (bảng tasks chưa có cột done) — ngoài scope.
  - Snooze parse tên task từ body (`"Task: X"`) — nếu đổi format body ở AlarmPlanner phải đồng bộ (ghi chú Task 4).
  - Permission bị từ chối → arm im lặng (try? await), không crash; user QA cần cấp quyền.
  - Simulator KHÔNG thay device thật cho criteria 4 (Task 6 Step 3).
- **Placeholder scan:** không có TODO/TBD; mọi step có code/lệnh cụ thể. ✔
```
