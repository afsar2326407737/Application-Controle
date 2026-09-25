import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  NotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  bool get isSupported => Platform.isAndroid;

  Future<void> initialize() async {
    if (!isSupported || _initialized) return;
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _plugin.initialize(settings: settings);
    _initialized = true;
  }

  Future<bool> requestPermission() async {
    if (!isSupported) return false;
    await initialize();
    final status = await Permission.notification.status;
    if (status.isGranted) return true;
    if (status.isPermanentlyDenied || status.isRestricted) {
      await openSystemSettings();
      return false;
    }
    final result = await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    if (result != null) return result;
    return (await Permission.notification.request()).isGranted;
  }

  Future<bool> hasPermission() async {
    if (!isSupported) return false;
    await initialize();
    return (await Permission.notification.status).isGranted;
  }

  Future<void> openSystemSettings() async {
    if (isSupported) await openAppSettings();
  }

  Future<void> showFocusStarted({
    required String intention,
    required int minutes,
  }) async {
    await initialize();
    await _show(
      id: 100,
      title: 'A quiet pocket of time',
      body: '$minutes minutes for $intention. You can pause whenever you need.',
      channelId: 'focus_sessions',
      channelName: 'Focus sessions',
      importance: Importance.low,
    );
  }

  Future<void> showFocusCompleted({
    required Duration focused,
    required String intention,
  }) async {
    await initialize();
    await _show(
      id: 101,
      title: 'Focus complete',
      body:
          '${focused.inMinutes} minutes of $intention. Let that be enough for now.',
      channelId: 'focus_sessions',
      channelName: 'Focus sessions',
      importance: Importance.high,
    );
  }

  Future<void> showDailyReflection() async {
    await initialize();
    await _show(
      id: 102,
      title: 'A moment to notice',
      body: 'See how today felt, without needing to change it.',
      channelId: 'daily_reflections',
      channelName: 'Daily reflections',
      importance: Importance.defaultImportance,
    );
  }

  Future<void> _show({
    required int id,
    required String title,
    required String body,
    required String channelId,
    required String channelName,
    required Importance importance,
  }) async {
    if (!isSupported) return;
    try {
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelName,
            channelDescription: 'Private, on-device Unloop reminders',
            importance: importance,
            priority: importance == Importance.high
                ? Priority.high
                : Priority.defaultPriority,
            onlyAlertOnce: true,
          ),
        ),
        payload: channelId,
      );
    } on Object catch (error) {
      if (kDebugMode) debugPrint('Notification skipped: $error');
    }
  }
}
