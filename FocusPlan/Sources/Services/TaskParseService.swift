import Foundation
import Supabase

struct TaskParseService {
    private let client = SupabaseManager.shared.client

    struct RequestBody: Encodable { let text: String }

    func parse(_ text: String) async throws -> ParsedTaskDraft {
        // functions.invoke tự đính JWT của session hiện tại (verify_jwt bật).
        let draft: ParsedTaskDraft = try await client.functions.invoke(
            "parse-task",
            options: FunctionInvokeOptions(body: RequestBody(text: text))
        )
        return draft
    }
}
