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
