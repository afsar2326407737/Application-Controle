import 'dart:io';

import 'package:flutter/services.dart';

import '../../core/constants/app_constants.dart';
import '../models/app_info.dart';
import '../models/usage_record.dart';

class AndroidUsageDataSource {
  const AndroidUsageDataSource();

  static const MethodChannel _channel = MethodChannel(AppConstants.channelId);

  Future<bool> hasUsageAccess() async {
    if (!Platform.isAndroid) return false;
    try {
      return await _channel.invokeMethod<bool>('hasUsageAccess') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<void> openUsageAccessSettings() =>
      _invokeVoid('openUsageAccessSettings');

  Future<void> openDigitalWellbeingSettings() =>
      _invokeVoid('openDigitalWellbeingSettings');

  Future<List<AppInfo>> getInstalledApps() async {
    if (!Platform.isAndroid) return _knownApps;
    try {
      final raw = await _channel.invokeMethod<List<Object?>>(
        'getInstalledApps',
      );
      if (raw == null) return _knownApps;
      final apps = raw
          .whereType<Map<Object?, Object?>>()
          .map(AppInfo.fromMap)
          .where((app) => app.packageName.isNotEmpty)
          .toList();
      return apps.isEmpty ? _knownApps : apps;
    } on PlatformException {
      return _knownApps;
    } on MissingPluginException {
      return _knownApps;
    }
  }

  /// Returns `null` when Android could not provide a trustworthy result. An
  /// empty list means the query succeeded and no foreground usage was found.
  Future<List<UsageRecord>?> getUsageForRange(int days) async {
    if (!Platform.isAndroid || days <= 0) return null;
    try {
      final raw = await _channel.invokeMethod<List<Object?>>(
        'getUsageForRange',
        {'days': days},
      );
      if (raw == null) return null;
      return raw
          .whereType<Map<Object?, Object?>>()
          .map(UsageRecord.fromPlatform)
          .where((record) => record.duration > Duration.zero)
          .toList();
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  Future<bool> openApplication(String packageName) async {
    if (!Platform.isAndroid || packageName.isEmpty) return false;
    try {
      return await _channel.invokeMethod<bool>('openApplication', {
            'packageName': packageName,
          }) ??
          false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<Map<String, Object?>?> consumePendingBlockerEvent() async {
    if (!Platform.isAndroid) return null;
    try {
      final raw = await _channel.invokeMethod<Map<Object?, Object?>>(
        'consumePendingBlockerEvent',
      );
      return raw?.cast<String, Object?>();
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  Future<void> _invokeVoid(String method) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>(method);
    } on PlatformException {
      return;
    } on MissingPluginException {
      return;
    }
  }

  static const _knownApps = <AppInfo>[
    AppInfo(packageName: 'com.google.android.youtube', displayName: 'YouTube'),
    AppInfo(packageName: 'com.instagram.android', displayName: 'Instagram'),
    AppInfo(packageName: 'com.zhiliaoapp.musically', displayName: 'TikTok'),
    AppInfo(packageName: 'com.facebook.katana', displayName: 'Facebook'),
    AppInfo(packageName: 'com.twitter.android', displayName: 'X'),
  ];
}
