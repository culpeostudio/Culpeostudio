import 'package:flutter/material.dart';

final RegExp _marketplaceQuantizationPattern = RegExp(
  r'^(?:i?q[1-8](?:_[0-9])?(?:_[a-z0-9]{1,3}){0,2}|int[348]|fp(?:8|16|32)|bf16|nf4|gptq|awq)$',
  caseSensitive: false,
);

class MarketplaceQuantizationSummary {
  const MarketplaceQuantizationSummary({
    required this.variants,
    required this.families,
  });

  final List<String> variants;
  final List<String> families;

  bool get isEmpty => variants.isEmpty;

  String get label {
    if (variants.isEmpty) return '';
    if (variants.length == 1) return variants.single;

    final visibleFamilies = families.take(3).toList(growable: false);
    final hiddenVariants = variants.length - visibleFamilies.length;
    return [
      ...visibleFamilies,
      if (hiddenVariants > 0) '+$hiddenVariants',
    ].join(' · ');
  }

  String get tooltip => variants.join(' · ');
}

class MarketplaceQuantizationSummaryTag extends StatelessWidget {
  const MarketplaceQuantizationSummaryTag({super.key, required this.summary});

  final MarketplaceQuantizationSummary summary;

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFFDFC077);
    return Tooltip(
      message: summary.tooltip,

      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: color.withValues(alpha: 0.45)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.tune_rounded, size: 12, color: color),
            const SizedBox(width: 5),
            Text(
              summary.label,
              style: const TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

bool isMarketplaceQuantization(String rawValue) {
  return _marketplaceQuantizationPattern.hasMatch(
    _normalizeMarketplaceQuantization(rawValue),
  );
}

MarketplaceQuantizationSummary summarizeMarketplaceQuantizations(
  Iterable<String> rawValues,
) {
  final variants = <String>[];
  final families = <String>[];
  final seenVariants = <String>{};
  final seenFamilies = <String>{};

  for (final rawValue in rawValues) {
    final normalized = _normalizeMarketplaceQuantization(rawValue);
    if (normalized.isEmpty || !seenVariants.add(normalized)) continue;

    variants.add(_displayMarketplaceQuantization(normalized));
    final family = _marketplaceQuantizationFamily(normalized);
    if (seenFamilies.add(family)) families.add(family);
  }

  return MarketplaceQuantizationSummary(
    variants: List.unmodifiable(variants),
    families: List.unmodifiable(families),
  );
}

List<String> marketplaceNonQuantizationTags(Iterable<String> tags) {
  return [
    for (final tag in tags)
      if (!isMarketplaceQuantization(tag)) tag,
  ];
}

String _normalizeMarketplaceQuantization(String rawValue) {
  var value = rawValue.trim().toLowerCase().replaceAll('-', '_');
  switch (value) {
    case '8bit':
      value = 'int8';
    case '4bit':
      value = 'int4';
    case '3bit':
      value = 'int3';
    case 'q4km':
      value = 'q4_k_m';
    case 'q5km':
      value = 'q5_k_m';
  }
  return value;
}

String _displayMarketplaceQuantization(String normalized) {
  return normalized.toUpperCase();
}

String _marketplaceQuantizationFamily(String normalized) {
  final iqFamily = RegExp(r'^(iq[1-8])').firstMatch(normalized);
  if (iqFamily != null) return iqFamily.group(1)!.toUpperCase();

  final qFamily = RegExp(r'^(q[1-8])').firstMatch(normalized);
  if (qFamily != null) return qFamily.group(1)!.toUpperCase();

  final exactFamily = RegExp(
    r'^(?:int[348]|fp(?:8|16|32)|bf16|nf4|gptq|awq)',
  ).firstMatch(normalized);
  return (exactFamily?.group(0) ?? normalized).toUpperCase();
}

String formatBytes(int bytes) {
  if (bytes <= 0) return '-';
  const unit = 1024;
  if (bytes < unit) return '$bytes B';
  if (bytes < unit * unit) return '${(bytes / unit).toStringAsFixed(1)} KB';
  if (bytes < unit * unit * unit) {
    return '${(bytes / (unit * unit)).toStringAsFixed(1)} MB';
  }
  if (bytes < unit * unit * unit * unit) {
    return '${(bytes / (unit * unit * unit)).toStringAsFixed(2)} GB';
  }
  return '${(bytes / (unit * unit * unit * unit)).toStringAsFixed(2)} TB';
}

Color marketplaceTagColor(String rawTag) {
  final tag = rawTag.toLowerCase().replaceAll('_', '-').trim();
  if (tag.startsWith('q2') || tag.startsWith('q3')) {
    return const Color(0xFFDFC077);
  }
  if (tag.startsWith('q4')) return const Color(0xFF4DD0E1);
  if (tag.startsWith('q5')) return const Color(0xFF81C784);
  if (tag.startsWith('q6') || tag.startsWith('q8') || tag.contains('fp16')) {
    return const Color(0xFFBAA6FF);
  }
  switch (tag) {
    case 'chat':
      return const Color(0xFFDFC077);
    case 'code':
      return const Color(0xFFDFC077);
    case 'reasoning':
      return const Color(0xFFBAA6FF);
    case 'vision':
      return const Color(0xFFF48FB1);
    case 'embedding':
      return const Color(0xFF81C784);
    case 'local':
      return const Color(0xFF4DD0E1);
    case 'api':
      return const Color(0xFFFFD54F);
    case 'long-context':
      return const Color(0xFF80CBC4);
    case 'gguf':
      return const Color(0xFFEBD9A8);
    case 'safetensors':
      return const Color(0xFFEBD9A8);
    default:
      return Colors.white70;
  }
}
