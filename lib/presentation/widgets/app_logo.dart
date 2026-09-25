import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.showName = true, this.compact = false});

  final bool showName;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final size = compact ? 36.0 : 46.0;
    return Semantics(
      label: AppConstants.appName,
      header: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: scheme.primary,
              borderRadius: BorderRadius.circular(size * 0.36),
              boxShadow: [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Icon(
              Icons.spa_rounded,
              size: compact ? 21 : 27,
              color: scheme.onPrimary,
            ),
          ),
          if (showName) ...[
            const SizedBox(width: 12),
            Text(
              AppConstants.appName,
              style:
                  (compact
                          ? Theme.of(context).textTheme.titleLarge
                          : Theme.of(context).textTheme.headlineMedium)
                      ?.copyWith(letterSpacing: -0.6),
            ),
          ],
        ],
      ),
    );
  }
}
