import 'package:flutter/material.dart';

/// Màn cấu hình Smart Alarm (escalating alarm) — UI tĩnh mock.
///
/// Không bắn notification thật: nút "Tạo báo thức" chỉ hiển thị SnackBar xác nhận.
class AlarmSettingsScreen extends StatefulWidget {
  const AlarmSettingsScreen({super.key});

  @override
  State<AlarmSettingsScreen> createState() => _AlarmSettingsScreenState();
}

class _AlarmSettingsScreenState extends State<AlarmSettingsScreen> {
  static const _dayLabels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  TimeOfDay _time = const TimeOfDay(hour: 7, minute: 0);
  final Set<int> _selectedDays = {0, 1, 2, 3, 4}; // mặc định T2–T6

  bool _loopAudio = true;
  bool _vibrate = true;
  bool _escalateVolume = true;
  bool _showNotification = true;

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  void _createAlarm() {
    final days = _selectedDays.isEmpty
        ? 'một lần'
        : [for (var i = 0; i < 7; i++) if (_selectedDays.contains(i)) _dayLabels[i]].join(', ');
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('Đã tạo báo thức lúc ${_time.format(context)} · $days')),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Báo thức thông minh')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _TimeCard(time: _time, onTap: _pickTime),
          const SizedBox(height: 24),
          _RepeatSelector(
            labels: _dayLabels,
            selected: _selectedDays,
            onToggle: (i) => setState(() {
              _selectedDays.contains(i) ? _selectedDays.remove(i) : _selectedDays.add(i);
            }),
          ),
          const SizedBox(height: 24),
          _OptionCard(
            children: [
              _SwitchRow(
                icon: Icons.repeat_rounded,
                title: 'Lặp âm thanh báo thức',
                subtitle: 'Phát lại đến khi tắt',
                value: _loopAudio,
                onChanged: (v) => setState(() => _loopAudio = v),
              ),
              _SwitchRow(
                icon: Icons.vibration_rounded,
                title: 'Rung',
                value: _vibrate,
                onChanged: (v) => setState(() => _vibrate = v),
              ),
              _SwitchRow(
                icon: Icons.volume_up_rounded,
                title: 'Tăng âm lượng dần',
                subtitle: 'Âm lượng lớn dần để khó ngủ quên',
                value: _escalateVolume,
                onChanged: (v) => setState(() => _escalateVolume = v),
              ),
              _SwitchRow(
                icon: Icons.notifications_active_rounded,
                title: 'Hiện thông báo',
                value: _showNotification,
                onChanged: (v) => setState(() => _showNotification = v),
                isLast: true,
              ),
            ],
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: _createAlarm,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Tạo báo thức', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}

class _TimeCard extends StatelessWidget {
  final TimeOfDay time;
  final VoidCallback onTap;

  const _TimeCard({required this.time, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 28),
          child: Column(
            children: [
              Text(
                'Giờ báo thức',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                time.format(context),
                style: theme.textTheme.displayLarge?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.edit_rounded, size: 16, color: colorScheme.onPrimaryContainer),
                  const SizedBox(width: 4),
                  Text(
                    'Chạm để đổi giờ',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RepeatSelector extends StatelessWidget {
  final List<String> labels;
  final Set<int> selected;
  final ValueChanged<int> onToggle;

  const _RepeatSelector({
    required this.labels,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lặp lại',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var i = 0; i < labels.length; i++)
              _DayChip(
                label: labels[i],
                isSelected: selected.contains(i),
                onTap: () => onToggle(i),
                colorScheme: colorScheme,
                textStyle: theme.textTheme.labelLarge,
              ),
          ],
        ),
      ],
    );
  }
}

class _DayChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final ColorScheme colorScheme;
  final TextStyle? textStyle;

  const _DayChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.colorScheme,
    required this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: isSelected,
      button: true,
      child: InkResponse(
        onTap: onTap,
        radius: 26,
        child: Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primary : colorScheme.surfaceContainerHighest,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
            ),
          ),
          child: Text(
            label,
            style: textStyle?.copyWith(
              color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final List<Widget> children;

  const _OptionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(children: children),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isLast;

  const _SwitchRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        SwitchListTile(
          value: value,
          onChanged: onChanged,
          secondary: Icon(icon, color: colorScheme.primary),
          title: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          subtitle: subtitle == null ? null : Text(subtitle!),
        ),
        if (!isLast)
          Divider(height: 1, indent: 16, endIndent: 16, color: colorScheme.outlineVariant),
      ],
    );
  }
}
