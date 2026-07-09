---
status: done
---

## Parent Decision Log

`.claude/wiki/decisions/focus-scheduler-decision-log.md`

## What to build

Pomodoro Timer module: màn hình đếm giờ focus session (start/stop/pause). Chạy nền khi app bị minimize/khoá màn hình; kết thúc phiên báo qua local notification — tái dùng hạ tầng của Alarm/Notification module (issue 005), không xây cơ chế thông báo mới. Đây là nguồn dữ liệu Pomodoro thực tế đầu tiên trong toàn bộ hệ thống — Daily Reflection (issue 008), Gamification core (issue 009), và Energy Matching Historical Weighting (issue 013) đều giả định có "dữ liệu Pomodoro" nhưng trước module này chưa có gì tạo ra nó.

## Acceptance criteria

- [x] User start/pause/end phiên Pomodoro từ tab "Tập trung" (UI xanh, identifier A11yID.Pomodoro.*)
- [x] Timer chạy đúng khi app minimize/khoá (wall-clock PomodoroEngine, chống suspend error)
- [x] Kết thúc phiên bắn local notification id `pomodoro-end` (tái dùng issue 005 NotificationScheduling)
- [x] Phiên hoàn thành lưu Supabase `pomodoro_sessions` (start_time, actual_duration, user_id). Dữ liệu nguồn cho issues 008/009/013. Full suite 57 tests PASS (49 unit + 8 UITests, end-to-end thật).

## Blocked by

- Blocked by `.claude/wiki/issues/001-ios-app-shell-supabase-auth.md`
- Blocked by `.claude/wiki/issues/005-local-escalating-alarm-loop.md`

## Decision Log sections addressed

- Tính năng mới bổ sung — Pomodoro timer UI (Clarify, FlowStack, Focus To-Do)
