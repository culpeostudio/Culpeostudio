import 'package:flutter/material.dart';

/// OBSIDIAN — dark theme palette.
/// Edit these values to restyle dark mode. Colours only; fonts live in
/// [AppFonts] (app_theme.dart) and are shared across both themes.
class DarkColors {
  DarkColors._();

  /// Gold accent used for active states, highlights and the brand mark.
  static const Color accent = Color(0xFFC9A24A);

  /// App backdrop (content workspace).
  static const Color bg = Color(0xFF0A0A0B);

  /// Raised surfaces: cards, inputs, dialogs.
  static const Color surface = Color(0xFF141414);

  /// The navigation rail / sidebar.
  static const Color rail = Color(0xFF060606);

  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white70;

  /// Hairline borders and separators.
  static final Color divider = Colors.white.withValues(alpha: 0.08);

  /// Label shown on the right of the content title bar.
  static const String editionLabel = 'Raw Obsidian Edition';
}
