import XCTest

/// QA end-to-end issue 006: start/pause/resume/hết phiên Pomodoro (rút ngắn qua
/// UITEST_POMODORO_SECONDS) → phiên hoàn thành phải lưu row vào bảng pomodoro_sessions
/// (RLS auth.uid) — verify qua REST, không chỉ qua UI.
final class PomodoroFlowUITests: XCTestCase {
    private let app = XCUIApplication(bundleIdentifier: "com.votronghoang.focusplan")
    private let supabaseURL = "https://njwmpikyqghniqqiweao.supabase.co"
    private let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5qd21waWt5cWdobmlxcWl3ZWFvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODMwNzE3OTIsImV4cCI6MjA5ODY0Nzc5Mn0.gB8a3wg86lBqwh7ltYJ0_tsJOED6O9Vk14DRP3vXjag"
    private let password = "secret123"
    private var token = ""

    override func setUp() { continueAfterFailure = false }

    private func rest(_ method: String, _ path: String, body: [String: Any]?, bearer: String) -> Any? {
        var req = URLRequest(url: URL(string: supabaseURL + path)!)
        req.httpMethod = method
        req.setValue(anonKey, forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(bearer)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "content-type")
        req.setValue("return=representation", forHTTPHeaderField: "Prefer")
        if let body { req.httpBody = try? JSONSerialization.data(withJSONObject: body) }
        var out: Any?
        let sem = DispatchSemaphore(value: 0)
        URLSession.shared.dataTask(with: req) { data, _, _ in
            if let data { out = try? JSONSerialization.jsonObject(with: data) }
            sem.signal()
        }.resume()
        _ = sem.wait(timeout: .now() + 20)
        return out
    }

    /// Sau khi đăng nhập, iOS bật dialog modal "Lưu mật khẩu?" (xuất hiện sau vài giây,
    /// process riêng che UI) → chặn tap tab nếu không tắt. Pattern y hệt HabitFlowUITests.
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

    private func signIn(_ email: String) {
        let signOut = app.buttons["home.sign-out-button"]
        if signOut.waitForExistence(timeout: 5) { signOut.tap() }
        XCTAssertTrue(app.textFields["signin.email-field"].waitForExistence(timeout: 10))
        app.textFields["signin.email-field"].tap()
        app.textFields["signin.email-field"].typeText(email)
        app.secureTextFields["signin.password-field"].tap()
        app.secureTextFields["signin.password-field"].typeText(password)
        app.buttons["signin.submit-button"].tap()
        XCTAssertTrue(app.buttons["home.alarm-button"].waitForExistence(timeout: 20))
        // Dialog "Lưu mật khẩu?" xuất hiện sau vài giây → poll để bắt và tắt trước khi qua tab khác.
        for _ in 0..<8 { if dismissSavePasswordDialog() { break }; Thread.sleep(forTimeInterval: 1) }
    }

    func test_pomodoro_full_cycle_saves_session() {
        let email = "pomoqa\(Int(Date().timeIntervalSince1970))@gmail.com"
        let signup = rest("POST", "/auth/v1/signup", body: ["email": email, "password": password], bearer: anonKey) as? [String: Any]
        token = (signup?["access_token"] as? String) ?? ""
        XCTAssertFalse(token.isEmpty, "Signup không trả token")

        app.launchEnvironment["UITEST_POMODORO_SECONDS"] = "5"
        app.launch()
        signIn(email)

        let tab = app.tabBars.buttons["Tập trung"]
        for _ in 0..<3 {
            dismissSavePasswordDialog()
            tab.tap()
            if app.staticTexts["pomodoro.time-text"].waitForExistence(timeout: 5) { break }
        }
        let timeText = app.staticTexts["pomodoro.time-text"]
        XCTAssertTrue(timeText.waitForExistence(timeout: 10))
        XCTAssertEqual(timeText.label, "00:05")

        // start → pause → resume
        app.buttons["pomodoro.start-button"].tap()
        XCTAssertTrue(app.buttons["pomodoro.pause-button"].waitForExistence(timeout: 5))
        app.buttons["pomodoro.pause-button"].tap()
        XCTAssertTrue(app.buttons["pomodoro.resume-button"].waitForExistence(timeout: 5))
        app.buttons["pomodoro.resume-button"].tap()

        // chờ hết phiên (5s + đệm) → UI quay về idle
        XCTAssertTrue(app.buttons["pomodoro.start-button"].waitForExistence(timeout: 20),
                      "Hết phiên không quay về trạng thái idle")

        // Row đã lưu trên Supabase (criteria 4)
        var saved = false
        for _ in 0..<10 {
            if let rows = rest("GET", "/rest/v1/pomodoro_sessions?select=id", body: nil, bearer: token) as? [[String: Any]],
               !rows.isEmpty { saved = true; break }
            Thread.sleep(forTimeInterval: 1)
        }
        XCTAssertTrue(saved, "Phiên hoàn thành không được lưu vào pomodoro_sessions")
    }
}
