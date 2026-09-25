import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/formatters.dart';
import '../../../data/models/app_info.dart';
import '../../../data/models/usage_record.dart';
import '../../viewmodels/app_view_model.dart';
import '../../viewmodels/dashboard_view_model.dart';
import '../../viewmodels/focus_view_model.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/progress_ring.dart';
import '../../widgets/section_header.dart';
import '../../widgets/unloop_card.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<DashboardViewModel>().load();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<DashboardViewModel>().load();
      context.read<FocusViewModel>().initialize();
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<DashboardViewModel>();
    final focusViewModel = context.watch<FocusViewModel>();
    final settings = context.watch<AppViewModel>().settings;
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: () => context.read<DashboardViewModel>().load(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              sliver: SliverToBoxAdapter(
                child: _Greeting(name: settings.displayName),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 120),
              sliver: SliverList.list(
                children: [
                  if (focusViewModel.activeSession != null) ...[
                    _ActiveFocusBanner(
                      onResume: () => context.push('/focus/active'),
                    ),
                    const SizedBox(height: 16),
                  ],
                  _UsageOverview(viewModel: viewModel),
                  const SizedBox(height: 16),
                  if (!viewModel.hasUsageAccess) ...[
                    _PermissionRequired(onOpen: viewModel.openUsageAccess),
                    const SizedBox(height: 16),
                  ],
                  if (viewModel.errorMessage != null) ...[
                    _SoftMessage(
                      icon: Icons.info_outline_rounded,
                      message: viewModel.errorMessage!,
                    ),
                    const SizedBox(height: 16),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: _MetricCard(
                          icon: Icons.self_improvement_rounded,
                          label: 'Focus today',
                          value: Formatters.minutes(
                            viewModel.completedFocusMinutes,
                          ),
                          detail: '${viewModel.focusSessionCount} sessions',
                          progress: viewModel.focusProgress,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MetricCard(
                          icon: Icons.local_fire_department_outlined,
                          label: 'Gentle streak',
                          value: '${viewModel.currentStreak} days',
                          detail: viewModel.currentStreak == 0
                              ? 'Begin whenever ready'
                              : 'Keep it kind',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _RiskMessage(message: viewModel.riskMessage),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: FilledButton.icon(
                          onPressed: () => context.push('/focus/setup'),
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text('Start focus'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: OutlinedButton.icon(
                          onPressed: () => context.push('/urge'),
                          icon: const Icon(Icons.pause_circle_outline_rounded),
                          label: const Text('Urge'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  SectionHeader(
                    title: 'Most present today',
                    subtitle: viewModel.todayApps.isEmpty
                        ? 'Your app patterns will gather here'
                        : 'Across the apps you chose to notice',
                  ),
                  const SizedBox(height: 14),
                  if (viewModel.isLoading && viewModel.todayApps.isEmpty)
                    const _LoadingCard()
                  else if (viewModel.todayApps.isEmpty)
                    UnloopCard(
                      child: EmptyState(
                        icon: Icons.hourglass_empty_rounded,
                        title: viewModel.hasUsageAccess
                            ? 'A fresh start'
                            : 'Usage data is optional',
                        message: viewModel.hasUsageAccess
                            ? 'No distracting app time has been cached yet.'
                            : 'Grant Usage Access to see app time, or keep using focus and urge tools without it.',
                        actionLabel: viewModel.hasUsageAccess
                            ? 'Refresh'
                            : 'Learn about access',
                        onAction: viewModel.hasUsageAccess
                            ? () => viewModel.load()
                            : viewModel.openUsageAccess,
                      ),
                    )
                  else
                    UnloopCard(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        children: [
                          for (
                            var index = 0;
                            index < viewModel.todayApps.length && index < 5;
                            index++
                          ) ...[
                            _UsageRow(
                              record: viewModel.todayApps[index],
                              isTop: index == 0,
                            ),
                            if (index < viewModel.todayApps.length - 1 &&
                                index < 4)
                              const Divider(indent: 66),
                          ],
                        ],
                      ),
                    ),
                  const SizedBox(height: 28),
                  const SectionHeader(
                    title: 'Your approach',
                    subtitle: 'Private by design, flexible by choice',
                  ),
                  const SizedBox(height: 14),
                  _CoachCard(onOpen: viewModel.openDigitalWellbeing),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.name});

  final String? name;

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 18
        ? 'Good afternoon'
        : 'Good evening';
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name == null || name!.trim().isEmpty
                    ? greeting
                    : '$greeting, ${name!.trim()}',
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Let today be intentional, not perfect.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.spa_rounded,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
      ],
    );
  }
}

class _UsageOverview extends StatelessWidget {
  const _UsageOverview({required this.viewModel});

  final DashboardViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return UnloopCard(
      padding: const EdgeInsets.all(22),
      child: Row(
        children: [
          ProgressRing(
            progress: viewModel.targetProgress,
            size: 142,
            strokeWidth: 11,
            semanticLabel: 'Progress toward distracting app time target',
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  Formatters.minutes(viewModel.distractingMinutes),
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: 3),
                Text(
                  'of ${Formatters.minutes(viewModel.dailyTargetMinutes)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 22),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Time on your chosen apps',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  viewModel.distractingMinutes <= viewModel.dailyTargetMinutes
                      ? 'You have ${Formatters.minutes(viewModel.dailyTargetMinutes - viewModel.distractingMinutes)} before your intention.'
                      : 'You are ${Formatters.minutes(viewModel.distractingMinutes - viewModel.dailyTargetMinutes)} past your intention. A new moment is enough.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${(viewModel.targetProgress * 100).round()}% of intention',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
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

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.detail,
    this.progress,
  });

  final IconData icon;
  final String label;
  final String value;
  final String detail;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return UnloopCard(
      padding: const EdgeInsets.all(17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 23),
          const SizedBox(height: 15),
          Text(label, style: theme.textTheme.bodySmall),
          const SizedBox(height: 3),
          Text(value, maxLines: 1, style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            detail,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (progress != null) ...[
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              borderRadius: BorderRadius.circular(8),
            ),
          ],
        ],
      ),
    );
  }
}

class _RiskMessage extends StatelessWidget {
  const _RiskMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.wb_twilight_rounded, color: theme.colorScheme.tertiary),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('A gentle check-in', style: theme.textTheme.titleMedium),
                const SizedBox(height: 5),
                Text(message, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UsageRow extends StatelessWidget {
  const _UsageRow({required this.record, required this.isTop});

  final UsageRecord record;
  final bool isTop;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final app = AppInfo(
      packageName: record.packageName,
      displayName: record.applicationName,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      child: Row(
        children: [
          AppIcon(app: app, size: 44),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        record.applicationName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    if (isTop) ...[
                      const SizedBox(width: 7),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Top',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  isTop ? 'Most present app today' : 'Time in foreground',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            Formatters.minutes(record.duration.inMinutes),
            style: theme.textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

class _PermissionRequired extends StatelessWidget {
  const _PermissionRequired({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return UnloopCard(
      color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.58),
      child: Row(
        children: [
          Icon(Icons.lock_open_rounded, color: theme.colorScheme.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Usage Access is off', style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  'Everything else still works. Add usage access only if you want the time picture.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onOpen,
            icon: const Icon(Icons.arrow_forward_rounded),
            tooltip: 'Open Usage Access settings',
          ),
        ],
      ),
    );
  }
}

class _SoftMessage extends StatelessWidget {
  const _SoftMessage({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 11),
          Expanded(child: Text(message, style: theme.textTheme.bodySmall)),
        ],
      ),
    );
  }
}

class _ActiveFocusBanner extends StatelessWidget {
  const _ActiveFocusBanner({required this.onResume});

  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = context.watch<FocusViewModel>().activeSession!;
    return UnloopCard(
      color: theme.colorScheme.primaryContainer,
      onTap: onResume,
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              Icons.self_improvement_rounded,
              color: theme.colorScheme.onPrimary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Focus in progress', style: theme.textTheme.titleMedium),
                const SizedBox(height: 3),
                Text(
                  '${session.intention} · ${Formatters.duration(session.remainingAt(DateTime.now()))} left',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_rounded),
        ],
      ),
    );
  }
}

class _CoachCard extends StatelessWidget {
  const _CoachCard({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return UnloopCard(
      onTap: onOpen,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.phone_android_rounded,
              color: theme.colorScheme.onSecondaryContainer,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Set up Android focus tools',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Open Digital Wellbeing for timed app limits.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.open_in_new_rounded, size: 20),
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return const UnloopCard(
      child: SizedBox(
        height: 130,
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
