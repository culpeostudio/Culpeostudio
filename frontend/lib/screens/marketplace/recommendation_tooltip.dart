import 'package:flutter/material.dart';

// Tooltip mit der Hardware-Empfehlung zu einem Modell.

class RecommendationTooltip extends StatelessWidget {
  final bool isRecommended;
  final bool isMaxQuality;
  final bool isCompact;

  const RecommendationTooltip({
    super.key,
    required this.isRecommended,
    required this.isMaxQuality,
    required this.isCompact,
  });

  String _body() {
    if (isRecommended) {
      return 'Q4_K_M / Q4_0 ist fuer die meisten User der beste '
          'Kompromiss: ca. 50% der Originalgroesse, aber fast '
          'volle Qualitaet. Laeuft auf fast jeder Hardware.';
    }
    if (isMaxQuality) {
      return 'FP16 / Q8 / Q5_0 behalten fast 100% der Original-'
          'Qualitaet, brauchen aber 2-3x mehr Speicher/RAM. '
          'Nur fuer starke GPUs (24 GB+ VRAM) sinnvoll.';
    }
    if (isCompact) {
      return 'Q2 / Q3 / Q5_K_S sind sehr klein (30-40% Groesse), '
          'aber die Ausgabe-Qualitaet leidet deutlich. Nur wenn '
          'Speicher ganz knapp ist.';
    }
    return 'Keine Empfehlung verfuegbar.';
  }

  Color _color() {
    if (isRecommended) return const Color(0xFF4CAF50);
    if (isMaxQuality) return const Color(0xFF8E7CFF);
    if (isCompact) return const Color(0xFFFFC107);
    return Colors.white70;
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: _body(),
      preferBelow: false,
      padding: const EdgeInsets.all(12),
      textStyle: const TextStyle(fontSize: 11, color: Colors.white),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E24),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _color().withValues(alpha: 0.35)),
      ),
      verticalOffset: 24,
      child: Icon(
        Icons.help_outline_rounded,
        size: 16,
        color: _color().withValues(alpha: 0.6),
      ),
    );
  }
}
