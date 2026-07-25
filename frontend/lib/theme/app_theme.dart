import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dark_theme.dart';
import 'light_theme.dart';

/// Router for the "Obsidian / Alabaster" design tokens.
///
/// The actual colour values live in [DarkColors] (dark_theme.dart) and
/// [LightColors] (light_theme.dart) — edit those files to restyle a theme.
/// This class just picks the right one based on the current [Brightness].
class AppColors {
  AppColors._();

  /// Shared bright gold accent (dark-mode value). Kept for widgets that
  /// reference a single accent regardless of theme.
  static const Color gold = DarkColors.accent;
  static const Color goldMuted = LightColors.accent;

  /// Theme-aware accent (gold): brighter on dark, deeper on light.
  static Color accent(Brightness b) =>
      b == Brightness.dark ? DarkColors.accent : LightColors.accent;

  // Surface-Aliase, referenziert vom ColorScheme in main.dart's ThemeData.
  static const Color obsidianSurface = DarkColors.surface;
  static const Color alabasterSurface = LightColors.surface;

  static Color bg(Brightness b) =>
      b == Brightness.dark ? DarkColors.bg : LightColors.bg;
  static Color surface(Brightness b) =>
      b == Brightness.dark ? DarkColors.surface : LightColors.surface;
  static Color rail(Brightness b) =>
      b == Brightness.dark ? DarkColors.rail : LightColors.rail;
  static Color textPrimary(Brightness b) =>
      b == Brightness.dark ? DarkColors.textPrimary : LightColors.textPrimary;
  static Color textSecondary(Brightness b) => b == Brightness.dark
      ? DarkColors.textSecondary
      : LightColors.textSecondary;
  static Color divider(Brightness b) =>
      b == Brightness.dark ? DarkColors.divider : LightColors.divider;

  /// Edition label for the content title bar.
  static String edition(Brightness b) =>
      b == Brightness.dark ? DarkColors.editionLabel : LightColors.editionLabel;
}

/// Shared typography (both themes use the same families).
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
