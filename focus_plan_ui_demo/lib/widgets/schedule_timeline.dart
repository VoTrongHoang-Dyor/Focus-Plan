import 'package:flutter/material.dart';

import '../models/schedule_block.dart';

/// Timeline dọc các time-block trong ngày.
///
/// Mỗi hàng: cột giờ (trái) · rail (dot + đường nối) · card nội dung.
/// Giữa hai block liền kề có khe nghỉ sẽ chèn một buffer row hiển thị rõ.
class ScheduleTimeline extends StatelessWidget {
  final List<ScheduleBlock> blocks;

  const ScheduleTimeline({super.key, required this.blocks});

  static const double _railWidth = 28;
  static const double _timeWidth = 46;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];

    for (var i = 0; i < blocks.length; i++) {
      final block = blocks[i];

      if (i > 0) {
        final gap = block.startMinutes - blocks[i - 1].endMinutes;
        if (gap > 0) {
          rows.add(_BufferRow(minutes: gap, railWidth: _railWidth, timeWidth: _timeWidth));
        }
      }

      rows.add(
        _BlockRow(
          block: block,
          isFirst: i == 0,
          isLast: i == blocks.length - 1,
          railWidth: _railWidth,
          timeWidth: _timeWidth,
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: rows,
    );
  }
}

class _BlockRow extends StatelessWidget {
  final ScheduleBlock block;
  final bool isFirst;
  final bool isLast;
  final double railWidth;
  final double timeWidth;

  const _BlockRow({
    required this.block,
    required this.isFirst,
    required this.isLast,
    required this.railWidth,
    required this.timeWidth,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: timeWidth,
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    block.startLabel,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  Text(
                    block.endLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ),
          _Rail(
            width: railWidth,
            color: block.accentColor,
            drawTop: !isFirst,
            drawBottom: !isLast,
            lineColor: colorScheme.outlineVariant,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _BlockCard(block: block),
            ),
          ),
        ],
      ),
    );
  }
}

class _Rail extends StatelessWidget {
  final double width;
  final Color color;
  final bool drawTop;
  final bool drawBottom;
  final Color lineColor;

  const _Rail({
    required this.width,
    required this.color,
    required this.drawTop,
    required this.drawBottom,
    required this.lineColor,
  });

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;

    return SizedBox(
      width: width,
      child: Column(
        children: [
          Expanded(
            child: Container(width: 2, color: drawTop ? lineColor : Colors.transparent),
          ),
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: surface, width: 3),
            ),
          ),
          Expanded(
            child: Container(width: 2, color: drawBottom ? lineColor : Colors.transparent),
          ),
        ],
      ),
    );
  }
}

class _BlockCard extends StatelessWidget {
  final ScheduleBlock block;

  const _BlockCard({required this.block});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accent = block.accentColor;
    final background =
        block.isHabit ? colorScheme.surfaceContainerHighest : colorScheme.surface;

    return Container(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: accent, width: 4)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(block.icon, size: 20, color: accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    block.title,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (block.isHabit)
                  _Badge(
                    icon: Icons.lock_rounded,
                    label: 'Thói quen cố định',
                    color: ScheduleColors.habit,
                    filled: true,
                  )
                else
                  _Badge(
                    icon: block.priority!.icon,
                    label: block.priority!.label,
                    color: block.priority!.color,
                    filled: true,
                  ),
                _Badge(
                  icon: Icons.bolt_rounded,
                  label: block.energyTag,
                  color: colorScheme.onSurfaceVariant,
                  filled: false,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool filled;

  const _Badge({
    required this.icon,
    required this.label,
    required this.color,
    required this.filled,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = filled ? color.withValues(alpha: 0.12) : Colors.transparent;
    final border = filled ? Colors.transparent : theme.colorScheme.outlineVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
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

class _BufferRow extends StatelessWidget {
  final int minutes;
  final double railWidth;
  final double timeWidth;

  const _BufferRow({
    required this.minutes,
    required this.railWidth,
    required this.timeWidth,
  });

  /// < 60 phút: "25'". >= 60 phút: "3h 45m" (bỏ phần phút nếu = 0).
  static String _formatGap(int minutes) {
    if (minutes < 60) return "$minutes'";
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      height: 34,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(width: timeWidth),
          SizedBox(
            width: railWidth,
            child: Center(
              child: Container(width: 2, color: colorScheme.outlineVariant),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.coffee_rounded,
                    size: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Nghỉ ${_formatGap(minutes)}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
