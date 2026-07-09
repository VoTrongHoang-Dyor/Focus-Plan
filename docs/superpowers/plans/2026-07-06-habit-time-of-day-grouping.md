# Habit Time-of-Day Grouping Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Nhóm habit theo buổi trong ngày (sáng/chiều/tối) trên `HabitsView` + hiển thị buổi derive trên `HabitFormView`, khớp bản Flutter demo — issue `.claude/wiki/issues/025-habit-time-of-day-grouping.md`.

**Architecture:** KHÔNG thêm field DB, KHÔNG migration — buổi là **computed property** derive từ `Habit.timeOfDay` (đúng cách demo Dart làm: `DayPartView.fromMinutes`, `models/habit.dart:43-47`). Thêm `enum DayPart` cạnh model `Habit`, `HabitsView` render section theo buổi, `HabitFormView` hiện buổi derive live khi user chọn giờ.

**Tech Stack:** SwiftUI (iOS 17), XcodeGen, XCTest + XCUITest.

## Global Constraints

- **Chạy SAU khi issue 024 đã commit xong** (form polish đang dở trên `HabitFormView.swift` — Task 3 build chồng lên bản đã commit đó).
- **Reference = spec:** `focus_plan_ui_demo/lib/models/habit.dart:28-48` (DayPart + ranges), `focus_plan_ui_demo/lib/screens/habits_screen.dart:136-262` (section layout). Đọc trước khi code.
- **Hour range CHỐT theo demo** (thắng phác thảo trong issue): `hour < 12` → morning, `hour < 18` → afternoon, còn lại → evening. (Demo xếp 0h–6h vào morning — giữ nguyên, không "sửa" theo issue sketch 6am–6am.)
- **Label CHỐT theo demo:** "Buổi sáng" / "Buổi chiều" / "Buổi tối". Icon SF Symbols tương ứng demo Material: `sunrise.fill` / `sun.max.fill` / `moon.fill` (chi tiết thẩm mỹ khác coder tự quyết bằng skill `ui-ux-pro-max`, stack SwiftUI).
- **Giữ nguyên 100%**: mọi `accessibilityLabel`/text UITest đang bám ("Thêm thói quen", "Đánh dấu hoàn thành", "Đánh dấu bỏ lỡ", nav title "Thói quen", "Thói quen mới"/"Sửa thói quen"), SummaryHeader, empty state, logic mark/delete/edit, `HabitBusyBlockService` (chỉ dùng `timeComponents` — KHÔNG đụng; confirm lại trong review).
- **Test suite phải xanh sau MỖI task.** Lệnh chạy trong `FocusPlan/`:
  - Build: `xcodegen generate && xcodebuild -project FocusPlan.xcodeproj -scheme FocusPlan -destination 'generic/platform=iOS Simulator' build`
  - Test: `xcodebuild -project FocusPlan.xcodeproj -scheme FocusPlan -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test`
- Commit sau mỗi task, message tiếng Anh `feat(ios): ...`.
- KHÔNG push, KHÔNG rebase/amend — 2 commit CI (`11f5bc6`, `21aac3a`) đang chờ HITL.

---

### Task 1: `DayPart` enum + `Habit.dayPart` (model)

**Files:**
- Modify: `FocusPlan/Sources/Models/Habit.swift`
- Test: `FocusPlan/Tests/HabitModelTests.swift`

**Interfaces:**
- Produces: `enum DayPart: CaseIterable, Equatable { case morning, afternoon, evening }` với `var label: String`, `var icon: String`, `static func from(hour: Int) -> DayPart`; `Habit.dayPart: DayPart` (Task 2 + 3 dùng).

- [ ] **Step 1: Viết failing tests** — thêm vào `HabitModelTests.swift`:

```swift
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
```

- [ ] **Step 2: Run test → FAIL** ("cannot find 'DayPart'").
- [ ] **Step 3: Implement** — thêm vào cuối `Habit.swift`:

```swift
/// Buổi trong ngày — derive từ giờ, KHÔNG lưu DB (port từ demo models/habit.dart DayPart).
enum DayPart: CaseIterable, Equatable {
    case morning, afternoon, evening

    var label: String {
        switch self {
        case .morning: "Buổi sáng"
        case .afternoon: "Buổi chiều"
        case .evening: "Buổi tối"
        }
    }

    /// SF Symbol tương ứng icon demo (wb_twilight/wb_sunny/nightlight).
    var icon: String {
        switch self {
        case .morning: "sunrise.fill"
        case .afternoon: "sun.max.fill"
        case .evening: "moon.fill"
        }
    }

    /// Ranges theo demo: <12h sáng, <18h chiều, còn lại tối.
    static func from(hour: Int) -> DayPart {
        if hour < 12 { return .morning }
        if hour < 18 { return .afternoon }
        return .evening
    }
}

extension Habit {
    /// Buổi của habit; timeOfDay hỏng (không parse được) → mặc định sáng.
    var dayPart: DayPart { DayPart.from(hour: timeComponents?.hour ?? 0) }
}
```

- [ ] **Step 4: Run test → PASS**, toàn bộ unit test cũ xanh.
- [ ] **Step 5: Commit** `feat(ios): add DayPart classification derived from habit timeOfDay`

---

### Task 2: `HabitsView` — section theo buổi

**Files:**
- Modify: `FocusPlan/Sources/Views/HabitsView.swift` (thay `Section` phẳng chứa `ForEach(vm.habits)` hiện tại, dòng ~25-33)
- Modify: `FocusPlan/UITests/HabitFlowUITests.swift` (thêm 1 assertion)

**Interfaces:**
- Consumes: `DayPart` (label/icon/CaseIterable), `Habit.dayPart` (Task 1).

**Cấu trúc theo demo (`habits_screen.dart:161-196` `_buildSection`):** mỗi buổi có habit → 1 section: header icon+label, rows sort theo giờ tăng dần; buổi rỗng → KHÔNG render section.

- [ ] **Step 1: Restyle** — trong `body`, thay block:

```swift
Section {
    ForEach(vm.habits) { habit in
        row(habit)
    }
    .onDelete { idx in
        let targets = idx.map { vm.habits[$0] }
        Task { for h in targets { await vm.delete(h) } }
    }
}
```

bằng:

```swift
ForEach(DayPart.allCases, id: \.self) { part in
    let items = habits(in: part)
    if !items.isEmpty {
        Section {
            ForEach(items) { habit in
                row(habit)
            }
            .onDelete { idx in
                let targets = idx.map { items[$0] }
                Task { for h in targets { await vm.delete(h) } }
            }
        } header: {
            Label(part.label, systemImage: part.icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.onSurfaceVariant)
        }
    }
}
```

và thêm helper private trong `HabitsView`:

```swift
/// Habit thuộc buổi `part`, sort giờ tăng dần ("HH:mm:ss" so chuỗi = so giờ).
private func habits(in part: DayPart) -> [Habit] {
    vm.habits.filter { $0.dayPart == part }.sorted { $0.timeOfDay < $1.timeOfDay }
}
```

(Chi tiết style header — casing, spacing — coder chốt bằng `ui-ux-pro-max` nhưng label text phải đúng nguyên văn "Buổi sáng/chiều/tối". SummaryHeader, emptyState, `row(_:)` giữ nguyên.)

- [ ] **Step 2: Thêm assertion UITest** — trong `test_habit_shows_and_checklist_persists` của `HabitFlowUITests.swift`, ngay SAU block Criteria 1 (`app.staticTexts["Thiền"]` đã tồn tại — seed habit `time_of_day: "06:00:00"` → morning):

```swift
// Criteria 1b (issue 025): habit 06:00 nằm trong section "Buổi sáng".
XCTAssertTrue(app.staticTexts["Buổi sáng"].waitForExistence(timeout: 5),
              "Không thấy section header 'Buổi sáng' — grouping theo buổi chưa render")
```

- [ ] **Step 3: Verify** — build + `-only-testing:FocusPlanUITests/HabitFlowUITests` + `-only-testing:FocusPlanUITests/A11yIdentifierUITests` → PASS.
- [ ] **Step 4: Commit** `feat(ios): group habits by time-of-day sections (demo parity)`

---

### Task 3: `HabitFormView` — hiện buổi derive + full-suite verification

**Files:**
- Modify: `FocusPlan/Sources/Views/HabitFormView.swift`

**Interfaces:**
- Consumes: `DayPart.from(hour:)`, `label`, `icon` (Task 1).

**Quyết định UX (chốt theo demo, `habits_screen.dart:31-118`):** demo form CHỈ chọn giờ — buổi 100% derive, không có picker buổi. Swift làm y hệt: giữ `DatePicker` giờ hiện có, thêm 1 dòng caption hiển thị buổi derive live ngay dưới field "Giờ cố định" — thoả criterion "logic chọn giờ → buổi" của issue. KHÔNG thêm picker buổi (YAGNI + lệch demo). Habit cũ không cần migration/đụng data — mở form là thấy buổi đúng từ giờ đã lưu.

- [ ] **Step 1: Implement** — trong `body`, ngay dưới field DatePicker "Giờ cố định" (sau `.filledFieldStyle()`), thêm:

```swift
Label(derivedDayPart.label, systemImage: derivedDayPart.icon)
    .font(.caption)
    .foregroundStyle(Theme.onSurfaceVariant)
```

và helper private trong `HabitFormView`:

```swift
/// Buổi derive live từ giờ đang chọn — cùng rule DayPart.from(hour:) với HabitsView.
private var derivedDayPart: DayPart {
    DayPart.from(hour: Calendar.current.component(.hour, from: time))
}
```

- [ ] **Step 2: Full-suite verify** — `xcodegen generate && xcodebuild -project FocusPlan.xcodeproj -scheme FocusPlan -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test` → toàn bộ unit + UITest xanh, 0 fail 0 skip.
- [ ] **Step 3: Confirm `HabitBusyBlockService` không đổi** — `git diff FocusPlan/Sources/Services/HabitBusyBlockService.swift` rỗng; ghi 1 dòng xác nhận trong message gửi reviewer (criterion 5 của issue).
- [ ] **Step 4: Commit** `feat(ios): show derived day part in habit form`

## Self-Review Notes

- Spec coverage: criterion 1 (classify) → Task 1; criterion 2 (schema/migration) → N/A by design, computed property, ghi rõ trong Architecture; criterion 3 (HabitsView sections) → Task 2; criterion 4 (form chọn giờ → buổi) → Task 3; criterion 5 (HabitBusyBlockService không đổi) → Task 3 Step 3; criterion 6 (test suite xanh) → verify từng task + full suite Task 3.
- Type consistency: `DayPart.from(hour:)`, `.label`, `.icon`, `Habit.dayPart` dùng thống nhất T1→T3.
- 2 điểm "TBD" trong issue đã chốt tại plan: hour range theo demo (<12/<18), form UX = giờ → buổi derive (không picker buổi).
