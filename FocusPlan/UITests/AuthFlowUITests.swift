import XCTest
import UIKit

/// QA end-to-end 5 điểm acceptance criteria issue 001.
/// Chạy với Supabase "Confirm email" đã TẮT (mailer_autoconfirm=true) để signup trả session ngay.
final class AuthFlowUITests: XCTestCase {

    private let app = XCUIApplication(bundleIdentifier: "com.votronghoang.focusplan")
    private let password = "secret123"

    override func setUp() {
        continueAfterFailure = false
    }

    private func uniqueEmail() -> String {
        "focusplanqa\(Int(Date().timeIntervalSince1970))@gmail.com"
    }

    private var greeting: XCUIElement {
        app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Xin chào,")).firstMatch
    }

    private var signInMarker: XCUIElement {
        app.buttons["Chưa có tài khoản? Tạo tài khoản"]
    }

    private func typeInto(_ field: XCUIElement, _ text: String) {
        XCTAssertTrue(field.waitForExistence(timeout: 5), "Field không xuất hiện: \(field)")
        field.tap()
        field.typeText(text)
    }

    /// SecureField trên iOS 17 sim bị "Automatic Strong Password" cover chặn typeText.
    /// Dùng pasteboard + long-press Paste để nhập chắc chắn, không đụng code app.
    private func pasteInto(_ field: XCUIElement, _ text: String) {
        XCTAssertTrue(field.waitForExistence(timeout: 5), "SecureField không xuất hiện")
        UIPasteboard.general.string = text
        field.tap()
        field.press(forDuration: 1.3)
        let paste = app.menuItems["Paste"].firstMatch
        XCTAssertTrue(paste.waitForExistence(timeout: 5), "Menu Paste không hiện cho SecureField")
        paste.tap()
    }

    private func snapshot(_ name: String) {
        let att = XCTAttachment(screenshot: app.screenshot())
        att.name = name
        att.lifetime = .keepAlways
        add(att)
    }


    func test_fullAuthFlow() {
        let email = uniqueEmail()
        app.launch()

        // Reset: nếu còn session cũ (Home), sign out về SignIn trước.
        let logout = app.buttons["Đăng xuất"]
        if logout.waitForExistence(timeout: 5) {
            logout.tap()
        }
        XCTAssertTrue(signInMarker.waitForExistence(timeout: 10), "Không tới được màn SignIn ban đầu")

        // ===== Criteria 1: Sign up -> vào thẳng Home =====
        signInMarker.tap()
        typeInto(app.textFields["Email"], email)
        pasteInto(app.secureTextFields["Mật khẩu"], password)
        pasteInto(app.secureTextFields["Xác nhận mật khẩu"], password)
        snapshot("01-signup-filled")
        app.buttons["Tạo tài khoản"].tap()

        if !greeting.waitForExistence(timeout: 20) {
            snapshot("01b-signup-failed")
            XCTFail("[Criteria 1] Sau sign up không vào Home. email=\(email)")
        }
        XCTAssertTrue(greeting.label.contains(email),
                      "[Criteria 1] Greeting sai email. label=\(greeting.label)")

        // ===== Criteria 5: Empty-state (dải 7 ngày + card) =====
        XCTAssertTrue(app.staticTexts["Chưa có task nào — sẽ thêm ở slice sau"].exists,
                      "[Criteria 5] Thiếu card empty-state")
        XCTAssertTrue(app.staticTexts["T2"].exists && app.staticTexts["T6"].exists,
                      "[Criteria 5] Thiếu dải 7 ngày")

        // ===== Criteria 3: Session persist qua terminate + relaunch =====
        app.terminate()
        app.launch()
        XCTAssertTrue(greeting.waitForExistence(timeout: 20),
                      "[Criteria 3] Session không persist qua relaunch")

        // ===== Criteria 4: Sign out -> SignIn, relaunch vẫn SignIn =====
        app.buttons["Đăng xuất"].tap()
        XCTAssertTrue(signInMarker.waitForExistence(timeout: 10),
                      "[Criteria 4] Sign out không về SignIn")
        app.terminate()
        app.launch()
        XCTAssertTrue(signInMarker.waitForExistence(timeout: 10),
                      "[Criteria 4] Relaunch sau sign out không ở SignIn (session chưa xoá)")
        XCTAssertFalse(greeting.exists,
                       "[Criteria 4] Vẫn còn Home sau khi sign out")

        // ===== Criteria 2: Sign in lại -> Home, greeting đúng email =====
        typeInto(app.textFields["Email"], email)
        pasteInto(app.secureTextFields["Mật khẩu"], password)
        app.buttons["Đăng nhập"].tap()
        XCTAssertTrue(greeting.waitForExistence(timeout: 20),
                      "[Criteria 2] Sign in không vào Home")
        XCTAssertTrue(greeting.label.contains(email),
                      "[Criteria 2] Greeting sai email sau sign in. label=\(greeting.label)")
    }
}
