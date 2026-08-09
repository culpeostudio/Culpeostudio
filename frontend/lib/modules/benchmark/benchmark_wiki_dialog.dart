import 'package:flutter/material.dart';

import '../../core/app_strings.dart';
import '../../core/dark_theme.dart';
import './benchmark_metric_art.dart';
import './benchmark_models.dart';
import './benchmark_widgets.dart';

/// Opens the wiki, optionally unfolded on the entry that explains [metricKey].
Future<void> showBenchmarkWiki(
  BuildContext context, {
  required BenchmarkBoard board,
  Map<String, BenchmarkMetricStats> stats = const {},
  Map<String, List<BenchmarkEntry>> leaders = const {},
  String metricKey = '',
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => BenchmarkWikiDialog(
      board: board,
      stats: stats,
      leaders: leaders,
      initialMetric: metricKey,
    ),
  );
}

/// Everything the board does not explain by itself: what the headline number
/// means, and what each category actually asks of a model.
///
/// The categories used to sit in an overview tab nobody read on the way to the
/// leaderboard. Here they are one tap away from every place a category name
/// appears, and each one stays folded until it is asked for.
class BenchmarkWikiDialog extends StatefulWidget {
  const BenchmarkWikiDialog({
    super.key,
    required this.board,
    this.stats = const {},
    this.leaders = const {},
    this.initialMetric = '',
  });

  final BenchmarkBoard board;
  final Map<String, BenchmarkMetricStats> stats;
  final Map<String, List<BenchmarkEntry>> leaders;
  final String initialMetric;

  @override
  State<BenchmarkWikiDialog> createState() => _BenchmarkWikiDialogState();
}

class _BenchmarkWikiDialogState extends State<BenchmarkWikiDialog> {
  final Map<String, GlobalKey> _anchors = {};
  late String _open = widget.initialMetric;

  @override
  void initState() {
    super.initState();
    if (widget.initialMetric.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _revealInitial());
    }
  }

  void _revealInitial() {
    final anchor = _anchors[widget.initialMetric]?.currentContext;
    if (anchor == null) return;
    Scrollable.ensureVisible(
      anchor,
      alignment: 0.1,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  void _toggle(String key) {
    setState(() => _open = _open == key ? '' : key);
  }

  GlobalKey _anchorOf(String key) => _anchors.putIfAbsent(key, GlobalKey.new);

  String get _primaryLabel => widget.board.primaryLabel.isEmpty
      ? tr('benchmark.sortAverage')
      : widget.board.primaryLabel;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700, maxHeight: 720),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF101014),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              Flexible(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final source = widget.board.source;

    return Container(
      padding: const EdgeInsets.fromLTRB(22, 18, 12, 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: kBenchmarkHairline)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: DarkColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.menu_book_outlined,
              size: 18,
              color: DarkColors.accent,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tr('benchmark.wikiTitle'),
                  style: const TextStyle(
                    color: kBenchmarkInk,
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  benchmarkBoardLabel(widget.board),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: kBenchmarkInkMuted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (source.provider.isNotEmpty) ...[
            const SizedBox(width: 12),
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: BenchmarkChip(
                label: source.provider,
                icon: source.live
                    ? Icons.sensors_rounded
                    : Icons.inventory_2_outlined,
              ),
            ),
          ],
          IconButton(
            key: const ValueKey('benchmark-wiki-close'),
            icon: const Icon(Icons.close, size: 19),
            color: Colors.white.withValues(alpha: 0.6),
            tooltip: tr('common.close'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final metrics = widget.board.metrics;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
      children: [
        Text(
          tr('benchmark.wikiIntro'),
          style: TextStyle(
            color: kBenchmarkInkSecondary,
            fontSize: 13,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 24),
        BenchmarkSectionTitle(title: tr('benchmark.wikiReading')),
        const SizedBox(height: 14),
        for (final entry in _readingEntries()) ...[
          entry,
          const SizedBox(height: 8),
        ],
        if (metrics.isNotEmpty) ...[
          const SizedBox(height: 22),
          BenchmarkSectionTitle(
            title: tr('benchmark.wikiCategories'),
            subtitle: tr('benchmark.wikiCategoriesHint'),
          ),
          const SizedBox(height: 14),
          for (final metric in metrics) ...[
            _buildMetricEntry(metric),
            const SizedBox(height: 8),
          ],
        ],
      ],
    );
  }

  List<Widget> _readingEntries() {
    final elo = widget.board.scoreKind == 'elo';

    final entries = <_WikiTopic>[
      _WikiTopic(
        key: 'score',
        icon: Icons.speed_rounded,
        color: DarkColors.accent,
        title: tr('benchmark.wikiScoreTitle', {'label': _primaryLabel}),
        text: elo
            ? tr('benchmark.wikiScoreElo')
            : tr('benchmark.wikiScorePercent', {
                'max': formatScore(
                  widget.board.scoreMax,
                  scoreKind: widget.board.scoreKind,
                ),
              }),
      ),
      _WikiTopic(
        key: 'rank',
        icon: Icons.emoji_events_outlined,
        color: benchmarkRankColor(2),
        title: tr('benchmark.wikiRankTitle'),
        text: tr('benchmark.wikiRankText'),
      ),
      _WikiTopic(
        key: 'type',
        icon: Icons.lock_open_rounded,
        color: benchmarkTypeColor('open_weights'),
        title: tr('benchmark.wikiTypeTitle'),
        text: tr('benchmark.wikiTypeText', {
          'open': benchmarkTypeLabel('open_weights'),
          'api': benchmarkTypeLabel('proprietary'),
        }),
      ),
      _WikiTopic(
        key: 'compare',
        icon: Icons.compare_arrows,
        color: const Color(0xFF6FBFC7),
        title: tr('benchmark.wikiCompareTitle'),
        text: tr('benchmark.wikiCompareText'),
      ),
      _WikiTopic(
        key: 'source',
        icon: Icons.update_rounded,
        color: const Color(0xFF8AC194),
        title: tr('benchmark.wikiSourceTitle'),
        text: tr('benchmark.wikiSourceText'),
      ),
    ];

    return [
      for (final topic in entries)
        _WikiEntry(
          key: ValueKey('benchmark-wiki-${topic.key}'),
          color: topic.color,
          icon: topic.icon,
          title: topic.title,
          expanded: _open == topic.key,
          onTap: () => _toggle(topic.key),
          child: _paragraph(topic.text),
        ),
    ];
  }

  Widget _buildMetricEntry(BenchmarkMetric metric) {
    final color = benchmarkMetricColor(metric);
    final stats = widget.stats[metric.key];
    final leaders = widget.leaders[metric.key] ?? const <BenchmarkEntry>[];
    final description = benchmarkMetricDescription(metric.key);
    final rated = stats != null && stats.evaluated > 0;

    return _WikiEntry(
      key: ValueKey('benchmark-wiki-metric-${metric.key}'),
      anchor: _anchorOf(metric.key),
      color: color,
      title: metric.label,
      subtitle: metric.family.isEmpty
          ? metric.setup
          : benchmarkFamilyLabel(metric.family),
      trailing: rated
          ? tr('benchmark.metricEvaluated', {
              'count': formatCount(stats.evaluated),
            })
          : '',
      expanded: _open == metric.key,
      onTap: () => _toggle(metric.key),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _paragraph(
            description.isEmpty
                ? tr('benchmark.wikiNoDescription')
                : description,
          ),
          if (metric.setup.isNotEmpty && metric.family.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              metric.setup,
              style: TextStyle(color: kBenchmarkInkFaint, fontSize: 11.5),
            ),
          ],
          const SizedBox(height: 16),
          BenchmarkMetricSpan(
            key: ValueKey('benchmark-wiki-art-${metric.key}'),
            metric: metric,
            stats: stats,
            board: widget.board,
          ),
          if (leaders.isNotEmpty) ...[
            const SizedBox(height: 14),
            _buildLeader(metric, leaders.first, color),
          ],
        ],
      ),
    );
  }

  Widget _buildLeader(
    BenchmarkMetric metric,
    BenchmarkEntry entry,
    Color color,
  ) {
    final score = entry.scoreOf(metric.key);

    return Container(
      padding: const EdgeInsets.only(top: 11),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: kBenchmarkHairline)),
      ),
      child: Row(
        children: [
          Text(
            tr('benchmark.metricLeader'),
            style: TextStyle(color: kBenchmarkInkFaint, fontSize: 11),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              entry.shortName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: kBenchmarkInkSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            score <= 0
                ? '—'
                : formatScore(score, scoreKind: widget.board.scoreKind),
            style: TextStyle(
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _paragraph(String text) {
    return Text(
      text,
      style: TextStyle(
        color: kBenchmarkInkSecondary,
        fontSize: 12.5,
        height: 1.6,
      ),
    );
  }
}

class _WikiTopic {
  const _WikiTopic({
    required this.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.text,
  });

  final String key;
  final IconData icon;
  final Color color;
  final String title;
  final String text;
}

/// One foldable point: a headline row that stays readable on its own, and the
/// explanation underneath once it is asked for.
class _WikiEntry extends StatelessWidget {
  const _WikiEntry({
    super.key,
    required this.title,
    required this.color,
    required this.expanded,
    required this.onTap,
    required this.child,
    this.anchor,
    this.icon,
    this.subtitle = '',
    this.trailing = '',
  });

  final String title;
  final String subtitle;
  final String trailing;
  final Color color;
  final IconData? icon;
  final bool expanded;
  final VoidCallback onTap;
  final Widget child;
  final Key? anchor;

  @override
  Widget build(BuildContext context) {
    return BenchmarkHover(
      builder: (context, hovered) {
        return Container(
          key: anchor,
          decoration: BoxDecoration(
            color: expanded
                ? Color.alphaBlend(
                    color.withValues(alpha: 0.03),
                    kBenchmarkCardColor,
                  )
                : (hovered ? kBenchmarkCardColor : Colors.transparent),
            borderRadius: BorderRadius.circular(kBenchmarkCardRadius),
            border: Border.all(
              color: expanded
                  ? color.withValues(alpha: 0.34)
                  : (hovered
                        ? Colors.white.withValues(alpha: 0.12)
                        : kBenchmarkBorderColor),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(onTap: onTap, child: _buildHead()),
                AnimatedSize(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: expanded
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: child,
                        )
                      : const SizedBox(width: double.infinity),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHead() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 13, 12, 13),
      child: Row(
        children: [
          if (icon != null)
            Icon(icon, size: 15, color: color)
          else
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: kBenchmarkInk,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color.withValues(alpha: 0.9),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing.isNotEmpty) ...[
            const SizedBox(width: 10),
            Text(
              trailing,
              maxLines: 1,
              style: TextStyle(color: kBenchmarkInkFaint, fontSize: 11),
            ),
          ],
          const SizedBox(width: 6),
          AnimatedRotation(
            turns: expanded ? 0.5 : 0,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            child: Icon(
              Icons.expand_more_rounded,
              size: 18,
              color: expanded ? color : kBenchmarkInkFaint,
            ),
          ),
        ],
      ),
    );
  }
}
