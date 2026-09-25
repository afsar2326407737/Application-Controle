import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../data/models/user_settings.dart';
import '../../viewmodels/app_view_model.dart';
import '../../viewmodels/settings_view_model.dart';
import '../../widgets/permission_card.dart';
import '../../widgets/unloop_card.dart';

class BlockerView extends StatelessWidget {
  const BlockerView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SettingsViewModel>();
    final appViewModel = context.watch<AppViewModel>();
    final settings = appViewModel.settings;
    final status = viewModel.blockerStatus;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Support mode')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(26),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.shield_outlined,
                  size: 36,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 18),
                Text(
                  'Support, not punishment',
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: 9),
                Text(
                  'Coach Mode works with Android Digital Wellbeing. Personal Blocker returns you to Unloop when a selected app opens.',
                  style: theme.textTheme.bodyLarge,
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          _ModeOption(
            icon: Icons.coffee_rounded,
            title: 'Coach Mode',
            description: 'Usage picture, focus sessions, urge pauses, and optional Android app limits.',
            selected: settings.preferredMode == AppMode.coach,
            onTap: () => viewModel.setMode(AppMode.coach),
          ),
          const SizedBox(height: 12),
          _ModeOption(
            icon: Icons.shield_outlined,
            title: 'Personal Blocker',
            description: 'Optional whole-app redirection for personal installations. It cannot target only YouTube Shorts.',
            selected: settings.preferredMode == AppMode.personalBlocker,
            onTap: () => viewModel.setMode(AppMode.personalBlocker),
          ),
          if (settings.preferredMode == AppMode.personalBlocker) ...[
            const SizedBox(height: 26),
            UnloopCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: status.isActive
                              ? theme.colorScheme.primary
                              : theme.colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          status.isActive
                              ? Icons.shield_rounded
                              : Icons.shield_outlined,
                          color: status.isActive
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSecondaryContainer,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              status.isActive
                                  ? 'Redirect is on'
                                  : 'Redirect is paused',
                              style: theme.textTheme.titleLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              status.systemEnabled
                                  ? 'Android accessibility access is granted'
                                  : 'Enable Unloop in Android accessibility settings',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (settings.blockerEnabled) ...[
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => viewModel.setBlockerEnabled(false),
                        icon: const Icon(Icons.emergency_outlined),
                        label: const Text('Emergency stop'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              value: settings.blockerEnabled,
              onChanged: (value) async {
                if (value && !status.systemEnabled) {
                  await viewModel.openAccessibilitySettings();
                }
                await viewModel.setBlockerEnabled(value);
              },
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              title: const Text('Redirect selected apps'),
              subtitle: Text(
                '${settings.selectedPackages.length} apps selected',
              ),
            ),
            TextButton.icon(
              onPressed: () => context.push('/settings/apps'),
              icon: const Icon(Icons.apps_rounded),
              label: const Text('Choose apps'),
            ),
            const SizedBox(height: 12),
            PermissionCard(
              icon: Icons.accessibility_new_rounded,
              title: PermissionCopy.blockerTitle,
              body: PermissionCopy.blockerBody,
              optional: true,
              isGranted: status.systemEnabled,
              actionLabel: 'Open Android accessibility settings',
              onAction: viewModel.openAccessibilitySettings,
            ),
            const SizedBox(height: 14),
            _SafetyNote(),
          ],
          if (viewModel.errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              viewModel.errorMessage!,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ],
        ],
      ),
    );
  }
}

class _ModeOption extends StatelessWidget {
  const _ModeOption({
    required this.icon,
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return UnloopCard(
      onTap: onTap,
      color: selected
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.64)
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleLarge),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            selected ? Icons.check_circle_rounded : Icons.circle_outlined,
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
          ),
        ],
      ),
    );
  }
}

class _SafetyNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Android can disable accessibility at any time. The emergency stop above always turns off Unloop’s own redirection immediately.',
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
