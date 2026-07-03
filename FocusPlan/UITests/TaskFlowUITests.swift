import XCTest
import UIKit

/// QA in-app cho issue 002 (phần KHÔNG cần Edge Function):
/// - Seed 1 user + 1 task qua REST (anon key public), rồi đăng nhập app và xác nhận
///   task hiển thị trong danh sách → chứng minh TaskRepository.fetchAll decode được
///   TaskItem (gồm timestamptz created_at/deadline) và TaskListView render đúng.
/// Criteria 1 (NL parse) cần Edge Function deploy → QA riêng sau khi deploy.
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

    private func seedUserAndTask(taskName: String) -> String {
        let ts = Int(Date().timeIntervalSince1970)
        let email = "qaseed\(ts)@gmail.com"
        let signup = postJSON("/auth/v1/signup", body: ["email": email, "password": password], bearer: anonKey)
        let token = signup?["access_token"] as? String
        XCTAssertNotNil(token, "Seed: signup không trả access_token (Confirm email phải TẮT)")
        let inserted = postJSON("/rest/v1/tasks",
                                body: ["name": taskName, "estimated_minutes": 45,
                                       "priority": "high", "deadline": "2026-07-10T09:30:00+00:00"],
                                bearer: token ?? "")
        XCTAssertNotNil(inserted?["id"], "Seed: insert task thất bại")
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
}
