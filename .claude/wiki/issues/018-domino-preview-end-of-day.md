---
status: todo
---

## Parent Decision Log

`.claude/wiki/decisions/focus-scheduler-decision-log.md`

## What to build

Domino Preview: màn hình cuối ngày hiện 1 thông điệp duy nhất kiểu "Nếu bạn hoàn thành task X ngày mai đúng giờ, streak Y sẽ đạt mốc Z" — tổng hợp từ dữ liệu streak/task đã có, không cần logic mới.

## Acceptance criteria

- [ ] Cuối ngày (sau Daily Reflection), user thấy 1 màn hình Domino Preview.
- [ ] Nội dung preview tính đúng: task cụ thể ngày mai + mốc streak sẽ đạt được nếu hoàn thành đúng giờ.
- [ ] Màn hình chỉ tổng hợp dữ liệu đã có (streak, task đã lên lịch) — không thêm nguồn dữ liệu mới.

## Blocked by

- Blocked by `.claude/wiki/issues/009-gamification-core-streak-badges.md`

## Decision Log sections addressed

- Brainstorm B.3
