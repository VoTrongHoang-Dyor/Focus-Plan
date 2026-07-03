---
status: todo
---

## Parent Decision Log

`.claude/wiki/decisions/focus-scheduler-decision-log.md`

## What to build

Nâng cấp energy-matching từ rule tĩnh (issue 004) sang có trọng số theo lịch sử thực tế: dùng Pomodoro completion rate theo khung giờ của từng user để tự điều chỉnh trọng số ưu tiên slot. Vẫn deterministic/thống kê, không phải LLM reasoning.

## Acceptance criteria

- [ ] Engine đọc được completion rate theo khung giờ từ dữ liệu Pomodoro thật do Pomodoro Timer (issue 006) ghi lại, tổng hợp qua Daily Reflection (issue 008).
- [ ] Trọng số slot được điều chỉnh dựa trên completion rate thực tế thay vì rule cố định "sáng = deep work".
- [ ] Hành vi vẫn deterministic — cùng input lịch sử cho cùng output, không random/không LLM reasoning.
- [ ] Có thể so sánh A/B được giữa rule tĩnh (004) và rule có trọng số (013) trên cùng bộ dữ liệu test.

## Blocked by

- Blocked by `.claude/wiki/issues/004-deterministic-scheduling-engine-v1.md`
- Blocked by `.claude/wiki/issues/006-pomodoro-timer.md`
- Blocked by `.claude/wiki/issues/008-daily-reflection-generation.md`

## Decision Log sections addressed

- Brainstorm A.1
