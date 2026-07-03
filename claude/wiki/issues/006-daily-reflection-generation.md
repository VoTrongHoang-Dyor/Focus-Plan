---
status: todo
---

## Parent Decision Log

`claude/wiki/decisions/focus-scheduler-decision-log.md`

## What to build

Daily Reflection: sinh tóm tắt cuối ngày chỉ dựa trên dữ liệu khách quan (task done/missed/late, thời lượng Pomodoro thực tế). Gộp chung vào cùng 1 lần gọi Edge Function với cron 9h sáng (issue 005) — prompt Gemini phải tách rõ 2 phần output (reschedule + reflection).

## Acceptance criteria

- [ ] Reflection chỉ dùng dữ liệu khách quan đã lưu (không có journal/note tự do — defer sang v2).
- [ ] Cùng 1 lệnh gọi Edge Function với 005 trả về cả phần reschedule và phần reflection, tách rõ ràng.
- [ ] Privacy policy có disclose việc dùng Gemini free tier (Google có thể dùng data train model).
- [ ] Reflection hiển thị được trong app cho user xem lại.

## Blocked by

- Blocked by `claude/wiki/issues/005-9am-reschedule-cron.md`

## Decision Log sections addressed

- Daily Reflection (bổ sung)
- Chi phí AI
