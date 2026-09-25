import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/formatters.dart';
import '../../../data/repositories/urge_repository.dart';
import '../../../data/repositories/usage_repository.dart';
import '../../../data/models/urge_log.dart';
import '../../viewmodels/focus_view_model.dart';
import '../../viewmodels/urge_view_model.dart';
import '../../widgets/breathing_orb.dart';
import '../../widgets/unloop_card.dart';

class UrgeView extends StatelessWidget {
  const UrgeView({super.key, this.packageName, this.appName});

  final String? packageName;
  final String? appName;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => UrgeViewModel(
        urgeRepository: context.read<UrgeRepository>(),
        usageRepository: context.read<UsageRepository>(),
        packageName: packageName,
        appName: appName,
      )..initialize(),
      child: const _UrgeContent(),
    );
  }
}

class _UrgeContent extends StatelessWidget {
  const _UrgeContent();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<UrgeViewModel>();
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            viewModel.reset();
            context.pop();
          },
          icon: const Icon(Icons.close_rounded),
          tooltip: 'Close',
        ),
        title: const Text('A small pause'),
      ),
      body: SafeArea(
        top: false,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          child: switch (viewModel.step) {
            0 => _FeelingStep(viewModel: viewModel),
            1 => _OptionsStep(viewModel: viewModel),
            2 => _CooldownStep(viewModel: viewModel),
            3 => _DecisionStep(viewModel: viewModel),
            _ => _CompleteStep(viewModel: viewModel),
          },
        ),
      ),
    );
  }
}

class _StepBody extends StatelessWidget {
  const _StepBody({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: ValueKey(child.key),
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.sizeOf(context).height * 0.64,
        ),
        child: child,
      ),
    );
  }
}

class _FeelingStep extends StatelessWidget {
  const _FeelingStep({required this.viewModel});

  final UrgeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _StepBody(
      key: const ValueKey('feeling'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What is the pull right now?',
            style: theme.textTheme.headlineLarge,
          ),
          const SizedBox(height: 10),
          Text(
            'Naming it does not commit you to an answer. It just makes this moment a little easier to see.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 28),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: UrgeViewModel.feelings.map((feeling) {
              final selected = viewModel.feeling == feeling;
              return ChoiceChip(
                label: Text(feeling),
                selected: selected,
                avatar: Icon(_feelingIcon(feeling), size: 18),
                onSelected: (_) => viewModel.chooseFeeling(feeling),
              );
            }).toList(),
          ),
          const SizedBox(height: 34),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: viewModel.canChooseWait
                  ? viewModel.continueFromFeeling
                  : null,
              child: const Text('Show me a small alternative'),
            ),
          ),
        ],
      ),
    );
  }

  IconData _feelingIcon(String feeling) => switch (feeling) {
    'Bored' => Icons.hourglass_bottom_rounded,
    'Tired' => Icons.battery_2_bar_rounded,
    'Curious' => Icons.lightbulb_outline_rounded,
    'Restless' => Icons.bolt_rounded,
    'Lonely' => Icons.group_outlined,
    _ => Icons.more_horiz_rounded,
  };
}

class _OptionsStep extends StatelessWidget {
  const _OptionsStep({required this.viewModel});

  final UrgeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _StepBody(
      key: const ValueKey('options'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Could you wait this long?',
            style: theme.textTheme.headlineLarge,
          ),
          const SizedBox(height: 9),
          Text(
            'Any amount counts. You can still choose the app when the pause ends.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [5, 10, 20].map((minutes) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: minutes == 20 ? 0 : 9),
                  child: _WaitCard(
                    minutes: minutes,
                    selected: viewModel.waitMinutes == minutes,
                    onTap: () => viewModel.chooseWait(minutes),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),
          Text('While you wait', style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          UnloopCard(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              children: UrgeViewModel.alternatives.map((alternative) {
                final selected = viewModel.alternative == alternative;
                return ListTile(
                  onTap: () => viewModel.chooseAlternative(alternative),
                  leading: Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    color: selected ? theme.colorScheme.primary : null,
                  ),
                  title: Text(alternative),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: viewModel.startCooldown,
            icon: const Icon(Icons.timer_outlined),
            label: Text('Wait ${viewModel.waitMinutes} minutes'),
          ),
        ],
      ),
    );
  }
}

class _WaitCard extends StatelessWidget {
  const _WaitCard({
    required this.minutes,
    required this.selected,
    required this.onTap,
  });

  final int minutes;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          height: 92,
          decoration: BoxDecoration(
            color: selected
                ? theme.colorScheme.primaryContainer
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('$minutes', style: theme.textTheme.headlineMedium),
              Text('minutes', style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _CooldownStep extends StatelessWidget {
  const _CooldownStep({required this.viewModel});

  final UrgeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _StepBody(
      key: const ValueKey('cooldown'),
      child: Column(
        children: [
          const SizedBox(height: 12),
          const BreathingOrb(),
          const SizedBox(height: 34),
          Text(
            Formatters.duration(viewModel.remaining),
            style: theme.textTheme.displaySmall?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'You do not have to suppress the urge. Just let this minute pass.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 26),
          UnloopCard(
            color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.62),
            child: Row(
              children: [
                Icon(Icons.spa_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 13),
                Expanded(
                  child: Text(
                    viewModel.alternative,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          OutlinedButton(
            onPressed: viewModel.decideNow,
            child: const Text('I am ready to decide now'),
          ),
        ],
      ),
    );
  }
}

class _DecisionStep extends StatelessWidget {
  const _DecisionStep({required this.viewModel});

  final UrgeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _StepBody(
      key: const ValueKey('decision'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('The pause is complete.', style: theme.textTheme.headlineLarge),
          const SizedBox(height: 10),
          Text(
            'What feels true now?',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 28),
          _DecisionCard(
            icon: Icons.self_improvement_rounded,
            title: 'Continue focusing',
            message: 'Stay with the intention you chose a little longer.',
            onTap: () => viewModel.decide(UrgeDecision.continued),
          ),
          const SizedBox(height: 14),
          _DecisionCard(
            icon: Icons.open_in_new_rounded,
            title: viewModel.appName == null
                ? 'Open the app'
                : 'Open ${viewModel.appName}',
            message: 'A conscious choice is still a choice. No punishment, no streak reset.',
            onTap: () => viewModel.decide(UrgeDecision.openedApp),
          ),
          const SizedBox(height: 14),
          TextButton(
            onPressed: viewModel.isSaving
                ? null
                : () => viewModel.decide(UrgeDecision.abandoned),
            child: const Text('I am not sure yet'),
          ),
        ],
      ),
    );
  }
}

class _DecisionCard extends StatelessWidget {
  const _DecisionCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return UnloopCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 5),
                Text(
                  message,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
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

class _CompleteStep extends StatelessWidget {
  const _CompleteStep({required this.viewModel});

  final UrgeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _StepBody(
      key: const ValueKey('complete'),
      child: Column(
        children: [
          const SizedBox(height: 30),
          Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              color: theme.colorScheme.tertiaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.favorite_outline_rounded,
              size: 48,
              color: theme.colorScheme.tertiary,
            ),
          ),
          const SizedBox(height: 30),
          Text(
            'Thanks for pausing.',
            textAlign: TextAlign.center,
            style: theme.textTheme.displaySmall,
          ),
          const SizedBox(height: 12),
          Text(
            'You noticed an urge and stayed with yourself for a little while. That is the whole story.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 30),
          FilledButton.icon(
            onPressed: () {
              if (context.read<FocusViewModel>().activeSession != null) {
                context.go('/focus/active');
              } else {
                context.go('/focus/setup');
              }
            },
            icon: const Icon(Icons.self_improvement_rounded),
            label: const Text('Return to focus'),
          ),
          TextButton(
            onPressed: () => context.go('/'),
            child: const Text('Back to today'),
          ),
        ],
      ),
    );
  }
}
