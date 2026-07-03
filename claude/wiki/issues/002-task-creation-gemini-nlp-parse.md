---
status: todo
---

## Parent Decision Log

`claude/wiki/decisions/focus-scheduler-decision-log.md`

## What to build

Cho phép user tạo/sửa task bằng ngôn ngữ tự nhiên; Gemini 2.0 Flash chỉ làm nhiệm vụ NLP parse input thành dữ liệu task có cấu trúc (tên, thời lượng ước tính, priority, deadline nếu có) — không giao reasoning/constraint-solving cho LLM.

## Acceptance criteria

- [ ] User nhập task bằng câu tự nhiên (vd "Học tiếng Trung 30 phút tối nay") → Gemini parse ra task có cấu trúc lưu vào Supabase.
- [ ] User xem được, sửa được, xoá được task đã tạo.
- [ ] Trường hợp Gemini parse sai/không chắc chắn có đường xử lý (yêu cầu user xác nhận/sửa trước khi lưu) — không tự ý lưu dữ liệu sai mà không cho user thấy.
- [ ] Task được gắn với user hiện tại (multi-user, không rò dữ liệu chéo user).

## Blocked by

- Blocked by `claude/wiki/issues/001-ios-app-shell-supabase-auth.md`

## Decision Log sections addressed

- Logic tìm slot trống (vai trò Gemini)
