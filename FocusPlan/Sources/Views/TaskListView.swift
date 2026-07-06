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
                VStack(spacing: 12) {
                    Image(systemName: "tray")
                        .font(.system(size: 36))
                        .foregroundStyle(Theme.onSurfaceVariant)
                    // Giữ NGUYÊN văn bản — TaskFlowUITests/AuthFlowUITests định vị bằng text này.
                    Text("Chưa có task nào — thêm bằng nút +")
                        .font(.subheadline)
                        .foregroundStyle(Theme.onSurfaceVariant)
                        .multilineTextAlignment(.center)
                }
                .padding(32)
                .frame(maxWidth: .infinity)
                .background(Theme.surfaceVariant, in: RoundedRectangle(cornerRadius: Theme.radiusCard))
                .accessibilityIdentifier(A11yID.TaskList.emptyState)
            } else {
                List {
                    ForEach(vm.tasks) { task in
                        Button { editingTask = task } label: { row(task) }
                            .buttonStyle(.plain)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
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
                    .background(Theme.primary, in: Circle()).foregroundStyle(.white)
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
        let accent = priorityColor(task.priority)
        HStack(alignment: .top, spacing: 0) {
            RoundedRectangle(cornerRadius: 2)
                .fill(accent)
                .frame(width: 4)
            VStack(alignment: .leading, spacing: 8) {
                Text(task.name).font(.subheadline.weight(.semibold))
                HStack(spacing: 6) {
                    badge(task.priority.label, color: accent, filled: true)
                    if let m = task.estimatedMinutes {
                        badge("\(m) phút", color: Theme.onSurfaceVariant, filled: false)
                    }
                    if let d = task.deadline {
                        badge(d.formatted(date: .abbreviated, time: .shortened),
                              color: Theme.onSurfaceVariant, filled: false)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: Theme.radiusCard))
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusCard))
        .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
    }

    private func priorityColor(_ priority: TaskPriority) -> Color {
        switch priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return Theme.onSurfaceVariant
        }
    }

    private func badge(_ text: String, color: Color, filled: Bool) -> some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(filled ? color.opacity(0.12) : Color.clear, in: Capsule())
            .overlay {
                if !filled { Capsule().stroke(Theme.onSurfaceVariant.opacity(0.3), lineWidth: 1) }
            }
    }
}
