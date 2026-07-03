import Foundation
import Supabase

struct HabitRepository {
    private let client = SupabaseManager.shared.client

    // RLS scope theo auth.uid(); user_id để DB default (không set ở client).

    func fetchHabits() async throws -> [Habit] {
        try await client.from("habits")
            .select().order("time_of_day", ascending: true)
            .execute().value
    }

    func createHabit(_ h: NewHabit) async throws -> Habit {
        try await client.from("habits")
            .insert(h, returning: .representation).select().single()
            .execute().value
    }

    func updateHabit(id: UUID, _ patch: HabitUpdate) async throws -> Habit {
        try await client.from("habits")
            .update(patch).eq("id", value: id).select().single()
            .execute().value
    }

    func deleteHabit(id: UUID) async throws {
        try await client.from("habits").delete().eq("id", value: id).execute()
    }

    func fetchLogs(date: String) async throws -> [HabitLog] {
        try await client.from("habit_logs")
            .select().eq("log_date", value: date)
            .execute().value
    }

    func setStatus(habitId: UUID, date: String, status: HabitStatus) async throws -> HabitLog {
        let payload = NewHabitLog(habitId: habitId, logDate: date, status: status)
        return try await client.from("habit_logs")
            .upsert(payload, onConflict: "habit_id,log_date", returning: .representation)
            .select().single()
            .execute().value
    }

    func clearStatus(habitId: UUID, date: String) async throws {
        try await client.from("habit_logs")
            .delete()
            .eq("habit_id", value: habitId)
            .eq("log_date", value: date)
            .execute()
    }
}
