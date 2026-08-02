import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../theme/dark_theme.dart';
import 'benchmark_models.dart';
import 'benchmark_orgs.dart';
import 'benchmark_widgets.dart';

class BenchmarkOverviewTab extends StatelessWidget {
  const BenchmarkOverviewTab({
    super.key,
    required this.overview,
    required this.onOpenModel,
    required this.onShowLeaderboard,
  });

  final BenchmarkOverview overview;
  final void Function(BenchmarkEntry entry) onOpenModel;

  final VoidCallback onShowLeaderboard;

  BenchmarkBoard get _board => overview.board;

  String get _primaryLabel => _board.primaryLabel.isEmpty
      ? tr('benchmark.sortAverage')
      : _board.primaryLabel;

  List<BenchmarkEntry> get _top => overview.topOverall;

  List<BenchmarkEntry> _leadersOf(String metricKey) =>
      overview.topByMetric[metricKey] ?? const [];

  int get _remaining {
    final total = overview.totalModels;
    final shown = _top.length;
    return total > shown ? total - shown : 0;
  }

  @override
  Widget build(BuildContext context) {
    final top = _top;
    final podium = top.take(3).toList();
    final rest = top.length > 3 ? top.sublist(3) : const <BenchmarkEntry>[];

    return ListView(
      padding: const EdgeInsets.fromLTRB(kBenchmarkInset, 4, 24, 36),
      children: [
        BenchmarkSectionTitle(title: tr('benchmark.topOverall')),
        const SizedBox(height: 16),
        if (podium.isEmpty)
          _buildEmpty()
        else ...[
          _buildPodium(podium),
          if (rest.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildRest(rest),
          ],
          _buildShowAll(),
        ],
        if (_board.metrics.isNotEmpty) ...[
          const SizedBox(height: 32),
          BenchmarkSectionTitle(
            title: tr('benchmark.metricsTitle'),
            subtitle: tr('benchmark.metricsSubtitle'),
          ),
          const SizedBox(height: 16),
          _buildMetricGrid(),
        ],
      ],
    );
  }

  Widget _buildRest(List<BenchmarkEntry> rest) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = BenchmarkTableLayout.of(
          width: constraints.maxWidth,
          board: _board,
        );

        return Column(
          children: [
            BenchmarkTableHeader(layout: layout, board: _board),
            for (var index = 0; index < rest.length; index++)
              BenchmarkTableRow(
                entry: rest[index],

                position: index + 4,
                board: _board,
                layout: layout,
                onTap: () => onOpenModel(rest[index]),
              ),
          ],
        );
      },
    );
  }

  Widget _buildShowAll() {
    final remaining = _remaining;

    return Column(
      children: [
        const SizedBox(height: 22),
        if (remaining > 0) ...[
          Text(
            tr('benchmark.showAllCount', {'count': formatCount(remaining)}),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 11.5,
            ),
          ),
          const SizedBox(height: 10),
        ],
        OutlinedButton.icon(
          key: const ValueKey('benchmark-show-all'),
          onPressed: onShowLeaderboard,
          icon: const Icon(Icons.arrow_downward_rounded, size: 16),
          label: Text(tr('benchmark.showAll')),
          style: OutlinedButton.styleFrom(
            foregroundColor: DarkColors.accent,
            side: BorderSide(color: DarkColors.accent.withValues(alpha: 0.35)),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            textStyle: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(
            Icons.lock_open,
            size: 38,
            color: Colors.white.withValues(alpha: 0.18),
          ),
          const SizedBox(height: 14),
          Text(
            tr('benchmark.empty'),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodium(List<BenchmarkEntry> podium) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 940
            ? 3
            : constraints.maxWidth > 600
            ? 2
            : 1;
        final width = (constraints.maxWidth - (columns - 1) * 14) / columns;
        final leader = podium.first.primary;

        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            for (var index = 0; index < podium.length; index++)
              SizedBox(
                width: width,
                child: _buildPodiumCard(podium[index], index + 1, leader),
              ),
          ],
        );
      },
    );
  }

  Widget _buildPodiumCard(BenchmarkEntry entry, int position, double leader) {
    final medal = benchmarkRankColor(position);
    final brand = benchmarkOrgBrand(entry.subtitle);
    final span = _board.scoreMax - _board.scoreFloor;
    final fraction = span <= 0
        ? 0.0
        : ((entry.primary - _board.scoreFloor) / span).clamp(0.0, 1.0);
    final behind = leader - entry.primary;

    final entrance = Interval(
      0.12 * (position - 1),
      0.72 + 0.12 * (position - 1),
      curve: Curves.easeOutCubic,
    );

    return BenchmarkHover(
      builder: (context, hovered) => AnimatedSlide(
        offset: hovered ? const Offset(0, -0.02) : Offset.zero,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 900),
          curve: entrance,
          builder: (context, appear, _) => Opacity(
            opacity: appear.clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(0, (1 - appear) * 20),
              child: Transform.scale(
                scale: 0.96 + 0.04 * appear,
                child: _buildPodiumBody(
                  entry,
                  position,
                  medal,
                  brand,
                  fraction,
                  behind,
                  hovered,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPodiumBody(
    BenchmarkEntry entry,
    int position,
    Color medal,
    BenchmarkOrgBrand brand,
    double fraction,
    double behind,
    bool hovered,
  ) {
    return BenchmarkCard(
      accent: medal,
      glow: position == 1,
      padding: EdgeInsets.zero,
      onTap: () => onOpenModel(entry),
      child: SizedBox(
        height: 208,
        child: Stack(
          children: [
            Positioned(
              right: 4,
              bottom: -34,
              child: AnimatedScale(
                scale: hovered ? 1.12 : 1,
                alignment: Alignment.bottomRight,
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOutCubic,
                  style: TextStyle(
                    color: medal.withValues(alpha: hovered ? 0.14 : 0.07),
                    fontSize: 132,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                  child: Text('$position'),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOutCubic,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: hovered
                              ? [
                                  BoxShadow(
                                    color: medal.withValues(alpha: 0.4),
                                    blurRadius: 16,
                                    spreadRadius: -3,
                                  ),
                                ]
                              : null,
                        ),
                        child: BenchmarkRankBadge(position: position, size: 32),
                      ),
                      const Spacer(),
                      if (position == 1)
                        Icon(
                          Icons.workspace_premium_rounded,
                          size: 20,
                          color: medal.withValues(alpha: 0.85),
                        ),
                    ],
                  ),
                  const SizedBox(height: 13),
                  Text(
                    entry.shortName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    entry.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: brand.color.withValues(alpha: 0.9),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        style: TextStyle(
                          color: medal,
                          fontSize: hovered ? 32 : 30,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                          height: 1,
                        ),
                        child: Text(
                          formatScore(
                            entry.primary,
                            scoreKind: _board.scoreKind,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _primaryLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.35),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    height: hovered ? 8 : 6,
                    child: Stack(
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const SizedBox.expand(),
                        ),
                        FractionallySizedBox(
                          widthFactor: fraction,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [medal.withValues(alpha: 0.45), medal],
                              ),
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: hovered
                                  ? [
                                      BoxShadow(
                                        color: medal.withValues(alpha: 0.45),
                                        blurRadius: 10,
                                        spreadRadius: -2,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (entry.type.isNotEmpty)
                        Flexible(
                          child: BenchmarkChip(
                            label: benchmarkTypeLabel(entry.type),
                            color: benchmarkTypeColor(entry.type),
                          ),
                        ),
                      if (position > 1 && behind > 0) ...[
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            tr('benchmark.behindLeader', {
                              'diff': formatScore(
                                behind,
                                scoreKind: _board.scoreKind,
                              ),
                            }),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.34),
                              fontSize: 10.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            if (hovered)
              Positioned.fill(
                child: BenchmarkSheen(
                  color: medal,
                  diagonal: true,
                  radius: kBenchmarkCardRadius,
                  strength: 0.16,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 1100
            ? 3
            : constraints.maxWidth > 700
            ? 2
            : 1;
        final width = (constraints.maxWidth - (columns - 1) * 12) / columns;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final metric in _board.metrics)
              SizedBox(width: width, child: _buildMetricCard(metric)),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard(BenchmarkMetric metric) {
    final stats = overview.metricStats[metric.key];
    final leaders = _leadersOf(metric.key);
    final description = benchmarkMetricDescription(metric.key);
    final color = benchmarkMetricColor(metric);

    return BenchmarkCard(
      accent: color,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Icon(
                  benchmarkFamilyIcon(metric.family),
                  size: 15,
                  color: color,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  metric.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (metric.setup.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              metric.setup,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.32),
                fontSize: 10.5,
                letterSpacing: 0.2,
              ),
            ),
          ],
          if (description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              description,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.62),
                fontSize: 12.5,
                height: 1.5,
              ),
            ),
          ],

          if (stats == null || stats.evaluated == 0) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 13,
                  color: Colors.white.withValues(alpha: 0.28),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    tr('benchmark.metricNoData'),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (stats != null && stats.evaluated > 0) ...[
            const SizedBox(height: 16),
            BenchmarkScoreBar(
              label: tr('benchmark.metricMedian', {
                'value': formatScore(stats.median, scoreKind: _board.scoreKind),
              }),
              value: stats.median,
              trailing: tr('benchmark.metricBest', {
                'value': formatScore(stats.max, scoreKind: _board.scoreKind),
              }),
              color: color,
              compact: true,
              scoreMax: _board.scoreMax,
              scoreFloor: _board.scoreFloor,
              scoreKind: _board.scoreKind,
            ),
          ],
          if (leaders.isNotEmpty) ...[
            const SizedBox(height: 14),
            _buildMetricLeader(leaders.first, color),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricLeader(BenchmarkEntry entry, Color color) {
    return Material(
      color: Colors.white.withValues(alpha: 0.025),
      borderRadius: BorderRadius.circular(9),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => onOpenModel(entry),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 7, 10, 7),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  entry.shortName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.workspace_premium_outlined,
                size: 13,
                color: color.withValues(alpha: 0.8),
              ),
              const SizedBox(width: 5),
              Text(
                formatScore(entry.primary, scoreKind: _board.scoreKind),
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
