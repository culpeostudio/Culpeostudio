import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dark_theme.dart';

class AppColors {
  AppColors._();

  static const Color gold = DarkColors.accent;

  static Color accent(Brightness _) => DarkColors.accent;

  static const Color obsidianSurface = DarkColors.surface;

  static Color bg(Brightness _) => DarkColors.bg;
  static Color surface(Brightness _) => DarkColors.surface;
  static Color rail(Brightness _) => DarkColors.rail;
  static Color textPrimary(Brightness _) => DarkColors.textPrimary;
  static Color textSecondary(Brightness _) => DarkColors.textSecondary;
  static Color divider(Brightness _) => DarkColors.divider;

  static String edition(Brightness _) => DarkColors.editionLabel;
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
