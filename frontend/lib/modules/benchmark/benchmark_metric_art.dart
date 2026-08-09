import 'package:flutter/material.dart';

import '../../core/app_strings.dart';
import './benchmark_models.dart';
import './benchmark_widgets.dart';

/// Where the middle of the field sits on the way to the best run.
///
/// The bar runs from zero to the best score of the category, so its far end is
/// always "the leader here". The strong part reaches the median: half of the
/// rated models score below it, the paler part is the stretch up to the top.
class BenchmarkMetricSpan extends StatelessWidget {
  const BenchmarkMetricSpan({
    super.key,
    required this.metric,
    required this.stats,
    required this.board,
    this.order = 0,
  });

  final BenchmarkMetric metric;
  final BenchmarkMetricStats? stats;
  final BenchmarkBoard board;

  /// Position in a list, used to stagger the reveal.
  final int order;

  @override
  Widget build(BuildContext context) {
    final data = stats;
    final color = benchmarkMetricColor(metric);

    if (data == null || data.evaluated == 0 || data.max <= 0) {
      return _EmptySpan(color: color);
    }

    final median = (data.median / data.max).clamp(0.0, 1.0);

    return Semantics(
      label: tr('benchmark.metricSpanLabel', {
        'metric': metric.label,
        'median': formatScore(data.median, scoreKind: board.scoreKind),
        'max': formatScore(data.max, scoreKind: board.scoreKind),
      }),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _MetricBar(median: median, color: color, order: order),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _SpanFigure(
                  label: tr('benchmark.metricFieldMedian'),
                  value: formatScore(data.median, scoreKind: board.scoreKind),
                ),
              ),
              _SpanFigure(
                label: tr('benchmark.metricFieldBest'),
                value: formatScore(data.max, scoreKind: board.scoreKind),
                alignment: CrossAxisAlignment.end,
                strong: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A filled bar in two tones: solid up to the median, pale up to the best run.
class _MetricBar extends StatelessWidget {
  const _MetricBar({
    required this.median,
    required this.color,
    required this.order,
  });

  static const double _height = 8;
  static const int _growMs = 420;
  static const int _stepMs = 45;

  final double median;
  final Color color;
  final int order;

  @override
  Widget build(BuildContext context) {
    final total = _growMs + _stepMs * order;
    final start = (_stepMs * order) / total;

    return SizedBox(
      height: _height,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: total),
        curve: Interval(start, 1, curve: Curves.easeOutQuart),
        builder: (context, progress, _) => Stack(
          children: [
            FractionallySizedBox(
              widthFactor: progress,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.34),
                  borderRadius: BorderRadius.circular(_height / 2),
                ),
              ),
            ),
            FractionallySizedBox(
              widthFactor: median * progress,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(_height / 2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpanFigure extends StatelessWidget {
  const _SpanFigure({
    required this.label,
    required this.value,
    this.alignment = CrossAxisAlignment.start,
    this.strong = false,
  });

  final String label;
  final String value;
  final CrossAxisAlignment alignment;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: kBenchmarkInkFaint,
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          style: TextStyle(
            color: strong ? kBenchmarkInk : kBenchmarkInkSecondary,
            fontFeatures: const [FontFeature.tabularFigures()],
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
            height: 1,
          ),
        ),
      ],
    );
  }
}

class _EmptySpan extends StatelessWidget {
  const _EmptySpan({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 8,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: benchmarkTrackColor(color),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const SizedBox.expand(),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          tr('benchmark.metricNoData'),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: kBenchmarkInkFaint,
            fontSize: 11.5,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
