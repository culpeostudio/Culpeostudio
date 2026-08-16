import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/app_strings.dart' show appLanguage;
import '../../core/design_tokens.dart';

import './chat_aux_strings.dart';

/// How much of its model's context window one chat currently occupies.
///
/// Both numbers are estimates and the backend says so: [limitTokens] may be the
/// average over the model catalogue when nothing reported a real window, and
/// [usedTokens] is counted by a characters-per-token rule rather than by the
/// model's own tokenizer.
@immutable
class ContextUsage {
  const ContextUsage({
    required this.limitTokens,
    required this.usedTokens,
    required this.source,
    this.modelLimitTokens = 0,
    this.compactions = 0,
    this.compacted = false,
  });

  /// Nothing measured yet - the meter stays hidden.
  static const ContextUsage unknown = ContextUsage(
    limitTokens: 0,
    usedTokens: 0,
    source: '',
  );

  final int limitTokens;
  final int usedTokens;

  /// What the model itself would allow, where [limitTokens] is only what this
  /// instance was started with. Zero when the two are the same - the engine's
  /// memory plan routinely starts a local model well below its maximum, and
  /// without this the meter looks like it miscounted.
  final int modelLimitTokens;

  /// Where [limitTokens] came from: `local`, `provider`, `catalog` or
  /// `average`.
  final String source;

  /// How often this chat's older turns were folded into a summary.
  final int compactions;

  /// True on the reading that follows a folding, which is why the meter can
  /// drop instead of only ever rising.
  final bool compacted;

  factory ContextUsage.fromMap(Map<String, dynamic> data) {
    return ContextUsage(
      limitTokens: (data['limit_tokens'] as num?)?.toInt() ?? 0,
      usedTokens: (data['used_tokens'] as num?)?.toInt() ?? 0,
      source: data['source']?.toString() ?? '',
      modelLimitTokens: (data['model_limit_tokens'] as num?)?.toInt() ?? 0,
      compactions: (data['compactions'] as num?)?.toInt() ?? 0,
      compacted: data['compacted'] == true,
    );
  }

  bool get isKnown => limitTokens > 0;

  double get ratio => limitTokens <= 0
      ? 0
      : (usedTokens / limitTokens).clamp(0.0, 1.0).toDouble();

  int get percent => (ratio * 100).round();

  /// True when the window is a stand-in rather than a number the model or its
  /// provider reported.
  bool get isEstimated => source == 'average';

  /// True when the running instance was given less room than the model could
  /// use - worth saying out loud, because restarting it with more context is
  /// something the user can actually do.
  bool get isBelowModelMaximum => modelLimitTokens > limitTokens;

  @override
  bool operator ==(Object other) =>
      other is ContextUsage &&
      other.limitTokens == limitTokens &&
      other.usedTokens == usedTokens &&
      other.modelLimitTokens == modelLimitTokens &&
      other.source == source &&
      other.compactions == compactions &&
      other.compacted == compacted;

  @override
  int get hashCode => Object.hash(
    limitTokens,
    usedTokens,
    source,
    modelLimitTokens,
    compactions,
    compacted,
  );
}

/// The ring next to the composer that fills as the conversation grows.
///
/// It is a reading, not a control, so it stays in the gold family until the
/// window gets tight - see the rust/gold split in [CulpeoColors]. Compaction
/// empties it again, which is the one moment the arc runs backwards.
class ContextMeter extends StatelessWidget {
  const ContextMeter({super.key, required this.usage, this.diameter = 26});

  final ContextUsage usage;
  final double diameter;

  static const double _warningRatio = 0.75;
  static const double _criticalRatio = 0.9;

  @override
  Widget build(BuildContext context) {
    if (!usage.isKnown) return const SizedBox.shrink();

    final color = _colorFor(usage.ratio);
    return Tooltip(
      message: _tooltip(),
      waitDuration: const Duration(milliseconds: 300),
      child: Semantics(
        label: tr('chatAux.context.semantics', {
          'percent': usage.percent.toString(),
        }),
        child: SizedBox(
          width: diameter,
          height: diameter,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(end: usage.ratio),
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeOutCubic,
            builder: (context, ratio, _) {
              return CustomPaint(
                painter: _ContextRingPainter(
                  ratio: ratio,
                  color: color,
                  track: CulpeoColors.hairlineStrong,
                ),
                child: Center(
                  child: Text(
                    // The percent sign would not survive at this size, and the
                    // tooltip spells the reading out anyway.
                    usage.percent.toString(),
                    style: TextStyle(
                      color: color,
                      fontSize: diameter * 0.34,
                      fontWeight: FontWeight.w700,
                      height: 1,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Color _colorFor(double ratio) {
    if (ratio >= _criticalRatio) return CulpeoColors.danger;
    if (ratio >= _warningRatio) return CulpeoColors.warning;
    return CulpeoColors.metric;
  }

  String _tooltip() {
    final lines = <String>[
      tr('chatAux.context.tooltip', {
        'used': _formatTokens(usage.usedTokens),
        'limit': _formatTokens(usage.limitTokens),
        'percent': usage.percent.toString(),
      }),
      tr('chatAux.context.source.${_sourceKey()}'),
      if (usage.isBelowModelMaximum)
        tr('chatAux.context.belowModelMaximum', {
          'model': _formatTokens(usage.modelLimitTokens),
        }),
    ];
    if (usage.compactions > 0) {
      lines.add(
        tr('chatAux.context.compacted', {
          'count': usage.compactions.toString(),
        }),
      );
    }
    return lines.join('\n');
  }

  String _sourceKey() {
    switch (usage.source) {
      case 'local':
      case 'provider':
      case 'catalog':
      case 'average':
        return usage.source;
      default:
        return 'average';
    }
  }
}

/// Tokens read as magnitudes, not as exact figures - "12,4k von 128k" says more
/// at a glance than six digits do.
String _formatTokens(int tokens) {
  if (tokens < 1000) return tokens.toString();
  final thousands = tokens / 1000;
  if (thousands >= 100) return '${thousands.round()}k';
  final decimal = appLanguage == 'en' ? '.' : ',';
  return '${thousands.toStringAsFixed(1).replaceAll('.', decimal)}k';
}

class _ContextRingPainter extends CustomPainter {
  const _ContextRingPainter({
    required this.ratio,
    required this.color,
    required this.track,
  });

  final double ratio;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.shortestSide * 0.11;
    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.height - stroke,
    );

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = track;
    canvas.drawArc(rect, 0, math.pi * 2, false, trackPaint);

    if (ratio <= 0) return;
    final fillPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;
    // From twelve o'clock, clockwise, so it reads like a gauge filling up.
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * ratio, false, fillPaint);
  }

  @override
  bool shouldRepaint(_ContextRingPainter old) =>
      old.ratio != ratio || old.color != color || old.track != track;
}
