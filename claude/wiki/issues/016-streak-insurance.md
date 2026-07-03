---
status: todo
---

## Parent Decision Log

`claude/wiki/decisions/focus-scheduler-decision-log.md`

## What to build

Streak Insurance: cho phép "cứu" streak 1 lần/tuần nếu user hoàn thành 1 task bù trong ngày đã bỏ lỡ, giới hạn nghiêm (1 lần/tuần, không tích luỹ).

## Acceptance criteria

- [ ] User bỏ lỡ streak trong tuần được offer 1 lần "cứu" nếu hoàn thành task bù trước một deadline hợp lý.
- [ ] Giới hạn đúng 1 lần/tuần, không cho phép tích luỹ dồn sang tuần sau.
- [ ] Sau khi dùng insurance, streak được khôi phục đúng logic (không cộng dồn sai số ngày).

## Blocked by

- Blocked by `claude/wiki/issues/007-gamification-core-streak-badges.md`

## Decision Log sections addressed

- Brainstorm B.1
