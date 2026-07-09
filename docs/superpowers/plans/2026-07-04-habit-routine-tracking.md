# Habit/Routine Tracking Implementation Plan

> **For agentic workers:** Implement task-by-task. Steps dùng checkbox (`- [ ]`). Trong team này coder thực thi toàn bộ plan rồi bàn giao reviewer — KHÔNG tự dispatch subagent.

**Goal:** Module Habit/Routine Tracking trong app `FocusPlan/`: user tạo/sửa/xoá habit (tên + giờ cố định + thời lượng, lặp hàng ngày), đánh dấu hoàn thành/bỏ lỡ theo ngày qua checklist, và xuất được danh sách khung giờ habit dưới dạng busy-block cho Scheduling Engine (issue 004) đọc. Habit độc lập với thuật toán xếp lịch — giờ cố định do user đặt, không bị di chuyển tự động.

**Architecture:** Nối tiếp `FocusPlan/` (issue 001/002). 2 bảng Supabase mới `habits` + `habit_logs` (RLS `auth.uid() = user_id`), mirror pattern bảng `tasks`. Client: models + `HabitRepository` (CRUD + upsert log theo ngày) + **`HabitBusyBlockService`** (hàm THUẦN: `[Habit]` + ngày → `[BusyBlock]`, là điểm tích hợp Scheduling Engine, được TDD unit test). UI: `TabView` 2 tab "Hôm nay" (HomeView cũ) / "Thói quen" (HabitsView mới).

**Tech Stack:** Swift/SwiftUI (iOS 17), supabase-swift 2.48.0 (PostgREST `from()` + `upsert`), Supabase Postgres + RLS.

## Global Constraints

- **Nối tiếp app** `FocusPlan/`. Giữ convention issue 001/002: SwiftUI, XcodeGen (`Sources/` include đệ quy → thêm file vào thư mục con là đủ, chỉ cần `xcodegen generate`), SPM, secret qua Info.plist.
- **Schema + RLS PHẢI vào repo** dưới `supabase/migrations/` (bài học issue 002 review — không để schema chỉ ở dashboard).
- **Multi-user isolation** dựa hoàn toàn RLS server-side; client KHÔNG set `user_id` (DB default `auth.uid()`).
- **Habit KHÔNG bị xếp lịch tự động** (criteria 3): habit chỉ lưu `time_of_day` cố định do user đặt; không có code nào tự đổi giờ habit. Đảm bảo bằng thiết kế (không có mutation giờ ngoài user edit).
- **Busy-block contract** (criteria 4): `struct BusyBlock { habitId: UUID; start: Date; end: Date }`; `HabitBusyBlockService.busyBlocks(habits:on:calendar:) -> [BusyBlock]`. Đây là interface Scheduling Engine (issue 004) sẽ đọc — không cần issue 004 tồn tại, chỉ cần output type + logic đúng, có test.
- **Naming:** không đặt type Swift tên `Task`.
- **Bảng Supabase** user tự chạy SQL (xem Tiền đề) — coder thêm migration file khớp.

## Tiền đề (gate cho Task 4+)

User đã chạy SQL tạo `habits` + `habit_logs` + RLS trên Supabase (leader xác nhận trước khi coder làm Task 4+). Task 1–3 (migration file + models + busy-block service) KHÔNG phụ thuộc bảng remote — làm ngay.

## File Structure

```
supabase/migrations/<ts>_create_habits.sql   # DDL habits + habit_logs + RLS (source of truth)

FocusPlan/Sources/
├── Models/
│   ├── Habit.swift            # row habits (+ NewHabit/HabitUpdate payload, timeComponents)
│   ├── HabitLog.swift         # row habit_logs + HabitStatus enum (+ NewHabitLog payload)
│   └── BusyBlock.swift        # struct BusyBlock
├── Services/
│   ├── HabitBusyBlockService.swift   # hàm thuần habits → busy-blocks
│   └── HabitRepository.swift          # CRUD habits + upsert/fetch logs
├── ViewModels/
│   └── HabitListViewModel.swift
└── Views/
    ├── MainTabView.swift      # TabView Hôm nay / Thói quen
    ├── HabitsView.swift       # checklist hôm nay + add/edit/delete
    ├── HabitFormView.swift    # form tạo/sửa habit (tên + giờ + thời lượng)
    └── RootView.swift         # (modify) signedIn → MainTabView

FocusPlan/Tests/
├── HabitBusyBlockServiceTests.swift   # TDD core — deterministic
└── HabitModelTests.swift              # decode + timeComponents
```

---

### Task 1: Migration file habits + habit_logs (source of truth trong repo)

**Files:**
- Create: `supabase/migrations/<YYYYMMDDHHMMSS>_create_habits.sql`

**Interfaces:**
- Produces: DDL nguồn sự thật cho 2 bảng + RLS (khớp bảng user chạy tay).

- [ ] **Step 1: Tạo file migration** (đặt timestamp thực tế bằng `date +%Y%m%d%H%M%S`; nội dung idempotent, KHÔNG `db push` lên remote đã tồn tại)

```sql
-- Source of truth cho bảng habits + habit_logs (issue 003).
-- Bảng đã được tạo tay trên remote qua SQL Editor; file này để version-control
-- + provision môi trường sạch. KHÔNG chạy `supabase db push` lên remote đang chạy (sẽ conflict).

create table if not exists public.habits (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade default auth.uid(),
  name text not null,
  time_of_day time not null,
  duration_minutes int not null default 30,
  created_at timestamptz not null default now()
);
alter table public.habits enable row level security;
drop policy if exists "habits_select_own" on public.habits;
drop policy if exists "habits_insert_own" on public.habits;
drop policy if exists "habits_update_own" on public.habits;
drop policy if exists "habits_delete_own" on public.habits;
create policy "habits_select_own" on public.habits for select using (auth.uid() = user_id);
create policy "habits_insert_own" on public.habits for insert with check (auth.uid() = user_id);
create policy "habits_update_own" on public.habits for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "habits_delete_own" on public.habits for delete using (auth.uid() = user_id);

create table if not exists public.habit_logs (
  id uuid primary key default gen_random_uuid(),
  habit_id uuid not null references public.habits(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade default auth.uid(),
  log_date date not null,
  status text not null check (status in ('done','missed')),
  created_at timestamptz not null default now(),
  unique (habit_id, log_date)
);
alter table public.habit_logs enable row level security;
drop policy if exists "habit_logs_select_own" on public.habit_logs;
drop policy if exists "habit_logs_insert_own" on public.habit_logs;
drop policy if exists "habit_logs_update_own" on public.habit_logs;
drop policy if exists "habit_logs_delete_own" on public.habit_logs;
create policy "habit_logs_select_own" on public.habit_logs for select using (auth.uid() = user_id);
create policy "habit_logs_insert_own" on public.habit_logs for insert with check (auth.uid() = user_id);
create policy "habit_logs_update_own" on public.habit_logs for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "habit_logs_delete_own" on public.habit_logs for delete using (auth.uid() = user_id);
```

- [ ] **Step 2: Commit**

```bash
git add supabase/migrations/
git commit -m "feat(backend): add habits + habit_logs schema migration with RLS"
```

---

### Task 2: Models Habit / HabitLog / BusyBlock + unit test

**Files:**
- Create: `FocusPlan/Sources/Models/Habit.swift`
- Create: `FocusPlan/Sources/Models/HabitLog.swift`
- Create: `FocusPlan/Sources/Models/BusyBlock.swift`
- Create: `FocusPlan/Tests/HabitModelTests.swift`

**Interfaces:**
- Produces:
  - `struct Habit: Codable, Identifiable, Equatable { let id: UUID; var name; var timeOfDay: String; var durationMinutes: Int; let createdAt: Date; var timeComponents: (hour: Int, minute: Int)? }`
  - `struct NewHabit: Encodable { name; timeOfDay: String; durationMinutes: Int }` (payload insert)
  - `struct HabitUpdate: Encodable { name; timeOfDay: String; durationMinutes: Int }`
  - `enum HabitStatus: String, Codable { case done, missed }`
  - `struct HabitLog: Codable, Identifiable, Equatable { let id: UUID; let habitId: UUID; let logDate: String; var status: HabitStatus }`
  - `struct NewHabitLog: Encodable { habitId: UUID; logDate: String; status: HabitStatus }` (payload upsert)
  - `struct BusyBlock: Equatable { let habitId: UUID; let start: Date; let end: Date }`

- [ ] **Step 1: Viết `Habit.swift`**

```swift
import Foundation

struct Habit: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var timeOfDay: String        // Postgres `time` -> "HH:mm:ss" (vd "06:00:00")
    var durationMinutes: Int
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, name
        case timeOfDay = "time_of_day"
        case durationMinutes = "duration_minutes"
        case createdAt = "created_at"
    }

    /// Tách giờ:phút từ timeOfDay ("06:00:00" -> (6, 0)).
    var timeComponents: (hour: Int, minute: Int)? {
        let parts = timeOfDay.split(separator: ":")
        guard parts.count >= 2, let h = Int(parts[0]), let m = Int(parts[1]) else { return nil }
        return (h, m)
    }
}

/// Payload insert — bỏ id/user_id/created_at (DB default; user_id = auth.uid()).
struct NewHabit: Encodable {
    var name: String
    var timeOfDay: String
    var durationMinutes: Int
    enum CodingKeys: String, CodingKey {
        case name
        case timeOfDay = "time_of_day"
        case durationMinutes = "duration_minutes"
    }
}

struct HabitUpdate: Encodable {
    var name: String
    var timeOfDay: String
    var durationMinutes: Int
    enum CodingKeys: String, CodingKey {
        case name
        case timeOfDay = "time_of_day"
        case durationMinutes = "duration_minutes"
    }
}
```

- [ ] **Step 2: Viết `HabitLog.swift`**

```swift
import Foundation

enum HabitStatus: String, Codable {
    case done, missed
}

struct HabitLog: Codable, Identifiable, Equatable {
    let id: UUID
    let habitId: UUID
    let logDate: String          // Postgres `date` -> "yyyy-MM-dd"
    var status: HabitStatus

    enum CodingKeys: String, CodingKey {
        case id
        case habitId = "habit_id"
        case logDate = "log_date"
        case status
    }
}

/// Payload upsert log theo (habit_id, log_date). user_id = DB default.
struct NewHabitLog: Encodable {
    var habitId: UUID
    var logDate: String
    var status: HabitStatus
    enum CodingKeys: String, CodingKey {
        case habitId = "habit_id"
        case logDate = "log_date"
        case status
    }
}
```

- [ ] **Step 3: Viết `BusyBlock.swift`**

```swift
import Foundation

struct BusyBlock: Equatable {
    let habitId: UUID
    let start: Date
    let end: Date
}
```

- [ ] **Step 4: Viết `HabitModelTests.swift`**

```swift
import XCTest
@testable import FocusPlan

final class HabitModelTests: XCTestCase {
    func test_habit_decodes_snake_case() throws {
        let json = """
        {"id":"11111111-1111-1111-1111-111111111111","name":"Thiền",
         "time_of_day":"06:00:00","duration_minutes":20,
         "created_at":"2026-07-04T00:00:00Z"}
        """
        let h = try JSONDecoder().decode(Habit.self, from: Data(json.utf8))
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
        let log = try JSONDecoder().decode(HabitLog.self, from: Data(json.utf8))
        XCTAssertEqual(log.status, .done)
        XCTAssertEqual(log.logDate, "2026-07-04")
    }
}
```

- [ ] **Step 5: Chạy test**

Run (trong `FocusPlan/`):
```bash
xcodegen generate
xcodebuild -project FocusPlan.xcodeproj -scheme FocusPlan \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
```
Expected: `** TEST SUCCEEDED **` (test mới + test cũ issue 001/002 vẫn pass).

- [ ] **Step 6: Commit**

```bash
git add FocusPlan/Sources/Models/Habit.swift FocusPlan/Sources/Models/HabitLog.swift \
  FocusPlan/Sources/Models/BusyBlock.swift FocusPlan/Tests/HabitModelTests.swift
git commit -m "feat(ios): add Habit/HabitLog/BusyBlock models + decode tests"
```

---

### Task 3: HabitBusyBlockService (hàm thuần) — TDD

**Files:**
- Create: `FocusPlan/Tests/HabitBusyBlockServiceTests.swift`
- Create: `FocusPlan/Sources/Services/HabitBusyBlockService.swift`

**Interfaces:**
- Consumes: `Habit`, `BusyBlock` (Task 2).
- Produces: `struct HabitBusyBlockService { func busyBlocks(habits: [Habit], on date: Date, calendar: Calendar) -> [BusyBlock] }`.

- [ ] **Step 1: Viết test THẤT BẠI trước** `HabitBusyBlockServiceTests.swift`

```swift
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
```

- [ ] **Step 2: Chạy test → xác nhận FAIL**

Run: `xcodegen generate && xcodebuild -project FocusPlan.xcodeproj -scheme FocusPlan -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test`
Expected: FAIL — `HabitBusyBlockService` chưa tồn tại.

- [ ] **Step 3: Viết `HabitBusyBlockService.swift`**

```swift
import Foundation

struct HabitBusyBlockService {
    /// Xuất busy-block cho từng habit vào ngày `date`. Hàm thuần, deterministic.
    /// Là interface Scheduling Engine (issue 004) sẽ đọc để tránh xếp task đè lên habit.
    func busyBlocks(habits: [Habit], on date: Date, calendar: Calendar = .current) -> [BusyBlock] {
        habits.compactMap { habit in
            guard let (hour, minute) = habit.timeComponents,
                  let start = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: date)
            else { return nil }
            let end = start.addingTimeInterval(TimeInterval(habit.durationMinutes * 60))
            return BusyBlock(habitId: habit.id, start: start, end: end)
        }
    }
}
```

- [ ] **Step 4: Chạy test → xác nhận PASS**

Run: (như Step 2)
Expected: `** TEST SUCCEEDED **`.

- [ ] **Step 5: Commit**

```bash
git add FocusPlan/Sources/Services/HabitBusyBlockService.swift \
  FocusPlan/Tests/HabitBusyBlockServiceTests.swift
git commit -m "feat(ios): HabitBusyBlockService exporting habit busy-blocks (TDD)"
```

---

> **GATE:** Task 4+ đụng bảng `habits`/`habit_logs` — chỉ bắt đầu sau khi leader xác nhận user đã tạo bảng + RLS trên Supabase.

### Task 4: HabitRepository (CRUD habits + logs)

**Files:**
- Create: `FocusPlan/Sources/Services/HabitRepository.swift`

**Interfaces:**
- Consumes: `SupabaseManager.shared.client`, models Task 2. (Tham khảo pattern `FocusPlan/Sources/Services/TaskRepository.swift` issue 002.)
- Produces: `struct HabitRepository` với:
  - `func fetchHabits() async throws -> [Habit]`
  - `func createHabit(_ h: NewHabit) async throws -> Habit`
  - `func updateHabit(id: UUID, _ patch: HabitUpdate) async throws -> Habit`
  - `func deleteHabit(id: UUID) async throws`
  - `func fetchLogs(date: String) async throws -> [HabitLog]`
  - `func setStatus(habitId: UUID, date: String, status: HabitStatus) async throws -> HabitLog`  (upsert theo `habit_id,log_date`)
  - `func clearStatus(habitId: UUID, date: String) async throws`

- [ ] **Step 1: Viết `HabitRepository.swift`**

```swift
import Foundation
import Supabase

struct HabitRepository {
    private let client = SupabaseManager.shared.client

    // LƯU Ý API: xác minh chuỗi builder PostgREST supabase-swift 2.48.0 (from/insert/update/
    // delete/upsert/select/single/order/eq/execute().value) — điều chỉnh nếu lệch, giữ hành vi.
    // RLS scope theo auth.uid(); user_id để DB default (không set ở client).

    func fetchHabits() async throws -> [Habit] {
        try await client.from("habits")
            .select().order("time_of_day", ascending: true)
            .execute().value
    }

    func createHabit(_ h: NewHabit) async throws -> Habit {
        try await client.from("habits")
            .insert(h, returning: .representation).select().single()
            .execute().value
    }

    func updateHabit(id: UUID, _ patch: HabitUpdate) async throws -> Habit {
        try await client.from("habits")
            .update(patch).eq("id", value: id).select().single()
            .execute().value
    }

    func deleteHabit(id: UUID) async throws {
        try await client.from("habits").delete().eq("id", value: id).execute()
    }

    func fetchLogs(date: String) async throws -> [HabitLog] {
        try await client.from("habit_logs")
            .select().eq("log_date", value: date)
            .execute().value
    }

    func setStatus(habitId: UUID, date: String, status: HabitStatus) async throws -> HabitLog {
        let payload = NewHabitLog(habitId: habitId, logDate: date, status: status)
        return try await client.from("habit_logs")
            .upsert(payload, onConflict: "habit_id,log_date", returning: .representation)
            .select().single()
            .execute().value
    }

    func clearStatus(habitId: UUID, date: String) async throws {
        try await client.from("habit_logs")
            .delete()
            .eq("habit_id", value: habitId)
            .eq("log_date", value: date)
            .execute()
    }
}
```

- [ ] **Step 2: Build**

Run: `xcodegen generate && xcodebuild -project FocusPlan.xcodeproj -scheme FocusPlan -destination 'generic/platform=iOS Simulator' build`
Expected: `** BUILD SUCCEEDED **`. (Nếu `upsert(onConflict:)` chữ ký khác trong 2.48.0, điều chỉnh — giữ hành vi upsert theo (habit_id, log_date).)

- [ ] **Step 3: Commit**

```bash
git add FocusPlan/Sources/Services/HabitRepository.swift
git commit -m "feat(ios): add HabitRepository CRUD habits + per-day log upsert"
```

---

### Task 5: HabitListViewModel + HabitsView (checklist hôm nay)

**Files:**
- Create: `FocusPlan/Sources/ViewModels/HabitListViewModel.swift`
- Create: `FocusPlan/Sources/Views/HabitsView.swift`
- Create: `FocusPlan/Sources/Views/HabitFormView.swift`

**Interfaces:**
- Consumes: `HabitRepository` (Task 4), models Task 2.
- Produces:
  - `@MainActor final class HabitListViewModel: ObservableObject { @Published habits; @Published logsByHabit: [UUID: HabitStatus]; @Published isLoading; @Published errorMessage; func load() async; func mark(_ habit: Habit, _ status: HabitStatus) async; func delete(_ habit: Habit) async; var todayString: String }`
  - `struct HabitsView: View`, `struct HabitFormView: View` (Mode create/edit).

- [ ] **Step 1: Viết `HabitListViewModel.swift`**

```swift
import Foundation

@MainActor
final class HabitListViewModel: ObservableObject {
    @Published private(set) var habits: [Habit] = []
    @Published private(set) var logsByHabit: [UUID: HabitStatus] = [:]
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let repo = HabitRepository()

    var todayString: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = .current
        return f.string(from: Date())
    }

    func load() async {
        isLoading = true; errorMessage = nil
        do {
            habits = try await repo.fetchHabits()
            let logs = try await repo.fetchLogs(date: todayString)
            logsByHabit = Dictionary(uniqueKeysWithValues: logs.map { ($0.habitId, $0.status) })
        } catch { errorMessage = error.localizedDescription }
        isLoading = false
    }

    func mark(_ habit: Habit, _ status: HabitStatus) async {
        do {
            if logsByHabit[habit.id] == status {
                try await repo.clearStatus(habitId: habit.id, date: todayString)   // bấm lại để bỏ đánh dấu
                logsByHabit[habit.id] = nil
            } else {
                _ = try await repo.setStatus(habitId: habit.id, date: todayString, status: status)
                logsByHabit[habit.id] = status
            }
        } catch { errorMessage = error.localizedDescription }
    }

    func delete(_ habit: Habit) async {
        do {
            try await repo.deleteHabit(id: habit.id)
            habits.removeAll { $0.id == habit.id }
            logsByHabit[habit.id] = nil
        } catch { errorMessage = error.localizedDescription }
    }
}
```

- [ ] **Step 2: Viết `HabitFormView.swift`**

```swift
import SwiftUI

struct HabitFormView: View {
    enum Mode { case create; case edit(Habit) }
    let mode: Mode
    var onSaved: () -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var time = Date()
    @State private var durationText = "30"
    @State private var isSaving = false
    @State private var errorMessage: String?

    private let repo = HabitRepository()

    var body: some View {
        NavigationStack {
            Form {
                Section("Tên thói quen") { TextField("vd Thiền", text: $name) }
                Section("Giờ cố định") {
                    DatePicker("Giờ", selection: $time, displayedComponents: .hourAndMinute)
                }
                Section("Thời lượng (phút)") {
                    TextField("30", text: $durationText).keyboardType(.numberPad)
                }
                if let errorMessage { Text(errorMessage).foregroundStyle(.red).font(.footnote) }
            }
            .navigationTitle(isEditing ? "Sửa thói quen" : "Thói quen mới")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Huỷ") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Lưu" : "Tạo") { Task { await save() } }
                        .disabled(isSaving || name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear(perform: prefill)
        }
    }

    private var isEditing: Bool { if case .edit = mode { return true }; return false }

    private func prefill() {
        if case .edit(let h) = mode {
            name = h.name
            durationText = String(h.durationMinutes)
            if let (hh, mm) = h.timeComponents,
               let d = Calendar.current.date(bySettingHour: hh, minute: mm, second: 0, of: Date()) {
                time = d
            }
        }
    }

    private func timeString() -> String {
        let c = Calendar.current.dateComponents([.hour, .minute], from: time)
        return String(format: "%02d:%02d", c.hour ?? 0, c.minute ?? 0)
    }

    private func save() async {
        isSaving = true; errorMessage = nil
        let duration = Int(durationText.trimmingCharacters(in: .whitespaces)) ?? 30
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        do {
            switch mode {
            case .create:
                _ = try await repo.createHabit(NewHabit(name: trimmedName, timeOfDay: timeString(), durationMinutes: duration))
            case .edit(let h):
                _ = try await repo.updateHabit(id: h.id, HabitUpdate(name: trimmedName, timeOfDay: timeString(), durationMinutes: duration))
            }
            onSaved(); dismiss()
        } catch { errorMessage = error.localizedDescription }
        isSaving = false
    }
}
```

- [ ] **Step 3: Viết `HabitsView.swift`**

```swift
import SwiftUI

struct HabitsView: View {
    @StateObject private var vm = HabitListViewModel()
    @State private var showingAdd = false
    @State private var editingHabit: Habit?

    var body: some View {
        NavigationStack {
            Group {
                if vm.isLoading && vm.habits.isEmpty {
                    ProgressView()
                } else if vm.habits.isEmpty {
                    ContentUnavailableView("Chưa có thói quen", systemImage: "repeat",
                        description: Text("Thêm thói quen bằng nút +"))
                } else {
                    List {
                        ForEach(vm.habits) { habit in
                            row(habit)
                        }
                        .onDelete { idx in
                            let targets = idx.map { vm.habits[$0] }
                            Task { for h in targets { await vm.delete(h) } }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Thói quen")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingAdd = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Thêm thói quen")
                }
            }
            .task { await vm.load() }
            .sheet(isPresented: $showingAdd) {
                HabitFormView(mode: .create, onSaved: { Task { await vm.load() } })
            }
            .sheet(item: $editingHabit) { h in
                HabitFormView(mode: .edit(h), onSaved: { Task { await vm.load() } })
            }
            .alert("Lỗi", isPresented: .constant(vm.errorMessage != nil)) {
                Button("OK") { vm.errorMessage = nil }
            } message: { Text(vm.errorMessage ?? "") }
        }
    }

    @ViewBuilder
    private func row(_ habit: Habit) -> some View {
        let status = vm.logsByHabit[habit.id]
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(habit.name)
                Text("\(String(habit.timeOfDay.prefix(5))) · \(habit.durationMinutes) phút")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                Task { await vm.mark(habit, .done) }
            } label: {
                Image(systemName: status == .done ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(status == .done ? .green : .secondary)
            }.buttonStyle(.plain)
            Button {
                Task { await vm.mark(habit, .missed) }
            } label: {
                Image(systemName: status == .missed ? "xmark.circle.fill" : "circle")
                    .foregroundStyle(status == .missed ? .red : .secondary)
            }.buttonStyle(.plain)
        }
        .contentShape(Rectangle())
        .onTapGesture { editingHabit = habit }
    }
}
```

- [ ] **Step 4: Build**

Run: `xcodegen generate && xcodebuild -project FocusPlan.xcodeproj -scheme FocusPlan -destination 'generic/platform=iOS Simulator' build`
Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 5: Commit**

```bash
git add FocusPlan/Sources/ViewModels/HabitListViewModel.swift \
  FocusPlan/Sources/Views/HabitsView.swift FocusPlan/Sources/Views/HabitFormView.swift
git commit -m "feat(ios): habit checklist (today done/missed) + create/edit/delete form"
```

---

### Task 6: MainTabView + wire RootView

**Files:**
- Create: `FocusPlan/Sources/Views/MainTabView.swift`
- Modify: `FocusPlan/Sources/Views/RootView.swift`

**Interfaces:**
- Consumes: `HomeView` (issue 002), `HabitsView` (Task 5), `AuthViewModel`.
- Produces: `struct MainTabView: View` — nhận `@ObservedObject var auth: AuthViewModel`, `let email: String`.

- [ ] **Step 1: Viết `MainTabView.swift`**

```swift
import SwiftUI

struct MainTabView: View {
    @ObservedObject var auth: AuthViewModel
    let email: String

    var body: some View {
        TabView {
            HomeView(auth: auth, email: email)
                .tabItem { Label("Hôm nay", systemImage: "calendar") }
            HabitsView()
                .tabItem { Label("Thói quen", systemImage: "repeat") }
        }
    }
}
```

- [ ] **Step 2: Sửa `RootView.swift`** — nhánh `.signedIn` đổi từ `HomeView(...)` sang `MainTabView(...)`:

```swift
            case .signedIn(let email):
                MainTabView(auth: auth, email: email)
```
(Chỉ đổi đúng dòng này; giữ nguyên phần còn lại của RootView.)

- [ ] **Step 3: Build**

Run: `xcodegen generate && xcodebuild -project FocusPlan.xcodeproj -scheme FocusPlan -destination 'generic/platform=iOS Simulator' build`
Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 4: Commit**

```bash
git add FocusPlan/Sources/Views/MainTabView.swift FocusPlan/Sources/Views/RootView.swift
git commit -m "feat(ios): wrap signed-in root in TabView (Hôm nay / Thói quen)"
```

---

### Task 7: QA end-to-end + verify RLS multi-user

- [ ] **Step 1: Build + launch trên simulator** (đăng nhập user thật issue 001)

```bash
xcodebuild -project FocusPlan.xcodeproj -scheme FocusPlan \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath build build
xcrun simctl install booted build/Build/Products/Debug-iphonesimulator/FocusPlan.app
xcrun simctl launch booted com.votronghoang.focusplan
```

- [ ] **Step 2: QA checklist (khớp acceptance criteria)**

1. **CRUD habit** (criteria 1): tab "Thói quen" → nút + → tạo "Thiền" 06:00 20 phút → xuất hiện trong list. Tap để sửa tên/giờ/thời lượng → cập nhật. Swipe xoá → biến mất. Kill+relaunch → thay đổi vẫn còn (đọc từ Supabase).
2. **Checklist done/missed** (criteria 2): bấm nút done (✓ xanh) → đánh dấu hoàn thành hôm nay; bấm missed (✗ đỏ) → chuyển bỏ lỡ; bấm lại để clear. Kill+relaunch → trạng thái hôm nay vẫn đúng.
3. **Habit không bị xếp tự động** (criteria 3): xác nhận không có UI/flow nào tự đổi giờ habit; giờ chỉ đổi khi user sửa trong form. (Kiểm tra thiết kế — không có Scheduling Engine động vào.)
4. **Busy-block export** (criteria 4): đã được `HabitBusyBlockServiceTests` (Task 3) verify deterministic — ghi rõ trong QA note rằng interface + logic busy-block có test tự động PASS; runtime không cần thêm vì Scheduling Engine (issue 004) chưa tồn tại.
5. **RLS multi-user**: sign out → user 2 → tab Thói quen RỖNG (không thấy habit user 1). Tạo habit ở user 2 → chỉ user 2 thấy. (Nếu làm được, verify thêm REST 2 token cho `habits` + `habit_logs`.)

- [ ] **Step 3: (Tuỳ chọn) verify RLS tầng API** với 2 access_token — mỗi token chỉ thấy habits/logs của mình. Ghi kết quả vào QA note.

- [ ] **Step 4: Commit** (nếu thêm XCUITest/script QA)

```bash
git add -A && git commit -m "test(ios): QA notes for habit tracking + RLS isolation"
```

---

## Self-Review (đã chạy)

- **Spec coverage:**
  - Criteria 1 (CRUD habit tên + giờ cố định lặp ngày): Task 4 (repo) + Task 5 (form/list). ✔
  - Criteria 2 (đánh dấu done/missed theo ngày): `habit_logs` + `setStatus/clearStatus` (Task 4) + checklist UI (Task 5). ✔
  - Criteria 3 (không bị xếp tự động): thiết kế — habit chỉ có `time_of_day` do user đặt, không mutation tự động; verify Task 7 Step 2.3. ✔
  - Criteria 4 (xuất busy-block cho Scheduling Engine): `BusyBlock` + `HabitBusyBlockService` (Task 3) + TDD test. ✔
- **Schema trong repo** (bài học issue 002): Task 1 migration file. ✔
- **Multi-user isolation:** RLS ở migration + client không set user_id (Task 2 payload bỏ user_id) + verify Task 7. ✔
- **Type consistency:** `Habit`/`NewHabit`/`HabitUpdate`, `HabitLog`/`NewHabitLog`/`HabitStatus`, `BusyBlock` khớp giữa models ↔ HabitRepository ↔ HabitBusyBlockService ↔ ViewModel ↔ Views. `HabitFormView.Mode` (create/edit) khớp gọi ở HabitsView. `MainTabView` khớp RootView. ✔
- **Rủi ro đã ghi:** chữ ký PostgREST/`upsert(onConflict:)` supabase-swift 2.48.0 (verify với package thật); decode `time`/`date`/`timestamptz` (giữ String cho time_of_day/log_date để tránh vỡ tz); simulator name.
- **Placeholder scan:** không có TODO/TBD; mọi step có code/lệnh cụ thể. ✔
