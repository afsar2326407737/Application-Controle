import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/services/app_database.dart';
import '../../core/services/blocker_service.dart';
import '../../core/services/data_export_service.dart';
import '../../core/services/notification_service.dart';
import '../../data/datasources/usage_local_data_source.dart';
import '../../data/models/app_info.dart';
import '../../data/models/user_settings.dart';
import '../../data/repositories/focus_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/repositories/urge_repository.dart';
import '../../data/repositories/usage_repository.dart';
import 'app_view_model.dart';

class SettingsViewModel extends ChangeNotifier {
  SettingsViewModel({
    required AppViewModel appViewModel,
    required SettingsRepository settingsRepository,
    required UsageRepository usageRepository,
    required UsageLocalDataSource usageLocalDataSource,
    required FocusRepository focusRepository,
    required UrgeRepository urgeRepository,
    required AppDatabase appDatabase,
    required BlockerService blockerService,
    required NotificationService notificationService,
    required DataExportService exportService,
  }) : _appViewModel = appViewModel,
       _settingsRepository = settingsRepository,
       _usageRepository = usageRepository,
       _usageLocalDataSource = usageLocalDataSource,
       _focusRepository = focusRepository,
       _urgeRepository = urgeRepository,
       _appDatabase = appDatabase,
       _blockerService = blockerService,
       _notificationService = notificationService,
       _exportService = exportService;

  final AppViewModel _appViewModel;
  final SettingsRepository _settingsRepository;
  final UsageRepository _usageRepository;
  final UsageLocalDataSource _usageLocalDataSource;
  final FocusRepository _focusRepository;
  final UrgeRepository _urgeRepository;
  final AppDatabase _appDatabase;
  final BlockerService _blockerService;
  final NotificationService _notificationService;
  final DataExportService _exportService;

  List<AppInfo> _availableApps = const [];
  BlockerStatus _blockerStatus = const BlockerStatus(
    systemEnabled: false,
    unloopEnabled: false,
  );
  bool _isBusy = false;
  bool _isLoadingApps = false;
  bool _hasNotificationPermission = false;
  String? _errorMessage;

  List<AppInfo> get availableApps => _availableApps;
  BlockerStatus get blockerStatus => _blockerStatus;
  bool get isBusy => _isBusy;
  bool get isLoadingApps => _isLoadingApps;
  bool get hasNotificationPermission => _hasNotificationPermission;
  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    try {
      _hasNotificationPermission = await _notificationService.hasPermission();
      _blockerStatus = await _blockerService.getStatus();
      notifyListeners();
    } on Object {
      _errorMessage = 'Some permission status could not be checked.';
      notifyListeners();
    }
  }

  Future<void> loadApps() async {
    _isLoadingApps = true;
    notifyListeners();
    _availableApps = await _usageRepository.getInstalledApps();
    _isLoadingApps = false;
    notifyListeners();
  }

  Future<void> setDailyLimit(int value) =>
      _update(_appViewModel.settings.copyWith(dailyLimitMinutes: value));

  Future<void> setDefaultFocus(int value) =>
      _update(_appViewModel.settings.copyWith(defaultFocusMinutes: value));

  Future<void> setReminders(bool value) =>
      _update(_appViewModel.settings.copyWith(remindersEnabled: value));

  Future<void> setNotifications(bool value) async {
    if (value) {
      final granted = await _notificationService.requestPermission();
      _hasNotificationPermission = granted;
      if (!granted) {
        _errorMessage = 'Notifications are still off. You can enable them in Android settings.';
        notifyListeners();
      }
    } else {
      _hasNotificationPermission = false;
    }
    await _update(_appViewModel.settings.copyWith(notificationsEnabled: value));
  }

  Future<void> setReminderTime(int hour, int minute) => _update(
    _appViewModel.settings.copyWith(reminderHour: hour, reminderMinute: minute),
  );

  Future<void> setQuietHours(int start, int end) => _update(
    _appViewModel.settings.copyWith(quietStartHour: start, quietEndHour: end),
  );

  Future<void> setThemeMode(ThemeMode mode) => _update(
    _appViewModel.settings.copyWith(
      themeModeName: switch (mode) {
        ThemeMode.system => 'system',
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
      },
    ),
  );

  Future<void> setMode(AppMode mode) async {
    if (mode == AppMode.personalBlocker) {
      await openAccessibilitySettings();
    }
    await _update(_appViewModel.settings.copyWith(preferredMode: mode));
  }

  Future<void> setSelectedApps(
    Set<String> packages,
    Map<String, String> names,
  ) => _update(
    _appViewModel.settings.copyWith(
      selectedPackages: packages.toList(),
      selectedAppNames: names,
      blockerEnabled:
          _appViewModel.settings.preferredMode == AppMode.personalBlocker &&
          _appViewModel.settings.blockerEnabled,
    ),
  );

  Future<void> setBlockerEnabled(bool value) async {
    final settings = _appViewModel.settings;
    if (value && settings.selectedPackages.isEmpty) {
      _errorMessage = 'Choose at least one app before enabling the redirect.';
      notifyListeners();
      return;
    }
    await _update(settings.copyWith(blockerEnabled: value));
    _blockerStatus = await _blockerService.getStatus();
    notifyListeners();
  }

  Future<void> openAccessibilitySettings() =>
      _blockerService.openAccessibilitySettings();

  Future<void> openUsageSettings() =>
      _usageRepository.openUsageAccessSettings();

  Future<File> createExport() => _exportService.createExport(
    settingsRepository: _settingsRepository,
    usageDataSource: _usageLocalDataSource,
    focusRepository: _focusRepository,
    urgeRepository: _urgeRepository,
  );

  Future<void> shareExport({Rect? origin}) async {
    final file = await createExport();
    await _exportService.shareFile(file, origin: origin);
  }

  Future<void> clearAllData() async {
    _isBusy = true;
    notifyListeners();
    try {
      await _blockerService.setEnabled(false, const []);
      await _appDatabase.clearUserData();
      await _appViewModel.reset();
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> _update(UserSettings settings) async {
    _isBusy = true;
    notifyListeners();
    await _appViewModel.updateSettings(settings);
    _isBusy = false;
    notifyListeners();
  }
}
