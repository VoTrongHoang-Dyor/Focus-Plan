---
status: todo
---

## Parent Decision Log

`.claude/wiki/decisions/focus-scheduler-decision-log.md`

## What to build

Deterministic scheduling engine v1: rule-based (không LLM) xếp task đã tạo vào slot rảnh trong ngày, dựa trên priority, energy-matching tĩnh (buổi sáng ưu tiên deep work, khung giờ khác theo rule cố định), buffer giữa các block, và busy-block từ Habit/Routine Tracking (issue 003) để không xếp task đè lên khung giờ habit cố định.

## Acceptance criteria

- [ ] Cho một danh sách task với priority + thời lượng ước tính, engine trả về lịch xếp slot cụ thể trong ngày.
- [ ] Rule energy-matching tĩnh được áp dụng nhất quán (không đổi giữa các lần chạy với cùng input).
- [ ] Buffer giữa các block được chèn theo rule cố định, không nhồi task sát nhau.
- [ ] Engine nhận danh sách busy-block từ Habit module (issue 003) và không xếp task nào đè lên khung giờ đó.
- [ ] Engine test được độc lập (input task list + busy-block list → output schedule), không phụ thuộc UI hay network call.

## Blocked by

- Blocked by `.claude/wiki/issues/002-task-creation-gemini-nlp-parse.md`
- Blocked by `.claude/wiki/issues/003-habit-routine-tracking.md`

## Decision Log sections addressed

- Logic tìm slot trống
