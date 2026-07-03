---
status: todo
---

## Parent Decision Log

`.claude/wiki/decisions/focus-scheduler-decision-log.md`

## What to build

Daily Reflection: sinh tóm tắt cuối ngày chỉ dựa trên dữ liệu khách quan (task done/missed/late, thời lượng Pomodoro thực tế lấy từ Pomodoro Timer module — issue 006). Gộp chung vào cùng 1 lần gọi Edge Function với cron 9h sáng (issue 007) — prompt Gemini phải tách rõ 2 phần output (reschedule + reflection).

## Acceptance criteria

- [ ] Reflection chỉ dùng dữ liệu khách quan đã lưu (không có journal/note tự do — defer sang v2).
- [ ] Thời lượng Pomodoro trong reflection lấy từ dữ liệu phiên thật do Pomodoro Timer (issue 006) ghi lại — không phải giá trị giả định/placeholder.
- [ ] Cùng 1 lệnh gọi Edge Function với 007 trả về cả phần reschedule và phần reflection, tách rõ ràng.
- [ ] Privacy policy có disclose việc dùng Gemini free tier (Google có thể dùng data train model).
- [ ] Reflection hiển thị được trong app cho user xem lại.

## Blocked by

- Blocked by `.claude/wiki/issues/006-pomodoro-timer.md`
- Blocked by `.claude/wiki/issues/007-9am-reschedule-cron.md`

## Decision Log sections addressed

- Daily Reflection (bổ sung)
- Chi phí AI
