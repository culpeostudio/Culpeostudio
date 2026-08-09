import 'package:flutter/material.dart';

class DarkColors {
  DarkColors._();

  /// Primary (Buttons, Active Nav, Avatar): Culpeo Rust (#C1440E)
  static const Color primary = Color(0xFFC1440E);

  /// Hover-Zustände & Glows: Ember Orange (#F2762E)
  static const Color hoverGlow = Color(0xFFF2762E);

  /// Akzente: Andes Sand (#E8DCC8)
  static const Color accent = Color(0xFFE8DCC8);

  /// Primary color alias for backward compatibility
  static const Color gold = Color(0xFFC1440E);

  /// Background (bg): #0D0D0E
  static const Color bg = Color(0xFF0D0D0E);

  /// Surface (surface): #1B1B1C
  static const Color surface = Color(0xFF1B1B1C);

  /// Sidebar (rail): #060607
  static const Color rail = Color(0xFF060607);

  /// Text (Bone White): #FAF7F2
  static const Color textPrimary = Color(0xFFFAF7F2);

  /// Text Secondary: Bone White with ~70% opacity
  static const Color textSecondary = Color(0xB3FAF7F2);

  static final Color divider = const Color(0xFFFAF7F2).withValues(alpha: 0.08);

  static const String editionLabel = 'Culpeo Rust Edition';
}
