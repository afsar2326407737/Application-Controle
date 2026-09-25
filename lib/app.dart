import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/constants/app_constants.dart';
import 'core/routing/app_router.dart';
import 'core/services/app_database.dart';
import 'core/services/blocker_service.dart';
import 'core/services/data_export_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/reminder_scheduler.dart';
import 'core/theme/app_theme.dart';
import 'data/datasources/android_usage_data_source.dart';
import 'data/datasources/daily_goal_local_data_source.dart';
import 'data/datasources/focus_local_data_source.dart';
import 'data/datasources/settings_local_data_source.dart';
import 'data/datasources/urge_local_data_source.dart';
import 'data/datasources/usage_local_data_source.dart';
import 'data/repositories/focus_repository.dart';
import 'data/repositories/settings_repository.dart';
import 'data/repositories/urge_repository.dart';
import 'data/repositories/usage_repository.dart';
import 'presentation/viewmodels/app_view_model.dart';
import 'presentation/viewmodels/dashboard_view_model.dart';
import 'presentation/viewmodels/focus_view_model.dart';
import 'presentation/viewmodels/insights_view_model.dart';
import 'presentation/viewmodels/settings_view_model.dart';
import 'presentation/widgets/app_logo.dart';

class UnloopBootstrap extends StatefulWidget {
  const UnloopBootstrap({super.key});

  @override
  State<UnloopBootstrap> createState() => _UnloopBootstrapState();
}

class _UnloopBootstrapState extends State<UnloopBootstrap> {
  late Future<_AppDependencies> _dependencies = _createDependencies();

  Future<_AppDependencies> _createDependencies() async {
    final preferences = await SharedPreferences.getInstance();
    final database = AppDatabase();
    await database.database;
    final settingsSource = SettingsLocalDataSource(preferences);
    final settingsRepository = SettingsRepository(settingsSource);
    final usageSource = UsageLocalDataSource(database);
    final androidUsageSource = const AndroidUsageDataSource();
    final usageRepository = UsageRepository(usageSource, androidUsageSource);
    final focusRepository = FocusRepository(
      FocusLocalDataSource(database),
      settingsSource,
    );
    final urgeRepository = UrgeRepository(
      UrgeLocalDataSource(database),
      settingsSource,
    );
    final notificationService = NotificationService();
    final reminderScheduler = const ReminderScheduler();
    const blockerService = BlockerService();
    await reminderScheduler.initialize();
    await notificationService.initialize();

    final appViewModel = AppViewModel(
      settingsRepository: settingsRepository,
      reminderScheduler: reminderScheduler,
      blockerService: blockerService,
    );
    await appViewModel.initialize();
    await reminderScheduler.schedule(appViewModel.settings);

    return _AppDependencies(
      database: database,
      usageLocalDataSource: usageSource,
      settingsRepository: settingsRepository,
      usageRepository: usageRepository,
      focusRepository: focusRepository,
      urgeRepository: urgeRepository,
      notificationService: notificationService,
      blockerService: blockerService,
      appViewModel: appViewModel,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_AppDependencies>(
      future: _dependencies,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return _DependencyScope(dependencies: snapshot.requireData);
        }
        if (snapshot.hasError) {
          return _BootstrapError(
            onRetry: () {
              setState(() {
                _dependencies = _createDependencies();
              });
            },
          );
        }
        return const _BootstrapSplash();
      },
    );
  }
}

class _DependencyScope extends StatelessWidget {
  const _DependencyScope({required this.dependencies});

  final _AppDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AppDatabase>.value(value: dependencies.database),
        Provider<UsageLocalDataSource>.value(
          value: dependencies.usageLocalDataSource,
        ),
        Provider<DailyGoalLocalDataSource>(
          create: (_) => DailyGoalLocalDataSource(dependencies.database),
        ),
        Provider<SettingsRepository>.value(
          value: dependencies.settingsRepository,
        ),
        Provider<UsageRepository>.value(value: dependencies.usageRepository),
        Provider<FocusRepository>.value(value: dependencies.focusRepository),
        Provider<UrgeRepository>.value(value: dependencies.urgeRepository),
        Provider<NotificationService>.value(
          value: dependencies.notificationService,
        ),
        Provider<BlockerService>.value(value: dependencies.blockerService),
        Provider<DataExportService>(create: (_) => const DataExportService()),
        ChangeNotifierProvider<AppViewModel>.value(
          value: dependencies.appViewModel,
        ),
        ChangeNotifierProvider(
          create: (context) => FocusViewModel(
            focusRepository: dependencies.focusRepository,
            notificationService: dependencies.notificationService,
          )..initialize(),
        ),
        ChangeNotifierProvider(
          create: (context) => DashboardViewModel(
            usageRepository: dependencies.usageRepository,
            focusRepository: dependencies.focusRepository,
            appViewModel: dependencies.appViewModel,
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => InsightsViewModel(
            usageRepository: dependencies.usageRepository,
            focusRepository: dependencies.focusRepository,
            urgeRepository: dependencies.urgeRepository,
            appViewModel: dependencies.appViewModel,
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => SettingsViewModel(
            appViewModel: dependencies.appViewModel,
            settingsRepository: dependencies.settingsRepository,
            usageRepository: dependencies.usageRepository,
            usageLocalDataSource: dependencies.usageLocalDataSource,
            focusRepository: dependencies.focusRepository,
            urgeRepository: dependencies.urgeRepository,
            appDatabase: dependencies.database,
            blockerService: dependencies.blockerService,
            notificationService: dependencies.notificationService,
            exportService: const DataExportService(),
          ),
        ),
      ],
      child: UnloopApp(
        appViewModel: dependencies.appViewModel,
        usageRepository: dependencies.usageRepository,
      ),
    );
  }
}

class UnloopApp extends StatefulWidget {
  const UnloopApp({
    required this.appViewModel,
    required this.usageRepository,
    super.key,
  });

  final AppViewModel appViewModel;
  final UsageRepository usageRepository;

  @override
  State<UnloopApp> createState() => _UnloopAppState();
}

class _UnloopAppState extends State<UnloopApp> with WidgetsBindingObserver {
  late final GoRouter _router = AppRouter.create(widget.appViewModel);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _consumeBlockerRedirect();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _router.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _consumeBlockerRedirect();
      });
    }
  }

  Future<void> _consumeBlockerRedirect() async {
    final event = await widget.usageRepository.consumePendingBlockerEvent();
    if (!mounted || event == null) return;
    if (!widget.appViewModel.settings.onboardingComplete) return;
    await _router.push('/urge', extra: event);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: AppConstants.appName,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: widget.appViewModel.themeMode,
      routerConfig: _router,
    );
  }
}

class _BootstrapSplash extends StatelessWidget {
  const _BootstrapSplash();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppLogo(),
              SizedBox(height: 28),
              SizedBox.square(
                dimension: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BootstrapError extends StatelessWidget {
  const _BootstrapError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AppLogo(),
                  const SizedBox(height: 24),
                  Text(
                    'Unloop could not open its private storage.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'No data was uploaded. Restarting the local setup usually helps.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: onRetry,
                    child: const Text('Try again'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AppDependencies {
  const _AppDependencies({
    required this.database,
    required this.usageLocalDataSource,
    required this.settingsRepository,
    required this.usageRepository,
    required this.focusRepository,
    required this.urgeRepository,
    required this.notificationService,
    required this.blockerService,
    required this.appViewModel,
  });

  final AppDatabase database;
  final UsageLocalDataSource usageLocalDataSource;
  final SettingsRepository settingsRepository;
  final UsageRepository usageRepository;
  final FocusRepository focusRepository;
  final UrgeRepository urgeRepository;
  final NotificationService notificationService;
  final BlockerService blockerService;
  final AppViewModel appViewModel;
}
