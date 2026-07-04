import 'package:flutter/material.dart';

/// Mức độ "chất lượng ngày" suy ra khách quan từ tỉ lệ hoàn thành task.
enum ReflectionLevel { good, medium, low }

extension ReflectionLevelView on ReflectionLevel {
  Color get color => switch (this) {
    ReflectionLevel.good => const Color(0xFF059669), // emerald 600
    ReflectionLevel.medium => const Color(0xFFF59E0B), // amber 500
    ReflectionLevel.low => const Color(0xFFE11D48), // rose 600
  };

  String get label => switch (this) {
    ReflectionLevel.good => 'Ngày hiệu quả',
    ReflectionLevel.medium => 'Ngày ổn',
    ReflectionLevel.low => 'Ngày chậm',
  };
}

/// Bản tóm tắt cuối ngày (mock, UI-only) — không backend/Gemini thật.
@immutable
class DailyReflection {
  final int tasksDone;
  final int tasksTotal;
  final int pomodoroSessions;
  final int focusMinutes;
  final String note;

  const DailyReflection({
    required this.tasksDone,
    required this.tasksTotal,
    required this.pomodoroSessions,
    required this.focusMinutes,
    required this.note,
  });

  double get completion => tasksTotal == 0 ? 0 : tasksDone / tasksTotal;

  ReflectionLevel get level {
    if (completion >= 0.7) return ReflectionLevel.good;
    if (completion >= 0.4) return ReflectionLevel.medium;
    return ReflectionLevel.low;
  }

  /// Dòng tóm tắt khách quan hiển thị trong chi tiết ngày.
  String get summaryLine =>
      '$tasksDone/$tasksTotal task hoàn thành · $pomodoroSessions phiên Pomodoro · $focusMinutes phút tập trung';
}

/// Dữ liệu reflection mock, key = ngày trong tháng (1..31).
///
/// Chỉ seed cho tháng hiện tại để minh hoạ; các tháng khác không có dữ liệu.
const Map<int, DailyReflection> mockReflections = {
  1: DailyReflection(
    tasksDone: 5,
    tasksTotal: 6,
    pomodoroSessions: 3,
    focusMinutes: 92,
    note: 'Buổi sáng deep work rất tập trung, hoàn thành gần hết việc quan trọng.',
  ),
  2: DailyReflection(
    tasksDone: 3,
    tasksTotal: 7,
    pomodoroSessions: 2,
    focusMinutes: 54,
    note: 'Nhiều họp xen ngang nên khó vào guồng, dời bớt việc sang mai.',
  ),
  3: DailyReflection(
    tasksDone: 6,
    tasksTotal: 6,
    pomodoroSessions: 4,
    focusMinutes: 110,
    note: 'Ngày trọn vẹn — giữ được nhịp Pomodoro đều và nghỉ đúng lúc.',
  ),
  4: DailyReflection(
    tasksDone: 4,
    tasksTotal: 6,
    pomodoroSessions: 3,
    focusMinutes: 78,
    note: 'Ổn định, nhưng buổi chiều hơi phân tán vì thông báo điện thoại.',
  ),
  5: DailyReflection(
    tasksDone: 1,
    tasksTotal: 5,
    pomodoroSessions: 1,
    focusMinutes: 25,
    note: 'Ngày nghỉ ngơi, chủ động làm ít để hồi sức.',
  ),
  8: DailyReflection(
    tasksDone: 5,
    tasksTotal: 6,
    pomodoroSessions: 3,
    focusMinutes: 88,
    note: 'Bắt đầu tuần tốt, ưu tiên đúng việc quan trọng từ sáng.',
  ),
  9: DailyReflection(
    tasksDone: 2,
    tasksTotal: 6,
    pomodoroSessions: 2,
    focusMinutes: 47,
    note: 'Bị cuốn vào việc gấp ngoài kế hoạch, cần đặt ranh giới rõ hơn.',
  ),
  10: DailyReflection(
    tasksDone: 6,
    tasksTotal: 7,
    pomodoroSessions: 4,
    focusMinutes: 105,
    note: 'Tập trung sâu buổi sáng, xử lý gọn phần khó nhất trong tuần.',
  ),
  11: DailyReflection(
    tasksDone: 4,
    tasksTotal: 6,
    pomodoroSessions: 3,
    focusMinutes: 72,
    note: 'Cân bằng giữa việc và nghỉ, giữ được năng lượng đến cuối ngày.',
  ),
};
