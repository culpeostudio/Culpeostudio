import 'package:flutter/material.dart';

/// ALABASTER — light theme palette.
/// Edit these values to restyle light mode. Colours only; fonts live in
/// [AppFonts] (app_theme.dart) and are shared across both themes.
class LightColors {
  LightColors._();

  /// Gold accent (slightly deeper than dark mode for contrast on white).
  static const Color accent = Color(0xFFA8873D);

  /// App backdrop (content workspace).
  static const Color bg = Color(0xFFFAF8F4);

  /// Raised surfaces: cards, inputs, dialogs.
  static const Color surface = Color(0xFFFFFFFF);

  /// The navigation rail / sidebar.
  static const Color rail = Color(0xFFFFFFFF);

  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B6B6B);

  /// Hairline borders and separators.
  static final Color divider = Colors.black.withValues(alpha: 0.08);

  /// Label shown on the right of the content title bar.
  static const String editionLabel = 'Raw Alabaster Edition';
}
