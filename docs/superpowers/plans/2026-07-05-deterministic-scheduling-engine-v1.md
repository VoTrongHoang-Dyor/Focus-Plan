# Deterministic Scheduling Engine v1 Implementation Plan

> **For agentic workers:** Trong team này coder thực thi toàn bộ plan task-by-task rồi bàn giao reviewer — KHÔNG tự dispatch subagent. Steps dùng checkbox (`- [ ]`) để tracking.

**Goal:** Engine rule-based (không LLM) xếp danh sách task đã tạo vào các slot rảnh trong ngày dựa trên loại task (deep/shallow), priority, thời lượng; chèn buffer cố định; và né busy-block habit — thuần, deterministic, test được độc lập UI/network.

**Architecture:** Thêm 1 field phân loại năng lượng `taskType` (deep/shallow) xuyên suốt stack (DB → model → Gemini parse → form) để engine map chính xác "buổi sáng = deep work". Trọng tâm là `SchedulingEngine` — 1 struct thuần với hàm `schedule(tasks:busyBlocks:on:calendar:config:)` nhận value types (TaskItem + BusyBlock đã có từ issue 002/003) và trả `ScheduleResult`. Không đụng UI hiển thị lịch (chưa thuộc scope criteria — engine chỉ cần test được độc lập).

**Tech Stack:** Swift 5.9 / iOS 17, XCTest, XcodeGen + SPM (như issue 001-003). Supabase Postgres (thêm cột), Edge Function Deno/TS (`parse-task`), Gemini `gemini-2.0-flash` JSON mode.

## Global Constraints

- **Nối tiếp app có sẵn** `FocusPlan/`. Convention: SwiftUI, XcodeGen (`project.yml` recursive `sources: - path: Sources`), source mới bỏ vào `FocusPlan/Sources/...` rồi `xcodegen generate`. Tests vào `FocusPlan/Tests/`.
- **KHÔNG dùng LLM trong engine** — thuần rule-based, deterministic (Decision Log: "Gemini chỉ NLP parse, không reasoning/constraint-solving").
- **Engine phải thuần & test độc lập** (criteria 5): input `[TaskItem]` + `[BusyBlock]` + date → output schedule; KHÔNG gọi network/Supabase/UI.
- **Tham số v1 (user chốt 2026-07-05):** khung ngày làm việc **08:00–22:00**, buffer cố định **10 phút** giữa các block. Energy-matching suy từ **field loại task deep/shallow** (user chọn thêm field, không suy ngầm từ priority).
- **Naming:** KHÔNG đặt type Swift tên `Task` (đụng `_Concurrency.Task`). Đã dùng `TaskItem`.
- **Type loại task:** `enum TaskType: String { case deep, shallow }`, cột DB `task_type`, default `shallow`.
- **Bảng `public.tasks`** đã tồn tại trên remote (issue 002, tạo tay). Thêm cột phải idempotent (`add column if not exists`), áp lên remote trước khi phần app đọc/ghi cột đó.

## File Structure

```
supabase/
├── migrations/
│   └── 20260704044752_create_tasks.sql        # (modify) thêm cột task_type idempotent
└── functions/parse-task/index.ts              # (modify) thêm task_type vào schema + prompt

FocusPlan/
├── Sources/
│   ├── Models/
│   │   ├── TaskType.swift                      # (create) enum deep/shallow + label + energy order
│   │   ├── TaskItem.swift                      # (modify) thêm taskType vào TaskItem/NewTask/TaskUpdate
│   │   ├── ParsedTaskDraft.swift               # (modify) thêm taskType (từ Gemini)
│   │   ├── ScheduledBlock.swift                # (create) output slot: taskId/start/end
│   │   └── ScheduleResult.swift                # (create) { scheduled:[ScheduledBlock], unscheduled:[UUID] }
│   ├── Services/
│   │   └── SchedulingEngine.swift              # (create) hàm thuần schedule(...)
│   └── Views/
│       └── TaskFormView.swift                  # (modify) thêm Picker chọn loại task
└── Tests/
    ├── TaskModelTests.swift                    # (modify) thêm assert decode taskType
    └── SchedulingEngineTests.swift             # (create) unit test engine (criteria 1-5)
```

**Quyết định phân rã:** Engine (Task 2) là deliverable cốt lõi và test được ngay khi model có `taskType` (Task 1) — không phụ thuộc DB/Gemini. Tasks 3-5 lan field ra để user set được (làm field "thật", tránh dead code). Tách theo trách nhiệm: model → engine → DB → Gemini → form.

---

### Task 1: TaskType enum + gắn taskType vào models

**Files:**
- Create: `FocusPlan/Sources/Models/TaskType.swift`
- Modify: `FocusPlan/Sources/Models/TaskItem.swift`
- Modify: `FocusPlan/Sources/Models/ParsedTaskDraft.swift`
- Modify: `FocusPlan/Tests/TaskModelTests.swift`

**Interfaces:**
- Produces:
  - `enum TaskType: String, Codable, CaseIterable, Identifiable { case deep, shallow; var id; var label: String; var energyOrder: Int }`
  - `TaskItem` thêm `var taskType: TaskType` (CodingKey `task_type`).
  - `NewTask`/`TaskUpdate` thêm `var taskType: TaskType` (CodingKey `task_type`).
  - `ParsedTaskDraft` thêm `var taskType: TaskType` (CodingKey `task_type`).

- [ ] **Step 1: Viết `TaskType.swift`**

```swift
import Foundation

enum TaskType: String, Codable, CaseIterable, Identifiable {
    case deep, shallow
    var id: String { rawValue }
    var label: String {
        switch self {
        case .deep: return "Deep work"
        case .shallow: return "Việc nhẹ"
        }
    }
    /// Thứ tự năng lượng cho sort của engine: deep xếp trước (buổi sáng).
    var energyOrder: Int {
        switch self {
        case .deep: return 0
        case .shallow: return 1
        }
    }
}
```

- [ ] **Step 2: Sửa `TaskItem.swift`** — thêm `taskType` vào 3 struct + CodingKeys. Vì DB có default `'shallow'` nhưng để decode an toàn khi cột chưa có (bản ghi cũ) dùng `decodeIfPresent` với default `.shallow` trong `TaskItem`.

Trong `TaskItem`, đổi thành custom decode cho field mới (giữ các field cũ như đang có):
```swift
struct TaskItem: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var estimatedMinutes: Int?
    var priority: TaskPriority
    var deadline: Date?
    var taskType: TaskType
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, name
        case estimatedMinutes = "estimated_minutes"
        case priority, deadline
        case taskType = "task_type"
        case createdAt = "created_at"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        estimatedMinutes = try c.decodeIfPresent(Int.self, forKey: .estimatedMinutes)
        priority = try c.decode(TaskPriority.self, forKey: .priority)
        deadline = try c.decodeIfPresent(Date.self, forKey: .deadline)
        taskType = try c.decodeIfPresent(TaskType.self, forKey: .taskType) ?? .shallow
        createdAt = try c.decode(Date.self, forKey: .createdAt)
    }

    // Init thường cho test/khởi tạo tay.
    init(id: UUID, name: String, estimatedMinutes: Int?, priority: TaskPriority,
         deadline: Date?, taskType: TaskType, createdAt: Date) {
        self.id = id; self.name = name; self.estimatedMinutes = estimatedMinutes
        self.priority = priority; self.deadline = deadline
        self.taskType = taskType; self.createdAt = createdAt
    }
}
```

Thêm `taskType` vào `NewTask` và `TaskUpdate` (encode bình thường):
```swift
struct NewTask: Encodable {
    var name: String
    var estimatedMinutes: Int?
    var priority: TaskPriority
    var deadline: Date?
    var taskType: TaskType
    enum CodingKeys: String, CodingKey {
        case name
        case estimatedMinutes = "estimated_minutes"
        case priority, deadline
        case taskType = "task_type"
    }
}

struct TaskUpdate: Encodable {
    var name: String
    var estimatedMinutes: Int?
    var priority: TaskPriority
    var deadline: Date?
    var taskType: TaskType
    enum CodingKeys: String, CodingKey {
        case name
        case estimatedMinutes = "estimated_minutes"
        case priority, deadline
        case taskType = "task_type"
    }
}
```

- [ ] **Step 3: Sửa `ParsedTaskDraft.swift`** — thêm `taskType` với default `.shallow` khi Gemini không trả.

Thêm property + CodingKey, và vì `ParsedTaskDraft` đang dùng synthesized decode, chuyển sang decodeIfPresent bằng cách thêm custom init HOẶC cho property default. Đơn giản nhất: thêm custom `init(from:)`:
```swift
struct ParsedTaskDraft: Codable {
    var name: String
    var estimatedMinutes: Int?
    var priority: TaskPriority
    var deadlineRaw: String?
    var needsConfirmation: Bool
    var note: String?
    var taskType: TaskType

    enum CodingKeys: String, CodingKey {
        case name
        case estimatedMinutes = "estimated_minutes"
        case priority
        case deadlineRaw = "deadline"
        case needsConfirmation = "needs_confirmation"
        case note
        case taskType = "task_type"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = try c.decode(String.self, forKey: .name)
        estimatedMinutes = try c.decodeIfPresent(Int.self, forKey: .estimatedMinutes)
        priority = try c.decode(TaskPriority.self, forKey: .priority)
        deadlineRaw = try c.decodeIfPresent(String.self, forKey: .deadlineRaw)
        needsConfirmation = try c.decode(Bool.self, forKey: .needsConfirmation)
        note = try c.decodeIfPresent(String.self, forKey: .note)
        taskType = try c.decodeIfPresent(TaskType.self, forKey: .taskType) ?? .shallow
    }
}
```
Giữ nguyên phần `deadlineDate` computed + `extension ParsedTaskDraft: Identifiable`.

- [ ] **Step 4: Thêm test decode vào `TaskModelTests.swift`** — cập nhật 2 test hiện có (JSON thêm/không có `task_type`) + 1 test mới. Sửa `test_parsedDraft_decodes_from_gemini_json` để JSON có `"task_type":"deep"` và assert; giữ `test_parsedDraft_handles_null_deadline_and_minutes` (không có task_type → default shallow) thêm assert.

Thêm test mới:
```swift
func test_parsedDraft_defaults_taskType_shallow_when_absent() throws {
    let jsonStr = """
    {"name":"Đọc mail","estimated_minutes":15,"priority":"low",
     "deadline":null,"needs_confirmation":false,"note":null}
    """
    let draft = try JSONDecoder().decode(ParsedTaskDraft.self, from: Data(jsonStr.utf8))
    XCTAssertEqual(draft.taskType, .shallow)
}

func test_taskItem_decodes_taskType_and_defaults_when_absent() throws {
    let withType = """
    {"id":"11111111-1111-1111-1111-111111111111","name":"Viết báo cáo",
     "estimated_minutes":90,"priority":"high","deadline":null,
     "task_type":"deep","created_at":"2026-07-05T01:00:00Z"}
    """
    let d = JSONDecoder()
    let t1 = try d.decode(TaskItem.self, from: Data(withType.utf8))
    XCTAssertEqual(t1.taskType, .deep)

    let noType = """
    {"id":"22222222-2222-2222-2222-222222222222","name":"Cũ",
     "estimated_minutes":null,"priority":"medium","deadline":null,
     "created_at":"2026-07-05T01:00:00Z"}
    """
    let t2 = try d.decode(TaskItem.self, from: Data(noType.utf8))
    XCTAssertEqual(t2.taskType, .shallow)
}
```
Trong `test_parsedDraft_decodes_from_gemini_json` thêm `"task_type":"deep"` vào JSON và `XCTAssertEqual(draft.taskType, .deep)`.

- [ ] **Step 5: Chạy unit test**

Run (trong `FocusPlan/`):
```bash
xcodegen generate
xcodebuild -project FocusPlan.xcodeproj -scheme FocusPlan \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:FocusPlanTests test
```
Expected: `** TEST SUCCEEDED **` (các test model cũ + mới pass). Nếu tên simulator khác → `xcrun simctl list devices` chọn tên có sẵn.

- [ ] **Step 6: Commit**

```bash
git add FocusPlan/Sources/Models/TaskType.swift FocusPlan/Sources/Models/TaskItem.swift \
  FocusPlan/Sources/Models/ParsedTaskDraft.swift FocusPlan/Tests/TaskModelTests.swift
git commit -m "feat(ios): add TaskType (deep/shallow) to task models"
```

---

### Task 2: SchedulingEngine (hàm thuần) + unit tests — TRỌNG TÂM

**Files:**
- Create: `FocusPlan/Sources/Models/ScheduledBlock.swift`
- Create: `FocusPlan/Sources/Models/ScheduleResult.swift`
- Create: `FocusPlan/Sources/Services/SchedulingEngine.swift`
- Create: `FocusPlan/Tests/SchedulingEngineTests.swift`

**Interfaces:**
- Consumes: `TaskItem` (đã có `taskType`, Task 1), `BusyBlock` (`{ habitId: UUID, start: Date, end: Date }`, issue 003).
- Produces:
  - `struct ScheduledBlock: Equatable { let taskId: UUID; let start: Date; let end: Date }`
  - `struct ScheduleResult: Equatable { let scheduled: [ScheduledBlock]; let unscheduled: [UUID] }`
  - `struct SchedulingEngine { struct Config { var dayStartHour: Int = 8; var dayEndHour: Int = 22; var bufferMinutes: Int = 10; var defaultDurationMinutes: Int = 30 }; func schedule(tasks: [TaskItem], busyBlocks: [BusyBlock], on date: Date, calendar: Calendar, config: Config) -> ScheduleResult }`

**Thuật toán (deterministic, greedy earliest-fit):**
1. Tính `dayStart` = `date` set giờ `config.dayStartHour:00`, `dayEnd` = `config.dayEndHour:00`.
2. Sort task: (a) `taskType.energyOrder` tăng (deep=0 trước shallow=1) → deep rơi vào sáng; (b) `priority` cao→thấp (thêm `sortRank` cho TaskPriority: high=0, medium=1, low=2); (c) thời lượng giảm dần (dài trước); (d) `createdAt` tăng; (e) `id.uuidString` tăng (chốt total order để deterministic tuyệt đối).
3. Busy-block: lọc các block giao với [dayStart, dayEnd], sort theo `start`.
4. Con trỏ `cursor = dayStart`. Với mỗi task theo thứ tự: duration = `estimatedMinutes ?? defaultDurationMinutes` (phút). Tìm `start` sớm nhất ≥ cursor sao cho `[start, start+duration]` nằm trong [dayStart, dayEnd] và KHÔNG giao busy-block nào: nếu `[cursor, cursor+duration]` đụng busy-block, nhảy `cursor` = `end` của busy-block đang chắn rồi thử lại; nếu vượt `dayEnd` → task vào `unscheduled`. Đặt được → thêm `ScheduledBlock`, `cursor = placedEnd + bufferMinutes`.
5. Trả `ScheduleResult(scheduled, unscheduled)`.

- [ ] **Step 1: Viết `ScheduledBlock.swift` + `ScheduleResult.swift`**

```swift
// ScheduledBlock.swift
import Foundation

struct ScheduledBlock: Equatable {
    let taskId: UUID
    let start: Date
    let end: Date
}
```
```swift
// ScheduleResult.swift
import Foundation

struct ScheduleResult: Equatable {
    let scheduled: [ScheduledBlock]
    let unscheduled: [UUID]   // task không đủ chỗ trong ngày
}
```

- [ ] **Step 2: Viết failing test `SchedulingEngineTests.swift`** (5 test phủ 5 criteria)

```swift
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
```

- [ ] **Step 3: Chạy test để xác nhận FAIL**

Run: `xcodegen generate && xcodebuild -project FocusPlan.xcodeproj -scheme FocusPlan -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:FocusPlanTests/SchedulingEngineTests test`
Expected: FAIL — `SchedulingEngine`/`ScheduleResult` chưa tồn tại (compile error) hoặc test đỏ.

- [ ] **Step 4: Viết `SchedulingEngine.swift`**

```swift
import Foundation

struct SchedulingEngine {
    struct Config {
        var dayStartHour: Int = 8
        var dayEndHour: Int = 22
        var bufferMinutes: Int = 10
        var defaultDurationMinutes: Int = 30
    }

    func schedule(tasks: [TaskItem], busyBlocks: [BusyBlock], on date: Date,
                  calendar: Calendar = .current, config: Config = Config()) -> ScheduleResult {
        guard let dayStart = calendar.date(bySettingHour: config.dayStartHour, minute: 0, second: 0, of: date),
              let dayEnd = calendar.date(bySettingHour: config.dayEndHour, minute: 0, second: 0, of: date)
        else { return ScheduleResult(scheduled: [], unscheduled: tasks.map(\.id)) }

        // Busy-block giao trong ngày, sort theo start.
        let busy = busyBlocks
            .filter { $0.end > dayStart && $0.start < dayEnd }
            .sorted { $0.start < $1.start }

        let ordered = tasks.sorted { a, b in
            if a.taskType.energyOrder != b.taskType.energyOrder {
                return a.taskType.energyOrder < b.taskType.energyOrder
            }
            if a.priority.sortRank != b.priority.sortRank {
                return a.priority.sortRank < b.priority.sortRank
            }
            let da = a.estimatedMinutes ?? config.defaultDurationMinutes
            let db = b.estimatedMinutes ?? config.defaultDurationMinutes
            if da != db { return da > db }                 // dài trước
            if a.createdAt != b.createdAt { return a.createdAt < b.createdAt }
            return a.id.uuidString < b.id.uuidString        // chốt total order
        }

        var scheduled: [ScheduledBlock] = []
        var unscheduled: [UUID] = []
        let buffer = TimeInterval(config.bufferMinutes * 60)
        var cursor = dayStart

        for task in ordered {
            let duration = TimeInterval((task.estimatedMinutes ?? config.defaultDurationMinutes) * 60)
            if let placedStart = earliestFit(from: cursor, duration: duration,
                                             dayEnd: dayEnd, busy: busy) {
                let placedEnd = placedStart.addingTimeInterval(duration)
                scheduled.append(ScheduledBlock(taskId: task.id, start: placedStart, end: placedEnd))
                cursor = placedEnd.addingTimeInterval(buffer)
            } else {
                unscheduled.append(task.id)
            }
        }
        return ScheduleResult(scheduled: scheduled, unscheduled: unscheduled)
    }

    /// Tìm start sớm nhất >= from để [start, start+duration] không giao busy & <= dayEnd.
    private func earliestFit(from: Date, duration: TimeInterval, dayEnd: Date,
                             busy: [BusyBlock]) -> Date? {
        var start = from
        while start.addingTimeInterval(duration) <= dayEnd {
            if let hit = busy.first(where: { $0.start < start.addingTimeInterval(duration) && $0.end > start }) {
                start = hit.end                              // nhảy qua busy-block đang chắn
            } else {
                return start
            }
        }
        return nil
    }
}
```

- [ ] **Step 5: Thêm `sortRank` cho `TaskPriority`** — sửa `FocusPlan/Sources/Models/TaskPriority.swift`, thêm computed property (giữ nguyên phần còn lại):

```swift
    /// Rank cho sort của SchedulingEngine: cao (high) xếp trước.
    var sortRank: Int {
        switch self {
        case .high: return 0
        case .medium: return 1
        case .low: return 2
        }
    }
```

- [ ] **Step 6: Chạy test để xác nhận PASS**

Run: `xcodegen generate && xcodebuild -project FocusPlan.xcodeproj -scheme FocusPlan -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:FocusPlanTests test`
Expected: `** TEST SUCCEEDED **` — 5 test engine + test model đều pass.

- [ ] **Step 7: Commit**

```bash
git add FocusPlan/Sources/Models/ScheduledBlock.swift FocusPlan/Sources/Models/ScheduleResult.swift \
  FocusPlan/Sources/Services/SchedulingEngine.swift FocusPlan/Sources/Models/TaskPriority.swift \
  FocusPlan/Tests/SchedulingEngineTests.swift
git commit -m "feat(ios): deterministic scheduling engine v1 (energy/priority/buffer/busy-block)"
```

---

> **GATE (DB):** Task 3 áp cột lên remote `public.tasks`. Coder áp bằng CLI (đã linked project `njwmpikyqghniqqiweao`). Nếu không có quyền chạy SQL trên remote → báo leader trước khi tiếp Task 4-5 (phần app đọc/ghi cột).

### Task 3: Thêm cột `task_type` vào bảng tasks

**Files:**
- Modify: `supabase/migrations/20260704044752_create_tasks.sql`

**Interfaces:**
- Produces: cột `public.tasks.task_type text not null default 'shallow' check (task_type in ('deep','shallow'))`.

- [ ] **Step 1: Thêm cột idempotent vào file migration** — nối cuối file `20260704044752_create_tasks.sql`:

```sql
-- issue 004: phân loại năng lượng cho Scheduling Engine (deep/shallow).
alter table public.tasks
  add column if not exists task_type text not null default 'shallow'
  check (task_type in ('deep', 'shallow'));
```

- [ ] **Step 2: Áp cột lên remote** (bảng tạo tay nên KHÔNG `db push`; áp thẳng ALTER idempotent):

```bash
# Cách A (nếu có DB URL): dùng connection string project để chạy ALTER.
# Cách B: chạy qua Supabase SQL editor thủ công (leader/user) — nhưng ưu tiên CLI.
supabase db execute --project-ref njwmpikyqghniqqiweao \
  "alter table public.tasks add column if not exists task_type text not null default 'shallow' check (task_type in ('deep','shallow'));"
```
Nếu `supabase db execute` không có ở version CLI hiện tại → dùng `psql "$SUPABASE_DB_URL" -c "<ALTER>"` với DB URL của project, hoặc báo leader để user chạy trong SQL editor. Verify: query `select task_type from public.tasks limit 1;` không lỗi cột thiếu.

- [ ] **Step 3: Commit**

```bash
git add supabase/migrations/20260704044752_create_tasks.sql
git commit -m "feat(backend): add task_type column to tasks (deep/shallow)"
```

---

### Task 4: Gemini parse-task suy `task_type`

**Files:**
- Modify: `supabase/functions/parse-task/index.ts`

**Interfaces:**
- Produces: JSON draft có thêm `task_type: "deep" | "shallow"`.

- [ ] **Step 1: Thêm `task_type` vào `responseSchema`** — trong object `properties` (giữ nguyên các field cũ), thêm:

```ts
    task_type: { type: "STRING", enum: ["deep", "shallow"] },
```
Và thêm `"task_type"` vào mảng `required`.

- [ ] **Step 2: Bổ sung hướng dẫn vào prompt** — thêm 1 dòng vào phần mô tả schema (trước dòng `Câu người dùng:`):

```
- task_type: "deep" nếu là việc cần tập trung cao/sáng tạo/khó (vd học, viết, code, thiết kế); "shallow" nếu việc nhẹ/hành chính/lặp (vd trả lời tin nhắn, dọn dẹp, mua sắm). Không rõ dùng "shallow".
```

- [ ] **Step 3: Redeploy + smoke test**

```bash
supabase functions deploy parse-task --project-ref njwmpikyqghniqqiweao
```
Nếu Gemini còn hết quota (429 `limit:0`) → KHÔNG chặn task này (chỉ cần deploy thành công; smoke live để lại khi có billing). Verify deploy trả `Deployed Functions`.

- [ ] **Step 4: Commit**

```bash
git add supabase/functions/parse-task/index.ts
git commit -m "feat(backend): parse-task infers task_type (deep/shallow)"
```

---

### Task 5: TaskFormView — Picker chọn loại task

**Files:**
- Modify: `FocusPlan/Sources/Views/TaskFormView.swift`

**Interfaces:**
- Consumes: `TaskType` (Task 1), `NewTask`/`TaskUpdate` (đã có `taskType`).

- [ ] **Step 1: Thêm state + prefill + section Picker + truyền vào save**

- Thêm state: `@State private var taskType: TaskType = .shallow`
- Trong `prefill()`: nhánh `.create(let d)` thêm `taskType = d.taskType`; nhánh `.edit(let t)` thêm `taskType = t.taskType`.
- Thêm Section vào Form (sau Section "Độ ưu tiên"):
```swift
                Section("Loại việc") {
                    Picker("Loại việc", selection: $taskType) {
                        ForEach(TaskType.allCases) { t in Text(t.label).tag(t) }
                    }.pickerStyle(.segmented)
                }
```
- Trong `save()`, truyền `taskType` vào cả 2 nhánh:
```swift
            case .create:
                _ = try await repo.create(NewTask(name: trimmedName, estimatedMinutes: minutes,
                    priority: priority, deadline: dl, taskType: taskType))
            case .edit(let t):
                _ = try await repo.update(id: t.id, TaskUpdate(name: trimmedName, estimatedMinutes: minutes,
                    priority: priority, deadline: dl, taskType: taskType))
```

- [ ] **Step 2: Build**

Run: `xcodegen generate && xcodebuild -project FocusPlan.xcodeproj -scheme FocusPlan -destination 'generic/platform=iOS Simulator' build`
Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 3: Commit**

```bash
git add FocusPlan/Sources/Views/TaskFormView.swift
git commit -m "feat(ios): task type picker in task form"
```

---

### Task 6: Full-suite verify + regression

**Files:** (không tạo file; có thể cập nhật UITest seed nếu cần cột mới)

- [ ] **Step 1: Chạy full suite**

Run (trong `FocusPlan/`):
```bash
xcodegen generate
xcodebuild -project FocusPlan.xcodeproj -scheme FocusPlan \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
```
Expected: `** TEST SUCCEEDED **` — toàn bộ unit (model + engine) + UITest cũ (Auth/Habit/Task) đều pass.

- [ ] **Step 2: Xử lý nếu UITest task cũ gãy do cột mới** — `TaskFlowUITests` seed task qua REST không gồm `task_type`; vì cột có default `'shallow'`, insert cũ vẫn hợp lệ, decode default shallow → không gãy. Nếu có lỗi decode/insert liên quan `task_type` → sửa TỐI THIỂU seed payload (thêm `"task_type":"shallow"`), báo rõ.

- [ ] **Step 3: Commit** (nếu có chỉnh test)

```bash
git add -A
git commit -m "test(ios): keep task UITests green after task_type column"
```

---

## Self-Review (đã chạy)

- **Spec coverage (5 acceptance criteria):**
  - Criteria 1 (task list → slot cụ thể): Task 2 engine + `test_schedules_tasks_into_concrete_slots`. ✔
  - Criteria 2 (energy-matching nhất quán, deterministic): Task 2 sort deep-first + total order + `test_deep_before_shallow_and_deterministic` (so sánh 2 lần chạy bằng nhau). ✔
  - Criteria 3 (buffer cố định): Task 2 `bufferMinutes=10` + `test_inserts_fixed_buffer_between_blocks`. ✔
  - Criteria 4 (né busy-block habit): Task 2 `earliestFit` skip busy + `test_avoids_busy_blocks` (dùng `BusyBlock` thật của issue 003). ✔
  - Criteria 5 (test độc lập UI/network): Task 2 hàm thuần, test XCTest không network/UI. ✔
  - Bonus: overflow → unscheduled (`test_overflow_goes_to_unscheduled`).
- **Field loại task (user chốt):** TaskType xuyên DB (Task 3) → model (Task 1) → Gemini (Task 4) → form (Task 5), field "thật" set được, không dead code. ✔
- **Type consistency:** `TaskType.energyOrder`, `TaskPriority.sortRank`, `TaskItem.taskType`, `NewTask/TaskUpdate.taskType`, `ScheduledBlock{taskId,start,end}`, `ScheduleResult{scheduled,unscheduled}`, `SchedulingEngine.Config`, `BusyBlock{start,end}` — khớp giữa các task. Engine đọc `estimatedMinutes ?? defaultDurationMinutes`. ✔
- **Rủi ro đã ghi:**
  - Decode `task_type` khi cột/JSON thiếu → `decodeIfPresent ?? .shallow` (Task 1) tránh vỡ bản ghi cũ + UITest seed cũ (Task 6 Step 2).
  - Áp cột lên remote (bảng tạo tay) → ALTER idempotent, gate trước Task 4-5 (Task 3 GATE).
  - Gemini quota `limit:0` → Task 4 chỉ cần deploy, smoke live để khi có billing (đồng nhất với trạng thái issue 002).
  - Buffer định nghĩa = khoảng cách giữa 2 task scheduled (cursor += buffer sau mỗi block); không áp buffer với busy-block (chỉ cấm overlap) — v1 đơn giản, đúng criteria.
- **Giả định (không hỏi lại, đã default hợp lý):**
  - Deadline KHÔNG dùng để sort trong v1 (chỉ taskType→priority→duration); deadline giữ là metadata. (Criteria không nhắc deadline trong scheduling.)
  - Task thiếu `estimatedMinutes` → mặc định 30'.
  - Overflow → trả `unscheduled` (không tự dời sang hôm sau — thuộc issue 014 buffer động sau này).
  - Engine chưa wire vào UI hiển thị "Today" — criteria chỉ cần engine test được độc lập; wiring lịch là slice sau.
- **Placeholder scan:** không có TODO/TBD; mọi step có code/lệnh cụ thể. ✔
```
