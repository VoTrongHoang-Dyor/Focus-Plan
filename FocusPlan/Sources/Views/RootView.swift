import SwiftUI

struct RootView: View {
    @StateObject private var auth = AuthViewModel()
    @State private var showingSignUp = false

    var body: some View {
        Group {
            switch auth.state {
            case .loading:
                ProgressView()               // splash
            case .signedOut:
                if showingSignUp {
                    SignUpView(auth: auth, onBack: {
                        auth.errorMessage = nil
                        showingSignUp = false
                    })
                } else {
                    SignInView(auth: auth, onTapCreateAccount: {
                        auth.errorMessage = nil
                        showingSignUp = true
                    })
                }
            case .signedIn(let email):
                MainTabView(auth: auth, email: email)
            }
        }
        .task { auth.start() }
        .onChange(of: auth.state) { _, newValue in
            if case .signedIn = newValue { showingSignUp = false }
        }
    }
}
