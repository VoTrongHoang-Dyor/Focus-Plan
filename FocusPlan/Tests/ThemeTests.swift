import XCTest
@testable import FocusPlan

final class ThemeTests: XCTestCase {
    func testHexColorParsesIndigoSeed() {
        // #4F46E5 → r=0x4F, g=0x46, b=0xE5 (so khớp components)
        let c = UIColor(Theme.primary)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        c.getRed(&r, green: &g, blue: &b, alpha: &a)
        XCTAssertEqual(r, 0x4F/255, accuracy: 0.01)
        XCTAssertEqual(g, 0x46/255, accuracy: 0.01)
        XCTAssertEqual(b, 0xE5/255, accuracy: 0.01)
    }

    func testRadiusAndSizeTokens() {
        XCTAssertEqual(Theme.radiusInput, 14)
        XCTAssertEqual(Theme.radiusChip, 16)
        XCTAssertEqual(Theme.radiusCard, 20)
        XCTAssertEqual(Theme.ctaHeight, 52)
    }
}
