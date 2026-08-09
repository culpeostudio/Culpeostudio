import 'package:flutter/material.dart';
import '../core/dark_theme.dart';

/// Animated Walking Culpeo Fox loader widget for Flutter GUI
class WalkingFoxLoader extends StatefulWidget {
  final String statusText;
  final double size;

  const WalkingFoxLoader({
    super.key,
    this.statusText = 'Culpeo Studio arbeitet...',
    this.size = 120.0,
  });

  @override
  State<WalkingFoxLoader> createState() => _WalkingFoxLoaderState();
}

class _WalkingFoxLoaderState extends State<WalkingFoxLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Walking Fox GIF Asset
        SizedBox(
          width: widget.size * 1.6,
          height: widget.size,
          child: Image.asset(
            'assets/culpeo_fox_walk.gif',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                Icons.pets_rounded,
                size: widget.size * 0.6,
                color: DarkColors.primary,
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        // Animated Status Text
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final dots = '.' * ((_controller.value * 4).floor() % 4);
            return Text(
              '${widget.statusText}$dots',
              style: const TextStyle(
                color: DarkColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            );
          },
        ),
      ],
    );
  }
}
