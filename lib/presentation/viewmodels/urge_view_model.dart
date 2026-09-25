import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/models/urge_log.dart';
import '../../data/repositories/urge_repository.dart';
import '../../data/repositories/usage_repository.dart';

class UrgeViewModel extends ChangeNotifier {
  UrgeViewModel({
    required UrgeRepository urgeRepository,
    required UsageRepository usageRepository,
    required String? packageName,
    required String? appName,
  }) : _urgeRepository = urgeRepository,
       _usageRepository = usageRepository,
       _packageName = packageName,
       _appName = appName;

  final UrgeRepository _urgeRepository;
  final UsageRepository _usageRepository;
  final String? _packageName;
  final String? _appName;

  int _step = 0;
  String? _feeling;
  int _waitMinutes = 10;
  String _alternative = 'Take five slow breaths';
  DateTime? _cooldownEnd;
  Timer? _ticker;
  bool _isSaving = false;

  int get step => _step;
  String? get feeling => _feeling;
  int get waitMinutes => _waitMinutes;
  String get alternative => _alternative;
  String? get packageName => _packageName;
  String? get appName => _appName;
  bool get isSaving => _isSaving;
  bool get canChooseWait => _feeling != null;

  Duration get remaining {
    final end = _cooldownEnd;
    if (end == null) return Duration.zero;
    final remaining = end.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  static const feelings = <String>[
    'Bored',
    'Tired',
    'Curious',
    'Restless',
    'Lonely',
    'Something else',
  ];

  static const alternatives = <String>[
    'Take five slow breaths',
    'Stand up and stretch',
    'Drink some water',
    'Read one page',
    'Write the reason for focusing',
  ];

  Future<void> initialize() async {
    final draft = _urgeRepository.loadDraft();
    if (draft != null) {
      _feeling = draft['feeling'] as String?;
      _waitMinutes = draft['waitMinutes'] as int? ?? 10;
      _alternative = draft['alternative'] as String? ?? alternatives.first;
      final storedEnd = draft['cooldownEnd'] as int?;
      if (storedEnd != null) {
        final end = DateTime.fromMillisecondsSinceEpoch(storedEnd);
        if (end.isAfter(DateTime.now())) {
          _cooldownEnd = end;
          _step = 2;
          _startTicker();
        } else {
          _step = 3;
        }
      }
    }
    notifyListeners();
  }

  void chooseFeeling(String value) {
    _feeling = value;
    _persistDraft();
    notifyListeners();
  }

  void continueFromFeeling() {
    if (_feeling == null) return;
    _step = 1;
    notifyListeners();
  }

  void chooseWait(int value) {
    _waitMinutes = value;
    _persistDraft();
    notifyListeners();
  }

  void chooseAlternative(String value) {
    _alternative = value;
    _persistDraft();
    notifyListeners();
  }

  Future<void> startCooldown() async {
    _cooldownEnd = DateTime.now().add(Duration(minutes: _waitMinutes));
    _step = 2;
    await _persistDraft();
    _startTicker();
    notifyListeners();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (remaining == Duration.zero) {
        _ticker?.cancel();
        _step = 3;
      }
      notifyListeners();
    });
  }

  Future<void> decide(UrgeDecision decision) async {
    if (_isSaving) return;
    _isSaving = true;
    notifyListeners();
    final now = DateTime.now();
    final log = UrgeLog(
      id: now.microsecondsSinceEpoch.toString(),
      timestamp: now,
      feeling: _feeling ?? 'Something else',
      waitMinutes: _waitMinutes,
      alternative: _alternative,
      decision: decision,
    );
    try {
      await _urgeRepository.save(log);
      if (decision == UrgeDecision.openedApp && _packageName != null) {
        await _usageRepository.openApplication(_packageName);
      }
      await _urgeRepository.clearDraft();
      _step = 4;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void decideNow() {
    _ticker?.cancel();
    _cooldownEnd = null;
    _step = 3;
    _persistDraft();
    notifyListeners();
  }

  void reset() {
    _ticker?.cancel();
    _step = 0;
    _feeling = null;
    _cooldownEnd = null;
    _urgeRepository.clearDraft();
    notifyListeners();
  }

  Future<void> _persistDraft() {
    return _urgeRepository.saveDraft({
      'feeling': _feeling,
      'waitMinutes': _waitMinutes,
      'alternative': _alternative,
      'cooldownEnd': _cooldownEnd?.millisecondsSinceEpoch,
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
