import 'package:flutter/foundation.dart';

import '../../data/repositories/settings_repository.dart';
import 'focus_view_model.dart';

class FocusSetupViewModel extends ChangeNotifier {
  FocusSetupViewModel({
    required SettingsRepository settingsRepository,
    required FocusViewModel focusViewModel,
  }) : _settingsRepository = settingsRepository,
       _focusViewModel = focusViewModel;

  final SettingsRepository _settingsRepository;
  final FocusViewModel _focusViewModel;

  int _durationMinutes = 25;
  String _intentionType = 'Study';
  String _customIntention = '';
  final Set<String> _packages = {};
  bool _strict = false;
  bool _isStarting = false;
  bool _isReady = false;
  String? _errorMessage;

  int get durationMinutes => _durationMinutes;
  String get intentionType => _intentionType;
  String get customIntention => _customIntention;
  Set<String> get packages => Set.unmodifiable(_packages);
  bool get strict => _strict;
  bool get isStarting => _isStarting;
  bool get isReady => _isReady;
  String? get errorMessage => _errorMessage;

  String get intention =>
      _intentionType == 'Custom' ? _customIntention.trim() : _intentionType;

  Future<void> initialize() async {
    final settings = _settingsRepository.load();
    _durationMinutes = settings.defaultFocusMinutes;
    _packages.addAll(settings.selectedPackages);
    _isReady = true;
    notifyListeners();
  }

  void setDuration(int value) {
    _durationMinutes = value;
    notifyListeners();
  }

  void setIntentionType(String value) {
    _intentionType = value;
    notifyListeners();
  }

  void setCustomIntention(String value) {
    _customIntention = value;
    notifyListeners();
  }

  void togglePackage(String packageName) {
    if (!_packages.remove(packageName)) _packages.add(packageName);
    notifyListeners();
  }

  void setStrict(bool value) {
    _strict = value;
    notifyListeners();
  }

  bool get canStart => intention.trim().isNotEmpty;

  Future<bool> start() async {
    if (!canStart || _isStarting) return false;
    _isStarting = true;
    _errorMessage = null;
    notifyListeners();
    final started = await _focusViewModel.start(
      minutes: _durationMinutes,
      intention: intention,
      avoidedPackages: _packages.toList(),
      isStrict: _strict,
    );
    _isStarting = false;
    if (!started) {
      _errorMessage = 'The session could not be started. Please try again.';
    }
    notifyListeners();
    return started;
  }
}
