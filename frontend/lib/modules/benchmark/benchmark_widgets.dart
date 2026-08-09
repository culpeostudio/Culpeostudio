import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/app_strings.dart';
import '../../core/dark_theme.dart';
import './benchmark_models.dart';
import './benchmark_orgs.dart';

const double kBenchmarkInset = 38;
const double kBenchmarkCardRadius = 10;
const Color kBenchmarkCardColor = Color(0xFF131316);
const Color kBenchmarkFieldColor = Color(0xFF0F0F12);

Color get kBenchmarkBorderColor => Colors.white.withValues(alpha: 0.07);

Color get kBenchmarkHairline => Colors.white.withValues(alpha: 0.08);

const Color kBenchmarkInk = Colors.white;

Color get kBenchmarkInkSecondary => Colors.white.withValues(alpha: 0.82);

Color get kBenchmarkInkMuted => Colors.white.withValues(alpha: 0.70);

Color get kBenchmarkInkFaint => Colors.white.withValues(alpha: 0.54);

/// The calm info blue the module uses wherever a neutral accent is needed.
const Color kBenchmarkInfoColor = Color(0xFF5FB3D6);

/// The unfilled part of a bar, as a lighter step of the fill's own hue.
///
/// A neutral track disappears against the obsidian surface, which makes an
/// 85 %-filled bar read as an unfilled line. Tinting it keeps the whole bar
/// legible as one object.
Color benchmarkTrackColor(Color fill) => fill.withValues(alpha: 0.18);

/// One calm family of category colours: even saturation, even lightness,
/// so no single metric shouts louder than the others.
const Map<String, Color> _familyColors = {
  'instruction': Color(0xFF7E78E0),
  'reasoning': Color(0xFFA48FE0),
  'math': Color(0xFF4A86E6),
  'coding': Color(0xFF54C08A),
  'creative': Color(0xFFE577B4),
  'conversation': Color(0xFFD9B05E),
  'language': Color(0xFFE08555),
  'vision': Color(0xFF8F96DE),
  'knowledge': Color(0xFF57BAA6),
  'safety': Color(0xFFD98079),
  'hard_prompts': Color(0xFFE0503C),
  'hardPrompts': Color(0xFFE0503C),
};

/// Metric-specific colours take priority over the metric's family colour, so
/// single categories can stand out even when their family is shared.
const Map<String, Color> _metricKeyColors = {
  'hard_prompts': Color(0xFFE0503C),
  'hardPrompts': Color(0xFFE0503C),
  'multi_turn': Color(0xFFE2B13E),
  'multiTurn': Color(0xFFE2B13E),
  'longer_query': Color(0xFF9C6FE0),
  'longerQuery': Color(0xFF9C6FE0),
  'non_english': Color(0xFF38BFD4),
  'nonEnglish': Color(0xFF38BFD4),
};

const List<Color> _metricPalette = [
  Color(0xFF7AA5E0),
  Color(0xFF5FBB90),
  Color(0xFF5FB3D6),
  Color(0xFFA48FE0),
  Color(0xFFD9B05E),
  Color(0xFFD98BB4),
  Color(0xFF8F96DE),
  Color(0xFF57BAA6),
];

const List<Color> kBenchmarkCompareColors = [
  Color(0xFFD9B05E),
  Color(0xFF5FB3D6),
  Color(0xFFA48FE0),
  Color(0xFF5FBB90),
];

Color benchmarkFamilyColor(String family) {
  if (family.isEmpty) return DarkColors.accent;
  final known = _familyColors[family];
  if (known != null) return known;
  return _paletteFor(family);
}

Color benchmarkMetricColor(BenchmarkMetric metric) {
  final byKey = _metricKeyColors[metric.key];
  if (byKey != null) return byKey;
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
      return const Color(0xFF5FBB90);
    case 'proprietary':
      return const Color(0xFFD68F62);
    default:
      return kBenchmarkInkSecondary;
  }
}

Color benchmarkRankColor(int position) {
  switch (position) {
    case 1:
      return const Color(0xFFFFB800);
    case 2:
      return const Color(0xFFE2E8F0);
    case 3:
      return const Color(0xFFF97316);
    default:
      return const Color(0xFF98A2B3);
  }
}

const Color kBenchmarkScoreColor = Color(0xFFFAF7F2);

/// Lifts a provider colour while preserving vibrant brand saturation.
Color benchmarkOrgInk(Color brand) {
  final hsl = HSLColor.fromColor(brand);
  if (hsl.lightness < 0.58) {
    return hsl.withLightness(0.64).toColor();
  }
  return brand;
}

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

String benchmarkFamilyLabel(String family) =>
    _translateOr('benchmark.family.$family', family);

String benchmarkDetailLabel(String key) =>
    _translateOr('benchmark.detail.$key', key);

class BenchmarkAdaptiveGrid extends StatelessWidget {
  const BenchmarkAdaptiveGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.mainAxisExtent,
    this.preferredMaxTileWidth = 520,
    this.maxColumns = 3,
    this.spacing = 12,
  }) : assert(maxColumns > 0),
       assert(preferredMaxTileWidth > 0),
       assert(mainAxisExtent > 0);

  final int itemCount;
  final NullableIndexedWidgetBuilder itemBuilder;
  final double mainAxisExtent;
  final double preferredMaxTileWidth;
  final int maxColumns;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidthForColumnLimit =
            (constraints.maxWidth - spacing * (maxColumns - 1)) / maxColumns;
        final maxTileWidth = math.max(
          preferredMaxTileWidth,
          maxWidthForColumnLimit,
        );

        return GridView.builder(
          primary: false,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: maxTileWidth,
            mainAxisExtent: mainAxisExtent,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
          ),
          itemCount: itemCount,
          itemBuilder: itemBuilder,
        );
      },
    );
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

class BenchmarkCard extends StatelessWidget {
  const BenchmarkCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.accent,
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;

  /// Tints the top rule and the border, for cards that carry a category.
  final Color? accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return BenchmarkHover(
      enabled: onTap != null,
      builder: (context, hovered) {
        final border = accent == null
            ? (hovered
                  ? Colors.white.withValues(alpha: 0.16)
                  : kBenchmarkBorderColor)
            : accent!.withValues(alpha: hovered ? 0.5 : 0.3);

        final content = AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          padding: padding,
          decoration: BoxDecoration(
            color: hovered
                ? Color.alphaBlend(
                    (accent ?? Colors.white).withValues(alpha: 0.04),
                    kBenchmarkCardColor,
                  )
                : kBenchmarkCardColor,
            borderRadius: BorderRadius.circular(kBenchmarkCardRadius),
            border: Border.all(color: border),
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

  /// The ceiling of the bar: the best score the field reaches here. Bars start
  /// at zero, so their length reads as a share of that best score.
  final double scoreMax;
  final String scoreKind;

  final Widget? leading;
  final bool animate;

  double _fraction(double raw) {
    if (scoreMax <= 0) return 0;
    return (raw / scoreMax).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final barColor = color ?? kBenchmarkInfoColor;
    final fraction = value <= 0 ? 0.0 : _fraction(value);
    final height = compact ? 6.0 : 8.0;

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
                  color: kBenchmarkInkSecondary,
                  fontSize: compact ? 11 : 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              value <= 0 ? '—' : formatScore(value, scoreKind: scoreKind),
              style: TextStyle(
                color: value <= 0 ? kBenchmarkInkFaint : barColor,
                fontFeatures: const [FontFeature.tabularFigures()],
                fontSize: compact ? 11.5 : 13,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            if (trailing.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(
                trailing,
                style: TextStyle(color: kBenchmarkInkFaint, fontSize: 10.5),
              ),
            ],
          ],
        ),
        SizedBox(height: compact ? 5 : 7),
        SizedBox(
          height: height,
          child: Stack(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: benchmarkTrackColor(barColor),
                  borderRadius: BorderRadius.circular(height / 2),
                ),
                child: const SizedBox.expand(),
              ),
              if (fraction > 0)
                _BenchmarkBarFill(
                  fraction: fraction,
                  color: barColor,
                  height: height,
                  animate: animate,
                ),
            ],
          ),
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
      if (factor <= 0) return const SizedBox.shrink();
      return FractionallySizedBox(
        widthFactor: factor.clamp(0.0, 1.0),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(height / 2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.35),
                blurRadius: 3,
                spreadRadius: 0,
              ),
            ],
          ),
          child: const SizedBox.expand(),
        ),
      );
    }

    if (!animate) return fill(fraction);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: fraction),
      duration: const Duration(milliseconds: 540),
      curve: Curves.easeOutQuart,
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

/// The two-letter provider monogram, used wherever a row needs identity
/// without spending a full column on it.
class BenchmarkOrgMark extends StatelessWidget {
  const BenchmarkOrgMark({super.key, required this.brand, this.size = 30});

  final BenchmarkOrgBrand brand;
  final double size;

  @override
  Widget build(BuildContext context) {
    final ink = benchmarkOrgInk(brand.color);

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: ink.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(size * 0.24),
      ),
      child: Text(
        brand.mark,
        maxLines: 1,
        style: TextStyle(
          color: ink,
          fontSize: brand.mark.length > 2 ? size * 0.3 : size * 0.36,
          fontWeight: FontWeight.w700,
          height: 1,
          letterSpacing: 0.2,
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
    this.onExplainMetric,
  });

  final BenchmarkTableLayout layout;
  final BenchmarkBoard board;
  final String sort;
  final bool descending;
  final ValueChanged<String>? onSort;

  final ValueChanged<double>? onMetricWindow;

  /// A category column is too narrow for its own button, so the explanation
  /// hangs off the secondary gesture and the tooltip says so.
  final ValueChanged<String>? onExplainMetric;

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
              explainKey: metric.key,
              tooltip: _metricTooltip(metric),
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

  String _metricTooltip(BenchmarkMetric metric) {
    final lines = [
      metric.setup.isEmpty ? metric.label : '${metric.label} · ${metric.setup}',
      benchmarkMetricDescription(metric.key),
      if (onExplainMetric != null) tr('benchmark.wikiExplainColumn'),
    ];
    return lines.where((line) => line.isNotEmpty).join('\n');
  }

  Widget _cell({
    required String label,
    double? width,
    TextAlign align = TextAlign.left,
    String sortKey = '',
    String column = '',
    String explainKey = '',
    String tooltip = '',
  }) {
    final sortable = sortKey.isNotEmpty && onSort != null;
    final explain = explainKey.isNotEmpty && onExplainMetric != null
        ? () => onExplainMetric!(explainKey)
        : null;
    final active = sortable && sortKey == sort;
    final right = align == TextAlign.right;

    Color activeColor = DarkColors.accent;
    if (active) {
      if (sortKey == kBenchmarkSortPrimary) {
        activeColor = const Color(0xFFFFB800);
      } else if (sortKey == kBenchmarkSortName) {
        activeColor = kBenchmarkInfoColor;
      } else {
        final m = board.metrics.firstWhere(
          (item) => item.key == sortKey,
          orElse: () => BenchmarkMetric(
            key: sortKey,
            label: '',
            family: sortKey,
            shots: '',
            dataset: '',
            url: '',
          ),
        );
        activeColor = benchmarkMetricColor(m);
      }
    }

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
              color: active ? activeColor : kBenchmarkInkSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.7,
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
            color: activeColor,
          ),
        ],
      ],
    );

    if (sortable) {
      content = InkWell(
        key: ValueKey('benchmark-column-${column.isEmpty ? sortKey : column}'),
        onTap: () => onSort!(sortKey),
        onSecondaryTap: explain,
        onLongPress: explain,
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
    this.fieldTop = 0,
    this.onTap,
    this.onCompare,
    this.highlightMetric = '',
  });

  final BenchmarkEntry entry;
  final int position;
  final BenchmarkBoard board;
  final BenchmarkTableLayout layout;

  /// The leader's score, which ends the bar. Zero falls back to the board's
  /// own ceiling, for the rows drawn before the field statistics arrive.
  final double fieldTop;
  final VoidCallback? onTap;
  final VoidCallback? onCompare;

  final String highlightMetric;

  bool get _dense => layout.dense;

  double _fraction(double value) {
    final ceiling = fieldTop > 0 ? fieldTop : board.scoreMax;
    if (ceiling <= 0 || value <= 0) return 0;
    return (value / ceiling).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final brand = benchmarkOrgBrand(entry.subtitle);
    final rankColor = benchmarkRankColor(position);
    final activeMetric = board.metrics.firstWhere(
      (m) => m.key == highlightMetric,
      orElse: () => const BenchmarkMetric(
        key: '',
        label: '',
        family: '',
        shots: '',
        dataset: '',
        url: '',
      ),
    );
    final isMetricSort =
        activeMetric.key.isNotEmpty &&
        highlightMetric != kBenchmarkSortPrimary &&
        highlightMetric != kBenchmarkSortName;
    final scoreColor = isMetricSort
        ? benchmarkMetricColor(activeMetric)
        : rankColor;

    return BenchmarkHover(
      enabled: onTap != null,
      builder: (context, hovered) {
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOut,
              height: layout.rowHeight,
              decoration: BoxDecoration(
                color: hovered
                    ? Colors.white.withValues(alpha: 0.045)
                    : Colors.transparent,
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: 3.5,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: scoreColor.withValues(
                          alpha: hovered ? 0.95 : (position <= 3 ? 0.7 : 0.45),
                        ),
                        borderRadius: const BorderRadius.horizontal(
                          right: Radius.circular(2),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      left: BenchmarkTableLayout.rowPaddingLeft,
                      right: BenchmarkTableLayout.rowPaddingRight,
                    ),
                    child: _buildContent(
                      benchmarkOrgInk(brand.color),
                      scoreColor,
                      hovered,
                    ),
                  ),
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
                  : kBenchmarkInkFaint,
              fontFeatures: const [FontFeature.tabularFigures()],
              fontSize: _dense ? 12.5 : 14,
              fontWeight: position <= 3 ? FontWeight.w700 : FontWeight.w500,
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
              formatOrgName(entry.subtitle),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: brandColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
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
              fontFeatures: const [FontFeature.tabularFigures()],
              fontSize: _dense ? 13.5 : 15.5,
              fontWeight: FontWeight.w700,
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
            formatOrgName(entry.subtitle),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: brandColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
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
        : kBenchmarkInkSecondary;

    return Text(
      value <= 0 ? '—' : formatScore(value, scoreKind: board.scoreKind),
      maxLines: 1,
      style: TextStyle(
        color: value <= 0 ? kBenchmarkInkFaint : color,
        fontFeatures: const [FontFeature.tabularFigures()],
        fontSize: 12,
        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
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
              color: benchmarkTrackColor(scoreColor),
              borderRadius: BorderRadius.circular(3),
            ),
            child: const SizedBox.expand(),
          ),
          FractionallySizedBox(
            widthFactor: _fraction(entry.primary),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: scoreColor.withValues(alpha: hovered ? 1.0 : 0.92),
                borderRadius: BorderRadius.circular(3),
                boxShadow: [
                  if (position <= 3)
                    BoxShadow(
                      color: scoreColor.withValues(alpha: 0.35),
                      blurRadius: 4,
                      spreadRadius: 0,
                    ),
                ],
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
              style: TextStyle(color: kBenchmarkInkMuted, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: kBenchmarkInkSecondary,
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
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: kBenchmarkInk,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                  height: 1.2,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(child: Container(height: 1, color: kBenchmarkHairline)),
            if (trailing != null) ...[const SizedBox(width: 14), trailing!],
          ],
        ),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Text(
              subtitle,
              style: TextStyle(
                color: kBenchmarkInkMuted,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
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

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            color: kBenchmarkInkMuted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(width: 8),
        PopupMenuButton<String>(
          key: widget.menuKey,
          tooltip: widget.label,
          padding: EdgeInsets.zero,
          position: PopupMenuPosition.under,
          offset: const Offset(0, 6),
          constraints: BoxConstraints.tightFor(width: widget.width),
          menuPadding: const EdgeInsets.all(6),
          color: const Color(0xFF17171B),
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.black.withValues(alpha: 0.55),
          elevation: 14,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
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
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? option.color.withValues(alpha: 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Row(
                  children: [
                    option.leading ?? _dot(option.color),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        option.label,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isSelected ? Colors.white : kBenchmarkInkMuted,
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                    if (option.count != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        formatCount(option.count!),
                        style: TextStyle(
                          color: kBenchmarkInkFaint,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    if (isSelected) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.check_rounded, size: 14, color: option.color),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOut,
            width: widget.width,
            height: 34,
            padding: const EdgeInsets.only(left: 12, right: 8),
            decoration: BoxDecoration(
              color: _open
                  ? Colors.white.withValues(alpha: 0.07)
                  : kBenchmarkFieldColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _open
                    ? Colors.white.withValues(alpha: 0.28)
                    : Colors.white.withValues(alpha: 0.12),
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
                    style: TextStyle(
                      color: kBenchmarkInkSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  Icons.expand_more_rounded,
                  size: 16,
                  color: _open ? kBenchmarkInkSecondary : kBenchmarkInkFaint,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _dot(Color color) => Container(
    width: 7,
    height: 7,
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
