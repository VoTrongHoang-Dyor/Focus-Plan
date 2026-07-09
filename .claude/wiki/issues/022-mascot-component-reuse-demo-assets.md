---
status: done
---

## Parent PRD

`.claude/wiki/prd/focusplan-swift-mascot-mcp-web.md`

## What to build

Component SwiftUI `MascotView(size:)` tái dùng asset PNG tách layer từ Flutter demo (`focus_plan_ui_demo/assets/images/mascot_body.png` + `mascot_arm.png`) với animation tương đương bản demo (ngó nghiêng / nhún / vẫy tay). Kích thước cố định theo màn, phong cách Duolingo: gắn vào HomeView (bản nhỏ) và AlarmFormView (bản to + tagline trang trí). KHÔNG tạo asset mới, KHÔNG làm onboarding screen.

## Acceptance criteria

- [x] `MascotView(size:)` là component duy nhất, thêm vào màn mới chỉ mất một dòng.
- [x] Asset PNG body/arm được import vào app Swift (bundle/asset catalog), hiển thị nền trong suốt đúng như demo.
- [x] Animation ngó nghiêng/nhún/vẫy chạy mượt tương đương bản Flutter demo.
- [x] HomeView hiển thị mascot nhỏ; AlarmFormView hiển thị mascot to + tagline — đúng quyết định "to/nhỏ theo màn".
- [x] Test suite xanh (mascot không cần unit test animation — verify qua build + hiển thị).

## Blocked by

- Blocked by `.claude/wiki/issues/021-alarm-form-view-smart-alarm-template.md`

## User stories addressed

- User story 10 (mascot to + tagline ở màn alarm)
- User story 11 (mascot nhỏ ở Home)
- User story 12 (animation sống động)
- User story 13 (component 1 dòng)
