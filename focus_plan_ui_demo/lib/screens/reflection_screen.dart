import 'package:flutter/material.dart';

import '../models/daily_reflection.dart';
import '../widgets/brand.dart';

/// Màn Daily Reflection: xem lại tóm tắt cuối ngày dạng lịch tháng (UI mock).
class ReflectionScreen extends StatefulWidget {
  const ReflectionScreen({super.key});

  @override
  State<ReflectionScreen> createState() => _ReflectionScreenState();
}

class _ReflectionScreenState extends State<ReflectionScreen> {
  static const _weekdayLabels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
  static const _monthNames = [
    'Tháng 1', 'Tháng 2', 'Tháng 3', 'Tháng 4', 'Tháng 5', 'Tháng 6',
    'Tháng 7', 'Tháng 8', 'Tháng 9', 'Tháng 10', 'Tháng 11', 'Tháng 12',
  ];

  final DateTime _today = DateTime.now();
  late DateTime _visibleMonth = DateTime(_today.year, _today.month);

  void _changeMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    });
  }

  bool get _isCurrentMonth =>
      _visibleMonth.year == _today.year && _visibleMonth.month == _today.month;

  DailyReflection? _reflectionFor(int day) =>
      _isCurrentMonth ? mockReflections[day] : null;

  void _openDay(int day, DailyReflection? reflection) {
    final date = DateTime(_visibleMonth.year, _visibleMonth.month, day);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => reflection == null
          ? _EmptyDaySheet(date: date)
          : _ReflectionDetail(date: date, reflection: reflection),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nhìn lại mỗi ngày')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _MonthHeader(
            label: '${_monthNames[_visibleMonth.month - 1]}, ${_visibleMonth.year}',
            onPrev: () => _changeMonth(-1),
            onNext: () => _changeMonth(1),
          ),
          const SizedBox(height: 16),
          _WeekdayRow(labels: _weekdayLabels),
          const SizedBox(height: 8),
          _buildGrid(context),
          const SizedBox(height: 24),
          const _Legend(),
        ],
      ),
    );
  }

  Widget _buildGrid(BuildContext context) {
    final year = _visibleMonth.year;
    final month = _visibleMonth.month;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final leadingBlanks = DateTime(year, month, 1).weekday - 1; // T2 = 0

    final cells = <Widget>[
      for (var i = 0; i < leadingBlanks; i++) const SizedBox.shrink(),
      for (var day = 1; day <= daysInMonth; day++) _dayCell(day),
    ];
    while (cells.length % 7 != 0) {
      cells.add(const SizedBox.shrink());
    }

    final rows = <Widget>[];
    for (var i = 0; i < cells.length; i += 7) {
      rows.add(
        Row(
          children: [
            for (final cell in cells.sublist(i, i + 7)) Expanded(child: cell),
          ],
        ),
      );
    }
    return Column(children: rows);
  }

  Widget _dayCell(int day) {
    final reflection = _reflectionFor(day);
    return _DayCell(
      day: day,
      reflection: reflection,
      isToday: _isCurrentMonth && day == _today.day,
      onTap: () => _openDay(day, reflection),
    );
  }
}

class _MonthHeader extends StatelessWidget {
  final String label;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _MonthHeader({required this.label, required this.onPrev, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: onPrev,
            icon: const Icon(Icons.chevron_left_rounded),
            color: colorScheme.onPrimaryContainer,
            tooltip: 'Tháng trước',
          ),
          Text(
            label,
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
          IconButton(
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right_rounded),
            color: colorScheme.onPrimaryContainer,
            tooltip: 'Tháng sau',
          ),
        ],
      ),
    );
  }
}

class _WeekdayRow extends StatelessWidget {
  final List<String> labels;

  const _WeekdayRow({required this.labels});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        for (final label in labels)
          Expanded(
            child: Center(
              child: Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Chấm tròn nhỏ chỉ mức độ ngày (dùng chung ở lịch, legend, chi tiết).
class _Dot extends StatelessWidget {
  final Color color;

  const _Dot(this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final DailyReflection? reflection;
  final bool isToday;
  final VoidCallback? onTap;

  const _DayCell({
    required this.day,
    required this.reflection,
    required this.isToday,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasData = reflection != null;

    return AspectRatio(
      aspectRatio: 1,
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Material(
          color: isToday ? colorScheme.primary.withValues(alpha: 0.10) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$day',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                    color: isToday ? colorScheme.primary : colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                _Dot(hasData ? reflection!.level.color : colorScheme.surfaceContainerHighest),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        for (final level in ReflectionLevel.values)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Dot(level.color),
              const SizedBox(width: 6),
              Text(level.label, style: theme.textTheme.labelMedium),
            ],
          ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Dot(theme.colorScheme.surfaceContainerHighest),
            const SizedBox(width: 6),
            Text('Chưa có dữ liệu', style: theme.textTheme.labelMedium),
          ],
        ),
      ],
    );
  }
}

class _ReflectionDetail extends StatelessWidget {
  final DateTime date;
  final DailyReflection reflection;

  const _ReflectionDetail({required this.date, required this.reflection});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final level = reflection.level;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Ngày ${date.day}/${date.month}/${date.year}',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: level.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _Dot(level.color),
                    const SizedBox(width: 6),
                    Text(
                      level.label,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: level.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.insights_rounded, size: 18, color: colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(reflection.summaryLine, style: theme.textTheme.bodyMedium),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nhìn lại',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(reflection.note, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet cho ngày chưa có dữ liệu reflection.
class _EmptyDaySheet extends StatelessWidget {
  final DateTime date;

  const _EmptyDaySheet({required this.date});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Mascot(size: 72),
          const SizedBox(height: 16),
          Text(
            'Ngày ${date.day}/${date.month}/${date.year}',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Chưa có dữ liệu cho ngày này.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
