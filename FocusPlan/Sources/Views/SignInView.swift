import SwiftUI

struct SignInView: View {
    @ObservedObject var auth: AuthViewModel
    var onTapCreateAccount: () -> Void

    @State private var email = ""
    @State private var password = ""
    @State private var validationError: String?
    @State private var isSubmitting = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Spacer()

                Image("BrandLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 120)

                Text("Đăng nhập")
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
                Text("Chào mừng bạn quay lại")
                    .font(.subheadline)
                    .foregroundStyle(Theme.onSurfaceVariant)

                VStack(spacing: 16) {
                    AuthField(icon: "envelope") {
                        TextField("Email", text: $email)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            .autocorrectionDisabled()
                            .accessibilityIdentifier(A11yID.SignIn.emailField)
                    }
                    AuthField(icon: "lock") {
                        SecureField("Mật khẩu", text: $password)
                            .accessibilityIdentifier(A11yID.SignIn.passwordField)
                    }
                }
                .padding(.top, 12)

                if let msg = validationError ?? auth.errorMessage {
                    Text(msg).foregroundStyle(.red).font(.footnote)
                        .accessibilityIdentifier(A11yID.SignIn.errorText)
                }

                Button {
                    Task { await submit() }
                } label: {
                    if isSubmitting {
                        ProgressView().tint(.white).frame(maxWidth: .infinity)
                    } else {
                        Text("Đăng nhập").font(.headline).frame(maxWidth: .infinity)
                    }
                }
                .authCTAStyle()
                .disabled(isSubmitting)
                .accessibilityIdentifier(A11yID.SignIn.submitButton)
                .padding(.top, 8)

                Button("Chưa có tài khoản? Tạo tài khoản", action: onTapCreateAccount)
                    .accessibilityIdentifier(A11yID.SignIn.goToSignUpButton)

                Spacer()
            }
            .padding(24)
        }
    }

    private func submit() async {
        validationError = AuthValidation.validate(email: email, password: password)
        guard validationError == nil else { return }
        isSubmitting = true
        await auth.signIn(email: email.trimmingCharacters(in: .whitespaces), password: password)
        isSubmitting = false
    }
}
