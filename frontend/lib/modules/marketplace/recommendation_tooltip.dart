import 'package:flutter/material.dart';

import './marketplace_detail_strings.dart';

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
      return tr('marketplaceDetail.recommendation.balanced');
    }
    if (isMaxQuality) {
      return tr('marketplaceDetail.recommendation.maxQuality');
    }
    if (isCompact) {
      return tr('marketplaceDetail.recommendation.compact');
    }
    return tr('marketplaceDetail.recommendation.unavailable');
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
