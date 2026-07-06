import XCTest
@testable import FocusPlan

final class UserAlarmStoreTests: XCTestCase {
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "UserAlarmStoreTests")!
        defaults.removePersistentDomain(forName: "UserAlarmStoreTests")
    }

    func test_append_then_load_roundtrips_all_fields() {
        let store = UserAlarmStore(defaults: defaults)
        let alarm = UserAlarm(hour: 16, minute: 26, repeatDays: [2, 4, 6],
                              loopAudio: true, vibrate: false,
                              systemVolumeMax: true, showNotification: true)
        store.append(alarm)
        // Store MỚI cùng defaults → chứng minh persist (không phải cache in-memory).
        let reloaded = UserAlarmStore(defaults: defaults).load()
        XCTAssertEqual(reloaded, [alarm])
    }

    func test_latest_returns_last_appended() {
        let store = UserAlarmStore(defaults: defaults)
        store.append(UserAlarm(hour: 7, minute: 0))
        store.append(UserAlarm(hour: 22, minute: 30))
        XCTAssertEqual(store.latest?.hour, 22)
        XCTAssertEqual(store.latest?.minute, 30)
    }

    func test_load_empty_when_nothing_saved() {
        XCTAssertEqual(UserAlarmStore(defaults: defaults).load(), [])
    }
}
