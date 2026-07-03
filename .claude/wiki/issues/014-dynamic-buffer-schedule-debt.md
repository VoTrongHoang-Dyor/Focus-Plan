---
status: todo
---

## Parent Decision Log

`.claude/wiki/decisions/focus-scheduler-decision-log.md`

## What to build

Buffer động theo "nợ lịch" (schedule debt): nếu tỷ lệ task bị dời trong ngày vượt ngưỡng (vd >30%), engine tự nới buffer giữa các block ngày hôm sau thay vì nhồi nhét.

## Acceptance criteria

- [ ] Engine tính được tỷ lệ task bị dời/reschedule trong một ngày từ dữ liệu đã lưu.
- [ ] Khi tỷ lệ vượt ngưỡng đã định, buffer giữa các block ngày kế tiếp tăng theo rule rõ ràng (không tuỳ tiện).
- [ ] Ngưỡng và mức tăng buffer là tham số có thể điều chỉnh (không hardcode cứng trong logic).

## Blocked by

- Blocked by `.claude/wiki/issues/004-deterministic-scheduling-engine-v1.md`
- Blocked by `.claude/wiki/issues/008-daily-reflection-generation.md`

## Decision Log sections addressed

- Brainstorm A.2
