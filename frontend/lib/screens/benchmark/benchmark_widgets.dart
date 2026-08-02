import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../theme/dark_theme.dart';
import 'benchmark_models.dart';
import 'benchmark_orgs.dart';

const double kBenchmarkInset = 38;
const double kBenchmarkCardRadius = 14;
const Color kBenchmarkCardColor = Color(0xFF16161D);
const Color kBenchmarkFieldColor = Color(0xFF0F0F12);

Color get kBenchmarkBorderColor => Colors.white.withValues(alpha: 0.06);

const Map<String, Color> _familyColors = {
  'instruction': Color(0xFF7C9CF0),
  'reasoning': Color(0xFFB98BE0),
  'math': Color(0xFF4FC3D9),
  'coding': Color(0xFF5FBF8C),
  'creative': Color(0xFFE07AB8),
  'conversation': Color(0xFFE08A4A),
  'language': Color(0xFF4AA3E0),
  'vision': Color(0xFFE0B14A),
  'knowledge': Color(0xFF5FA8D3),
  'safety': Color(0xFFE05A73),
};

const List<Color> _metricPalette = [
  Color(0xFF7C9CF0),
  Color(0xFF5FBF8C),
  Color(0xFF4FC3D9),
  Color(0xFFB98BE0),
  Color(0xFFE08A4A),
  Color(0xFFE07AB8),
  Color(0xFF4AA3E0),
  Color(0xFFE0B14A),
];

const List<Color> kBenchmarkCompareColors = [
  DarkColors.accent,
  Color(0xFF4FC3D9),
  Color(0xFFB98BE0),
  Color(0xFF5FBF8C),
];

Color benchmarkFamilyColor(String family) {
  if (family.isEmpty) return DarkColors.accent;
  final known = _familyColors[family];
  if (known != null) return known;
  return _paletteFor(family);
}

Color benchmarkMetricColor(BenchmarkMetric metric) {
  if (metric.family.isNotEmpty) return benchmarkFamilyColor(metric.family);
  return _paletteFor(metric.key);
}

Color _paletteFor(String key) {
  var hash = 0;
  for (final unit in key.codeUnits) {
    hash = (hash * 31 + unit) & 0x7fffffff;
  }
  return _metricPalette[hash % _metricPalette.length];
}

Color benchmarkTypeColor(String type) {
  switch (type) {
    case 'open_weights':
      return const Color(0xFF4FC3D9);
    case 'proprietary':
      return const Color(0xFFB98BE0);
    default:
      return Colors.white.withValues(alpha: 0.5);
  }
}

Color benchmarkRankColor(int position) {
  switch (position) {
    case 1:
      return const Color(0xFFE3B34D);
    case 2:
      return const Color(0xFFBFC7D4);
    case 3:
      return const Color(0xFFCC8B5C);
    default:
      return Colors.white.withValues(alpha: 0.34);
  }
}

const Color kBenchmarkScoreColor = Color(0xFFA9BDD9);

String formatScore(double value, {String scoreKind = 'percent'}) {
  return value.toStringAsFixed(scoreKind == 'elo' ? 0 : 1);
}

String formatCount(int value) {
  final separator = appLanguage == 'en' ? ',' : '.';
  final digits = value.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(separator);
    buffer.write(digits[i]);
  }
  return value < 0 ? '-$buffer' : buffer.toString();
}

String formatCompact(int value) {
  final english = appLanguage == 'en';
  if (value >= 1000000000) {
    final short = (value / 1000000000).toStringAsFixed(1);
    return english ? '${short}B' : '$short Mrd.';
  }
  if (value >= 1000000) {
    final short = (value / 1000000).toStringAsFixed(1);
    return english ? '${short}M' : '$short Mio.';
  }
  if (value >= 1000) {
    final short = (value / 1000).toStringAsFixed(1);
    return english ? '${short}K' : '$short Tsd.';
  }
  return formatCount(value);
}

String formatIsoDate(String iso) {
  if (iso.isEmpty) return '—';
  final parsed = DateTime.tryParse(iso);
  if (parsed == null) return iso;
  final local = parsed.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  return appLanguage == 'en'
      ? '$month/$day/${local.year}'
      : '$day.$month.${local.year}';
}

String _translateOr(String key, String fallback) {
  final translated = tr(key);
  return translated == key ? fallback : translated;
}

String benchmarkTypeLabel(String key) {
  if (key.isEmpty) return '—';
  return _translateOr('benchmark.type.$key', key);
}

String benchmarkBoardLabel(BenchmarkBoard board) {
  if (board.label.isNotEmpty) return board.label;
  return _translateOr('benchmark.board.${board.key}', board.key);
}

String benchmarkMetricDescription(String key) =>
    _translateOr('benchmark.metric.$key.desc', '');

String benchmarkDetailLabel(String key) =>
    _translateOr('benchmark.detail.$key', key);

IconData benchmarkFamilyIcon(String family) {
  switch (family) {
    case 'coding':
      return Icons.terminal_rounded;
    case 'math':
      return Icons.functions_rounded;
    case 'reasoning':
      return Icons.psychology_outlined;
    case 'creative':
      return Icons.auto_awesome_outlined;
    case 'instruction':
      return Icons.rule_rounded;
    case 'conversation':
      return Icons.forum_outlined;
    case 'language':
      return Icons.translate_rounded;
    case 'vision':
      return Icons.visibility_outlined;
    default:
      return Icons.insights_rounded;
  }
}

class BenchmarkHover extends StatefulWidget {
  const BenchmarkHover({super.key, required this.builder, this.enabled = true});

  final Widget Function(BuildContext context, bool hovered) builder;
  final bool enabled;

  @override
  State<BenchmarkHover> createState() => _BenchmarkHoverState();
}

class _BenchmarkHoverState extends State<BenchmarkHover> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.builder(context, false);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: widget.builder(context, _hovered),
    );
  }
}

class BenchmarkSheen extends StatefulWidget {
  const BenchmarkSheen({
    super.key,
    required this.color,
    this.diagonal = false,
    this.radius = 0,
    this.strength = 0.18,
  });

  final Color color;

  final bool diagonal;
  final double radius;
  final double strength;

  @override
  State<BenchmarkSheen> createState() => _BenchmarkSheenState();
}

class _BenchmarkSheenState extends State<BenchmarkSheen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final sweep = -0.35 + 1.7 * _controller.value;

          return DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: widget.radius > 0
                  ? BorderRadius.circular(widget.radius)
                  : null,
              gradient: LinearGradient(
                begin: widget.diagonal
                    ? Alignment.topLeft
                    : Alignment.centerLeft,
                end: widget.diagonal
                    ? Alignment.bottomRight
                    : Alignment.centerRight,
                colors: [
                  Colors.transparent,
                  widget.color.withValues(alpha: widget.strength),
                  Colors.transparent,
                ],
                stops: [
                  (sweep - 0.17).clamp(0.0, 1.0),
                  sweep.clamp(0.0, 1.0),
                  (sweep + 0.17).clamp(0.0, 1.0),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class BenchmarkCard extends StatelessWidget {
  const BenchmarkCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.highlighted = false,
    this.accent,
    this.glow = false,
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;
  final bool highlighted;
  final Color? accent;
  final bool glow;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tint = accent ?? (highlighted ? DarkColors.accent : null);

    return BenchmarkHover(
      enabled: onTap != null,
      builder: (context, hovered) {
        final border = tint == null
            ? (hovered
                  ? Colors.white.withValues(alpha: 0.14)
                  : kBenchmarkBorderColor)
            : tint.withValues(alpha: hovered ? 0.55 : 0.34);

        final content = AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: padding,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                tint == null
                    ? kBenchmarkCardColor
                    : Color.alphaBlend(
                        tint.withValues(alpha: hovered ? 0.11 : 0.07),
                        kBenchmarkCardColor,
                      ),
                kBenchmarkCardColor,
              ],
            ),
            borderRadius: BorderRadius.circular(kBenchmarkCardRadius),
            border: Border.all(color: border),
            boxShadow: glow
                ? [
                    BoxShadow(
                      color: (tint ?? DarkColors.accent).withValues(
                        alpha: hovered ? 0.20 : 0.13,
                      ),
                      blurRadius: 26,
                      spreadRadius: -6,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: child,
        );

        if (onTap == null) return content;
        return Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(kBenchmarkCardRadius),
          clipBehavior: Clip.antiAlias,
          child: InkWell(onTap: onTap, child: content),
        );
      },
    );
  }
}

class BenchmarkPill extends StatelessWidget {
  const BenchmarkPill({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.dense = false,
  });

  final String label;
  final Color color;
  final IconData? icon;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 10,
        vertical: dense ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: dense ? 12 : 14),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: dense ? 10.5 : 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BenchmarkStatTile extends StatelessWidget {
  const BenchmarkStatTile({
    super.key,
    required this.label,
    required this.value,
    this.hint = '',
    this.icon,
    this.color = DarkColors.accent,
  });

  final String label;
  final String value;
  final String hint;
  final IconData? icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return BenchmarkCard(
      accent: color,
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withValues(alpha: 0.28)),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 9.5,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                    height: 1.05,
                  ),
                ),
                if (hint.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    hint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color.withValues(alpha: 0.85),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class BenchmarkScoreBar extends StatelessWidget {
  const BenchmarkScoreBar({
    super.key,
    required this.label,
    required this.value,
    this.median,
    this.trailing = '',
    this.color,
    this.compact = false,
    this.scoreMax = 100,
    this.scoreFloor = 0,
    this.scoreKind = 'percent',
    this.leading,
    this.animate = true,
  });

  final String label;
  final double value;
  final double? median;
  final String trailing;
  final Color? color;
  final bool compact;
  final double scoreMax;
  final double scoreFloor;
  final String scoreKind;

  final Widget? leading;
  final bool animate;

  double _fraction(double raw) {
    final span = scoreMax - scoreFloor;
    if (span <= 0) return 0;
    return ((raw - scoreFloor) / span).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final barColor = color ?? DarkColors.accent;
    final fraction = value <= 0 ? 0.0 : _fraction(value);
    final medianFraction = (median == null || median! <= 0)
        ? null
        : _fraction(median!);
    final height = compact ? 7.0 : 9.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 8)],
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.78),
                  fontSize: compact ? 11 : 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              value <= 0 ? '—' : formatScore(value, scoreKind: scoreKind),
              style: TextStyle(
                color: value <= 0 ? Colors.white38 : barColor,
                fontSize: compact ? 11.5 : 13,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
            if (trailing.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(
                trailing,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 10,
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: compact ? 5 : 7),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            return SizedBox(
              height: height,
              child: Stack(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(height / 2),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.04),
                      ),
                    ),
                    child: const SizedBox.expand(),
                  ),
                  _BenchmarkBarFill(
                    fraction: fraction,
                    color: barColor,
                    height: height,
                    animate: animate,
                  ),

                  if (medianFraction != null)
                    Positioned(
                      left: (width * medianFraction).clamp(0.0, width - 2),
                      top: -2,
                      bottom: -2,
                      child: Container(
                        width: 2,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _BenchmarkBarFill extends StatelessWidget {
  const _BenchmarkBarFill({
    required this.fraction,
    required this.color,
    required this.height,
    required this.animate,
  });

  final double fraction;
  final Color color;
  final double height;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    Widget fill(double factor) {
      return FractionallySizedBox(
        widthFactor: factor,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withValues(alpha: 0.55), color],
            ),
            borderRadius: BorderRadius.circular(height / 2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.35),
                blurRadius: 8,
                spreadRadius: -3,
              ),
            ],
          ),
        ),
      );
    }

    if (!animate) return fill(fraction);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: fraction),
      duration: const Duration(milliseconds: 620),
      curve: Curves.easeOutCubic,
      builder: (context, factor, _) => fill(factor),
    );
  }
}

class BenchmarkChip extends StatelessWidget {
  const BenchmarkChip({
    super.key,
    required this.label,
    this.icon,
    this.accent = false,
    this.color,
  });

  final String label;
  final IconData? icon;
  final bool accent;

  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tone =
        color ??
        (accent ? DarkColors.accent : Colors.white.withValues(alpha: 0.55));
    final tinted = color != null || accent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: tinted
            ? tone.withValues(alpha: 0.12)
            : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: tinted
              ? tone.withValues(alpha: 0.32)
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: tone),
            const SizedBox(width: 5),
          ],

          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: tone,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BenchmarkRankBadge extends StatelessWidget {
  const BenchmarkRankBadge({super.key, required this.position, this.size = 34});

  final int position;
  final double size;

  @override
  Widget build(BuildContext context) {
    final medal = position >= 1 && position <= 3;
    final color = benchmarkRankColor(position);

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: medal
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withValues(alpha: 0.30),
                  color.withValues(alpha: 0.08),
                ],
              )
            : null,
        borderRadius: BorderRadius.circular(size * 0.3),
        border: Border.all(
          color: medal
              ? color.withValues(alpha: 0.45)
              : Colors.white.withValues(alpha: 0.07),
        ),
      ),
      child: Text(
        '$position',
        maxLines: 1,
        style: TextStyle(
          color: medal ? color : Colors.white.withValues(alpha: 0.4),
          fontSize: size * (position >= 100 ? 0.30 : 0.38),
          fontWeight: FontWeight.w800,
          height: 1,
          letterSpacing: -0.3,
        ),
      ),
    );
  }
}

const String kBenchmarkSortPrimary = 'primary';

const String kBenchmarkSortName = 'name';

class BenchmarkTableLayout {
  const BenchmarkTableLayout({
    required this.rank,
    required this.org,
    required this.type,
    required this.bar,
    required this.score,
    required this.compare,
    required this.metrics,
    required this.metricWidth,
    required this.metricSlots,
    required this.metricScroll,
    required this.metricScrollMax,
    required this.scoreGap,
    required this.modelMin,
    required this.dense,
  });

  static const double gap = 14;

  static const double _metricMin = 82;
  static const double _metricMax = 112;

  static const double _barMin = 100;
  static const double _barMax = 260;

  static const double _scoreGapMax = 100;

  static const double _modelMax = 460;

  static const double _modelMin = 230;
  static const double _modelMinNarrow = 150;

  static const double rowPaddingLeft = 12;
  static const double rowPaddingRight = 4;

  static const int maxMetrics = 5;

  factory BenchmarkTableLayout.of({
    required double width,
    required BenchmarkBoard board,
    bool dense = false,
    bool hasCompare = false,
    double metricScroll = 0,
  }) {
    final rank = dense ? 34.0 : 44.0;
    final score = dense ? 54.0 : 66.0;
    final compare = hasCompare ? 40.0 : 0.0;
    final org = !dense && width >= 720 ? 138.0 : 0.0;
    final type = !dense && width >= 560 ? 116.0 : 0.0;
    var bar = !dense && width >= 900 ? _barMin : 0.0;
    var metricWidth = _metricMin;
    final modelMin = width < 520 ? _modelMinNarrow : _modelMin;

    var free =
        width -
        rowPaddingLeft -
        rowPaddingRight -
        rank -
        gap -
        modelMin -
        _span(org) -
        _span(type) -
        _span(bar) -
        gap -
        score -
        compare;

    var fits = 0;
    if (!dense && org > 0) {
      while (fits < board.metrics.length &&
          fits < maxMetrics &&
          free >= metricWidth + gap) {
        fits++;
        free -= metricWidth + gap;
      }
    }
    final metrics = fits == 0 ? const <BenchmarkMetric>[] : board.metrics;

    if (fits > 0 && free > 0) {
      final grow = (free / fits).clamp(0.0, _metricMax - _metricMin);
      metricWidth += grow;
      free -= grow * fits;
    }
    var scoreGap = 0.0;
    if (fits > 0 && free > 0) {
      scoreGap = free.clamp(0.0, _scoreGapMax);
      free -= scoreGap;
    }
    if (bar > 0 && free > 0) {
      final grow = free.clamp(0.0, _barMax - _barMin);
      bar += grow;
      free -= grow;
    }
    if (free > 0) {
      final modelGrow = free.clamp(0.0, _modelMax - modelMin);
      free -= modelGrow;
      if (fits > 0) scoreGap += free;
    }

    final window = fits == 0 ? 0.0 : fits * metricWidth + (fits - 1) * gap;
    final content = metrics.isEmpty
        ? 0.0
        : metrics.length * metricWidth + (metrics.length - 1) * gap;
    final maxScroll = content - window > 0 ? content - window : 0.0;

    return BenchmarkTableLayout(
      rank: rank,
      org: org,
      type: type,
      bar: bar,
      score: score,
      compare: compare,
      metrics: List.unmodifiable(metrics),
      metricWidth: metricWidth,
      metricSlots: fits,
      metricScroll: metricScroll.clamp(0.0, maxScroll),
      metricScrollMax: maxScroll,
      scoreGap: scoreGap,
      modelMin: modelMin,
      dense: dense,
    );
  }

  static double _span(double width) => width <= 0 ? 0 : width + gap;

  final double rank;
  final double org;
  final double type;
  final double bar;
  final double score;
  final double compare;

  final List<BenchmarkMetric> metrics;

  final double metricWidth;

  final int metricSlots;

  final double metricScroll;

  final double metricScrollMax;

  final double scoreGap;

  final double modelMin;
  final bool dense;

  bool get showOrg => org > 0;
  bool get showType => type > 0;
  bool get showBar => bar > 0;
  bool get showCompare => compare > 0;

  double get metricSpan => metricSlots == 0
      ? 0
      : metricSlots * metricWidth + (metricSlots - 1) * gap;

  double get metricContent => metrics.isEmpty
      ? 0
      : metrics.length * metricWidth + (metrics.length - 1) * gap;

  int get firstVisibleMetric =>
      metrics.isEmpty ? 0 : (metricScroll / (metricWidth + gap)).floor() + 1;

  int get lastVisibleMetric {
    if (metrics.isEmpty) return 0;
    final last = ((metricScroll + metricSpan) / (metricWidth + gap)).ceil();
    return last > metrics.length ? metrics.length : last;
  }

  double get wantedWidth =>
      rowPaddingLeft +
      rowPaddingRight +
      rank +
      gap +
      modelMin +
      _span(org) +
      _span(type) +
      _span(bar) +
      metricSlots * (metricWidth + gap) +
      scoreGap +
      gap +
      score +
      compare;

  double get rowHeight => dense ? 44 : 54;
}

class BenchmarkMetricStrip extends StatelessWidget {
  const BenchmarkMetricStrip({
    super.key,
    required this.layout,
    required this.cell,
  });

  final BenchmarkTableLayout layout;

  final Widget Function(BenchmarkMetric metric, int index) cell;

  @override
  Widget build(BuildContext context) {
    if (layout.metricSlots == 0) return const SizedBox.shrink();

    final strip = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < layout.metrics.length; index++) ...[
          if (index > 0) const SizedBox(width: BenchmarkTableLayout.gap),
          SizedBox(
            width: layout.metricWidth,
            child: cell(layout.metrics[index], index),
          ),
        ],
      ],
    );

    return SizedBox(
      width: layout.metricSpan,
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.centerLeft,
          maxWidth: layout.metricContent,
          child: Transform.translate(
            offset: Offset(-layout.metricScroll, 0),
            child: strip,
          ),
        ),
      ),
    );
  }
}

class BenchmarkTableHeader extends StatelessWidget {
  const BenchmarkTableHeader({
    super.key,
    required this.layout,
    required this.board,
    this.sort = kBenchmarkSortPrimary,
    this.descending = true,
    this.onSort,
    this.onMetricWindow,
  });

  final BenchmarkTableLayout layout;
  final BenchmarkBoard board;
  final String sort;
  final bool descending;
  final ValueChanged<String>? onSort;

  final ValueChanged<double>? onMetricWindow;

  String get _primaryLabel => board.primaryLabel.isEmpty
      ? tr('benchmark.sortAverage')
      : board.primaryLabel;

  @override
  Widget build(BuildContext context) {
    final slide = onMetricWindow != null && layout.metricScrollMax > 0;

    return BenchmarkHover(
      enabled: slide,
      builder: (context, hovered) => Container(
        padding: const EdgeInsets.only(
          left: BenchmarkTableLayout.rowPaddingLeft,
          right: BenchmarkTableLayout.rowPaddingRight,
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.09)),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 32, child: _buildLabels()),

            if (slide)
              AnimatedOpacity(
                opacity: hovered ? 1 : 0,
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                child: _buildWindow(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabels() {
    return Row(
      children: [
        _cell(
          width: layout.rank,
          label: tr('benchmark.columnRank'),
          align: TextAlign.right,
          sortKey: kBenchmarkSortPrimary,
          column: 'rank',
        ),
        const SizedBox(width: BenchmarkTableLayout.gap),
        Expanded(
          child: _cell(
            label: tr('benchmark.columnModel'),
            sortKey: kBenchmarkSortName,
          ),
        ),
        if (layout.showOrg) ...[
          const SizedBox(width: BenchmarkTableLayout.gap),
          _cell(width: layout.org, label: tr('benchmark.columnOrg')),
        ],
        if (layout.showType) ...[
          const SizedBox(width: BenchmarkTableLayout.gap),
          _cell(width: layout.type, label: tr('benchmark.columnType')),
        ],
        if (layout.metricSlots > 0) ...[
          const SizedBox(width: BenchmarkTableLayout.gap),
          BenchmarkMetricStrip(
            layout: layout,

            cell: (metric, _) => _cell(
              label: metric.label,
              sortKey: metric.key,
              tooltip: metric.setup.isEmpty
                  ? metric.label
                  : '${metric.label} · ${metric.setup}',
            ),
          ),
        ],

        if (layout.scoreGap > 0) SizedBox(width: layout.scoreGap),
        const SizedBox(width: BenchmarkTableLayout.gap),
        _cell(
          width: layout.score,
          label: _primaryLabel,
          sortKey: kBenchmarkSortPrimary,
          column: 'score',
        ),

        if (layout.showBar)
          SizedBox(width: layout.bar + BenchmarkTableLayout.gap),
        if (layout.showCompare) SizedBox(width: layout.compare),
      ],
    );
  }

  Widget _buildWindow() {
    const gap = BenchmarkTableLayout.gap;

    return SizedBox(
      height: 15,
      child: Row(
        children: [
          SizedBox(width: layout.rank),
          const SizedBox(width: gap),
          const Expanded(child: SizedBox.shrink()),
          if (layout.showOrg) SizedBox(width: layout.org + gap),
          if (layout.showType) SizedBox(width: layout.type + gap),
          const SizedBox(width: gap),
          SizedBox(
            width: layout.metricSpan,
            child: BenchmarkMetricWindow(
              layout: layout,
              onChanged: onMetricWindow!,
            ),
          ),
          if (layout.scoreGap > 0) SizedBox(width: layout.scoreGap),
          const SizedBox(width: gap),
          SizedBox(width: layout.score),
          if (layout.showBar) SizedBox(width: layout.bar + gap),
          if (layout.showCompare) SizedBox(width: layout.compare),
        ],
      ),
    );
  }

  Widget _cell({
    required String label,
    double? width,
    TextAlign align = TextAlign.left,
    String sortKey = '',
    String column = '',
    String tooltip = '',
  }) {
    final sortable = sortKey.isNotEmpty && onSort != null;
    final active = sortable && sortKey == sort;
    final right = align == TextAlign.right;

    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: right
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      children: [
        Flexible(
          child: Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: align,
            style: TextStyle(
              color: active
                  ? DarkColors.accent
                  : Colors.white.withValues(alpha: 0.38),
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.9,
            ),
          ),
        ),
        if (active) ...[
          const SizedBox(width: 4),
          Icon(
            descending
                ? Icons.arrow_downward_rounded
                : Icons.arrow_upward_rounded,
            size: 11,
            color: DarkColors.accent,
          ),
        ],
      ],
    );

    if (sortable) {
      content = InkWell(
        key: ValueKey('benchmark-column-${column.isEmpty ? sortKey : column}'),
        onTap: () => onSort!(sortKey),
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: content,
        ),
      );
      content = Align(
        alignment: right ? Alignment.centerRight : Alignment.centerLeft,
        child: content,
      );
    }

    if (tooltip.isNotEmpty) {
      content = Tooltip(message: tooltip, child: content);
    }
    return width == null ? content : SizedBox(width: width, child: content);
  }
}

class BenchmarkTableRow extends StatelessWidget {
  const BenchmarkTableRow({
    super.key,
    required this.entry,
    required this.position,
    required this.board,
    required this.layout,
    this.onTap,
    this.onCompare,
    this.highlightMetric = '',
  });

  final BenchmarkEntry entry;
  final int position;
  final BenchmarkBoard board;
  final BenchmarkTableLayout layout;
  final VoidCallback? onTap;
  final VoidCallback? onCompare;

  final String highlightMetric;

  bool get _dense => layout.dense;

  double _fraction(double value) {
    final span = board.scoreMax - board.scoreFloor;
    if (span <= 0 || value <= 0) return 0;
    return ((value - board.scoreFloor) / span).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final brand = benchmarkOrgBrand(entry.subtitle);
    final medal = position >= 1 && position <= 3;
    final scoreColor = medal
        ? benchmarkRankColor(position)
        : kBenchmarkScoreColor;
    final accent = medal ? scoreColor : brand.color;

    return BenchmarkHover(
      enabled: onTap != null,
      builder: (context, hovered) {
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              height: layout.rowHeight,
              decoration: BoxDecoration(
                color: hovered
                    ? Color.alphaBlend(
                        accent.withValues(alpha: 0.09),
                        kBenchmarkCardColor,
                      )
                    : Colors.transparent,
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),

                boxShadow: medal && hovered
                    ? [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.26),
                          blurRadius: 28,
                          spreadRadius: -4,
                        ),
                      ]
                    : null,
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: 2,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: hovered ? 0.95 : 0.7),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      left: BenchmarkTableLayout.rowPaddingLeft,
                      right: BenchmarkTableLayout.rowPaddingRight,
                    ),
                    child: _buildContent(brand.color, scoreColor, hovered),
                  ),

                  if (medal && hovered)
                    Positioned.fill(child: BenchmarkSheen(color: accent)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(Color brandColor, Color scoreColor, bool hovered) {
    return Row(
      children: [
        SizedBox(
          width: layout.rank,
          child: Text(
            '$position',
            textAlign: TextAlign.right,
            maxLines: 1,
            style: TextStyle(
              color: position <= 3
                  ? benchmarkRankColor(position)
                  : Colors.white.withValues(alpha: 0.38),
              fontSize: _dense ? 12.5 : 14,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
        ),
        const SizedBox(width: BenchmarkTableLayout.gap),
        Expanded(child: _buildName(brandColor)),
        if (layout.showOrg) ...[
          const SizedBox(width: BenchmarkTableLayout.gap),
          SizedBox(
            width: layout.org,
            child: Text(
              entry.subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: brandColor,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ],
        if (layout.showType) ...[
          const SizedBox(width: BenchmarkTableLayout.gap),
          SizedBox(
            width: layout.type,

            child: entry.type.isEmpty
                ? const SizedBox.shrink()
                : Text(
                    benchmarkTypeLabel(entry.type),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: benchmarkTypeColor(entry.type),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
          ),
        ],
        if (layout.metricSlots > 0) ...[
          const SizedBox(width: BenchmarkTableLayout.gap),
          BenchmarkMetricStrip(
            layout: layout,
            cell: (metric, _) => _buildMetricCell(metric),
          ),
        ],
        if (layout.scoreGap > 0) SizedBox(width: layout.scoreGap),
        const SizedBox(width: BenchmarkTableLayout.gap),
        SizedBox(
          width: layout.score,
          child: Text(
            entry.primary <= 0
                ? '—'
                : formatScore(entry.primary, scoreKind: board.scoreKind),
            maxLines: 1,
            style: TextStyle(
              color: scoreColor,
              fontSize: _dense ? 13.5 : 15.5,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
        ),
        if (layout.showBar) ...[
          const SizedBox(width: BenchmarkTableLayout.gap),
          _buildBar(scoreColor, hovered),
        ],
        if (layout.showCompare)
          SizedBox(
            width: layout.compare,
            child: onCompare == null
                ? const SizedBox.shrink()
                : IconButton(
                    icon: const Icon(Icons.compare_arrows, size: 17),
                    color: Colors.white.withValues(alpha: 0.4),
                    hoverColor: DarkColors.accent.withValues(alpha: 0.14),
                    tooltip: tr('benchmark.addToCompare'),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 34,
                      height: 34,
                    ),
                    onPressed: onCompare,
                  ),
          ),
      ],
    );
  }

  Widget _buildName(Color brandColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          entry.shortName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white,
            fontSize: _dense ? 12.5 : 13.5,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
        if (!layout.showOrg) ...[
          const SizedBox(height: 2),
          Text(
            entry.subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: brandColor,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMetricCell(BenchmarkMetric metric) {
    final value = entry.scoreOf(metric.key);
    final active = metric.key == highlightMetric;
    final color = active
        ? benchmarkMetricColor(metric)
        : Colors.white.withValues(alpha: 0.6);

    return Text(
      value <= 0 ? '—' : formatScore(value, scoreKind: board.scoreKind),
      maxLines: 1,
      style: TextStyle(
        color: value <= 0 ? Colors.white.withValues(alpha: 0.2) : color,
        fontSize: 12,
        fontWeight: active ? FontWeight.w800 : FontWeight.w600,
        letterSpacing: -0.2,
      ),
    );
  }

  Widget _buildBar(Color scoreColor, bool hovered) {
    return SizedBox(
      width: layout.bar,
      height: 6,
      child: Stack(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(3),
            ),
            child: const SizedBox.expand(),
          ),
          FractionallySizedBox(
            widthFactor: _fraction(entry.primary),

            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    scoreColor.withValues(alpha: hovered ? 0.6 : 0.45),
                    scoreColor,
                  ],
                ),
                borderRadius: BorderRadius.circular(3),
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
  }
}

class BenchmarkFactRow extends StatelessWidget {
  const BenchmarkFactRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 11.5,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BenchmarkSectionTitle extends StatelessWidget {
  const BenchmarkSectionTitle({
    super.key,
    required this.title,
    this.subtitle = '',
    this.color = DarkColors.accent,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Color color;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 3,
          height: subtitle.isEmpty ? 18 : 36,
          margin: const EdgeInsets.only(top: 2, right: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [color, color.withValues(alpha: 0.15)],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.1,
                ),
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.42),
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 12), trailing!],
      ],
    );
  }
}

class BenchmarkFilterOption {
  const BenchmarkFilterOption({
    required this.value,
    required this.label,
    required this.color,
    this.leading,
    this.count,
  });

  final String value;
  final String label;
  final Color color;

  final Widget? leading;

  final int? count;
}

class BenchmarkFilterMenu extends StatefulWidget {
  const BenchmarkFilterMenu({
    super.key,
    required this.label,
    required this.selected,
    required this.options,
    required this.onSelected,
    this.width = 200,
    this.menuKey,
  });

  final String label;
  final String selected;
  final List<BenchmarkFilterOption> options;
  final ValueChanged<String> onSelected;
  final double width;

  final Key? menuKey;

  @override
  State<BenchmarkFilterMenu> createState() => _BenchmarkFilterMenuState();
}

class _BenchmarkFilterMenuState extends State<BenchmarkFilterMenu> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    if (widget.options.isEmpty) return const SizedBox.shrink();

    final active = widget.options.firstWhere(
      (option) => option.value == widget.selected,
      orElse: () => widget.options.first,
    );
    final borderColor = active.color.withValues(alpha: 0.32);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.label,
          style: const TextStyle(color: Colors.white54, fontSize: 10.5),
        ),
        const SizedBox(width: 6),
        PopupMenuButton<String>(
          key: widget.menuKey,
          tooltip: widget.label,
          padding: EdgeInsets.zero,
          position: PopupMenuPosition.under,
          offset: const Offset(0, -1),
          constraints: BoxConstraints.tightFor(width: widget.width),
          menuPadding: const EdgeInsets.all(4),
          color: const Color(0xFF17171F),
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.black.withValues(alpha: 0.58),
          elevation: 10,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(10),
              bottomRight: Radius.circular(10),
            ),
            side: BorderSide(color: active.color.withValues(alpha: 0.52)),
          ),
          onOpened: () => setState(() => _open = true),
          onCanceled: () => setState(() => _open = false),
          onSelected: (value) {
            setState(() => _open = false);
            widget.onSelected(value);
          },
          itemBuilder: (context) => widget.options.map((option) {
            final isSelected = option.value == widget.selected;
            return PopupMenuItem<String>(
              value: option.value,
              height: 36,
              padding: EdgeInsets.zero,
              child: Container(
                height: 32,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? option.color.withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected
                        ? option.color.withValues(alpha: 0.38)
                        : Colors.transparent,
                  ),
                ),
                child: Row(
                  children: [
                    option.leading ?? _dot(option.color),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        option.label,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isSelected ? option.color : Colors.white70,
                          fontSize: 11,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                    if (option.count != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        formatCount(option.count!),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.35),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    if (isSelected) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.check_rounded, size: 15, color: option.color),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
          child: Container(
            width: widget.width,
            height: 34,
            padding: const EdgeInsets.only(left: 10, right: 4),
            decoration: BoxDecoration(
              color: active.color.withValues(alpha: 0.075),
              borderRadius: BorderRadius.vertical(
                top: const Radius.circular(8),
                bottom: Radius.circular(_open ? 0 : 8),
              ),
              border: Border(
                top: BorderSide(color: borderColor),
                left: BorderSide(color: borderColor),
                right: BorderSide(color: borderColor),
                bottom: _open
                    ? BorderSide.none
                    : BorderSide(color: borderColor),
              ),
            ),
            child: Row(
              children: [
                active.leading ?? _dot(active.color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    active.label,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
                Icon(
                  Icons.expand_more_rounded,
                  size: 17,
                  color: active.color.withValues(alpha: 0.88),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _dot(Color color) => Container(
    width: 6,
    height: 6,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

class BenchmarkMetricWindow extends StatelessWidget {
  const BenchmarkMetricWindow({
    super.key,
    required this.layout,
    required this.onChanged,
  });

  final BenchmarkTableLayout layout;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    if (layout.metricScrollMax <= 0) return const SizedBox.shrink();

    return Tooltip(
      message: tr('benchmark.metricWindowRange', {
        'from': '${layout.firstVisibleMetric}',
        'to': '${layout.lastVisibleMetric}',
        'total': '${layout.metrics.length}',
      }),
      child: SliderTheme(
        data: SliderThemeData(
          trackHeight: 2,

          activeTrackColor: Colors.white.withValues(alpha: 0.16),
          inactiveTrackColor: Colors.white.withValues(alpha: 0.16),
          thumbColor: Colors.white.withValues(alpha: 0.55),

          overlayShape: SliderComponentShape.noOverlay,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4.5),
        ),
        child: Slider(
          key: const ValueKey('benchmark-metric-window'),
          padding: EdgeInsets.zero,
          value: layout.metricScroll,
          min: 0,

          max: layout.metricScrollMax,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class BenchmarkToggle extends StatelessWidget {
  const BenchmarkToggle({
    super.key,
    required this.label,
    required this.active,
    required this.onTap,
    required this.icon,
    this.activeIcon,
    this.color = DarkColors.accent,
    this.buttonKey,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;
  final IconData icon;
  final IconData? activeIcon;
  final Color color;
  final Key? buttonKey;

  @override
  Widget build(BuildContext context) {
    final tone = active ? color : Colors.white.withValues(alpha: 0.55);

    return Material(
      color: active ? color.withValues(alpha: 0.12) : kBenchmarkFieldColor,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: buttonKey,
        onTap: onTap,
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: active
                  ? color.withValues(alpha: 0.42)
                  : Colors.white.withValues(alpha: 0.07),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(active ? (activeIcon ?? icon) : icon, size: 14, color: tone),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  color: tone,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
