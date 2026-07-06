import SwiftUI

struct HabitsView: View {
    @StateObject private var vm = HabitListViewModel()
    @State private var showingAdd = false
    @State private var editingHabit: Habit?

    private var doneCount: Int { vm.logsByHabit.values.filter { $0 == .done }.count }

    var body: some View {
        NavigationStack {
            Group {
                if vm.isLoading && vm.habits.isEmpty {
                    ProgressView()
                } else if vm.habits.isEmpty {
                    emptyState
                } else {
                    List {
                        Section {
                            SummaryHeader(done: doneCount, total: vm.habits.count)
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)

                        ForEach(DayPart.allCases, id: \.self) { part in
                            let items = habits(in: part)
                            if !items.isEmpty {
                                Section {
                                    ForEach(items) { habit in
                                        row(habit)
                                    }
                                    .onDelete { idx in
                                        let targets = idx.map { items[$0] }
                                        Task { for h in targets { await vm.delete(h) } }
                                    }
                                } header: {
                                    Label(part.label, systemImage: part.icon)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(Theme.onSurfaceVariant)
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
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

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "repeat")
                .font(.system(size: 40))
                .foregroundStyle(Theme.onSurfaceVariant)
            Text("Chưa có thói quen nào")
                .font(.title3.weight(.semibold))
            Text("Thêm thói quen cố định hàng ngày để theo dõi mỗi ngày.")
                .font(.subheadline)
                .foregroundStyle(Theme.onSurfaceVariant)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            Button {
                showingAdd = true
            } label: {
                Label("Thêm thói quen", systemImage: "plus")
                    .font(.headline)
            }
            .authCTAStyle()
            .padding(.horizontal, 40)
            .padding(.top, 8)
        }
        .padding(32)
        .frame(maxWidth: .infinity)
    }

    /// Habit thuộc buổi `part`, sort giờ tăng dần ("HH:mm:ss" so chuỗi = so giờ).
    private func habits(in part: DayPart) -> [Habit] {
        vm.habits.filter { $0.dayPart == part }.sorted { $0.timeOfDay < $1.timeOfDay }
    }

    @ViewBuilder
    private func row(_ habit: Habit) -> some View {
        let status = vm.logsByHabit[habit.id]
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(habit.name).font(.subheadline.weight(.medium))
                Text("\(String(habit.timeOfDay.prefix(5))) · \(habit.durationMinutes) phút")
                    .font(.caption).foregroundStyle(Theme.onSurfaceVariant)
            }
            Spacer()
            Button {
                Task { await vm.mark(habit, .done) }
            } label: {
                Image(systemName: status == .done ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(status == .done ? Theme.done : Theme.onSurfaceVariant)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Đánh dấu hoàn thành")
            Button {
                Task { await vm.mark(habit, .missed) }
            } label: {
                Image(systemName: status == .missed ? "xmark.circle.fill" : "circle")
                    .foregroundStyle(status == .missed ? .red : Theme.onSurfaceVariant)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Đánh dấu bỏ lỡ")
        }
        .contentShape(Rectangle())
        .onTapGesture { editingHabit = habit }
    }
}

/// Card tóm tắt tiến độ hôm nay — port từ `habits_screen.dart` `_SummaryHeader`.
private struct SummaryHeader: View {
    let done: Int
    let total: Int

    private var progress: Double { total == 0 ? 0 : Double(done) / Double(total) }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Thói quen hôm nay")
                    .font(.headline)
                    .foregroundStyle(Theme.onPrimaryContainer)
                Text("Đã hoàn thành \(done)/\(total)")
                    .font(.subheadline)
                    .foregroundStyle(Theme.onPrimaryContainer)
            }
            Spacer()
            ZStack {
                Circle().stroke(Theme.onPrimaryContainer.opacity(0.15), lineWidth: 5)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Theme.onPrimaryContainer, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(Int((progress * 100).rounded()))%")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Theme.onPrimaryContainer)
            }
            .frame(width: 52, height: 52)
        }
        .padding(20)
        .background(Theme.primaryContainer, in: RoundedRectangle(cornerRadius: Theme.radiusCard))
    }
}
