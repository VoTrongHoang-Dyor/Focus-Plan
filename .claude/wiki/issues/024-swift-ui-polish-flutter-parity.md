---
status: done
---

## Plan gốc

`docs/superpowers/plans/2026-07-05-swift-ui-polish-flutter-parity.md`

## What to build

Restyle các màn SwiftUI hiện có của `FocusPlan/` đạt chất lượng visual của bản Flutter demo (`focus_plan_ui_demo/`), theo Tasks 2-6 của plan gốc + phần asset còn thiếu của Task 1. Không đổi logic/hành vi, không tạo màn mới, không thêm mascot (issue 022 riêng).

**Phần đã xong:** Task 1 của plan — chỉ `Theme.swift` + `ThemeTests.swift` đã được hoàn thành trong plan issue 021 (`docs/superpowers/plans/2026-07-06-alarm-form-view-smart-alarm-template.md`).

**Phần cần làm:** Issue 024 thực hiện:
- Phần asset Task 1 chưa hoàn thành: `Assets.xcassets` imageset `BrandLogo` (copy từ `focus_plan_ui_demo/assets/images/logo.png`), colorset `AccentColor` #4F46E5 — cần cho Task 2 (auth screens sử dụng logo).
- Tasks 2-6 phía sau (restyle auth, home, task, habit).

**Tasks cần thực hiện:**
- **Task 2:** Auth screens restyle (SignIn + SignUp) — đọc reference Dart (`sign_in_screen.dart`, `sign_up_screen.dart`), apply Theme tokens, filled textfield style, logo, centered layout.
- **Task 3:** Home + MainTabView — greeting block, speech bubble, day chips, section header, tint tab bar.
- **Task 4:** Task list + task forms — card style row, empty state, input filled, CTA prominent.
- **Task 5:** Habits screens — summary header card, list card section, empty state, progress ring.
- **Task 6:** Full-suite verification + screenshot evidence.

Giữ nguyên 100%: tất cả `accessibilityIdentifier` từ issue 019, logic/navigation, `accessibilityLabel` hiện có, test suite (35 unit + 7 UITest phải xanh — cộng từ 021/022 mới).

## Acceptance criteria

- [x] Auth screens restyle đạt parity Flutter demo (Theme.primary, filled style, logo 120pt, centered, "Chào mừng bạn quay lại" subtitle) — build xanh, AuthFlowUITests + A11yIdentifierUITests pass.
- [x] Home + MainTabView: greeting block, speech bubble, day chips, section header — build xanh, HomeView logic giữ nguyên (greetingText identifier vẫn query được).
- [x] Task list + forms: card style row, empty state pattern, badge priority — build xanh, TaskFlowUITests pass.
- [x] Habits screens: summary card, progress ring, list card section, empty state — build xanh, HabitFlowUITests pass.
- [x] Full suite: 26 unit + 44 UITest xanh, 0 skip, 0 fail. Screenshot evidence 8 png lưu `docs/superpowers/plans/evidence/2026-07-05-ui-polish/` (auth, home, task-list, task-form, habits-list, habits-form, evidence collection).
- [x] Mọi `accessibilityIdentifier` + `accessibilityLabel` giữ nguyên sau restyle — MCP driver (issue 020) + UITest vẫn query được đúng.

## Blocked by

- `.claude/wiki/issues/021-alarm-form-view-smart-alarm-template.md` — Task 1 (Theme.swift + asset) nằm ở plan 021, issue 024 phải chờ Theme có sẵn.
- `.claude/wiki/issues/022-mascot-component-reuse-demo-assets.md` — Restyling các màn (chủ yếu Home + AlarmFormView) cùng lúc với việc gắn mascot (issue 022) sẽ conflict layout. Xếp issue 024 SAU 021/022 để restyle một lần trên cơ sở đã có Theme + Mascot.

## Notes

- Issue 023 (CI/CD) **không block** issue 024 — là parallel/optional. Issue 024 có thể chạy ngay sau 021✓ + 022✓ hoàn tất. Task 6 verification (full-suite) có thể chạy tay hoặc qua CI nếu 023 sẵn sàng.

## User stories addressed

- User story 1, 2, 20 (accessibility naming convention) từ PRD cha — issue 019 đã cover, issue 024 giữ nguyên.
- Các story của issue 021 (AlarmFormView), 022 (Mascot) không nhập — khác workstream.
