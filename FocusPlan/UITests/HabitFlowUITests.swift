import XCTest
import UIKit

/// QA in-app issue 003: seed user + habit qua REST, đăng nhập app → tab "Thói quen"
/// xác nhận habit hiển thị (criteria 1, decode), rồi test checklist done + persist qua
/// terminate/relaunch (criteria 2). RLS multi-user verify ở REST (script riêng).
final class HabitFlowUITests: XCTestCase {

    private let app = XCUIApplication(bundleIdentifier: "com.votronghoang.focusplan")
    private let supabaseURL = "https://njwmpikyqghniqqiweao.supabase.co"
    private let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5qd21waWt5cWdobmlxcWl3ZWFvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODMwNzE3OTIsImV4cCI6MjA5ODY0Nzc5Mn0.gB8a3wg86lBqwh7ltYJ0_tsJOED6O9Vk14DRP3vXjag"
    private let password = "secret123"

    private var token = ""
    private var habitId = ""

    override func setUp() { continueAfterFailure = false }

    // MARK: REST helpers (đồng bộ bằng semaphore)

    private func rest(_ method: String, _ path: String, body: Any?, bearer: String) -> Any? {
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

    private func seedUserAndHabit() -> String {
        let ts = Int(Date().timeIntervalSince1970)
        let email = "habitqa\(ts)@gmail.com"
        let signup = rest("POST", "/auth/v1/signup", body: ["email": email, "password": password], bearer: anonKey) as? [String: Any]
        token = (signup?["access_token"] as? String) ?? ""
        XCTAssertFalse(token.isEmpty, "Seed: signup không trả token (Confirm email phải TẮT)")
        let inserted = (rest("POST", "/rest/v1/habits",
                             body: ["name": "Thiền", "time_of_day": "06:00:00", "duration_minutes": 20],
                             bearer: token) as? [[String: Any]])?.first
        habitId = (inserted?["id"] as? String) ?? ""
        XCTAssertFalse(habitId.isEmpty, "Seed: tạo habit thất bại")
        return email
    }

    private func todayString() -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; f.timeZone = .current
        return f.string(from: Date())
    }

    private func fetchTodayLogStatus() -> String? {
        let today = todayString()
        let rows = rest("GET", "/rest/v1/habit_logs?habit_id=eq.\(habitId)&log_date=eq.\(today)&select=status", body: nil, bearer: token) as? [[String: Any]]
        return rows?.first?["status"] as? String
    }

    private func typeInto(_ field: XCUIElement, _ text: String) {
        XCTAssertTrue(field.waitForExistence(timeout: 5)); field.tap(); field.typeText(text)
    }
    private func pasteInto(_ field: XCUIElement, _ text: String) {
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        UIPasteboard.general.string = text
        field.tap(); field.press(forDuration: 1.3)
        let paste = app.menuItems["Paste"].firstMatch
        XCTAssertTrue(paste.waitForExistence(timeout: 5)); paste.tap()
    }

    private func signIn(_ email: String) {
        app.launch()
        let logout = app.buttons["Đăng xuất"]
        if logout.waitForExistence(timeout: 5) { logout.tap() }
        let goSignIn = app.buttons["Chưa có tài khoản? Tạo tài khoản"]
        XCTAssertTrue(goSignIn.waitForExistence(timeout: 10))
        typeInto(app.textFields["Email"], email)
        pasteInto(app.secureTextFields["Mật khẩu"], password)
        app.buttons["Đăng nhập"].tap()
        // Dialog "Lưu mật khẩu?" xuất hiện sau vài giây → poll để bắt và tắt.
        for _ in 0..<8 { if dismissSavePasswordDialog() { break }; Thread.sleep(forTimeInterval: 1) }
    }

    /// Sau khi đăng nhập, iOS bật dialog modal "Lưu mật khẩu?" che UI → chặn tap tab.
    /// Trên iOS mới (26) dialog nằm trong app hierarchy (không phải springboard) nên tìm
    /// nút "Để sau" ở app trước rồi mới fallback springboard. Tap-if-present, trả true nếu tắt.
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

    private func openHabitsTab() {
        let tab = app.tabBars.buttons["Thói quen"]
        XCTAssertTrue(tab.waitForExistence(timeout: 20), "Không thấy tab Thói quen (chưa vào MainTabView?)")
        // Tắt dialog phòng khi còn che rồi tap tab (retry đến khi vào màn Thói quen).
        for _ in 0..<3 {
            dismissSavePasswordDialog()
            tab.tap()
            if app.navigationBars["Thói quen"].waitForExistence(timeout: 5) { break }
        }
    }

    func test_habit_shows_and_checklist_persists() {
        let email = seedUserAndHabit()
        signIn(email)
        openHabitsTab()

        // Criteria 1: habit seed hiển thị (decode + list + tab wiring).
        if !app.staticTexts["Thiền"].waitForExistence(timeout: 20) {
            let att = XCTAttachment(screenshot: app.screenshot())
            att.name = "habits-tab-no-habit"; att.lifetime = .keepAlways; add(att)
            let alertMsg = app.alerts.staticTexts.allElementsBoundByIndex.map { $0.label }.joined(separator: " | ")
            XCTFail("Habit đã seed không hiện. habitId=\(habitId) token?=\(!token.isEmpty) alert=[\(alertMsg)]")
        }

        // Criteria 1b (issue 025): habit 06:00 nằm trong section "Buổi sáng".
        XCTAssertTrue(app.staticTexts["Buổi sáng"].waitForExistence(timeout: 5),
                      "Không thấy section header 'Buổi sáng' — grouping theo buổi chưa render")

        // Criteria 2: tap done → ghi xuống Supabase.
        let doneBtn = app.buttons["Đánh dấu hoàn thành"].firstMatch
        XCTAssertTrue(doneBtn.waitForExistence(timeout: 5))
        doneBtn.tap()
        // chờ ghi
        var status: String?
        for _ in 0..<10 { status = fetchTodayLogStatus(); if status == "done" { break }; Thread.sleep(forTimeInterval: 1) }
        XCTAssertEqual(status, "done", "Tap done không ghi log 'done' vào Supabase")

        // Persist qua terminate + relaunch: app load lại trạng thái 'done' đã lưu.
        // Bằng chứng hành vi: sau relaunch bấm done LẦN NỮA → theo toggle sẽ CLEAR
        // (chỉ xảy ra nếu app đã nạp đúng trạng thái done đã persist).
        app.terminate()
        app.launch()
        openHabitsTab()
        XCTAssertTrue(app.staticTexts["Thiền"].waitForExistence(timeout: 20))
        let doneBtn2 = app.buttons["Đánh dấu hoàn thành"].firstMatch
        XCTAssertTrue(doneBtn2.waitForExistence(timeout: 5))
        doneBtn2.tap()
        var cleared = false
        for _ in 0..<10 { if fetchTodayLogStatus() == nil { cleared = true; break }; Thread.sleep(forTimeInterval: 1) }
        XCTAssertTrue(cleared, "Sau relaunch bấm done không clear → app chưa nạp đúng trạng thái persist")
    }
}
