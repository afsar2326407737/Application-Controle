import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/date_time_utils.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/focus_session.dart';
import '../../viewmodels/insights_view_model.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/section_header.dart';
import '../../widgets/unloop_card.dart';

class InsightsView extends StatefulWidget {
  const InsightsView({super.key});

  @override
  State<InsightsView> createState() => _InsightsViewState();
}

class _InsightsViewState extends State<InsightsView>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<InsightsViewModel>().load(syncUsage: true);
      }
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
      context.read<InsightsViewModel>().load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<InsightsViewModel>();
    final summary = viewModel.summary;
    final theme = Theme.of(context);
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: () => viewModel.load(syncUsage: true),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 120),
              sliver: SliverList.list(
                children: [
                  Text(
                    'Notice, don’t judge',
                    style: theme.textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'A private look at the last seven days.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _WeeklyHero(viewModel: viewModel),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _InsightMetric(
                          label: 'Most present',
                          value: summary.topAppName.isEmpty
                              ? '—'
                              : summary.topAppName,
                          detail: summary.topAppMinutes == 0
                              ? 'Waiting for data'
                              : Formatters.minutes(summary.topAppMinutes),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _InsightMetric(
                          label: 'Gentle streak',
                          value: '${summary.currentStreak} days',
                          detail: '${summary.completedSessions} sessions',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  const SectionHeader(
                    title: 'Your week in minutes',
                    subtitle: 'Chosen app time and protected focus',
                  ),
                  const SizedBox(height: 14),
                  UnloopCard(
                    padding: const EdgeInsets.fromLTRB(14, 22, 18, 14),
                    child: SizedBox(
                      height: 220,
                      child:
                          summary.days.every(
                            (day) =>
                                day.distractingMinutes == 0 &&
                                day.focusMinutes == 0,
                          )
                          ? const Center(
                              child: Text(
                                'Your first data point can be a small focus session.',
                              ),
                            )
                          : _WeeklyChart(days: summary.days),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _LegendDot(
                        color: theme.colorScheme.tertiary,
                        label: 'Chosen apps',
                      ),
                      const SizedBox(width: 18),
                      _LegendDot(
                        color: theme.colorScheme.primary,
                        label: 'Focus',
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  const SectionHeader(title: 'Patterns worth keeping'),
                  const SizedBox(height: 14),
                  UnloopCard(
                    child: Column(
                      children: [
                        _PatternRow(
                          icon: Icons.wb_sunny_outlined,
                          title: summary.bestFocusDay == null
                              ? 'Your focus pattern is still forming'
                              : 'Best focus day',
                          value: summary.bestFocusDay == null
                              ? 'Keep sessions small'
                              : DateTimeUtils.friendlyDate(
                                  summary.bestFocusDay!,
                                ),
                        ),
                        const Divider(height: 27),
                        _PatternRow(
                          icon: Icons.schedule_rounded,
                          title: 'Strongest focus time',
                          value: summary.bestFocusTimeLabel,
                        ),
                        const Divider(height: 27),
                        _PatternRow(
                          icon: Icons.front_hand_outlined,
                          title: 'Conscious app choices',
                          value: '${summary.urgeOpenEvents} after a pause',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(19),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(
                        alpha: 0.64,
                      ),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.lightbulb_outline_rounded,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'A gentle suggestion',
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 5),
                              Text(viewModel.suggestion),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  SectionHeader(
                    title: 'Recent focus',
                    subtitle: viewModel.recentSessions.isEmpty
                        ? 'Completed sessions will remain here'
                        : 'Your history is never deleted automatically',
                  ),
                  const SizedBox(height: 14),
                  if (viewModel.recentSessions.isEmpty)
                    UnloopCard(
                      child: EmptyState(
                        icon: Icons.self_improvement_rounded,
                        title: 'A blank page is okay',
                        message: 'Start when it feels useful. Even one minute becomes part of your local history.',
                        actionLabel: 'Start a focus session',
                        onAction: () {},
                      ),
                    )
                  else
                    UnloopCard(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      child: Column(
                        children: [
                          for (
                            var index = 0;
                            index < viewModel.recentSessions.length;
                            index++
                          ) ...[
                            _SessionRow(
                              session: viewModel.recentSessions[index],
                            ),
                            if (index < viewModel.recentSessions.length - 1)
                              const Divider(indent: 18, endIndent: 18),
                          ],
                        ],
                      ),
                    ),
                  if (viewModel.errorMessage != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      viewModel.errorMessage!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyHero extends StatelessWidget {
  const _WeeklyHero({required this.viewModel});

  final InsightsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final summary = viewModel.summary;
    final theme = Theme.of(context);
    return UnloopCard(
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.58),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              Icons.insights_rounded,
              color: theme.colorScheme.onPrimary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('This week', style: theme.textTheme.titleLarge),
                const SizedBox(height: 5),
                Text(
                  '${Formatters.minutes(summary.totalFocusMinutes)} focused across ${summary.completedSessions} sessions.',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          if (viewModel.isLoading)
            const SizedBox.square(
              dimension: 22,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
        ],
      ),
    );
  }
}

class _InsightMetric extends StatelessWidget {
  const _InsightMetric({
    required this.label,
    required this.value,
    required this.detail,
  });

  final String label;
  final String value;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return UnloopCard(
      padding: const EdgeInsets.all(17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 3),
          Text(
            detail,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyChart extends StatelessWidget {
  const _WeeklyChart({required this.days});

  final List<dynamic> days;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxValue = days.fold<int>(0, (current, day) {
      final value = math.max(
        day.distractingMinutes as int,
        day.focusMinutes as int,
      );
      return math.max(current, value);
    });
    final maxY = math.max(30.0, (maxValue * 1.25).ceilToDouble());
    return BarChart(
      BarChartData(
        minY: 0,
        maxY: maxY,
        alignment: BarChartAlignment.spaceAround,
        barTouchData: BarTouchData(enabled: false),
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: math.max(10, maxY / 3),
          getDrawingHorizontalLine: (value) => FlLine(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.52),
            strokeWidth: 1,
            dashArray: [4, 5],
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 34,
              interval: math.max(10, maxY / 3),
              getTitlesWidget: (value, meta) => Text(
                value.toInt().toString(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= days.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    DateTimeUtils.shortWeekday(days[index].date as DateTime),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: List.generate(days.length, (index) {
          final day = days[index];
          return BarChartGroupData(
            x: index,
            barsSpace: 3,
            barRods: [
              BarChartRodData(
                toY: (day.distractingMinutes as int).toDouble(),
                width: 7,
                color: theme.colorScheme.tertiary,
                borderRadius: BorderRadius.circular(5),
              ),
              BarChartRodData(
                toY: (day.focusMinutes as int).toDouble(),
                width: 7,
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(5),
              ),
            ],
          );
        }),
      ),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _PatternRow extends StatelessWidget {
  const _PatternRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary),
        const SizedBox(width: 13),
        Expanded(child: Text(title, style: theme.textTheme.bodyMedium)),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: theme.textTheme.labelLarge,
          ),
        ),
      ],
    );
  }
}

class _SessionRow extends StatelessWidget {
  const _SessionRow({required this.session});

  final FocusSession session;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completed = session.status == FocusSessionStatus.completed;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: completed
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          completed ? Icons.check_rounded : Icons.pause_rounded,
          color: completed ? theme.colorScheme.primary : null,
        ),
      ),
      title: Text(session.intention),
      subtitle: Text(
        '${DateTimeUtils.friendlyDate(session.startTime)} · ${session.status.label}',
      ),
      trailing: Text(
        Formatters.minutes(session.completedDuration.inMinutes),
        style: theme.textTheme.labelLarge,
      ),
    );
  }
}
