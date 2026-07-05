import Foundation
import Supabase

struct TaskParseService {
    private let client = SupabaseManager.shared.client

    struct RequestBody: Encodable { let text: String }

    func parse(_ text: String) async throws -> ParsedTaskDraft {
        // Test-seam: khi UITest set env này → dùng draft canned, bỏ qua Gemini/Edge Function.
        // Không set (user thật) → chạy production path bình thường.
        if let mock = ProcessInfo.processInfo.environment["UITEST_MOCK_PARSE_DRAFT"] {
            return try JSONDecoder().decode(ParsedTaskDraft.self, from: Data(mock.utf8))
        }
        // functions.invoke tự đính JWT của session hiện tại (verify_jwt bật).
        let draft: ParsedTaskDraft = try await client.functions.invoke(
            "parse-task",
            options: FunctionInvokeOptions(body: RequestBody(text: text))
        )
        return draft
    }
}
