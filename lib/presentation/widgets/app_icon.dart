import 'package:flutter/material.dart';

import '../../data/models/app_info.dart';

class AppIcon extends StatelessWidget {
  const AppIcon({required this.app, super.key, this.size = 44});

  final AppInfo app;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bytes = app.iconBytes;
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      alignment: Alignment.center,
      child: bytes != null && bytes.isNotEmpty
          ? Image.memory(
              bytes,
              width: size,
              height: size,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              errorBuilder: (_, _, _) => _fallback(scheme),
            )
          : _fallback(scheme),
    );
  }

  Widget _fallback(ColorScheme scheme) {
    final text = app.displayName.trim();
    return Text(
      text.isEmpty ? '?' : text.characters.first.toUpperCase(),
      style: TextStyle(
        color: scheme.onSecondaryContainer,
        fontSize: size * 0.4,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
