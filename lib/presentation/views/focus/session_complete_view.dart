import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/formatters.dart';
import '../../viewmodels/focus_view_model.dart';
import '../../widgets/unloop_card.dart';

class SessionCompleteView extends StatelessWidget {
  const SessionCompleteView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<FocusViewModel>();
    final session = viewModel.completedSession;
    final theme = Theme.of(context);
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              children: [
                const Spacer(),
                Container(
                  width: 128,
                  height: 128,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.primaryContainer,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.spa_rounded,
                        size: 58,
                        color: theme.colorScheme.primary,
                      ),
                      const Positioned(
                        right: 22,
                        top: 22,
                        child: Icon(Icons.auto_awesome_rounded, size: 20),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 34),
                Text(
                  'You made some room.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.displaySmall,
                ),
                const SizedBox(height: 12),
                Text(
                  'That is enough for now. Let the rest of the day meet you as it is.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 28),
                UnloopCard(
                  child: Column(
                    children: [
                      _CompletionRow(
                        label: 'Intention',
                        value: session?.intention ?? 'Focus',
                      ),
                      const Divider(height: 26),
                      _CompletionRow(
                        label: 'Time protected',
                        value: Formatters.duration(
                          session?.completedDuration ?? Duration.zero,
                          compact: true,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: () {
                    viewModel.acknowledgeCompletion();
                    context.go('/');
                  },
                  icon: const Icon(Icons.home_rounded),
                  label: const Text('Return to today'),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    viewModel.acknowledgeCompletion();
                    context.go('/insights');
                  },
                  child: const Text('See my progress'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CompletionRow extends StatelessWidget {
  const _CompletionRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Text(value, style: Theme.of(context).textTheme.titleLarge),
      ],
    );
  }
}
