import Foundation
import Supabase

@MainActor
final class AuthViewModel: ObservableObject {
    enum AuthState: Equatable {
        case loading
        case signedOut
        case signedIn(email: String)
    }

    @Published private(set) var state: AuthState = .loading
    @Published var errorMessage: String?

    private let auth = SupabaseManager.shared.client.auth
    private var listenerTask: Task<Void, Never>?

    deinit {
        listenerTask?.cancel()
    }

    /// Lắng nghe thay đổi auth (bao gồm event .initialSession khôi phục session lúc mở app).
    func start() {
        guard listenerTask == nil else { return }
        listenerTask = Task { [weak self] in
            guard let self else { return }
            for await change in self.auth.authStateChanges {
                if let session = change.session {
                    self.state = .signedIn(email: session.user.email ?? "")
                } else {
                    self.state = .signedOut
                }
            }
        }
    }

    func signIn(email: String, password: String) async {
        errorMessage = nil
        do {
            _ = try await auth.signIn(email: email, password: password)
            // state cập nhật qua authStateChanges
        } catch {
            errorMessage = friendlyMessage(error)
        }
    }

    /// return true nếu đăng ký xong đã có session (vào thẳng Home);
    /// false nếu project bật email confirmation (cần user xác nhận email).
    func signUp(email: String, password: String) async -> Bool {
        errorMessage = nil
        do {
            let response = try await auth.signUp(email: email, password: password)
            return response.session != nil
        } catch {
            errorMessage = friendlyMessage(error)
            return false
        }
    }

    func signOut() async {
        do {
            try await auth.signOut()
        } catch {
            errorMessage = friendlyMessage(error)
        }
    }

    private func friendlyMessage(_ error: Error) -> String {
        // Hiện message gốc; đủ cho beta. Có thể map mã lỗi Supabase sau.
        return error.localizedDescription
    }
}
