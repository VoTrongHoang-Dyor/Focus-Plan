---
status: todo
---

## Parent Decision Log

`claude/wiki/decisions/focus-scheduler-decision-log.md`

## What to build

Tinh chỉnh prompt/copy của Gemini (dùng trong reschedule + reflection) để lồng ghép philosophy (Ngộ nhận Cân bằng/Tranh thủ, Info Diet, Fasting, Vietnam Airlines mindset) dưới dạng ngôn ngữ/copy — không build UI riêng cho các khái niệm này.

## Acceptance criteria

- [ ] Output reschedule/reflection có giọng điệu/copy phản ánh các philosophy đã chọn, không chỉ là text thuần thông báo.
- [ ] Không có màn hình/UI riêng nào được build chỉ để giải thích philosophy — chỉ nằm trong prompt và output text.
- [ ] Prompt có thể điều chỉnh/tune riêng biệt với logic reschedule/reflection (tách biệt concern).

## Blocked by

- Blocked by `claude/wiki/issues/005-9am-reschedule-cron.md`
- Blocked by `claude/wiki/issues/006-daily-reflection-generation.md`

## Decision Log sections addressed

- Scope discipline framework MVP (mục ẩn dưới dạng philosophy)
