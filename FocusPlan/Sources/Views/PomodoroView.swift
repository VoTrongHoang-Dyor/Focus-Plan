import SwiftUI

struct PomodoroView: View {
    @StateObject private var vm = PomodoroViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                ZStack {
                    Circle().stroke(Theme.primaryContainer, lineWidth: 10)
                    Circle()
                        .trim(from: 0, to: vm.progress)
                        .stroke(Theme.primary, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.25), value: vm.progress)
                    Text(vm.remainingText)
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .accessibilityIdentifier(A11yID.Pomodoro.timeText)
                }
                .frame(width: 220, height: 220)

                controls
            }
            .padding(24)
            .navigationTitle("Tập trung")
            // TimelineView không tiện gọi hàm VM → dùng task lặp 1s khi view sống.
            .task {
                while !Task.isCancelled {
                    vm.onTick()
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                }
            }
            .alert("Lỗi", isPresented: .constant(vm.errorMessage != nil)) {
                Button("OK") { vm.errorMessage = nil }
            } message: { Text(vm.errorMessage ?? "") }
        }
    }

    @ViewBuilder
    private var controls: some View {
        switch vm.state {
        case .idle:
            Button { vm.start() } label: {
                Label("Bắt đầu", systemImage: "play.fill").font(.headline).frame(maxWidth: .infinity)
            }
            .authCTAStyle()
            .accessibilityIdentifier(A11yID.Pomodoro.startButton)
        case .running:
            HStack(spacing: 12) {
                Button { vm.pause() } label: {
                    Label("Tạm dừng", systemImage: "pause.fill").font(.headline).frame(maxWidth: .infinity)
                }
                .authCTAStyle()
                .accessibilityIdentifier(A11yID.Pomodoro.pauseButton)
                stopButton
            }
        case .paused:
            HStack(spacing: 12) {
                Button { vm.resume() } label: {
                    Label("Tiếp tục", systemImage: "play.fill").font(.headline).frame(maxWidth: .infinity)
                }
                .authCTAStyle()
                .accessibilityIdentifier(A11yID.Pomodoro.resumeButton)
                stopButton
            }
        }
    }

    private var stopButton: some View {
        Button(role: .destructive) { vm.stop() } label: {
            Label("Kết thúc", systemImage: "stop.fill").font(.headline).frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, minHeight: Theme.ctaHeight)
        .background(Theme.surfaceVariant, in: RoundedRectangle(cornerRadius: Theme.radiusInput))
        .foregroundStyle(.red)
        .accessibilityIdentifier(A11yID.Pomodoro.stopButton)
    }
}
