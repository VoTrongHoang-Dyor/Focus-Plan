import Foundation

@MainActor
final class TaskListViewModel: ObservableObject {
    @Published private(set) var tasks: [TaskItem] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let repo = TaskRepository()

    func load() async {
        isLoading = true
        errorMessage = nil
        do { tasks = try await repo.fetchAll() }
        catch { errorMessage = error.localizedDescription }
        isLoading = false
    }

    func delete(_ task: TaskItem) async {
        do {
            try await repo.delete(id: task.id)
            tasks.removeAll { $0.id == task.id }
        } catch { errorMessage = error.localizedDescription }
    }
}
