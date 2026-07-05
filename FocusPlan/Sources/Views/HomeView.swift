import SwiftUI

struct HomeView: View {
    @ObservedObject var auth: AuthViewModel
    let email: String

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
                Text("Xin chào, \(email)").font(.headline)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .accessibilityIdentifier(A11yID.Home.greetingText)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(weekDays, id: \.self) { day in
                            dayChip(day)
                        }
                    }
                }

                TaskListView()
            }
            .padding(16)
            .navigationTitle("Today")
            .toolbar {
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
        }
    }

    @ViewBuilder
    private func dayChip(_ day: Date) -> some View {
        let cal = Calendar.current
        let isToday = cal.isDateInToday(day)
        let weekdayIndex = cal.component(.weekday, from: day) - 1
        VStack(spacing: 4) {
            Text(labels[weekdayIndex]).font(.caption)
            Text("\(cal.component(.day, from: day))").bold()
        }
        .frame(width: 48, height: 64)
        .background(isToday ? Color.accentColor : Color(.secondarySystemBackground),
                    in: RoundedRectangle(cornerRadius: 16))
        .foregroundStyle(isToday ? Color.white : Color.primary)
    }
}
