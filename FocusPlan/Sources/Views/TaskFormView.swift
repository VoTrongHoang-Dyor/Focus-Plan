import SwiftUI

struct TaskFormView: View {
    enum Mode {
        case create(ParsedTaskDraft)
        case edit(TaskItem)
    }

    let mode: Mode
    var onSaved: () -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var minutesText = ""
    @State private var priority: TaskPriority = .medium
    @State private var hasDeadline = false
    @State private var deadline = Date()
    @State private var note: String?
    @State private var isSaving = false
    @State private var errorMessage: String?

    private let repo = TaskRepository()

    var body: some View {
        NavigationStack {
            Form {
                if let note, !note.isEmpty {
                    Section { Text(note).font(.footnote).foregroundStyle(.orange) }
                }
                Section("Tên task") { TextField("Tên", text: $name) }
                Section("Thời lượng (phút)") {
                    TextField("vd 30", text: $minutesText).keyboardType(.numberPad)
                }
                Section("Độ ưu tiên") {
                    Picker("Độ ưu tiên", selection: $priority) {
                        ForEach(TaskPriority.allCases) { p in Text(p.label).tag(p) }
                    }.pickerStyle(.segmented)
                }
                Section {
                    Toggle("Có deadline", isOn: $hasDeadline)
                    if hasDeadline {
                        DatePicker("Deadline", selection: $deadline)
                    }
                }
                if let errorMessage { Text(errorMessage).foregroundStyle(.red).font(.footnote) }
            }
            .navigationTitle(isEditing ? "Sửa task" : "Xác nhận task")
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
        switch mode {
        case .create(let d):
            name = d.name
            minutesText = d.estimatedMinutes.map(String.init) ?? ""
            priority = d.priority
            note = d.note
            if let dd = d.deadlineDate { hasDeadline = true; deadline = dd }
        case .edit(let t):
            name = t.name
            minutesText = t.estimatedMinutes.map(String.init) ?? ""
            priority = t.priority
            if let dd = t.deadline { hasDeadline = true; deadline = dd }
        }
    }

    private func save() async {
        isSaving = true; errorMessage = nil
        let minutes = Int(minutesText.trimmingCharacters(in: .whitespaces))
        let dl = hasDeadline ? deadline : nil
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        do {
            switch mode {
            case .create:
                _ = try await repo.create(NewTask(name: trimmedName, estimatedMinutes: minutes, priority: priority, deadline: dl))
            case .edit(let t):
                _ = try await repo.update(id: t.id, TaskUpdate(name: trimmedName, estimatedMinutes: minutes, priority: priority, deadline: dl))
            }
            onSaved(); dismiss()
        } catch { errorMessage = error.localizedDescription }
        isSaving = false
    }
}
