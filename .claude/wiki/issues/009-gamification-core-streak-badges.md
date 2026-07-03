---
status: todo
---

## Parent Decision Log

`.claude/wiki/decisions/focus-scheduler-decision-log.md`

## What to build

Gamification core: Seinfeld streak chain (chuỗi ngày hoàn thành), Loss Aversion nhẹ (mất streak khi bỏ lỡ, không liên quan tiền thật), và 6 Levels badge đo qua dữ liệu Pomodoro thật do Pomodoro Timer module (issue 006) ghi lại.

## Acceptance criteria

- [ ] Streak tăng khi user hoàn thành task đúng hạn trong ngày, reset khi bỏ lỡ (theo rule Seinfeld chain).
- [ ] Mất streak có feedback rõ ràng trong UI (Loss Aversion) nhưng không có cơ chế tiền thật.
- [ ] 6 Levels badge được tính dựa trên dữ liệu Pomodoro tích luỹ từ issue 006, có ngưỡng rõ ràng cho từng level.
- [ ] Logic tính streak/badge test được độc lập với input là lịch sử task/Pomodoro.

## Blocked by

- Blocked by `.claude/wiki/issues/002-task-creation-gemini-nlp-parse.md`
- Blocked by `.claude/wiki/issues/006-pomodoro-timer.md`
- Blocked by `.claude/wiki/issues/008-daily-reflection-generation.md`

## Decision Log sections addressed

- Scope discipline framework MVP
