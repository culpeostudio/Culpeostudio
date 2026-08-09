import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import './dark_theme.dart';

class AppColors {
  AppColors._();

  /// Primary (Buttons, Active Nav, Avatar): Culpeo Rust (#C1440E)
  static const Color primary = DarkColors.primary;
  static Color get primaryColor => DarkColors.primary;

  /// Hover-Zustände & Glows: Ember Orange (#F2762E)
  static const Color hoverGlow = DarkColors.hoverGlow;
  static Color get hoverGlowColor => DarkColors.hoverGlow;

  /// Akzente: Andes Sand (#E8DCC8)
  static const Color accentColor = DarkColors.accent;
  static Color get accent => DarkColors.accent;

  /// Primary color alias for backward compatibility
  static const Color gold = DarkColors.primary;

  static const Color obsidianSurface = DarkColors.surface;

  /// Background (bg): #0D0D0E
  static Color get bg => DarkColors.bg;

  /// Surface (surface): #1B1B1C
  static Color get surface => DarkColors.surface;

  /// Sidebar (rail): #060607
  static Color get rail => DarkColors.rail;

  /// Text (Bone White): #FAF7F2
  static Color get textPrimary => DarkColors.textPrimary;
  static Color get textSecondary => DarkColors.textSecondary;
  static Color get divider => DarkColors.divider;

  static String get edition => DarkColors.editionLabel;
}

class AppFonts {
  AppFonts._();

  static TextStyle serifItalic({
    double fontSize = 26,
    Color? color,
    FontWeight fontWeight = FontWeight.w500,
  }) => GoogleFonts.playfairDisplay(
    fontSize: fontSize,
    fontStyle: FontStyle.italic,
    fontWeight: fontWeight,
    color: color,
  );

  static TextStyle mono({
    double fontSize = 11,
    Color? color,
    FontWeight fontWeight = FontWeight.w600,
    double letterSpacing = 1.2,
  }) => GoogleFonts.jetBrainsMono(
    fontSize: fontSize,
    fontWeight: fontWeight,
    letterSpacing: letterSpacing,
    color: color,
  );

  static TextStyle navigation({
    double fontSize = 14,
    Color? color,
    FontWeight fontWeight = FontWeight.w500,
  }) => GoogleFonts.manrope(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
  );
}
