import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_strings.dart';
import '../../theme/dark_theme.dart';
import '../../widgets/top_notification.dart';
import 'benchmark_models.dart';
import 'benchmark_orgs.dart';
import 'benchmark_widgets.dart';

class BenchmarkDetailDialog extends StatefulWidget {
  const BenchmarkDetailDialog({
    super.key,
    required this.modelId,
    required this.board,
    required this.loadDetail,
    this.onCompare,
  });

  final String modelId;
  final BenchmarkBoard board;
  final Future<Map<String, dynamic>> Function(String modelId) loadDetail;
  final void Function(String modelId)? onCompare;

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
          color: Colors.redAccent,
        );
      }
    } catch (_) {
      if (!mounted) return;
      showTopNotification(
        context,
        tr('benchmark.openLinkFailed', {'url': url}),
        color: Colors.redAccent,
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
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            brand.color.withValues(alpha: 0.12),
            Colors.transparent,
            Colors.transparent,
          ],
        ),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
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
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                if (org.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    org,
                    style: TextStyle(
                      color: brand.color.withValues(alpha: 0.9),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
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
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.board.primaryLabel.isEmpty
                        ? tr('benchmark.sortAverage')
                        : widget.board.primaryLabel,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.35),
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
              style: const TextStyle(color: Colors.redAccent, fontSize: 13),
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
                        style: const TextStyle(
                          color: Colors.white70,
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
          if (detail.peers.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildPeersSection(detail),
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
                trailing: primary == null ? '' : _deltaText(primary.diff),
                scoreMax: widget.board.scoreMax,
                scoreFloor: widget.board.scoreFloor,
                scoreKind: widget.board.scoreKind,
              ),
              const SizedBox(height: 8),
              Divider(color: Colors.white.withValues(alpha: 0.05), height: 20),

              for (final metric in metrics) ...[
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
                  scoreMax: widget.board.scoreMax,
                  scoreFloor: widget.board.scoreFloor,
                  scoreKind: widget.board.scoreKind,
                ),
                if (metric != metrics.last) const SizedBox(height: 14),
              ],
            ],
          ),
        ),
      ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BenchmarkSectionTitle(title: tr('benchmark.detailFacts')),
        const SizedBox(height: 12),
        BenchmarkCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (best.type.isNotEmpty)
                BenchmarkFactRow(
                  label: tr('benchmark.factType'),
                  value: benchmarkTypeLabel(best.type),
                ),
              if (best.org.isNotEmpty)
                BenchmarkFactRow(
                  label: tr('benchmark.factOrg'),
                  value: best.org,
                ),
              if (best.license.isNotEmpty)
                BenchmarkFactRow(
                  label: tr('benchmark.factLicense'),
                  value: best.license,
                ),
              if (best.evalDate.isNotEmpty)
                BenchmarkFactRow(
                  label: tr('benchmark.factSubmitted'),
                  value: best.evalDate,
                ),

              for (final fact in best.details)
                BenchmarkFactRow(
                  label: benchmarkDetailLabel(fact.key),
                  value: fact.value,
                ),
              if (detail.entries.length > 1) ...[
                const SizedBox(height: 10),
                Text(
                  tr('benchmark.detailRuns'),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 11.5,
                  ),
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
            const Icon(Icons.link_off, size: 16, color: Colors.orangeAccent),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                tr('benchmark.hubMissing'),
                style: const TextStyle(color: Colors.white70, fontSize: 12.5),
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
        BenchmarkSectionTitle(title: tr('benchmark.hubTitle'), color: hubColor),
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
                    const Color(0xFF4FC3D9),
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
                      const Color(0xFFB98BE0),
                    ),
                  if (hub.lastModified.isNotEmpty)
                    _hubMetric(
                      tr('benchmark.hubUpdated'),
                      formatIsoDate(hub.lastModified),
                      Icons.update_rounded,
                      const Color(0xFF5FBF8C),
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
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 9,
                    letterSpacing: 0.7,
                    fontWeight: FontWeight.w700,
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
              color: Colors.white,
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

  Widget _buildPeersSection(BenchmarkModelDetail detail) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BenchmarkSectionTitle(title: tr('benchmark.peers')),
        const SizedBox(height: 12),

        LayoutBuilder(
          builder: (context, constraints) {
            final layout = BenchmarkTableLayout.of(
              width: constraints.maxWidth,
              board: widget.board,
              dense: true,
            );

            return Column(
              children: [
                for (final peer in detail.peers)
                  BenchmarkTableRow(
                    entry: peer,
                    position: peer.rank,
                    board: widget.board,
                    layout: layout,
                    onTap: () => _load(peer.lookupId),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
