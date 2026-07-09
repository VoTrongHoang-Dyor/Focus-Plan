---
status: done
---

## Parent Decision Log

`.claude/wiki/decisions/focus-scheduler-decision-log.md`

## What to build

Cho phép user tạo/sửa task bằng ngôn ngữ tự nhiên; Gemini 2.0 Flash chỉ làm nhiệm vụ NLP parse input thành dữ liệu task có cấu trúc (tên, thời lượng ước tính, priority, deadline nếu có) — không giao reasoning/constraint-solving cho LLM.

## Acceptance criteria

- [x] User nhập task bằng câu tự nhiên (vd "Học tiếng Trung 30 phút tối nay") → Gemini parse ra task có cấu trúc lưu vào Supabase.
- [x] User xem được, sửa được, xoá được task đã tạo.
- [x] Trường hợp Gemini parse sai/không chắc chắn có đường xử lý (yêu cầu user xác nhận/sửa trước khi lưu) — không tự ý lưu dữ liệu sai mà không cho user thấy.
- [x] Task được gắn với user hiện tại (multi-user, không rò dữ liệu chéo user).

## QA / verify (2026-07-05)

- Implement theo plan `docs/superpowers/plans/2026-07-03-task-creation-gemini-nlp-parse.md`: SwiftUI + supabase-swift. App gọi Edge Function `parse-task` (Gemini 2.0 Flash structured output, `verify_jwt` bật, key server-side) → `ParsedTaskDraft` → **luôn** qua màn confirm (`TaskFormView`) → insert bảng `tasks`. RLS 4 policy `auth.uid() = user_id`.
- Reviewer PASS 2 vòng. Full test suite `** TEST SUCCEEDED **`: 10 unit + 5 XCUITest (0 skip) trên iPhone 17 sim + Supabase thật.
  - `test_naturalLanguageParse_createsTask` (criteria 1+3): NL input → confirm prefill → save. Phần Gemini **mock qua test-seam env-gated** (`UITEST_MOCK_PARSE_DRAFT`), đường save Supabase THẬT.
  - `test_taskList_isolatedBetweenUsers` (criteria 4): chứng minh user B không thấy task user A (RLS enforcement).
- Edge Function `parse-task` deployed ACTIVE + cap input length (`text > 1000` → 400) chống phồng token cost.
- **Ràng buộc còn mở:** Gemini LIVE chưa QA end-to-end do API key hết quota (`limit: 0`, billing chưa bật) — seam mock giúp test độc lập quota. Khi bật billing nên chạy 1 pass QA thủ công qua Gemini thật.
- Commits chính session verify: `fe155d2` (E2E mock seam+test), `06d3624` (cap input), `032d87f` (isolation test). HabitFlow test-harness fix (issue 003): `9633859`.

## Blocked by

- Blocked by `.claude/wiki/issues/001-ios-app-shell-supabase-auth.md`

## Decision Log sections addressed

- Logic tìm slot trống (vai trò Gemini)
