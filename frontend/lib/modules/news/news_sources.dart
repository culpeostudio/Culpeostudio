import 'package:flutter/material.dart';

import '../../core/design_tokens.dart';

class NewsSourceBrand {
  const NewsSourceBrand({required this.color, required this.mark});

  final Color color;

  final String mark;
}

const Map<String, NewsSourceBrand> _newsSourceBrands = {
  'openai news': NewsSourceBrand(color: Color(0xFF10A37F), mark: 'OA'),
  'anthropic news': NewsSourceBrand(color: Color(0xFFD97757), mark: 'AN'),
  'google deepmind blog': NewsSourceBrand(color: Color(0xFF4285F4), mark: 'DM'),
  'mistral ai news': NewsSourceBrand(color: Color(0xFFFA500F), mark: 'MI'),
  'hugging face blog': NewsSourceBrand(color: Color(0xFFF5B33C), mark: 'HF'),
  'marktechpost': NewsSourceBrand(color: Color(0xFF9B7BE0), mark: 'MT'),
  "tom's hardware": NewsSourceBrand(color: Color(0xFF4AA3E0), mark: 'TH'),
  'the verge ai': NewsSourceBrand(color: Color(0xFFD96BC0), mark: 'VG'),
  'venturebeat': NewsSourceBrand(color: Color(0xFFC8322B), mark: 'VB'),
  'golem.de': NewsSourceBrand(color: Color(0xFF8CC152), mark: 'GO'),
  'heise online': NewsSourceBrand(color: Color(0xFF6C7CE8), mark: 'HE'),
  'hacker news': NewsSourceBrand(color: Color(0xFFFF6600), mark: 'HN'),
  'videocardz': NewsSourceBrand(color: Color(0xFF3FBFD1), mark: 'VC'),
};

const List<Color> _fallbackPalette = [
  Color(0xFF10A37F),
  Color(0xFFF5B33C),
  Color(0xFF9B7BE0),
  Color(0xFF4AA3E0),
  Color(0xFF3FBFD1),
  Color(0xFFD96BC0),
  Color(0xFFE0574A),
  Color(0xFF8CC152),
  Color(0xFF6C7CE8),
  Color(0xFFFF6600),
];

const Color _neutralSourceColor = CulpeoColors.metric;

NewsSourceBrand newsSourceBrand(String author) {
  final key = author.trim().toLowerCase();
  if (key.isEmpty) {
    return const NewsSourceBrand(color: _neutralSourceColor, mark: '?');
  }

  final known = _newsSourceBrands[key];
  if (known != null) return known;

  var hash = 0;
  for (final unit in key.codeUnits) {
    hash = (hash * 31 + unit) & 0x7fffffff;
  }
  return NewsSourceBrand(
    color: _fallbackPalette[hash % _fallbackPalette.length],
    mark: _derivedMark(author),
  );
}

String _derivedMark(String author) {
  final words = author
      .trim()
      .split(RegExp(r'[\s./-]+'))
      .where((word) => word.isNotEmpty)
      .toList();
  if (words.isEmpty) return '?';
  if (words.length >= 2) {
    return (words[0].substring(0, 1) + words[1].substring(0, 1)).toUpperCase();
  }
  final word = words.first;
  return word.substring(0, word.length >= 2 ? 2 : 1).toUpperCase();
}
