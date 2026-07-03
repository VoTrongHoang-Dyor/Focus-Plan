import Foundation
import Supabase

struct TaskRepository {
    private let client = SupabaseManager.shared.client
    private let table = "tasks"

    func fetchAll() async throws -> [TaskItem] {
        try await client.from(table)
            .select()
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    func create(_ task: NewTask) async throws -> TaskItem {
        try await client.from(table)
            .insert(task, returning: .representation)
            .select()
            .single()
            .execute()
            .value
    }

    func update(id: UUID, _ patch: TaskUpdate) async throws -> TaskItem {
        try await client.from(table)
            .update(patch)
            .eq("id", value: id)
            .select()
            .single()
            .execute()
            .value
    }

    func delete(id: UUID) async throws {
        try await client.from(table)
            .delete()
            .eq("id", value: id)
            .execute()
    }
}
