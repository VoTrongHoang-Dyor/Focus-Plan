---
status: todo
---

## Parent Decision Log

`claude/wiki/decisions/focus-scheduler-decision-log.md`

## What to build

Cơ chế báo thức local notification: khi đến giờ task đã xếp lịch, app bắn notification lặp lại nhiều lần (1-2 phút/lần, trong khoảng ~10 phút) với tone tăng dần độ khẩn cấp (escalating tone), best-effort — không dùng Critical Alerts entitlement.

## Acceptance criteria

- [ ] Đến giờ task, notification đầu tiên được bắn.
- [ ] Nếu user không tương tác, notification lặp lại theo chu kỳ 1-2 phút, trong ~10 phút, với âm thanh/tone tăng dần.
- [ ] User tương tác (mở app, đánh dấu done/snooze) thì chuỗi notification dừng.
- [ ] Hành vi được test trên iOS thật (không chỉ simulator) do local notification background có giới hạn hệ điều hành.

## Blocked by

- Blocked by `claude/wiki/issues/003-deterministic-scheduling-engine-v1.md`

## Decision Log sections addressed

- Cơ chế báo thức (core loop)
