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
            VStack(alignment: .leading, spacing: 16) {
                TextField("Email", text: $email)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .textFieldStyle(.roundedBorder)
                    .accessibilityIdentifier(A11yID.SignUp.emailField)

                SecureField("Mật khẩu", text: $password)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityIdentifier(A11yID.SignUp.passwordField)

                SecureField("Xác nhận mật khẩu", text: $confirm)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityIdentifier(A11yID.SignUp.confirmPasswordField)

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
                    if isSubmitting { ProgressView().frame(maxWidth: .infinity) }
                    else { Text("Tạo tài khoản").frame(maxWidth: .infinity) }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isSubmitting)
                .accessibilityIdentifier(A11yID.SignUp.submitButton)

                Button("Đã có tài khoản? Đăng nhập", action: onBack)
                    .frame(maxWidth: .infinity)
                    .accessibilityIdentifier(A11yID.SignUp.goToSignInButton)

                Spacer()
            }
            .padding(24)
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
