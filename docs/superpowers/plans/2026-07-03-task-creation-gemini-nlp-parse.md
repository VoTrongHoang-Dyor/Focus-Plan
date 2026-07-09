# Task Creation + Gemini NLP Parse Implementation Plan

> **For agentic workers:** Implement task-by-task. Steps dùng checkbox (`- [ ]`). Trong team này coder thực thi toàn bộ plan rồi bàn giao reviewer — KHÔNG tự dispatch subagent.

**Goal:** Cho phép user nhập task bằng câu tiếng Việt tự nhiên → Gemini 2.0 Flash (qua Supabase Edge Function proxy) parse thành task có cấu trúc → user xác nhận/sửa trước khi lưu → lưu/xem/sửa/xoá task trong Supabase, scoped theo user qua RLS.

**Architecture:** Gemini KHÔNG gọi trực tiếp từ client (tránh lộ API key). App gọi Supabase **Edge Function `parse-task`** (giữ Gemini key server-side, JWT-verified), function trả JSON draft. App hiển thị màn confirm/sửa; khi user xác nhận, app **insert vào bảng `tasks` qua PostgREST** (supabase-swift), RLS `auth.uid() = user_id` tự scope. Nối tiếp codebase `FocusPlan/` (issue 001) — thay empty-state trong `HomeView` bằng danh sách task + luồng thêm task.

**Tech Stack:** Swift/SwiftUI (iOS 17), supabase-swift 2.48.0 (PostgREST `from()` + `functions.invoke`), Supabase Edge Function (Deno/TypeScript), Gemini `gemini-2.0-flash` JSON mode.

## Global Constraints

- **Nối tiếp app có sẵn** tại `FocusPlan/` (issue 001). Giữ nguyên convention: SwiftUI, XcodeGen (`project.yml`, `.xcodeproj` không commit), SPM, source đọc secret qua Info.plist. Thêm source mới vào `FocusPlan/Sources/...` rồi `xcodegen generate`.
- **Gemini gọi qua Edge Function proxy** — TUYỆT ĐỐI không nhúng Gemini API key vào app/client/git. Key chỉ nằm ở Edge Function secret (`supabase secrets set GEMINI_API_KEY=...`). Không log plaintext key ra output/commit.
- **Model:** `gemini-2.0-flash` (không đổi sang tên khác).
- **Bảng Supabase:** `public.tasks` (user tự tạo qua SQL — xem "Tiền đề"). Cột: `id uuid`, `user_id uuid` (default `auth.uid()`), `name text`, `estimated_minutes int null`, `priority text in (low|medium|high) default medium`, `deadline timestamptz null`, `created_at timestamptz`. RLS bật, 4 policy `auth.uid() = user_id`.
- **Confirm-before-save bắt buộc:** MỌI task luôn đi qua màn confirm/sửa trước khi insert — không bao giờ lưu âm thầm (acceptance criteria 3).
- **Multi-user isolation:** dựa hoàn toàn vào RLS server-side (không lọc user_id thủ công ở client là đủ, nhưng insert phải để `user_id` mặc định `auth.uid()`). Verify bằng QA cross-user (Task 8).
- **Naming:** KHÔNG đặt type Swift tên `Task` (đụng `_Concurrency.Task`). Dùng `TaskItem`.

## Tiền đề (phải xong trước khi code phần DB access — Task 5 trở đi)

User đã chạy SQL tạo bảng `tasks` + RLS trên Supabase (leader xác nhận trước khi coder làm Task 5+). Tasks 1–4 (Edge Function + models) KHÔNG phụ thuộc bảng — làm được ngay.

## File Structure

```
supabase/                                  # (repo root) Supabase CLI project cho backend app
├── config.toml                            # từ `supabase init`
└── functions/
    └── parse-task/
        └── index.ts                       # Edge Function: proxy Gemini, trả JSON draft

FocusPlan/
├── project.yml                            # (modify) — không cần đổi nếu Sources/ đã include cả cây con
└── Sources/
    ├── Models/
    │   ├── TaskPriority.swift             # enum low/medium/high + label tiếng Việt
    │   ├── TaskItem.swift                 # row DB (Codable, Identifiable)
    │   └── ParsedTaskDraft.swift          # kết quả parse từ Edge Function (editable)
    ├── Services/
    │   ├── TaskParseService.swift         # gọi functions.invoke("parse-task")
    │   └── TaskRepository.swift           # CRUD bảng tasks qua from("tasks")
    ├── ViewModels/
    │   └── TaskListViewModel.swift        # @MainActor: load/delete tasks, state
    └── Views/
        ├── HomeView.swift                 # (modify) thay empty-state bằng TaskListView + nút thêm
        ├── TaskListView.swift             # danh sách task, swipe-to-delete, tap-to-edit
        ├── AddTaskView.swift              # nhập câu tự nhiên → parse → điều hướng confirm
        └── TaskFormView.swift             # form confirm/sửa dùng chung cho create-from-draft & edit
```

Ghi chú project.yml: target `FocusPlan` đang khai báo `sources: - path: Sources` (đệ quy) → thêm thư mục con Models/Services/ViewModels tự động được include. Chỉ cần `xcodegen generate` lại. Không cần sửa project.yml cho app target. (Edge Function nằm ngoài Xcode, không thuộc target nào.)

---

### Task 1: Supabase CLI project + Edge Function skeleton (stub JSON)

**Files:**
- Create: `supabase/config.toml` (qua `supabase init`)
- Create: `supabase/functions/parse-task/index.ts`
- Modify: `.gitignore` repo root (ignore `supabase/.branches`, `supabase/.temp`)

**Interfaces:**
- Produces: Edge Function `parse-task` nhận `POST { text: string }`, trả JSON `{ name, estimated_minutes, priority, deadline, needs_confirmation, note }`.

- [ ] **Step 1: Cài/kiểm tra Supabase CLI**

```bash
which supabase || brew install supabase/tap/supabase
supabase --version
```

- [ ] **Step 2: Init Supabase project ở repo root** (nếu `supabase/` chưa có)

Run (tại repo root `/Users/hoang_dyor_i/Code_Projects/VoTrongHoang/skills`):
```bash
supabase init
```
Expected: tạo `supabase/config.toml`. (Không cần `supabase start` — ta deploy lên project thật.)

- [ ] **Step 3: Viết skeleton `supabase/functions/parse-task/index.ts`** (chưa gọi Gemini, trả stub để verify deploy + wiring)

```ts
import { serve } from "https://deno.land/std@0.224.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "content-type": "application/json" },
  });
}

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  try {
    const { text } = await req.json();
    if (!text || typeof text !== "string") return json({ error: "text required" }, 400);
    // STUB — Task 2 sẽ thay bằng Gemini thật
    return json({
      name: text,
      estimated_minutes: null,
      priority: "medium",
      deadline: null,
      needs_confirmation: true,
      note: "stub",
    });
  } catch (e) {
    return json({ error: "internal", detail: String(e).slice(0, 300) }, 500);
  }
});
```

- [ ] **Step 4: Deploy + smoke test** (cần `supabase login` + link project ref `njwmpikyqghniqqiweao` — leader cấp qua brief nếu coder chưa có access token)

```bash
supabase functions deploy parse-task --project-ref njwmpikyqghniqqiweao
# smoke: gọi với --no-verify-jwt tạm để test nhanh KHÔNG được — verify_jwt bật mặc định.
# Test qua app ở Task 6, hoặc local:
supabase functions serve parse-task --no-verify-jwt --env-file supabase/functions/.env.local &
curl -s -X POST http://localhost:54321/functions/v1/parse-task \
  -H "content-type: application/json" -d '{"text":"Học tiếng Trung 30 phút"}'
```
Expected: JSON `{"name":"Học tiếng Trung 30 phút",...,"note":"stub"}`.

- [ ] **Step 5: Commit** (KHÔNG commit `.env.local` chứa key)

```bash
# thêm vào .gitignore repo root: supabase/functions/.env.local, supabase/.branches, supabase/.temp
git add supabase/config.toml supabase/functions/parse-task/index.ts .gitignore
git commit -m "feat(backend): scaffold parse-task edge function (stub)"
```

---

### Task 2: Gemini integration trong Edge Function

**Files:**
- Modify: `supabase/functions/parse-task/index.ts`

**Interfaces:**
- Consumes: env `GEMINI_API_KEY` (secret). Produces: cùng JSON contract như Task 1 nhưng do Gemini sinh thật.

- [ ] **Step 1: Set secret Gemini key** (key do leader cấp qua brief — KHÔNG viết vào file/commit)

```bash
supabase secrets set GEMINI_API_KEY=<KEY_TỪ_BRIEF> --project-ref njwmpikyqghniqqiweao
```

- [ ] **Step 2: Thay STUB bằng gọi Gemini thật trong `index.ts`**

```ts
import { serve } from "https://deno.land/std@0.224.0/http/server.ts";

const GEMINI_API_KEY = Deno.env.get("GEMINI_API_KEY")!;
const MODEL = "gemini-2.0-flash";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};
function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "content-type": "application/json" },
  });
}

const responseSchema = {
  type: "OBJECT",
  properties: {
    name: { type: "STRING" },
    estimated_minutes: { type: "INTEGER", nullable: true },
    priority: { type: "STRING", enum: ["low", "medium", "high"] },
    deadline: { type: "STRING", nullable: true },
    needs_confirmation: { type: "BOOLEAN" },
    note: { type: "STRING", nullable: true },
  },
  required: ["name", "priority", "needs_confirmation"],
};

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  try {
    const { text } = await req.json();
    if (!text || typeof text !== "string") return json({ error: "text required" }, 400);

    const nowIso = new Date().toISOString();
    const prompt = `Bạn là bộ phân tích công việc. Người dùng nhập một câu tiếng Việt mô tả task.
Hôm nay là ${nowIso} (UTC). Trả về JSON đúng schema:
- name: tên task ngắn gọn, rõ ràng.
- estimated_minutes: thời lượng ước tính (phút) nếu câu nêu (vd "30 phút" -> 30; "1 tiếng" -> 60); không rõ để null.
- priority: "low" | "medium" | "high" theo mức khẩn cấp; không rõ dùng "medium".
- deadline: nếu câu nêu mốc thời gian ("tối nay", "ngày mai", "thứ 6") quy ra ISO8601 dựa trên hôm nay; không có để null.
- needs_confirmation: true nếu bạn không chắc chắn ở bất kỳ trường nào.
- note: 1 câu ngắn giải thích nếu không chắc, ngược lại null.
Câu người dùng: """${text}"""`;

    const res = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:generateContent?key=${GEMINI_API_KEY}`,
      {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({
          contents: [{ parts: [{ text: prompt }] }],
          generationConfig: { responseMimeType: "application/json", responseSchema },
        }),
      },
    );
    if (!res.ok) return json({ error: "gemini_error", detail: (await res.text()).slice(0, 400) }, 502);
    const data = await res.json();
    const raw = data?.candidates?.[0]?.content?.parts?.[0]?.text;
    if (!raw) return json({ error: "empty_gemini_response" }, 502);
    return json(JSON.parse(raw));
  } catch (e) {
    return json({ error: "internal", detail: String(e).slice(0, 400) }, 500);
  }
});
```

- [ ] **Step 3: Deploy + smoke test với câu thật**

```bash
supabase functions deploy parse-task --project-ref njwmpikyqghniqqiweao
supabase functions serve parse-task --no-verify-jwt --env-file supabase/functions/.env.local &
# .env.local (gitignored) chỉ để test local, chứa GEMINI_API_KEY=<key>
curl -s -X POST http://localhost:54321/functions/v1/parse-task \
  -H "content-type: application/json" -d '{"text":"Học tiếng Trung 30 phút tối nay"}'
```
Expected: JSON hợp lệ, vd `{"name":"Học tiếng Trung","estimated_minutes":30,"priority":"medium","deadline":"2026-07-03T…","needs_confirmation":false,...}`. Xác nhận `name` không rỗng, `priority` thuộc enum, `estimated_minutes` = 30.

- [ ] **Step 4: Commit** (không commit `.env.local`)

```bash
git add supabase/functions/parse-task/index.ts
git commit -m "feat(backend): parse-task calls Gemini 2.0 Flash with JSON schema"
```

---

### Task 3: iOS models + unit test decode

**Files:**
- Create: `FocusPlan/Sources/Models/TaskPriority.swift`
- Create: `FocusPlan/Sources/Models/TaskItem.swift`
- Create: `FocusPlan/Sources/Models/ParsedTaskDraft.swift`
- Create: `FocusPlan/Tests/TaskModelTests.swift`

**Interfaces:**
- Produces:
  - `enum TaskPriority: String, Codable, CaseIterable, Identifiable { case low, medium, high; var label: String }`
  - `struct TaskItem: Codable, Identifiable, Equatable { let id: UUID; var name; var estimatedMinutes: Int?; var priority: TaskPriority; var deadline: Date?; let createdAt: Date }`
  - `struct NewTask: Encodable { name; estimatedMinutes: Int?; priority; deadline: Date? }` (payload insert — không có id/user_id/created_at, để DB default)
  - `struct TaskUpdate: Encodable { name; estimatedMinutes: Int?; priority; deadline: Date? }` (payload update)
  - `struct ParsedTaskDraft: Codable { name; estimatedMinutes: Int?; priority; deadlineRaw: String?; needsConfirmation: Bool; note: String? }`

- [ ] **Step 1: Viết `TaskPriority.swift`**

```swift
import Foundation

enum TaskPriority: String, Codable, CaseIterable, Identifiable {
    case low, medium, high
    var id: String { rawValue }
    var label: String {
        switch self {
        case .low: return "Thấp"
        case .medium: return "Trung bình"
        case .high: return "Cao"
        }
    }
}
```

- [ ] **Step 2: Viết `TaskItem.swift`**

```swift
import Foundation

struct TaskItem: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var estimatedMinutes: Int?
    var priority: TaskPriority
    var deadline: Date?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, name
        case estimatedMinutes = "estimated_minutes"
        case priority, deadline
        case createdAt = "created_at"
    }
}

/// Payload insert — bỏ id/user_id/created_at để DB tự điền (user_id = default auth.uid()).
struct NewTask: Encodable {
    var name: String
    var estimatedMinutes: Int?
    var priority: TaskPriority
    var deadline: Date?
    enum CodingKeys: String, CodingKey {
        case name
        case estimatedMinutes = "estimated_minutes"
        case priority, deadline
    }
}

/// Payload update.
struct TaskUpdate: Encodable {
    var name: String
    var estimatedMinutes: Int?
    var priority: TaskPriority
    var deadline: Date?
    enum CodingKeys: String, CodingKey {
        case name
        case estimatedMinutes = "estimated_minutes"
        case priority, deadline
    }
}
```

- [ ] **Step 3: Viết `ParsedTaskDraft.swift`** (deadline từ Gemini để dạng String thô, tránh vỡ decode ISO không chuẩn; convert sang Date ở form)

```swift
import Foundation

struct ParsedTaskDraft: Codable {
    var name: String
    var estimatedMinutes: Int?
    var priority: TaskPriority
    var deadlineRaw: String?
    var needsConfirmation: Bool
    var note: String?

    enum CodingKeys: String, CodingKey {
        case name
        case estimatedMinutes = "estimated_minutes"
        case priority
        case deadlineRaw = "deadline"
        case needsConfirmation = "needs_confirmation"
        case note
    }

    /// Parse deadlineRaw (ISO8601 đầy đủ hoặc date-only) sang Date nếu được.
    var deadlineDate: Date? {
        guard let raw = deadlineRaw, !raw.isEmpty else { return nil }
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = iso.date(from: raw) { return d }
        iso.formatOptions = [.withInternetDateTime]
        if let d = iso.date(from: raw) { return d }
        let dateOnly = DateFormatter()
        dateOnly.dateFormat = "yyyy-MM-dd"
        dateOnly.timeZone = TimeZone(identifier: "UTC")
        return dateOnly.date(from: raw)
    }
}
```

- [ ] **Step 4: Viết test `FocusPlan/Tests/TaskModelTests.swift`**

```swift
import XCTest
@testable import FocusPlan

final class TaskModelTests: XCTestCase {
    func test_priority_labels_vietnamese() {
        XCTAssertEqual(TaskPriority.low.label, "Thấp")
        XCTAssertEqual(TaskPriority.medium.label, "Trung bình")
        XCTAssertEqual(TaskPriority.high.label, "Cao")
    }

    func test_parsedDraft_decodes_from_gemini_json() throws {
        let jsonStr = """
        {"name":"Học tiếng Trung","estimated_minutes":30,"priority":"medium",
         "deadline":"2026-07-03T13:00:00Z","needs_confirmation":false,"note":null}
        """
        let draft = try JSONDecoder().decode(ParsedTaskDraft.self, from: Data(jsonStr.utf8))
        XCTAssertEqual(draft.name, "Học tiếng Trung")
        XCTAssertEqual(draft.estimatedMinutes, 30)
        XCTAssertEqual(draft.priority, .medium)
        XCTAssertFalse(draft.needsConfirmation)
        XCTAssertNotNil(draft.deadlineDate)
    }

    func test_parsedDraft_handles_null_deadline_and_minutes() throws {
        let jsonStr = """
        {"name":"Gọi mẹ","estimated_minutes":null,"priority":"high",
         "deadline":null,"needs_confirmation":true,"note":"không rõ thời lượng"}
        """
        let draft = try JSONDecoder().decode(ParsedTaskDraft.self, from: Data(jsonStr.utf8))
        XCTAssertNil(draft.estimatedMinutes)
        XCTAssertNil(draft.deadlineDate)
        XCTAssertTrue(draft.needsConfirmation)
    }
}
```

- [ ] **Step 5: Chạy test**

Run (trong `FocusPlan/`):
```bash
xcodegen generate
xcodebuild -project FocusPlan.xcodeproj -scheme FocusPlan \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
```
Expected: `** TEST SUCCEEDED **` (3 test mới + 2 test cũ issue 001 vẫn pass). Nếu tên simulator khác, `xcrun simctl list devices` chọn tên có sẵn.

- [ ] **Step 6: Commit**

```bash
git add FocusPlan/Sources/Models/ FocusPlan/Tests/TaskModelTests.swift
git commit -m "feat(ios): add TaskItem/TaskPriority/ParsedTaskDraft models + decode tests"
```

---

### Task 4: TaskParseService (gọi Edge Function)

**Files:**
- Create: `FocusPlan/Sources/Services/TaskParseService.swift`

**Interfaces:**
- Consumes: `SupabaseManager.shared.client.functions`, `ParsedTaskDraft` (Task 3).
- Produces: `struct TaskParseService { func parse(_ text: String) async throws -> ParsedTaskDraft }`.

- [ ] **Step 1: Viết `TaskParseService.swift`**

```swift
import Foundation
import Supabase

struct TaskParseService {
    private let client = SupabaseManager.shared.client

    struct RequestBody: Encodable { let text: String }

    func parse(_ text: String) async throws -> ParsedTaskDraft {
        // functions.invoke tự đính JWT của session hiện tại (verify_jwt bật).
        // LƯU Ý API: xác minh chữ ký invoke của supabase-swift 2.48.0; nếu khác,
        // điều chỉnh nhưng giữ: gửi body {text}, decode ParsedTaskDraft từ response.
        let draft: ParsedTaskDraft = try await client.functions.invoke(
            "parse-task",
            options: FunctionInvokeOptions(body: RequestBody(text: text))
        )
        return draft
    }
}
```

- [ ] **Step 2: Build**

Run: `xcodegen generate && xcodebuild -project FocusPlan.xcodeproj -scheme FocusPlan -destination 'generic/platform=iOS Simulator' build`
Expected: `** BUILD SUCCEEDED **`. (Nếu `functions.invoke` generic decode chưa suy ra được kiểu, chỉ định decoder hoặc dùng biến thể trả `Data` rồi `JSONDecoder().decode`. Verify theo package thật.)

- [ ] **Step 3: Commit**

```bash
git add FocusPlan/Sources/Services/TaskParseService.swift
git commit -m "feat(ios): add TaskParseService calling parse-task edge function"
```

---

> **GATE:** Task 5–8 đụng bảng `tasks` — chỉ bắt đầu sau khi leader xác nhận user đã tạo bảng + RLS trên Supabase.

### Task 5: TaskRepository (CRUD bảng tasks)

**Files:**
- Create: `FocusPlan/Sources/Services/TaskRepository.swift`

**Interfaces:**
- Consumes: `SupabaseManager.shared.client`, `TaskItem`/`NewTask`/`TaskUpdate` (Task 3).
- Produces: `struct TaskRepository` với:
  - `func fetchAll() async throws -> [TaskItem]`
  - `func create(_ task: NewTask) async throws -> TaskItem`
  - `func update(id: UUID, _ patch: TaskUpdate) async throws -> TaskItem`
  - `func delete(id: UUID) async throws`

- [ ] **Step 1: Viết `TaskRepository.swift`**

```swift
import Foundation
import Supabase

struct TaskRepository {
    private let client = SupabaseManager.shared.client
    private let table = "tasks"

    // LƯU Ý API: xác minh chuỗi builder PostgREST của supabase-swift 2.48.0
    // (from/insert/select/single/order/eq/execute().value). Điều chỉnh nếu lệch,
    // giữ nguyên hành vi: RLS scope theo auth.uid(), user_id để DB default.

    func fetchAll() async throws -> [TaskItem] {
        try await client.from(table)
            .select()
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    func create(_ task: NewTask) async throws -> TaskItem {
        try await client.from(table)
            .insert(task, returning: .representation)
            .select()
            .single()
            .execute()
            .value
    }

    func update(id: UUID, _ patch: TaskUpdate) async throws -> TaskItem {
        try await client.from(table)
            .update(patch)
            .eq("id", value: id)
            .select()
            .single()
            .execute()
            .value
    }

    func delete(id: UUID) async throws {
        try await client.from(table)
            .delete()
            .eq("id", value: id)
            .execute()
    }
}
```

- [ ] **Step 2: Build**

Run: `xcodegen generate && xcodebuild -project FocusPlan.xcodeproj -scheme FocusPlan -destination 'generic/platform=iOS Simulator' build`
Expected: `** BUILD SUCCEEDED **`. (Date encode/decode timestamptz: dựa decoder mặc định của supabase-swift; nếu `deadline`/`created_at` lỗi decode, điều chỉnh theo decoder package — ghi rõ trong finding cho reviewer.)

- [ ] **Step 3: Commit**

```bash
git add FocusPlan/Sources/Services/TaskRepository.swift
git commit -m "feat(ios): add TaskRepository CRUD over tasks table (RLS-scoped)"
```

---

### Task 6: TaskListViewModel + TaskListView + gắn vào HomeView

**Files:**
- Create: `FocusPlan/Sources/ViewModels/TaskListViewModel.swift`
- Create: `FocusPlan/Sources/Views/TaskListView.swift`
- Modify: `FocusPlan/Sources/Views/HomeView.swift`

**Interfaces:**
- Consumes: `TaskRepository` (Task 5), `TaskItem` (Task 3).
- Produces: `@MainActor final class TaskListViewModel: ObservableObject { @Published tasks; @Published isLoading; @Published errorMessage; func load() async; func delete(_:) async }`; `struct TaskListView: View`.

- [ ] **Step 1: Viết `TaskListViewModel.swift`**

```swift
import Foundation

@MainActor
final class TaskListViewModel: ObservableObject {
    @Published private(set) var tasks: [TaskItem] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let repo = TaskRepository()

    func load() async {
        isLoading = true
        errorMessage = nil
        do { tasks = try await repo.fetchAll() }
        catch { errorMessage = error.localizedDescription }
        isLoading = false
    }

    func delete(_ task: TaskItem) async {
        do {
            try await repo.delete(id: task.id)
            tasks.removeAll { $0.id == task.id }
        } catch { errorMessage = error.localizedDescription }
    }
}
```

- [ ] **Step 2: Viết `TaskListView.swift`** (danh sách + swipe delete + tap edit + nút thêm; empty-state khi rỗng)

```swift
import SwiftUI

struct TaskListView: View {
    @StateObject private var vm = TaskListViewModel()
    @State private var showingAdd = false
    @State private var editingTask: TaskItem?

    var body: some View {
        Group {
            if vm.isLoading && vm.tasks.isEmpty {
                ProgressView()
            } else if vm.tasks.isEmpty {
                VStack {
                    Text("Chưa có task nào — thêm bằng nút +")
                        .multilineTextAlignment(.center).padding(24)
                }
                .frame(maxWidth: .infinity)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            } else {
                List {
                    ForEach(vm.tasks) { task in
                        Button { editingTask = task } label: { row(task) }
                            .buttonStyle(.plain)
                    }
                    .onDelete { indexSet in
                        let targets = indexSet.map { vm.tasks[$0] }
                        Task { for t in targets { await vm.delete(t) } }
                    }
                }
                .listStyle(.plain)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            Button { showingAdd = true } label: {
                Image(systemName: "plus").font(.title2.bold()).padding()
                    .background(Color.accentColor, in: Circle()).foregroundStyle(.white)
            }
            .padding(24)
            .accessibilityLabel("Thêm task")
        }
        .task { await vm.load() }
        .sheet(isPresented: $showingAdd) {
            AddTaskView(onSaved: { Task { await vm.load() } })
        }
        .sheet(item: $editingTask) { task in
            TaskFormView(mode: .edit(task), onSaved: { Task { await vm.load() } })
        }
        .alert("Lỗi", isPresented: .constant(vm.errorMessage != nil)) {
            Button("OK") { vm.errorMessage = nil }
        } message: { Text(vm.errorMessage ?? "") }
    }

    @ViewBuilder
    private func row(_ task: TaskItem) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(task.name).font(.body)
            HStack(spacing: 8) {
                Text(task.priority.label).font(.caption)
                    .padding(.horizontal, 8).padding(.vertical, 2)
                    .background(Color(.secondarySystemBackground), in: Capsule())
                if let m = task.estimatedMinutes { Text("\(m) phút").font(.caption).foregroundStyle(.secondary) }
                if let d = task.deadline {
                    Text(d.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
```

- [ ] **Step 3: Sửa `HomeView.swift`** — thay khối empty-state (dòng ~33-41: `Spacer()` + VStack card "Chưa có task nào — sẽ thêm ở slice sau" + `Spacer()`) bằng `TaskListView()`:

```swift
// Trong body của HomeView, thay đoạn:
//   Spacer()
//   VStack { Text("Chưa có task nào — sẽ thêm ở slice sau") ... }
//     .frame(...).background(...)
//   Spacer()
// bằng:
                TaskListView()
```
Giữ nguyên greeting, week strip, toolbar sign out.

- [ ] **Step 4: Build**

Run: `xcodegen generate && xcodebuild -project FocusPlan.xcodeproj -scheme FocusPlan -destination 'generic/platform=iOS Simulator' build`
Expected: `** BUILD SUCCEEDED **`. (AddTaskView/TaskFormView tạo ở Task 7 — nếu build Task 6 độc lập bị thiếu type, làm Task 6+7 liền rồi build chung. Khuyến nghị: viết stub tối thiểu cho AddTaskView/TaskFormView ở cuối Task 6 để build xanh, hoàn thiện ở Task 7.)

- [ ] **Step 5: Commit**

```bash
git add FocusPlan/Sources/ViewModels/TaskListViewModel.swift \
  FocusPlan/Sources/Views/TaskListView.swift FocusPlan/Sources/Views/HomeView.swift
git commit -m "feat(ios): task list with load/delete wired into HomeView"
```

---

### Task 7: AddTaskView (nhập NL → parse) + TaskFormView (confirm/sửa/edit → lưu)

**Files:**
- Create: `FocusPlan/Sources/Views/AddTaskView.swift`
- Create: `FocusPlan/Sources/Views/TaskFormView.swift`

**Interfaces:**
- Consumes: `TaskParseService` (Task 4), `TaskRepository` (Task 5), `ParsedTaskDraft`/`TaskItem`/`NewTask`/`TaskUpdate` (Task 3).
- Produces:
  - `struct AddTaskView: View` — nhận `var onSaved: () -> Void`.
  - `struct TaskFormView: View` — nhận `enum Mode { case create(ParsedTaskDraft); case edit(TaskItem) }` + `var onSaved: () -> Void`.

- [ ] **Step 1: Viết `TaskFormView.swift`** (form dùng chung; confirm-before-save cho create, cập nhật cho edit)

```swift
import SwiftUI

struct TaskFormView: View {
    enum Mode {
        case create(ParsedTaskDraft)
        case edit(TaskItem)
    }

    let mode: Mode
    var onSaved: () -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var minutesText = ""
    @State private var priority: TaskPriority = .medium
    @State private var hasDeadline = false
    @State private var deadline = Date()
    @State private var note: String?
    @State private var isSaving = false
    @State private var errorMessage: String?

    private let repo = TaskRepository()

    var body: some View {
        NavigationStack {
            Form {
                if let note, !note.isEmpty {
                    Section { Text(note).font(.footnote).foregroundStyle(.orange) }
                }
                Section("Tên task") { TextField("Tên", text: $name) }
                Section("Thời lượng (phút)") {
                    TextField("vd 30", text: $minutesText).keyboardType(.numberPad)
                }
                Section("Độ ưu tiên") {
                    Picker("Độ ưu tiên", selection: $priority) {
                        ForEach(TaskPriority.allCases) { p in Text(p.label).tag(p) }
                    }.pickerStyle(.segmented)
                }
                Section {
                    Toggle("Có deadline", isOn: $hasDeadline)
                    if hasDeadline {
                        DatePicker("Deadline", selection: $deadline)
                    }
                }
                if let errorMessage { Text(errorMessage).foregroundStyle(.red).font(.footnote) }
            }
            .navigationTitle(isEditing ? "Sửa task" : "Xác nhận task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Huỷ") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Lưu" : "Tạo") { Task { await save() } }
                        .disabled(isSaving || name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear(perform: prefill)
        }
    }

    private var isEditing: Bool { if case .edit = mode { return true }; return false }

    private func prefill() {
        switch mode {
        case .create(let d):
            name = d.name
            minutesText = d.estimatedMinutes.map(String.init) ?? ""
            priority = d.priority
            note = d.note
            if let dd = d.deadlineDate { hasDeadline = true; deadline = dd }
        case .edit(let t):
            name = t.name
            minutesText = t.estimatedMinutes.map(String.init) ?? ""
            priority = t.priority
            if let dd = t.deadline { hasDeadline = true; deadline = dd }
        }
    }

    private func save() async {
        isSaving = true; errorMessage = nil
        let minutes = Int(minutesText.trimmingCharacters(in: .whitespaces))
        let dl = hasDeadline ? deadline : nil
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        do {
            switch mode {
            case .create:
                _ = try await repo.create(NewTask(name: trimmedName, estimatedMinutes: minutes, priority: priority, deadline: dl))
            case .edit(let t):
                _ = try await repo.update(id: t.id, TaskUpdate(name: trimmedName, estimatedMinutes: minutes, priority: priority, deadline: dl))
            }
            onSaved(); dismiss()
        } catch { errorMessage = error.localizedDescription }
        isSaving = false
    }
}
```

- [ ] **Step 2: Viết `AddTaskView.swift`** (nhập câu tự nhiên → parse → đẩy sang TaskFormView.create)

```swift
import SwiftUI

struct AddTaskView: View {
    var onSaved: () -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var text = ""
    @State private var isParsing = false
    @State private var errorMessage: String?
    @State private var draft: ParsedTaskDraft?

    private let parser = TaskParseService()

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Nhập task bằng câu tự nhiên").font(.headline)
                TextField("vd: Học tiếng Trung 30 phút tối nay", text: $text, axis: .vertical)
                    .textFieldStyle(.roundedBorder).lineLimit(2...4)
                if let errorMessage { Text(errorMessage).foregroundStyle(.red).font(.footnote) }
                Button {
                    Task { await parse() }
                } label: {
                    if isParsing { ProgressView().frame(maxWidth: .infinity) }
                    else { Text("Phân tích").frame(maxWidth: .infinity) }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isParsing || text.trimmingCharacters(in: .whitespaces).isEmpty)
                Spacer()
            }
            .padding(24)
            .navigationTitle("Thêm task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Huỷ") { dismiss() } }
            }
            .sheet(item: $draft) { d in
                // Luôn qua màn confirm trước khi lưu (acceptance criteria 3).
                TaskFormView(mode: .create(d), onSaved: {
                    onSaved(); dismiss()
                })
            }
        }
    }

    private func parse() async {
        isParsing = true; errorMessage = nil
        do { draft = try await parser.parse(text.trimmingCharacters(in: .whitespaces)) }
        catch { errorMessage = "Không phân tích được: \(error.localizedDescription)" }
        isParsing = false
    }
}
```

Ghi chú: `ParsedTaskDraft` cần `Identifiable` để dùng `.sheet(item:)`. Thêm `extension ParsedTaskDraft: Identifiable { var id: String { name } }` ở cuối `ParsedTaskDraft.swift` (hoặc thêm `let localId = UUID()` nếu muốn ổn định hơn).

- [ ] **Step 3: Bổ sung Identifiable cho ParsedTaskDraft** (nếu chưa làm ở Task 3)

Trong `ParsedTaskDraft.swift`, thêm:
```swift
extension ParsedTaskDraft: Identifiable {
    var id: String { name }
}
```

- [ ] **Step 4: Build**

Run: `xcodegen generate && xcodebuild -project FocusPlan.xcodeproj -scheme FocusPlan -destination 'generic/platform=iOS Simulator' build`
Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 5: Commit**

```bash
git add FocusPlan/Sources/Views/AddTaskView.swift FocusPlan/Sources/Views/TaskFormView.swift \
  FocusPlan/Sources/Models/ParsedTaskDraft.swift
git commit -m "feat(ios): add task capture (NL parse) + confirm/edit form saving to Supabase"
```

---

### Task 8: QA end-to-end + verify RLS multi-user

**Files:** (không tạo file app; có thể thêm XCUITest tuỳ chọn)

- [ ] **Step 1: Deploy chắc chắn Edge Function bản Gemini + secret đã set**

```bash
supabase functions deploy parse-task --project-ref njwmpikyqghniqqiweao
supabase secrets list --project-ref njwmpikyqghniqqiweao   # thấy GEMINI_API_KEY (không in giá trị)
```

- [ ] **Step 2: QA thủ công trên simulator (đăng nhập bằng user thật issue 001)**

Build + launch (như issue 001). Checklist khớp acceptance criteria:
1. **Tạo task NL**: nhập "Học tiếng Trung 30 phút tối nay" → bấm "Phân tích" → màn "Xác nhận task" hiện name/priority/deadline/minutes do Gemini parse → bấm "Tạo" → task xuất hiện trong danh sách. (criteria 1)
2. **Confirm-before-save**: xác nhận KHÔNG có đường nào lưu task mà không qua màn confirm; sửa 1 field ở màn confirm rồi lưu → giá trị đã sửa được lưu (criteria 3).
3. **Xem/sửa/xoá**: tap task → sửa tên/priority → Lưu → cập nhật trong list; swipe để xoá → biến mất; kill+relaunch → thay đổi vẫn còn (đọc từ Supabase). (criteria 2)
4. **RLS multi-user** (criteria 4): sign out, tạo user thứ 2 (email khác), đăng nhập → danh sách task RỖNG (không thấy task của user 1). Tạo 1 task ở user 2 → chỉ user 2 thấy. Đăng nhập lại user 1 → chỉ thấy task user 1. Xác nhận không rò chéo.

- [ ] **Step 3: (Tuỳ chọn) verify RLS ở tầng API** — chứng minh isolation không chỉ ở UI:

```bash
# Lấy 2 access_token của 2 user (đăng nhập REST), gọi GET /rest/v1/tasks?select=* với từng token,
# xác nhận mỗi token chỉ trả task của chính user đó. Ghi kết quả vào QA note.
```

- [ ] **Step 4: Commit** (nếu có thêm XCUITest/script QA)

```bash
git add -A
git commit -m "test(ios): QA harness/notes for task capture + RLS isolation"
```

---

## Self-Review (đã chạy)

- **Spec coverage:**
  - Criteria 1 (NL → Gemini parse → lưu Supabase): Task 2 (Gemini) + Task 4 (parse service) + Task 7 (AddTaskView→confirm→create) + Task 5 (insert). ✔
  - Criteria 2 (xem/sửa/xoá): Task 5 (CRUD) + Task 6 (list/delete) + Task 7 (edit form). ✔
  - Criteria 3 (confirm trước khi lưu, không lưu âm thầm): thiết kế "luôn qua TaskFormView.create trước insert" — Task 7 Step 2. ✔
  - Criteria 4 (multi-user, không rò chéo): RLS ở SQL (tiền đề) + insert để user_id default auth.uid() (Task 3/5) + verify Task 8 Step 2.4/Step 3. ✔
- **Bảo mật:** Gemini key chỉ ở Edge Function secret (Task 2 Step 1), không vào app/git; `.env.local` gitignored (Task 1/2). ✔
- **Type consistency:** `ParsedTaskDraft` (deadlineRaw/deadlineDate), `TaskItem`/`NewTask`/`TaskUpdate` field names khớp giữa models ↔ TaskRepository ↔ TaskFormView. `TaskParseService.parse` trả `ParsedTaskDraft` khớp AddTaskView. `TaskListViewModel` dùng `TaskRepository` đúng chữ ký. `TaskFormView.Mode` khớp cách gọi ở AddTaskView (.create) và TaskListView (.edit). ✔
- **Rủi ro đã ghi:**
  - Chữ ký API supabase-swift 2.48.0 cho `functions.invoke` và PostgREST builder — coder verify với package thật, giữ hành vi (Task 4/5 note).
  - Decode `deadline`/`created_at` timestamptz — dựa decoder mặc định supabase-swift; điều chỉnh nếu lỗi (Task 5 note).
  - Gemini deadline ISO có thể date-only — `deadlineDate` xử lý fallback (Task 3).
  - Build Task 6 phụ thuộc type ở Task 7 — làm liền hoặc stub (Task 6 Step 4 note).
  - Gemini output non-deterministic → chất lượng parse đánh giá thủ công (Task 8), khớp Testing Decisions của PRD.
  - `verify_jwt` mặc định bật → app phải đăng nhập mới gọi được parse-task (đúng ý đồ chống lạm dụng proxy).
- **Placeholder scan:** không có TODO/TBD; mọi step có code/lệnh cụ thể. ✔
