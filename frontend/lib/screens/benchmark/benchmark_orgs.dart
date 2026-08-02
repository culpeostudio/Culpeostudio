import 'package:flutter/material.dart';

class BenchmarkOrgBrand {
  const BenchmarkOrgBrand({required this.color, required this.mark});

  final Color color;

  final String mark;
}

const Map<String, BenchmarkOrgBrand> _orgBrands = {
  'openai': BenchmarkOrgBrand(color: Color(0xFF10A37F), mark: 'OA'),
  'anthropic': BenchmarkOrgBrand(color: Color(0xFFD97757), mark: 'AN'),
  'google': BenchmarkOrgBrand(color: Color(0xFF4285F4), mark: 'GO'),
  'meta': BenchmarkOrgBrand(color: Color(0xFF3B82F6), mark: 'ME'),
  'mistral': BenchmarkOrgBrand(color: Color(0xFFFA500F), mark: 'MI'),
  'deepseek': BenchmarkOrgBrand(color: Color(0xFF4D6BFE), mark: 'DS'),
  'alibaba': BenchmarkOrgBrand(color: Color(0xFF6D5AE6), mark: 'QW'),
  'xai': BenchmarkOrgBrand(color: Color(0xFFB8BFCC), mark: 'XA'),
  'moonshot': BenchmarkOrgBrand(color: Color(0xFF5A7CFF), mark: 'MO'),
  'zhipu': BenchmarkOrgBrand(color: Color(0xFF3859FF), mark: 'ZP'),
  'tencent': BenchmarkOrgBrand(color: Color(0xFF0F7BE0), mark: 'TC'),
  'baidu': BenchmarkOrgBrand(color: Color(0xFF4A52E8), mark: 'BD'),
  'bytedance': BenchmarkOrgBrand(color: Color(0xFF5A78D6), mark: 'BY'),
  'minimax': BenchmarkOrgBrand(color: Color(0xFFE8563F), mark: 'MM'),
  'microsoft': BenchmarkOrgBrand(color: Color(0xFF00A4EF), mark: 'MS'),
  'nvidia': BenchmarkOrgBrand(color: Color(0xFF76B900), mark: 'NV'),
  'amazon': BenchmarkOrgBrand(color: Color(0xFFFF9900), mark: 'AZ'),
  'cohere': BenchmarkOrgBrand(color: Color(0xFFFF7759), mark: 'CO'),
  'ai21': BenchmarkOrgBrand(color: Color(0xFF7B61FF), mark: 'A21'),
  'reka': BenchmarkOrgBrand(color: Color(0xFFE45C9C), mark: 'RK'),
  '01ai': BenchmarkOrgBrand(color: Color(0xFF00B2A9), mark: 'YI'),
  'stepfun': BenchmarkOrgBrand(color: Color(0xFF3B7BFF), mark: 'SF'),
  'allenai': BenchmarkOrgBrand(color: Color(0xFFF0529C), mark: 'AI2'),
  'ibm': BenchmarkOrgBrand(color: Color(0xFF3B82F6), mark: 'IB'),
  'liquid': BenchmarkOrgBrand(color: Color(0xFF00C2A8), mark: 'LQ'),
  'upstage': BenchmarkOrgBrand(color: Color(0xFF7A5CFF), mark: 'UP'),
  'inclusionai': BenchmarkOrgBrand(color: Color(0xFF19A6A0), mark: 'IN'),
  'perplexity': BenchmarkOrgBrand(color: Color(0xFF20B8CD), mark: 'PP'),
  'databricks': BenchmarkOrgBrand(color: Color(0xFFFF5A3C), mark: 'DB'),
  'snowflake': BenchmarkOrgBrand(color: Color(0xFF29B5E8), mark: 'SN'),
  'stability': BenchmarkOrgBrand(color: Color(0xFF9B59F6), mark: 'ST'),
  'tii': BenchmarkOrgBrand(color: Color(0xFF00A19A), mark: 'FA'),
  'nous': BenchmarkOrgBrand(color: Color(0xFFB388FF), mark: 'NO'),
  'eleutherai': BenchmarkOrgBrand(color: Color(0xFF6C7CE8), mark: 'EL'),
  'huggingface': BenchmarkOrgBrand(color: Color(0xFFF5B33C), mark: 'HF'),
};

const Map<String, String> _orgAliases = {
  'meta-llama': 'meta',
  'metaai': 'meta',
  'facebook': 'meta',
  'llama': 'meta',
  'deepseek-ai': 'deepseek',
  'mistralai': 'mistral',
  'qwen': 'alibaba',
  'qwen2': 'alibaba',
  'qwen3': 'alibaba',
  'alibaba-cloud': 'alibaba',
  'alibabacloud': 'alibaba',
  'tongyi': 'alibaba',
  'x-ai': 'xai',
  'grok': 'xai',
  'googledeepmind': 'google',
  'google-deepmind': 'google',
  'deepmind': 'google',
  'gemini': 'google',
  'gemma': 'google',
  'openai-community': 'openai',
  'moonshotai': 'moonshot',
  'kimi': 'moonshot',
  'thudm': 'zhipu',
  'z-ai': 'zhipu',
  'zai': 'zhipu',
  'zai-org': 'zhipu',
  'glm': 'zhipu',
  'hunyuan': 'tencent',
  'tencent-hunyuan': 'tencent',
  'ernie': 'baidu',
  'baidu-ernie': 'baidu',
  'doubao': 'bytedance',
  'seed': 'bytedance',
  'minimaxai': 'minimax',
  'minimax-ai': 'minimax',
  'phi': 'microsoft',
  'nova': 'amazon',
  'amazon-agi': 'amazon',
  'commandr': 'cohere',
  'cohereforai': 'cohere',
  'cohere-labs': 'cohere',
  'ai21labs': 'ai21',
  '01-ai': '01ai',
  '01.ai': '01ai',
  'yi': '01ai',
  'zero-one-ai': '01ai',
  'ai2': 'allenai',
  'allen-institute': 'allenai',
  'liquidai': 'liquid',
  'nousresearch': 'nous',
  'falcon': 'tii',
  'tiiuae': 'tii',
  'granite': 'ibm',
  'ibm-granite': 'ibm',
  'nvidia-nemotron': 'nvidia',
  'nemotron': 'nvidia',
  'solar': 'upstage',
  'inclusion-ai': 'inclusionai',
  'ling': 'inclusionai',
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
  Color(0xFFE08A4A),
];

const Color _neutralOrgColor = Color(0xFFC9A24A);

BenchmarkOrgBrand benchmarkOrgBrand(String org) {
  final raw = org.trim();
  if (raw.isEmpty) {
    return const BenchmarkOrgBrand(color: _neutralOrgColor, mark: '?');
  }

  final key = _normalize(raw);
  final resolved = _orgAliases[key] ?? key;

  final known = _orgBrands[resolved];
  if (known != null) return known;

  for (final entry in _orgAliases.entries) {
    if (resolved.startsWith(entry.key)) {
      final brand = _orgBrands[entry.value];
      if (brand != null) return brand;
    }
  }
  for (final entry in _orgBrands.entries) {
    if (resolved.startsWith(entry.key)) return entry.value;
  }

  var hash = 0;
  for (final unit in resolved.codeUnits) {
    hash = (hash * 31 + unit) & 0x7fffffff;
  }
  return BenchmarkOrgBrand(
    color: _fallbackPalette[hash % _fallbackPalette.length],
    mark: _derivedMark(raw),
  );
}

String _normalize(String value) {
  final buffer = StringBuffer();
  for (final rune in value.toLowerCase().runes) {
    final char = String.fromCharCode(rune);
    if (RegExp(r'[a-z0-9]').hasMatch(char)) buffer.write(char);
  }
  return buffer.toString();
}

String _derivedMark(String org) {
  final words = org
      .trim()
      .split(RegExp(r'[\s._/-]+'))
      .where((word) => word.isNotEmpty)
      .toList();
  if (words.isEmpty) return '?';
  if (words.length >= 2) {
    return (words[0].substring(0, 1) + words[1].substring(0, 1)).toUpperCase();
  }
  final word = words.first;
  return word.substring(0, word.length >= 2 ? 2 : 1).toUpperCase();
}
