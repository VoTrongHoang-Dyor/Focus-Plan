---
status: todo
---

## Parent Decision Log

`.claude/wiki/decisions/focus-scheduler-decision-log.md`

## What to build

Pomodoro Timer module: màn hình đếm giờ focus session (start/stop/pause). Chạy nền khi app bị minimize/khoá màn hình; kết thúc phiên báo qua local notification — tái dùng hạ tầng của Alarm/Notification module (issue 005), không xây cơ chế thông báo mới. Đây là nguồn dữ liệu Pomodoro thực tế đầu tiên trong toàn bộ hệ thống — Daily Reflection (issue 008), Gamification core (issue 009), và Energy Matching Historical Weighting (issue 013) đều giả định có "dữ liệu Pomodoro" nhưng trước module này chưa có gì tạo ra nó.

## Acceptance criteria

- [ ] User bắt đầu, tạm dừng, và kết thúc một phiên Pomodoro từ UI.
- [ ] Timer vẫn chạy đúng khi app bị minimize/khoá màn hình.
- [ ] Kết thúc phiên (hết giờ) bắn local notification, tái dùng hạ tầng notification của issue 005.
- [ ] Mỗi phiên hoàn thành được lưu lại (thời điểm bắt đầu, thời lượng thực tế) gắn với user hiện tại — đây là dữ liệu nguồn cho các module gamification/reflection sau này đọc vào.

## Blocked by

- Blocked by `.claude/wiki/issues/001-ios-app-shell-supabase-auth.md`
- Blocked by `.claude/wiki/issues/005-local-escalating-alarm-loop.md`

## Decision Log sections addressed

- Tính năng mới bổ sung — Pomodoro timer UI (Clarify, FlowStack, Focus To-Do)
