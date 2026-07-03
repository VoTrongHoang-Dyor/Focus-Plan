---
status: todo
---

## Parent Decision Log

`claude/wiki/decisions/focus-scheduler-decision-log.md`

## What to build

Khi 2 task tranh 1 slot, ngoài việc engine (issue 003) chọn theo priority, Gemini sinh thêm 1 câu giải thích ngắn bằng ngôn ngữ tự nhiên tại sao task A thắng task B (dùng chung path Gemini đã có cho giải thích reschedule).

## Acceptance criteria

- [ ] Khi engine phát hiện xung đột slot, có ghi lại task thắng/thua và lý do (priority, thời lượng, v.v.).
- [ ] Gemini nhận thông tin xung đột này và sinh 1 câu giải thích ngắn, hiển thị được trong UI.
- [ ] Không có xung đột thì không sinh giải thích thừa (chỉ kích hoạt khi thực sự có tranh chấp slot).

## Blocked by

- Blocked by `claude/wiki/issues/003-deterministic-scheduling-engine-v1.md`

## Decision Log sections addressed

- Brainstorm A.3
