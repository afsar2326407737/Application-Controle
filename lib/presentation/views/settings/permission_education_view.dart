import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../viewmodels/settings_view_model.dart';
import '../../widgets/permission_card.dart';
import '../../widgets/unloop_card.dart';

class PermissionEducationView extends StatelessWidget {
  const PermissionEducationView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SettingsViewModel>();
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Permissions & privacy')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
        children: [
          Text(
            'Only what helps, only when asked',
            style: theme.textTheme.headlineLarge,
          ),
          const SizedBox(height: 10),
          Text(
            'Every permission is optional. Denying one never stops focus sessions or the urge flow.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 26),
          PermissionCard(
            icon: Icons.query_stats_rounded,
            title: 'Usage Access · optional',
            body: PermissionCopy.usageBody,
            optional: true,
            actionLabel: 'Open Usage Access settings',
            onAction: viewModel.openUsageSettings,
          ),
          const SizedBox(height: 14),
          PermissionCard(
            icon: Icons.notifications_none_rounded,
            title: 'Notifications · optional',
            body: PermissionCopy.notificationBody,
            optional: true,
            isGranted: viewModel.hasNotificationPermission,
            actionLabel: 'Request notifications',
            onAction: () => viewModel.setNotifications(true),
          ),
          const SizedBox(height: 14),
          PermissionCard(
            icon: Icons.accessibility_new_rounded,
            title: 'Accessibility · personal mode only',
            body: PermissionCopy.blockerBody,
            optional: true,
            isGranted: viewModel.blockerStatus.systemEnabled,
            actionLabel: 'Open accessibility settings',
            onAction: viewModel.openAccessibilitySettings,
          ),
          const SizedBox(height: 26),
          UnloopCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Never requested', style: theme.textTheme.titleLarge),
                const SizedBox(height: 14),
                const _NoPermissionRow(label: 'Camera or photos'),
                const _NoPermissionRow(label: 'Microphone'),
                const _NoPermissionRow(label: 'Contacts'),
                const _NoPermissionRow(label: 'Location'),
                const _NoPermissionRow(label: 'Internet in the release build'),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.lock_outline_rounded,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Unloop reads package names and Android usage durations only after Usage Access is granted. It never reads app content.',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NoPermissionRow extends StatelessWidget {
  const _NoPermissionRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.close_rounded, size: 19),
          const SizedBox(width: 10),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
