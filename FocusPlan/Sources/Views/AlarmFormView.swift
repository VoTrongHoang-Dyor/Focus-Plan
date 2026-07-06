import SwiftUI

/// Màn tạo báo thức theo template "Smart Alarm" (assets/4.jpg).
/// Vibrate / System volume max: persist-only (iOS không có public API per-notification)
/// → caption "Theo cài đặt hệ thống". Xem plan 2026-07-06-alarm-form-view.
struct AlarmFormView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var time: Date
    @State private var repeatDays: Set<Int>
    @State private var loopAudio: Bool
    @State private var vibrate: Bool
    @State private var systemVolumeMax: Bool
    @State private var showNotification: Bool
    @State private var showTimePicker = false

    private let store: UserAlarmStore
    // Hiển thị bắt đầu Thứ 2; giá trị = weekday chuẩn Calendar.
    private let days: [(weekday: Int, label: String)] = [
        (2, "T2"), (3, "T3"), (4, "T4"), (5, "T5"), (6, "T6"), (7, "T7"), (1, "CN")
    ]

    init(store: UserAlarmStore = UserAlarmStore()) {
        self.store = store
        let cal = Calendar.current
        let now = Date()
        // prefill = bằng chứng persist; không có alarm lưu → default = giờ hiện tại + UserAlarm defaults.
        let alarm = store.latest ?? UserAlarm(hour: cal.component(.hour, from: now),
                                              minute: cal.component(.minute, from: now))
        _time = State(initialValue: cal.date(bySettingHour: alarm.hour, minute: alarm.minute,
                                             second: 0, of: now) ?? now)
        _repeatDays = State(initialValue: alarm.repeatDays)
        _loopAudio = State(initialValue: alarm.loopAudio)
        _vibrate = State(initialValue: alarm.vibrate)
        _systemVolumeMax = State(initialValue: alarm.systemVolumeMax)
        _showNotification = State(initialValue: alarm.showNotification)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 8) {
                        MascotView(size: 120)
                        Text("Cùng dậy đúng giờ nào!")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Theme.onSurfaceVariant)
                            .accessibilityHidden(true)
                    }
                    timeCard
                    repeatSection
                    settingsSection
                    createButton
                    Text("You can do it")
                        .font(.subheadline)
                        .foregroundStyle(Theme.onSurfaceVariant)
                        .accessibilityIdentifier(A11yID.AlarmForm.hintText)
                }
                .padding(16)
            }
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Đóng") { dismiss() }
                        .accessibilityIdentifier(A11yID.AlarmForm.cancelButton)
                }
            }
        }
    }

    // MARK: - Sections

    private var timeCard: some View {
        VStack(spacing: 8) {
            Button {
                withAnimation { showTimePicker.toggle() }
            } label: {
                Text(time.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.primary)
            }
            .accessibilityIdentifier(A11yID.AlarmForm.timeText)
            .accessibilityLabel("Chọn giờ báo thức")

            if showTimePicker {
                DatePicker("Giờ báo thức", selection: $time, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .accessibilityIdentifier(A11yID.AlarmForm.timePicker)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: Theme.radiusCard))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }

    private var repeatSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Lặp lại").font(.headline)
            HStack(spacing: 8) {
                ForEach(days, id: \.weekday) { day in
                    dayChip(day.weekday, day.label)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func dayChip(_ weekday: Int, _ label: String) -> some View {
        let isOn = repeatDays.contains(weekday)
        return Button {
            if isOn { repeatDays.remove(weekday) } else { repeatDays.insert(weekday) }
        } label: {
            Text(label)
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(isOn ? Theme.primary : Theme.surfaceVariant,
                            in: RoundedRectangle(cornerRadius: Theme.radiusChip))
                .foregroundStyle(isOn ? Color.white : Color.primary)
        }
        .accessibilityIdentifier(A11yID.AlarmForm.dayToggle(weekday))
        .accessibilityLabel("Lặp lại \(label)")
        .accessibilityAddTraits(isOn ? [.isSelected] : [])
    }

    private var settingsSection: some View {
        VStack(spacing: 10) {
            settingRow("Loop alarm audio", isOn: $loopAudio,
                       id: A11yID.AlarmForm.loopAudioToggle)
            settingRow("Vibrate", caption: "Theo cài đặt hệ thống", isOn: $vibrate,
                       id: A11yID.AlarmForm.vibrateToggle)
            settingRow("System volume max", caption: "Theo cài đặt hệ thống", isOn: $systemVolumeMax,
                       id: A11yID.AlarmForm.volumeMaxToggle)
            settingRow("Show notification", isOn: $showNotification,
                       id: A11yID.AlarmForm.showNotificationToggle)
        }
    }

    private func settingRow(_ title: String, caption: String? = nil,
                            isOn: Binding<Bool>, id: String) -> some View {
        Toggle(isOn: isOn) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).foregroundStyle(Color.white)
                if let caption {
                    Text(caption).font(.caption).foregroundStyle(Color.white.opacity(0.6))
                }
            }
        }
        .tint(Theme.primary)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(hex: 0x111827), in: RoundedRectangle(cornerRadius: Theme.radiusChip))
        .accessibilityIdentifier(id)
    }

    private var createButton: some View {
        Button {
            createAlarm()
        } label: {
            Text("Create Alarm")
                .font(.headline)
                .frame(maxWidth: .infinity, minHeight: Theme.ctaHeight)
                .background(Theme.primary, in: RoundedRectangle(cornerRadius: Theme.radiusInput))
                .foregroundStyle(Color.white)
        }
        .accessibilityIdentifier(A11yID.AlarmForm.createButton)
    }

    // MARK: - Actions

    private func createAlarm() {
        let cal = Calendar.current
        let alarm = UserAlarm(hour: cal.component(.hour, from: time),
                              minute: cal.component(.minute, from: time),
                              repeatDays: repeatDays,
                              loopAudio: loopAudio, vibrate: vibrate,
                              systemVolumeMax: systemVolumeMax,
                              showNotification: showNotification)
        store.append(alarm)
        dismiss()
        Task { await TodayScheduleService.shared.refreshAndArm() }  // arm thật (Task 4)
    }
}
