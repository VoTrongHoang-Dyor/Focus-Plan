import SwiftUI

struct HabitFormView: View {
    enum Mode { case create; case edit(Habit) }
    let mode: Mode
    var onSaved: () -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var time = Date()
    @State private var durationText = "30"
    @State private var isSaving = false
    @State private var errorMessage: String?

    private let repo = HabitRepository()

    var body: some View {
        NavigationStack {
            Form {
                Section("Tên thói quen") { TextField("vd Thiền", text: $name) }
                    .listRowBackground(Theme.surfaceVariant)
                Section("Giờ cố định") {
                    DatePicker("Giờ", selection: $time, displayedComponents: .hourAndMinute)
                }
                Section("Thời lượng (phút)") {
                    TextField("30", text: $durationText).keyboardType(.numberPad)
                }
                .listRowBackground(Theme.surfaceVariant)
                if let errorMessage { Text(errorMessage).foregroundStyle(.red).font(.footnote) }
            }
            .tint(Theme.primary)
            .navigationTitle(isEditing ? "Sửa thói quen" : "Thói quen mới")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Huỷ") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Lưu" : "Tạo") { Task { await save() } }
                        .disabled(isSaving || name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear(perform: prefill)
        }
    }

    private var isEditing: Bool { if case .edit = mode { return true }; return false }

    private func prefill() {
        if case .edit(let h) = mode {
            name = h.name
            durationText = String(h.durationMinutes)
            if let (hh, mm) = h.timeComponents,
               let d = Calendar.current.date(bySettingHour: hh, minute: mm, second: 0, of: Date()) {
                time = d
            }
        }
    }

    private func timeString() -> String {
        let c = Calendar.current.dateComponents([.hour, .minute], from: time)
        return String(format: "%02d:%02d", c.hour ?? 0, c.minute ?? 0)
    }

    private func save() async {
        isSaving = true; errorMessage = nil
        let duration = Int(durationText.trimmingCharacters(in: .whitespaces)) ?? 30
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        do {
            switch mode {
            case .create:
                _ = try await repo.createHabit(NewHabit(name: trimmedName, timeOfDay: timeString(), durationMinutes: duration))
            case .edit(let h):
                _ = try await repo.updateHabit(id: h.id, HabitUpdate(name: trimmedName, timeOfDay: timeString(), durationMinutes: duration))
            }
            onSaved(); dismiss()
        } catch { errorMessage = error.localizedDescription }
        isSaving = false
    }
}
