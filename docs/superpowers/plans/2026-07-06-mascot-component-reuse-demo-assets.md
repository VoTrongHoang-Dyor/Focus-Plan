# MascotView — Reuse Demo Assets Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Component SwiftUI `MascotView(size:)` port 1:1 từ Flutter demo (2 layer PNG + animation ngó nghiêng/nhún/vẫy 1700ms), gắn vào HomeView (nhỏ, 64) và AlarmFormView (to, 120 + tagline) — issue 022.

**Architecture:** Copy 2 PNG tách layer từ `focus_plan_ui_demo/assets/images/` vào asset catalog mới `FocusPlan/Resources/Assets.xcassets` (catalog này issue 024 sẽ thêm BrandLogo/AccentColor sau — KHÔNG tạo ở đây). `MascotView` là 1 file duy nhất: ZStack body + arm xoay quanh pivot vai, 3 animation autoreverse. Mascot + tagline **decorative** → `accessibilityHidden(true)` để không nhiễu `screen_elements` của MCP (issue 020).

**Tech Stack:** SwiftUI (iOS 17), XcodeGen (`Resources/` đã include theo folder trong `project.yml` — KHÔNG sửa project.yml, chỉ `xcodegen generate`), XCTest/XCUITest suite hiện có.

## Spec animation (port từ `focus_plan_ui_demo/lib/widgets/brand.dart` — ĐỌC file này trước khi code)

Canvas 2 PNG: **189×341** (body + arm cùng canvas, chồng khít). Pivot khớp vai: **(151, 118)** tọa độ canvas → `UnitPoint(x: 151/189, y: 118/341)`. Driver demo: 1 controller 1700ms easeInOut autoreverse, `v` chạy 0→1→0:

| Hiệu ứng | Demo (theo v) | Port SwiftUI (autoreverse tương đương) |
|---|---|---|
| Ngó nghiêng toàn thân | `(v-0.5)*0.26` rad → ±0.13 rad | rotate −0.13 ↔ +0.13 rad, 1.7s autoreverse |
| Nhún trục Y | `-sin(v·π)*3` pt → 0→−3→0 mỗi chu kỳ 1.7s | offset y: 0 ↔ −3 pt, **0.85s** autoreverse (nửa chu kỳ = đúng hình sin demo) |
| Vẫy tay quanh pivot | `-0.07 + v*0.27` rad → −0.07..+0.20 | rotate arm −0.07 ↔ +0.20 rad, 1.7s autoreverse |

## Global Constraints

- **KHÔNG tạo asset mới** — chỉ copy `mascot_body.png` + `mascot_arm.png` từ demo (Decision Log đã chốt). KHÔNG import `logo.png` (BrandLogo thuộc issue 024). KHÔNG làm onboarding screen.
- **KHÔNG đổi** bất kỳ `accessibilityIdentifier`/logic/navigation hiện có — chỉ THÊM view. Mascot + tagline mới đều `accessibilityHidden(true)` (không thêm identifier mới → bảng `FocusPlan/docs/accessibility-identifiers.md` không đổi).
- Kích thước đã chốt (Decision Log): HomeView **64** (theo demo `home_screen.dart:110`), AlarmFormView **120**. Tagline màn alarm (copy chốt): **"Cùng dậy đúng giờ nào!"** — KHÔNG đụng hint text `alarmform.hint-text` ("You can do it") hiện có.
- Test suite phải xanh sau MỖI task (animation không cần unit test — acceptance chốt verify qua build + hiển thị). Lệnh chạy trong `FocusPlan/`:
  - Generate + build: `xcodegen generate && xcodebuild -project FocusPlan.xcodeproj -scheme FocusPlan -destination 'generic/platform=iOS Simulator' build`
  - Full suite: `xcodebuild -project FocusPlan.xcodeproj -scheme FocusPlan -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test`
- Chi tiết thẩm mỹ nhỏ (spacing quanh mascot, font tagline) coder tự quyết bằng skill `ui-ux-pro-max` (stack SwiftUI).
- Commit sau mỗi task, message tiếng Anh, prefix `feat(ios):`.

---

### Task 1: Asset catalog + MascotView component

**Files:**
- Create: `FocusPlan/Resources/Assets.xcassets/Contents.json`
- Create: `FocusPlan/Resources/Assets.xcassets/MascotBody.imageset/` (Contents.json + `mascot_body.png` copy từ demo)
- Create: `FocusPlan/Resources/Assets.xcassets/MascotArm.imageset/` (Contents.json + `mascot_arm.png` copy từ demo)
- Create: `FocusPlan/Sources/Views/MascotView.swift`

**Interfaces:**
- Produces: `struct MascotView: View` — `init(size: CGFloat)`; asset names `"MascotBody"`, `"MascotArm"`. Task 2/3 chỉ cần `MascotView(size:)` một dòng (acceptance criteria 1).

- [ ] **Step 1: Tạo asset catalog** — chạy từ repo root:

```bash
mkdir -p FocusPlan/Resources/Assets.xcassets/MascotBody.imageset FocusPlan/Resources/Assets.xcassets/MascotArm.imageset
cp focus_plan_ui_demo/assets/images/mascot_body.png FocusPlan/Resources/Assets.xcassets/MascotBody.imageset/
cp focus_plan_ui_demo/assets/images/mascot_arm.png FocusPlan/Resources/Assets.xcassets/MascotArm.imageset/
```

`FocusPlan/Resources/Assets.xcassets/Contents.json`:

```json
{
  "info" : { "author" : "xcode", "version" : 1 }
}
```

`FocusPlan/Resources/Assets.xcassets/MascotBody.imageset/Contents.json`:

```json
{
  "images" : [
    { "filename" : "mascot_body.png", "idiom" : "universal", "scale" : "1x" },
    { "idiom" : "universal", "scale" : "2x" },
    { "idiom" : "universal", "scale" : "3x" }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
```

`MascotArm.imageset/Contents.json`: y hệt, thay filename `mascot_arm.png`.

- [ ] **Step 2: Implement `MascotView.swift`:**

```swift
import SwiftUI

/// Linh vật Focus Plan — port từ Flutter demo (focus_plan_ui_demo/lib/widgets/brand.dart).
/// 2 layer PNG cùng canvas 189x341: thân + tay xoay quanh khớp vai (151,118).
/// Decorative: accessibilityHidden để không nhiễu screen_elements của MCP (issue 020).
struct MascotView: View {
    let size: CGFloat

    private static let artAspect: CGFloat = 189.0 / 341.0
    private static let armPivot = UnitPoint(x: 151.0 / 189.0, y: 118.0 / 341.0)

    @State private var sway = false   // ngó nghiêng ±0.13 rad + vẫy tay, 1.7s autoreverse
    @State private var bob = false    // nhún 0 → -3pt, 0.85s autoreverse (≈ sin của demo)

    var body: some View {
        ZStack {
            Image("MascotBody").resizable()
            Image("MascotArm").resizable()
                .rotationEffect(.radians(sway ? 0.20 : -0.07), anchor: Self.armPivot)
        }
        .aspectRatio(Self.artAspect, contentMode: .fit)
        .frame(height: size)
        .rotationEffect(.radians(sway ? 0.13 : -0.13))
        .offset(y: bob ? -3 : 0)
        .accessibilityHidden(true)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.7).repeatForever(autoreverses: true)) {
                sway = true
            }
            withAnimation(.easeInOut(duration: 0.85).repeatForever(autoreverses: true)) {
                bob = true
            }
        }
    }
}
```

- [ ] **Step 3: Build + verify hiển thị** — `xcodegen generate && xcodebuild ... build` PASS. Verify nền trong suốt + animation: boot simulator, gắn tạm `MascotView(size: 120)` vào Preview hoặc dùng bước Task 4 (không commit code tạm).
- [ ] **Step 4: Full suite xanh** (chưa gắn vào màn nào → suite không đổi hành vi).
- [ ] **Step 5: Commit** — `git commit -m "feat(ios): MascotView component ported from Flutter demo with layered PNG animation"`

---

### Task 2: Gắn mascot nhỏ vào HomeView (size 64)

**Files:**
- Modify: `FocusPlan/Sources/Views/HomeView.swift` (chỉ khối greeting đầu VStack)
- Reference: `focus_plan_ui_demo/lib/screens/home_screen.dart:100-112` (greeting bên trái, `Mascot(size: 64)` bên phải)

**Interfaces:**
- Consumes: `MascotView(size:)` (Task 1).

- [ ] **Step 1:** Bọc greeting hiện có vào HStack — GIỮ NGUYÊN mọi modifier + identifier của Text:

```swift
// TRƯỚC:
//     Text("Xin chào, \(email)").font(.headline)
//         .lineLimit(1)
//         .truncationMode(.tail)
//         .accessibilityIdentifier(A11yID.Home.greetingText)
// SAU:
                HStack(alignment: .center, spacing: 12) {
                    Text("Xin chào, \(email)").font(.headline)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .accessibilityIdentifier(A11yID.Home.greetingText)
                    Spacer()
                    MascotView(size: 64)
                }
```

- [ ] **Step 2: Verify** — build PASS + chạy UITest liên quan Home: `-only-testing:FocusPlanUITests/A11yIdentifierUITests -only-testing:FocusPlanUITests/AuthFlowUITests`. Expected: PASS (greeting identifier còn nguyên, mascot hidden không nhiễu).
- [ ] **Step 3: Commit** — `git commit -m "feat(ios): small mascot beside HomeView greeting (demo parity, size 64)"`

---

### Task 3: Gắn mascot to + tagline vào AlarmFormView (size 120)

**Files:**
- Modify: `FocusPlan/Sources/Views/AlarmFormView.swift` (chỉ THÊM block đầu VStack trong ScrollView, trước `timeCard`)

**Interfaces:**
- Consumes: `MascotView(size:)` (Task 1), `Theme.onSurfaceVariant` (có sẵn).

- [ ] **Step 1:** Thêm header mascot TRƯỚC `timeCard` trong `VStack(spacing: 20)`:

```swift
                    VStack(spacing: 8) {
                        MascotView(size: 120)
                        Text("Cùng dậy đúng giờ nào!")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Theme.onSurfaceVariant)
                            .accessibilityHidden(true)
                    }
```

KHÔNG đổi gì khác: `timeCard`, các identifier `alarmform.*`, hint text "You can do it" giữ nguyên vị trí/identifier.

- [ ] **Step 2: Verify** — build PASS + `-only-testing:FocusPlanUITests/AlarmFlowUITests`. Expected: PASS (mascot/tagline hidden, mọi identifier alarm form còn query được; nếu form dài hơn màn hình làm tap trượt → thêm `app.swipeUp()` trong test là KHÔNG được phép sửa test cũ tùy tiện — thay vào đó giảm spacing/size header theo `ui-ux-pro-max`, giữ test nguyên).
- [ ] **Step 3: Commit** — `git commit -m "feat(ios): large mascot with tagline on AlarmFormView header (size 120)"`

---

### Task 4: Evidence hiển thị + full suite

**Files:**
- Create: `docs/superpowers/plans/evidence/2026-07-06-mascot/home.png`, `alarm-form.png`

- [ ] **Step 1: Chụp evidence** — boot simulator "iPhone 17 Pro", launch app (có thể dùng MCP driver `tools/focusplan-mcp` hoặc xcrun trực tiếp), vào Home và AlarmFormView, chụp:

```bash
mkdir -p docs/superpowers/plans/evidence/2026-07-06-mascot
xcrun simctl io booted screenshot docs/superpowers/plans/evidence/2026-07-06-mascot/home.png
# mở AlarmFormView rồi:
xcrun simctl io booted screenshot docs/superpowers/plans/evidence/2026-07-06-mascot/alarm-form.png
```

Đối chiếu bằng mắt (skill `ui-ux-pro-max`): nền PNG trong suốt, mascot không méo (aspect 189:341), animation chạy (ngó nghiêng/nhún/vẫy), Home nhỏ - AlarmForm to + tagline.

- [ ] **Step 2: Full suite** — `xcodegen generate && xcodebuild -project FocusPlan.xcodeproj -scheme FocusPlan -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test`. Expected: PASS toàn bộ (37 unit + toàn bộ UITest). Đây là tiêu chí done cuối issue 022.
- [ ] **Step 3: Commit** — `git commit -m "docs(ios): mascot display evidence screenshots"`

---

## Acceptance criteria mapping (issue 022)

| Criteria | Task |
|---|---|
| `MascotView(size:)` component duy nhất, gắn màn mới 1 dòng | Task 1 (Task 2/3 chứng minh: mỗi call-site đúng 1 dòng `MascotView(size:)`) |
| Asset PNG body/arm import vào bundle, nền trong suốt đúng demo | Task 1 + Task 4 (evidence) |
| Animation ngó nghiêng/nhún/vẫy mượt tương đương demo | Task 1 (spec bảng animation) + Task 4 (verify mắt) |
| HomeView mascot nhỏ; AlarmFormView mascot to + tagline | Task 2 (64) + Task 3 (120 + "Cùng dậy đúng giờ nào!") |
| Test suite xanh (không cần unit test animation) | Task 2/3 (targeted UITest) + Task 4 (full suite) |
