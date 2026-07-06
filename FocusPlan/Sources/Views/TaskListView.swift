import SwiftUI

struct TaskListView: View {
    @StateObject private var vm = TaskListViewModel()
    @State private var showingAdd = false
    @State private var editingTask: TaskItem?
    /// Cho HomeView hiển thị đếm "X việc" phía trên list — không đổi hành vi list.
    var onCountChange: ((Int) -> Void)?

    var body: some View {
        Group {
            if vm.isLoading && vm.tasks.isEmpty {
                ProgressView()
            } else if vm.tasks.isEmpty {
                VStack {
                    Text("Chưa có task nào — thêm bằng nút +")
                        .multilineTextAlignment(.center).padding(24)
                }
                .frame(maxWidth: .infinity)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .accessibilityIdentifier(A11yID.TaskList.emptyState)
            } else {
                List {
                    ForEach(vm.tasks) { task in
                        Button { editingTask = task } label: { row(task) }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier(A11yID.TaskList.row(task.id))
                    }
                    .onDelete { indexSet in
                        let targets = indexSet.map { vm.tasks[$0] }
                        Task { for t in targets { await vm.delete(t) } }
                    }
                }
                .listStyle(.plain)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            Button { showingAdd = true } label: {
                Image(systemName: "plus").font(.title2.bold()).padding()
                    .background(Color.accentColor, in: Circle()).foregroundStyle(.white)
            }
            .padding(24)
            .accessibilityLabel("Thêm task")
            .accessibilityIdentifier(A11yID.TaskList.addButton)
        }
        .task { await vm.load() }
        .onChange(of: vm.tasks.count) { _, count in onCountChange?(count) }
        .sheet(isPresented: $showingAdd) {
            AddTaskView(onSaved: { Task { await vm.load() } })
        }
        .sheet(item: $editingTask) { task in
            TaskFormView(mode: .edit(task), onSaved: { Task { await vm.load() } })
        }
        .alert("Lỗi", isPresented: .constant(vm.errorMessage != nil)) {
            Button("OK") { vm.errorMessage = nil }
        } message: { Text(vm.errorMessage ?? "") }
    }

    @ViewBuilder
    private func row(_ task: TaskItem) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(task.name).font(.body)
            HStack(spacing: 8) {
                Text(task.priority.label).font(.caption)
                    .padding(.horizontal, 8).padding(.vertical, 2)
                    .background(Color(.secondarySystemBackground), in: Capsule())
                if let m = task.estimatedMinutes { Text("\(m) phút").font(.caption).foregroundStyle(.secondary) }
                if let d = task.deadline {
                    Text(d.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
