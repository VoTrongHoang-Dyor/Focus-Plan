import 'package:flutter/material.dart';

/// Loại block trong lịch: task thường hoặc busy-block từ Habit tracking.
enum BlockKind { task, habit }

/// Mức ưu tiên của task (habit không có priority).
enum TaskPriority { high, medium, low }

/// Màu semantic cho từng mức priority + habit.
///
/// Đây là functional color (báo mức khẩn) nên tách khỏi seed indigo của theme;
/// luôn đi kèm icon + nhãn text để không vi phạm quy tắc "color-not-only".
class ScheduleColors {
  const ScheduleColors._();

  static const Color high = Color(0xFFE11D48); // rose 600
  static const Color medium = Color(0xFFF59E0B); // amber 500
  static const Color low = Color(0xFF10B981); // emerald 500
  static const Color habit = Color(0xFF64748B); // slate 500 — màu trầm
}

extension TaskPriorityView on TaskPriority {
  Color get color => switch (this) {
    TaskPriority.high => ScheduleColors.high,
    TaskPriority.medium => ScheduleColors.medium,
    TaskPriority.low => ScheduleColors.low,
  };

  String get label => switch (this) {
    TaskPriority.high => 'Ưu tiên cao',
    TaskPriority.medium => 'Ưu tiên vừa',
    TaskPriority.low => 'Ưu tiên thấp',
  };

  IconData get icon => switch (this) {
    TaskPriority.high => Icons.keyboard_double_arrow_up_rounded,
    TaskPriority.medium => Icons.drag_handle_rounded,
    TaskPriority.low => Icons.keyboard_arrow_down_rounded,
  };
}

@immutable
class ScheduleBlock {
  /// Phút tính từ nửa đêm — dùng để tính buffer giữa các block.
  final int startMinutes;
  final int endMinutes;
  final String title;
  final BlockKind kind;

  /// Chỉ có với [BlockKind.task]; habit để `null`.
  final TaskPriority? priority;

  /// Nhãn energy-matching, ví dụ "Deep work · Sáng".
  final String energyTag;
  final IconData icon;

  const ScheduleBlock({
    required this.startMinutes,
    required this.endMinutes,
    required this.title,
    required this.kind,
    required this.energyTag,
    required this.icon,
    this.priority,
  });

  bool get isHabit => kind == BlockKind.habit;

  /// Màu điểm nhấn: theo priority với task, màu trầm với habit.
  Color get accentColor =>
      isHabit ? ScheduleColors.habit : priority!.color;

  String get startLabel => _formatMinutes(startMinutes);
  String get endLabel => _formatMinutes(endMinutes);

  static String _formatMinutes(int minutes) {
    final h = (minutes ~/ 60).toString().padLeft(2, '0');
    final m = (minutes % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }
}

int _hm(int h, int m) => h * 60 + m;

/// Lịch mock 1 ngày làm việc — output giả lập của Deterministic Scheduling
/// Engine v1: task xếp theo giờ, ưu tiên cao + deep work vào buổi sáng,
/// habit busy-block cố định xen kẽ, có buffer nghỉ giữa các block.
final List<ScheduleBlock> mockSchedule = [
  ScheduleBlock(
    startMinutes: _hm(6, 30),
    endMinutes: _hm(6, 50),
    title: 'Thiền buổi sáng',
    kind: BlockKind.habit,
    energyTag: 'Khởi động · Sáng',
    icon: Icons.self_improvement_rounded,
  ),
  ScheduleBlock(
    startMinutes: _hm(7, 15),
    endMinutes: _hm(9, 15),
    title: 'Viết tài liệu kiến trúc',
    kind: BlockKind.task,
    priority: TaskPriority.high,
    energyTag: 'Deep work · Sáng',
    icon: Icons.architecture_rounded,
  ),
  ScheduleBlock(
    startMinutes: _hm(9, 30),
    endMinutes: _hm(10, 15),
    title: 'Review PR & trả lời email',
    kind: BlockKind.task,
    priority: TaskPriority.medium,
    energyTag: 'Tập trung nhẹ · Sáng',
    icon: Icons.mark_email_read_rounded,
  ),
  ScheduleBlock(
    startMinutes: _hm(12, 0),
    endMinutes: _hm(13, 0),
    title: 'Tập gym',
    kind: BlockKind.habit,
    energyTag: 'Vận động · Trưa',
    icon: Icons.fitness_center_rounded,
  ),
  ScheduleBlock(
    startMinutes: _hm(13, 30),
    endMinutes: _hm(14, 30),
    title: 'Họp nhóm tuần',
    kind: BlockKind.task,
    priority: TaskPriority.medium,
    energyTag: 'Phối hợp · Trưa',
    icon: Icons.groups_rounded,
  ),
  ScheduleBlock(
    startMinutes: _hm(15, 0),
    endMinutes: _hm(16, 30),
    title: 'Cải thiện scheduling engine',
    kind: BlockKind.task,
    priority: TaskPriority.high,
    energyTag: 'Deep work · Chiều',
    icon: Icons.tune_rounded,
  ),
  ScheduleBlock(
    startMinutes: _hm(16, 45),
    endMinutes: _hm(17, 15),
    title: 'Dọn inbox & lên kế hoạch mai',
    kind: BlockKind.task,
    priority: TaskPriority.low,
    energyTag: 'Việc nhẹ · Chiều',
    icon: Icons.checklist_rounded,
  ),
  ScheduleBlock(
    startMinutes: _hm(21, 0),
    endMinutes: _hm(21, 30),
    title: 'Đọc sách',
    kind: BlockKind.habit,
    energyTag: 'Thư giãn · Tối',
    icon: Icons.menu_book_rounded,
  ),
];
