import 'dart:ui';

import 'package:flutter/material.dart';

// Zustandslose Bausteine der Einstellungen: Glas-Karte als Rahmen, Eingabe-
// feld fuer die Dialoge, Farbe eines eigenen Nodes, Kennwert-Zeile der
// System-Infos und Status-Chip eines Skills.

Widget settingsGlassCard({required Widget child, EdgeInsetsGeometry? padding}) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
      child: Container(
        padding: padding ?? const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0x1A0C0C0F), // Very sleek translucent dark
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.05),
            width: 1.0,
          ),
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

Color customNodeColor(int index) {
  final colors = [
    const Color(0xFF00E676), // Bright Green
    const Color(0xFF00B0FF), // Bright Blue
    const Color(0xFFFF9100), // Bright Orange
    const Color(0xFFF50057), // Bright Pink
    const Color(0xFFD500F9), // Bright Purple
    const Color(0xFF00E5FF), // Bright Cyan
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
    style: const TextStyle(color: Colors.white, fontSize: 14),
    decoration: InputDecoration(
      filled: true,
      fillColor: const Color(0xCC09090C),
      hintText: hintText,
      hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFC9A24A), width: 1.2),
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
          style: const TextStyle(color: Colors.white38, fontSize: 12),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
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
          ? const Color(0xFFC9A24A).withValues(alpha: 0.12)
          : Colors.redAccent.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: positive
            ? const Color(0xFFC9A24A).withValues(alpha: 0.35)
            : Colors.redAccent.withValues(alpha: 0.35),
      ),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: positive ? const Color(0xFFEBD9A8) : Colors.redAccent,
        fontSize: 11,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}
