import SwiftUI

struct HabitsView: View {
    @StateObject private var vm = HabitListViewModel()
    @State private var showingAdd = false
    @State private var editingHabit: Habit?

    var body: some View {
        NavigationStack {
            Group {
                if vm.isLoading && vm.habits.isEmpty {
                    ProgressView()
                } else if vm.habits.isEmpty {
                    ContentUnavailableView("Chưa có thói quen", systemImage: "repeat",
                        description: Text("Thêm thói quen bằng nút +"))
                } else {
                    List {
                        ForEach(vm.habits) { habit in
                            row(habit)
                        }
                        .onDelete { idx in
                            let targets = idx.map { vm.habits[$0] }
                            Task { for h in targets { await vm.delete(h) } }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Thói quen")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingAdd = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Thêm thói quen")
                }
            }
            .task { await vm.load() }
            .sheet(isPresented: $showingAdd) {
                HabitFormView(mode: .create, onSaved: { Task { await vm.load() } })
            }
            .sheet(item: $editingHabit) { h in
                HabitFormView(mode: .edit(h), onSaved: { Task { await vm.load() } })
            }
            .alert("Lỗi", isPresented: .constant(vm.errorMessage != nil)) {
                Button("OK") { vm.errorMessage = nil }
            } message: { Text(vm.errorMessage ?? "") }
        }
    }

    @ViewBuilder
    private func row(_ habit: Habit) -> some View {
        let status = vm.logsByHabit[habit.id]
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(habit.name)
                Text("\(String(habit.timeOfDay.prefix(5))) · \(habit.durationMinutes) phút")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                Task { await vm.mark(habit, .done) }
            } label: {
                Image(systemName: status == .done ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(status == .done ? .green : .secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Đánh dấu hoàn thành")
            Button {
                Task { await vm.mark(habit, .missed) }
            } label: {
                Image(systemName: status == .missed ? "xmark.circle.fill" : "circle")
                    .foregroundStyle(status == .missed ? .red : .secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Đánh dấu bỏ lỡ")
        }
        .contentShape(Rectangle())
        .onTapGesture { editingHabit = habit }
    }
}
