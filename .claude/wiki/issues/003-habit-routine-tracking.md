---
status: done
---

## Parent Decision Log

`.claude/wiki/decisions/focus-scheduler-decision-log.md`

## What to build

Habit/Routine Tracking module: checklist giờ cố định do user tự đặt (vd 6h sáng thiền, tập thể dục), lặp lại hàng ngày. Độc lập với Scheduling Engine — không đi qua thuật toán xếp lịch task thường. Điểm tích hợp duy nhất: xuất danh sách khung giờ habit ra làm busy-block input cho Scheduling Engine (issue 004), để engine không xếp task thường đè lên.

## Acceptance criteria

- [x] User tạo/sửa/xoá được một habit với tên + giờ cố định lặp lại hàng ngày.
- [x] User đánh dấu hoàn thành/bỏ lỡ habit trong ngày qua checklist.
- [x] Habit KHÔNG được xếp/di chuyển bởi Scheduling Engine — giờ cố định do user đặt, không đổi tự động.
- [x] Module xuất được danh sách khung giờ habit dưới dạng busy-block mà Scheduling Engine (issue 004) có thể đọc làm input.

## QA / verify (2026-07-04)

- Bảng `habits` + `habit_logs` (+ RLS 8 policy `*_own`, `unique(habit_id, log_date)`, FK cascade). Migration `supabase/migrations/20260704051538_create_habits.sql` trong repo.
- Client: models, `HabitRepository` (CRUD + upsert log `onConflict: habit_id,log_date`), `HabitBusyBlockService` (hàm thuần, TDD 3 test), UI TabView "Hôm nay/Thói quen".
- Reviewer PASS (không Critical/Important). Build + full test PASS (10 unit + 3 UITest), không regression issue 001/002.
- QA 5/5 PASS: CRUD, checklist done/missed persist qua relaunch, không auto-schedule, busy-block export (TDD), RLS multi-user (REST 2-token: user B & anon rỗng, không sửa/xoá được của A).
- Ghi nợ (không chặn): RLS hardening `habit_logs` insert/update chưa kiểm `habit_id` thuộc user — rủi ro thực tế ≈ 0 (UUID không đoán được, chỉ write-DoS, không lộ data). Xem xét khi mở rộng multi-user thật.

## Blocked by

- Blocked by `.claude/wiki/issues/001-ios-app-shell-supabase-auth.md`

## Decision Log sections addressed

- Tính năng mới bổ sung — Habit/Routine tracking (TickTick, MyPlan)
