---
status: done
---

## Parent PRD

`.claude/wiki/prd/focusplan-swift-mascot-mcp-web.md`

## What to build

Custom MCP server (giao thức MCP chuẩn qua stdio) bridge sang XCUITest/accessibility tree để AI agent điều khiển app FocusPlan trên simulator như một automation tester. Bộ lệnh tối thiểu: liệt kê element màn hình hiện tại (identifier/loại/giá trị), tap theo identifier, nhập text theo identifier, đọc giá trị/label, chờ element xuất hiện. KHÔNG nhúng command channel (deep link/HTTP/WebSocket) vào app. Khởi động được bằng 1 lệnh từ máy dev có Xcode.

## Acceptance criteria

- [x] MCP server khởi động bằng 1 lệnh, expose bộ lệnh tối thiểu (list/tap/type/read/wait) qua stdio đúng chuẩn MCP.
- [x] Mỗi lệnh trả kết quả có cấu trúc; identifier sai/element không tồn tại → error message rõ ràng (agent tự sửa hướng được, không kẹt im lặng).
- [x] E2E proof: một agent (hoặc script mô phỏng agent) chạy flow THẬT hoàn toàn qua lệnh MCP — mở app → sign in → tạo task → thấy task trong list — không can thiệp tay.
- [x] App production không đổi hành vi (không thêm code runtime nào vào app target ngoài identifier đã có từ issue 019).

## Blocked by

- Blocked by `.claude/wiki/issues/019-accessibility-identifiers-core-flows.md`

## User stories addressed

- User story 1 (MCP server expose lệnh thao tác)
- User story 3 (đọc cấu trúc màn hình)
- User story 4 (khởi động 1 lệnh)
- User story 5 (error message rõ)
- User story 18 (E2E qua auth)
