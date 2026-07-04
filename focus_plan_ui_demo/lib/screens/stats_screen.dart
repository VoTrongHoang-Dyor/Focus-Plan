import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/gamification_stats.dart';

/// Màn Thành tích (Gamification): streak, cảnh báo nguy cơ mất chuỗi,
/// và level Pomodoro theo 6 bậc. UI tĩnh mock — không tính toán thật.
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  static const Color _streakColor = Color(0xFFF97316); // orange 500
  static const Color _warnColor = Color(0xFFDC2626); // red 600

  @override
  Widget build(BuildContext context) {
    const stats = mockStats;

    return Scaffold(
      appBar: AppBar(title: const Text('Thành tích')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          if (stats.streakAtRisk) ...[
            _StreakRiskBanner(streak: stats.currentStreak, color: _warnColor),
            const SizedBox(height: 16),
          ],
          _StreakCard(stats: stats, color: _streakColor),
          const SizedBox(height: 16),
          _LevelCard(stats: stats),
        ],
      ),
    );
  }
}

class _StreakRiskBanner extends StatelessWidget {
  final int streak;
  final Color color;

  const _StreakRiskBanner({required this.streak, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chuỗi $streak ngày đang gặp nguy!',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Hoàn thành 1 task hôm nay để giữ chuỗi.',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  final GamificationStats stats;
  final Color color;

  const _StreakCard({required this.stats, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return _StatCard(
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.local_fire_department_rounded, size: 36, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Chuỗi hiện tại', style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${stats.currentStreak}',
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text('ngày liên tiếp', style: theme.textTheme.bodyMedium),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Kỷ lục: ${stats.bestStreak} ngày',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
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

class _LevelCard extends StatelessWidget {
  final GamificationStats stats;

  const _LevelCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final level = stats.currentLevel;
    final next = stats.nextLevel;

    final encourage = stats.isMaxLevel
        ? 'Đỉnh cao rồi — giữ phong độ nhé!'
        : 'Còn ${stats.pomodoroToNext} Pomodoro nữa để lên "${next!.name}".';

    return _StatCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Level Pomodoro', style: theme.textTheme.titleMedium),
          const SizedBox(height: 16),
          Row(
            children: [
              _ProgressRing(
                progress: stats.levelProgress,
                color: colorScheme.primary,
                trackColor: colorScheme.surfaceContainerHighest,
                size: 96,
                stroke: 10,
                center: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Lv ${level.level}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colorScheme.primary,
                      ),
                    ),
                    Text(
                      level.name,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${stats.pomodoroTotal} Pomodoro tích luỹ',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(encourage, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Divider(height: 1, color: colorScheme.outlineVariant),
          const SizedBox(height: 16),
          for (final l in pomodoroLevels)
            _LevelRow(
              level: l,
              isCurrent: l.level == level.level,
              isReached: stats.pomodoroTotal >= l.threshold,
            ),
        ],
      ),
    );
  }
}

class _LevelRow extends StatelessWidget {
  final PomodoroLevel level;
  final bool isCurrent;
  final bool isReached;

  const _LevelRow({
    required this.level,
    required this.isCurrent,
    required this.isReached,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accent = colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            isReached ? Icons.check_circle_rounded : Icons.lock_outline_rounded,
            size: 20,
            color: isReached ? accent : colorScheme.outline,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Level ${level.level} · ${level.name}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400,
                color: isCurrent ? accent : colorScheme.onSurface,
              ),
            ),
          ),
          Text(
            '${level.threshold}+',
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          if (isCurrent) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Hiện tại',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Card nền chung cho các khối stats.
class _StatCard extends StatelessWidget {
  final Widget child;

  const _StatCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: child,
    );
  }
}

/// Vòng tiến trình tự vẽ bằng CustomPaint (không dùng package chart).
class _ProgressRing extends StatelessWidget {
  final double progress;
  final Color color;
  final Color trackColor;
  final double size;
  final double stroke;
  final Widget center;

  const _ProgressRing({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.size,
    required this.stroke,
    required this.center,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(
          progress: progress.clamp(0.0, 1.0),
          color: color,
          trackColor: trackColor,
          stroke: stroke,
        ),
        child: Center(child: center),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;
  final double stroke;

  _RingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.stroke,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - stroke) / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawCircle(center, radius, trackPaint);

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.trackColor != trackColor ||
      old.stroke != stroke;
}
