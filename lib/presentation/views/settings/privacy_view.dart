import 'package:flutter/material.dart';

import '../../widgets/unloop_card.dart';

class PrivacyView extends StatelessWidget {
  const PrivacyView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy promise')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
        children: [
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.lock_rounded,
              size: 40,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Your attention is not ours to collect.',
            style: theme.textTheme.headlineLarge,
          ),
          const SizedBox(height: 12),
          Text(
            'Unloop is built so the useful part of the app can work without a network connection.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 26),
          const _PrivacySection(
            icon: Icons.phone_android_rounded,
            title: 'Stored on this device',
            body: 'Preferences, cached app durations, focus sessions, and urge logs stay in Android app storage and SQLite.',
          ),
          const SizedBox(height: 12),
          const _PrivacySection(
            icon: Icons.visibility_off_outlined,
            title: 'No app content',
            body: 'Unloop never reads posts, messages, photos, search terms, or notification content.',
          ),
          const SizedBox(height: 12),
          const _PrivacySection(
            icon: Icons.cloud_off_rounded,
            title: 'No account or cloud',
            body: 'There are no accounts, servers, advertisements, analytics identifiers, or AI features in version one.',
          ),
          const SizedBox(height: 12),
          const _PrivacySection(
            icon: Icons.file_download_outlined,
            title: 'Portable by you',
            body: 'Export creates a local JSON copy. Clearing all data removes Unloop history and preferences immediately.',
          ),
          const SizedBox(height: 24),
          UnloopCard(
            color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.72),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: theme.colorScheme.tertiary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Android Usage Access and accessibility permissions are controlled in system settings. You can revoke either at any time.',
                    style: theme.textTheme.bodyMedium,
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

class _PrivacySection extends StatelessWidget {
  const _PrivacySection({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return UnloopCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: theme.colorScheme.onSecondaryContainer),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
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
