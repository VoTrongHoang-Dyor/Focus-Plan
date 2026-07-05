# Accessibility Identifier Convention

Mục tiêu: AI agent (MCP server, issue 020) và automation tester tra cứu control theo
identifier ổn định, TỰ MÔ TẢ — đoán được ngữ nghĩa từ tên mà không cần đọc tài liệu.

## Quy tắc

- Format: `{screen}.{element}-{type}` — lowercase, kebab-case.
  - `screen`: signin, signup, home, tasklist, addtask, taskform (thêm màn mới → thêm prefix mới, vd `alarmform`).
  - `type` suffix: `-field` (nhập liệu), `-button`, `-toggle`, `-picker`, `-text` (chỉ đọc), `-state` (empty/loading).
- Phần tử động (hàng trong list): `{screen}.row.{uuid}` — uuid là id thật của entity.
- Nguồn sự thật DUY NHẤT: `FocusPlan/Sources/Support/A11yID.swift`. View không hardcode chuỗi.
- UITest target không link app module → test dùng literal string, phải khớp `A11yID` từng ký tự.
- Identifier là lớp BỔ SUNG cho automation — KHÔNG thay thế `accessibilityLabel`
  (label tiếng Việt phục vụ VoiceOver/UITest cũ, giữ nguyên).
- Picker segmented: identifier đặt ở container; segment con tap theo label hiển thị
  (vd "Thấp"/"Trung bình"/"Cao") — ghi chú này quan trọng cho MCP driver.
- Màn mới (AlarmFormView...) BẮT BUỘC phủ identifier theo convention này ngay khi tạo.
