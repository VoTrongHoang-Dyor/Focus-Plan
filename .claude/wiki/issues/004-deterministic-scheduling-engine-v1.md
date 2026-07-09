---
status: done
---

## Parent Decision Log

`.claude/wiki/decisions/focus-scheduler-decision-log.md`

## What to build

Deterministic scheduling engine v1: rule-based (không LLM) xếp task đã tạo vào slot rảnh trong ngày, dựa trên priority, energy-matching tĩnh (buổi sáng ưu tiên deep work, khung giờ khác theo rule cố định), buffer giữa các block, và busy-block từ Habit/Routine Tracking (issue 003) để không xếp task đè lên khung giờ habit cố định.

## Acceptance criteria

- [x] Cho một danh sách task với priority + thời lượng ước tính, engine trả về lịch xếp slot cụ thể trong ngày.
- [x] Rule energy-matching tĩnh được áp dụng nhất quán (không đổi giữa các lần chạy với cùng input).
- [x] Buffer giữa các block được chèn theo rule cố định, không nhồi task sát nhau.
- [x] Engine nhận danh sách busy-block từ Habit module (issue 003) và không xếp task nào đè lên khung giờ đó.
- [x] Engine test được độc lập (input task list + busy-block list → output schedule), không phụ thuộc UI hay network call.

## QA / verify (2026-07-05)

- Implement theo plan `docs/superpowers/plans/2026-07-05-deterministic-scheduling-engine-v1.md`, 6 task TDD.
- **Design (user chốt):** energy-matching suy từ field `TaskType` deep/shallow mới (lan DB → model → Gemini → form), không suy ngầm từ priority. Khung ngày **08:00–22:00**, buffer cố định **10 phút**.
- **Engine:** `FocusPlan/Sources/Services/SchedulingEngine.swift` — hàm thuần `schedule(tasks:busyBlocks:on:calendar:config:)` → `ScheduleResult{scheduled, unscheduled}`. Greedy earliest-fit, sort total-order deterministic (`energyOrder → priority.sortRank → duration desc → createdAt → id.uuidString`), né busy-block (`BusyBlock` issue 003), buffer giữa task, overflow → unscheduled. KHÔNG LLM.
- Reviewer PASS (soi thuật toán + verify): 0 Critical, 0 Important. Full suite `** TEST SUCCEEDED **` — 17 unit (SchedulingEngineTests 5/5 phủ 5 criteria + overflow) + 5 UITest, 0 hồi quy issue 002/003.
- Cột DB `task_type` (default `shallow`, check `in (deep,shallow)`) đã áp remote `public.tasks` (ALTER idempotent). Edge Function `parse-task` redeploy suy `task_type` (chưa smoke live do Gemini quota `limit:0`).
- Commits: `9a29055` (TaskType+models), `02241e9` (engine), `88ecdfa` (cột DB), `5fa0515` (parse-task), `a61e63f` (form picker).

## Backlog (Nit từ reviewer — không chặn, tùy chọn sau)

- Bổ sung test hồi quy edge-case cho engine: `estimatedMinutes = nil` → default 30'; busy-block phân mảnh khiến không đủ khe; busy-block chồng lấn. (Thuật toán đã xử lý đúng, chỉ thiếu test chốt.)
- Test helper `task()` trong `SchedulingEngineTests.swift` suy UUID từ `abs(name.hashValue)` — `String.hashValue` random theo process + rủi ro `abs(Int.min)` trap; nên dùng UUID cố định. Cosmetic, test-only.
- **Chưa wire engine vào UI "Today"** — criteria chỉ yêu cầu engine test độc lập; hiển thị lịch xếp là slice sau.

## Blocked by

- Blocked by `.claude/wiki/issues/002-task-creation-gemini-nlp-parse.md`
- Blocked by `.claude/wiki/issues/003-habit-routine-tracking.md`

## Decision Log sections addressed

- Logic tìm slot trống
