# Accessibility Identifiers for Core Flows Implementation Plan

> **For agentic workers:** Trong team này coder thực thi toàn bộ plan task-by-task rồi bàn giao reviewer — KHÔNG tự dispatch subagent. Steps dùng checkbox (`- [ ]`).

**Goal:** Phủ `accessibilityIdentifier` chuẩn hoá, tự mô tả, định nghĩa tập trung cho mọi control tương tác của core flows hiện có (auth: sign in/up/out; task: list/add/confirm-form) + tài liệu naming convention — nền cho MCP control server (issue 020) điều khiển app "không cần đọc doc".

**Architecture:** Một file hằng số trung tâm `A11yID` (enum namespace theo màn) — không magic string rải rác; view chỉ tham chiếu hằng số. Identifier là LỚP BỔ SUNG: giữ nguyên mọi `accessibilityLabel` tiếng Việt hiện có (UITest cũ đang query theo label/text — không đổi hành vi). Một XCUITest mới đi xuyên suốt các màn core (dùng seed user + mock parse seam có sẵn) assert mọi identifier tra cứu được.

**Tech Stack:** Swift/SwiftUI iOS 17, XCTest/XCUITest, XcodeGen. Không dependency mới.

## Global Constraints

- **Naming convention (chốt trong plan này, tài liệu hoá ở Task 1):** `"{screen}.{element}-{type}"`, lowercase, kebab-case; phần tử động (hàng list) dùng `"{screen}.row.{uuid}"`. Ví dụ: `signin.email-field`, `tasklist.add-button`, `tasklist.row.<UUID>`. Screen prefix: `signin`, `signup`, `home`, `tasklist`, `addtask`, `taskform`. Type suffix: `-field`, `-button`, `-toggle`, `-picker`, `-text`, `-state`.
- **KHÔNG xoá/sửa `accessibilityLabel` hiện có** (`"Thêm task"`, `"Đăng xuất"`) — UITest cũ phụ thuộc. Identifier thêm song song.
- **Không đổi hành vi UI/logic nào** — chỉ thêm modifier `.accessibilityIdentifier(...)` + file hằng số + test + doc.
- Habit flow (HabitsView/HabitFormView) NGOÀI scope issue 019 (PRD chốt core flows = auth, task, alarm; alarm chưa có UI). Không đụng.
- Nối tiếp convention repo: XcodeGen (`xcodegen generate` sau khi thêm file), test vào `FocusPlan/Tests|UITests`, sim iPhone 17 Pro (đổi nếu tên khác).

## File Structure

```
FocusPlan/
├── Sources/
│   ├── Support/
│   │   └── A11yID.swift                      # (create) hằng số identifier tập trung
│   └── Views/
│       ├── SignInView.swift                   # (modify) + identifier
│       ├── SignUpView.swift                   # (modify) + identifier
│       ├── HomeView.swift                     # (modify) + identifier (sign-out, greeting)
│       ├── TaskListView.swift                 # (modify) + identifier (add, empty, rows)
│       ├── AddTaskView.swift                  # (modify) + identifier
│       └── TaskFormView.swift                 # (modify) + identifier
├── UITests/
│   └── A11yIdentifierUITests.swift            # (create) traversal test assert identifier
└── docs/
    └── accessibility-identifiers.md           # (create) naming convention (ngắn)
```

---

### Task 1: A11yID constants + convention doc

**Files:**
- Create: `FocusPlan/Sources/Support/A11yID.swift`
- Create: `FocusPlan/docs/accessibility-identifiers.md`

**Interfaces:**
- Produces: `enum A11yID` với namespace `SignIn/SignUp/Home/TaskList/AddTask/TaskForm` — các hằng số `static let` (và `TaskList.row(_ id: UUID) -> String`). Task 2-3 tham chiếu đúng các tên dưới đây; Task 4 (UITest) dùng LITERAL string (target UITest không link app module) — phải khớp từng ký tự.

- [ ] **Step 1: Viết `A11yID.swift`**

```swift
import Foundation

/// Accessibility identifiers tập trung — nguồn sự thật duy nhất, không magic string trong view.
/// Convention: "{screen}.{element}-{type}" (lowercase, kebab-case); hàng động: "{screen}.row.{uuid}".
/// Chi tiết: FocusPlan/docs/accessibility-identifiers.md
enum A11yID {
    enum SignIn {
        static let emailField = "signin.email-field"
        static let passwordField = "signin.password-field"
        static let submitButton = "signin.submit-button"
        static let goToSignUpButton = "signin.go-to-signup-button"
        static let errorText = "signin.error-text"
    }

    enum SignUp {
        static let emailField = "signup.email-field"
        static let passwordField = "signup.password-field"
        static let confirmPasswordField = "signup.confirm-password-field"
        static let submitButton = "signup.submit-button"
        static let goToSignInButton = "signup.go-to-signin-button"
        static let errorText = "signup.error-text"
        static let infoText = "signup.info-text"
    }

    enum Home {
        static let greetingText = "home.greeting-text"
        static let signOutButton = "home.sign-out-button"
    }

    enum TaskList {
        static let addButton = "tasklist.add-button"
        static let emptyState = "tasklist.empty-state"
        static func row(_ id: UUID) -> String { "tasklist.row.\(id.uuidString)" }
    }

    enum AddTask {
        static let inputField = "addtask.input-field"
        static let parseButton = "addtask.parse-button"
        static let cancelButton = "addtask.cancel-button"
        static let errorText = "addtask.error-text"
    }

    enum TaskForm {
        static let nameField = "taskform.name-field"
        static let minutesField = "taskform.minutes-field"
        static let priorityPicker = "taskform.priority-picker"
        static let taskTypePicker = "taskform.tasktype-picker"
        static let deadlineToggle = "taskform.deadline-toggle"
        static let deadlinePicker = "taskform.deadline-picker"
        static let noteText = "taskform.note-text"
        static let errorText = "taskform.error-text"
        static let saveButton = "taskform.save-button"
        static let cancelButton = "taskform.cancel-button"
    }
}
```

- [ ] **Step 2: Viết `FocusPlan/docs/accessibility-identifiers.md`**

```markdown
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
```

- [ ] **Step 3: Build** — Run (trong `FocusPlan/`): `xcodegen generate && xcodebuild -project FocusPlan.xcodeproj -scheme FocusPlan -destination 'generic/platform=iOS Simulator' build`
Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 4: Commit**

```bash
git add FocusPlan/Sources/Support/A11yID.swift FocusPlan/docs/accessibility-identifiers.md
git commit -m "feat(ios): central A11yID constants + identifier naming convention"
```

---

### Task 2: Gắn identifier — auth flow (SignIn/SignUp/Home)

**Files:**
- Modify: `FocusPlan/Sources/Views/SignInView.swift`
- Modify: `FocusPlan/Sources/Views/SignUpView.swift`
- Modify: `FocusPlan/Sources/Views/HomeView.swift`

**Interfaces:**
- Consumes: `A11yID.SignIn/SignUp/Home` (Task 1).

- [ ] **Step 1: SignInView** — thêm modifier vào từng control (giữ nguyên mọi modifier có sẵn):

```swift
// TextField("Email", ...) — thêm sau .textFieldStyle(.roundedBorder):
                    .accessibilityIdentifier(A11yID.SignIn.emailField)
// SecureField("Mật khẩu", ...) — thêm sau .textFieldStyle(.roundedBorder):
                    .accessibilityIdentifier(A11yID.SignIn.passwordField)
// Text(msg) lỗi — thêm sau .font(.footnote):
                    .accessibilityIdentifier(A11yID.SignIn.errorText)
// Button Đăng nhập — thêm sau .disabled(isSubmitting):
                .accessibilityIdentifier(A11yID.SignIn.submitButton)
// Button "Chưa có tài khoản? Tạo tài khoản" — thêm sau .frame(maxWidth: .infinity):
                    .accessibilityIdentifier(A11yID.SignIn.goToSignUpButton)
```

- [ ] **Step 2: SignUpView** — tương tự:

```swift
// TextField("Email"): .accessibilityIdentifier(A11yID.SignUp.emailField)
// SecureField("Mật khẩu"): .accessibilityIdentifier(A11yID.SignUp.passwordField)
// SecureField("Xác nhận mật khẩu"): .accessibilityIdentifier(A11yID.SignUp.confirmPasswordField)
// Text(msg) lỗi: .accessibilityIdentifier(A11yID.SignUp.errorText)
// Text(info): .accessibilityIdentifier(A11yID.SignUp.infoText)
// Button Tạo tài khoản (sau .disabled(isSubmitting)): .accessibilityIdentifier(A11yID.SignUp.submitButton)
// Button "Đã có tài khoản? Đăng nhập" (sau .frame): .accessibilityIdentifier(A11yID.SignUp.goToSignInButton)
```

- [ ] **Step 3: HomeView**:

```swift
// Text("Xin chào, \(email)") — thêm sau .truncationMode(.tail):
                    .accessibilityIdentifier(A11yID.Home.greetingText)
// Button sign-out trong toolbar — thêm SAU .accessibilityLabel("Đăng xuất") (giữ label):
                    .accessibilityIdentifier(A11yID.Home.signOutButton)
```

- [ ] **Step 4: Build** — như Task 1 Step 3. Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 5: Commit**

```bash
git add FocusPlan/Sources/Views/SignInView.swift FocusPlan/Sources/Views/SignUpView.swift \
  FocusPlan/Sources/Views/HomeView.swift
git commit -m "feat(ios): accessibility identifiers for auth flow (signin/signup/home)"
```

---

### Task 3: Gắn identifier — task flow (TaskList/AddTask/TaskForm)

**Files:**
- Modify: `FocusPlan/Sources/Views/TaskListView.swift`
- Modify: `FocusPlan/Sources/Views/AddTaskView.swift`
- Modify: `FocusPlan/Sources/Views/TaskFormView.swift`

**Interfaces:**
- Consumes: `A11yID.TaskList/AddTask/TaskForm` (Task 1).

- [ ] **Step 1: TaskListView**:

```swift
// Empty-state VStack (khối "Chưa có task nào — thêm bằng nút +") — thêm sau .background(...):
                .accessibilityIdentifier(A11yID.TaskList.emptyState)
// Button từng row trong ForEach — thêm sau .buttonStyle(.plain):
                            .accessibilityIdentifier(A11yID.TaskList.row(task.id))
// Nút "+" overlay — thêm SAU .accessibilityLabel("Thêm task") (giữ label):
            .accessibilityIdentifier(A11yID.TaskList.addButton)
```

- [ ] **Step 2: AddTaskView**:

```swift
// TextField câu tự nhiên — thêm sau .lineLimit(2...4):
                    .accessibilityIdentifier(A11yID.AddTask.inputField)
// Text(errorMessage) — thêm sau .font(.footnote):
                    .accessibilityIdentifier(A11yID.AddTask.errorText)
// Button Phân tích — thêm sau .disabled(...):
                .accessibilityIdentifier(A11yID.AddTask.parseButton)
// Button "Huỷ" trong toolbar — bọc/thêm: Button("Huỷ") { dismiss() }.accessibilityIdentifier(A11yID.AddTask.cancelButton)
```

- [ ] **Step 3: TaskFormView**:

```swift
// Text(note) cam: .accessibilityIdentifier(A11yID.TaskForm.noteText)
// TextField("Tên"): .accessibilityIdentifier(A11yID.TaskForm.nameField)
// TextField("vd 30") (sau .keyboardType(.numberPad)): .accessibilityIdentifier(A11yID.TaskForm.minutesField)
// Picker Độ ưu tiên (sau .pickerStyle(.segmented)): .accessibilityIdentifier(A11yID.TaskForm.priorityPicker)
// Picker Loại việc (sau .pickerStyle(.segmented)): .accessibilityIdentifier(A11yID.TaskForm.taskTypePicker)
// Toggle "Có deadline": .accessibilityIdentifier(A11yID.TaskForm.deadlineToggle)
// DatePicker "Deadline": .accessibilityIdentifier(A11yID.TaskForm.deadlinePicker)
// Text(errorMessage): .accessibilityIdentifier(A11yID.TaskForm.errorText)
// Button "Huỷ" toolbar: .accessibilityIdentifier(A11yID.TaskForm.cancelButton)
// Button Lưu/Tạo (sau .disabled(...)): .accessibilityIdentifier(A11yID.TaskForm.saveButton)
```

- [ ] **Step 4: Build.** Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 5: Commit**

```bash
git add FocusPlan/Sources/Views/TaskListView.swift FocusPlan/Sources/Views/AddTaskView.swift \
  FocusPlan/Sources/Views/TaskFormView.swift
git commit -m "feat(ios): accessibility identifiers for task flow (list/add/form)"
```

---

### Task 4: UITest traversal — assert identifier tra cứu được + suite xanh

**Files:**
- Create: `FocusPlan/UITests/A11yIdentifierUITests.swift`

**Interfaces:**
- Consumes: identifier LITERAL khớp `A11yID` (UITest target không link app module); pattern seed user + `UITEST_MOCK_PARSE_DRAFT` seam (đã có từ issue 002); helper dismiss dialog "Lưu mật khẩu" (copy pattern từ TaskFlowUITests — helper là private per-class, copy tối thiểu, KHÔNG refactor file test cũ).

- [ ] **Step 1: Viết `A11yIdentifierUITests.swift`** — 1 test đi xuyên: SignIn (assert 4 identifier tĩnh) → [nếu còn session cũ: sign out bằng `home.sign-out-button`] → qua SignUp rồi quay lại (assert nút điều hướng) → login bằng identifier (seed user REST như TaskFlowUITests) → Home/TaskList (assert greeting, add-button; empty-state hoặc row) → mở AddTask (assert input/parse/cancel) → parse bằng mock seam → TaskForm (assert name/minutes/priority/tasktype/deadline-toggle/save/cancel). Mọi thao tác trong test này thực hiện QUA identifier (không dùng label) — chính là bằng chứng criteria "control tra cứu được theo identifier". Kịch bản code cụ thể: coder viết theo pattern `TaskFlowUITests` hiện có (seedUser/postJSON/pasteInto/typeInto/dismissSavePasswordDialog + launchEnvironment mock JSON), thay MỌI query `app.textFields["Email"]`-style bằng `app.textFields["signin.email-field"]`-style. Assert dùng `waitForExistence` cho element đầu mỗi màn, `XCTAssertTrue(el.exists)` cho phần còn lại.

- [ ] **Step 2: Chạy riêng test mới** — Run: `xcodegen generate && xcodebuild ... -only-testing:FocusPlanUITests/A11yIdentifierUITests test` (destination iPhone 17 Pro). Expected: PASS. Nếu identifier nào không query được (vd DatePicker/Picker SwiftUI expose khác loại element), coder điều chỉnh CÁCH QUERY trong test (`app.otherElements`/`app.descendants(matching: .any)["id"]`) — KHÔNG đổi convention; ghi chú loại element thật vào `docs/accessibility-identifiers.md` (thông tin quý cho MCP driver issue 020).

- [ ] **Step 3: Chạy FULL suite** — Expected: `** TEST SUCCEEDED **`, toàn bộ unit + UITest cũ xanh (label cũ không bị phá).

- [ ] **Step 4: Commit**

```bash
git add FocusPlan/UITests/A11yIdentifierUITests.swift FocusPlan/docs/accessibility-identifiers.md
git commit -m "test(ios): UITest proves core-flow controls queryable by accessibility identifier"
```

---

## Self-Review (đã chạy)

- **Acceptance criteria coverage:**
  - Criteria 1 (mọi control core flow có identifier): Task 2 (auth: 12 control) + Task 3 (task: 13 control) — đối chiếu từng control thật trong 6 view hiện có. ✔
  - Criteria 2 (định nghĩa tập trung + doc): Task 1 (`A11yID` + `accessibility-identifiers.md`). ✔
  - Criteria 3 (XCUITest chứng minh queryable): Task 4 — thao tác hoàn toàn qua identifier. ✔
  - Criteria 4 (suite cũ xanh, không phá label): Global Constraint giữ label + Task 4 Step 3 full suite. ✔
- **Type consistency:** tên hằng số ở Task 2/3 khớp Task 1; UITest dùng literal khớp từng ký tự (đã ghi rõ lý do: UITest target không link app module). ✔
- **Rủi ro đã ghi:** SwiftUI expose element type không đoán trước (DatePicker/Picker/segmented) → Task 4 Step 2 cho phép đổi cách query + bắt buộc ghi lại vào doc (phục vụ MCP issue 020); toolbar Button "Huỷ" 2 sheet trùng identifier context (khác màn nên không đụng nhau — mỗi identifier có prefix màn riêng). ✔
- **Placeholder scan:** các step Task 2/3 dùng dạng "comment + dòng modifier chính xác" thay vì dump cả file (file đã tồn tại, coder Read trước khi Edit theo CLAUDE.md) — mọi modifier/hằng số/lệnh đều cụ thể, không TODO/TBD. ✔
