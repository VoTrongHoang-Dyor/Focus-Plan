import Foundation

enum SupabaseConfig {
    static let url: URL = {
        guard let raw = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
              let url = URL(string: raw.trimmingCharacters(in: .whitespaces)) else {
            fatalError("SUPABASE_URL thiếu/không hợp lệ trong Info.plist. Kiểm tra Config/Secrets.xcconfig.")
        }
        return url
    }()

    static let anonKey: String = {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String,
              !key.isEmpty else {
            fatalError("SUPABASE_ANON_KEY thiếu trong Info.plist. Kiểm tra Config/Secrets.xcconfig.")
        }
        return key
    }()
}
