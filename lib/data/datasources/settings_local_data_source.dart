import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_settings.dart';

class SettingsLocalDataSource {
  SettingsLocalDataSource(this._preferences);

  static const _settingsKey = 'user_settings_v1';
  static const _activeSessionKey = 'active_focus_session_v1';
  static const _urgeDraftKey = 'urge_draft_v1';

  final SharedPreferences _preferences;

  UserSettings load() {
    final value = _preferences.getString(_settingsKey);
    if (value == null) return const UserSettings();
    try {
      return UserSettings.decode(value);
    } on FormatException {
      return const UserSettings();
    }
  }

  Future<void> save(UserSettings settings) async {
    await _preferences.setString(_settingsKey, settings.encode());
  }

  Future<void> clear() async {
    await _preferences.remove(_settingsKey);
    await _preferences.remove(_activeSessionKey);
    await _preferences.remove(_urgeDraftKey);
  }

  Map<String, Object?>? getActiveSession() {
    final value = _preferences.getString(_activeSessionKey);
    if (value == null) return null;
    try {
      return (jsonDecode(value) as Map).cast<String, Object?>();
    } on FormatException {
      return null;
    }
  }

  Future<void> saveActiveSession(Map<String, Object?> session) async {
    await _preferences.setString(_activeSessionKey, jsonEncode(session));
  }

  Future<void> clearActiveSession() async {
    await _preferences.remove(_activeSessionKey);
  }

  Map<String, Object?>? getUrgeDraft() {
    final value = _preferences.getString(_urgeDraftKey);
    if (value == null) return null;
    try {
      return (jsonDecode(value) as Map).cast<String, Object?>();
    } on FormatException {
      return null;
    }
  }

  Future<void> saveUrgeDraft(Map<String, Object?> draft) async {
    await _preferences.setString(_urgeDraftKey, jsonEncode(draft));
  }

  Future<void> clearUrgeDraft() async {
    await _preferences.remove(_urgeDraftKey);
  }
}
