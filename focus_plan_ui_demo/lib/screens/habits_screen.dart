import 'package:flutter/material.dart';

import '../models/habit.dart';

/// Màn quản lý Habit / Routine: danh sách thói quen cố định hàng ngày,
/// nhóm theo buổi, tick trạng thái done/missed, thêm/sửa/xoá (mock, UI-only).
class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  final List<Habit> _habits = seedHabits();

  static const Color _doneColor = Color(0xFF059669); // emerald 600

  Color _statusColor(HabitStatus status, ColorScheme scheme) => switch (status) {
    HabitStatus.done => _doneColor,
    HabitStatus.missed => scheme.error,
    HabitStatus.pending => scheme.outline,
  };

  void _cycleStatus(Habit habit) {
    setState(() => habit.todayStatus = habit.todayStatus.next);
  }

  Future<void> _openForm({Habit? existing}) async {
    final nameController = TextEditingController(text: existing?.name ?? '');
    var time = TimeOfDay(
      hour: (existing?.timeMinutes ?? 8 * 60) ~/ 60,
      minute: (existing?.timeMinutes ?? 8 * 60) % 60,
    );

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(existing == null ? 'Thêm thói quen' : 'Sửa thói quen'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: (_) => setDialogState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Tên thói quen',
                      hintText: 'VD: Thiền chánh niệm',
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.schedule_rounded),
                    title: const Text('Giờ cố định hàng ngày'),
                    trailing: Text(
                      time.format(context),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: time,
                      );
                      if (picked != null) setDialogState(() => time = picked);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Huỷ'),
                ),
                FilledButton(
                  onPressed: nameController.text.trim().isEmpty
                      ? null
                      : () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Lưu'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved != true) {
      nameController.dispose();
      return;
    }

    final name = nameController.text.trim();
    final minutes = time.hour * 60 + time.minute;
    setState(() {
      if (existing == null) {
        _habits.add(
          Habit(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            name: name,
            timeMinutes: minutes,
          ),
        );
      } else {
        existing.name = name;
        existing.timeMinutes = minutes;
      }
    });
    nameController.dispose();
  }

  void _deleteHabit(Habit habit) {
    final index = _habits.indexOf(habit);
    setState(() => _habits.remove(habit));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Đã xoá "${habit.name}"'),
          action: SnackBarAction(
            label: 'Hoàn tác',
            onPressed: () => setState(() => _habits.insert(index, habit)),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final doneCount = _habits.where((h) => h.todayStatus == HabitStatus.done).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Thói quen')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Thêm thói quen'),
      ),
      body: _habits.isEmpty
          ? _EmptyState(onAdd: () => _openForm())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                _SummaryHeader(done: doneCount, total: _habits.length),
                const SizedBox(height: 20),
                for (final part in DayPart.values)
                  ..._buildSection(part, colorScheme),
              ],
            ),
    );
  }

  List<Widget> _buildSection(DayPart part, ColorScheme colorScheme) {
    final items = _habits.where((h) => h.dayPart == part).toList()
      ..sort((a, b) => a.timeMinutes.compareTo(b.timeMinutes));
    if (items.isEmpty) return const [];

    return [
      _SectionHeader(dayPart: part),
      const SizedBox(height: 10),
      Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Column(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0)
                Divider(height: 1, indent: 60, color: colorScheme.outlineVariant),
              _HabitRow(
                habit: items[i],
                statusColor: _statusColor(items[i].todayStatus, colorScheme),
                onToggle: () => _cycleStatus(items[i]),
                onEdit: () => _openForm(existing: items[i]),
                onDelete: () => _deleteHabit(items[i]),
              ),
            ],
          ],
        ),
      ),
      const SizedBox(height: 24),
    ];
  }
}

class _SummaryHeader extends StatelessWidget {
  final int done;
  final int total;

  const _SummaryHeader({required this.done, required this.total});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final progress = total == 0 ? 0.0 : done / total;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thói quen hôm nay',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Đã hoàn thành $done/$total',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 52,
            height: 52,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 5,
                  backgroundColor: colorScheme.onPrimaryContainer.withValues(alpha: 0.15),
                ),
                Text(
                  '${(progress * 100).round()}%',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final DayPart dayPart;

  const _SectionHeader({required this.dayPart});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Icon(dayPart.icon, size: 20, color: colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          dayPart.label,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _HabitRow extends StatelessWidget {
  final Habit habit;
  final Color statusColor;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _HabitRow({
    required this.habit,
    required this.statusColor,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDone = habit.todayStatus == HabitStatus.done;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            iconSize: 28,
            onPressed: onToggle,
            icon: Icon(habit.todayStatus.icon, color: statusColor),
            tooltip: 'Trạng thái: ${habit.todayStatus.label}',
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  habit.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                    color: isDone ? colorScheme.onSurfaceVariant : colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.schedule_rounded, size: 14, color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      habit.timeLabel,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _FixedBadge(),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Tuỳ chọn',
            onSelected: (value) {
              if (value == 'edit') onEdit();
              if (value == 'delete') onDelete();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.edit_outlined),
                  title: Text('Sửa'),
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.delete_outline, color: colorScheme.error),
                  title: Text('Xoá', style: TextStyle(color: colorScheme.error)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Badge "Thói quen cố định" (đồng bộ ý nghĩa với busy-block ở màn lịch).
class _FixedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const color = Color(0xFF64748B); // slate 500 — màu trầm

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_rounded, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            'Thói quen cố định',
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.self_improvement_rounded, size: 64, color: colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'Chưa có thói quen nào',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Thêm thói quen cố định hàng ngày để theo dõi mỗi ngày.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Thêm thói quen'),
            ),
          ],
        ),
      ),
    );
  }
}
