import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Flat, calm backdrop matching the "Obsidian / Alabaster" mockups.
/// Dark = deep coal black, light = warm alabaster. A very soft radial
/// vignette keeps it from looking dead-flat without distracting from content.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final base = AppColors.bg(brightness);
    final isDark = brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(-0.2, -0.6),
          radius: 1.4,
          colors: isDark
              ? [
                  const Color(0xFF121214),
                  base,
                  const Color(0xFF060607),
                ]
              : [
                  const Color(0xFFFFFFFF),
                  base,
                  const Color(0xFFF1ECE4),
                ],
          stops: const [0.0, 0.55, 1.0],
        ),
      ),
    );
  }
}
