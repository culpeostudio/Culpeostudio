import 'package:flutter/material.dart';

// Gemeinsame Formatierhelfer des Marktplatzes.

// Hilfsfunktion: formatiert eine Byte-Groesse lesbarer (KB/MB/GB).
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
