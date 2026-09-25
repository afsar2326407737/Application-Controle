import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../../data/models/user_settings.dart';
import '../constants/app_constants.dart';
import '../utils/date_time_utils.dart';
import 'notification_service.dart';

@pragma('vm:entry-point')
void unloopBackgroundCallbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName != AppConstants.reminderTask || !Platform.isAndroid) {
      return true;
    }

    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    final preferences = await SharedPreferences.getInstance();
    final settings = UserSettings.decode(
      preferences.getString('user_settings_v1') ??
          const UserSettings().encode(),
    );
    if (!settings.remindersEnabled || !settings.notificationsEnabled) {
      return true;
    }

    final now = DateTime.now();
    if (DateTimeUtils.isWithinQuietHours(
      now,
      startHour: settings.quietStartHour,
      endHour: settings.quietEndHour,
    )) {
      return true;
    }

    final requestedMinutes =
        settings.reminderHour * 60 + settings.reminderMinute;
    final currentMinutes = now.hour * 60 + now.minute;
    final difference = (currentMinutes - requestedMinutes).abs();
    if (difference > 30) return true;

    final today = DateTimeUtils.dayKey(now);
    if (preferences.getString('last_daily_reminder') == today) return true;
    await preferences.setString('last_daily_reminder', today);
    await NotificationService().showDailyReflection();
    return true;
  });
}

class ReminderScheduler {
  const ReminderScheduler();

  Future<void> initialize() async {
    if (!Platform.isAndroid) return;
    try {
      await Workmanager().initialize(unloopBackgroundCallbackDispatcher);
    } on Object {
      // Background reminders are optional. The rest of Unloop remains usable.
    }
  }

  Future<void> schedule(UserSettings settings) async {
    if (!Platform.isAndroid) return;
    try {
      if (!settings.remindersEnabled || !settings.notificationsEnabled) {
        await Workmanager().cancelByUniqueName(AppConstants.reminderWorkName);
        return;
      }
      await Workmanager().registerPeriodicTask(
        AppConstants.reminderWorkName,
        AppConstants.reminderTask,
        frequency: const Duration(days: 1),
        initialDelay: _until(settings.reminderHour, settings.reminderMinute),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
        constraints: Constraints(networkType: NetworkType.notRequired),
      );
    } on Object {
      // OEM battery settings can prevent background work. This must never
      // prevent reminders or other app features from being configured.
    }
  }

  Duration _until(int hour, int minute) {
    final now = DateTime.now();
    var next = DateTime(now.year, now.month, now.day, hour, minute);
    if (!next.isAfter(now)) next = next.add(const Duration(days: 1));
    return next.difference(now);
  }
}
