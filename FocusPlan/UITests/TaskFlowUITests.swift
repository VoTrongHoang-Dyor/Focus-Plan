import XCTest
import UIKit

/// QA in-app cho issue 002:
/// - test_signedInUser_seesSeededTask: seed user + task qua REST → login → task hiển thị
///   trong list → TaskRepository.fetchAll decode TaskItem (timestamptz) + render đúng.
/// - test_naturalLanguageParse_createsTask: criteria 1 — nhập câu NL → parse (Gemini mock
///   qua seam UITEST_MOCK_PARSE_DRAFT) → màn confirm → lưu THẬT vào Supabase → list.
/// - test_taskList_isolatedBetweenUsers: criteria 4 — task user A không rò sang user B (RLS).
final class TaskFlowUITests: XCTestCase {

    private let app = XCUIApplication(bundleIdentifier: "com.votronghoang.focusplan")
    private let supabaseURL = "https://njwmpikyqghniqqiweao.supabase.co"
    // anon key là public (role=anon) — an toàn để trong test.
    private let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5qd21waWt5cWdobmlxcWl3ZWFvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODMwNzE3OTIsImV4cCI6MjA5ODY0Nzc5Mn0.gB8a3wg86lBqwh7ltYJ0_tsJOED6O9Vk14DRP3vXjag"
    private let password = "secret123"

    override func setUp() { continueAfterFailure = false }

    // MARK: - REST helpers (đồng bộ hoá bằng semaphore)

    private func postJSON(_ path: String, body: [String: Any], bearer: String) -> [String: Any]? {
        var req = URLRequest(url: URL(string: supabaseURL + path)!)
        req.httpMethod = "POST"
        req.setValue(anonKey, forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(bearer)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "content-type")
        req.setValue("return=representation", forHTTPHeaderField: "Prefer")
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        var result: [String: Any]?
        let sem = DispatchSemaphore(value: 0)
        URLSession.shared.dataTask(with: req) { data, _, _ in
            if let data, let obj = try? JSONSerialization.jsonObject(with: data) {
                if let arr = obj as? [[String: Any]] { result = arr.first }
                else { result = obj as? [String: Any] }
            }
            sem.signal()
        }.resume()
        _ = sem.wait(timeout: .now() + 20)
        return result
    }

    private func seedUser() -> (email: String, token: String) {
        // Unique per-call (không chỉ per-second) để 2 lần seed liên tiếp không trùng email.
        let email = "qaseed\(Int(Date().timeIntervalSince1970))_\(UInt32.random(in: 0 ..< 1_000_000))@gmail.com"
        let signup = postJSON("/auth/v1/signup", body: ["email": email, "password": password], bearer: anonKey)
        let token = signup?["access_token"] as? String
        XCTAssertNotNil(token, "Seed: signup không trả access_token (Confirm email phải TẮT)")
        return (email, token ?? "")
    }

    private func seedUserAndTask(taskName: String) -> String {
        let user = seedUser()
        let inserted = postJSON("/rest/v1/tasks",
                                body: ["name": taskName, "estimated_minutes": 45,
                                       "priority": "high", "deadline": "2026-07-10T09:30:00+00:00"],
                                bearer: user.token)
        XCTAssertNotNil(inserted?["id"], "Seed: insert task thất bại")
        return user.email
    }

    private func typeInto(_ field: XCUIElement, _ text: String) {
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap(); field.typeText(text)
    }

    private func pasteInto(_ field: XCUIElement, _ text: String) {
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        UIPasteboard.general.string = text
        field.tap(); field.press(forDuration: 1.3)
        let paste = app.menuItems["Paste"].firstMatch
        XCTAssertTrue(paste.waitForExistence(timeout: 5))
        paste.tap()
    }

    /// Sau khi đăng nhập, iOS bật dialog modal "Lưu mật khẩu?" che UI → chặn mọi tap.
    /// Trên iOS mới dialog nằm trong app hierarchy (không phải springboard) nên tìm nút
    /// "Để sau" ở cả hai nơi. Tap-if-present nhanh, trả về true nếu đã tắt.
    @discardableResult
    private func dismissSavePasswordDialog() -> Bool {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        for label in ["Để sau", "Not Now", "Lúc khác"] {
            let appBtn = app.buttons[label]
            if appBtn.exists { appBtn.tap(); return true }
            let sbBtn = springboard.buttons[label]
            if sbBtn.exists { sbBtn.tap(); return true }
        }
        return false
    }

    /// Criteria 1 + 3 end-to-end: nhập câu tiếng Việt tự nhiên → parse ra ParsedTaskDraft
    /// có cấu trúc → LUÔN qua màn "Xác nhận task" (không lưu âm thầm) → bấm Tạo → task
    /// được lưu THẬT vào Supabase và hiện trong danh sách.
    /// Chỉ response Gemini là mock (qua test-seam UITEST_MOCK_PARSE_DRAFT); đường lưu
    /// Supabase vẫn là real integration.
    func test_naturalLanguageParse_createsTask() {
        let email = seedUser().email   // user mới, KHÔNG seed task
        let expectedName = "Học tiếng Trung"

        // Mock draft Gemini trả về (snake_case khớp CodingKeys của ParsedTaskDraft).
        app.launchEnvironment["UITEST_MOCK_PARSE_DRAFT"] = """
        {"name":"\(expectedName)","estimated_minutes":30,"priority":"medium",\
        "deadline":"2026-07-05T20:00:00Z","needs_confirmation":false,"note":null}
        """
        app.launch()
        let logout = app.buttons["Đăng xuất"]
        if logout.waitForExistence(timeout: 5) { logout.tap() }

        let goSignIn = app.buttons["Chưa có tài khoản? Tạo tài khoản"]
        XCTAssertTrue(goSignIn.waitForExistence(timeout: 10), "Chưa tới màn SignIn")
        typeInto(app.textFields["Email"], email)
        pasteInto(app.secureTextFields["Mật khẩu"], password)
        app.buttons["Đăng nhập"].tap()
        // Dialog "Lưu mật khẩu?" xuất hiện sau vài giây → poll để bắt và tắt.
        for _ in 0..<8 { if dismissSavePasswordDialog() { break }; Thread.sleep(forTimeInterval: 1) }

        // Mở AddTaskView từ Home (retry + tắt dialog phòng khi nó che nút).
        let addButton = app.buttons["Thêm task"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 20), "Không vào được Home sau đăng nhập")
        let addMarker = app.staticTexts["Nhập task bằng câu tự nhiên"]
        for _ in 0..<3 {
            dismissSavePasswordDialog()
            addButton.tap()
            if addMarker.waitForExistence(timeout: 5) { break }
        }
        XCTAssertTrue(addMarker.exists, "Không mở được màn Thêm task")

        // Nhập câu tiếng Việt tự nhiên vào ô của AddTaskView (TextField axis:.vertical
        // xuất hiện dạng textView; fallback textField).
        let input = app.textViews.firstMatch.waitForExistence(timeout: 5)
            ? app.textViews.firstMatch
            : app.textFields.firstMatch
        typeInto(input, "Học tiếng Trung 30 phút tối nay")

        // Phân tích → seam trả draft mock ngay.
        app.buttons["Phân tích"].tap()

        // Criteria 3: LUÔN qua màn confirm trước khi lưu.
        XCTAssertTrue(app.navigationBars["Xác nhận task"].waitForExistence(timeout: 10),
                      "Không tới màn Xác nhận task")

        // Criteria 1: tên task được prefill đúng từ draft ("Học tiếng Trung").
        let names = app.textFields.allElementsBoundByIndex.compactMap { $0.value as? String }
        XCTAssertTrue(names.contains(expectedName),
                      "Tên task chưa prefill đúng từ draft: \(names)")

        // Bấm Tạo → lưu THẬT vào Supabase → task xuất hiện trong list.
        app.buttons["Tạo"].tap()
        XCTAssertTrue(app.staticTexts[expectedName].waitForExistence(timeout: 20),
                      "Task vừa tạo (\(expectedName)) không xuất hiện trong danh sách")
    }

    func test_signedInUser_seesSeededTask() {
        let taskName = "QA seed task \(Int(Date().timeIntervalSince1970))"
        let email = seedUserAndTask(taskName: taskName)

        app.launch()
        // Nếu còn session cũ → sign out.
        let logout = app.buttons["Đăng xuất"]
        if logout.waitForExistence(timeout: 5) { logout.tap() }

        let goSignIn = app.buttons["Chưa có tài khoản? Tạo tài khoản"]
        XCTAssertTrue(goSignIn.waitForExistence(timeout: 10), "Chưa tới màn SignIn")

        typeInto(app.textFields["Email"], email)
        pasteInto(app.secureTextFields["Mật khẩu"], password)
        app.buttons["Đăng nhập"].tap()

        // Task đã seed phải hiển thị → fetchAll decode TaskItem (timestamptz) + render OK.
        XCTAssertTrue(app.staticTexts[taskName].waitForExistence(timeout: 20),
                      "Task đã seed không hiện trong danh sách (decode/list lỗi)")
        // priority label tiếng Việt hiển thị
        XCTAssertTrue(app.staticTexts["Cao"].exists, "Không thấy nhãn priority 'Cao'")
    }

    /// Criteria 4: RLS isolation — task của user A KHÔNG rò sang user B.
    func test_taskList_isolatedBetweenUsers() {
        let taskNameA = "Task riêng A \(Int(Date().timeIntervalSince1970))"
        _ = seedUserAndTask(taskName: taskNameA)   // user A + 1 task
        let emailB = seedUser().email               // user B, không task

        app.launch()
        let logout = app.buttons["Đăng xuất"]
        if logout.waitForExistence(timeout: 5) { logout.tap() }

        let goSignIn = app.buttons["Chưa có tài khoản? Tạo tài khoản"]
        XCTAssertTrue(goSignIn.waitForExistence(timeout: 10), "Chưa tới màn SignIn")
        typeInto(app.textFields["Email"], emailB)
        pasteInto(app.secureTextFields["Mật khẩu"], password)
        app.buttons["Đăng nhập"].tap()
        for _ in 0..<8 { if dismissSavePasswordDialog() { break }; Thread.sleep(forTimeInterval: 1) }

        // Chờ list user B load xong (empty-state hiện) → fetchAll đã trả về (0 row).
        XCTAssertTrue(app.staticTexts["Chưa có task nào — thêm bằng nút +"].waitForExistence(timeout: 20),
                      "List user B chưa load xong")
        // RLS scope theo auth.uid(): task của A không được hiện cho B.
        XCTAssertFalse(app.staticTexts[taskNameA].exists,
                       "Rò dữ liệu chéo: user B thấy task của user A")
    }
}
