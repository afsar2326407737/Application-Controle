import 'package:flutter/material.dart';

import '../../data/models/user_settings.dart';
import '../../data/repositories/settings_repository.dart';
import '../../core/services/blocker_service.dart';
import '../../core/services/reminder_scheduler.dart';

class AppViewModel extends ChangeNotifier {
  AppViewModel({
    required SettingsRepository settingsRepository,
    required ReminderScheduler reminderScheduler,
    required BlockerService blockerService,
  }) : _settingsRepository = settingsRepository,
       _reminderScheduler = reminderScheduler,
       _blockerService = blockerService;

  final SettingsRepository _settingsRepository;
  final ReminderScheduler _reminderScheduler;
  final BlockerService _blockerService;

  UserSettings _settings = const UserSettings();
  bool _isReady = false;
  String? _errorMessage;

  UserSettings get settings => _settings;
  bool get isReady => _isReady;
  String? get errorMessage => _errorMessage;

  ThemeMode get themeMode => switch (_settings.themeModeName) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };

  Future<void> initialize() async {
    try {
      _settings = _settingsRepository.load();
    } on Object {
      _settings = const UserSettings();
      _errorMessage = 'Your settings could not be read, so defaults were used.';
    } finally {
      _isReady = true;
      notifyListeners();
    }
  }

  Future<void> updateSettings(UserSettings settings) async {
    _settings = settings;
    notifyListeners();
    try {
      await _settingsRepository.save(settings);
      await _reminderScheduler.schedule(settings);
      if (settings.preferredMode == AppMode.personalBlocker &&
          settings.blockerEnabled) {
        await _blockerService.setEnabled(true, settings.selectedPackages);
      } else if (!settings.blockerEnabled) {
        await _blockerService.setEnabled(false, const []);
      }
    } on Object {
      _errorMessage = 'That preference is visible now but could not be saved.';
      notifyListeners();
    }
  }

  Future<void> reset() async {
    await _settingsRepository.clear();
    _settings = const UserSettings();
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
