# iOS App Shell + Supabase Auth Implementation Plan

> **For agentic workers:** Implement task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Trong team này, coder thực thi toàn bộ plan rồi bàn giao reviewer — KHÔNG tự dispatch subagent.

**Goal:** Tạo app iOS native (SwiftUI) tối thiểu "Focus Plan" với auth qua Supabase: sign up / sign in / sign out, session persist qua lần mở app, và một màn hình Home empty-state sau khi đăng nhập.

**Architecture:** SwiftUI app dựng bằng XcodeGen (`project.yml` → `.xcodeproj`). Một `SupabaseManager` giữ `SupabaseClient` singleton. Một `AuthViewModel: ObservableObject` lắng nghe `authStateChanges` của supabase-swift và phát ra 3 trạng thái (`loading` / `signedOut` / `signedIn`). `RootView` switch theo trạng thái đó để hiển thị Splash → SignIn/SignUp → Home. Session persistence do supabase-swift tự lo (Keychain) — không tự viết lớp lưu trữ.

**Tech Stack:** Swift, SwiftUI, iOS 17, XcodeGen, Swift Package Manager, `supabase-swift` (product `Supabase`, `github.com/supabase/supabase-swift`, `from: 2.0.0`).

## Global Constraints

- **App name (display):** `Focus Plan`. **Thư mục project:** `FocusPlan/` ở repo root. **Bundle id:** `com.votronghoang.focusplan`.
- **iOS deployment target:** `17.0`.
- **UI framework:** SwiftUI. **Package manager:** SPM. **Project generator:** XcodeGen.
- **Supabase project (THẬT — dùng ngay để test):**
  - URL: `https://njwmpikyqghniqqiweao.supabase.co`
  - Anon key: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5qd21waWt5cWdobmlxcWl3ZWFvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODMwNzE3OTIsImV4cCI6MjA5ODY0Nzc5Mn0.gB8a3wg86lBqwh7ltYJ0_tsJOED6O9Vk14DRP3vXjag`
  - Đây là **anon/public key** (role=anon), an toàn dùng trong client. RLS bảo vệ dữ liệu.
- **Không hardcode key rải rác:** URL + anon key nằm DUY NHẤT trong `FocusPlan/Config/Secrets.xcconfig` (gitignored), đọc vào code qua Info.plist → `SupabaseConfig`. Commit `Secrets.example.xcconfig` làm template.
- **Ngôn ngữ UI:** tiếng Việt, khớp label/flow của demo Flutter (xem "Tài nguyên tham khảo").
- **Validation form (khớp demo):** email regex `^[^@\s]+@[^@\s]+\.[^@\s]+$`; password tối thiểu 6 ký tự; sign up có ô confirm phải khớp password.
- **Cảnh báo email confirmation (Supabase setting):** Nếu project bật "Confirm email" (Authentication → Providers → Email), `signUp` trả về user nhưng KHÔNG có session tới khi user xác nhận email. Code sign-up PHẢI xử lý cả 2 nhánh: có session → vào thẳng Home; không có session → hiện thông báo "Kiểm tra email để xác nhận tài khoản". (User có thể tắt "Confirm email" trên dashboard để test end-to-end mượt hơn — đây là bước setup thủ công của user, ghi lại trong QA note.)

## Tài nguyên tham khảo (UI/flow — KHÔNG copy code Flutter, chỉ lấy layout/label)

- `focus_plan_ui_demo/lib/screens/splash_screen.dart` — spinner giữa màn hình khi đang khôi phục session.
- `focus_plan_ui_demo/lib/screens/sign_in_screen.dart` — form Email + Mật khẩu, nút "Đăng nhập", link "Chưa có tài khoản? Tạo tài khoản".
- `focus_plan_ui_demo/lib/screens/sign_up_screen.dart` — form Email + Mật khẩu + Xác nhận mật khẩu, nút "Tạo tài khoản", link "Đã có tài khoản? Đăng nhập".
- `focus_plan_ui_demo/lib/screens/home_screen.dart` — AppBar "Today" + nút logout; greeting "Xin chào, {email}"; dải 7 ngày ngang (nhãn CN/T2..T7); card empty-state giữa màn hình "Chưa có task nào — sẽ thêm ở slice sau".
- `focus_plan_ui_demo/lib/theme.dart` — seed color indigo `#4F46E5`.

## File Structure

```
FocusPlan/
├── project.yml                       # XcodeGen spec
├── .gitignore                        # ignore Secrets.xcconfig + build artifacts
├── Config/
│   ├── Secrets.xcconfig              # (gitignored) URL + anon key thật
│   └── Secrets.example.xcconfig      # (committed) template
├── Sources/
│   ├── FocusPlanApp.swift            # @main entry, gắn AuthViewModel + RootView
│   ├── Support/
│   │   ├── SupabaseConfig.swift      # đọc URL/key từ Info.plist bundle
│   │   └── SupabaseManager.swift     # SupabaseClient singleton
│   ├── Auth/
│   │   └── AuthViewModel.swift       # ObservableObject, authState + actions
│   └── Views/
│       ├── RootView.swift            # switch theo authState
│       ├── SignInView.swift
│       ├── SignUpView.swift
│       └── HomeView.swift
├── Resources/
│   └── Info.plist                    # chứa key $(SUPABASE_URL), $(SUPABASE_ANON_KEY)
└── Tests/
    └── SupabaseConfigTests.swift     # unit test config load được
```

---

### Task 1: Project scaffold + XcodeGen + build được app rỗng

**Files:**
- Create: `FocusPlan/project.yml`
- Create: `FocusPlan/.gitignore`
- Create: `FocusPlan/Config/Secrets.xcconfig`
- Create: `FocusPlan/Config/Secrets.example.xcconfig`
- Create: `FocusPlan/Resources/Info.plist`
- Create: `FocusPlan/Sources/FocusPlanApp.swift` (tạm thời hiển thị `Text("Focus Plan")`)

**Interfaces:**
- Produces: scheme `FocusPlan`, target app `FocusPlan`, target test `FocusPlanTests`; Info.plist expose `SUPABASE_URL` + `SUPABASE_ANON_KEY`; SPM package `Supabase`.

- [ ] **Step 1: Kiểm tra/ cài XcodeGen**

```bash
which xcodegen || brew install xcodegen
xcodegen --version
```

- [ ] **Step 2: Viết `FocusPlan/Config/Secrets.example.xcconfig`** (committed, template — KHÔNG chứa key thật)

```
// Copy file này thành Secrets.xcconfig rồi điền giá trị thật.
// LƯU Ý: xcconfig coi "//" là comment, nên URL phải chèn $() để tách "https://".
SUPABASE_URL = https:/$()/YOUR-PROJECT.supabase.co
SUPABASE_ANON_KEY = your-anon-key-here
```

- [ ] **Step 3: Viết `FocusPlan/Config/Secrets.xcconfig`** (gitignored, giá trị THẬT — chú ý trick `$()` để `//` trong URL không bị nuốt)

```
SUPABASE_URL = https:/$()/njwmpikyqghniqqiweao.supabase.co
SUPABASE_ANON_KEY = eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5qd21waWt5cWdobmlxcWl3ZWFvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODMwNzE3OTIsImV4cCI6MjA5ODY0Nzc5Mn0.gB8a3wg86lBqwh7ltYJ0_tsJOED6O9Vk14DRP3vXjag
```

- [ ] **Step 4: Viết `FocusPlan/.gitignore`**

```
Secrets.xcconfig
*.xcodeproj/
build/
DerivedData/
.DS_Store
```

- [ ] **Step 5: Viết `FocusPlan/Resources/Info.plist`** (expose 2 key để đọc trong runtime; giá trị lấy từ build setting qua `$()`)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>SUPABASE_URL</key>
    <string>$(SUPABASE_URL)</string>
    <key>SUPABASE_ANON_KEY</key>
    <string>$(SUPABASE_ANON_KEY)</string>
</dict>
</plist>
```

- [ ] **Step 6: Viết `FocusPlan/project.yml`**

```yaml
name: FocusPlan
options:
  bundleIdPrefix: com.votronghoang
  deploymentTarget:
    iOS: "17.0"
packages:
  Supabase:
    url: https://github.com/supabase/supabase-swift
    from: "2.0.0"
targets:
  FocusPlan:
    type: application
    platform: iOS
    sources:
      - path: Sources
      - path: Resources
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.votronghoang.focusplan
        INFOPLIST_FILE: Resources/Info.plist
        INFOPLIST_KEY_UILaunchScreen_Generation: "YES"
        INFOPLIST_KEY_CFBundleDisplayName: Focus Plan
        MARKETING_VERSION: "0.1.0"
        CURRENT_PROJECT_VERSION: "1"
    configFiles:
      Debug: Config/Secrets.xcconfig
      Release: Config/Secrets.xcconfig
    dependencies:
      - package: Supabase
        product: Supabase
  FocusPlanTests:
    type: bundle.unit-test
    platform: iOS
    sources:
      - path: Tests
    dependencies:
      - target: FocusPlan
```

- [ ] **Step 7: Viết `FocusPlan/Sources/FocusPlanApp.swift`** (tạm để build)

```swift
import SwiftUI

@main
struct FocusPlanApp: App {
    var body: some Scene {
        WindowGroup {
            Text("Focus Plan")
        }
    }
}
```

- [ ] **Step 8: Generate + build**

Run (từ trong `FocusPlan/`):
```bash
xcodegen generate
xcodebuild -project FocusPlan.xcodeproj -scheme FocusPlan \
  -destination 'generic/platform=iOS Simulator' build
```
Expected: `** BUILD SUCCEEDED **` (SPM resolve `supabase-swift` cần mạng — lần đầu sẽ tải).

- [ ] **Step 9: Commit**

```bash
git add FocusPlan/project.yml FocusPlan/.gitignore FocusPlan/Config/Secrets.example.xcconfig \
  FocusPlan/Resources/Info.plist FocusPlan/Sources/FocusPlanApp.swift
git commit -m "feat(ios): scaffold FocusPlan SwiftUI app via XcodeGen + Supabase SPM"
```
(LƯU Ý: `Secrets.xcconfig` bị gitignore — đúng, không add.)

---

### Task 2: SupabaseConfig + unit test đọc config

**Files:**
- Create: `FocusPlan/Sources/Support/SupabaseConfig.swift`
- Create: `FocusPlan/Tests/SupabaseConfigTests.swift`

**Interfaces:**
- Produces: `enum SupabaseConfig { static let url: URL; static let anonKey: String }` — dùng bởi Task 3.

- [ ] **Step 1: Viết test thất bại `FocusPlan/Tests/SupabaseConfigTests.swift`**

```swift
import XCTest
@testable import FocusPlan

final class SupabaseConfigTests: XCTestCase {
    func test_url_has_supabase_host() {
        XCTAssertEqual(SupabaseConfig.url.scheme, "https")
        XCTAssertTrue(SupabaseConfig.url.host?.hasSuffix(".supabase.co") ?? false,
                      "URL host phải là *.supabase.co, thực tế: \(String(describing: SupabaseConfig.url.host))")
    }

    func test_anon_key_is_nonEmpty_jwt() {
        XCTAssertFalse(SupabaseConfig.anonKey.isEmpty)
        XCTAssertTrue(SupabaseConfig.anonKey.hasPrefix("eyJ"), "anon key phải là JWT bắt đầu bằng eyJ")
    }
}
```

- [ ] **Step 2: Chạy test để xác nhận fail**

Run (trong `FocusPlan/`):
```bash
xcodebuild -project FocusPlan.xcodeproj -scheme FocusPlan \
  -destination 'platform=iOS Simulator,name=iPhone 15' test
```
Expected: FAIL — `SupabaseConfig` chưa tồn tại (compile error).

- [ ] **Step 3: Viết `FocusPlan/Sources/Support/SupabaseConfig.swift`**

```swift
import Foundation

enum SupabaseConfig {
    static let url: URL = {
        guard let raw = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
              let url = URL(string: raw.trimmingCharacters(in: .whitespaces)) else {
            fatalError("SUPABASE_URL thiếu/không hợp lệ trong Info.plist. Kiểm tra Config/Secrets.xcconfig.")
        }
        return url
    }()

    static let anonKey: String = {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String,
              !key.isEmpty else {
            fatalError("SUPABASE_ANON_KEY thiếu trong Info.plist. Kiểm tra Config/Secrets.xcconfig.")
        }
        return key
    }()
}
```

- [ ] **Step 4: Chạy test để xác nhận pass**

Run: (lệnh test như Step 2)
Expected: `** TEST SUCCEEDED **` — 2 test pass. (Nếu fail vì host sai → dấu hiệu trick `$()` trong xcconfig chưa đúng, sửa Task 1 Step 3.)

- [ ] **Step 5: Commit**

```bash
git add FocusPlan/Sources/Support/SupabaseConfig.swift FocusPlan/Tests/SupabaseConfigTests.swift
git commit -m "feat(ios): load Supabase URL/anon key from Info.plist with config test"
```

---

### Task 3: SupabaseManager + AuthViewModel

**Files:**
- Create: `FocusPlan/Sources/Support/SupabaseManager.swift`
- Create: `FocusPlan/Sources/Auth/AuthViewModel.swift`

**Interfaces:**
- Consumes: `SupabaseConfig.url`, `SupabaseConfig.anonKey` (Task 2).
- Produces:
  - `final class SupabaseManager { static let shared: SupabaseManager; let client: SupabaseClient }`
  - `@MainActor final class AuthViewModel: ObservableObject` với:
    - `enum AuthState: Equatable { case loading; case signedOut; case signedIn(email: String) }`
    - `@Published private(set) var state: AuthState`
    - `@Published var errorMessage: String?`
    - `func signIn(email: String, password: String) async`
    - `func signUp(email: String, password: String) async -> Bool` (return `true` nếu đã có session ngay; `false` nếu cần xác nhận email)
    - `func signOut() async`
    - `func start()` — bắt đầu lắng nghe `authStateChanges` (gọi trong `.task` của RootView)

- [ ] **Step 1: Viết `FocusPlan/Sources/Support/SupabaseManager.swift`**

```swift
import Foundation
import Supabase

final class SupabaseManager {
    static let shared = SupabaseManager()
    let client: SupabaseClient

    private init() {
        client = SupabaseClient(
            supabaseURL: SupabaseConfig.url,
            supabaseKey: SupabaseConfig.anonKey
        )
    }
}
```

- [ ] **Step 2: Viết `FocusPlan/Sources/Auth/AuthViewModel.swift`**

```swift
import Foundation
import Supabase

@MainActor
final class AuthViewModel: ObservableObject {
    enum AuthState: Equatable {
        case loading
        case signedOut
        case signedIn(email: String)
    }

    @Published private(set) var state: AuthState = .loading
    @Published var errorMessage: String?

    private let auth = SupabaseManager.shared.client.auth
    private var listenerTask: Task<Void, Never>?

    /// Lắng nghe thay đổi auth (bao gồm event .initialSession khôi phục session lúc mở app).
    func start() {
        guard listenerTask == nil else { return }
        listenerTask = Task { [weak self] in
            guard let self else { return }
            for await change in self.auth.authStateChanges {
                if let session = change.session {
                    self.state = .signedIn(email: session.user.email ?? "")
                } else {
                    self.state = .signedOut
                }
            }
        }
    }

    func signIn(email: String, password: String) async {
        errorMessage = nil
        do {
            _ = try await auth.signIn(email: email, password: password)
            // state cập nhật qua authStateChanges
        } catch {
            errorMessage = friendlyMessage(error)
        }
    }

    /// return true nếu đăng ký xong đã có session (vào thẳng Home);
    /// false nếu project bật email confirmation (cần user xác nhận email).
    func signUp(email: String, password: String) async -> Bool {
        errorMessage = nil
        do {
            let response = try await auth.signUp(email: email, password: password)
            return response.session != nil
        } catch {
            errorMessage = friendlyMessage(error)
            return false
        }
    }

    func signOut() async {
        do {
            try await auth.signOut()
        } catch {
            errorMessage = friendlyMessage(error)
        }
    }

    private func friendlyMessage(_ error: Error) -> String {
        // Hiện message gốc; đủ cho beta. Có thể map mã lỗi Supabase sau.
        return error.localizedDescription
    }
}
```

- [ ] **Step 3: Build để xác nhận compile**

Run (trong `FocusPlan/`):
```bash
xcodegen generate
xcodebuild -project FocusPlan.xcodeproj -scheme FocusPlan \
  -destination 'generic/platform=iOS Simulator' build
```
Expected: `** BUILD SUCCEEDED **`. (Nếu `AuthResponse.session` sai tên property theo version supabase-swift đã resolve → kiểm tra API thật của package đã tải trong DerivedData/SourcePackages và điều chỉnh; giữ nguyên hành vi return-bool.)

- [ ] **Step 4: Commit**

```bash
git add FocusPlan/Sources/Support/SupabaseManager.swift FocusPlan/Sources/Auth/AuthViewModel.swift
git commit -m "feat(ios): add SupabaseManager client + AuthViewModel with auth state stream"
```

---

### Task 4: SignInView

**Files:**
- Create: `FocusPlan/Sources/Views/SignInView.swift`

**Interfaces:**
- Consumes: `AuthViewModel.signIn(email:password:)`, `AuthViewModel.errorMessage` (Task 3).
- Produces: `struct SignInView: View` — nhận `@ObservedObject var auth: AuthViewModel` và `var onTapCreateAccount: () -> Void`.

- [ ] **Step 1: Viết `FocusPlan/Sources/Views/SignInView.swift`**

```swift
import SwiftUI

struct SignInView: View {
    @ObservedObject var auth: AuthViewModel
    var onTapCreateAccount: () -> Void

    @State private var email = ""
    @State private var password = ""
    @State private var validationError: String?
    @State private var isSubmitting = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Đăng nhập").font(.largeTitle).bold()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom, 16)

                TextField("Email", text: $email)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .textFieldStyle(.roundedBorder)

                SecureField("Mật khẩu", text: $password)
                    .textFieldStyle(.roundedBorder)

                if let msg = validationError ?? auth.errorMessage {
                    Text(msg).foregroundStyle(.red).font(.footnote)
                }

                Button {
                    Task { await submit() }
                } label: {
                    if isSubmitting { ProgressView().frame(maxWidth: .infinity) }
                    else { Text("Đăng nhập").frame(maxWidth: .infinity) }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isSubmitting)

                Button("Chưa có tài khoản? Tạo tài khoản", action: onTapCreateAccount)
                    .frame(maxWidth: .infinity)

                Spacer()
            }
            .padding(24)
        }
    }

    private func submit() async {
        validationError = AuthValidation.validate(email: email, password: password)
        guard validationError == nil else { return }
        isSubmitting = true
        await auth.signIn(email: email.trimmingCharacters(in: .whitespaces), password: password)
        isSubmitting = false
    }
}
```

- [ ] **Step 2: Viết helper validation `FocusPlan/Sources/Auth/AuthValidation.swift`**

(Tạo file mới — dùng chung cho SignIn/SignUp; khớp rule demo.)
```swift
import Foundation

enum AuthValidation {
    static func validateEmail(_ value: String) -> String? {
        let v = value.trimmingCharacters(in: .whitespaces)
        if v.isEmpty { return "Nhập email" }
        let regex = #"^[^@\s]+@[^@\s]+\.[^@\s]+$"#
        if v.range(of: regex, options: .regularExpression) == nil { return "Email không hợp lệ" }
        return nil
    }

    static func validatePassword(_ value: String) -> String? {
        if value.isEmpty { return "Nhập mật khẩu" }
        if value.count < 6 { return "Mật khẩu tối thiểu 6 ký tự" }
        return nil
    }

    /// Gộp cho sign-in.
    static func validate(email: String, password: String) -> String? {
        return validateEmail(email) ?? validatePassword(password)
    }
}
```

- [ ] **Step 3: Build**

Run: `xcodegen generate && xcodebuild -project FocusPlan.xcodeproj -scheme FocusPlan -destination 'generic/platform=iOS Simulator' build`
Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 4: Commit**

```bash
git add FocusPlan/Sources/Views/SignInView.swift FocusPlan/Sources/Auth/AuthValidation.swift
git commit -m "feat(ios): add SignInView with form validation"
```

---

### Task 5: SignUpView

**Files:**
- Create: `FocusPlan/Sources/Views/SignUpView.swift`

**Interfaces:**
- Consumes: `AuthViewModel.signUp(email:password:) -> Bool`, `AuthValidation` (Task 4).
- Produces: `struct SignUpView: View` — nhận `@ObservedObject var auth: AuthViewModel` và `var onBack: () -> Void`.

- [ ] **Step 1: Viết `FocusPlan/Sources/Views/SignUpView.swift`**

```swift
import SwiftUI

struct SignUpView: View {
    @ObservedObject var auth: AuthViewModel
    var onBack: () -> Void

    @State private var email = ""
    @State private var password = ""
    @State private var confirm = ""
    @State private var validationError: String?
    @State private var infoMessage: String?
    @State private var isSubmitting = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                TextField("Email", text: $email)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .textFieldStyle(.roundedBorder)

                SecureField("Mật khẩu", text: $password)
                    .textFieldStyle(.roundedBorder)

                SecureField("Xác nhận mật khẩu", text: $confirm)
                    .textFieldStyle(.roundedBorder)

                if let msg = validationError ?? auth.errorMessage {
                    Text(msg).foregroundStyle(.red).font(.footnote)
                }
                if let info = infoMessage {
                    Text(info).foregroundStyle(.green).font(.footnote)
                }

                Button {
                    Task { await submit() }
                } label: {
                    if isSubmitting { ProgressView().frame(maxWidth: .infinity) }
                    else { Text("Tạo tài khoản").frame(maxWidth: .infinity) }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isSubmitting)

                Button("Đã có tài khoản? Đăng nhập", action: onBack)
                    .frame(maxWidth: .infinity)

                Spacer()
            }
            .padding(24)
            .navigationTitle("Tạo tài khoản")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func submit() async {
        infoMessage = nil
        validationError = AuthValidation.validateEmail(email)
            ?? AuthValidation.validatePassword(password)
            ?? (password != confirm ? "Mật khẩu xác nhận không khớp" : nil)
        guard validationError == nil else { return }

        isSubmitting = true
        let hasSession = await auth.signUp(
            email: email.trimmingCharacters(in: .whitespaces),
            password: password
        )
        isSubmitting = false
        // Nếu hasSession == true: RootView tự chuyển sang Home qua authStateChanges.
        // Nếu false và không có lỗi: cần xác nhận email.
        if !hasSession && auth.errorMessage == nil {
            infoMessage = "Kiểm tra email để xác nhận tài khoản, sau đó đăng nhập."
        }
    }
}
```

- [ ] **Step 2: Build**

Run: `xcodegen generate && xcodebuild -project FocusPlan.xcodeproj -scheme FocusPlan -destination 'generic/platform=iOS Simulator' build`
Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 3: Commit**

```bash
git add FocusPlan/Sources/Views/SignUpView.swift
git commit -m "feat(ios): add SignUpView with confirm-password + email-confirmation handling"
```

---

### Task 6: HomeView (empty-state) + Sign Out

**Files:**
- Create: `FocusPlan/Sources/Views/HomeView.swift`

**Interfaces:**
- Consumes: `AuthViewModel.signOut()` (Task 3).
- Produces: `struct HomeView: View` — nhận `@ObservedObject var auth: AuthViewModel` và `let email: String`.

- [ ] **Step 1: Viết `FocusPlan/Sources/Views/HomeView.swift`** (dải 7 ngày + card empty-state + nút logout, khớp demo)

```swift
import SwiftUI

struct HomeView: View {
    @ObservedObject var auth: AuthViewModel
    let email: String

    private let labels = ["CN", "T2", "T3", "T4", "T5", "T6", "T7"]

    private var weekDays: [Date] {
        let cal = Calendar.current
        let today = Date()
        let weekdayIndex = cal.component(.weekday, from: today) - 1 // 0=CN
        return (0..<7).map { i in
            cal.date(byAdding: .day, value: i - weekdayIndex, to: today) ?? today
        }
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Xin chào, \(email)").font(.headline)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(weekDays, id: \.self) { day in
                            dayChip(day)
                        }
                    }
                }

                Spacer()
                VStack {
                    Text("Chưa có task nào — sẽ thêm ở slice sau")
                        .multilineTextAlignment(.center)
                        .padding(24)
                }
                .frame(maxWidth: .infinity)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                Spacer()
            }
            .padding(16)
            .navigationTitle("Today")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await auth.signOut() }
                    } label: {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                    }
                    .accessibilityLabel("Đăng xuất")
                }
            }
        }
    }

    @ViewBuilder
    private func dayChip(_ day: Date) -> some View {
        let cal = Calendar.current
        let isToday = cal.isDateInToday(day)
        let weekdayIndex = cal.component(.weekday, from: day) - 1
        VStack(spacing: 4) {
            Text(labels[weekdayIndex]).font(.caption)
            Text("\(cal.component(.day, from: day))").bold()
        }
        .frame(width: 48, height: 64)
        .background(isToday ? Color.accentColor : Color(.secondarySystemBackground),
                    in: RoundedRectangle(cornerRadius: 16))
        .foregroundStyle(isToday ? Color.white : Color.primary)
    }
}
```

- [ ] **Step 2: Build**

Run: `xcodegen generate && xcodebuild -project FocusPlan.xcodeproj -scheme FocusPlan -destination 'generic/platform=iOS Simulator' build`
Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 3: Commit**

```bash
git add FocusPlan/Sources/Views/HomeView.swift
git commit -m "feat(ios): add HomeView empty-state with week strip + sign out"
```

---

### Task 7: RootView routing + wiring @main + verify toàn bộ acceptance criteria

**Files:**
- Create: `FocusPlan/Sources/Views/RootView.swift`
- Modify: `FocusPlan/Sources/FocusPlanApp.swift`

**Interfaces:**
- Consumes: `AuthViewModel` (Task 3), `SignInView` / `SignUpView` (Task 4/5), `HomeView` (Task 6).

- [ ] **Step 1: Viết `FocusPlan/Sources/Views/RootView.swift`**

```swift
import SwiftUI

struct RootView: View {
    @StateObject private var auth = AuthViewModel()
    @State private var showingSignUp = false

    var body: some View {
        Group {
            switch auth.state {
            case .loading:
                ProgressView()               // splash
            case .signedOut:
                if showingSignUp {
                    SignUpView(auth: auth, onBack: { showingSignUp = false })
                } else {
                    SignInView(auth: auth, onTapCreateAccount: { showingSignUp = true })
                }
            case .signedIn(let email):
                HomeView(auth: auth, email: email)
            }
        }
        .task { auth.start() }
        .onChange(of: auth.state) { _, newValue in
            if case .signedIn = newValue { showingSignUp = false }
        }
    }
}
```

- [ ] **Step 2: Sửa `FocusPlan/Sources/FocusPlanApp.swift`**

```swift
import SwiftUI

@main
struct FocusPlanApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
```

- [ ] **Step 3: Build**

Run: `xcodegen generate && xcodebuild -project FocusPlan.xcodeproj -scheme FocusPlan -destination 'generic/platform=iOS Simulator' build`
Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 4: Chạy unit test**

Run: `xcodebuild -project FocusPlan.xcodeproj -scheme FocusPlan -destination 'platform=iOS Simulator,name=iPhone 15' test`
Expected: `** TEST SUCCEEDED **`.

- [ ] **Step 5: Verify thủ công trên simulator (MANUAL — bắt buộc, đây là verify acceptance criteria thật)**

Boot simulator + install + launch:
```bash
xcodebuild -project FocusPlan.xcodeproj -scheme FocusPlan \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -derivedDataPath build build
xcrun simctl boot "iPhone 15" || true
xcrun simctl install booted \
  build/Build/Products/Debug-iphonesimulator/FocusPlan.app
xcrun simctl launch booted com.votronghoang.focusplan
```
Checklist (tick từng cái, khớp acceptance criteria issue 001):
1. **Sign up:** tạo tài khoản email/password mới → vào Home (nếu project tắt "Confirm email") HOẶC hiện "Kiểm tra email…" (nếu bật). Ghi rõ nhánh nào xảy ra vào QA note.
2. **Sign in:** đăng nhập bằng tài khoản vừa tạo (đã xác nhận nếu cần) → vào Home, greeting hiện đúng email.
3. **Session persist:** kill app (`xcrun simctl terminate booted com.votronghoang.focusplan`) rồi launch lại → vào thẳng Home, KHÔNG phải đăng nhập lại.
4. **Sign out:** bấm nút logout ở Home → về màn SignIn. Kill + launch lại → vẫn ở SignIn (session đã xoá).
5. **Empty-state:** Home hiển thị dải 7 ngày + card "Chưa có task nào — sẽ thêm ở slice sau".

- [ ] **Step 6: Commit**

```bash
git add FocusPlan/Sources/Views/RootView.swift FocusPlan/Sources/FocusPlanApp.swift
git commit -m "feat(ios): wire RootView auth routing + splash/session restore"
```

---

## Self-Review (đã chạy)

- **Spec coverage:** 4 acceptance criteria issue 001 → sign up (Task 5), sign in (Task 4), session persist (Task 3 authStateChanges + supabase-swift keychain, verify Task 7 Step 5.3), sign out + xoá session (Task 6 + verify 5.4), Home empty-state (Task 6). ✔
- **Type consistency:** `AuthViewModel.state: AuthState`, `signIn/signUp/signOut/start` dùng nhất quán ở SignInView/SignUpView/HomeView/RootView. `signUp` return `Bool` khớp cách SignUpView xử lý. `SupabaseConfig.url/anonKey` khớp SupabaseManager. `AuthValidation` khớp SignIn/SignUp. ✔
- **Placeholder scan:** không có TBD/TODO; mọi step có code/lệnh cụ thể. ✔
- **Rủi ro đã ghi:** (a) tên property `AuthResponse.session` có thể khác theo version supabase-swift đã resolve → coder kiểm tra API thật, giữ hành vi; (b) xcconfig `//` gotcha đã xử lý bằng `$()`; (c) email-confirmation setting xử lý cả 2 nhánh; (d) tên simulator `iPhone 15` — nếu máy không có, coder đổi sang tên simulator có sẵn (`xcrun simctl list devices`).
