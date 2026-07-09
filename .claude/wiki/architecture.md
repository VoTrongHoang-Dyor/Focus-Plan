# Kiến trúc tổng thể

## Tổng quan

Repo chứa **Focus Plan** — ứng dụng iOS native (SwiftUI) — cùng bộ công cụ Second Brain/Agent Teams của Claude Code phục vụ quy trình phát triển. Codebase sản phẩm thật nằm ở `FocusPlan/`. Có một prototype Flutter throwaway (`focus_plan_ui_demo/`) chỉ để tham khảo UI/flow, **không** phải app thật.

## App: Focus Plan (`FocusPlan/`)

Ứng dụng iOS native. **Done:** app shell + auth (001), Task capture (002), Habit tracking (003), Scheduling Engine (004), Alarm Loop (005), Pomodoro timer (006), Accessibility IDs core flows (019), MCP server (020), AlarmFormView + Theme (021), Mascot component (022), Swift UI Polish (024), Habit time-of-day grouping (025), CI/CD GitHub Actions (023).

### Setup & build

- **Stack:** SwiftUI, iOS 17. Project sinh bằng **XcodeGen** (`FocusPlan/project.yml` → `.xcodeproj`, **`.xcodeproj` KHÔNG commit** — gitignore `*.xcodeproj/`, tái sinh bằng `xcodegen`). Package manager **SPM**; auth dùng `supabase-swift` (Package.resolved: **2.48.0**). Bundle id `com.votronghoang.focusplan`, display name "Focus Plan".
- **Config/secret:** `FocusPlan/Config/Secrets.xcconfig` (**gitignored**, chứa `SUPABASE_URL` + `SUPABASE_ANON_KEY`) → nạp vào runtime qua `Resources/Info.plist` (`$(VAR)` substitution). Commit `Secrets.example.xcconfig` làm template. Anon key là public-by-design (RLS bảo vệ ở phía Supabase).

### Backend (Supabase)

Schema version-controlled tại `supabase/migrations/` (nguồn sự thật; **KHÔNG** `supabase db push` lên remote đang chạy vì bảng đã tạo tay → conflict "already exists"). Mọi bảng bật RLS + 4 policy `*_own` scope theo `auth.uid() = user_id`; `user_id` để DB default `auth.uid()`, client không set.

- `public.tasks` (migration `20260704044752`, issue 002; cột task_type thêm issue 004) — id, user_id, name, estimated_minutes, priority (low|medium|high, default medium), deadline, **task_type (deep|shallow, default shallow)**, created_at.
- `public.habits` (migration `20260704051538`, issue 003) — id, user_id, name, time_of_day (`time`), duration_minutes (default 30), created_at.
- `public.habit_logs` (cùng migration) — id, habit_id (FK cascade), user_id, log_date (`date`), status (done|missed), **unique(habit_id, log_date)** → upsert theo cặp này.
- `public.pomodoro_sessions` (migration `20260706200344`, issue 006) — id, user_id, start_time (`timestamptz`), actual_duration_seconds (`integer`), created_at. RLS select/insert own. Dữ liệu nguồn cho gamification (issues 008/009/013).
- **Edge Function** `supabase/functions/parse-task/index.ts` (issue 002, suy task_type từ issue 004) — Deno; nhận `{text}`, gọi Gemini (`gemini-2.0-flash`, key qua env `GEMINI_API_KEY`), trả về draft task đã parse (+ **task_type classification — NLP parse only, không reasoning**). `verify_jwt` bật (client `functions.invoke` tự đính JWT session). Task_type classify CHƯA smoke live do Gemini API quota hết (`limit: 0`, billing chưa bật).

### Client architecture (`FocusPlan/Sources/`)

Phân lớp Models → Services (data access) → ViewModels (`@MainActor ObservableObject`) → Views (SwiftUI).

- **App/Support:** `FocusPlanApp.swift` (`@main`, `WindowGroup { RootView() }`, gắn `@UIApplicationDelegateAdaptor` + xin notification permission + re-arm khi scenePhase active); `Support/SupabaseConfig.swift` (đọc secret từ Info.plist); `Support/SupabaseManager.swift` (singleton bọc `SupabaseClient`); `Support/AlarmNotificationDelegate.swift` (issue 005); **`Support/A11yID.swift`** (issue 019: enum hằng số naming convention `{screen}.{element}-{type}`, ~41 identifier phủ 7 core flows — auth/home/task/habit + alarm); **`Support/Theme.swift`** (issue 021: design tokens từ Flutter demo — color palette indigo/emerald, corner radius, CTA height, helper `Color(hex:)`; token được dùng cả trong app + chờ cho UI polish).
- **Auth:** `Auth/AuthViewModel.swift` (nghe `authStateChanges`; state `loading`/`signedOut`/`signedIn(email:)`; `signIn`/`signUp`/`signOut`); `Auth/AuthValidation.swift` (validate email/password, password ≥ 6 ký tự).
- **Models:** `Habit`(+`NewHabit`/`HabitUpdate`, **issue 025: thêm computed property `.dayPart` map `timeOfDay` → `DayPart` enum**), `DayPart` (**issue 025:** enum morning/afternoon/evening, hour range <12h/<18h/rest), `HabitLog`(+`HabitStatus`/`NewHabitLog`), `BusyBlock`, `TaskItem`(+`NewTask`/`TaskUpdate`), `TaskPriority`(+`sortRank` for engine sort), **`TaskType`** (deep/shallow, energyOrder), `ParsedTaskDraft`, **`ScheduledBlock`**, **`ScheduleResult`**, **`UserAlarm`** (issue 021: loại alarm user định nghĩa, chứa hour/minute, repeat days, toggles Loop/Vibrate/SystemVolume/ShowNotification, tạo/cập nhật/xóa qua UI), **`PomodoroSession`**/**`NewPomodoroSession`** (issue 006: id, user_id, start_time, actual_duration_seconds — dữ liệu nguồn gamification) — struct Codable, payload insert/update tách riêng (Encodable, bỏ id/user_id/created_at).
- **Services:** `HabitRepository` (CRUD habits + `setStatus`/`clearStatus` upsert log onConflict `habit_id,log_date`); `TaskRepository` (CRUD tasks); `TaskParseService` (invoke edge function `parse-task`); `HabitBusyBlockService` (hàm thuần/deterministic map `[Habit]` → `[BusyBlock]` cho 1 ngày); `SchedulingEngine` (issue 004, hàm thuần, greedy earliest-fit, không LLM); **`AlarmPlanner`** (issue 005) — hàm thuần plan chùm ~6×2' escalating title, skip-past, budget 60 né 64-limit; **`AlarmScheduler`** (bọc `UNUserNotificationCenter` qua protocol `NotificationScheduling`, test fake); **`TodayScheduleService`** (issue 005/021, mở rộng: fetchAll task alarms + user alarms → busyBlocks → SchedulingEngine → combined AlarmPlanner/UserAlarmPlanner → arm; re-arm khi app active, lọc future items); **`UserAlarmStore`** (issue 021: persist user alarm cấu hình qua `UserDefaults`); **`UserAlarmPlanner`** (issue 021: map user alarm cấu hình `(hour, minute, repeat days, toggles)` → `PlannedAlarm` và arm qua `AlarmScheduler`); **`PomodoroSessionRepository`** (issue 006: CRUD pomodoro_sessions Supabase); **`PomodoroEngine`** (issue 006: hàm thuần wall-clock state machine idle/running/paused, chống suspend).
- **ViewModels:** `HabitListViewModel`, `TaskListViewModel`, **`PomodoroViewModel`** (issue 006: @MainActor ObservableObject, manage PomodoroEngine state, trigger notification end, save session Supabase).
- **Navigation & Views:** `RootView` route theo `AuthState`; nhánh `signedIn` render **`MainTabView`** — TabView 3 tab: "Hôm nay" (`HomeView` = task list + mascot nhỏ bên greeting + toolbar button tạo alarm, issue 002), "Thói quen" (`HabitsView` = **issue 025: section theo DayPart (Morning/Afternoon/Evening), mỗi section habit của buổi đó**; checklist done/missed hôm nay, issue 003), "Tập trung" (`PomodoroView` = **issue 006: timer 25 phút fixed, start/pause/end, notification end, save session Supabase**). Views khác: `SignInView`, `SignUpView`, `HabitFormView` (**issue 025: giờ input → buổi derive live**), `AddTaskView`/`TaskFormView`/`TaskListView`, **`AlarmFormView`** (issue 021: màn tạo/cập nhật user alarm theo Smart Alarm template, hiển thị giờ, Repeat 7 ngày, 4 toggle cài đặt, CTA "Create Alarm" nối vào UserAlarmPlanner; gắn mascot lớn + tagline "Cùng dậy đúng giờ nào!", issue 022), **`MascotView(size:)`** (issue 022: component tái dùng asset PNG tách layer từ demo, animation ngó/nhún/vẫy, kích thước tuỳ chỉnh).

### Vận hành & session

- **Session persistence:** do `supabase-swift` tự lo (Keychain) + event `.initialSession` khôi phục lúc mở app — **không** tự viết lớp lưu trữ.
- **Ràng buộc QA:** XCUITest yêu cầu Supabase "Confirm email" TẮT (`mailer_autoconfirm: true`) để flow sign-up vào thẳng session. **Issue 002:** Edge Function + DB schema deployed ACTIVE; test suite pass (mock parse qua env-seam `UITEST_MOCK_PARSE_DRAFT` + Supabase thật). **Gemini live chưa QA** do API key hết quota (`limit: 0`, billing chưa bật) — khi bật billing nên chạy 1 pass QA thủ công Gemini thật.

### Test

Unit (`FocusPlan/Tests/`): `SupabaseConfigTests` (2), `HabitModelTests` (2), `HabitBusyBlockServiceTests` (3, TDD), `TaskModelTests` (mở rộng), `SchedulingEngineTests` (5, issue 004), `AlarmPlannerTests` (4, issue 005), `AlarmSchedulerTests` (3, issue 005), `TodayScheduleServiceTests` (2, issue 005), **`UserAlarmPlannerTests`** (6, issue 021), **`UserAlarmStoreTests`** (3, issue 021), **`ThemeTests`** (2, issue 021), **`PomodoroEngineTests`** (5, issue 006), **`PomodoroSessionRepositoryTests`** (3, issue 006) = **49 test**. UITest (`FocusPlan/UITests/`, XCUITest QA harness): `AuthFlowUITests`, `HabitFlowUITests`, `TaskFlowUITests`, **`A11yIdentifierUITests`** (issue 019: thao tác hoàn toàn qua identifier), **`AlarmFlowUITests`** (1, issue 021: tạo alarm qua UI + persist + affect behavior), **`PomodoroFlowUITests`** (1, issue 006: start/pause/end + Supabase save) = **8 UITest** (tổng 57 test).

### AlarmFormView & Theme Layer (issue 021)

**AlarmFormView:** màn tạo user alarm mới theo Smart Alarm template. Bao gồm: header giờ lớn (hour + minute picker), mục Repeat 7 ngày (T2–CN toggle), 4 toggle cài đặt (Loop alarm audio / Vibrate / System volume max / Show notification). Toggle map: Loop/ShowNotification → real arm behavior via `UserAlarmPlanner` nối vào `AlarmScheduler`; Vibrate/SystemVolume → persist-only (iOS public API limitation). CTA "Create Alarm" nối vào `UserAlarmPlanner` → arm user alarm ngay + persist cấu hình qua `UserAlarmStore` (`UserDefaults`). Phủ `accessibilityIdentifier` theo issue 019 ngay từ đầu (~11 identifier mới cho alarm-form).

**Theme Layer:** `Support/Theme.swift` enum chứa design tokens (color indigo #4F46E5 primary / emerald #059669 done / system backgrounds; corner radius 14/16/20 for input/chip/card; CTA height 52pt; helper `Color(hex:)` init + `filledFieldStyle()` for Form/TextFields → ScrollView filled appearance + `authCTAStyle()` for consistent button). Token được dùng trong AlarmFormView + Swift UI Polish forms (issue 024) — tránh hardcode màu/size trong views.

**Integration:** 
- `TodayScheduleService.refreshAndArm()` mở rộng: không chỉ task alarms mà còn fetch user alarms từ `UserAlarmStore` → `UserAlarmPlanner` map → arm thêm.
- HomeView toolbar: button "Tạo báo thức" mở AlarmFormView (navigation).
- Tests: 9 unit (6 UserAlarmPlanner + 3 UserAlarmStore + 2 ThemeTests) + 1 UITest (AlarmFlowUITests: tạo alarm qua UI, persist, relaunch verify).

### MCP Server (`tools/focusplan-mcp/`, issue 020)

Bridge MCP stdio → XCUITest để AI agent điều khiển app trên simulator. **Architecture:** 2 tầng:
- **Driver (XCUITest):** target `FocusPlanMcpDriver` (test bundle riêng) chứa HTTP loopback server (Network.framework, port 8931) thực thi lệnh JSON lên `XCUIApplication` qua identifier.
- **MCP Server (Node.js):** `tools/focusplan-mcp/index.mjs` expose 9 tools MCP chuẩn: `driver_start` (spawn `xcodebuild test`), `driver_status`, `app_launch`, `screen_elements`, `tap`, `tap_system_dialog` (escape hatch cho system UI), `type_text` (paste mode cho secure field/tiếng Việt), `read_element`, `wait_for`. Tool forward request HTTP → driver, trả error nếu driver không sẵn sàng.
- **E2E proof:** script `e2e-proof.mjs` chạy flow sign in → tạo task hoàn toàn qua MCP (mọi thao tác app qua identifier, không can thiệp tay).
- **No app changes (ngoài functional content):** scheme `FocusPlan` chính giữ nguyên (42 test vẫn pass); driver ở test bundle riêng không ảnh hưởng production. Content change: thêm AlarmFormView + Theme layer (phục vụ issue 021 + future polish 024); không thêm behavioral rủi ro vì AlarmFormView nối vào existing AlarmPlanner/Scheduler (issue 005).

### CI/CD Pipeline (issue 023)

**GitHub Actions workflow** (`.github/workflows/` — issue 023): mỗi push/PR chạy:
1. **Build:** `xcodegen generate` + `xcodebuild build` (ẩu simulator, macOS runner)
2. **Unit test:** `xcodebuild test -testPlan UnitTests` (luôn chạy, 39 unit tests)
3. **Release archive:** `xcodebuild build -configuration Release` (unsigned, artifact lưu GitHub)
4. **UITest:** được gate rõ ràng workflow_dispatch (skip trên push, cần bật tay để chạy; tài liệu tại `docs/ci.md`)

**Secrets & Credentials:**
- GitHub Secrets: Supabase URL/anon key (nếu UITest bật)
- `Secrets.xcconfig` gitignored → secrets read từ Info.plist ← GitHub Secrets đón từ runner env
- Apple Developer credentials (ký/upload TestFlight): chờ user cấp, pha 2 chưa implement

**Results & Artifacts:**
- Conclusion: build + unit test xanh per run (vd run 28792926607: 6m5s)
- Artifacts: `unit.xcresult` + xcbeautify log (readable per run)
- UITest: tài liệu `docs/ci.md` cách bật gate

### Tech debt

- RLS `habit_logs` insert/update chỉ kiểm `auth.uid() = user_id`, **chưa** kiểm `habit_id` có thuộc user hay không → về lý thuyết user có thể ghi log cho habit của người khác nếu đoán được `habit_id`. Rủi ro thực tế ≈ 0 (UUID không đoán được), nhưng nên siết bằng policy kiểm ownership của `habit_id` khi có dịp.

### Plan chi tiết

- `docs/superpowers/plans/2026-07-03-ios-app-shell-supabase-auth.md` (issue 001).
- `docs/superpowers/plans/2026-07-05-mcp-control-server-xcuitest-bridge.md` (issue 020).
- `docs/superpowers/plans/2026-07-06-alarm-form-view-smart-alarm-template.md` (issue 021).
- `docs/superpowers/plans/2026-07-05-swift-ui-polish-flutter-parity.md` (issue 024).

## Cấu trúc thư mục

- `CLAUDE.md` — hướng dẫn hành vi chung (7 quy tắc): tư duy trước khi code, tối giản, thay đổi phẫu thuật, thực thi theo mục tiêu, kiểm tra cwd trước `cd`, luôn trả lời tiếng Việt, và Second Brain wiki schema (mục 7).
- `FocusPlan/` — app iOS native thật (xem mục "App: Focus Plan" ở trên). Chứa:
  - target UITest riêng `FocusPlanMcpDriver` (issue 020) trong `FocusPlan/McpDriver/`
  - `Resources/Assets.xcassets` (issue 021/022/024): MascotBody + MascotArm imageset (PNG từ demo, issue 022); **chờ issue 024:** thêm BrandLogo imageset + AccentColor colorset (asset này đã tồn tại, issue 024 chỉ append, không tạo lại)
- `supabase/` — backend project: `migrations/` (nguồn sự thật schema+RLS bảng `tasks`/`habits`/`habit_logs`), `functions/parse-task/` (Edge Function Gemini), `config.toml`.
- `tools/focusplan-mcp/` — MCP stdio server bridge XCUITest (issue 020): `index.mjs` (9 tools MCP), `e2e-proof.mjs` (proof chạy flow sign in → tạo task qua MCP), `README.md`.
- `focus_plan_ui_demo/` — prototype Flutter throwaway, chỉ tham khảo UI/flow; KHÔNG phải app thật, không đồng bộ với `FocusPlan/`.
- `.claude/` — workspace Claude Code:
  - `agents/` — persona cho Agent Teams: `leader.md`, `coder.md`, `reviewer.md`, `librarian.md`.
  - `commands/` — slash command tuỳ biến: `team.md`.
  - `plans/` — plan đang lưu: `plan.md`.
  - `skills/` — skill nội bộ: `grill-me` (hỏi xoáy plan/ý tưởng), `improve-codebase-architecture`, `prd-to-issues`, `write-a-prd`, `tdd`.
  - `settings.local.json` — permissions cục bộ (`bypassPermissions`, deny các lệnh git/rm phá hoại).
  - `wiki/` — Second Brain, đồng thời là vault Obsidian này.
- `FocusPlan/docs/` — tài liệu nội bộ app:
  - `accessibility-identifiers.md` (issue 019): convention `{screen}.{element}-{type}` + bảng element-type — chuẩn cho MCP control.
- `setup/` — prompt gốc dùng để bootstrap:
  - `prompt_1.md` — setup statusline hiển thị token count.
  - `prompt_2.md` — pattern "LLM Wiki" / second brain — nguồn gốc ý tưởng của schema ở `CLAUDE.md` §7.

## Ghi chú

- Vault Obsidian root = chính thư mục `wiki/` này (`.obsidian/` nằm trực tiếp bên trong, không lồng qua thư mục con `obsidian/` như trước).
- Root `README.md` có ghi chú của user: cần cài plugin Dataview cho Obsidian qua `obsidian://show-plugin?id=dataview` (dùng cho query Active PRD bên dưới).

## PRD đang Active

```dataview
TABLE status, date
FROM "prd"
WHERE status = "Active"
SORT date DESC
```

## Kanban (issues)

```dataview
TABLE status
FROM "issues"
SORT status ASC, file.name ASC
```
