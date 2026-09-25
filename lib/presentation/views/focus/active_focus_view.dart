import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/formatters.dart';
import '../../viewmodels/focus_view_model.dart';
import '../../widgets/breathing_orb.dart';
import '../../widgets/unloop_card.dart';

class ActiveFocusView extends StatefulWidget {
  const ActiveFocusView({super.key});

  @override
  State<ActiveFocusView> createState() => _ActiveFocusViewState();
}

class _ActiveFocusViewState extends State<ActiveFocusView>
    with WidgetsBindingObserver {
  bool _handlingCompletion = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<FocusViewModel>().initialize();
    }
  }

  Future<void> _confirmEnd() async {
    final end = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.self_improvement_rounded),
        title: const Text('Pause this focus session?'),
        content: const Text(
          'Whatever you completed still counts. Ending early is information, not a failure.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep focusing'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('End session'),
          ),
        ],
      ),
    );
    if (end == true && mounted) {
      await context.read<FocusViewModel>().endEarly();
      if (mounted) context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<FocusViewModel>();
    if (viewModel.completedSession != null && !_handlingCompletion) {
      _handlingCompletion = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/focus/complete');
      });
    }
    final session = viewModel.activeSession;
    if (session == null && viewModel.completedSession == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: () => context.go('/'),
            icon: const Icon(Icons.close_rounded),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.spa_rounded, size: 54),
                const SizedBox(height: 18),
                Text(
                  'No focus session is active',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => context.go('/focus/setup'),
                  child: const Text('Make a little space'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (session == null) return const SizedBox.shrink();
    final paused = session.status.name == 'paused';
    final theme = Theme.of(context);
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: _confirmEnd,
                      icon: const Icon(Icons.close_rounded),
                      tooltip: 'End focus session',
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            paused ? Icons.pause_rounded : Icons.circle,
                            size: paused ? 18 : 9,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 7),
                          Text(
                            paused ? 'Paused' : 'Focusing gently',
                            style: theme.textTheme.labelLarge,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                BreathingOrb(isActive: !paused),
                const SizedBox(height: 34),
                Text(
                  session.intention,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineLarge,
                ),
                const SizedBox(height: 9),
                Text(
                  paused
                      ? 'Take the pause you need.'
                      : 'Nothing to solve right now.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  Formatters.duration(viewModel.remaining),
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${Formatters.duration(viewModel.elapsed)} of ${Formatters.duration(session.plannedDuration)} focused',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 25),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: viewModel.progress,
                    minHeight: 8,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _confirmEnd,
                        child: const Text('End gently'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: paused ? viewModel.resume : viewModel.pause,
                        icon: Icon(
                          paused
                              ? Icons.play_arrow_rounded
                              : Icons.pause_rounded,
                        ),
                        label: Text(paused ? 'Resume' : 'Pause'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                UnloopCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        size: 19,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Your timer is saved on this device and recovers after restarts.',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
