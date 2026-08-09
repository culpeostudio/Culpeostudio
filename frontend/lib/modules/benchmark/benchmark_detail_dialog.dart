import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_strings.dart';
import '../../core/dark_theme.dart';
import '../../core/top_notification.dart';
import './benchmark_models.dart';
import './benchmark_orgs.dart';
import './benchmark_widgets.dart';

class BenchmarkDetailDialog extends StatefulWidget {
  const BenchmarkDetailDialog({
    super.key,
    required this.modelId,
    required this.board,
    required this.loadDetail,
    this.fieldTops = BenchmarkFieldTops.empty,
    this.onCompare,
    this.onOpenMetric,
  });

  final String modelId;
  final BenchmarkBoard board;
  final Future<Map<String, dynamic>> Function(String modelId) loadDetail;

  /// The best score of the field, which every bar here uses as its ceiling.
  final BenchmarkFieldTops fieldTops;
  final void Function(String modelId)? onCompare;

  /// Opens the wiki on a category, for readers who wonder what it measures.
  final void Function(String metricKey)? onOpenMetric;

  @override
  State<BenchmarkDetailDialog> createState() => _BenchmarkDetailDialogState();
}

class _BenchmarkDetailDialogState extends State<BenchmarkDetailDialog> {
  BenchmarkModelDetail? _detail;
  String? _error;
  bool _isLoading = true;
  late String _modelId = widget.modelId;

  @override
  void initState() {
    super.initState();
    _load(_modelId);
  }

  Future<void> _load(String modelId) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _modelId = modelId;
    });
    try {
      final response = await widget.loadDetail(modelId);
      if (!mounted) return;
      setState(() {
        _detail = BenchmarkModelDetail.fromJson(response);
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = '$error';
        _isLoading = false;
      });
    }
  }

  Future<void> _openLink(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || url.isEmpty) return;
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        showTopNotification(
          context,
          tr('benchmark.openLinkFailed', {'url': url}),
          color: Color(0xFFDE8F8F),
        );
      }
    } catch (_) {
      if (!mounted) return;
      showTopNotification(
        context,
        tr('benchmark.openLinkFailed', {'url': url}),
        color: Color(0xFFDE8F8F),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 780),
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

  String get _orgName {
    final detail = _detail;
    final fromEntry = detail?.best?.subtitle ?? '';
    if (fromEntry.isNotEmpty) return fromEntry;
    final id = detail?.modelId ?? '';
    final slash = id.indexOf('/');
    return slash > 0 ? id.substring(0, slash) : '';
  }

  Widget _buildHeader() {
    final detail = _detail;
    final title = detail?.name.isNotEmpty == true ? detail!.name : _modelId;
    final best = detail?.best;
    final org = _orgName;
    final brand = benchmarkOrgBrand(org);
    final medal = best == null
        ? DarkColors.accent
        : benchmarkRankColor(best.rank);

    return Container(
      padding: const EdgeInsets.fromLTRB(22, 20, 14, 18),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: kBenchmarkHairline)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: kBenchmarkInk,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.4,
                  ),
                ),
                if (org.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    formatOrgName(org),
                    style: TextStyle(
                      color: benchmarkOrgInk(brand.color),
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
                if (best != null) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      BenchmarkChip(
                        label: tr('benchmark.detailRank', {
                          'rank': '${best.rank}',
                          'total': formatCount(detail!.source.entries),
                        }),
                        color: medal,
                        icon: Icons.emoji_events_outlined,
                      ),
                      BenchmarkChip(label: widget.board.label),
                      if (best.type.isNotEmpty)
                        BenchmarkChip(
                          label: benchmarkTypeLabel(best.type),
                          color: benchmarkTypeColor(best.type),
                        ),
                      if (best.license.isNotEmpty)
                        BenchmarkChip(label: best.license),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (best != null) ...[
            const SizedBox(width: 16),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    formatScore(
                      best.primary,
                      scoreKind: widget.board.scoreKind,
                    ),
                    style: TextStyle(
                      color: medal,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      fontSize: 30,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -1,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.board.primaryLabel.isEmpty
                        ? tr('benchmark.sortAverage')
                        : widget.board.primaryLabel,
                    style: TextStyle(
                      color: kBenchmarkInkMuted,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
          ],
          if (widget.onCompare != null)
            IconButton(
              icon: const Icon(Icons.compare_arrows),
              color: Colors.white.withValues(alpha: 0.6),
              tooltip: tr('benchmark.addToCompare'),
              onPressed: () => widget.onCompare!(_modelId),
            ),
          if (detail?.hubUrl.isNotEmpty == true ||
              detail?.best?.url.isNotEmpty == true)
            IconButton(
              icon: const Icon(Icons.open_in_new, size: 19),
              color: Colors.white.withValues(alpha: 0.6),
              tooltip: tr('benchmark.openOnHub'),
              onPressed: () => _openLink(
                detail!.hubUrl.isNotEmpty ? detail.hubUrl : detail.best!.url,
              ),
            ),
          IconButton(
            icon: const Icon(Icons.close),
            color: Colors.white.withValues(alpha: 0.6),
            tooltip: tr('common.close'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 80),
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(DarkColors.accent),
          ),
        ),
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFDE8F8F), fontSize: 13),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _load(_modelId),
              child: Text(tr('common.retry')),
            ),
          ],
        ),
      );
    }

    final detail = _detail;
    if (detail == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!detail.hasLeaderboardData)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: BenchmarkCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 16,
                      color: DarkColors.accent,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        tr('benchmark.noLeaderboardEntry'),
                        style: TextStyle(
                          color: kBenchmarkInkSecondary,
                          fontSize: 12.5,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (detail.hasLeaderboardData) ...[
            _buildScoresSection(detail),
            const SizedBox(height: 24),
            _buildFactsSection(detail),
          ],
          if (detail.hub != null) ...[
            const SizedBox(height: 24),
            _buildHubSection(detail.hub!),
          ],
          if (detail.cardResults.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildCardResultsSection(detail),
          ],
        ],
      ),
    );
  }

  Widget _buildScoresSection(BenchmarkModelDetail detail) {
    final best = detail.best!;
    final primary = detail.deltas['primary'];
    final metrics = detail.metrics.isNotEmpty
        ? detail.metrics
        : widget.board.metrics;

    // Every bar starts at zero and ends at the best score the field reaches in
    // that same category, so a full bar means "nobody scores higher here".
    final tops = widget.fieldTops;
    final headline = tops.primaryCeiling(
      fallback: math.max(
        best.primary,
        math.max(primary?.median ?? 0, widget.board.scoreMax),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BenchmarkSectionTitle(
          title: tr('benchmark.detailScores'),
          subtitle: tr('benchmark.detailPercentile', {
            'value': detail.percentile.toStringAsFixed(1),
          }),
        ),
        const SizedBox(height: 16),
        BenchmarkCard(
          accent: DarkColors.accent,
          child: Column(
            children: [
              BenchmarkScoreBar(
                label: widget.board.primaryLabel.isEmpty
                    ? tr('benchmark.sortAverage')
                    : widget.board.primaryLabel,
                value: best.primary,
                median: primary?.median,
                color: kBenchmarkInfoColor,
                trailing: primary == null ? '' : _deltaText(primary.diff),
                scoreMax: headline,
                scoreKind: widget.board.scoreKind,
              ),
              const SizedBox(height: 8),
              Divider(color: Colors.white.withValues(alpha: 0.05), height: 20),

              for (final metric in metrics) ...[
                _explainable(
                  metric.key,
                  BenchmarkScoreBar(
                    label: metric.label,
                    value: best.scoreOf(metric.key),
                    median: detail.deltas[metric.key]?.median,
                    color: benchmarkMetricColor(metric),
                    trailing: best.scoreOf(metric.key) <= 0
                        ? ''
                        : tr('benchmark.detailRankShort', {
                            'rank': formatCount(
                              detail.metricRanks[metric.key] ?? 0,
                            ),
                          }),
                    compact: true,
                    scoreMax: tops.ceilingOf(
                      metric.key,
                      fallback: math.max(
                        best.scoreOf(metric.key),
                        math.max(
                          detail.deltas[metric.key]?.median ?? 0,
                          widget.board.scoreMax,
                        ),
                      ),
                    ),
                    scoreKind: widget.board.scoreKind,
                  ),
                ),
                if (metric != metrics.last) const SizedBox(height: 14),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// Wraps a category bar so tapping it opens what that category measures.
  Widget _explainable(String metricKey, Widget child) {
    final open = widget.onOpenMetric;
    if (open == null) return child;

    return Tooltip(
      message: tr('benchmark.wikiExplain'),
      waitDuration: const Duration(milliseconds: 400),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey('benchmark-explain-$metricKey'),
          onTap: () => open(metricKey),
          // Vertical only: horizontal padding would push the category bars
          // out of line with the headline bar above them.
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: child,
          ),
        ),
      ),
    );
  }

  String _deltaText(double diff) {
    final formatted = diff.abs().toStringAsFixed(
      widget.board.scoreKind == 'elo' ? 0 : 1,
    );
    return diff >= 0
        ? tr('benchmark.detailVsMedianUp', {'diff': formatted})
        : tr('benchmark.detailVsMedianDown', {'diff': formatted});
  }

  Widget _buildFactsSection(BenchmarkModelDetail detail) {
    final best = detail.best!;
    final tiles = <Widget>[
      if (best.type.isNotEmpty)
        _factTile(
          tr('benchmark.factType'),
          benchmarkTypeLabel(best.type),
          best.openWeights ? Icons.public_rounded : Icons.lock_rounded,
          benchmarkTypeColor(best.type),
        ),
      if (best.org.isNotEmpty)
        _factTile(
          tr('benchmark.factOrg'),
          best.org,
          Icons.apartment_rounded,
          benchmarkOrgBrand(best.org).color,
        ),
      if (best.license.isNotEmpty)
        _factTile(
          tr('benchmark.factLicense'),
          best.license,
          Icons.badge_outlined,
          const Color(0xFF7DA0E8),
        ),
      if (best.evalDate.isNotEmpty)
        _factTile(
          tr('benchmark.factSubmitted'),
          best.evalDate,
          Icons.update_rounded,
          const Color(0xFF8AC194),
        ),
      for (final fact in best.details)
        _factTile(
          benchmarkDetailLabel(fact.key),
          fact.value,
          _detailIcon(fact.key),
          _detailColor(fact.key),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BenchmarkSectionTitle(title: tr('benchmark.detailFacts')),
        const SizedBox(height: 12),
        BenchmarkCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(spacing: 10, runSpacing: 10, children: tiles),
              if (detail.entries.length > 1) ...[
                const SizedBox(height: 16),
                Divider(color: Colors.white.withValues(alpha: 0.05)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.history_rounded,
                      size: 14,
                      color: kBenchmarkInkFaint,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      tr('benchmark.detailRuns'),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    for (final entry in detail.entries)
                      BenchmarkChip(
                        label:
                            '${_runLabel(entry)} · '
                            '${formatScore(entry.primary, scoreKind: widget.board.scoreKind)}',
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  IconData _detailIcon(String key) {
    switch (key) {
      case 'votes':
        return Icons.how_to_vote_outlined;
      case 'confidence':
        return Icons.verified_outlined;
      case 'variance':
        return Icons.shuffle_rounded;
      case 'arena_rank':
        return Icons.emoji_events_outlined;
      default:
        return Icons.tag_rounded;
    }
  }

  Color _detailColor(String key) {
    switch (key) {
      case 'votes':
        return const Color(0xFFD9B05E);
      case 'confidence':
        return const Color(0xFF5FB3D6);
      case 'variance':
        return const Color(0xFFE07AB8);
      case 'arena_rank':
        return const Color(0xFFFFB800);
      default:
        return const Color(0xFF8F96DE);
    }
  }

  Widget _factTile(String label, String value, IconData icon, Color color) {
    return Container(
      width: 162,
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kBenchmarkBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: kBenchmarkInkMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: kBenchmarkInk,
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  String _runLabel(BenchmarkEntry entry) {
    for (final detail in entry.details) {
      if (detail.key == 'precision') return detail.value;
    }
    return entry.key;
  }

  Widget _buildHubSection(BenchmarkHubStats hub) {
    if (hub.missing) {
      return BenchmarkCard(
        child: Row(
          children: [
            const Icon(Icons.link_off, size: 16, color: Color(0xFFDDA872)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                tr('benchmark.hubMissing'),
                style: TextStyle(color: kBenchmarkInkSecondary, fontSize: 12.5),
              ),
            ),
          ],
        ),
      );
    }

    const hubColor = Color(0xFFF5B33C);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BenchmarkSectionTitle(title: tr('benchmark.hubTitle')),
        const SizedBox(height: 12),
        BenchmarkCard(
          accent: hubColor,
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _hubMetric(
                    tr('benchmark.hubDownloads'),
                    formatCompact(hub.downloads30d),
                    Icons.download_rounded,
                    const Color(0xFF6FBFC7),
                  ),
                  if (hub.downloadsAllTime > 0)
                    _hubMetric(
                      tr('benchmark.hubDownloadsTotal'),
                      formatCompact(hub.downloadsAllTime),
                      Icons.cloud_download_outlined,
                      const Color(0xFF7C9CF0),
                    ),
                  _hubMetric(
                    tr('benchmark.hubLikes'),
                    formatCount(hub.likes),
                    Icons.favorite_rounded,
                    const Color(0xFFE07AB8),
                  ),
                  if (hub.trendingScore > 0)
                    _hubMetric(
                      tr('benchmark.hubTrending'),
                      hub.trendingScore.toStringAsFixed(0),
                      Icons.trending_up_rounded,
                      const Color(0xFFE08A4A),
                    ),
                  if (hub.paramsTotal > 0)
                    _hubMetric(
                      tr('benchmark.hubParams'),
                      formatCompact(hub.paramsTotal),
                      Icons.memory_rounded,
                      const Color(0xFFB79AD6),
                    ),
                  if (hub.lastModified.isNotEmpty)
                    _hubMetric(
                      tr('benchmark.hubUpdated'),
                      formatIsoDate(hub.lastModified),
                      Icons.update_rounded,
                      const Color(0xFF8AC194),
                    ),
                ],
              ),
              if (hub.providers.isNotEmpty || hub.gated) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    if (hub.gated)
                      BenchmarkChip(
                        label: tr('benchmark.hubGated'),
                        icon: Icons.lock_outline,
                        color: const Color(0xFFE05A73),
                      ),
                    for (final provider in hub.providers)
                      BenchmarkChip(
                        label: provider,
                        icon: Icons.cloud_outlined,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _hubMetric(String label, String value, IconData icon, Color color) {
    return Container(
      width: 154,
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kBenchmarkBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: kBenchmarkInkMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: kBenchmarkInk,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardResultsSection(BenchmarkModelDetail detail) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BenchmarkSectionTitle(
          title: tr('benchmark.cardResults'),
          subtitle: tr('benchmark.cardResultsNote'),
        ),
        const SizedBox(height: 12),
        BenchmarkCard(
          child: Column(
            children: [
              for (final result in detail.cardResults.take(12))
                BenchmarkFactRow(
                  label: result.dataset.isEmpty
                      ? result.metric
                      : result.dataset,
                  value: '${result.metric}: ${result.value.toStringAsFixed(1)}',
                ),
            ],
          ),
        ),
      ],
    );
  }
}
