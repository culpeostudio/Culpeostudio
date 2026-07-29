import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dark_theme.dart';

/// Design tokens for the permanent Obsidian dark theme.
///
/// The optional brightness parameters preserve callers that read the ambient
/// theme, while all values intentionally resolve to the single dark palette.
class AppColors {
  AppColors._();

  /// Shared bright gold accent.
  static const Color gold = DarkColors.accent;

  static Color accent(Brightness _) => DarkColors.accent;

  // Surface alias referenced by the ColorScheme in main.dart's ThemeData.
  static const Color obsidianSurface = DarkColors.surface;

  static Color bg(Brightness _) => DarkColors.bg;
  static Color surface(Brightness _) => DarkColors.surface;
  static Color rail(Brightness _) => DarkColors.rail;
  static Color textPrimary(Brightness _) => DarkColors.textPrimary;
  static Color textSecondary(Brightness _) => DarkColors.textSecondary;
  static Color divider(Brightness _) => DarkColors.divider;

  /// Edition label for the content title bar.
  static String edition(Brightness _) => DarkColors.editionLabel;
}

/// Shared application typography.
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

  /// Restrained, highly legible type for navigation labels.
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
