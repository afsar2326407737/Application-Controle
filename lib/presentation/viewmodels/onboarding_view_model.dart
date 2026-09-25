import 'package:flutter/foundation.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/notification_service.dart';
import '../../data/models/app_info.dart';
import '../../data/models/user_settings.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/repositories/usage_repository.dart';
import '../viewmodels/app_view_model.dart';

class OnboardingViewModel extends ChangeNotifier {
  OnboardingViewModel({
    required SettingsRepository settingsRepository,
    required UsageRepository usageRepository,
    required AppViewModel appViewModel,
    required NotificationService notificationService,
  }) : _settingsRepository = settingsRepository,
       _usageRepository = usageRepository,
       _appViewModel = appViewModel,
       _notificationService = notificationService;

  final SettingsRepository _settingsRepository;
  final UsageRepository _usageRepository;
  final AppViewModel _appViewModel;
  final NotificationService _notificationService;

  List<AppInfo> _availableApps = const [];
  final Set<String> _selectedPackages = {};
  final Map<String, String> _selectedNames = {};
  String _displayName = '';
  String _primaryDistraction = 'Short videos';
  int _dailyLimitMinutes = 120;
  int _focusMinutes = 25;
  AppMode _mode = AppMode.coach;
  bool _isLoadingApps = false;
  bool _isSaving = false;
  bool _hasUsageAccess = false;
  bool _notificationPermissionRequested = false;
  bool _notificationsGranted = false;
  String? _errorMessage;

  List<AppInfo> get availableApps => _availableApps;
  Set<String> get selectedPackages => Set.unmodifiable(_selectedPackages);
  Map<String, String> get selectedNames => Map.unmodifiable(_selectedNames);
  String get displayName => _displayName;
  String get primaryDistraction => _primaryDistraction;
  int get dailyLimitMinutes => _dailyLimitMinutes;
  int get focusMinutes => _focusMinutes;
  AppMode get mode => _mode;
  bool get isLoadingApps => _isLoadingApps;
  bool get isSaving => _isSaving;
  bool get hasUsageAccess => _hasUsageAccess;
  bool get notificationPermissionRequested => _notificationPermissionRequested;
  bool get notificationsGranted => _notificationsGranted;
  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    _isLoadingApps = true;
    notifyListeners();
    try {
      _hasUsageAccess = await _usageRepository.hasUsageAccess();
      final apps = await _usageRepository.getInstalledApps();
      apps.sort(_sortApps);
      _availableApps = apps;
    } on Object {
      _availableApps = const [];
      _errorMessage = 'App discovery is unavailable. You can continue safely.';
    } finally {
      _isLoadingApps = false;
      notifyListeners();
    }
  }

  int _sortApps(AppInfo first, AppInfo second) {
    const commonPackages = {
      'com.google.android.youtube',
      'com.instagram.android',
      'com.zhiliaoapp.musically',
      'com.facebook.katana',
      'com.twitter.android',
    };
    final firstRank = commonPackages.contains(first.packageName) ? 0 : 1;
    final secondRank = commonPackages.contains(second.packageName) ? 0 : 1;
    if (firstRank != secondRank) return firstRank - secondRank;
    return first.displayName.toLowerCase().compareTo(
      second.displayName.toLowerCase(),
    );
  }

  void setDisplayName(String value) {
    _displayName = value.trimLeft();
    notifyListeners();
  }

  void setPrimaryDistraction(String value) {
    _primaryDistraction = value;
    notifyListeners();
  }

  void setDailyLimit(int value) {
    _dailyLimitMinutes = value;
    notifyListeners();
  }

  void setFocusMinutes(int value) {
    _focusMinutes = value;
    notifyListeners();
  }

  void toggleApp(AppInfo app) {
    if (_selectedPackages.contains(app.packageName)) {
      _selectedPackages.remove(app.packageName);
      _selectedNames.remove(app.packageName);
    } else {
      _selectedPackages.add(app.packageName);
      _selectedNames[app.packageName] = app.displayName;
    }
    notifyListeners();
  }

  void setMode(AppMode value) {
    _mode = value;
    notifyListeners();
  }

  Future<void> openUsageAccess() async {
    await _usageRepository.openUsageAccessSettings();
  }

  Future<void> refreshPermissionStatus() async {
    _hasUsageAccess = await _usageRepository.hasUsageAccess();
    notifyListeners();
  }

  Future<bool> requestNotificationPermission() async {
    _notificationPermissionRequested = true;
    notifyListeners();
    _notificationsGranted = await _notificationService.requestPermission();
    notifyListeners();
    return _notificationsGranted;
  }

  Future<bool> completeOnboarding() async {
    if (_isSaving) return false;
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    final current = _settingsRepository.load();
    final settings = current.copyWith(
      onboardingComplete: true,
      displayName: _displayName.trim(),
      primaryDistraction: _primaryDistraction,
      preferredMode: _mode,
      dailyLimitMinutes: _dailyLimitMinutes,
      defaultFocusMinutes: _focusMinutes,
      focusTargetMinutes: _focusMinutes * 2,
      selectedPackages: _selectedPackages.toList(),
      selectedAppNames: _selectedNames,
      usageAccessPrompted: true,
      notificationsEnabled: _notificationsGranted,
      blockerEnabled: false,
    );
    try {
      await _appViewModel.updateSettings(settings);
      // Keep onboarding usable even if a platform service fails while saving.
      await _settingsRepository.save(settings);
      return true;
    } on Object {
      _errorMessage = 'Your plan could not be saved. Please try once more.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  static const distractions = <String>[
    'Short videos',
    'Social feeds',
    'News',
    'Games',
    'Messaging',
  ];

  static const focusDurations = AppConstants.focusDurations;
}
