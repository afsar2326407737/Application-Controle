import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/formatters.dart';
import '../../../data/models/user_settings.dart';
import '../../viewmodels/app_view_model.dart';
import '../../viewmodels/settings_view_model.dart';
import '../../widgets/section_header.dart';
import '../../widgets/unloop_card.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<SettingsViewModel>().load();
    });
  }

  Future<void> _chooseTarget() async {
    final viewModel = context.read<SettingsViewModel>();
    final settings = context.read<AppViewModel>().settings;
    final value = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) =>
          _TargetSheet(initialValue: settings.dailyLimitMinutes),
    );
    if (value != null) await viewModel.setDailyLimit(value);
  }

  Future<void> _chooseFocusDuration() async {
    final viewModel = context.read<SettingsViewModel>();
    final settings = context.read<AppViewModel>().settings;
    final value = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (context) =>
          _FocusDurationSheet(initialValue: settings.defaultFocusMinutes),
    );
    if (value != null) await viewModel.setDefaultFocus(value);
  }

  Future<void> _chooseReminderTime() async {
    final viewModel = context.read<SettingsViewModel>();
    final settings = context.read<AppViewModel>().settings;
    final value = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: settings.reminderHour,
        minute: settings.reminderMinute,
      ),
      helpText: 'Choose daily reflection time',
    );
    if (value != null) {
      await viewModel.setReminderTime(value.hour, value.minute);
    }
  }

  Future<void> _chooseQuietHours() async {
    final viewModel = context.read<SettingsViewModel>();
    final settings = context.read<AppViewModel>().settings;
    final result = await showModalBottomSheet<List<int>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _QuietHoursSheet(
        initialStart: settings.quietStartHour,
        initialEnd: settings.quietEndHour,
      ),
    );
    if (result != null) {
      await viewModel.setQuietHours(result[0], result[1]);
    }
  }

  Future<void> _export() async {
    final renderBox = context.findRenderObject() as RenderBox?;
    final origin = renderBox == null
        ? null
        : renderBox.localToGlobal(Offset.zero) & renderBox.size;
    try {
      await context.read<SettingsViewModel>().shareExport(origin: origin);
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('The export could not be shared.')),
        );
      }
    }
  }

  Future<void> _clearData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.delete_outline_rounded),
        title: const Text('Clear all Unloop data?'),
        content: const Text(
          'This removes usage history, focus sessions, urge logs, and preferences from this device. Android’s own Usage Access permission is not changed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep my data'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear everything'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<SettingsViewModel>().clearAllData();
      if (mounted) context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SettingsViewModel>();
    final appViewModel = context.watch<AppViewModel>();
    final settings = appViewModel.settings;
    final theme = Theme.of(context);
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 120),
        children: [
          Text('Make Unloop yours', style: theme.textTheme.headlineLarge),
          const SizedBox(height: 7),
          Text(
            'Every setting stays on this device.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (viewModel.isBusy) ...[
            const SizedBox(height: 14),
            const LinearProgressIndicator(minHeight: 3),
          ],
          const SizedBox(height: 30),
          const SectionHeader(title: 'Daily rhythm'),
          const SizedBox(height: 12),
          UnloopCard(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.timelapse_rounded,
                  title: 'Chosen app limit',
                  subtitle: Formatters.minutes(settings.dailyLimitMinutes),
                  onTap: _chooseTarget,
                ),
                const Divider(indent: 58),
                _SettingsTile(
                  icon: Icons.self_improvement_rounded,
                  title: 'Default focus length',
                  subtitle: '${settings.defaultFocusMinutes} minutes',
                  onTap: _chooseFocusDuration,
                ),
                const Divider(indent: 58),
                _SettingsTile(
                  icon: Icons.notifications_none_rounded,
                  title: 'Daily reflection',
                  subtitle: _formatTime(
                    settings.reminderHour,
                    settings.reminderMinute,
                  ),
                  trailing: Switch.adaptive(
                    value: settings.remindersEnabled,
                    onChanged: viewModel.setReminders,
                  ),
                  onTap: _chooseReminderTime,
                ),
                const Divider(indent: 58),
                _SettingsTile(
                  icon: Icons.bedtime_outlined,
                  title: 'Quiet hours',
                  subtitle:
                      '${_hour(settings.quietStartHour)}–${_hour(settings.quietEndHour)}',
                  onTap: _chooseQuietHours,
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          const SectionHeader(title: 'Your apps'),
          const SizedBox(height: 12),
          UnloopCard(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.apps_rounded,
                  title: 'Apps to notice',
                  subtitle:
                      '${settings.selectedPackages.length} selected locally',
                  onTap: () => context.push('/settings/apps'),
                ),
                const Divider(indent: 58),
                _SettingsTile(
                  icon: settings.preferredMode == AppMode.coach
                      ? Icons.coffee_rounded
                      : Icons.shield_outlined,
                  title: 'Support mode',
                  subtitle: settings.preferredMode.label,
                  onTap: () => context.push('/settings/blocker'),
                ),
                const Divider(indent: 58),
                _SettingsTile(
                  icon: Icons.key_outlined,
                  title: 'Permissions & privacy',
                  subtitle: 'See exactly what each permission can do',
                  onTap: () => context.push('/permissions'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          const SectionHeader(title: 'Notifications & appearance'),
          const SizedBox(height: 12),
          UnloopCard(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                SwitchListTile(
                  value: settings.notificationsEnabled,
                  onChanged: viewModel.setNotifications,
                  secondary: const Icon(Icons.notifications_outlined),
                  title: const Text('Session notifications'),
                  subtitle: Text(
                    viewModel.hasNotificationPermission
                        ? 'Gentle completion and reminder messages'
                        : 'Permission is off; Unloop still works',
                  ),
                ),
                const Divider(indent: 58),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.palette_outlined),
                          const SizedBox(width: 18),
                          Text('Theme', style: theme.textTheme.titleMedium),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<ThemeMode>(
                          segments: const [
                            ButtonSegment(
                              value: ThemeMode.system,
                              icon: Icon(Icons.brightness_auto_outlined),
                              label: Text('System'),
                            ),
                            ButtonSegment(
                              value: ThemeMode.light,
                              icon: Icon(Icons.light_mode_outlined),
                              label: Text('Light'),
                            ),
                            ButtonSegment(
                              value: ThemeMode.dark,
                              icon: Icon(Icons.dark_mode_outlined),
                              label: Text('Dark'),
                            ),
                          ],
                          selected: {appViewModel.themeMode},
                          showSelectedIcon: false,
                          onSelectionChanged: (selection) =>
                              viewModel.setThemeMode(selection.first),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          const SectionHeader(title: 'Your data'),
          const SizedBox(height: 12),
          UnloopCard(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.ios_share_rounded,
                  title: 'Export local data',
                  subtitle: 'Share a JSON copy whenever you want',
                  onTap: _export,
                ),
                const Divider(indent: 58),
                _SettingsTile(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy promise',
                  subtitle: 'Plain-language details about local storage',
                  onTap: () => context.push('/settings/privacy'),
                ),
                const Divider(indent: 58),
                _SettingsTile(
                  icon: Icons.delete_outline_rounded,
                  title: 'Clear all data',
                  subtitle: 'Remove Unloop history and preferences',
                  destructive: true,
                  onTap: _clearData,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'Unloop · local-first · no account',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _hour(int value) {
    final suffix = value >= 12 ? 'PM' : 'AM';
    final display = value % 12 == 0 ? 12 : value % 12;
    return '$display $suffix';
  }

  String _formatTime(int hour, int minute) {
    final suffix = hour >= 12 ? 'PM' : 'AM';
    final display = hour % 12 == 0 ? 12 : hour % 12;
    return '$display:${minute.toString().padLeft(2, '0')} $suffix';
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = destructive
        ? theme.colorScheme.error
        : theme.colorScheme.onSurface;
    return ListTile(
      minTileHeight: 72,
      onTap: onTap,
      leading: Icon(icon, color: destructive ? theme.colorScheme.error : null),
      title: Text(title, style: TextStyle(color: color)),
      subtitle: Text(subtitle),
      trailing:
          trailing ??
          Icon(
            Icons.chevron_right_rounded,
            color: theme.colorScheme.onSurfaceVariant,
          ),
    );
  }
}

class _TargetSheet extends StatefulWidget {
  const _TargetSheet({required this.initialValue});

  final int initialValue;

  @override
  State<_TargetSheet> createState() => _TargetSheetState();
}

class _TargetSheetState extends State<_TargetSheet> {
  late int _value = widget.initialValue;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 4, 22, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chosen app limit',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 7),
            Text(
              Formatters.minutes(_value),
              style: Theme.of(context).textTheme.displaySmall,
            ),
            Slider(
              value: _value.toDouble(),
              min: 30,
              max: 300,
              divisions: 9,
              onChanged: (value) => setState(() => _value = value.round()),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context, _value),
                child: const Text('Use this intention'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FocusDurationSheet extends StatelessWidget {
  const _FocusDurationSheet({required this.initialValue});

  final int initialValue;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 4, 22, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Default focus length',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 9,
              runSpacing: 9,
              children: [15, 25, 45, 60]
                  .map(
                    (minutes) => ChoiceChip(
                      label: Text('$minutes min'),
                      selected: initialValue == minutes,
                      onSelected: (_) => Navigator.pop(context, minutes),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuietHoursSheet extends StatefulWidget {
  const _QuietHoursSheet({
    required this.initialStart,
    required this.initialEnd,
  });

  final int initialStart;
  final int initialEnd;

  @override
  State<_QuietHoursSheet> createState() => _QuietHoursSheetState();
}

class _QuietHoursSheetState extends State<_QuietHoursSheet> {
  late TimeOfDay _start = TimeOfDay(hour: widget.initialStart, minute: 0);
  late TimeOfDay _end = TimeOfDay(hour: widget.initialEnd, minute: 0);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 4, 22, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quiet hours', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 7),
            Text(
              'Unloop will not send a daily reflection during this window.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () async {
                      final result = await showTimePicker(
                        context: context,
                        initialTime: _start,
                      );
                      if (result != null) setState(() => _start = result);
                    },
                    icon: const Icon(Icons.bedtime_outlined),
                    label: Text(_start.format(context)),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Icon(Icons.arrow_forward_rounded),
                ),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () async {
                      final result = await showTimePicker(
                        context: context,
                        initialTime: _end,
                      );
                      if (result != null) setState(() => _end = result);
                    },
                    icon: const Icon(Icons.wb_sunny_outlined),
                    label: Text(_end.format(context)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () =>
                    Navigator.pop(context, [_start.hour, _end.hour]),
                child: const Text('Save quiet hours'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
