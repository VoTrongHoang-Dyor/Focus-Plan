import XCTest
import UIKit

/// Issue 021: tạo alarm qua UI hoàn toàn bằng identifier + chứng minh persist qua relaunch
/// (form prefill từ alarm lưu gần nhất — vibrate OFF sống sót sau terminate/relaunch).
final class AlarmFlowUITests: XCTestCase {

    private let app = XCUIApplication(bundleIdentifier: "com.votronghoang.focusplan")
    private let supabaseURL = "https://njwmpikyqghniqqiweao.supabase.co"
    private let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5qd21waWt5cWdobmlxcWl3ZWFvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODMwNzE3OTIsImV4cCI6MjA5ODY0Nzc5Mn0.gB8a3wg86lBqwh7ltYJ0_tsJOED6O9Vk14DRP3vXjag"
    private let password = "secret123"

    override func setUp() { continueAfterFailure = false }

    // MARK: - Helpers (copy tối thiểu từ A11yIdentifierUITests)

    private func postJSON(_ path: String, body: [String: Any], bearer: String) -> [String: Any]? {
        var req = URLRequest(url: URL(string: supabaseURL + path)!)
        req.httpMethod = "POST"
        req.setValue(anonKey, forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(bearer)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "content-type")
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        var result: [String: Any]?
        let sem = DispatchSemaphore(value: 0)
        URLSession.shared.dataTask(with: req) { data, _, _ in
            if let data, let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                result = obj
            }
            sem.signal()
        }.resume()
        _ = sem.wait(timeout: .now() + 20)
        return result
    }

    private func seedUser() -> String {
        let email = "alarmqa\(Int(Date().timeIntervalSince1970))_\(UInt32.random(in: 0 ..< 1_000_000))@gmail.com"
        let signup = postJSON("/auth/v1/signup", body: ["email": email, "password": password], bearer: anonKey)
        XCTAssertNotNil(signup?["access_token"] as? String, "Seed: signup không trả token")
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

    private func signIn(email: String) {
        let signOut = app.buttons["home.sign-out-button"]
        if signOut.waitForExistence(timeout: 5) { signOut.tap() }
        XCTAssertTrue(app.textFields["signin.email-field"].waitForExistence(timeout: 10))
        typeInto(app.textFields["signin.email-field"], email)
        pasteInto(app.secureTextFields["signin.password-field"], password)
        app.buttons["signin.submit-button"].tap()
        for _ in 0..<8 { if dismissSavePasswordDialog() { break }; Thread.sleep(forTimeInterval: 1) }
        XCTAssertTrue(app.buttons["home.alarm-button"].waitForExistence(timeout: 20),
                      "home.alarm-button không xuất hiện sau đăng nhập")
    }

    /// Mở AlarmFormView (retry tap như pattern add-button các test cũ).
    private func openAlarmForm() {
        let alarmBtn = app.buttons["home.alarm-button"]
        let createBtn = app.buttons["alarmform.create-button"]
        for _ in 0..<3 {
            dismissSavePasswordDialog()
            alarmBtn.tap()
            if createBtn.waitForExistence(timeout: 5) { break }
        }
        XCTAssertTrue(createBtn.exists, "AlarmFormView chưa mở (create-button không thấy)")
    }

    // MARK: - Test

    func test_create_alarm_via_identifiers_and_persist_across_relaunch() {
        let email = seedUser()
        // UserAlarmStore là single-device (UserDefaults.standard, không theo tài khoản) —
        // reset ở lần launch đầu để test không phụ thuộc state alarm còn sót từ lần chạy trước.
        app.launchEnvironment["UITEST_RESET_USER_ALARMS"] = "1"
        app.launch()
        signIn(email: email)

        // --- Mở form, đủ control qua identifier ---
        openAlarmForm()
        XCTAssertTrue(app.buttons["alarmform.time-text"].exists)
        XCTAssertTrue(app.buttons["alarmform.day-toggle-2"].exists)   // T2
        XCTAssertTrue(app.buttons["alarmform.day-toggle-1"].exists)   // CN
        XCTAssertTrue(app.switches["alarmform.loop-audio-toggle"].exists)
        XCTAssertTrue(app.switches["alarmform.show-notification-toggle"].exists)
        XCTAssertTrue(app.staticTexts["alarmform.hint-text"].exists)

        // --- Cấu hình đặc trưng: chọn T2 + T4, tắt Vibrate ---
        app.buttons["alarmform.day-toggle-2"].tap()
        app.buttons["alarmform.day-toggle-4"].tap()
        let vibrate = app.switches["alarmform.vibrate-toggle"]
        XCTAssertEqual(vibrate.value as? String, "1", "Vibrate mặc định phải ON")
        vibrate.switches.firstMatch.tap()   // SwiftUI Toggle: tap switch con
        XCTAssertEqual(vibrate.value as? String, "0")

        // --- Create Alarm → sheet đóng ---
        app.buttons["alarmform.create-button"].tap()
        XCTAssertTrue(app.buttons["home.alarm-button"].waitForExistence(timeout: 10),
                      "Sheet chưa đóng sau Create Alarm")

        // --- Relaunch: session Supabase còn, form prefill từ alarm đã lưu ---
        // KHÔNG reset UserAlarmStore lần relaunch này — mới chứng minh được persist thật.
        app.launchEnvironment["UITEST_RESET_USER_ALARMS"] = nil
        app.terminate()
        app.launch()
        XCTAssertTrue(app.buttons["home.alarm-button"].waitForExistence(timeout: 20),
                      "Session không persist sau relaunch")
        openAlarmForm()
        XCTAssertEqual(app.switches["alarmform.vibrate-toggle"].value as? String, "0",
                       "Vibrate OFF không persist qua relaunch")
        // Day chip đã chọn persist (trait isSelected).
        XCTAssertTrue(app.buttons["alarmform.day-toggle-2"].isSelected,
                      "Ngày T2 đã chọn không persist qua relaunch")
    }
}
