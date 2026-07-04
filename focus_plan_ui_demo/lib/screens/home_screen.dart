import 'package:flutter/material.dart';

import '../models/schedule_block.dart';
import '../services/session_service.dart';
import '../widgets/brand.dart';
import '../widgets/schedule_timeline.dart';
import 'alarm_settings_screen.dart';
import 'habits_screen.dart';
import 'reflection_screen.dart';
import 'sign_in_screen.dart';
import 'stats_screen.dart';

class HomeScreen extends StatelessWidget {
  final String email;

  const HomeScreen({super.key, required this.email});

  static const _labels = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];

  Future<void> _handleSignOut(BuildContext context) async {
    await SessionService.signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SignInScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final weekDays = List.generate(
      7,
      (i) => now.subtract(Duration(days: now.weekday % 7 - i)),
    );
    final colorScheme = Theme.of(context).colorScheme;
    final habitCount = mockSchedule.where((b) => b.isHabit).length;
    final taskCount = mockSchedule.length - habitCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Today'),
        actions: [
          IconButton(
            icon: const Icon(Icons.checklist_rounded),
            tooltip: 'Thói quen',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const HabitsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.alarm_rounded),
            tooltip: 'Báo thức',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AlarmSettingsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded),
            tooltip: 'Nhìn lại',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ReflectionScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.emoji_events_rounded),
            tooltip: 'Thành tích',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const StatsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: () => _handleSignOut(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Xin chào, $email', style: Theme.of(context).textTheme.titleMedium),
                ),
                const SizedBox(width: 12),
                const Mascot(size: 48),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: weekDays.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final day = weekDays[index];
                  final isToday = day.day == now.day && day.month == now.month;
                  return Container(
                    width: 48,
                    decoration: BoxDecoration(
                      color: isToday ? colorScheme.primary : colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _labels[day.weekday % 7],
                          style: TextStyle(
                            color: isToday ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${day.day}',
                          style: TextStyle(
                            color: isToday ? colorScheme.onPrimary : colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('Lịch hôm nay', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(width: 8),
                Text(
                  '$taskCount việc · $habitCount thói quen',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ScheduleTimeline(blocks: mockSchedule),
            ),
          ],
        ),
      ),
    );
  }
}
