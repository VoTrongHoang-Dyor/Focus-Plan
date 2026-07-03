---
status: todo
---

## Parent Decision Log

`.claude/wiki/decisions/focus-scheduler-decision-log.md`

## What to build

Cron job 9h sáng theo timezone từng user (Supabase pg_cron + Edge Function) gọi lại scheduling engine (issue 004) để reschedule các task chưa hoàn thành/task mới trong ngày, rồi push kết quả qua APNs/FCM.

## Acceptance criteria

- [ ] Cron chạy đúng 9h sáng theo timezone của từng user (không phải giờ server cố định).
- [ ] Edge Function gọi scheduling engine và nhận lại lịch mới.
- [ ] Push notification báo user lịch đã được reschedule, qua APNs (iOS trước) — FCM để sẵn interface cho Android sau.
- [ ] Có log/record lần reschedule (phục vụ issue 008 Daily Reflection và issue 014 buffer động).

## Blocked by

- Blocked by `.claude/wiki/issues/001-ios-app-shell-supabase-auth.md`
- Blocked by `.claude/wiki/issues/004-deterministic-scheduling-engine-v1.md`

## Decision Log sections addressed

- Trigger reschedule 9h sáng
