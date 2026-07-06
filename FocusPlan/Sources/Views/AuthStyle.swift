import SwiftUI

/// Style input filled dùng chung Sign In / Sign Up — port từ `auth_style.dart`
/// (filled, bo `Theme.radiusInput`, không viền, prefix icon).
struct AuthField<Content: View>: View {
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(Theme.onSurfaceVariant)
            content
        }
        .padding(.horizontal, 16)
        .frame(height: Theme.ctaHeight)
        .background(Theme.surfaceVariant, in: RoundedRectangle(cornerRadius: Theme.radiusInput))
    }
}

extension View {
    /// CTA chính màn auth/form: cao `Theme.ctaHeight`, bo `Theme.radiusInput`, nền `Theme.primary`.
    func authCTAStyle() -> some View {
        self
            .frame(maxWidth: .infinity, minHeight: Theme.ctaHeight)
            .background(Theme.primary, in: RoundedRectangle(cornerRadius: Theme.radiusInput))
            .foregroundStyle(Color.white)
    }

    /// Field filled dùng ngoài Form/List (TaskFormView/HabitFormView): nền `Theme.surfaceVariant`
    /// bo `Theme.radiusInput`, không viền — đồng bộ `AuthField` khi không cần prefix icon.
    func filledFieldStyle() -> some View {
        self
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Theme.surfaceVariant, in: RoundedRectangle(cornerRadius: Theme.radiusInput))
    }
}
