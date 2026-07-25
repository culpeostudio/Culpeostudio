import 'package:flutter/material.dart';

// Vorschau der Filter-Chip-Optik in den Marktplatz-Einstellungen.

class MarketplaceFilterStylePreview extends StatelessWidget {
  const MarketplaceFilterStylePreview({super.key});

  @override
  Widget build(BuildContext context) {
    const chat = Color(0xFFDFC077);
    const code = Color(0xFFDFC077);
    const reasoning = Color(0xFFBAA6FF);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF16161D).withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
      ),
      child: const Wrap(
        spacing: 7,
        runSpacing: 7,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            'Kategorie',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          PreviewFilterChip(label: 'Chat', color: chat, selected: true),
          PreviewFilterChip(label: 'Code', color: code),
          PreviewFilterChip(label: 'Reasoning', color: reasoning),
          PreviewFilterChip(label: 'Vision', color: Color(0xFFF48FB1)),
          PreviewFilterChip(label: 'Nur lokal', color: Color(0xFFFFC107)),
        ],
      ),
    );
  }
}

class PreviewFilterChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;

  const PreviewFilterChip({
    super.key,
    required this.label,
    required this.color,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: selected ? 0.38 : 0.075),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withValues(alpha: selected ? 0.95 : 0.38),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : color.withValues(alpha: 0.86),
          fontSize: 10.5,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }
}

// M17: Kleines Tooltip-Popover fuer die Empfehlung-Badges im
// Download-Option-Picker. Zeigt kurz erklaerend, was "Ausgewogen",
// "Max Qualitaet" oder "Kompakt" konkret fuer den User bedeutet.
