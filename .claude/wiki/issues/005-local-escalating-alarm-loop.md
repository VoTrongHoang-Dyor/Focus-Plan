---
status: done
---

## Parent Decision Log

`.claude/wiki/decisions/focus-scheduler-decision-log.md`

## What to build

Cơ chế báo thức local notification: khi đến giờ task đã xếp lịch, app bắn notification lặp lại nhiều lần (1-2 phút/lần, trong khoảng ~10 phút) với tone tăng dần độ khẩn cấp (escalating tone), best-effort — không dùng Critical Alerts entitlement.

## Acceptance criteria

- [x] Đến giờ task, notification đầu tiên được bắn.
- [x] Nếu user không tương tác, notification lặp lại theo chu kỳ 1-2 phút, trong ~10 phút, với âm thanh/tone tăng dần.
- [x] User tương tác (mở app, đánh dấu done/snooze) thì chuỗi notification dừng.
- [ ] Hành vi được test trên iOS thật (không chỉ simulator) do local notification background có giới hạn hệ điều hành. **← PENDING: user tự QA trên iPhone thật theo checklist bên dưới (môi trường team không có device; quyết định user 2026-07-05).**

## QA / verify (2026-07-05)

- Implement theo plan `docs/superpowers/plans/2026-07-05-local-escalating-alarm-loop.md`, 6 task TDD phần thuần.
- **Design (user chốt):** chùm ~6 `UNNotificationRequest` cách 2' (offset 0..10'), `.default` sound, escalation qua TEXT khẩn dần (không asset âm thanh); KHÔNG Critical Alerts / background mode; Full scope — wiring engine issue 004 vào app.
- **Kiến trúc:** `AlarmPlanner` (pure: chùm/escalating/skip-past/budget 60 né 64-limit) + `AlarmScheduler` (bọc `UNUserNotificationCenter` qua protocol, test bằng fake) + `AlarmNotificationDelegate` (category actions Done/Snooze; Snooze re-arm +10' qua `userInfo["taskName"]`) + `TodayScheduleService` (fetchAll → busyBlocks → SchedulingEngine → arm; re-arm khi app `.active`, lọc `start > now` để mở app dừng chuỗi đang chạy).
- Reviewer FAIL vòng 1 (1 Critical criteria-3: re-arm đuôi chùm đang chạy; 1 Important: coupling Snooze↔body) → coder fix (`bb6d033`, `1e4ca96`) → **PASS vòng cuối criteria 1-3**. Full suite `** TEST SUCCEEDED **`: 26 unit + 5 UITest = 31, 0 hồi quy.
- Commits: `74a30ab` (permission+delegate), `ed27c95` (AlarmPlanner), `619b7b8` (AlarmScheduler), `98e2109` (Done/Snooze), `3b348ac` (TodayScheduleService), `bb6d033` (fix criteria-3), `1e4ca96` (userInfo decouple).

## Checklist QA device thật (criteria 4 — user tự chạy trên iPhone)

1. Cấp quyền notification; tạo 1 task có giờ bắt đầu gần (engine xếp hôm nay) → đến giờ → notification đầu bắn.
2. Không tương tác → lặp mỗi ~2', trong ~10', title khẩn dần ("⏰ Đến giờ rồi" → … → "⏰⏰ LÀM NGAY").
3. Mở app → chuỗi dừng. "Xong" → dừng chùm task đó. "Hoãn 10'" → dừng rồi arm lại chùm mới từ +10'.
4. Khoá màn hình / app nền → vẫn nhận (best-effort; iOS có thể gộp/trễ — chấp nhận theo design v1).

Khi user xác nhận đủ 4 mục → tick criteria 4.

## Blocked by

- Blocked by `.claude/wiki/issues/004-deterministic-scheduling-engine-v1.md`

## Decision Log sections addressed

- Cơ chế báo thức (core loop)
