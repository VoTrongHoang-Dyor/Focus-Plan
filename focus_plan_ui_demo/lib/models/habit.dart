import 'package:flutter/material.dart';

/// Trạng thái của habit trong ngày hôm nay.
enum HabitStatus { pending, done, missed }

extension HabitStatusView on HabitStatus {
  String get label => switch (this) {
    HabitStatus.pending => 'Chưa làm',
    HabitStatus.done => 'Hoàn thành',
    HabitStatus.missed => 'Bỏ lỡ',
  };

  IconData get icon => switch (this) {
    HabitStatus.pending => Icons.circle_outlined,
    HabitStatus.done => Icons.check_circle_rounded,
    HabitStatus.missed => Icons.cancel_rounded,
  };

  /// Nhấn để xoay vòng: chưa làm → hoàn thành → bỏ lỡ → chưa làm.
  HabitStatus get next => switch (this) {
    HabitStatus.pending => HabitStatus.done,
    HabitStatus.done => HabitStatus.missed,
    HabitStatus.missed => HabitStatus.pending,
  };
}

/// Buổi trong ngày — dùng để nhóm habit theo phong cách routine (Sáng/Chiều/Tối).
enum DayPart { morning, afternoon, evening }

extension DayPartView on DayPart {
  String get label => switch (this) {
    DayPart.morning => 'Buổi sáng',
    DayPart.afternoon => 'Buổi chiều',
    DayPart.evening => 'Buổi tối',
  };

  IconData get icon => switch (this) {
    DayPart.morning => Icons.wb_twilight_rounded,
    DayPart.afternoon => Icons.wb_sunny_rounded,
    DayPart.evening => Icons.nightlight_round,
  };

  static DayPart fromMinutes(int minutes) {
    if (minutes < 12 * 60) return DayPart.morning;
    if (minutes < 18 * 60) return DayPart.afternoon;
    return DayPart.evening;
  }
}

/// Habit lặp cố định hàng ngày (mock, UI-only).
///
/// Các trường có thể đổi được để chỉnh sửa trực tiếp trong `setState` — demo
/// không persist, không backend.
class Habit {
  final String id;
  String name;

  /// Giờ cố định trong ngày, tính bằng phút từ nửa đêm.
  int timeMinutes;
  HabitStatus todayStatus;

  Habit({
    required this.id,
    required this.name,
    required this.timeMinutes,
    this.todayStatus = HabitStatus.pending,
  });

  DayPart get dayPart => DayPartView.fromMinutes(timeMinutes);

  String get timeLabel {
    final h = (timeMinutes ~/ 60).toString().padLeft(2, '0');
    final m = (timeMinutes % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }
}

int _hm(int h, int m) => h * 60 + m;

/// Danh sách habit mock ban đầu.
List<Habit> seedHabits() => [
  Habit(id: 'h1', name: 'Thiền chánh niệm', timeMinutes: _hm(6, 30), todayStatus: HabitStatus.done),
  Habit(id: 'h2', name: 'Uống một cốc nước', timeMinutes: _hm(8, 0)),
  Habit(id: 'h3', name: 'Tập gym', timeMinutes: _hm(12, 0), todayStatus: HabitStatus.missed),
  Habit(id: 'h4', name: 'Đi bộ 15 phút', timeMinutes: _hm(17, 30)),
  Habit(id: 'h5', name: 'Đọc sách', timeMinutes: _hm(21, 0), todayStatus: HabitStatus.done),
];
