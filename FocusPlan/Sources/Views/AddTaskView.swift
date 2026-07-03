import SwiftUI

struct AddTaskView: View {
    var onSaved: () -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var text = ""
    @State private var isParsing = false
    @State private var errorMessage: String?
    @State private var draft: ParsedTaskDraft?

    private let parser = TaskParseService()

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Nhập task bằng câu tự nhiên").font(.headline)
                TextField("vd: Học tiếng Trung 30 phút tối nay", text: $text, axis: .vertical)
                    .textFieldStyle(.roundedBorder).lineLimit(2...4)
                if let errorMessage { Text(errorMessage).foregroundStyle(.red).font(.footnote) }
                Button {
                    Task { await parse() }
                } label: {
                    if isParsing { ProgressView().frame(maxWidth: .infinity) }
                    else { Text("Phân tích").frame(maxWidth: .infinity) }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isParsing || text.trimmingCharacters(in: .whitespaces).isEmpty)
                Spacer()
            }
            .padding(24)
            .navigationTitle("Thêm task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Huỷ") { dismiss() } }
            }
            .sheet(item: $draft) { d in
                // Luôn qua màn confirm trước khi lưu (acceptance criteria 3).
                TaskFormView(mode: .create(d), onSaved: {
                    onSaved(); dismiss()
                })
            }
        }
    }

    private func parse() async {
        isParsing = true; errorMessage = nil
        do { draft = try await parser.parse(text.trimmingCharacters(in: .whitespaces)) }
        catch { errorMessage = "Không phân tích được: \(error.localizedDescription)" }
        isParsing = false
    }
}
