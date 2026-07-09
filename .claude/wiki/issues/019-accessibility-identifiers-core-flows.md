---
status: done
---

## Parent PRD

`.claude/wiki/prd/focusplan-swift-mascot-mcp-web.md`

## What to build

Phủ `accessibilityIdentifier` chuẩn hoá, tự mô tả, ổn định cho toàn bộ control thuộc core flows HIỆN CÓ của app Swift (auth: sign in / sign up / sign out; task: list / add / confirm-form) + tài liệu hoá naming convention ngắn gọn để mọi UI sau này (AlarmFormView, v.v.) theo cùng chuẩn. Đây là nền cho MCP control (issue 020) — mục tiêu "AI đoán được cách thao tác mà không cần đọc doc".

## Acceptance criteria

- [x] Mọi control tương tác trong flow auth (email/password field, nút đăng nhập/đăng ký/đăng xuất, link chuyển màn) và flow task (nút thêm, ô nhập câu tự nhiên, nút Phân tích, các field/toggle/nút trong form xác nhận, hàng task trong list) có `accessibilityIdentifier` theo naming convention thống nhất.
- [x] Naming convention được định nghĩa tập trung trong code (hằng số, không magic string rải rác) + tài liệu ngắn mô tả quy tắc đặt tên.
- [x] Có XCUITest chứng minh các control tra cứu được theo identifier (query by identifier thành công trên các màn core).
- [x] Toàn bộ test suite hiện có vẫn xanh (`** TEST SUCCEEDED **`) — không phá `accessibilityLabel` tiếng Việt đang được UITest cũ dùng.

## QA / verify (2026-07-05)

- Implement theo plan `docs/superpowers/plans/2026-07-05-accessibility-identifiers-core-flows.md`.
- **Chuẩn hóa:** `A11yID.swift` (enum hằng số duy nhất nguồn sự thật) + doc `FocusPlan/docs/accessibility-identifiers.md` ghi convention `{screen}.{element}-{type}` + bảng element-type khái niệm cho MCP.
- **Phủ:** 31 identifier trên 6 view core flows (SignIn, SignUp, Home, TaskList, TaskForm, AddTask). Thuần additive — không đề cập `accessibilityLabel` tiếng Việt cũ.
- **Reviewer PASS** (0 Critical, 0 Important) — full suite `** TEST SUCCEEDED **`: 26 unit + 6 UITest = **32** (thêm `A11yIdentifierUITests` — thao tác hoàn toàn qua identifier, không hard-code XPath/coordinate).
- **Commits:** `36f4b93`, `51d1384`, `32c7b89`, `2773edc`.

## Backlog (Nit từ reviewer — không chặn)

- Test chưa exercise vài identifier có điều kiện/động: `taskform.note/error-text` (show khi user type), `deadline-picker` (tap để reveal), `signin/signup.error-text`, `signup.info-text` (show khi validate fail), `tasklist.row.{uuid}` (cần seed task để iterate rows).
- Day chips HomeView display-only chưa cần identifier; nhớ thêm nếu sau này tappable.

## Blocked by

None - can start immediately

## User stories addressed

- User story 2 (identifier ổn định + tự mô tả)
- User story 18 (auth flow thao tác được qua identifier)
- User story 20 (naming convention tài liệu hoá)
