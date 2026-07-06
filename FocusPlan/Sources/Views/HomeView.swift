import SwiftUI

struct HomeView: View {
    @ObservedObject var auth: AuthViewModel
    let email: String

    @State private var showAlarmForm = false
    @State private var taskCount = 0

    private let labels = ["CN", "T2", "T3", "T4", "T5", "T6", "T7"]

    private var weekDays: [Date] {
        let cal = Calendar.current
        let today = Date()
        let weekdayIndex = cal.component(.weekday, from: today) - 1 // 0=CN
        return (0..<7).map { i in
            cal.date(byAdding: .day, value: i - weekdayIndex, to: today) ?? today
        }
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        // 1 Text node (concat) để giữ nguyên hành vi UITest cũ (AuthFlowUITests
                        // định vị bằng predicate `label BEGINSWITH "Xin chào,"` trên staticText đơn).
                        (Text("Xin chào,\n").font(.subheadline).foregroundColor(Theme.onSurfaceVariant)
                            + Text(email).font(.title2.weight(.bold)))
                            .lineLimit(2)
                            .truncationMode(.tail)
                            .accessibilityIdentifier(A11yID.Home.greetingText)
                        SpeechBubble("Hôm nay mình cùng tập trung nhé!")
                    }
                    Spacer()
                    MascotView(size: 64)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(weekDays, id: \.self) { day in
                            dayChip(day)
                        }
                    }
                }

                HStack(alignment: .lastTextBaseline, spacing: 8) {
                    Text("Lịch hôm nay").font(.title3.weight(.semibold))
                    Text("\(taskCount) việc")
                        .font(.caption)
                        .foregroundStyle(Theme.onSurfaceVariant)
                }

                TaskListView(onCountChange: { taskCount = $0 })
            }
            .padding(16)
            .navigationTitle("Today")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showAlarmForm = true
                    } label: {
                        Image(systemName: "alarm")
                    }
                    .accessibilityLabel("Tạo báo thức")
                    .accessibilityIdentifier(A11yID.Home.alarmButton)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await auth.signOut() }
                    } label: {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                    }
                    .accessibilityLabel("Đăng xuất")
                    .accessibilityIdentifier(A11yID.Home.signOutButton)
                }
            }
            .sheet(isPresented: $showAlarmForm) { AlarmFormView() }
        }
    }

    @ViewBuilder
    private func dayChip(_ day: Date) -> some View {
        let cal = Calendar.current
        let isToday = cal.isDateInToday(day)
        let weekdayIndex = cal.component(.weekday, from: day) - 1
        VStack(spacing: 4) {
            Text(labels[weekdayIndex]).font(.caption)
                .foregroundStyle(isToday ? Color.white : Theme.onSurfaceVariant)
            Text("\(cal.component(.day, from: day))").bold()
                .foregroundStyle(isToday ? Color.white : Color.primary)
        }
        .frame(width: 48, height: 64)
        .background(isToday ? Theme.primary : Theme.surfaceVariant,
                    in: RoundedRectangle(cornerRadius: Theme.radiusChip))
    }
}

/// Bong bóng thoại nhỏ cạnh lời chào — port từ `home_screen.dart` `_SpeechBubble`.
private struct SpeechBubble: View {
    let text: String

    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(Theme.onPrimaryContainer)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Theme.secondaryContainer, in: RoundedRectangle(cornerRadius: 14))
    }
}
