---
status: todo
---

## Parent Decision Log

`claude/wiki/decisions/focus-scheduler-decision-log.md`

## What to build

Level 3 badge (mốc "tắt điện thoại") đo bằng tín hiệu Focus Mode/Do Not Disturb của hệ điều hành thay vì Screen Time API thật — né rủi ro Screen Time entitlement.

## Acceptance criteria

- [ ] App đọc được trạng thái Focus Mode/DND hiện tại của thiết bị qua API hệ điều hành (không tự bật hộ).
- [ ] Level 3 badge được tính dựa trên thời gian Focus Mode/DND bật trùng với khung giờ task đã lên lịch.
- [ ] Không dùng Screen Time entitlement thật ở bất kỳ đâu trong slice này.

## Blocked by

- Blocked by `claude/wiki/issues/007-gamification-core-streak-badges.md`
- Blocked by `claude/wiki/issues/009-screen-time-monk-mode.md`

## Decision Log sections addressed

- Brainstorm B.2
