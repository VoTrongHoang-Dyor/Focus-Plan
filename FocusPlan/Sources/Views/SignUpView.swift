import SwiftUI

struct SignUpView: View {
    @ObservedObject var auth: AuthViewModel
    var onBack: () -> Void

    @State private var email = ""
    @State private var password = ""
    @State private var confirm = ""
    @State private var validationError: String?
    @State private var infoMessage: String?
    @State private var isSubmitting = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Image("BrandLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 110)

                    Text("Tạo tài khoản để bắt đầu")
                        .font(.subheadline)
                        .foregroundStyle(Theme.onSurfaceVariant)
                        .padding(.bottom, 8)

                    AuthField(icon: "envelope") {
                        TextField("Email", text: $email)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            .autocorrectionDisabled()
                            .accessibilityIdentifier(A11yID.SignUp.emailField)
                    }
                    AuthField(icon: "lock") {
                        SecureField("Mật khẩu", text: $password)
                            .accessibilityIdentifier(A11yID.SignUp.passwordField)
                    }
                    AuthField(icon: "lock.shield") {
                        SecureField("Xác nhận mật khẩu", text: $confirm)
                            .accessibilityIdentifier(A11yID.SignUp.confirmPasswordField)
                    }

                    if let msg = validationError ?? auth.errorMessage {
                        Text(msg).foregroundStyle(.red).font(.footnote)
                            .accessibilityIdentifier(A11yID.SignUp.errorText)
                    }
                    if let info = infoMessage {
                        Text(info).foregroundStyle(.green).font(.footnote)
                            .accessibilityIdentifier(A11yID.SignUp.infoText)
                    }

                    Button {
                        Task { await submit() }
                    } label: {
                        if isSubmitting {
                            ProgressView().tint(.white).frame(maxWidth: .infinity)
                        } else {
                            Text("Tạo tài khoản").font(.headline).frame(maxWidth: .infinity)
                        }
                    }
                    .authCTAStyle()
                    .disabled(isSubmitting)
                    .accessibilityIdentifier(A11yID.SignUp.submitButton)
                    .padding(.top, 8)

                    Button("Đã có tài khoản? Đăng nhập", action: onBack)
                        .accessibilityIdentifier(A11yID.SignUp.goToSignInButton)
                }
                .padding(24)
            }
            .navigationTitle("Tạo tài khoản")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func submit() async {
        infoMessage = nil
        validationError = AuthValidation.validateEmail(email)
            ?? AuthValidation.validatePassword(password)
            ?? (password != confirm ? "Mật khẩu xác nhận không khớp" : nil)
        guard validationError == nil else { return }

        isSubmitting = true
        let hasSession = await auth.signUp(
            email: email.trimmingCharacters(in: .whitespaces),
            password: password
        )
        isSubmitting = false
        // Nếu hasSession == true: RootView tự chuyển sang Home qua authStateChanges.
        // Nếu false và không có lỗi: cần xác nhận email.
        if !hasSession && auth.errorMessage == nil {
            infoMessage = "Kiểm tra email để xác nhận tài khoản, sau đó đăng nhập."
        }
    }
}
