/// Một bậc level theo tổng số phiên Pomodoro tích luỹ.
class PomodoroLevel {
  final int level; // 1..6
  final String name;
  final int threshold; // số Pomodoro tối thiểu để đạt level này

  const PomodoroLevel(this.level, this.name, this.threshold);
}

/// 6 bậc level cố định (ngưỡng Pomodoro tích luỹ).
const List<PomodoroLevel> pomodoroLevels = [
  PomodoroLevel(1, 'Tân binh', 0),
  PomodoroLevel(2, 'Chăm chỉ', 25),
  PomodoroLevel(3, 'Kỷ luật', 75),
  PomodoroLevel(4, 'Tập trung', 150),
  PomodoroLevel(5, 'Bậc thầy', 300),
  PomodoroLevel(6, 'Huyền thoại', 500),
];

/// Số liệu gamification (mock, UI-only) — không tính streak/level thật.
class GamificationStats {
  final int currentStreak;
  final int bestStreak;

  /// Cờ mock: hôm nay chưa hoàn thành task nào → nguy cơ mất chuỗi.
  final bool streakAtRisk;

  final int pomodoroTotal;

  const GamificationStats({
    required this.currentStreak,
    required this.bestStreak,
    required this.streakAtRisk,
    required this.pomodoroTotal,
  });

  int get _currentLevelIndex {
    var idx = 0;
    for (var i = 0; i < pomodoroLevels.length; i++) {
      if (pomodoroTotal >= pomodoroLevels[i].threshold) idx = i;
    }
    return idx;
  }

  PomodoroLevel get currentLevel => pomodoroLevels[_currentLevelIndex];

  PomodoroLevel? get nextLevel {
    final next = _currentLevelIndex + 1;
    return next < pomodoroLevels.length ? pomodoroLevels[next] : null;
  }

  bool get isMaxLevel => nextLevel == null;

  /// Tiến trình 0..1 từ ngưỡng level hiện tại tới level kế.
  double get levelProgress {
    final next = nextLevel;
    if (next == null) return 1;
    final base = currentLevel.threshold;
    return (pomodoroTotal - base) / (next.threshold - base);
  }

  /// Số Pomodoro còn thiếu để lên level kế; null nếu đã max.
  int? get pomodoroToNext =>
      nextLevel == null ? null : nextLevel!.threshold - pomodoroTotal;
}

/// Số liệu mock để minh hoạ (đang ở trạng thái nguy cơ mất chuỗi).
const GamificationStats mockStats = GamificationStats(
  currentStreak: 12,
  bestStreak: 21,
  streakAtRisk: true,
  pomodoroTotal: 182,
);
