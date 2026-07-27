import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/chat_aux_strings.dart';

/// A small, native chart surface rendered from a `visual` Markdown fence.
///
/// Example:
/// ```visual
/// {"type":"bar","title":"Umsatz","labels":["Jan","Feb"],"values":[12,19]}
/// ```
class ChatVisualBlock extends StatelessWidget {
  const ChatVisualBlock({
    super.key,
    required this.source,
    this.accentColor = const Color(0xFF3E88E5),
  });

  final String source;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final data = _decodeVisual(source);
    if (data == null) return _invalidBlock();

    final type = (data['type']?.toString() ?? 'bar').toLowerCase();
    final title =
        data['title']?.toString() ?? tr('chatAux.visual.defaultTitle');
    final subtitle = data['subtitle']?.toString();
    final labels = _strings(data['labels']);
    final values = _numbers(data['values']);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (subtitle?.isNotEmpty == true) ...[
            const SizedBox(height: 3),
            Text(
              subtitle!,
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ],
          const SizedBox(height: 14),
          switch (type) {
            'line' => _chart(_LineChartPainter(values, accentColor)),
            'donut' || 'pie' => _chart(_DonutChartPainter(values, accentColor)),
            'flow' || 'process' => _flow(data),
            'metric' || 'kpi' => _metric(data, values),
            'column' => _chart(_BarChartPainter(values, accentColor)),
            _ => _chart(
              _HorizontalBarChartPainter(values, labels, accentColor),
              height: math.max(160, values.length * 64.0 + 32),
            ),
          },
          if (labels.isNotEmpty &&
              type != 'bar' &&
              type != 'flow' &&
              type != 'process') ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 4,
              children: List.generate(
                math.min(labels.length, math.max(values.length, 1)),
                (index) => Text(
                  '${labels[index]}${index < values.length ? '  ${_format(values[index])}' : ''}',
                  style: const TextStyle(color: Colors.white60, fontSize: 11),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _chart(CustomPainter painter, {double height = 150}) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: painter),
    );
  }

  Widget _flow(Map<String, dynamic> data) {
    final nodes = _strings(data['nodes']);
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      runSpacing: 8,
      children: [
        for (var index = 0; index < nodes.length; index++) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: accentColor.withValues(alpha: 0.28)),
            ),
            child: Text(
              nodes[index],
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
          if (index < nodes.length - 1)
            Icon(Icons.arrow_forward_rounded, size: 15, color: accentColor),
        ],
      ],
    );
  }

  Widget _metric(Map<String, dynamic> data, List<double> values) {
    final value =
        data['value']?.toString() ??
        (values.isNotEmpty ? _format(values.first) : '–');
    final unit = data['unit']?.toString() ?? '';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          value,
          style: TextStyle(
            color: accentColor,
            fontSize: 38,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
        if (unit.isNotEmpty) ...[
          const SizedBox(width: 6),
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Text(
              unit,
              style: const TextStyle(color: Colors.white60, fontSize: 14),
            ),
          ),
        ],
      ],
    );
  }

  Widget _invalidBlock() => Container(
    margin: const EdgeInsets.symmetric(vertical: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.red.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
    ),
    child: Text(
      tr('chatAux.visual.invalidJson'),
      style: const TextStyle(color: Colors.white70, fontSize: 12),
    ),
  );
}

Map<String, dynamic>? _decodeVisual(String source) {
  try {
    final value = jsonDecode(source);
    return value is Map ? Map<String, dynamic>.from(value) : null;
  } catch (_) {
    return null;
  }
}

List<String> _strings(dynamic value) => value is List
    ? value
          .map((item) => item.toString())
          .where((item) => item.isNotEmpty)
          .toList()
    : const [];

List<double> _numbers(dynamic value) {
  if (value is! List) return const [];
  return value
      .map((item) => item is num ? item.toDouble() : double.tryParse('$item'))
      .whereType<double>()
      .toList();
}

String _format(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(1);

abstract class _ChartPainter extends CustomPainter {
  const _ChartPainter(this.values, this.accent);

  final List<double> values;
  final Color accent;

  void grid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 1;
    for (var index = 1; index < 4; index++) {
      final y = size.height * index / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }
}

class _BarChartPainter extends _ChartPainter {
  const _BarChartPainter(super.values, super.accent);

  @override
  void paint(Canvas canvas, Size size) {
    grid(canvas, size);
    if (values.isEmpty) return;
    final maxValue = values.reduce(math.max).abs().clamp(1, double.infinity);
    final gap = 8.0;
    final width = (size.width - gap * (values.length - 1)) / values.length;
    final paint = Paint()..color = accent;
    for (var index = 0; index < values.length; index++) {
      final height = size.height * (values[index] / maxValue).clamp(0, 1);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          index * (width + gap),
          size.height - height,
          width,
          height,
        ),
        const Radius.circular(4),
      );
      canvas.drawRRect(
        rect,
        paint..color = accent.withValues(alpha: 0.55 + index % 2 * 0.3),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) => true;
}

class _HorizontalBarChartPainter extends _ChartPainter {
  const _HorizontalBarChartPainter(super.values, this.labels, super.accent);

  final List<String> labels;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    const labelWidth = 112.0;
    const axisHeight = 24.0;
    final plotWidth = math.max(1.0, size.width - labelWidth - 8);
    final plotHeight = size.height - axisHeight;
    final maxValue = values.reduce(math.max).abs().clamp(1, double.infinity);
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..strokeWidth = 1;
    final labelStyle = const TextStyle(color: Colors.white, fontSize: 11);
    final tickStyle = const TextStyle(color: Colors.white54, fontSize: 10);

    for (var index = 0; index <= 5; index++) {
      final x = labelWidth + plotWidth * index / 5;
      canvas.drawLine(Offset(x, 0), Offset(x, plotHeight), gridPaint);
      _paintText(
        canvas,
        _format(maxValue * index / 5),
        tickStyle,
        Offset(x - 5, plotHeight + 7),
      );
    }

    final rowHeight = plotHeight / values.length;
    for (var index = 0; index < values.length; index++) {
      final barHeight = math.min(42.0, rowHeight * 0.62);
      final y = rowHeight * index + (rowHeight - barHeight) / 2;
      final barWidth = plotWidth * (values[index] / maxValue).clamp(0, 1);
      final label = index < labels.length
          ? labels[index]
          : tr('chatAux.visual.valueFallback', {
              'number': (index + 1).toString(),
            });
      final labelPainter = TextPainter(
        text: TextSpan(text: label, style: labelStyle),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: labelWidth - 12);
      labelPainter.paint(
        canvas,
        Offset(
          labelWidth - labelPainter.width - 10,
          y + (barHeight - labelPainter.height) / 2,
        ),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(labelWidth, y, barWidth, barHeight),
          const Radius.circular(4),
        ),
        Paint()..color = accent,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HorizontalBarChartPainter oldDelegate) => true;
}

void _paintText(Canvas canvas, String value, TextStyle style, Offset offset) {
  final painter = TextPainter(
    text: TextSpan(text: value, style: style),
    textDirection: TextDirection.ltr,
  )..layout();
  painter.paint(canvas, offset);
}

class _LineChartPainter extends _ChartPainter {
  const _LineChartPainter(super.values, super.accent);

  @override
  void paint(Canvas canvas, Size size) {
    grid(canvas, size);
    if (values.length < 2) return;
    final maxValue = values.reduce(math.max);
    final minValue = values.reduce(math.min);
    final spread = (maxValue - minValue).abs() < 0.0001
        ? 1.0
        : maxValue - minValue;
    final path = Path();
    for (var index = 0; index < values.length; index++) {
      final x = size.width * index / (values.length - 1);
      final y =
          size.height - size.height * ((values[index] - minValue) / spread);
      if (index == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = accent
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) => true;
}

class _DonutChartPainter extends _ChartPainter {
  const _DonutChartPainter(super.values, super.accent);

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final total = values.fold<double>(0, (sum, value) => sum + value.abs());
    if (total == 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 8;
    var start = -math.pi / 2;
    for (var index = 0; index < values.length; index++) {
      final sweep = values[index].abs() / total * math.pi * 2;
      final color = Color.lerp(
        accent,
        const Color(0xFF9D7BDE),
        index / math.max(1, values.length - 1),
      )!;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sweep - 0.04,
        false,
        Paint()
          ..color = color
          ..strokeWidth = 24
          ..style = PaintingStyle.stroke,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) => true;
}
