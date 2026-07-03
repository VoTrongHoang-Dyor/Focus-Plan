---
status: todo
---

## Parent Decision Log

`.claude/wiki/decisions/focus-scheduler-decision-log.md`

## What to build

Habit/Routine Tracking module: checklist giờ cố định do user tự đặt (vd 6h sáng thiền, tập thể dục), lặp lại hàng ngày. Độc lập với Scheduling Engine — không đi qua thuật toán xếp lịch task thường. Điểm tích hợp duy nhất: xuất danh sách khung giờ habit ra làm busy-block input cho Scheduling Engine (issue 004), để engine không xếp task thường đè lên.

## Acceptance criteria

- [ ] User tạo/sửa/xoá được một habit với tên + giờ cố định lặp lại hàng ngày.
- [ ] User đánh dấu hoàn thành/bỏ lỡ habit trong ngày qua checklist.
- [ ] Habit KHÔNG được xếp/di chuyển bởi Scheduling Engine — giờ cố định do user đặt, không đổi tự động.
- [ ] Module xuất được danh sách khung giờ habit dưới dạng busy-block mà Scheduling Engine (issue 004) có thể đọc làm input.

## Blocked by

- Blocked by `.claude/wiki/issues/001-ios-app-shell-supabase-auth.md`

## Decision Log sections addressed

- Tính năng mới bổ sung — Habit/Routine tracking (TickTick, MyPlan)
