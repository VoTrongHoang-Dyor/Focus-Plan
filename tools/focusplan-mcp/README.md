# focusplan-mcp

MCP server (stdio) điều khiển app **FocusPlan** trên iOS Simulator qua accessibilityIdentifier
(issue 019). Bridge sang một XCUITest driver (`FocusPlanMcpDriver`) mở HTTP loopback
`127.0.0.1:8931` trong tiến trình test runner rồi thực thi lệnh lên `XCUIApplication`.
App production KHÔNG chứa code command channel — chỉ điều khiển qua accessibility.

## Yêu cầu

- macOS + Xcode + iOS Simulator "iPhone 17 Pro" (đổi tên qua tham số `driver_start`).
- Node ≥ 18 (test với v22).
- `npm install` trong thư mục này.

## Chạy

Driver có thể tự khởi động qua tool `driver_start`, hoặc chạy tay:

```bash
# (tuỳ chọn) chạy driver tay — giữ terminal này sống:
TEST_RUNNER_MCP_DRIVER=1 xcodebuild \
  -project ../../FocusPlan/FocusPlan.xcodeproj -scheme FocusPlanMcpDriver \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
```

Đăng ký MCP server với Claude Code:

```bash
claude mcp add focusplan -- node <repo>/tools/focusplan-mcp/index.mjs
```

E2E proof (tự spawn driver, chạy flow thật sign in → tạo task hoàn toàn qua MCP):

```bash
node e2e-proof.mjs
```

## Tools (stdio, chuẩn MCP)

| Tool | Mô tả |
|---|---|
| `driver_start {simulator?}` | Spawn `xcodebuild` scheme driver, chờ HTTP bridge sẵn sàng. |
| `driver_status` | Kiểm tra driver reachable. |
| `app_launch {env?}` | Mở app; `env` merge vào launchEnvironment (vd `UITEST_MOCK_PARSE_DRAFT`). |
| `screen_elements` | Liệt kê element có identifier `{identifier,type,label,value,enabled,hittable}`. |
| `tap {id}` | Tap control theo identifier. |
| `type_text {id,text,paste?}` | Nhập text; `paste:true` cho secure field / tiếng Việt. |
| `read_element {id}` | Đọc label/value/type. |
| `wait_for {id,timeoutSeconds?}` | Chờ element xuất hiện. |
| `tap_system_dialog {label}` | **Escape hatch** — CHỈ cho dialog hệ điều hành (vd "Để sau"). |

Lỗi (identifier sai / không tap được / timeout / bad request) trả về `isError: true`
với message nguyên văn từ driver → agent tự sửa hướng.

## Quy ước identifier

Xem `FocusPlan/docs/accessibility-identifiers.md` — convention `{screen}.{element}-{type}`,
hàng động `{screen}.row.{uuid}`, kèm bảng loại XCUIElement thật của từng identifier.

**Quan trọng:** mọi thao tác lên control APP phải dùng identifier (`tap`/`type_text`/...).
`tap_system_dialog` chỉ dành cho UI của hệ điều hành, KHÔNG dùng cho control trong app.
