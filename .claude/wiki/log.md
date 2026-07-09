# Librarian log

## [2026-07-06] update | Issue 006 done (Pomodoro Timer — dữ liệu nguồn gamification/reflection)

**Agent:** librarian
**Operation:** Update (triggered by leader — issue 006 reviewer PASS + security-review sạch, 5 commits local ready)
**Files reviewed & verification:**
- Commits local (not pushed yet): ab127c6 → 2b19419: migration `pomodoro_sessions` + PomodoroSession/PomodoroEngine/PomodoroViewModel/PomodoroView + PomodoroFlowUITests.
- Plan verify: `docs/superpowers/plans/2026-07-06-pomodoro-timer.md` (wall-clock timer, notification reuse issue 005, Supabase E2E).
- Decision update: "Phiên cố định 25 phút MVP" (user chốt 2026-07-06 vs. điểm "Còn mở" cũ).
- Test suite verified: 49 unit + 8 UITest = 57 tests PASS, end-to-end thật (row Supabase remote), security-review sạch (no finding ≥ MEDIUM).
- Accessibility: A11yID.Pomodoro.* identifiers thêm; accessibility labels giữ nguyên.

**Acceptance criteria — all met:**
- [x] C1: User start/pause/end phiên từ tab "Tập trung" ✓
- [x] C2: Timer chạy đúng app minimize/khoá (wall-clock engine, chống suspend) ✓
- [x] C3: Kết thúc phiên → notification id `pomodoro-end` (reuse issue 005) ✓
- [x] C4: Phiên hoàn thành lưu `pomodoro_sessions` (start_time, actual_duration, user_id) — dữ liệu nguồn issues 008/009/013 ✓

**Pages updated:**
- Issue 006: frontmatter status todo → **done**, all 4 criteria ticked ✓
- `focus-scheduler-decision-log.md`: mục "Pomodoro timer UI" ghi chú "Đã chốt 2026-07-06: phiên cố định 25 phút MVP, tab thứ 3 độc lập" → resolve điểm "Còn mở" cũ ✓
- `architecture.md` (next step): 3 tab (Hôm nay / Thói quen / Tập trung), module Pomodoro detail, 49 unit + 8 UITest

**Trạng thái module ghi nhận:** issue 001→005 (Scheduler foundation) done; issue 006 (Pomodoro data source) done — nguồn dữ liệu mới cho gamification/reflection. Commits local chờ user duyệt push (quy trình: reviewer pass → user duyệt push → librarian UPDATE lần nữa). Test app-total đang: 49 unit + 8 UITest (= 57 full).

---

## [2026-07-06] update | Issue 023 done (CI/CD GitHub Actions — xanh trên GitHub)

**Agent:** librarian
**Operation:** Update (triggered by leader — issue 023 reviewer PASS, push xong, CI run xanh)
**Files reviewed & verification:**
- Commit push: 4 commits reviewer pass (ad263c5..7ed0e95) push thành công `origin main`, không force. (Note: 2 CI commit 11f5bc6/21aac3a đã ở remote từ trước).
- CI run 28792926607 conclusion **success**: build xanh (6m5s), unit tests xanh (toàn bộ), release archive unsigned xanh (1m49s), UITest skipped đúng thiết kế (gate workflow_dispatch).
- Tài liệu: `docs/ci.md` ghi UITest gate + cách bật.
- Artifacts: `unit.xcresult` + xcbeautify log per run (readable).
- Secrets: `Secrets.xcconfig` không commit, secrets từ GitHub Secrets via runner env.

**Acceptance criteria — all met:**
- [x] C1: Workflow chạy xanh push/PR — build + unit test pass (run 28792926607 proof) ✓
- [x] C2: UITest gate rõ ràng (skip workflow_dispatch + tài liệu docs/ci.md) ✓
- [x] C3: Không secret commit — Secrets.xcconfig gitignored, GitHub Secrets per runtime ✓
- [x] C4: Kết quả test rõ (artifact + xcbeautify log per run) ✓

**Note:** TestFlight pha 2 (ký/upload release) chờ user cấp Apple Developer credentials — không block done (feature gate CI basic per design).

**Pages updated:**
- Issue 023: frontmatter status todo → **done**, all 4 criteria ticked (ghi chú run id 28792926607, TestFlight pha 2 pending) ✓
- `architecture.md`:
  - Tổng quan: "Upcoming: 023" → "Done: ..., 023" ✓
  - Thêm mục "CI/CD Pipeline (issue 023)" chi tiết workflow (build/unit/archive/UITest gate), secrets handling, artifacts ✓

**Trạng thái module ghi nhận:** issue 019→020→021→022→024→025→023 **hoàn tất hoàn toàn** (A11y ID → MCP → Alarm UI → Mascot → Polish → Grouping → CI). Test app-total: 39 unit + 7 UITest (46 full). Dependency chain + CI hoàn tất. Coder bắt đầu issue 006 Pomodoro song song (sẽ có UPDATE riêng).

---

## [2026-07-06] update | Issue 025 done (Habit time-of-day grouping)

**Agent:** librarian
**Operation:** Update (triggered by leader — issue 025 reviewer PASS, all criteria met)
**Files reviewed & verification:**
- Commits: `f870da2` (DayPart enum + Habit.dayPart computed property, TDD), `47fb145` (HabitsView section by buổi + UITest assertion), `7ed0e95` (HabitFormView giờ→buổi derive).
- Plan verify: `docs/superpowers/plans/2026-07-06-habit-time-of-day-grouping.md` (hour range <12h morning / <18h afternoon / rest evening; form UX giờ→buổi derived, no buổi picker).
- Schema: KHÔNG field DB mới, KHÔNG migration (computed property on Habit model).
- HabitBusyBlockService: diff rỗng — KHÔNG ảnh hưởng scheduling (grouping là view-layer only).
- Test suite verified: 39 unit + 7 UITest = 46 tests PASS, 0 fail, 0 skip; accessibility labels giữ nguyên.

**Acceptance criteria — all met:**
- [x] C1: DayPart enum + Habit.dayPart computed property ✓
- [x] C2: N/A by design — computed property (no migration needed) ✓
- [x] C3: HabitsView section theo buổi (header Morning/Afternoon/Evening) ✓
- [x] C4: HabitFormView giờ input → buổi derive (no separate buổi picker) ✓
- [x] C5: HabitBusyBlockService confirm no change (grouping không ảnh hưởng scheduling) ✓
- [x] C6: 46 tests PASS (39 unit + 7 UITest) ✓

**Pages updated:**
- Issue 025: frontmatter status todo → **done**, all 6 criteria ticked ✓
- `architecture.md`:
  - Tổng quan: "Done: 024. Upcoming: 023" → "Done: 024, 025. Upcoming: 023" ✓
  - Models: thêm DayPart enum + ghi Habit.dayPart computed property (issue 025) ✓
  - Views: HabitsView section by buổi, HabitFormView giờ→buổi derive (issue 025) ✓

**Trạng thái module ghi nhận:** issue 019→020→021→022→024→025 hoàn tất (A11y ID → MCP → Alarm UI → Mascot → Polish → Grouping). Test app-total: 39 unit + 7 UITest (46 full). Dependency chain hoàn tất except CI/CD (023 pending, parallel track). Issue 025 là cuối đợt này per leader — tiếp theo: 023 (CI/CD, HITL review) + phác hoạ pha 2 refactor issue 011 (Monk Mode).

---

## [2026-07-06] update | Issue 024 done (Swift UI Polish — Flutter Parity)

**Agent:** librarian
**Operation:** Update (triggered by leader — issue 024 reviewer PASS, all criteria met)
**Files reviewed & verification:**
- Commits: `6b3a06e` (asset), `517ade5` (auth), `65fc732` (home+tab), `716dd3c` (task-list+forms), `0be50e8` (habits), `ad263c5` (evidence), `408a658` (form polish addendum — TaskFormView/HabitFormView form→scrollview + authCTAStyle, evidence updated).
- Test suite verified: 26 unit + 44 UITest xanh (thực tế lớn hơn criterion cũ "26 unit + 6 UITest"); all pass, 0 skip, 0 fail.
- Evidence: `docs/superpowers/plans/evidence/2026-07-05-ui-polish/` (8 png files).
- Accessibility: tất cả `accessibilityIdentifier`/`accessibilityLabel` giữ nguyên, MCP query không đổi.

**Acceptance criteria — all met:**
- [x] C1: Auth screens restyle parity (Theme.primary, filled, logo, centered, subtitle)
- [x] C2: Home + MainTabView (greeting, speech bubble, day chips, section header, HomeView logic preserved)
- [x] C3: Task list + forms (card rows, empty state, priority badge)
- [x] C4: Habits screens (summary card, progress ring, list card, empty state)
- [x] C5: Full suite 26 unit + 44 UITest xanh, 8 png evidence
- [x] C6: A11y ID giữ nguyên → MCP + UITest query đúng

**Pages updated:**
- Issue 024: frontmatter status todo → **done**, all 6 criteria ticked ✓
- `architecture.md`:
  - Tổng quan: "Swift UI Polish (024)" chuyển từ "Upcoming" → "Done" ✓
  - Theme Layer: thêm ghi chú `filledFieldStyle()` + `authCTAStyle()` helper (issue 024 form polish dùng) ✓

**Trạng thái module ghi nhận:** issue 019→020→021→022✓ → 024✓ (tuyến tính: A11y ID → MCP → Alarm UI → Mascot → Polish). Test app-total: 26 unit + 44 UITest. Dependency chain 021/022 done → 024 (restyle/polish chờ Theme có sẵn) done. Tiếp theo: 023 (CI/CD GitHub Actions, độc lập HITL).

---

## [2026-07-06] update | Issue 025 created (Habit time-of-day grouping)

**Agent:** librarian
**Operation:** Update (triggered by leader — create follow-up issue for gap found in 024 review)
**Scope verification:**
- Nguồn gốc: phát hiện từ review issue 024 (Swift UI Polish) — demo nhóm habit theo buổi (sáng/chiều/tối), model Swift hiện chỉ có `timeOfDay: String` (giờ cụ thể), không có grouping logic
- Vì vậy: 024 chỉ restyle visual, không mở rộng model → tách thành issue 025 riêng
- Verify codebase: Habit model đã có `timeOfDay` field, HabitBusyBlockService kiểm tra likely không cần đổi

**File created:**
- `.claude/wiki/issues/025-habit-time-of-day-grouping.md` (status: todo)
  - What to build: helper/field để classify `timeOfDay` → Morning/Afternoon/Evening + HabitsView section + HabitFormView chooser
  - Acceptance criteria: model logic, schema safe migration, section group, form UI, test pass
  - Blocked by: 024 (UI polish base)
  - Planning note: chốt hour range + form UX

**Trạng thái hàng đợi (ghi nhận, không cần cập nhật issue):**
- Sau 024 → 023 (CI/CD) → refactor 011 + pha 2 Monk Mode → 025 cân nhắc cùng nhóm 006–018

---

## [2026-07-06] grill + decision-log | Monk Mode × Screen Time (refine issue 011)

**Agent:** librarian (Decision Log ghi sau khi user chốt ở phiên chính qua /grill-me 3 round)
**Operation:** GRILL hoàn tất + Decision Log ghi nhận
**Status:** user chốt hết fork qua 3 round — xung đột issue 011 (cấm Screen Time entitlement) vs yêu cầu (muốn Screen Time) resolved.

**Quyết định chốt:**
1. **Kiến trúc 2 pha** (supersede phần criterion issue 011):
   - Pha 1 (MVP): KHÔNG dùng Screen Time API, NỘI entitlement form song song; thay vào: focus lock in-app + nhắc bật Focus/DND hệ thống
   - Pha 2 (khi Apple duyệt): FamilyControls + ManagedSettings shield
2. Distribution: App Store công khai
3. BỎ: dashboard usage, deep-link Settings, notification suppress
4. Monk Mode pha 1: focus lock UI + tự kích hoạt theo focus session (issue 006)
5. Friction: reflection gate gõ lý do dừng, heuristic local (KHÔNG Gemini)
6. Log lý do → daily reflection (issue 008) track pattern
7. KPI: completion rate ↑ when Monk Mode on (pha 1 validate)

**Rủi ro:**
- Entitlement pha 2 timeline Apple quyết (vài ngày–vài tuần)
- Heuristic local có thể lách (text dài vô nghĩa) — chấp nhận pha 1
- Apple review soft-restriction safer than hard-lock

**Pages tạo:**
- `.claude/wiki/decisions/monk-mode-screen-time-decision-log.md` (status: Active, full detail ở đó)

**Hệ quả wiki (leader điều phối sau, NOT in this task):**
- Issue 011: refine acceptance criteria pha 1
- Issue mới: pha 2 Screen Time entitlement implementation
- Issue 017: verify vẫn khớp (không đổi)

**Tiếp theo:** leader lập kế hoạch refactor issue 011 + tạo issue pha 2 qua pipeline.

---

## [2026-07-06] update | Issue 022 done (MascotView — reuse demo assets)

**Agent:** librarian
**Operation:** Update (triggered by reviewer PASS issue 022 — MascotView + assets complete)
**Files reviewed:**
- `FocusPlan/Sources/Views/MascotView.swift` (component reusable, `accessibilityHidden: true` — không nhiễu MCP)
- `FocusPlan/Resources/Assets.xcassets/` (MascotBody.imageset + MascotArm.imageset từ demo PNG, byte-for-byte khớp)
- `FocusPlan/Sources/Views/{HomeView.swift,AlarmFormView.swift}` (mascot gắn: home 64, alarm 120 + tagline)
- Evidence: `docs/superpowers/plans/evidence/2026-07-06-mascot/` (screenshot)
- Git commits: `81b3427`–`75a456e` (4 commits)

**Acceptance criteria — all met:**
- [x] C1: MascotView(size:) component duy nhất, 1 dòng thêm vào view
- [x] C2: asset PNG (body/arm) import app bundle, nền trong suốt như demo
- [x] C3: animation ngó/nhún/vẫy chạy mượt = demo (verified manual + đối chiếu brand.dart)
- [x] C4: HomeView mascot 64 + AlarmFormView mascot 120 + tagline "Cùng dậy đúng giờ nào!"
- [x] C5: test suite xanh (42 test vẫn xanh, mascot verification qua build + hiển thị)

**Pages updated:**
- Issue 022: status todo → **done**, tick 5 criteria ✓
- `architecture.md`:
  - Tổng quan: "Mascot component (022)" chuyển Done ✓
  - Views: HomeView/AlarmFormView ghi mascot đã gắn, MascotView(size:) component mới ✓
  - Cấu trúc: `FocusPlan/Resources/Assets.xcassets` ghi MascotBody/Arm + note cho issue 024 (catalog đã tồn tại, 024 chỉ append BrandLogo/AccentColor) ✓

**Reviewer note (tracker — trade-off chấp nhận):**
- Animation mascot vẫn chạy khi bị sheet (AlarmFormView) che — trade-off: rendering đơn giản, không pause animation. Nếu sau này có vấn đề hiệu năng, review lại quirk này.

**Dependency chain progression:** 021→022✓ → 023 (CI/CD) parallel → 024 (Polish) — kiểm tra: issue 024 blocked by ai giờ?

---

## [2026-07-06] update | Issue 021 done (AlarmFormView + Theme design tokens)

**Agent:** librarian
**Operation:** Update (triggered by reviewer PASS issue 021 — AlarmFormView + Theme complete)
**Files reviewed:**
- `FocusPlan/Sources/Models/UserAlarm.swift`
- `FocusPlan/Sources/Services/{UserAlarmStore,UserAlarmPlanner}.swift`
- `FocusPlan/Sources/Support/{Theme.swift,A11yID.swift}` (ThemeTests, A11yID extension ~11 alarm-form ids)
- `FocusPlan/Sources/Views/AlarmFormView.swift`, `HomeView.swift` (toolbar button)
- `FocusPlan/Tests/{UserAlarmPlannerTests,UserAlarmStoreTests,ThemeTests}.swift` (9 unit)
- `FocusPlan/UITests/AlarmFlowUITests.swift` (1 UITest)
- Git commits: `fcd251e`–`ec5db4c` (7 commits, last fix seam UITEST_RESET_USER_ALARMS)

**Acceptance criteria — all met:**
- [x] C1: AlarmFormView template (giờ lớn, Repeat 7 ngày, 4 toggle, CTA "Create Alarm")
- [x] C2: Create Alarm persist + ảnh hưởng hành vi alarm (Loop/ShowNotification real arm; Vibrate/Volume persist-only per iOS API limits)
- [x] C3: ~11 new alarm-form identifier theo A11yID convention (MCP control được)
- [x] C4: test suite xanh (35 unit + 7 UITest = 42 total); logic map unit test + flow UITest

**Pages updated:**
- Issue 021: status todo → **done**, tick 4 criteria ✓
- `architecture.md`:
  - Tổng quan: "AlarmFormView (021)" chuyển từ "Upcoming" → "Done" ✓
  - Support: thêm Theme.swift + A11yID mở rộng ✓
  - Models: thêm UserAlarm ✓
  - Services: mở rộng TodayScheduleService + UserAlarmPlanner + UserAlarmStore ✓
  - Views: AlarmFormView + HomeView toolbar entry ✓
  - Test: 26→35 unit, 6→7 UITest (cộng ThemeTests 2 từ issue 021) ✓
  - Thêm mục "AlarmFormView & Theme Layer" chi tiết integration ✓
  - Plan chi tiết: link `2026-07-06-alarm-form-view-smart-alarm-template.md` ✓

**Reviewer note (tracker — không block):**
- `dayChip` dùng `accessibilityAddTraits(.isSelected)` không có removeTraits tường minh — nếu sau này MCP cần đọc trạng thái chọn ngày trong cùng session, cần kiểm quirk này lại (select state persistence qua view update).

**Dependency chain progression:** 020 (MCP) done → 021 (AlarmFormView) done → 022 (Mascot) unblocked, 023 (CI/CD) parallel, 024 (Polish) xếp sau.

---

## [2026-07-06] update | Issue 024 created (Swift UI Polish — Flutter Parity)

**Agent:** librarian
**Operation:** Update (triggered by leader — create + correct Kanban issue for UI polish workstream)
**Scope verification & correction:**
- Plan gốc: `docs/superpowers/plans/2026-07-05-swift-ui-polish-flutter-parity.md` (Tasks 1-6)
- Parent PRD: `focusplan-swift-mascot-mcp-web.md` **does NOT cover** UI polish
- Task 1 status: plan issue 021 hoàn thành CHỈ `Theme.swift`/`ThemeTests.swift` — asset (BrandLogo, AccentColor) CHƯA làm
- Vì vậy: issue 024 scope = Tasks 2-6 + asset Task 1 (không phải chỉ Tasks 2-6)

**File created & updated:**
- `.claude/wiki/issues/024-swift-ui-polish-flutter-parity.md` (status: todo)
  - What to build: Tasks 2-6 + asset Task 1 (BrandLogo imageset, AccentColor colorset)
  - Theme.swift chỉ ghi "đã xong ở 021"
  - Asset BrandLogo cần cho Task 2 (auth screens)
  - Acceptance criteria: visual parity Flutter demo, test suite xanh, accessibility id giữ nguyên
  - Blocked by: 021 (cần Theme), 022 (Mascot layout), 023 (optional CI)

**Dependency chain:** 021 (Theme) → 024 (asset + Tasks 2-6 restyle) → 022/023 parallel

---

## [2026-07-06] update | Issue 020 done (MCP Control Server XCUITest bridge)

**Agent:** librarian
**Operation:** Update (triggered by reviewer PASS issue 020 — all 4 acceptance criteria met)
**Files reviewed:**
- `FocusPlan/McpDriver/McpDriverTests.swift`, `FocusPlan/McpDriver/DriverServer.swift`
- `tools/focusplan-mcp/index.mjs` (9 MCP tools), `e2e-proof.mjs` (E2E proof script), `README.md`
- `FocusPlan/docs/accessibility-identifiers.md` (doc link to MCP usage)
- Commits: `6c3ae9b` (skeleton), `6745ec2` (DriverServer HTTP), `67a3471` (MCP server stdio), `e873cc8` (E2E proof), `f59c16a` (doc update)

**Acceptance criteria — all met:**
- [x] C1: MCP server stdio khởi động 1 lệnh (`node index.mjs` or `driver_start` tool), expose 9 tools (driver_start, driver_status, app_launch, screen_elements, tap, tap_system_dialog, type_text, read_element, wait_for)
- [x] C2: error trả `isError:true` + message cụ thể (từ driver, forwarded nguyên văn — identifier not found/not hittable/timeout)
- [x] C3: E2E proof `e2e-proof.mjs` chạy flow thật (sign in → tạo task → assert row) hoàn toàn qua MCP, không can thiệp tay
- [x] C4: app production không đổi (scheme FocusPlan vẫn 32 test; driver ở test bundle riêng FocusPlanMcpDriver)

**Pages updated:**
- Issue 020: status todo → **done**, tick 4 criteria ✓
- `architecture.md`: 
  - Tổng quan: "MCP server (020)" chuyển từ "Upcoming" → "Done" ✓
  - Thêm mục "### MCP Server (issue 020)": 2-tầng architecture (Driver XCUITest + MCP stdio), 9 tools, E2E proof, no app changes ✓
  - Cấu trúc thư mục: thêm `FocusPlan/McpDriver/` + `tools/focusplan-mcp/` ✓
  - Plan chi tiết: thêm link đến `docs/superpowers/plans/2026-07-05-mcp-control-server-xcuitest-bridge.md` ✓

**Trạng thái module ghi nhận:** issue 019 done (A11y IDs), issue 020 done (MCP server) → issue 021 (AlarmFormView) unblocked — dependency chain 019→020→021 progressing.

---

## [2026-07-05] update | Issue 019 done (Accessibility IDs), issue 020 in-progress (MCP server)

**Agent:** librarian
**Operation:** Update (triggered by reviewer PASS issue 019)
**Status:** issue 019 done (4/4 criteria ✓), issue 020 in-progress

**Issue 019 (Accessibility Identifiers Core Flows) — PASS:**
- `A11yID.swift` enum + convention doc `accessibility-identifiers.md` (naming `{screen}.{element}-{type}`)
- 31 identifier phủ 6 core flows (SignIn, SignUp, Home, TaskList, TaskForm, AddTask)
- Reviewer PASS (0 Critical, 0 Important) — full suite: 26 unit + 6 UITest = 32 (thêm A11yIdentifierUITests)
- Backlog Nit: vài identifier động (error-text, picker, row.{uuid}) chưa exercise

**Pages updated:**
- Issue 019: status done, tick 4 criteria, QA/verify section, backlog nit ✓
- Issue 020: status in-progress ✓
- `architecture.md`: A11yID.swift + convention doc + test 26→32 UITest ✓

**Kanban progression:** 019 done → 020 in-progress (MCP server bridge XCUITest/identifier).

---

## [2026-07-05] pipeline-complete | PRD + 5 issue mới cho Mascot/MCP/Web (grill→Decision Log→PRD→Kanban hoàn tất, issue 019 in-progress)

**Agent:** librarian
**Operation:** Update (ghi nhận pipeline grill→PRD→prd-to-issues hoàn tất)

**Artifacts tạo (leader chạy write-a-prd/prd-to-issues):**
- PRD: `.claude/wiki/prd/focusplan-swift-mascot-mcp-web.md` (status: Active)
- 5 issue mới: 019-023 (status: todo → issue 019 chuyển in-progress)
  - `019-accessibility-identifiers-core-flows` (in-progress)
  - `020-mcp-control-server-xcuitest-bridge` (todo, phụ thuộc 019)
  - `021-alarm-form-view-smart-alarm-template` (todo, phụ thuộc 020)
  - `022-mascot-component-reuse-demo-assets` (todo, phụ thuộc 021)
  - `023-ci-cd-github-actions-ios` (todo, độc lập HITL)

**Dependency chain:** 019 → 020 → 021 → 022 (tuyến tính MCP→UI), 023 parallel (CI/CD — human review).

**Kanban progression:** issue 019 bắt đầu (in-progress).

---

## [2026-07-05] grill + decision-log | FocusPlan Swift App — Mascot/MCP/Web (3 round grill + Decision Log riêng)

**Agent:** librarian
**Operation:** GRILL (Round 1-3) + Decision Log (Decision Log mới)
**Status:** grill hoàn tất — 4 câu Round 3 user trả lời đủ, không cần Round 4.

**Quá trình:**
- Round 1: 5 câu grill (phạm vi `focus_plan_ui_demo` Flutter lúc đó)
- Round 1 feedback: user chốt phạm vi demo "nâng sản phẩm thật" → phát hiện hiểu nhầm phạm vi
- Round 2: re-contextualize thành `FocusPlan/` Swift app thật (4 câu)
- Round 2 feedback: phạm vi ĐỔI từ Flutter → Swift; Q3 user CHƯA HIỂU → cần Round 3
- Việc 1 (UPDATE issue 005): cập nhật architecture.md, test 17→26 unit, ghi log. ✓
- Việc 2 (GRILL Round 3): explore code Swift → mascot KHÔNG có, alarm UI KHÔNG có (chỉ logic); soạn 4 câu Round 3.
- Việc 3 (viết Decision Log): tích hợp feedback 3 round → Decision Log file riêng `focusplan-swift-mascot-mcp-web-decision-log.md`

**Pages tạo/cập nhật:**
- `.claude/wiki/decisions/focusplan-swift-mascot-mcp-web-decision-log.md` (file mới, status: Active, phạm vi Swift app, ghi 3 round chốt)
- `.claude/wiki/decisions/focus-scheduler-decision-log.md`: thêm 1 dòng cross-reference → file mới
- `.claude/wiki/architecture.md`: cập nhật issue 005 (3 edits, test 17→26 unit) ✓

**Kết quả Round 3 ghi vào Decision Log:**
- Mascot: tái dùng PNG từ Flutter demo (body/arm + animation) — KHÔNG tạo asset mới
- AlarmFormView: TẠO MỚI theo template Smart Alarm (7 day repeat, 4 toggles, CTA, mascot to) — KHÔNG làm onboarding riêng
- MCP: custom server (stdio) bridge XCUITest/accessibilityIdentifier (trước UI mới)
- CI/CD: GitHub Actions xcodebuild + TestFlight
- Web: conditional $100/tháng MRR (không làm ngay)

**Tiếp theo:** leader chạy write-a-prd → prd-to-issues để phân rã Decision Log thành PRD + issue kanban.

---

## [2026-07-05] update | Local Escalating Alarm Loop (issue 005 done) — criteria 1-3 pass, criteria 4 PENDING user device QA

**Agent:** librarian
**Operation:** Update (triggered by reviewer PASS issue 005 criteria 1-3; criteria 4 PENDING user device)
**Files reviewed:**
- `FocusPlan/Sources/Services/{AlarmPlanner,AlarmScheduler,TodayScheduleService}.swift`
- `FocusPlan/Sources/Support/AlarmNotificationDelegate.swift`
- `FocusPlan/Sources/FocusPlanApp.swift` (UIApplicationDelegateAdaptor, permission, re-arm on active)
- `FocusPlan/Tests/{AlarmPlannerTests,AlarmSchedulerTests,TodayScheduleServiceTests}.swift`
- `.claude/wiki/issues/005-local-escalating-alarm-loop.md` (3/4 criteria ✓, criteria 4 PENDING + checklist ghi)

**Pages updated:**
- `.claude/wiki/architecture.md`:
  - App/Support: thêm AlarmNotificationDelegate (AppDelegate, category, actions, Snooze re-arm +10')
  - Services: thêm AlarmPlanner (chùm ~6×2', escalating title, budget 60), AlarmScheduler (bọc UNUserNotificationCenter qua protocol), TodayScheduleService (wiring engine 004 vào runtime: fetchAll→busyBlocks→SchedulingEngine→AlarmPlanner→arm; re-arm khi app active)
  - Test count: 17 → **26 unit** (AlarmPlannerTests 4 + AlarmSchedulerTests 3 + TodayScheduleServiceTests 2), UITest 5 (no change)

**Trạng thái module ghi nhận:** issue 001 auth (done), 002 Task capture (done), 003 Habit (done), 004 Scheduling Engine (done), 005 Alarm Loop (done — criteria 1-3, criteria 4 PENDING user device QA per checklist). Test app-total: 26 unit + 5 UITest = 31. Engine wiring (TodayScheduleService) là ĐỐI TƯỢNG đầu tiên trong runtime kết nối engine vào app (fetchAll từ DB → compute schedule → arm alarm).

**Xác minh vs lời leader & Decision Log:** khớp code thật — AlarmPlanner chùm 6×2' (config), title escalating TEXT (không Critical Alerts), AlarmScheduler fake-test, Snooze re-arm +10' (userInfo decouple), TodayScheduleService re-arm khi app active (lọc future items để mở app dừng chuỗi). Criteria 4 CHƯA verify (user QA thật device per checklist trong issue). Escalation là TEXT+system sound (v1, không asset). UI lịch "Today" vẫn chưa có (chỉ engine arm alarm, chưa display schedule). Commits: 74a30ab/ed27c95/619b7b8/98e2109/3b348ac/bb6d033/1e4ca96.

---

## [2026-07-05] update | Deterministic Scheduling Engine (issue 004 done) — greedy earliest-fit, deterministic sort, no LLM

**Agent:** librarian
**Operation:** Update (triggered by reviewer PASS issue 004 — Scheduling Engine v1 complete)
**Files reviewed:**
- `FocusPlan/Sources/Services/SchedulingEngine.swift` (greedy earliest-fit, sort deterministic: energyOrder→priority.sortRank→duration→createdAt→id, buffer 10min, busy-block avoidance)
- `FocusPlan/Sources/Models/{TaskType,ScheduledBlock,ScheduleResult}.swift` (new models for engine)
- `FocusPlan/Sources/Models/{TaskItem,TaskPriority}.swift` (update: taskType field, sortRank property)
- `supabase/migrations/20260704044752_create_tasks.sql` (alter: add task_type column)
- `supabase/functions/parse-task/index.ts` (redeploy: suy task_type classification)
- `FocusPlan/Sources/Views/TaskFormView.swift` (add Picker loại việc)
- `FocusPlan/Tests/SchedulingEngineTests.swift` (5 unit tests phủ 5 criteria + overflow)
- `.claude/wiki/issues/004-deterministic-scheduling-engine-v1.md` (5/5 criteria ✓, QA verify section, Backlog Nit ghi)
- `.claude/wiki/decisions/focus-scheduler-decision-log.md` (mục "Logic tìm slot trống" addressed: engine + task_type classify)

**Pages updated:**
- `.claude/wiki/architecture.md` — update mục "Backend":
  - `public.tasks` description: thêm task_type column (deep|shallow)
  - Edge Function parse-task: ghi rõ suy task_type (NLP classify only, không reasoning), chưa smoke live quota
  - Models: thêm TaskType, ScheduledBlock, ScheduleResult; TaskPriority.sortRank
  - Services: thêm SchedulingEngine description (greedy earliest-fit, deterministic sort, no LLM)
  - Test count: 10 → 17 unit (SchedulingEngineTests 5/5 criteria + overflow), UITest vẫn 5

**Trạng thái module ghi nhận:** issue 001 auth (done), 002 Task capture (done), 003 Habit (done), 004 Scheduling Engine (done ← vừa rồi). Test app-total: 17 unit + 5 UITest. Engine CHƯA wire vào UI "Today" (mới test độc lập per criteria).

**Xác minh vs lời leader & Decision Log:** khớp code thật — engine thuần deterministic (greedy), task_type classification NLP parse only (không reasoning), busy-block avoidance, buffer rule cố định, unscheduled overflow. Backlog Nit (edge-case test, UUID helper) ghi trong issue, chưa làm. Edge Function task_type classify chưa smoke live (Gemini quota limit:0 nhất quán issue 002). Commits chính: 9a29055/02241e9/88ecdfa/5fa0515/a61e63f.

---

## [2026-07-05] update | Task creation (issue 002 done) — Gemini NLP parse + mock test seam

**Agent:** librarian
**Operation:** Update (triggered by reviewer PASS issue 002 — Gemini NLP parse + task CRUD complete)
**Files reviewed:**
- `supabase/migrations/20260704044752_create_tasks.sql` (bảng tasks, RLS 4 policy `auth.uid()=user_id`)
- `supabase/functions/parse-task/index.ts` (Deno, Gemini 2.0-flash structured output, verify_jwt, cap input 1000 chars)
- `FocusPlan/Sources/Models/{TaskItem,TaskPriority,ParsedTaskDraft}.swift`
- `FocusPlan/Sources/Services/{TaskParseService,TaskRepository}.swift` (test-seam env `UITEST_MOCK_PARSE_DRAFT`)
- `FocusPlan/Sources/ViewModels/TaskListViewModel.swift`
- `FocusPlan/Sources/Views/{AddTaskView,TaskFormView,TaskListView}.swift`
- `.claude/wiki/issues/002-task-creation-gemini-nlp-parse.md` (4/4 criteria ✓, QA verify section added)
- `.claude/wiki/decisions/focus-scheduler-decision-log.md` (dòng 22-24 "Gemini chỉ NLP parse, không reasoning" ✓)

**Pages updated:**
- `.claude/wiki/architecture.md` — update mục "Vận hành & session": rõ Edge Function + DB deployed ACTIVE; mock test pass (seam env); Gemini live CHƯA QA do API key hết quota (billing chưa bật). Cập nhật test count: 3 UITest → 5 UITest (thêm 2 test từ issue 002: parse + isolation).

**Trạng thái module ghi nhận:** issue 001 auth (done), issue 002 Task capture (done — Edge Function deployed, mock test pass, Gemini live chưa QA quota), issue 003 Habit (done). Test app-total: 10 unit + 5 UITest.

**Xác minh vs lời leader:** khớp code thật — Edge Function proxy Gemini 2.0 Flash (parse only, no reasoning), bảng tasks + RLS 4 policy, test-seam pattern env-gated (UITEST_MOCK_PARSE_DRAFT), Supabase real, User isolation verified. Caveat: Gemini API quota hết (`limit: 0`) → khi billing bật nên QA thủ công live Gemini. Commit chính: `fe155d2` (E2E mock seam+test), `06d3624` (cap input), `032d87f` (isolation test). Issue 003 fix test-harness riêng (commit `9633859`), không đổi scope 003.

---

## [2026-07-04] update | Habit/Routine module + Task module + tab navigation (issue 003 done)

**Agent:** librarian
**Operation:** Update (triggered by coder changes — issue 003 done; đồng thời sync module Task issue 002 chưa từng vào wiki)
**Files reviewed:**
- `supabase/migrations/20260704051538_create_habits.sql` (habits + habit_logs, RLS 4 policy/bảng, unique(habit_id,log_date))
- `supabase/migrations/20260704044752_create_tasks.sql`, `supabase/functions/parse-task/index.ts` (Gemini `gemini-2.0-flash`, verify_jwt)
- `FocusPlan/Sources/Models/{Habit,HabitLog,BusyBlock}.swift`
- `FocusPlan/Sources/Services/{HabitRepository,HabitBusyBlockService}.swift`
- `FocusPlan/Sources/Views/{MainTabView,RootView}.swift`
- Đối chiếu Task module: `Services/{TaskParseService,TaskRepository}`, `Models/{TaskItem,ParsedTaskDraft}`
- Test counts qua `grep -c 'func test'`; issue 002 (in-progress) / 003 (done) frontmatter

**Pages updated:**
- `.claude/wiki/architecture.md` — overwrite mục "App: Focus Plan": cấu trúc lại thành Setup/Backend/Client architecture/Vận hành/Test/Tech debt. Thêm: 3 bảng Supabase (tasks/habits/habit_logs) + RLS + Edge Function parse-task; phân lớp Models→Services→ViewModels→Views; `HabitBusyBlockService` là interface busy-block cho Scheduling Engine (issue 004); navigation đổi sang `MainTabView` 2 tab (sửa mô tả cũ sai "HomeView empty-state / RootView route trực tiếp"); tech-debt RLS habit_logs chưa kiểm ownership habit_id. Thêm `supabase/` vào cấu trúc thư mục.

**Trạng thái module ghi nhận:** issue 001 auth (done), issue 002 Task capture (in-progress — code xong, QA parse chờ Gemini billing), issue 003 Habit (done). Test app-total: 10 unit + 3 UITest.

**Xác minh vs lời leader:** khớp code thật — 2 bảng mới + RLS đúng mô tả, `HabitBusyBlockService` là hàm thuần deterministic, `RootView.signedIn` → `MainTabView` TabView 2 tab, tech-debt RLS habit_logs đúng như leader nêu.

---

## [2026-07-03] update | FocusPlan iOS app shell + Supabase auth (issue 001)

**Agent:** librarian
**Operation:** Update (triggered by coder changes — lần đầu repo có codebase native Swift/iOS thật)
**Files reviewed:**
- `FocusPlan/project.yml`, `FocusPlan/.gitignore`
- `FocusPlan/Sources/FocusPlanApp.swift`, `Support/SupabaseConfig.swift`, `Support/SupabaseManager.swift`
- `FocusPlan/Sources/Auth/AuthViewModel.swift`, `Auth/AuthValidation.swift`
- `FocusPlan/Sources/Views/RootView.swift` (+ Home/SignIn/SignUp)
- `FocusPlan/Resources/Info.plist`, `Config/Secrets.example.xcconfig`
- `FocusPlan/FocusPlan.xcodeproj/.../Package.resolved` (xác minh supabase-swift 2.48.0)
- `git ls-files` (xác minh `.xcodeproj` + `Secrets.xcconfig` không track)
- `.claude/wiki/issues/001-ios-app-shell-supabase-auth.md` (status: done)

**Pages updated:**
- `.claude/wiki/architecture.md` — thêm mục "Tổng quan" + "App: Focus Plan (`FocusPlan/`)" mô tả stack (SwiftUI/XcodeGen/SPM/supabase-swift 2.48.0), cấu trúc Sources, config qua Info.plist, session persistence do supabase-swift lo, test unit + XCUITest, ràng buộc `mailer_autoconfirm`. Thêm `FocusPlan/` và `focus_plan_ui_demo/` (throwaway Flutter prototype) vào cấu trúc thư mục để tránh nhầm lẫn.

**Xác minh vs lời leader:** tất cả khớp code thật — `.xcodeproj` không commit, `Secrets.xcconfig` gitignored, supabase-swift 2.48.0, session dựa `.initialSession`, không có lớp lưu trữ tự viết.

---
