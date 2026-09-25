import 'dart:convert';

enum AppMode { coach, personalBlocker }

extension AppModeLabel on AppMode {
  String get label => this == AppMode.coach ? 'Coach Mode' : 'Personal Blocker';
}

class UserSettings {
  const UserSettings({
    this.onboardingComplete = false,
    this.displayName = '',
    this.primaryDistraction = 'Short videos',
    this.preferredMode = AppMode.coach,
    this.dailyLimitMinutes = 120,
    this.focusTargetMinutes = 50,
    this.defaultFocusMinutes = 25,
    this.remindersEnabled = true,
    this.reminderHour = 20,
    this.reminderMinute = 0,
    this.quietStartHour = 22,
    this.quietEndHour = 7,
    this.notificationsEnabled = true,
    this.themeModeName = 'system',
    this.selectedPackages = const <String>[],
    this.selectedAppNames = const <String, String>{},
    this.blockerEnabled = false,
    this.usageAccessPrompted = false,
  });

  final bool onboardingComplete;
  final String displayName;
  final String primaryDistraction;
  final AppMode preferredMode;
  final int dailyLimitMinutes;
  final int focusTargetMinutes;
  final int defaultFocusMinutes;
  final bool remindersEnabled;
  final int reminderHour;
  final int reminderMinute;
  final int quietStartHour;
  final int quietEndHour;
  final bool notificationsEnabled;
  final String themeModeName;
  final List<String> selectedPackages;
  final Map<String, String> selectedAppNames;
  final bool blockerEnabled;
  final bool usageAccessPrompted;

  UserSettings copyWith({
    bool? onboardingComplete,
    String? displayName,
    String? primaryDistraction,
    AppMode? preferredMode,
    int? dailyLimitMinutes,
    int? focusTargetMinutes,
    int? defaultFocusMinutes,
    bool? remindersEnabled,
    int? reminderHour,
    int? reminderMinute,
    int? quietStartHour,
    int? quietEndHour,
    bool? notificationsEnabled,
    String? themeModeName,
    List<String>? selectedPackages,
    Map<String, String>? selectedAppNames,
    bool? blockerEnabled,
    bool? usageAccessPrompted,
  }) {
    return UserSettings(
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      displayName: displayName ?? this.displayName,
      primaryDistraction: primaryDistraction ?? this.primaryDistraction,
      preferredMode: preferredMode ?? this.preferredMode,
      dailyLimitMinutes: dailyLimitMinutes ?? this.dailyLimitMinutes,
      focusTargetMinutes: focusTargetMinutes ?? this.focusTargetMinutes,
      defaultFocusMinutes: defaultFocusMinutes ?? this.defaultFocusMinutes,
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      quietStartHour: quietStartHour ?? this.quietStartHour,
      quietEndHour: quietEndHour ?? this.quietEndHour,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      themeModeName: themeModeName ?? this.themeModeName,
      selectedPackages: selectedPackages ?? this.selectedPackages,
      selectedAppNames: selectedAppNames ?? this.selectedAppNames,
      blockerEnabled: blockerEnabled ?? this.blockerEnabled,
      usageAccessPrompted: usageAccessPrompted ?? this.usageAccessPrompted,
    );
  }

  Map<String, Object?> toJson() => {
    'onboardingComplete': onboardingComplete,
    'displayName': displayName,
    'primaryDistraction': primaryDistraction,
    'preferredMode': preferredMode.name,
    'dailyLimitMinutes': dailyLimitMinutes,
    'focusTargetMinutes': focusTargetMinutes,
    'defaultFocusMinutes': defaultFocusMinutes,
    'remindersEnabled': remindersEnabled,
    'reminderHour': reminderHour,
    'reminderMinute': reminderMinute,
    'quietStartHour': quietStartHour,
    'quietEndHour': quietEndHour,
    'notificationsEnabled': notificationsEnabled,
    'themeModeName': themeModeName,
    'selectedPackages': selectedPackages,
    'selectedAppNames': selectedAppNames,
    'blockerEnabled': blockerEnabled,
    'usageAccessPrompted': usageAccessPrompted,
  };

  factory UserSettings.fromJson(Map<String, Object?> json) {
    final rawPackages = json['selectedPackages'];
    final rawNames = json['selectedAppNames'];
    return UserSettings(
      onboardingComplete: json['onboardingComplete'] as bool? ?? false,
      displayName: json['displayName'] as String? ?? '',
      primaryDistraction:
          json['primaryDistraction'] as String? ?? 'Short videos',
      preferredMode: AppMode.values.firstWhere(
        (value) => value.name == json['preferredMode'],
        orElse: () => AppMode.coach,
      ),
      dailyLimitMinutes: json['dailyLimitMinutes'] as int? ?? 120,
      focusTargetMinutes: json['focusTargetMinutes'] as int? ?? 50,
      defaultFocusMinutes: json['defaultFocusMinutes'] as int? ?? 25,
      remindersEnabled: json['remindersEnabled'] as bool? ?? true,
      reminderHour: json['reminderHour'] as int? ?? 20,
      reminderMinute: json['reminderMinute'] as int? ?? 0,
      quietStartHour: json['quietStartHour'] as int? ?? 22,
      quietEndHour: json['quietEndHour'] as int? ?? 7,
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      themeModeName: json['themeModeName'] as String? ?? 'system',
      selectedPackages: rawPackages is List
          ? rawPackages.whereType<String>().toList()
          : const <String>[],
      selectedAppNames: rawNames is Map
          ? rawNames.map(
              (key, value) => MapEntry(key.toString(), value.toString()),
            )
          : const <String, String>{},
      blockerEnabled: json['blockerEnabled'] as bool? ?? false,
      usageAccessPrompted: json['usageAccessPrompted'] as bool? ?? false,
    );
  }

  String encode() => jsonEncode(toJson());

  factory UserSettings.decode(String value) {
    final decoded = jsonDecode(value);
    if (decoded is! Map) {
      throw const FormatException('Settings must be a JSON object.');
    }
    return UserSettings.fromJson(decoded.cast<String, Object?>());
  }
}
