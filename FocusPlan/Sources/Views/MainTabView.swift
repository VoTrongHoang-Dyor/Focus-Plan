import SwiftUI

struct MainTabView: View {
    @ObservedObject var auth: AuthViewModel
    let email: String

    var body: some View {
        TabView {
            HomeView(auth: auth, email: email)
                .tabItem { Label("Hôm nay", systemImage: "calendar") }
            HabitsView()
                .tabItem { Label("Thói quen", systemImage: "repeat") }
            PomodoroView()
                .tabItem { Label("Tập trung", systemImage: "timer") }
        }
        .tint(Theme.primary)
    }
}
