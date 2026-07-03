# Kiến trúc tổng thể

## Tổng quan

## Cấu trúc thư mục

- `CLAUDE.md` — hướng dẫn hành vi chung (7 quy tắc): tư duy trước khi code, tối giản, thay đổi phẫu thuật, thực thi theo mục tiêu, kiểm tra cwd trước `cd`, luôn trả lời tiếng Việt, và Second Brain wiki schema (mục 7).
- `claude/` — workspace Claude Code:
  - `agents/` — persona cho Agent Teams: `leader.md`, `coder.md`, `reviewer.md`, `librarian.md`.
  - `commands/` — slash command tuỳ biến: `team.md`.
  - `plans/` — plan đang lưu: `plan.md`.
  - `skills/` — skill nội bộ: `grill-me` (hỏi xoáy plan/ý tưởng), `improve-codebase-architecture`, `prd-to-issues`, `write-a-prd`, `tdd`.
  - `settings.local.json` — permissions cục bộ (`bypassPermissions`, deny các lệnh git/rm phá hoại).
  - `wiki/` — Second Brain, đồng thời là vault Obsidian này.
- `setup/` — prompt gốc dùng để bootstrap:
  - `prompt_1.md` — setup statusline hiển thị token count.
  - `prompt_2.md` — pattern "LLM Wiki" / second brain — nguồn gốc ý tưởng của schema ở `CLAUDE.md` §7.

## Ghi chú

- Vault Obsidian root = chính thư mục `wiki/` này (`.obsidian/` nằm trực tiếp bên trong, không lồng qua thư mục con `obsidian/` như trước).
- Root `README.md` có ghi chú của user: cần cài plugin Dataview cho Obsidian qua `obsidian://show-plugin?id=dataview` (dùng cho query Active PRD bên dưới).

## PRD đang Active

```dataview
TABLE status, date
FROM "prd"
WHERE status = "Active"
SORT date DESC
```

## Kanban (issues)

```dataview
TABLE status
FROM "issues"
SORT status ASC, file.name ASC
```
