import XCTest
import UIKit

/// Issue 019: chứng minh mọi control core-flow tra cứu được QUA accessibilityIdentifier.
/// Test thao tác hoàn toàn bằng identifier (literal khớp `A11yID` — UITest target không
/// link app module). Gemini bị mock qua seam UITEST_MOCK_PARSE_DRAFT (issue 002).
/// Copy helper tối thiểu từ TaskFlowUITests (KHÔNG refactor file test cũ).
final class A11yIdentifierUITests: XCTestCase {

    private let app = XCUIApplication(bundleIdentifier: "com.votronghoang.focusplan")
    private let supabaseURL = "https://njwmpikyqghniqqiweao.supabase.co"
    // anon key public (role=anon) — an toàn để trong test.
    private let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5qd21waWt5cWdobmlxcWl3ZWFvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODMwNzE3OTIsImV4cCI6MjA5ODY0Nzc5Mn0.gB8a3wg86lBqwh7ltYJ0_tsJOED6O9Vk14DRP3vXjag"
    private let password = "secret123"

    override func setUp() { continueAfterFailure = false }

    // MARK: - Helpers (copy tối thiểu)

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

    private func seedUser() -> String {
        let email = "a11yqa\(Int(Date().timeIntervalSince1970))_\(UInt32.random(in: 0 ..< 1_000_000))@gmail.com"
        let signup = postJSON("/auth/v1/signup", body: ["email": email, "password": password], bearer: anonKey)
        XCTAssertNotNil(signup?["access_token"] as? String, "Seed: signup không trả token (Confirm email phải TẮT)")
        return email
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

    /// Tra cứu theo identifier bất kể loại element (Picker/Toggle/DatePicker SwiftUI
    /// expose loại khác nhau — chỉ cần identifier query được là đạt).
    private func anyEl(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    // MARK: - Test

    func test_coreFlow_controls_queryable_by_identifier() {
        let email = seedUser()
        app.launchEnvironment["UITEST_MOCK_PARSE_DRAFT"] = """
        {"name":"Học tiếng Trung","estimated_minutes":30,"priority":"medium",\
        "deadline":"2026-07-05T20:00:00Z","needs_confirmation":false,"note":null,\
        "task_type":"deep"}
        """
        app.launch()

        // Còn session cũ → sign out QUA identifier.
        let signOut = app.buttons["home.sign-out-button"]
        if signOut.waitForExistence(timeout: 5) { signOut.tap() }

        // --- SignIn: 4 identifier tĩnh ---
        XCTAssertTrue(app.textFields["signin.email-field"].waitForExistence(timeout: 10),
                      "signin.email-field không tra cứu được")
        XCTAssertTrue(app.secureTextFields["signin.password-field"].exists)
        XCTAssertTrue(app.buttons["signin.submit-button"].exists)
        XCTAssertTrue(app.buttons["signin.go-to-signup-button"].exists)

        // --- SignUp: sang màn, assert, quay lại (QUA identifier) ---
        app.buttons["signin.go-to-signup-button"].tap()
        XCTAssertTrue(app.textFields["signup.email-field"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.secureTextFields["signup.password-field"].exists)
        XCTAssertTrue(app.secureTextFields["signup.confirm-password-field"].exists)
        XCTAssertTrue(app.buttons["signup.submit-button"].exists)
        XCTAssertTrue(app.buttons["signup.go-to-signin-button"].exists)
        app.buttons["signup.go-to-signin-button"].tap()

        // --- Login QUA identifier ---
        XCTAssertTrue(app.textFields["signin.email-field"].waitForExistence(timeout: 5))
        typeInto(app.textFields["signin.email-field"], email)
        pasteInto(app.secureTextFields["signin.password-field"], password)
        app.buttons["signin.submit-button"].tap()
        for _ in 0..<8 { if dismissSavePasswordDialog() { break }; Thread.sleep(forTimeInterval: 1) }

        // --- Home / TaskList ---
        XCTAssertTrue(app.buttons["tasklist.add-button"].waitForExistence(timeout: 20),
                      "tasklist.add-button không tra cứu được (chưa vào Home?)")
        XCTAssertTrue(anyEl("home.greeting-text").exists)
        XCTAssertTrue(app.buttons["home.sign-out-button"].exists)
        XCTAssertTrue(anyEl("tasklist.empty-state").exists, "tasklist.empty-state không tra cứu được")

        // --- AddTask (retry mở sheet: tap "+" đôi khi bị nuốt, như E2E TaskFlow) ---
        let addBtn = app.buttons["tasklist.add-button"]
        let parseBtn = app.buttons["addtask.parse-button"]
        for _ in 0..<3 {
            dismissSavePasswordDialog()
            addBtn.tap()
            if parseBtn.waitForExistence(timeout: 5) { break }
        }
        XCTAssertTrue(parseBtn.exists, "addtask.parse-button không tra cứu được (sheet chưa mở)")
        XCTAssertTrue(app.buttons["addtask.cancel-button"].exists)
        // TextField(axis:.vertical) có thể expose là textField hoặc textView (xem doc).
        var input = app.textFields["addtask.input-field"]
        if !input.exists { input = app.textViews["addtask.input-field"] }
        XCTAssertTrue(input.waitForExistence(timeout: 5), "addtask.input-field không tra cứu được")

        // --- Parse (mock seam) → TaskForm ---
        typeInto(input, "Học tiếng Trung 30 phút tối nay")
        app.buttons["addtask.parse-button"].tap()

        XCTAssertTrue(app.textFields["taskform.name-field"].waitForExistence(timeout: 10),
                      "taskform.name-field không tra cứu được")
        XCTAssertTrue(app.textFields["taskform.minutes-field"].exists)
        XCTAssertTrue(anyEl("taskform.priority-picker").exists, "taskform.priority-picker không tra cứu được")
        XCTAssertTrue(anyEl("taskform.tasktype-picker").exists, "taskform.tasktype-picker không tra cứu được")
        XCTAssertTrue(anyEl("taskform.deadline-toggle").exists, "taskform.deadline-toggle không tra cứu được")
        XCTAssertTrue(app.buttons["taskform.save-button"].exists)
        XCTAssertTrue(app.buttons["taskform.cancel-button"].exists)
    }
}
