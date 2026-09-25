import 'package:flutter/material.dart';

class BreathingOrb extends StatefulWidget {
  const BreathingOrb({super.key, this.isActive = true});

  final bool isActive;

  @override
  State<BreathingOrb> createState() => _BreathingOrbState();
}

class _BreathingOrbState extends State<BreathingOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );
    _scale = Tween<double>(begin: 0.78, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
    if (widget.isActive) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant BreathingOrb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isActive && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) {
          return Transform.scale(scale: _scale.value, child: child);
        },
        child: Container(
          width: 184,
          height: 184,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                scheme.primaryContainer,
                scheme.secondaryContainer.withValues(alpha: 0.65),
                scheme.surface.withValues(alpha: 0.2),
              ],
              stops: const [0, 0.68, 1],
            ),
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withValues(alpha: 0.14),
                blurRadius: 46,
                spreadRadius: 8,
              ),
            ],
          ),
          child: Icon(
            Icons.air_rounded,
            size: 54,
            color: scheme.onPrimaryContainer.withValues(alpha: 0.66),
          ),
        ),
      ),
    );
  }
}
