import Foundation
import Supabase

struct PomodoroSessionRepository {
    private let client = SupabaseManager.shared.client

    // RLS scope theo auth.uid(); user_id để DB default (không set ở client).

    func create(_ s: NewPomodoroSession) async throws -> PomodoroSession {
        try await client.from("pomodoro_sessions")
            .insert(s, returning: .representation).select().single()
            .execute().value
    }

    func fetchSessions() async throws -> [PomodoroSession] {
        try await client.from("pomodoro_sessions")
            .select().order("started_at", ascending: false)
            .execute().value
    }
}
