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
            VStack(alignment: .leading, spacing: 16) {
                Text("Đăng nhập").font(.largeTitle).bold()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom, 16)

                TextField("Email", text: $email)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .textFieldStyle(.roundedBorder)
                    .accessibilityIdentifier(A11yID.SignIn.emailField)

                SecureField("Mật khẩu", text: $password)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityIdentifier(A11yID.SignIn.passwordField)

                if let msg = validationError ?? auth.errorMessage {
                    Text(msg).foregroundStyle(.red).font(.footnote)
                        .accessibilityIdentifier(A11yID.SignIn.errorText)
                }

                Button {
                    Task { await submit() }
                } label: {
                    if isSubmitting { ProgressView().frame(maxWidth: .infinity) }
                    else { Text("Đăng nhập").frame(maxWidth: .infinity) }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isSubmitting)
                .accessibilityIdentifier(A11yID.SignIn.submitButton)

                Button("Chưa có tài khoản? Tạo tài khoản", action: onTapCreateAccount)
                    .frame(maxWidth: .infinity)
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
