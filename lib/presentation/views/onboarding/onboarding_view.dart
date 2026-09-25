import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/notification_service.dart';
import '../../../data/models/user_settings.dart';
import '../../../data/repositories/settings_repository.dart';
import '../../../data/repositories/usage_repository.dart';
import '../../viewmodels/app_view_model.dart';
import '../../viewmodels/onboarding_view_model.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/app_selection_list.dart';
import '../../widgets/permission_card.dart';

class OnboardingView extends StatelessWidget {
  const OnboardingView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => OnboardingViewModel(
        settingsRepository: context.read<SettingsRepository>(),
        usageRepository: context.read<UsageRepository>(),
        appViewModel: context.read<AppViewModel>(),
        notificationService: context.read<NotificationService>(),
      )..load(),
      child: const _OnboardingContent(),
    );
  }
}

class _OnboardingContent extends StatefulWidget {
  const _OnboardingContent();

  @override
  State<_OnboardingContent> createState() => _OnboardingContentState();
}

class _OnboardingContentState extends State<_OnboardingContent>
    with WidgetsBindingObserver {
  final _pageController = PageController();
  int _page = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<OnboardingViewModel>().refreshPermissionStatus();
    }
  }

  void _next() {
    if (_page < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    final success = await context
        .read<OnboardingViewModel>()
        .completeOnboarding();
    if (success && mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<OnboardingViewModel>();
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 10, 22, 8),
              child: Row(
                children: [
                  const AppLogo(compact: true),
                  const Spacer(),
                  Text(
                    '${_page + 1} of 5',
                    style: Theme.of(context).textTheme.labelLarge
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Row(
                children: List.generate(
                  5,
                  (index) => Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      height: 4,
                      margin: EdgeInsets.only(right: index == 4 ? 0 : 6),
                      decoration: BoxDecoration(
                        color: index <= _page
                            ? scheme.primary
                            : scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (value) => setState(() => _page = value),
                children: [
                  const _WelcomePage(),
                  const _PlanPage(),
                  const _AppsPage(),
                  const _PermissionsPage(),
                  const _ModePage(),
                ],
              ),
            ),
            if (viewModel.errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Text(
                  viewModel.errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: scheme.error),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 10, 22, 18),
              child: Row(
                children: [
                  if (_page > 0)
                    IconButton.outlined(
                      onPressed: () => _pageController.previousPage(
                        duration: const Duration(milliseconds: 360),
                        curve: Curves.easeOutCubic,
                      ),
                      icon: const Icon(Icons.arrow_back_rounded),
                      tooltip: 'Back',
                    )
                  else
                    const SizedBox(width: 48),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _page == 4 && viewModel.isSaving
                          ? null
                          : _next,
                      child: _page == 4
                          ? (viewModel.isSaving
                                ? const SizedBox.square(
                                    dimension: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Text('Create my plan'))
                          : const Text('Continue'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageBody extends StatelessWidget {
  const _PageBody({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.sizeOf(context).height * 0.58,
        ),
        child: child,
      ),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return _PageBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 22),
          Center(
            child: Container(
              width: 168,
              height: 168,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.primaryContainer,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 112,
                    height: 112,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: scheme.surface.withValues(alpha: 0.8),
                    ),
                  ),
                  Icon(Icons.spa_rounded, size: 62, color: scheme.primary),
                ],
              ),
            ),
          ),
          const SizedBox(height: 42),
          Text(
            'Make a little\nroom to breathe.',
            style: theme.textTheme.displaySmall,
          ),
          const SizedBox(height: 16),
          Text(
            AppConstants.appTagline,
            style: theme.textTheme.titleMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 30),
          const _PromiseRow(
            icon: Icons.visibility_outlined,
            text: 'Understand your habits without judgment',
          ),
          const SizedBox(height: 14),
          const _PromiseRow(
            icon: Icons.self_improvement_rounded,
            text: 'Make focus feel small, calm, and possible',
          ),
          const SizedBox(height: 14),
          const _PromiseRow(
            icon: Icons.lock_outline_rounded,
            text: 'Keep every detail on this device',
          ),
        ],
      ),
    );
  }
}

class _PromiseRow extends StatelessWidget {
  const _PromiseRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: scheme.secondaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: scheme.onSecondaryContainer),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
        ),
      ],
    );
  }
}

class _PlanPage extends StatelessWidget {
  const _PlanPage();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<OnboardingViewModel>();
    final theme = Theme.of(context);
    return _PageBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Start with a gentle plan',
            style: theme.textTheme.headlineLarge,
          ),
          const SizedBox(height: 10),
          Text(
            'Everything here can change later.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 28),
          TextField(
            onChanged: viewModel.setDisplayName,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'What should we call you? (optional)',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: viewModel.primaryDistraction,
            decoration: const InputDecoration(
              labelText: 'What tends to pull you in?',
              prefixIcon: Icon(Icons.psychology_alt_outlined),
            ),
            items: OnboardingViewModel.distractions
                .map(
                  (value) => DropdownMenuItem(value: value, child: Text(value)),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) viewModel.setPrimaryDistraction(value);
            },
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Daily intention',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              Text(
                '${viewModel.dailyLimitMinutes ~/ 60}h ${viewModel.dailyLimitMinutes % 60}m',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          Slider(
            value: viewModel.dailyLimitMinutes.toDouble(),
            min: 30,
            max: 240,
            divisions: 7,
            label: '${viewModel.dailyLimitMinutes} minutes',
            onChanged: (value) => viewModel.setDailyLimit(value.round()),
          ),
          const SizedBox(height: 18),
          Text('A usual focus pocket', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 9,
            runSpacing: 9,
            children: OnboardingViewModel.focusDurations.map((duration) {
              return ChoiceChip(
                label: Text('$duration min'),
                selected: viewModel.focusMinutes == duration,
                onSelected: (_) => viewModel.setFocusMinutes(duration),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _AppsPage extends StatelessWidget {
  const _AppsPage();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<OnboardingViewModel>();
    final theme = Theme.of(context);
    if (viewModel.isLoadingApps) {
      return const Center(child: CircularProgressIndicator());
    }
    return _PageBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What would you like room from?',
            style: theme.textTheme.headlineLarge,
          ),
          const SizedBox(height: 10),
          Text(
            'Choose any apps that tend to pull you into an unplanned scroll.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 22),
          if (viewModel.availableApps.isEmpty)
            const _NoAppsFound()
          else
            AppSelectionList(
              apps: viewModel.availableApps,
              selectedPackages: viewModel.selectedPackages,
              onToggle: viewModel.toggleApp,
            ),
          const SizedBox(height: 18),
          Text(
            '${viewModel.selectedPackages.length} selected · only package names and time are used',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoAppsFound extends StatelessWidget {
  const _NoAppsFound();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Text(
        'App discovery is unavailable right now. You can still create a plan and choose apps later.',
      ),
    );
  }
}

class _PermissionsPage extends StatelessWidget {
  const _PermissionsPage();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<OnboardingViewModel>();
    final theme = Theme.of(context);
    return _PageBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('You stay in control', style: theme.textTheme.headlineLarge),
          const SizedBox(height: 10),
          Text(
            'Unloop works without every permission. Say no now and you can change your mind in Settings.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 26),
          PermissionCard(
            icon: Icons.query_stats_rounded,
            title: PermissionCopy.usageTitle,
            body: PermissionCopy.usageBody,
            optional: true,
            isGranted: viewModel.hasUsageAccess,
            actionLabel: 'Open Usage Access settings',
            onAction: viewModel.openUsageAccess,
          ),
          const SizedBox(height: 14),
          PermissionCard(
            icon: Icons.notifications_none_rounded,
            title: PermissionCopy.notificationTitle,
            body: PermissionCopy.notificationBody,
            optional: true,
            isGranted: viewModel.notificationsGranted,
            actionLabel: 'Allow notifications',
            onAction: viewModel.requestNotificationPermission,
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.shield_outlined,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'No internet permission, accounts, ads, or analytics identifiers.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModePage extends StatelessWidget {
  const _ModePage();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<OnboardingViewModel>();
    final theme = Theme.of(context);
    return _PageBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Choose your support', style: theme.textTheme.headlineLarge),
          const SizedBox(height: 10),
          Text(
            'Coach Mode is the gentle default. Personal Blocker is optional and reversible.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          _ModeCard(
            icon: Icons.coffee_rounded,
            title: 'Coach Mode',
            description: 'See your patterns, use focus sessions, and follow Android Digital Wellbeing setup when you choose.',
            selected: viewModel.mode == AppMode.coach,
            onTap: () => viewModel.setMode(AppMode.coach),
          ),
          const SizedBox(height: 14),
          _ModeCard(
            icon: Icons.shield_outlined,
            title: 'Personal Blocker',
            description: 'When a selected app opens, return here for a pause. Android asks for accessibility access later.',
            selected: viewModel.mode == AppMode.personalBlocker,
            onTap: () => viewModel.setMode(AppMode.personalBlocker),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: theme.colorScheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.favorite_outline_rounded,
                  color: theme.colorScheme.tertiary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your first plan: ${viewModel.focusMinutes} focused minutes, '
                    '${viewModel.dailyLimitMinutes ~/ 60}h ${viewModel.dailyLimitMinutes % 60}m of distracting app time, and ${viewModel.selectedPackages.length} apps to notice.',
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

class _ModeCard extends StatelessWidget {
  const _ModeCard({
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
    final scheme = theme.colorScheme;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected
            ? scheme.primaryContainer.withValues(alpha: 0.62)
            : scheme.surface,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: selected ? scheme.primary : scheme.outlineVariant,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: selected
                        ? scheme.primary
                        : scheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    icon,
                    color: selected
                        ? scheme.onPrimary
                        : scheme.onSecondaryContainer,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleLarge),
                      const SizedBox(height: 7),
                      Text(
                        description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                  color: selected ? scheme.primary : scheme.outlineVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
