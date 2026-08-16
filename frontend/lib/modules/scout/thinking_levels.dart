import 'package:flutter/material.dart';

class ReasoningProfile {
  final String id;
  final String name;
  final bool mandatory;
  final bool defaultEnabled;
  final List<String> supportedEfforts;
  final String defaultEffort;

  /// Context window in tokens, from the same catalogue entry as the thinking
  /// levels above. Zero when the catalogue does not report one.
  final int contextLength;

  const ReasoningProfile({
    required this.id,
    required this.name,
    required this.mandatory,
    required this.defaultEnabled,
    required this.supportedEfforts,
    required this.defaultEffort,
    this.contextLength = 0,
  });

  factory ReasoningProfile.fromMap(Map<String, dynamic> data) {
    return ReasoningProfile(
      id: data['id']?.toString() ?? '',
      name: data['name']?.toString() ?? '',
      mandatory: data['mandatory'] == true,
      defaultEnabled: data['default_enabled'] == true,
      supportedEfforts: List<String>.from(data['supported_efforts'] ?? []),
      defaultEffort: data['default_effort']?.toString() ?? '',
      contextLength: (data['context_length'] as num?)?.toInt() ?? 0,
    );
  }
}

class ThinkingLevels {
  static const List<String> canonicalOrder = [
    'none',
    'minimal',
    'low',
    'medium',
    'high',
    'xhigh',
    'max',
  ];

  static ReasoningProfile? matchProfile(
    List<ReasoningProfile> profiles,
    String modelName,
  ) {
    final lowerName = modelName.toLowerCase();
    for (final p in profiles) {
      if (lowerName.contains(p.id)) return p;
    }
    return null;
  }

  static List<String> optionsFor(
    List<ReasoningProfile> profiles,
    String modelName,
  ) {
    final profile = matchProfile(profiles, modelName);
    if (profile != null && profile.supportedEfforts.isNotEmpty) {
      final sorted = profile.supportedEfforts.toList()
        ..sort(
          (a, b) =>
              canonicalOrder.indexOf(a).compareTo(canonicalOrder.indexOf(b)),
        );

      if (profile.mandatory) {
        sorted.remove('none');
      }

      if (sorted.isNotEmpty) {
        return sorted;
      }
    }
    return ['none', 'medium', 'max'];
  }

  static String defaultLevelFor(
    List<ReasoningProfile> profiles,
    String modelName,
  ) {
    final profile = matchProfile(profiles, modelName);
    if (profile != null) {
      if (profile.defaultEnabled && profile.defaultEffort.isNotEmpty) {
        return profile.defaultEffort;
      }
      if (profile.mandatory) {
        final sorted = profile.supportedEfforts.toList()
          ..sort(
            (a, b) =>
                canonicalOrder.indexOf(a).compareTo(canonicalOrder.indexOf(b)),
          );
        sorted.remove('none');
        if (sorted.isNotEmpty) return sorted.first;
      }
      return 'none';
    }
    return 'none';
  }

  static String legacyTierFor(String effort) {
    switch (effort) {
      case 'none':
        return 'none';
      case 'xhigh':
      case 'max':
        return 'max';
      default:
        return 'medium';
    }
  }

  static IconData iconDataFor(String level) {
    if (level == 'dual') return Icons.bolt;
    if (level == 'agentic') return Icons.psychology_outlined;
    switch (level) {
      case 'none':
        return Icons.speed;
      case 'minimal':
      case 'low':
        return Icons.lightbulb_outline;
      case 'medium':
        return Icons.psychology;
      case 'high':
      case 'xhigh':
      case 'max':
        return Icons.auto_awesome;
      default:
        return Icons.psychology;
    }
  }

  static String iconFor(String level) {
    if (level == 'dual') return 'bolt';
    if (level == 'agentic') return 'psychology_outlined';
    switch (level) {
      case 'none':
        return 'flash_on';
      case 'minimal':
      case 'low':
        return 'lightbulb';
      case 'medium':
        return 'psychology';
      case 'high':
      case 'xhigh':
      case 'max':
        return 'diamond';
      default:
        return 'psychology';
    }
  }
}
