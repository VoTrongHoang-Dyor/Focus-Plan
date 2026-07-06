import SwiftUI

/// Design tokens port từ focus_plan_ui_demo (Material 3, seed #4F46E5).
/// Mọi view dùng token này — không hardcode màu/radius trong view.
enum Theme {
    static let primary = Color(hex: 0x4F46E5)
    static let primaryContainer = Color(hex: 0xE0E7FF)   // indigo 100
    static let onPrimaryContainer = Color(hex: 0x312E81) // indigo 900
    static let secondaryContainer = Color(hex: 0xE0E7FF)
    static let done = Color(hex: 0x059669)               // emerald 600
    static let surfaceVariant = Color(.secondarySystemBackground)
    static let onSurfaceVariant = Color(.secondaryLabel)

    static let radiusInput: CGFloat = 14
    static let radiusChip: CGFloat = 16
    static let radiusCard: CGFloat = 20
    static let ctaHeight: CGFloat = 52
}

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}
