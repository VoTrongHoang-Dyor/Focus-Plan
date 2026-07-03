import Foundation

@MainActor
final class HabitListViewModel: ObservableObject {
    @Published private(set) var habits: [Habit] = []
    @Published private(set) var logsByHabit: [UUID: HabitStatus] = [:]
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let repo = HabitRepository()

    var todayString: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = .current
        return f.string(from: Date())
    }

    func load() async {
        isLoading = true; errorMessage = nil
        do {
            habits = try await repo.fetchHabits()
            let logs = try await repo.fetchLogs(date: todayString)
            logsByHabit = Dictionary(uniqueKeysWithValues: logs.map { ($0.habitId, $0.status) })
        } catch { errorMessage = error.localizedDescription }
        isLoading = false
    }

    func mark(_ habit: Habit, _ status: HabitStatus) async {
        do {
            if logsByHabit[habit.id] == status {
                try await repo.clearStatus(habitId: habit.id, date: todayString)   // bấm lại để bỏ đánh dấu
                logsByHabit[habit.id] = nil
            } else {
                _ = try await repo.setStatus(habitId: habit.id, date: todayString, status: status)
                logsByHabit[habit.id] = status
            }
        } catch { errorMessage = error.localizedDescription }
    }

    func delete(_ habit: Habit) async {
        do {
            try await repo.deleteHabit(id: habit.id)
            habits.removeAll { $0.id == habit.id }
            logsByHabit[habit.id] = nil
        } catch { errorMessage = error.localizedDescription }
    }
}
