# MCP Control Server (stdio) + XCUITest Bridge Implementation Plan

> **For agentic workers:** Coder thực thi task-by-task rồi bàn giao reviewer — KHÔNG tự dispatch subagent. Steps dùng checkbox (`- [ ]`).

**Goal:** AI agent kết nối MCP server (stdio) và điều khiển app FocusPlan trên simulator qua accessibilityIdentifier (issue 019): liệt kê element, tap, nhập text, đọc giá trị, chờ element — kèm E2E proof chạy flow thật (sign in → tạo task) hoàn toàn qua lệnh MCP.

**Architecture:** 2 tầng. (1) **Driver** = một XCUITest đặc biệt trong target/scheme RIÊNG (`FocusPlanMcpDriver`) — khi chạy, nó mở HTTP server loopback (Network.framework, port 8931) ngay trong tiến trình test runner và thực thi lệnh JSON lên `XCUIApplication` (mô hình WebDriverAgent thu nhỏ). (2) **MCP server** = Node.js stdio (`tools/focusplan-mcp/`) expose tools chuẩn MCP, forward lệnh qua HTTP tới driver; tool `driver_start` tự spawn `xcodebuild test` cho scheme driver → thoả "khởi động 1 lệnh". App production KHÔNG đổi (không thêm code nào vào app target).

**Tech Stack:** Swift/XCUITest + Network.framework (driver, không dependency mới), Node.js ≥18 + `@modelcontextprotocol/sdk` + `zod` (MCP server), Supabase REST (seed user cho E2E — pattern UITests có sẵn).

## Global Constraints

- **KHÔNG đụng app target** — driver nằm trong test bundle riêng; app chỉ được điều khiển qua accessibility (đúng Decision Log: không deep link/HTTP/WebSocket trong app).
- **Suite chính KHÔNG đổi:** scheme `FocusPlan` giữ đúng 2 test bundle cũ (FocusPlanTests + FocusPlanUITests) — 32 test hiện có phải xanh nguyên, 0 skip. Driver chạy bằng scheme riêng `FocusPlanMcpDriver`.
- **Mọi thao tác lên control APP đi qua identifier** (chuẩn `A11yID`/`FocusPlan/docs/accessibility-identifiers.md`). Ngoại lệ DUY NHẤT: dialog HỆ ĐIỀU HÀNH (vd "Lưu mật khẩu?" → "Để sau"/"Not Now") — cho phép lệnh `tap_label`, doc ghi rõ đây là escape hatch cho system UI, cấm dùng cho control app.
- **Error rõ ràng:** identifier không tồn tại/không tap được → response `{ok:false, error:"..."}` mô tả đúng nguyên nhân (agent tự sửa hướng).
- **Gemini quota vẫn chết** → E2E dùng seam `UITEST_MOCK_PARSE_DRAFT` có sẵn (driver hỗ trợ launch app kèm env).
- Port driver: `8931` (override bằng env `MCP_DRIVER_PORT`). Loopback only (`127.0.0.1`).
- Env truyền vào test runner qua prefix `TEST_RUNNER_` của xcodebuild (vd `TEST_RUNNER_MCP_DRIVER=1`).
- Node package KHÔNG commit `node_modules` (thêm `.gitignore`). Không commit secret (Supabase anon key là public — được phép như UITests).
- Sim: iPhone 17 Pro (đổi nếu tên khác). LƯU Ý API: chữ ký `@modelcontextprotocol/sdk` và Network.framework verify với bản thật; giữ nguyên HÀNH VI đã đặc tả nếu phải chỉnh cú pháp.

## File Structure

```
FocusPlan/
├── project.yml                                # (modify) + target FocusPlanMcpDriver + schemes tường minh
└── McpDriver/
    ├── McpDriverTests.swift                   # (create) entry: giữ server sống trong 1 test
    └── DriverServer.swift                     # (create) HTTP loopback + dispatch lệnh XCUITest

tools/focusplan-mcp/
├── package.json                               # (create) deps: @modelcontextprotocol/sdk, zod
├── .gitignore                                 # (create) node_modules
├── index.mjs                                  # (create) MCP server stdio: tools + forward HTTP + driver_start
├── e2e-proof.mjs                              # (create) MCP client: flow sign in → tạo task qua MCP
└── README.md                                  # (create) cách chạy + đăng ký với agent
```

---

### Task 1: Target + scheme riêng cho driver (project.yml) + skeleton

**Files:**
- Modify: `FocusPlan/project.yml`
- Create: `FocusPlan/McpDriver/McpDriverTests.swift`

**Interfaces:**
- Produces: scheme `FocusPlanMcpDriver` chạy được độc lập; scheme `FocusPlan` giữ nguyên 2 test bundle cũ.

- [ ] **Step 1: Sửa `project.yml`** — thêm target + định nghĩa schemes tường minh (vì thêm target UI-test mới mà không định nghĩa scheme, XcodeGen có thể auto-gộp nó vào scheme app → phá suite chính):

```yaml
# thêm vào mục targets:
  FocusPlanMcpDriver:
    type: bundle.ui-testing
    platform: iOS
    sources:
      - path: McpDriver
    settings:
      base:
        GENERATE_INFOPLIST_FILE: "YES"
        TEST_TARGET_NAME: FocusPlan
    dependencies:
      - target: FocusPlan

# thêm mục schemes (cùng cấp targets):
schemes:
  FocusPlan:
    build:
      targets:
        FocusPlan: all
    test:
      targets:
        - FocusPlanTests
        - FocusPlanUITests
  FocusPlanMcpDriver:
    build:
      targets:
        FocusPlan: all
    test:
      targets:
        - FocusPlanMcpDriver
```

- [ ] **Step 2: Skeleton `McpDriverTests.swift`**

```swift
import XCTest

/// KHÔNG phải test thường — đây là entry giữ DriverServer sống để MCP server điều khiển app.
/// Chỉ chạy khi TEST_RUNNER_MCP_DRIVER=1 (qua scheme FocusPlanMcpDriver). An toàn kép:
/// nếu lọt vào suite khác sẽ skip.
final class McpDriverTests: XCTestCase {
    func test_runDriver() throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["MCP_DRIVER"] == "1",
                          "MCP driver only (set TEST_RUNNER_MCP_DRIVER=1)")
        let port = UInt16(ProcessInfo.processInfo.environment["MCP_DRIVER_PORT"] ?? "") ?? 8931
        let server = DriverServer(port: port)
        try server.start()
        // Giữ test runner sống vô hạn — main runloop phục vụ cả DispatchQueue.main.
        while true { RunLoop.current.run(mode: .default, before: .distantFuture) }
    }
}
```
(Task 2 mới tạo `DriverServer` — để build xanh ở task này, tạo luôn file `DriverServer.swift` với stub `final class DriverServer { init(port: UInt16) {}; func start() throws {} }`, thay thật ở Task 2.)

- [ ] **Step 3: Verify scheme tách đúng**

```bash
cd FocusPlan && xcodegen generate
xcodebuild -project FocusPlan.xcodeproj -list          # thấy 2 scheme: FocusPlan, FocusPlanMcpDriver
xcodebuild -project FocusPlan.xcodeproj -scheme FocusPlan \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
```
Expected: `-list` có 2 scheme; suite chính vẫn `** TEST SUCCEEDED **` với đúng 32 test, KHÔNG có McpDriverTests trong log.

- [ ] **Step 4: Commit**

```bash
git add FocusPlan/project.yml FocusPlan/McpDriver/
git commit -m "feat(mcp): dedicated FocusPlanMcpDriver UITest target/scheme (skeleton)"
```

---

### Task 2: DriverServer — HTTP loopback thực thi lệnh XCUITest

**Files:**
- Create (thay stub): `FocusPlan/McpDriver/DriverServer.swift`

**Interfaces:**
- Produces: HTTP `POST /command` body JSON → response JSON. Actions:
  - `{"action":"status"}` → `{ok:true, state:"ready"}`
  - `{"action":"launch","env":{...}}` → launch app với `launchEnvironment` (merge), trả ok
  - `{"action":"elements"}` → `{ok:true, elements:[{identifier,type,label,value,enabled,hittable}]}` (mọi element có identifier ≠ "", cap 200)
  - `{"action":"tap","id":"..."}` / `{"action":"tap_label","label":"..."}` (chỉ cho system dialog)
  - `{"action":"type","id":"...","text":"...","paste":true|false}` (paste=true dùng UIPasteboard + menu Paste — cần cho secure field & tiếng Việt)
  - `{"action":"read","id":"..."}` → `{ok:true, element:{...}}`
  - `{"action":"wait","id":"...","timeout":10}` → ok khi element xuất hiện, `{ok:false,error:"timeout waiting for <id>"}` nếu không
  - Mọi lỗi: `{ok:false, error:"<mô tả: not found / not hittable / bad request>"}`

- [ ] **Step 1: Viết `DriverServer.swift`**

```swift
import Foundation
import Network
import XCTest

final class DriverServer {
    private let port: UInt16
    private var listener: NWListener?
    private let app = XCUIApplication(bundleIdentifier: "com.votronghoang.focusplan")

    init(port: UInt16) { self.port = port }

    func start() throws {
        let params = NWParameters.tcp
        params.requiredLocalEndpoint = NWEndpoint.hostPort(host: "127.0.0.1",
                                                           port: NWEndpoint.Port(rawValue: port)!)
        let l = try NWListener(using: params)
        l.newConnectionHandler = { [weak self] conn in self?.handle(conn) }
        l.start(queue: DispatchQueue(label: "mcp.driver.listener"))
        listener = l
        NSLog("[MCPDriver] listening on 127.0.0.1:\(port)")
    }

    private func handle(_ conn: NWConnection) {
        conn.start(queue: DispatchQueue(label: "mcp.driver.conn"))
        receiveRequest(conn, buffer: Data())
    }

    /// Đọc tới khi đủ headers + Content-Length body (HTTP/1.1 tối giản, mỗi connection 1 request).
    private func receiveRequest(_ conn: NWConnection, buffer: Data) {
        conn.receive(minimumIncompleteLength: 1, maximumLength: 1 << 16) { [weak self] data, _, _, error in
            guard let self, error == nil, let data, !data.isEmpty else { conn.cancel(); return }
            var buf = buffer; buf.append(data)
            guard let headerEnd = buf.range(of: Data("\r\n\r\n".utf8)) else {
                self.receiveRequest(conn, buffer: buf); return
            }
            let headerData = buf[..<headerEnd.lowerBound]
            let headers = String(decoding: headerData, as: UTF8.self)
            let contentLength = headers.split(separator: "\r\n")
                .first { $0.lowercased().hasPrefix("content-length:") }
                .flatMap { Int($0.split(separator: ":")[1].trimmingCharacters(in: .whitespaces)) } ?? 0
            let bodyStart = headerEnd.upperBound
            if buf.count - bodyStart.utf8Offset(in: buf) < contentLength {
                self.receiveRequest(conn, buffer: buf); return
            }
            let body = buf.subdata(in: bodyStart..<buf.index(bodyStart, offsetBy: contentLength))
            // XCUITest API phải chạy trên main thread của test runner.
            DispatchQueue.main.async {
                let responseJSON = self.dispatch(body: body)
                self.send(conn, json: responseJSON)
            }
        }
    }
    // Helper offset (Data.Index là Int-based): dùng trực tiếp Int nếu compiler cho phép;
    // LƯU Ý API: nếu Data.Index thao tác khác, chỉnh cú pháp nhưng giữ hành vi "đọc đủ Content-Length".

    private func send(_ conn: NWConnection, json: Data) {
        var resp = Data("HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: \(json.count)\r\nConnection: close\r\n\r\n".utf8)
        resp.append(json)
        conn.send(content: resp, completion: .contentProcessed { _ in conn.cancel() })
    }

    // MARK: - Command dispatch (chạy trên main thread)

    private func dispatch(body: Data) -> Data {
        guard let cmd = try? JSONSerialization.jsonObject(with: body) as? [String: Any],
              let action = cmd["action"] as? String else {
            return encode(["ok": false, "error": "bad request: body must be JSON {action,...}"])
        }
        switch action {
        case "status":
            return encode(["ok": true, "state": "ready"])
        case "launch":
            if let env = cmd["env"] as? [String: String] {
                for (k, v) in env { app.launchEnvironment[k] = v }
            }
            app.launch()
            return encode(["ok": true])
        case "elements":
            let els = app.descendants(matching: .any)
                .matching(NSPredicate(format: "identifier != ''"))
                .allElementsBoundByIndex.prefix(200)
                .map(describe)
            return encode(["ok": true, "elements": Array(els)])
        case "tap":
            guard let id = cmd["id"] as? String else { return encode(["ok": false, "error": "missing id"]) }
            let el = find(id)
            guard el.exists else { return encode(["ok": false, "error": "element not found: \(id)"]) }
            guard el.isHittable else { return encode(["ok": false, "error": "element not hittable: \(id)"]) }
            el.tap()
            return encode(["ok": true])
        case "tap_label": // CHỈ cho system dialog (vd "Để sau"). Không dùng cho control app.
            guard let label = cmd["label"] as? String else { return encode(["ok": false, "error": "missing label"]) }
            let btn = app.buttons[label].firstMatch
            guard btn.waitForExistence(timeout: 2) else { return encode(["ok": false, "error": "no button labeled: \(label)"]) }
            btn.tap()
            return encode(["ok": true])
        case "type":
            guard let id = cmd["id"] as? String, let text = cmd["text"] as? String else {
                return encode(["ok": false, "error": "missing id/text"])
            }
            let el = find(id)
            guard el.waitForExistence(timeout: 5) else { return encode(["ok": false, "error": "element not found: \(id)"]) }
            el.tap()
            if (cmd["paste"] as? Bool) == true {
                UIPasteboard.general.string = text
                el.press(forDuration: 1.3)
                let paste = app.menuItems["Paste"].firstMatch
                guard paste.waitForExistence(timeout: 5) else { return encode(["ok": false, "error": "paste menu not shown for: \(id)"]) }
                paste.tap()
            } else {
                el.typeText(text)
            }
            return encode(["ok": true])
        case "read":
            guard let id = cmd["id"] as? String else { return encode(["ok": false, "error": "missing id"]) }
            let el = find(id)
            guard el.exists else { return encode(["ok": false, "error": "element not found: \(id)"]) }
            return encode(["ok": true, "element": describe(el)])
        case "wait":
            guard let id = cmd["id"] as? String else { return encode(["ok": false, "error": "missing id"]) }
            let timeout = (cmd["timeout"] as? Double) ?? 10
            let el = find(id)
            return el.waitForExistence(timeout: timeout)
                ? encode(["ok": true, "element": describe(el)])
                : encode(["ok": false, "error": "timeout (\(Int(timeout))s) waiting for: \(id)"])
        default:
            return encode(["ok": false, "error": "unknown action: \(action)"])
        }
    }

    private func find(_ id: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: id).firstMatch
    }

    private func describe(_ el: XCUIElement) -> [String: Any] {
        [
            "identifier": el.identifier,
            "type": Self.typeName(el.elementType),
            "label": el.label,
            "value": String(describing: el.value ?? ""),
            "enabled": el.isEnabled,
            "hittable": el.isHittable,
        ]
    }

    private static func typeName(_ t: XCUIElement.ElementType) -> String {
        switch t {
        case .button: return "button"
        case .textField: return "textField"
        case .secureTextField: return "secureTextField"
        case .staticText: return "staticText"
        case .switch: return "switch"
        case .segmentedControl: return "segmentedControl"
        case .datePicker: return "datePicker"
        case .other: return "other"
        default: return "type#\(t.rawValue)"
        }
    }

    private func encode(_ obj: [String: Any]) -> Data {
        (try? JSONSerialization.data(withJSONObject: obj)) ?? Data("{\"ok\":false,\"error\":\"encode failure\"}".utf8)
    }
}
```
LƯU Ý API: các điểm cần verify với SDK thật — thao tác `Data.Index/range`, `NWListener` requiredLocalEndpoint, `matching(identifier:)`. Chỉnh cú pháp nếu lệch, GIỮ hành vi đặc tả ở Interfaces.

- [ ] **Step 2: Smoke driver bằng curl**

```bash
cd FocusPlan && xcodegen generate
TEST_RUNNER_MCP_DRIVER=1 xcodebuild -project FocusPlan.xcodeproj -scheme FocusPlanMcpDriver \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test &   # chạy nền, chờ "listening"
sleep 90   # lần đầu build lâu; hoặc poll
curl -s -X POST http://127.0.0.1:8931/command -d '{"action":"status"}'
curl -s -X POST http://127.0.0.1:8931/command -d '{"action":"launch","env":{}}'
curl -s -X POST http://127.0.0.1:8931/command -d '{"action":"elements"}'
curl -s -X POST http://127.0.0.1:8931/command -d '{"action":"tap","id":"khong-ton-tai"}'
```
Expected: status ok; launch ok (app mở trên sim); elements trả danh sách identifier (thấy `signin.*` hoặc `home.*`); tap sai id → `{ok:false,error:"element not found: khong-ton-tai"}`. Xong thì kill xcodebuild.

- [ ] **Step 3: Commit**

```bash
git add FocusPlan/McpDriver/DriverServer.swift
git commit -m "feat(mcp): DriverServer executes JSON commands over loopback HTTP inside XCUITest"
```

---

### Task 3: MCP server Node (stdio) + README

**Files:**
- Create: `tools/focusplan-mcp/package.json`, `.gitignore`, `index.mjs`, `README.md`

**Interfaces:**
- Produces MCP tools (stdio): `driver_start {simulator?}`, `driver_status`, `app_launch {env?}`, `screen_elements`, `tap {id}`, `tap_system_dialog {label}`, `type_text {id, text, paste?}`, `read_element {id}`, `wait_for {id, timeoutSeconds?}`. Mỗi tool trả JSON text; lỗi driver → `isError` + message nguyên văn từ driver.

- [ ] **Step 1: `package.json` + `.gitignore`**

```json
{
  "name": "focusplan-mcp",
  "version": "0.1.0",
  "type": "module",
  "private": true,
  "dependencies": {
    "@modelcontextprotocol/sdk": "^1.0.0",
    "zod": "^3.23.0"
  }
}
```
`.gitignore`: `node_modules/`

- [ ] **Step 2: `index.mjs`**

```js
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";
import { spawn } from "node:child_process";
import path from "node:path";
import { fileURLToPath } from "node:url";

const PORT = process.env.MCP_DRIVER_PORT ?? "8931";
const BASE = `http://127.0.0.1:${PORT}/command`;
const REPO = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../..");
let driverProc = null;

async function command(body) {
  let res;
  try {
    res = await fetch(BASE, { method: "POST", body: JSON.stringify(body) });
  } catch {
    throw new Error("driver not reachable — run driver_start first (xcodebuild scheme FocusPlanMcpDriver)");
  }
  const json = await res.json();
  if (!json.ok) throw new Error(json.error ?? "driver error");
  return json;
}
const asText = (obj) => ({ content: [{ type: "text", text: JSON.stringify(obj) }] });
const asError = (e) => ({ isError: true, content: [{ type: "text", text: String(e.message ?? e) }] });
const run = (fn) => async (args) => { try { return asText(await fn(args ?? {})); } catch (e) { return asError(e); } };

const server = new McpServer({ name: "focusplan-mcp", version: "0.1.0" });

server.tool("driver_start",
  "Khởi động driver (xcodebuild UITest giữ HTTP bridge). Chờ tới khi sẵn sàng (~2-5 phút lần đầu).",
  { simulator: z.string().optional().describe("Tên simulator, mặc định iPhone 17 Pro") },
  run(async ({ simulator = "iPhone 17 Pro" }) => {
    if (driverProc && !driverProc.killed) return { started: "already-running" };
    driverProc = spawn("xcodebuild", [
      "-project", path.join(REPO, "FocusPlan/FocusPlan.xcodeproj"),
      "-scheme", "FocusPlanMcpDriver",
      "-destination", `platform=iOS Simulator,name=${simulator}`,
      "test",
    ], { env: { ...process.env, TEST_RUNNER_MCP_DRIVER: "1" }, stdio: "ignore", detached: false });
    const deadline = Date.now() + 300_000;
    while (Date.now() < deadline) {
      try { await command({ action: "status" }); return { started: true }; }
      catch { await new Promise((r) => setTimeout(r, 3000)); }
    }
    throw new Error("driver did not become ready within 5 minutes");
  }));

server.tool("driver_status", "Kiểm tra driver sẵn sàng chưa.", {}, run(() => command({ action: "status" })));
server.tool("app_launch", "Mở app FocusPlan (kèm env tuỳ chọn, vd UITEST_MOCK_PARSE_DRAFT).",
  { env: z.record(z.string()).optional() }, run(({ env }) => command({ action: "launch", env })));
server.tool("screen_elements", "Liệt kê element có accessibilityIdentifier trên màn hiện tại.",
  {}, run(() => command({ action: "elements" })));
server.tool("tap", "Tap element theo accessibilityIdentifier.",
  { id: z.string() }, run(({ id }) => command({ action: "tap", id })));
server.tool("tap_system_dialog", "CHỈ cho dialog hệ điều hành (vd 'Để sau', 'Not Now') — không dùng cho control app.",
  { label: z.string() }, run(({ label }) => command({ action: "tap_label", label })));
server.tool("type_text", "Nhập text vào field theo identifier. paste=true cho secure field/tiếng Việt.",
  { id: z.string(), text: z.string(), paste: z.boolean().optional() },
  run(({ id, text, paste }) => command({ action: "type", id, text, paste })));
server.tool("read_element", "Đọc label/value/type của element theo identifier.",
  { id: z.string() }, run(({ id }) => command({ action: "read", id })));
server.tool("wait_for", "Chờ element xuất hiện.",
  { id: z.string(), timeoutSeconds: z.number().optional() },
  run(({ id, timeoutSeconds }) => command({ action: "wait", id, timeout: timeoutSeconds ?? 10 })));

await server.connect(new StdioServerTransport());
```
LƯU Ý API: chữ ký `server.tool(...)`/`McpServer` verify với version SDK cài thật (`registerTool`/schema shape có thể khác giữa version) — giữ nguyên danh sách tool + hành vi.

- [ ] **Step 3: `README.md`** — ghi: yêu cầu (macOS + Xcode + sim + Node ≥18, `npm install`), chạy driver thủ công (lệnh xcodebuild với `TEST_RUNNER_MCP_DRIVER=1`) hoặc để tool `driver_start` tự spawn, đăng ký với Claude Code: `claude mcp add focusplan -- node <repo>/tools/focusplan-mcp/index.mjs`, danh sách tool + quy ước identifier (link `FocusPlan/docs/accessibility-identifiers.md`), ghi chú escape hatch `tap_system_dialog`.

- [ ] **Step 4: Smoke** — `cd tools/focusplan-mcp && npm install`; viết nhanh 1 lệnh kiểm tra bằng SDK client hoặc `npx @modelcontextprotocol/inspector node index.mjs` (nếu sẵn): xác nhận 9 tool xuất hiện; gọi `driver_status` khi driver TẮT → trả error message "driver not reachable — run driver_start first". Expected đúng như vậy.

- [ ] **Step 5: Commit**

```bash
git add tools/focusplan-mcp/package.json tools/focusplan-mcp/.gitignore \
  tools/focusplan-mcp/index.mjs tools/focusplan-mcp/README.md tools/focusplan-mcp/package-lock.json
git commit -m "feat(mcp): focusplan-mcp stdio server bridging MCP tools to XCUITest driver"
```

---

### Task 4: E2E proof — agent script chạy sign in → tạo task hoàn toàn qua MCP

**Files:**
- Create: `tools/focusplan-mcp/e2e-proof.mjs`

**Interfaces:**
- Consumes: MCP server (Task 3) qua `@modelcontextprotocol/sdk` Client + StdioClientTransport; Supabase REST seed user (URL + anon key public — cùng giá trị `FocusPlan/UITests/TaskFlowUITests.swift`); mock draft JSON (schema `ParsedTaskDraft`).
- Produces: script exit 0 + in transcript từng bước khi flow thành công.

- [ ] **Step 1: Viết `e2e-proof.mjs`** — kịch bản:

```js
// Khung (điền URL/anon key từ TaskFlowUITests):
import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { StdioClientTransport } from "@modelcontextprotocol/sdk/client/stdio.js";

const SUPABASE_URL = "https://njwmpikyqghniqqiweao.supabase.co";
const ANON_KEY = "<anon key — copy từ TaskFlowUITests.swift>";
const MOCK_DRAFT = JSON.stringify({ name: "Học tiếng Trung", estimated_minutes: 30,
  priority: "medium", deadline: null, needs_confirmation: false, note: null, task_type: "deep" });

async function seedUser() { /* POST /auth/v1/signup email qa-mcp-<ts>-<rand>@gmail.com, password secret123 → assert access_token */ }

const client = new Client({ name: "e2e-proof", version: "0.1.0" });
await client.connect(new StdioClientTransport({ command: "node", args: ["index.mjs"] }));
const call = async (name, args) => { /* client.callTool; log tên+args+kết quả; throw nếu isError */ };

// 1. driver_start
// 2. app_launch { env: { UITEST_MOCK_PARSE_DRAFT: MOCK_DRAFT } }
// 3. Nếu wait_for("signin.email-field", 8) fail → còn session cũ: tap("home.sign-out-button") rồi wait signin.
// 4. type_text signin.email-field (email seed) → type_text signin.password-field (paste:true)
//    → tap signin.submit-button
// 5. Dialog OS "Lưu mật khẩu?" có thể hiện → tap_system_dialog("Để sau") best-effort (bỏ qua lỗi nếu không có).
// 6. wait_for("tasklist.add-button", 30) → tap
// 7. wait_for("addtask.input-field") → type_text (paste:true) "Học tiếng Trung 30 phút tối nay"
//    → tap addtask.parse-button
// 8. wait_for("taskform.save-button", 30) → read_element("taskform.name-field")
//    assert value chứa "Học tiếng Trung" (prefill từ mock) → tap taskform.save-button
// 9. screen_elements → assert tồn tại identifier bắt đầu "tasklist.row." → PASS
// In "E2E PROOF PASSED" + transcript; exit 0. Bất kỳ bước fail → in lỗi + exit 1.
```
Viết code đầy đủ theo khung trên (transcript log mỗi call). Điểm mấu chốt: MỌI thao tác app qua identifier; `tap_system_dialog` chỉ dùng cho dialog OS bước 5.

- [ ] **Step 2: Chạy proof**

```bash
cd tools/focusplan-mcp && node e2e-proof.mjs
```
Expected: `E2E PROOF PASSED`, exit 0. (Driver do `driver_start` tự spawn — lần đầu chờ build.) Nếu flake dialog/keyboard: retry theo pattern UITests, nhưng assert cuối phải thật.

- [ ] **Step 3: Commit**

```bash
git add tools/focusplan-mcp/e2e-proof.mjs
git commit -m "test(mcp): E2E proof — sign in and create task entirely via MCP tools"
```

---

### Task 5: Regression + hoàn thiện doc

- [ ] **Step 1: Full suite chính** — `xcodebuild -scheme FocusPlan ... test` → `** TEST SUCCEEDED **`, đúng 32 test, 0 skip (driver không lọt vào suite).
- [ ] **Step 2: Cập nhật `FocusPlan/docs/accessibility-identifiers.md`** — thêm mục ngắn "MCP control": trỏ sang `tools/focusplan-mcp/README.md`, nhắc escape hatch `tap_system_dialog` chỉ cho system UI.
- [ ] **Step 3: Commit** — `git add -A && git commit -m "docs(mcp): link identifier convention to focusplan-mcp usage"`

---

## Self-Review (đã chạy)

- **Acceptance criteria coverage:**
  - C1 (server 1 lệnh, bộ lệnh tối thiểu qua stdio): Task 3 (`node index.mjs`; 9 tool gồm list/tap/type/read/wait + driver_start). ✔
  - C2 (kết quả cấu trúc + error rõ): Interfaces Task 2 (mọi nhánh lỗi có message cụ thể) + Task 3 forward nguyên văn (`isError`). Smoke Task 2 Step 2 + Task 3 Step 4 test cả nhánh lỗi. ✔
  - C3 (E2E: mở app → sign in → tạo task → thấy trong list, không tay): Task 4 — MCP client script, mọi thao tác app qua identifier, assert row cuối. ✔
  - C4 (app production không đổi): driver ở test bundle riêng, không file nào trong `Sources/` bị sửa; scheme chính giữ nguyên (Task 1 Step 3 + Task 5 Step 1 verify 32 test). ✔
- **Type consistency:** action names driver (`status/launch/elements/tap/tap_label/type/read/wait`) khớp lệnh MCP server forward; identifier dùng literal chuẩn `A11yID` (signin.*, tasklist.*, addtask.*, taskform.*); mock draft JSON khớp CodingKeys `ParsedTaskDraft` (snake_case + `task_type`). ✔
- **Rủi ro đã ghi:** API SDK MCP/Network có thể lệch version → các LƯU Ý API cho phép chỉnh cú pháp giữ hành vi; XCUITest main-thread → dispatch main; scheme auto-gen của XcodeGen → định nghĩa schemes tường minh + verify `-list`; secure field/tiếng Việt → `paste:true`; dialog OS → `tap_system_dialog` escape hatch (doc cấm dùng cho app); Gemini chết → mock seam qua `app_launch env`; build driver lâu → driver_start poll 5 phút. ✔
- **Placeholder scan:** Task 4 Step 1 dùng khung kịch bản chi tiết từng bước + yêu cầu code đầy đủ (flow, assert, exit code đều đặc tả cụ thể) — không TODO mơ hồ. ✔
