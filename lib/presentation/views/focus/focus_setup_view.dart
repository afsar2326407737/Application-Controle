import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/settings_repository.dart';
import '../../viewmodels/focus_setup_view_model.dart';
import '../../viewmodels/focus_view_model.dart';
import '../../widgets/section_header.dart';
import '../../widgets/unloop_card.dart';

class FocusSetupView extends StatelessWidget {
  const FocusSetupView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => FocusSetupViewModel(
        settingsRepository: context.read<SettingsRepository>(),
        focusViewModel: context.read<FocusViewModel>(),
      )..initialize(),
      child: const _FocusSetupContent(),
    );
  }
}

class _FocusSetupContent extends StatelessWidget {
  const _FocusSetupContent();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<FocusSetupViewModel>();
    final settings = context.read<SettingsRepository>().load();
    final focusViewModel = context.watch<FocusViewModel>();
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Make space to focus'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.close_rounded),
          tooltip: 'Close focus setup',
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Text(
              'What matters for this little while?',
              style: theme.textTheme.headlineLarge,
            ),
            const SizedBox(height: 9),
            Text(
              'A small, specific intention is easier to return to.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 26),
            const SectionHeader(title: 'Duration'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 9,
              runSpacing: 9,
              children: [15, 25, 45, 60].map((minutes) {
                return ChoiceChip(
                  label: Text('$minutes min'),
                  selected: viewModel.durationMinutes == minutes,
                  onSelected: (_) => viewModel.setDuration(minutes),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),
            const SectionHeader(title: 'Intention'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 9,
              runSpacing: 9,
              children: ['Study', 'Work', 'Exercise', 'Reading', 'Custom']
                  .map(
                    (value) => ChoiceChip(
                      label: Text(value),
                      selected: viewModel.intentionType == value,
                      onSelected: (_) => viewModel.setIntentionType(value),
                    ),
                  )
                  .toList(),
            ),
            if (viewModel.intentionType == 'Custom') ...[
              const SizedBox(height: 14),
              TextField(
                autofocus: true,
                onChanged: viewModel.setCustomIntention,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'What are you focusing on?',
                  hintText: 'e.g. Outline the next chapter',
                ),
              ),
            ],
            const SizedBox(height: 28),
            SectionHeader(
              title: 'Apps to set aside',
              subtitle: settings.selectedAppNames.isEmpty
                  ? 'Your selected distracting apps'
                  : '${settings.selectedPackages.length} selected',
            ),
            const SizedBox(height: 12),
            if (settings.selectedPackages.isEmpty)
              UnloopCard(
                child: Text(
                  'No apps are selected yet. This session can still begin and be a useful pause.',
                  style: theme.textTheme.bodyMedium,
                ),
              )
            else
              UnloopCard(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  children: settings.selectedPackages.map((packageName) {
                    final selected = viewModel.packages.contains(packageName);
                    return CheckboxListTile(
                      value: selected,
                      onChanged: (_) => viewModel.togglePackage(packageName),
                      dense: true,
                      title: Text(
                        settings.selectedAppNames[packageName] ?? packageName,
                      ),
                      secondary: selected
                          ? Icon(
                              Icons.check_circle_rounded,
                              color: theme.colorScheme.primary,
                            )
                          : const Icon(Icons.circle_outlined),
                    );
                  }).toList(),
                ),
              ),
            const SizedBox(height: 22),
            UnloopCard(
              child: SwitchListTile.adaptive(
                value: viewModel.strict,
                onChanged: viewModel.setStrict,
                contentPadding: EdgeInsets.zero,
                title: const Text('Gentle reminder mode'),
                subtitle: const Text(
                  'Keep session reminders enabled. Strict mode changes your intention, not access to your emergency exit.',
                ),
                secondary: Icon(
                  viewModel.strict
                      ? Icons.shield_outlined
                      : Icons.favorite_outline_rounded,
                ),
              ),
            ),
            const SizedBox(height: 24),
            UnloopCard(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.62),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ready when you are', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 10),
                  _SummaryRow(label: 'For', value: viewModel.intention),
                  _SummaryRow(
                    label: 'Length',
                    value: '${viewModel.durationMinutes} minutes',
                  ),
                  _SummaryRow(
                    label: 'Apps set aside',
                    value: '${viewModel.packages.length}',
                  ),
                ],
              ),
            ),
            if (viewModel.errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                viewModel.errorMessage!,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ],
            const SizedBox(height: 18),
            if (focusViewModel.activeSession != null)
              FilledButton.icon(
                onPressed: () => context.go('/focus/active'),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Return to active session'),
              )
            else
              FilledButton.icon(
                onPressed: !viewModel.canStart || viewModel.isStarting
                    ? null
                    : () async {
                        final started = await viewModel.start();
                        if (started && context.mounted) {
                          context.go('/focus/active');
                        }
                      },
                icon: viewModel.isStarting
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.self_improvement_rounded),
                label: const Text('Begin focus session'),
              ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.labelLarge,
            ),
          ),
        ],
      ),
    );
  }
}
