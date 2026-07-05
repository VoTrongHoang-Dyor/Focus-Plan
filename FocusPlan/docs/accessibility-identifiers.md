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

## Loại XCUIElement thật của từng identifier (quan sát iPhone 17 Pro / iOS 26)

Đo bằng `A11yIdentifierUITests`. MCP driver (issue 020) query theo đúng loại dưới đây;
mọi identifier đều tra cứu được qua `descendants(matching:.any).matching(identifier:)`.

| Identifier | XCUIElement type | Query |
|---|---|---|
| `signin/signup.email-field` | textField | `app.textFields[id]` |
| `signin/signup.password-field`, `signup.confirm-password-field` | secureTextField | `app.secureTextFields[id]` |
| `*.submit-button`, `*.go-to-*-button`, `*.add-button`, `*.parse-button`, `*.cancel-button`, `*.save-button`, `home.sign-out-button` | button | `app.buttons[id]` |
| `home.greeting-text`, `tasklist.empty-state` | staticText | `app.staticTexts[id]` |
| `tasklist.row.{uuid}` | button (row) | `app.buttons[id]` |
| `addtask.input-field` | textField (dù là `TextField(axis:.vertical)`) | `app.textFields[id]` |
| `taskform.name-field`, `taskform.minutes-field` | textField | `app.textFields[id]` |
| `taskform.priority-picker`, `taskform.tasktype-picker` | segmentedControl | `app.segmentedControls[id]`; tap segment con theo label |
| `taskform.deadline-toggle` | switch | `app.switches[id]` |
| `taskform.deadline-picker` | datePicker | `app.datePickers[id]` |

Lưu ý cho automation: nút "+" thêm task (`tasklist.add-button`) thỉnh thoảng cần tap lại
(sheet không mở lần đầu) — nên retry mở sheet + chờ `addtask.parse-button` xuất hiện.

## MCP control (issue 020)

AI agent điều khiển app qua các identifier trên bằng MCP server `tools/focusplan-mcp/`
(bridge sang XCUITest driver). Cách chạy + danh sách tool: `tools/focusplan-mcp/README.md`.
E2E proof (sign in → tạo task hoàn toàn qua MCP): `tools/focusplan-mcp/e2e-proof.mjs`.

Quy tắc bắt buộc cho driver/agent: mọi thao tác lên control APP dùng identifier
(`tap`/`type_text`/`read_element`/`wait_for`). Tool `tap_system_dialog` là escape hatch
CHỈ cho UI hệ điều hành (vd "Lưu mật khẩu?" → "Để sau") — cấm dùng cho control trong app.
