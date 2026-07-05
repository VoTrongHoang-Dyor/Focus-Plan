// E2E proof: một "agent" (script) chạy flow THẬT hoàn toàn qua tool MCP —
// mở app → sign in (user seed) → tạo task (NL parse mock) → thấy task trong list.
// Mọi thao tác control app đi qua accessibilityIdentifier. Exit 0 = PASS.
import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { StdioClientTransport } from "@modelcontextprotocol/sdk/client/stdio.js";

const SUPABASE_URL = "https://njwmpikyqghniqqiweao.supabase.co";
// anon key public (role=anon) — giống TaskFlowUITests.swift.
const ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5qd21waWt5cWdobmlxcWl3ZWFvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODMwNzE3OTIsImV4cCI6MjA5ODY0Nzc5Mn0.gB8a3wg86lBqwh7ltYJ0_tsJOED6O9Vk14DRP3vXjag";
const PASSWORD = "secret123";
const MOCK_DRAFT = JSON.stringify({
  name: "Học tiếng Trung", estimated_minutes: 30, priority: "medium",
  deadline: null, needs_confirmation: false, note: null, task_type: "deep",
});

const log = (...a) => console.log(...a);

async function seedUser() {
  const email = `qa-mcp-${Date.now()}-${Math.floor(Math.random() * 1e6)}@gmail.com`;
  const res = await fetch(`${SUPABASE_URL}/auth/v1/signup`, {
    method: "POST",
    headers: { apikey: ANON_KEY, "content-type": "application/json" },
    body: JSON.stringify({ email, password: PASSWORD }),
  });
  const j = await res.json();
  if (!j.access_token) throw new Error("seed signup thất bại (no access_token): " + JSON.stringify(j));
  log(`  seed user: ${email}`);
  return email;
}

const client = new Client({ name: "e2e-proof", version: "0.1.0" });

async function call(name, args = {}, timeoutMs = 30_000) {
  log(`→ ${name} ${JSON.stringify(args)}`);
  const r = await client.callTool({ name, arguments: args }, undefined, { timeout: timeoutMs });
  const text = r.content?.[0]?.text ?? "";
  if (r.isError) throw new Error(`${name} lỗi: ${text}`);
  log(`← ${text.length > 200 ? text.slice(0, 200) + "…" : text}`);
  return text ? JSON.parse(text) : {};
}

// wait_for không ném (trả bool) để dùng cho nhánh điều kiện/retry.
async function waitOk(id, timeoutSeconds) {
  try { await call("wait_for", { id, timeoutSeconds }, timeoutSeconds * 1000 + 15_000); return true; }
  catch { return false; }
}

async function main() {
  log("== Seed user qua REST ==");
  const email = await seedUser();

  log("== Kết nối MCP server ==");
  await client.connect(new StdioClientTransport({ command: "node", args: ["index.mjs"] }));

  log("== 1. driver_start (build + boot có thể vài phút) ==");
  await call("driver_start", {}, 330_000);

  log("== 2. app_launch (mock parse seam) ==");
  await call("app_launch", { env: { UITEST_MOCK_PARSE_DRAFT: MOCK_DRAFT } });

  log("== 3. Đảm bảo ở màn SignIn (sign out nếu còn session, retry timing) ==");
  let atSignin = false;
  for (let i = 0; i < 4; i++) {
    if (await waitOk("signin.email-field", 8)) { atSignin = true; break; }
    log("  chưa ở SignIn → thử sign out qua identifier");
    try { await call("tap", { id: "home.sign-out-button" }); } catch { /* nút vắng → bỏ qua */ }
    await new Promise((r) => setTimeout(r, 1500));
  }
  if (!atSignin) throw new Error("không tới được SignIn");

  log("== 4. Đăng nhập qua identifier ==");
  await call("type_text", { id: "signin.email-field", text: email });
  await call("type_text", { id: "signin.password-field", text: PASSWORD, paste: true });
  await call("tap", { id: "signin.submit-button" });

  log("== 5. Bỏ dialog OS 'Lưu mật khẩu?' (best-effort, escape hatch) ==");
  for (let i = 0; i < 6; i++) {
    try { await call("tap_system_dialog", { label: "Để sau" }); break; }
    catch { await new Promise((r) => setTimeout(r, 1000)); }
  }

  log("== 6. Vào Home → mở AddTask (retry mở sheet) ==");
  if (!(await waitOk("tasklist.add-button", 30))) throw new Error("không vào được Home");
  let opened = false;
  for (let i = 0; i < 3; i++) {
    await call("tap", { id: "tasklist.add-button" });
    if (await waitOk("addtask.parse-button", 5)) { opened = true; break; }
  }
  if (!opened) throw new Error("không mở được màn AddTask");

  log("== 7. Nhập câu NL → Phân tích (mock draft) ==");
  await call("type_text", { id: "addtask.input-field", text: "Học tiếng Trung 30 phút tối nay", paste: true });
  await call("tap", { id: "addtask.parse-button" });

  log("== 8. Màn confirm: tên prefill từ mock → Tạo ==");
  if (!(await waitOk("taskform.save-button", 30))) throw new Error("không tới màn Xác nhận task");
  const nameEl = await call("read_element", { id: "taskform.name-field" });
  const nameVal = String(nameEl.element?.value ?? "");
  if (!nameVal.includes("Học tiếng Trung")) {
    throw new Error(`tên task chưa prefill đúng từ mock draft: "${nameVal}"`);
  }
  await call("tap", { id: "taskform.save-button" });

  log("== 9. Assert task xuất hiện trong list (tasklist.row.*) ==");
  let found = false;
  for (let i = 0; i < 10; i++) {
    await new Promise((r) => setTimeout(r, 1500));   // để list reload xong (tránh chờ quiescence)
    const els = await call("screen_elements", {}, 90_000);
    found = (els.elements ?? []).some((e) => String(e.identifier).startsWith("tasklist.row."));
    if (found) break;
  }
  if (!found) throw new Error("task vừa tạo không xuất hiện trong list (không thấy tasklist.row.*)");

  log("\n✅ E2E PROOF PASSED — sign in + tạo task hoàn toàn qua MCP tools.");
}

main()
  .then(async () => { await client.close(); process.exit(0); })
  .catch(async (e) => {
    console.error("\n❌ E2E PROOF FAILED:", e.message);
    try { await client.close(); } catch {}
    process.exit(1);
  });
