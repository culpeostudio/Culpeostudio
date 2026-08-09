import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/design_tokens.dart';

import '../../core/dark_theme.dart';

class SettingsPalette {
  SettingsPalette._();

  static const Color accent = DarkColors.accent;

  static const Color accentSoft = Color(0xFFEBD9A8);

  static const Color accentMuted = Color(0xFF8C7536);

  static const Color surface = DarkColors.surface;

  static const Color surfaceRaised = CulpeoColors.panel;

  static const Color surfaceInput = Color(0xFF0F0F12);

  static const Color surfaceNavStart = Color(0xFF1B1B24);

  static const Color surfaceNavEnd = Color(0xFF131317);

  static const Color glassBg = Color(0x1A0C0C0F);

  static const Color glassHover = Color(0x2B0D0D12);

  static const Color glassIdle = Color(0x1A09090D);

  static const Color dialogScrim = Color(0xE6121216);

  static const Color dialogInputFill = Color(0xCC09090C);

  static const Color hairline = Color(0x0DFFFFFF);

  static const Color hairlineSoft = Color(0x0AFFFFFF);

  static const Color hairlineStrong = Color(0x1FFFFFFF);

  static const Color dividerLine = Color(0x0FFFFFFF);

  static const Color textPrimary = DarkColors.textPrimary;
  static const Color textSecondary = DarkColors.textSecondary;
  static const Color textMuted = Colors.white54;
  static const Color textFaint = Colors.white38;
  static const Color textVeryFaint = Colors.white30;
  static const Color textHint = Color(0x38FFFFFF);
  static const Color textHintFaint = Color(0x3DFFFFFF);

  static const Color success = Colors.greenAccent;
  static const Color warning = Colors.amberAccent;
  static const Color danger = Colors.redAccent;
  static const Color info = Color(0xFF00C6FF);

  static const Color noteBg = Color(0x14C9A24A);

  static const Color noteBorder = Color(0x59C9A24A);
}

Widget settingsGlassCard({required Widget child, EdgeInsetsGeometry? padding}) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
      child: Container(
        padding: padding ?? const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: SettingsPalette.glassBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: SettingsPalette.hairline, width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: child,
      ),
    ),
  );
}

Widget settingsPhaseNoteBanner({
  required String title,
  required String body,
  IconData icon = Icons.hourglass_top_rounded,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: SettingsPalette.noteBg,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: SettingsPalette.noteBorder, width: 1.0),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: SettingsPalette.accent, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: SettingsPalette.accentSoft,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                body,
                style: const TextStyle(
                  color: SettingsPalette.textMuted,
                  fontSize: 11,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Color customNodeColor(int index) {
  final colors = [
    const Color(0xFF00E676),
    const Color(0xFF00B0FF),
    const Color(0xFFFF9100),
    const Color(0xFFF50057),
    const Color(0xFFD500F9),
    const Color(0xFF00E5FF),
  ];
  return colors[index % colors.length];
}

Widget settingsDialogTextField({
  required TextEditingController controller,
  required String hintText,
  bool obscureText = false,
  Widget? suffixIcon,
}) {
  return TextField(
    controller: controller,
    obscureText: obscureText,
    style: const TextStyle(color: SettingsPalette.textPrimary, fontSize: 14),
    decoration: InputDecoration(
      filled: true,
      fillColor: SettingsPalette.dialogInputFill,
      hintText: hintText,
      hintStyle: const TextStyle(color: SettingsPalette.textHint, fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: SettingsPalette.accent, width: 1.2),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      suffixIcon: suffixIcon,
    ),
  );
}

Widget settingsSpecRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: SettingsPalette.textFaint,
            fontSize: 12,
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: SettingsPalette.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget settingsSkillChip(String label, bool positive) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: positive
          ? SettingsPalette.accent.withValues(alpha: 0.12)
          : SettingsPalette.danger.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: positive
            ? SettingsPalette.accent.withValues(alpha: 0.35)
            : SettingsPalette.danger.withValues(alpha: 0.35),
      ),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: positive ? SettingsPalette.accentSoft : SettingsPalette.danger,
        fontSize: 11,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}
