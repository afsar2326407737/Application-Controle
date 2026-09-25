import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/viewmodels/app_view_model.dart';
import '../../presentation/views/focus/active_focus_view.dart';
import '../../presentation/views/focus/focus_setup_view.dart';
import '../../presentation/views/focus/session_complete_view.dart';
import '../../presentation/views/home/home_shell.dart';
import '../../presentation/views/onboarding/onboarding_view.dart';
import '../../presentation/views/settings/app_selection_view.dart';
import '../../presentation/views/settings/blocker_view.dart';
import '../../presentation/views/settings/permission_education_view.dart';
import '../../presentation/views/settings/privacy_view.dart';
import '../../presentation/views/urge/urge_view.dart';

abstract final class AppRouter {
  static GoRouter create(AppViewModel appViewModel) {
    return GoRouter(
      initialLocation: appViewModel.settings.onboardingComplete
          ? '/'
          : '/onboarding',
      refreshListenable: appViewModel,
      redirect: (context, state) {
        final path = state.uri.path;
        final onboardingComplete = appViewModel.settings.onboardingComplete;
        if (!onboardingComplete && path != '/onboarding') return '/onboarding';
        if (onboardingComplete && path == '/onboarding') return '/';
        return null;
      },
      routes: [
        GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingView()),
        GoRoute(
          path: '/',
          pageBuilder: (_, _) => const NoTransitionPage(child: HomeShell()),
        ),
        GoRoute(
          path: '/insights',
          pageBuilder: (_, _) =>
              const NoTransitionPage(child: HomeShell(initialIndex: 1)),
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (_, _) =>
              const NoTransitionPage(child: HomeShell(initialIndex: 2)),
        ),
        GoRoute(
          path: '/focus/setup',
          builder: (_, _) => const FocusSetupView(),
        ),
        GoRoute(
          path: '/focus/active',
          builder: (_, _) => const ActiveFocusView(),
        ),
        GoRoute(
          path: '/focus/complete',
          builder: (_, _) => const SessionCompleteView(),
        ),
        GoRoute(
          path: '/urge',
          builder: (context, state) {
            final extra = state.extra;
            final arguments = extra is Map ? extra : const <String, Object?>{};
            return UrgeView(
              packageName: arguments['packageName'] as String?,
              appName: arguments['appName'] as String?,
            );
          },
        ),
        GoRoute(
          path: '/settings/apps',
          builder: (_, _) => const AppSelectionView(),
        ),
        GoRoute(
          path: '/settings/blocker',
          builder: (_, _) => const BlockerView(),
        ),
        GoRoute(
          path: '/settings/privacy',
          builder: (_, _) => const PrivacyView(),
        ),
        GoRoute(
          path: '/permissions',
          builder: (_, _) => const PermissionEducationView(),
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.explore_off_outlined, size: 48),
                const SizedBox(height: 16),
                Text(
                  'This page could not be found.',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => context.go('/'),
                  child: const Text('Back to today'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
