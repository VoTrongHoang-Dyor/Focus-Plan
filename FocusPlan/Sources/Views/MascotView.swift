import SwiftUI

/// Linh vật Focus Plan — port từ Flutter demo (focus_plan_ui_demo/lib/widgets/brand.dart).
/// 2 layer PNG cùng canvas 189x341: thân + tay xoay quanh khớp vai (151,118).
/// Decorative: accessibilityHidden để không nhiễu screen_elements của MCP (issue 020).
struct MascotView: View {
    let size: CGFloat

    private static let artAspect: CGFloat = 189.0 / 341.0
    private static let armPivot = UnitPoint(x: 151.0 / 189.0, y: 118.0 / 341.0)

    @State private var sway = false   // ngó nghiêng ±0.13 rad + vẫy tay, 1.7s autoreverse
    @State private var bob = false    // nhún 0 → -3pt, 0.85s autoreverse (≈ sin của demo)

    var body: some View {
        ZStack {
            Image("MascotBody").resizable()
            Image("MascotArm").resizable()
                .rotationEffect(.radians(sway ? 0.20 : -0.07), anchor: Self.armPivot)
        }
        .aspectRatio(Self.artAspect, contentMode: .fit)
        .frame(height: size)
        .rotationEffect(.radians(sway ? 0.13 : -0.13))
        .offset(y: bob ? -3 : 0)
        .accessibilityHidden(true)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.7).repeatForever(autoreverses: true)) {
                sway = true
            }
            withAnimation(.easeInOut(duration: 0.85).repeatForever(autoreverses: true)) {
                bob = true
            }
        }
    }
}
