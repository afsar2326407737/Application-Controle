import 'dart:io';

import 'package:flutter/services.dart';

import '../constants/app_constants.dart';

class BlockerStatus {
  const BlockerStatus({
    required this.systemEnabled,
    required this.unloopEnabled,
  });

  final bool systemEnabled;
  final bool unloopEnabled;

  bool get isActive => systemEnabled && unloopEnabled;
}

class BlockerService {
  const BlockerService();

  static const MethodChannel _channel = MethodChannel(AppConstants.channelId);

  Future<BlockerStatus> getStatus() async {
    if (!Platform.isAndroid) {
      return const BlockerStatus(systemEnabled: false, unloopEnabled: false);
    }
    try {
      final result =
          await _channel.invokeMethod<Map<Object?, Object?>>(
            'getBlockerStatus',
          ) ??
          const {};
      return BlockerStatus(
        systemEnabled: result['systemEnabled'] as bool? ?? false,
        unloopEnabled: result['unloopEnabled'] as bool? ?? false,
      );
    } on PlatformException {
      return const BlockerStatus(systemEnabled: false, unloopEnabled: false);
    } on MissingPluginException {
      return const BlockerStatus(systemEnabled: false, unloopEnabled: false);
    }
  }

  Future<void> openAccessibilitySettings() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('openAccessibilitySettings');
    } on PlatformException {
      return;
    } on MissingPluginException {
      return;
    }
  }

  Future<void> setEnabled(bool enabled, List<String> packages) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('setBlockerEnabled', {
        'enabled': enabled,
        'packages': packages,
      });
    } on PlatformException {
      return;
    } on MissingPluginException {
      return;
    }
  }
}
