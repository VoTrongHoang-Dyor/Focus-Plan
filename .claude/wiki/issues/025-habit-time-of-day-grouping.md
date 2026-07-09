---
status: done
---

## Parent PRD

`.claude/wiki/prd/focusplan-swift-mascot-mcp-web.md`

## What to build

Thêm khả năng nhóm habit theo buổi trong ngày (sáng/chiều/tối), tương tự bản Flutter demo (`focus_plan_ui_demo/lib/screens/habits_screen.dart:136–262`). 

**Hiện tại:** Model `Habit` có field `timeOfDay: String` (Postgres `time` — giờ cụ thể vd "06:00:00", khi nào thực hiện habit), nhưng KHÔNG có logic nhóm vào buổi. `HabitsView` hiển thị danh sách phẳng.

**Cần làm:**
1. **Model + Schema:** Thêm logic/field để classify `timeOfDay` vào buổi (morning ~6am-12pm, afternoon ~12pm-6pm, evening ~6pm-6am). Có thể:
   - Thêm explicit field `timeOfDayPeriod` enum vào model `Habit` (choice: model hoặc computed property)
   - Or: helper function thuần dùng `timeOfDay` để derive period (recommendation: helper function để avoid DB migration)
   - Kiểm tra `HabitBusyBlockService` xem logic busy-block có cần thay đổi không (likely không, vì chỉ về hiển thị, không ảnh hưởng scheduling)

2. **UI:** 
   - `HabitFormView`: option picker chọn buổi (Morning/Afternoon/Evening) thay vì giờ cụ thể, hoặc kèm (TBD ở planning)
   - `HabitsView`: section theo buổi, mỗi section hiển thị habit trong buổi đó (layout khớp demo)

3. **Data:** Migration an toàn cho habit cũ (map existing `timeOfDay` → period, default hợp lý, hoặc ask user on next edit)

## Acceptance criteria

- [x] Model `Habit` (và `HabitUpdate`) có cách classify `timeOfDay` vào buổi (Morning/Afternoon/Evening) — DayPart enum + computed property `Habit.dayPart` (TDD).
- [x] Schema Supabase bảng `habits` — N/A by design: computed property không cần migration, giữ nguyên `time` column.
- [x] `HabitsView` hiển thị section theo buổi (header mỗi buổi "Buổi sáng"/"Buổi chiều"/"Buổi tối") — khớp layout demo.
- [x] `HabitFormView` cho user chọn giờ → buổi derive live (không picker buổi riêng). Hour range: <12h sáng / <18h chiều / còn lại tối.
- [x] `HabitBusyBlockService` kiểm tra — diff rỗng, KHÔNG cần thay đổi (grouping là view-layer, không ảnh hưởng scheduling logic).
- [x] Toàn bộ test suite xanh (46 tests: 39 unit + 7 UITest, HabitFlowUITests buổi grouping assertion pass, accessibility text giữ nguyên).

## Blocked by

- `.claude/wiki/issues/024-swift-ui-polish-flutter-parity.md` — UI grouping dựng trên `HabitsView` đã restyle.

## User stories addressed

Implicit từ PRD (không có user story riêng, follow-up gap từ 024 polish).

## Notes

**Phát hiện:** Issue 025 được tách từ scope 024 (Swift UI Polish) vì 024 chỉ restyle visual cấu trúc hiện có, không mở rộng model/data. Habit grouping cần model thay đổi → riêng thẻ.

**Planning cần chốt:** chính xác hour range cho Morning/Afternoon/Evening (recommend căn theo demo Dart), form UX cho user chọn buổi hay giờ.
