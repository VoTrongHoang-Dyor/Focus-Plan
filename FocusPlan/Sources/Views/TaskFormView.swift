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
    @State private var taskType: TaskType = .shallow
    @State private var hasDeadline = false
    @State private var deadline = Date()
    @State private var note: String?
    @State private var isSaving = false
    @State private var errorMessage: String?

    private let repo = TaskRepository()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let note, !note.isEmpty {
                        Text(note).font(.footnote).foregroundStyle(.orange)
                            .accessibilityIdentifier(A11yID.TaskForm.noteText)
                    }

                    fieldLabel("Tên task")
                    TextField("Tên", text: $name)
                        .filledFieldStyle()
                        .accessibilityIdentifier(A11yID.TaskForm.nameField)

                    fieldLabel("Thời lượng (phút)")
                    TextField("vd 30", text: $minutesText).keyboardType(.numberPad)
                        .filledFieldStyle()
                        .accessibilityIdentifier(A11yID.TaskForm.minutesField)

                    fieldLabel("Độ ưu tiên")
                    Picker("Độ ưu tiên", selection: $priority) {
                        ForEach(TaskPriority.allCases) { p in Text(p.label).tag(p) }
                    }
                    .pickerStyle(.segmented)
                    .padding(8)
                    .background(Theme.surfaceVariant, in: RoundedRectangle(cornerRadius: Theme.radiusInput))
                    .accessibilityIdentifier(A11yID.TaskForm.priorityPicker)

                    fieldLabel("Loại việc")
                    Picker("Loại việc", selection: $taskType) {
                        ForEach(TaskType.allCases) { t in Text(t.label).tag(t) }
                    }
                    .pickerStyle(.segmented)
                    .padding(8)
                    .background(Theme.surfaceVariant, in: RoundedRectangle(cornerRadius: Theme.radiusInput))
                    .accessibilityIdentifier(A11yID.TaskForm.taskTypePicker)

                    Toggle("Có deadline", isOn: $hasDeadline)
                        .filledFieldStyle()
                        .accessibilityIdentifier(A11yID.TaskForm.deadlineToggle)
                    if hasDeadline {
                        DatePicker("Deadline", selection: $deadline)
                            .filledFieldStyle()
                            .accessibilityIdentifier(A11yID.TaskForm.deadlinePicker)
                    }

                    if let errorMessage { Text(errorMessage).foregroundStyle(.red).font(.footnote)
                        .accessibilityIdentifier(A11yID.TaskForm.errorText) }

                    Button {
                        Task { await save() }
                    } label: {
                        if isSaving { ProgressView().tint(.white).frame(maxWidth: .infinity) }
                        else { Text(isEditing ? "Lưu" : "Tạo").font(.headline).frame(maxWidth: .infinity) }
                    }
                    .authCTAStyle()
                    .disabled(isSaving || name.trimmingCharacters(in: .whitespaces).isEmpty)
                    .accessibilityIdentifier(A11yID.TaskForm.saveButton)
                    .padding(.top, 8)
                }
                .padding(24)
            }
            .navigationTitle(isEditing ? "Sửa task" : "Xác nhận task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Huỷ") { dismiss() }
                        .accessibilityIdentifier(A11yID.TaskForm.cancelButton)
                }
            }
            .onAppear(perform: prefill)
        }
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text).font(.caption).foregroundStyle(Theme.onSurfaceVariant)
    }

    private var isEditing: Bool { if case .edit = mode { return true }; return false }

    private func prefill() {
        switch mode {
        case .create(let d):
            name = d.name
            minutesText = d.estimatedMinutes.map(String.init) ?? ""
            priority = d.priority
            taskType = d.taskType
            note = d.note
            if let dd = d.deadlineDate { hasDeadline = true; deadline = dd }
        case .edit(let t):
            name = t.name
            minutesText = t.estimatedMinutes.map(String.init) ?? ""
            priority = t.priority
            taskType = t.taskType
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
                _ = try await repo.create(NewTask(name: trimmedName, estimatedMinutes: minutes, priority: priority, deadline: dl, taskType: taskType))
            case .edit(let t):
                _ = try await repo.update(id: t.id, TaskUpdate(name: trimmedName, estimatedMinutes: minutes, priority: priority, deadline: dl, taskType: taskType))
            }
            onSaved(); dismiss()
        } catch { errorMessage = error.localizedDescription }
        isSaving = false
    }
}
