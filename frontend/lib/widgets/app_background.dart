import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Flat, calm backdrop for the permanent Obsidian dark theme.
/// A soft radial vignette keeps it from looking dead-flat without distracting
/// from content.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final base = AppColors.bg(Brightness.dark);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(-0.2, -0.6),
          radius: 1.4,
          colors: [const Color(0xFF121214), base, const Color(0xFF060607)],
          stops: const [0.0, 0.55, 1.0],
        ),
      ),
    );
  }
}
