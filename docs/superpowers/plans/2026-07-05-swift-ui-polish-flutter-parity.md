# Swift UI Polish — Flutter Demo Parity Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Nâng giao diện các màn SwiftUI hiện có của `FocusPlan/` đạt chất lượng visual của bản Flutter demo (`focus_plan_ui_demo/`), không đổi hành vi/logic, không port màn mới.

**Architecture:** Thêm 1 theme layer tập trung (`Theme.swift` — token màu/bo góc/spacing port từ demo) + asset catalog (logo). Sau đó restyle từng nhóm màn theo cấu trúc visual của file Dart tương ứng. Logic (ViewModel/Service), navigation, và toàn bộ `accessibilityIdentifier` (issue 019) giữ nguyên tuyệt đối.

**Tech Stack:** SwiftUI (iOS 17), XcodeGen (`FocusPlan/project.yml`, chạy `xcodegen generate` sau khi thêm file/resource), XCTest + XCUITest.

## Global Constraints

- **Reference = spec:** file Dart trong `focus_plan_ui_demo/lib/` là chuẩn visual. Mỗi task ghi rõ file Dart tham chiếu — đọc nó trước khi code.
- **Design judgment:** chi tiết thẩm mỹ (shadow, độ đậm màu container, animation nhỏ) coder tự quyết bằng skill `ui-ux-pro-max` (stack: SwiftUI) — nhưng token màu, corner radius, cấu trúc layout liệt kê trong plan là BẮT BUỘC theo demo.
- **KHÔNG đụng:** mascot (issue 022 riêng — không import `mascot_body.png`/`mascot_arm.png`, không tạo MascotView), màn Alarm (issue 021), các màn demo chưa có bên Swift (splash/stats/reflection).
- **Giữ nguyên 100%** mọi `accessibilityIdentifier` từ `A11yID` (issue 019) và mọi `accessibilityLabel` hiện có — UITest + MCP driver (issue 020) phụ thuộc chúng.
- **Test suite phải xanh sau MỖI task:** 26 unit test + 6 UITest. Lệnh chạy trong `FocusPlan/`:
  - Build: `xcodegen generate && xcodebuild -project FocusPlan.xcodeproj -scheme FocusPlan -destination 'generic/platform=iOS Simulator' build`
  - Test: `xcodebuild -project FocusPlan.xcodeproj -scheme FocusPlan -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test`
- Token màu gốc từ demo: **primary indigo `#4F46E5`** (seed của `ColorScheme.fromSeed` Material 3), **done emerald `#059669`** (`habits_screen.dart:19`), corner radius **14** (input/CTA auth), **16** (day chip), **20** (card/summary), CTA cao **52pt**.
- Copy tiếng Việt lấy đúng nguyên văn từ demo (vd "Xin chào,", "Chào mừng bạn quay lại", "Lịch hôm nay", "Thói quen hôm nay", "Đã hoàn thành X/Y").
- Commit sau mỗi task, message tiếng Anh `style(ui): ...`.

---

### Task 1: Theme layer + asset catalog (logo)

**Files:**
- Create: `FocusPlan/Sources/Support/Theme.swift`
- Create: `FocusPlan/Resources/Assets.xcassets` (asset `BrandLogo` từ `focus_plan_ui_demo/assets/images/logo.png`, asset `AccentColor` = indigo)
- Modify: `FocusPlan/project.yml` (chỉ nếu `Resources/` chưa được include dạng folder — kiểm tra trước, nhiều khả năng đã include vì Info.plist nằm đó)
- Test: `FocusPlan/Tests/ThemeTests.swift`

**Interfaces:**
- Produces: `enum Theme` — token mà mọi task sau dùng: `Theme.primary`, `Theme.primaryContainer`, `Theme.onPrimaryContainer`, `Theme.done`, `Theme.surfaceVariant`, `Theme.onSurfaceVariant`, `Theme.radiusInput` (14), `Theme.radiusChip` (16), `Theme.radiusCard` (20), `Theme.ctaHeight` (52), helper `Color(hex:)`.

- [ ] **Step 1: Viết failing test** — `ThemeTests.swift`:

```swift
import XCTest
@testable import FocusPlan

final class ThemeTests: XCTestCase {
    func testHexColorParsesIndigoSeed() {
        // #4F46E5 → r=0x4F, g=0x46, b=0xE5 (so khớp components)
        let c = UIColor(Theme.primary)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        c.getRed(&r, green: &g, blue: &b, alpha: &a)
        XCTAssertEqual(r, 0x4F/255, accuracy: 0.01)
        XCTAssertEqual(g, 0x46/255, accuracy: 0.01)
        XCTAssertEqual(b, 0xE5/255, accuracy: 0.01)
    }

    func testRadiusAndSizeTokens() {
        XCTAssertEqual(Theme.radiusInput, 14)
        XCTAssertEqual(Theme.radiusChip, 16)
        XCTAssertEqual(Theme.radiusCard, 20)
        XCTAssertEqual(Theme.ctaHeight, 52)
    }
}
```

- [ ] **Step 2: Run test → FAIL** ("cannot find 'Theme'").
- [ ] **Step 3: Implement `Theme.swift`:**

```swift
import SwiftUI

/// Design tokens port từ focus_plan_ui_demo (Material 3, seed #4F46E5).
/// Mọi view dùng token này — không hardcode màu/radius trong view.
enum Theme {
    // Màu (light scheme; derive container từ seed theo tinh thần M3 —
    // giá trị derive cụ thể coder chốt bằng ui-ux-pro-max, giữ đúng hue indigo)
    static let primary = Color(hex: 0x4F46E5)
    static let primaryContainer = Color(hex: 0xE0E7FF)   // indigo 100
    static let onPrimaryContainer = Color(hex: 0x312E81) // indigo 900
    static let secondaryContainer = Color(hex: 0xE0E7FF)
    static let done = Color(hex: 0x059669)               // emerald 600
    static let surfaceVariant = Color(.secondarySystemBackground)
    static let onSurfaceVariant = Color(.secondaryLabel)

    // Shape / size
    static let radiusInput: CGFloat = 14
    static let radiusChip: CGFloat = 16
    static let radiusCard: CGFloat = 20
    static let ctaHeight: CGFloat = 52
}

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}
```

- [ ] **Step 4: Tạo `Assets.xcassets`** — imageset `BrandLogo` (copy `focus_plan_ui_demo/assets/images/logo.png` vào, 1x là đủ), colorset `AccentColor` = #4F46E5. Kiểm tra `project.yml`: nếu `Resources/` chưa vào target dạng folder-resource thì thêm; chạy `xcodegen generate` và xác nhận asset nằm trong app bundle.
- [ ] **Step 5: Run test → PASS**, build xanh, toàn bộ unit test cũ xanh.
- [ ] **Step 6: Commit** `style(ui): add Theme tokens + brand asset catalog ported from Flutter demo`

---

### Task 2: Auth screens (SignIn + SignUp)

**Files:**
- Modify: `FocusPlan/Sources/Views/SignInView.swift`
- Modify: `FocusPlan/Sources/Views/SignUpView.swift`
- Reference: `focus_plan_ui_demo/lib/screens/sign_in_screen.dart`, `sign_up_screen.dart`, `widgets/auth_style.dart`, `widgets/brand.dart` (BrandLogo height 120)

**Interfaces:**
- Consumes: `Theme.*`, asset `BrandLogo` (Task 1).
- Produces: private style helpers dùng chung 2 màn (vd `AuthTextFieldStyle`) — nếu tách file thì đặt `FocusPlan/Sources/Views/AuthStyle.swift`.

**Cấu trúc bắt buộc theo demo (sign_in_screen.dart:60-121):**
1. Logo `Image("BrandLogo")` height 120, giữa màn.
2. Headline "Đăng nhập" / "Tạo tài khoản" + subtitle xám ("Chào mừng bạn quay lại").
3. TextField dạng **filled** (nền `Theme.surfaceVariant`, bo `radiusInput`, KHÔNG viền, prefix icon `envelope`/`lock`) — thay `.textFieldStyle(.roundedBorder)` hiện tại.
4. CTA filled cao `ctaHeight`, bo `radiusInput`, nền `Theme.primary` — giữ nguyên ProgressView khi submitting.
5. Link chuyển màn dạng TextButton như hiện tại.
6. Nội dung căn giữa dọc màn (demo dùng `mainAxisAlignment: center`) thay vì dồn lên trên.

- [ ] **Step 1:** Đọc 2 file Dart reference + chạy `ui-ux-pro-max` cho quyết định chi tiết còn lại.
- [ ] **Step 2:** Restyle `SignInView.swift` — giữ nguyên: toàn bộ `A11yID.SignIn.*`, logic `submit()`, binding `auth`.
- [ ] **Step 3:** Restyle `SignUpView.swift` cùng ngôn ngữ visual — giữ nguyên `A11yID.SignUp.*` (kể cả `infoText`).
- [ ] **Step 4: Verify** — build + `-only-testing:FocusPlanUITests/AuthFlowUITests` + `-only-testing:FocusPlanUITests/A11yIdentifierUITests` → PASS.
- [ ] **Step 5: Commit** `style(ui): polish auth screens to Flutter demo parity`

---

### Task 3: Home + MainTabView

**Files:**
- Modify: `FocusPlan/Sources/Views/HomeView.swift`
- Modify: `FocusPlan/Sources/Views/MainTabView.swift`
- Reference: `focus_plan_ui_demo/lib/screens/home_screen.dart`

**Interfaces:**
- Consumes: `Theme.*`.
- Produces: private view `SpeechBubble(text:)` trong HomeView (Task này KHÔNG thêm mascot — chừa sẵn chỗ trong HStack greeting để issue 022 gắn `MascotView` sau).

**Cấu trúc bắt buộc theo demo (home_screen.dart:80-176):**
1. Greeting block: "Xin chào," (bodyMedium, màu `onSurfaceVariant`) trên dòng riêng + display name (titleLarge, w700) — thay dòng đơn `"Xin chào, \(email)"` hiện tại nhưng **`A11yID.Home.greetingText` phải vẫn gắn vào text chứa email/tên** (UITest assert tồn tại).
2. Speech bubble "Hôm nay mình cùng tập trung nhé!" — nền `secondaryContainer`, bo 14, padding 12×8 (home_screen.dart:180-202).
3. Day chips: giữ logic hiện có, đổi màu theo token (`Theme.primary` cho today, `surfaceVariant` cho ngày khác), width 48, bo `radiusChip`.
4. Section header "Lịch hôm nay" + đếm "X việc" (bodySmall xám, baseline-aligned) phía trên `TaskListView()`.
5. `MainTabView`: thêm `.tint(Theme.primary)`.

- [ ] **Step 1:** Đọc reference + restyle theo cấu trúc trên (ui-ux-pro-max cho chi tiết).
- [ ] **Step 2: Verify** — build + full UITest suite → PASS (chú ý `home.greeting-text`, `home.sign-out-button` còn query được).
- [ ] **Step 3: Commit** `style(ui): polish Home + tab bar to Flutter demo parity`

---

### Task 4: Task list + task forms

**Files:**
- Modify: `FocusPlan/Sources/Views/TaskListView.swift`
- Modify: `FocusPlan/Sources/Views/AddTaskView.swift`
- Modify: `FocusPlan/Sources/Views/TaskFormView.swift`
- Reference: `focus_plan_ui_demo/lib/widgets/schedule_timeline.dart` (ngôn ngữ card: nền surface, bo góc, badge màu theo loại), `habits_screen.dart` (pattern form/empty-state)

**Yêu cầu:**
1. Row task → card style: nền surface, bo `radiusCard` hoặc list-section bo góc, badge priority màu (high=đỏ/medium=cam/low=xám — coder chốt shade qua ui-ux-pro-max, nhất quán token).
2. Empty state: icon + title + subtitle xám + CTA — pattern như `_EmptyState` demo (habits_screen.dart:410-449), KHÔNG mascot.
3. AddTaskView/TaskFormView: input filled bo `radiusInput` đồng bộ auth, nút Save/CTA prominent `Theme.primary`.
4. Giữ nguyên: `A11yID.TaskList.*` (kể cả `row(_:)` động), `A11yID.AddTask.*`, `A11yID.TaskForm.*`, mọi logic parse/save.

- [ ] **Step 1:** Đọc reference + restyle 3 file.
- [ ] **Step 2: Verify** — build + `-only-testing:FocusPlanUITests/TaskFlowUITests` + `A11yIdentifierUITests` → PASS.
- [ ] **Step 3: Commit** `style(ui): polish task list and task forms`

---

### Task 5: Habits screens

**Files:**
- Modify: `FocusPlan/Sources/Views/HabitsView.swift`
- Modify: `FocusPlan/Sources/Views/HabitFormView.swift`
- Reference: `focus_plan_ui_demo/lib/screens/habits_screen.dart`

**Yêu cầu (habits_screen.dart:136-262):**
1. Summary header card: nền `primaryContainer`, bo `radiusCard`, "Thói quen hôm nay" + "Đã hoàn thành X/Y" + progress ring % (dựng bằng `Circle().trim(from:to:)`).
2. List habit → card section bo `radiusCard` viền mảnh, divider indent; nút done dùng `Theme.done` (emerald) thay `.green`, missed dùng đỏ hệ thống.
3. Empty state theo pattern demo (KHÔNG mascot).
4. HabitFormView: input filled đồng bộ, CTA prominent.
5. **Ràng buộc test:** `HabitFlowUITests` hiện định vị bằng `accessibilityLabel` + text ("Thêm thói quen", "Đánh dấu hoàn thành", "Đánh dấu bỏ lỡ") — giữ nguyên các label/text này nguyên văn.

- [ ] **Step 1:** Đọc reference + restyle 2 file.
- [ ] **Step 2: Verify** — build + `-only-testing:FocusPlanUITests/HabitFlowUITests` → PASS.
- [ ] **Step 3: Commit** `style(ui): polish habits screens to Flutter demo parity`

---

### Task 6: Full-suite verification + screenshot evidence

- [ ] **Step 1:** Chạy FULL test: `xcodegen generate && xcodebuild -project FocusPlan.xcodeproj -scheme FocusPlan -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test` → 26 unit + 6 UITest PASS (0 fail).
- [ ] **Step 2:** Chụp screenshot 5 màn chính trên simulator (SignIn, Home, TaskForm, Habits, AddTask) — dùng `xcrun simctl io booted screenshot <file>.png`, lưu vào `docs/superpowers/plans/evidence/2026-07-05-ui-polish/` — để reviewer + user so trực quan với demo.
- [ ] **Step 3:** `git status` sạch ngoài file chủ đích; commit cuối nếu còn evidence: `docs(ui): add polish evidence screenshots`

## Self-Review Notes

- Spec coverage: mọi màn Swift hiện có đều có task (auth: T2, home/tab: T3, task: T4, habit: T5); theme nền tảng T1; verification T6. Mascot/Alarm/màn mới: chủ đích NGOÀI scope (issues 021/022).
- Type consistency: `Theme.primary/done/radiusInput/radiusChip/radiusCard/ctaHeight` dùng thống nhất T1→T5.
- Không placeholder: các quyết định mở (shade badge priority, derive container M3) được gán rõ cho coder + ui-ux-pro-max, không phải "TBD".
