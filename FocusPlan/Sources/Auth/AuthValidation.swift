import Foundation

enum AuthValidation {
    static func validateEmail(_ value: String) -> String? {
        let v = value.trimmingCharacters(in: .whitespaces)
        if v.isEmpty { return "Nhập email" }
        let regex = #"^[^@\s]+@[^@\s]+\.[^@\s]+$"#
        if v.range(of: regex, options: .regularExpression) == nil { return "Email không hợp lệ" }
        return nil
    }

    static func validatePassword(_ value: String) -> String? {
        if value.isEmpty { return "Nhập mật khẩu" }
        if value.count < 6 { return "Mật khẩu tối thiểu 6 ký tự" }
        return nil
    }

    /// Gộp cho sign-in.
    static func validate(email: String, password: String) -> String? {
        return validateEmail(email) ?? validatePassword(password)
    }
}
