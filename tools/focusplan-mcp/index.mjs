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
const asError = (e) => ({ isError: true, content: [{ type: "text", text: String(e?.message ?? e) }] });
const run = (fn) => async (args) => { try { return asText(await fn(args ?? {})); } catch (e) { return asError(e); } };

const server = new McpServer({ name: "focusplan-mcp", version: "0.1.0" });

server.tool("driver_start",
  "Khởi động driver (xcodebuild UITest giữ HTTP bridge). Chờ tới khi sẵn sàng (~2-5 phút lần đầu).",
  { simulator: z.string().optional().describe("Tên simulator, mặc định iPhone 17 Pro") },
  run(async ({ simulator = "iPhone 17 Pro" }) => {
    if (driverProc && !driverProc.killed) return { started: "already-running" };
    // Nếu đã có driver ngoài đang chạy (dev tự spawn) → dùng luôn.
    try { await command({ action: "status" }); return { started: "external" }; } catch {}
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

server.tool("driver_status", "Kiểm tra driver sẵn sàng chưa.", {},
  run(() => command({ action: "status" })));

server.tool("app_launch", "Mở app FocusPlan (kèm env tuỳ chọn, vd UITEST_MOCK_PARSE_DRAFT).",
  { env: z.record(z.string()).optional() },
  run(({ env }) => command({ action: "launch", env })));

server.tool("screen_elements", "Liệt kê element có accessibilityIdentifier trên màn hiện tại.", {},
  run(() => command({ action: "elements" })));

server.tool("tap", "Tap element theo accessibilityIdentifier.",
  { id: z.string() },
  run(({ id }) => command({ action: "tap", id })));

server.tool("tap_system_dialog",
  "CHỈ cho dialog hệ điều hành (vd 'Để sau', 'Not Now') — KHÔNG dùng cho control app.",
  { label: z.string() },
  run(({ label }) => command({ action: "tap_label", label })));

server.tool("type_text", "Nhập text vào field theo identifier. paste=true cho secure field/tiếng Việt.",
  { id: z.string(), text: z.string(), paste: z.boolean().optional() },
  run(({ id, text, paste }) => command({ action: "type", id, text, paste })));

server.tool("read_element", "Đọc label/value/type của element theo identifier.",
  { id: z.string() },
  run(({ id }) => command({ action: "read", id })));

server.tool("wait_for", "Chờ element xuất hiện.",
  { id: z.string(), timeoutSeconds: z.number().optional() },
  run(({ id, timeoutSeconds }) => command({ action: "wait", id, timeout: timeoutSeconds ?? 10 })));

await server.connect(new StdioServerTransport());
