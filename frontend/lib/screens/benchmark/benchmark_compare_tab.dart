import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../theme/dark_theme.dart';
import 'benchmark_models.dart';
import 'benchmark_widgets.dart';

class BenchmarkCompareTab extends StatefulWidget {
  const BenchmarkCompareTab({
    super.key,
    required this.board,
    required this.modelIds,
    required this.details,
    required this.isLoading,
    required this.error,
    required this.onRemove,
    required this.onClear,
    required this.onOpenModel,
  });

  final BenchmarkBoard board;
  final List<String> modelIds;
  final List<BenchmarkModelDetail> details;
  final bool isLoading;
  final String? error;
  final void Function(String modelId) onRemove;
  final VoidCallback onClear;
  final void Function(String modelId) onOpenModel;

  @override
  State<BenchmarkCompareTab> createState() => _BenchmarkCompareTabState();
}

class _BenchmarkCompareTabState extends State<BenchmarkCompareTab> {
  BenchmarkBoard get board => widget.board;
  List<String> get modelIds => widget.modelIds;
  List<BenchmarkModelDetail> get details => widget.details;
  bool get isLoading => widget.isLoading;
  String? get error => widget.error;
  void Function(String modelId) get onRemove => widget.onRemove;
  VoidCallback get onClear => widget.onClear;
  void Function(String modelId) get onOpenModel => widget.onOpenModel;

  final ScrollController _columns = ScrollController();

  @override
  void initState() {
    super.initState();

    _columns.addListener(_onScroll);
    _refreshAfterLayout();
  }

  @override
  void didUpdateWidget(BenchmarkCompareTab oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.modelIds.length != widget.modelIds.length ||
        oldWidget.details.length != widget.details.length) {
      _refreshAfterLayout();
    }
  }

  void _refreshAfterLayout() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _columns.removeListener(_onScroll);
    _columns.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (mounted) setState(() {});
  }

  bool get _canPageBack => _columns.hasClients && _columns.offset > 1;

  bool get _canPageOn =>
      _columns.hasClients &&
      _columns.offset < _columns.position.maxScrollExtent - 1;

  void _page(int direction) {
    if (!_columns.hasClients) return;
    final step = _columns.position.viewportDimension * direction;
    _columns.animateTo(
      (_columns.offset + step).clamp(0.0, _columns.position.maxScrollExtent),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  static const double _gap = 12;

  static const double _rowHeight = 46;

  static const int _visibleColumns = 4;

  static const double _columnMin = 150;

  String _nameOf(BenchmarkModelDetail detail) =>
      detail.name.isEmpty ? detail.modelId : detail.name;

  Color _colorOf(int index) =>
      kBenchmarkCompareColors[index % kBenchmarkCompareColors.length];

  String get _primaryLabel => board.primaryLabel.isEmpty
      ? tr('benchmark.sortAverage')
      : board.primaryLabel;

  List<String> get _pending => modelIds
      .where(
        (id) =>
            !details.any((detail) => detail.modelId == id || detail.name == id),
      )
      .toList();

  @override
  Widget build(BuildContext context) {
    if (modelIds.isEmpty) return _buildEmpty();
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(DarkColors.accent),
        ),
      );
    }
    if (error != null) {
      return Center(
        child: Text(
          error!,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.redAccent, fontSize: 13),
        ),
      );
    }
    if (details.isEmpty) return _buildEmpty();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth - kBenchmarkInset - 24;
        final labelWidth = width > 900 ? 180.0 : 128.0;

        final columnWidth = math.max(
          _columnMin,
          (width - labelWidth - _visibleColumns * _gap) / _visibleColumns,
        );
        final rows = _buildRows();
        final count = details.length + _pending.length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(kBenchmarkInset, 0, 24, 0),
              child: _buildToolbar(count),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(kBenchmarkInset, 0, 24, 24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: labelWidth,
                      child: Column(
                        children: [
                          for (final row in rows)
                            _framed(row, child: row.label),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Scrollbar(
                        controller: _columns,
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          controller: _columns,
                          scrollDirection: Axis.horizontal,
                          child: Column(
                            children: [
                              for (final row in rows)
                                _framed(
                                  row,
                                  child: Row(
                                    children: [
                                      for (
                                        var index = 0;
                                        index < count;
                                        index++
                                      ) ...[
                                        const SizedBox(width: _gap),
                                        SizedBox(
                                          width: columnWidth,
                                          child: row.cell(index),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),

                              const SizedBox(height: 14),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildToolbar(int count) {
    final pageable = count > _visibleColumns;

    return Row(
      children: [
        TextButton.icon(
          onPressed: onClear,
          icon: const Icon(Icons.clear_all, size: 15),
          label: Text(tr('benchmark.compareClear')),
          style: TextButton.styleFrom(
            foregroundColor: Colors.white.withValues(alpha: 0.5),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            textStyle: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Spacer(),
        if (pageable) ...[
          Text(
            tr('benchmark.compareCount', {'count': '$count'}),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          _pageButton(
            key: const ValueKey('benchmark-compare-back'),
            icon: Icons.chevron_left_rounded,
            enabled: _canPageBack,
            onTap: () => _page(-1),
          ),
          _pageButton(
            key: const ValueKey('benchmark-compare-on'),
            icon: Icons.chevron_right_rounded,
            enabled: _canPageOn,
            onTap: () => _page(1),
          ),
        ],
      ],
    );
  }

  Widget _pageButton({
    required Key key,
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return IconButton(
      key: key,
      icon: Icon(icon, size: 20),
      color: Colors.white.withValues(alpha: 0.55),
      disabledColor: Colors.white.withValues(alpha: 0.14),
      hoverColor: DarkColors.accent.withValues(alpha: 0.14),
      constraints: const BoxConstraints.tightFor(width: 32, height: 32),
      padding: EdgeInsets.zero,
      onPressed: enabled ? onTap : null,
    );
  }

  Widget _framed(_CompareRow row, {required Widget child}) {
    return Container(
      height: row.height,
      decoration: row.divider
          ? BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
              ),
            )
          : null,
      child: child,
    );
  }

  List<_CompareRow> _buildRows() {
    return [
      _CompareRow(
        height: 74,
        divider: false,
        label: const SizedBox.shrink(),
        cell: (column) => Align(
          alignment: Alignment.bottomCenter,
          child: _buildColumnHead(column),
        ),
      ),
      _CompareRow(
        height: 34,
        divider: false,
        label: _buildSectionLabel(tr('benchmark.compareScores')),
        cell: (_) => const SizedBox.shrink(),
      ),
      _scoreRow(
        label: _primaryLabel,
        valueOf: (detail) => detail.best?.primary ?? 0,
        headline: true,
      ),
      for (final metric in board.metrics)
        _scoreRow(
          label: metric.label,
          valueOf: (detail) => detail.best?.scoreOf(metric.key) ?? 0,
        ),
      _CompareRow(
        height: 30,
        divider: false,
        label: const SizedBox.shrink(),
        cell: (_) => const SizedBox.shrink(),
      ),
      _CompareRow(
        height: 34,
        divider: false,
        label: _buildSectionLabel(tr('benchmark.detailFacts')),
        cell: (_) => const SizedBox.shrink(),
      ),
      _factRow(
        label: tr('benchmark.factType'),
        valueOf: (detail) => benchmarkTypeLabel(detail.best?.type ?? ''),
        colorOf: (detail) => benchmarkTypeColor(detail.best?.type ?? ''),
      ),
      _factRow(
        label: tr('benchmark.factLicense'),
        valueOf: (detail) =>
            (detail.best?.license.isEmpty ?? true) ? '—' : detail.best!.license,
      ),
      _factRow(
        label: tr('benchmark.hubDownloads'),
        valueOf: (detail) {
          final hub = detail.hub;
          if (hub == null || hub.missing) return '—';
          return formatCompact(hub.downloads30d);
        },
      ),
    ];
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 74,
              height: 74,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: DarkColors.accent.withValues(alpha: 0.06),
                shape: BoxShape.circle,
                border: Border.all(
                  color: DarkColors.accent.withValues(alpha: 0.16),
                ),
              ),
              child: Icon(
                Icons.compare_arrows,
                size: 32,
                color: DarkColors.accent.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 18),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Text(
                tr('benchmark.compareEmpty'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.42),
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColumnHead(int column) {
    final pending = column >= details.length;
    final name = pending
        ? _pending[column - details.length]
        : _nameOf(details[column]);
    final org = pending ? '' : (details[column].best?.subtitle ?? '');
    final color = pending
        ? Colors.white.withValues(alpha: 0.3)
        : _colorOf(column);

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(10, 9, 4, 9),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.06),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            border: Border.all(color: color.withValues(alpha: 0.28)),
          ),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: pending ? null : () => onOpenModel(name),
                  borderRadius: BorderRadius.circular(6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: color,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                      if (org.isNotEmpty || pending) ...[
                        const SizedBox(height: 3),
                        Text(
                          pending ? tr('benchmark.compareNoData') : org,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.38),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 13),
                color: Colors.white.withValues(alpha: 0.35),
                tooltip: tr('benchmark.compareRemove'),
                constraints: const BoxConstraints.tightFor(
                  width: 26,
                  height: 26,
                ),
                padding: EdgeInsets.zero,
                onPressed: () => onRemove(name),
              ),
            ],
          ),
        ),
        Container(height: 2, color: color.withValues(alpha: 0.6)),
      ],
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 6),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.32),
          fontSize: 9.5,
          letterSpacing: 1,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  _CompareRow _scoreRow({
    required String label,
    required double Function(BenchmarkModelDetail detail) valueOf,
    bool headline = false,
  }) {
    var best = 0.0;
    for (final detail in details) {
      final value = valueOf(detail);
      if (value > best) best = value;
    }
    final reference = details.isEmpty ? 0.0 : valueOf(details.first);

    return _CompareRow(
      height: _rowHeight,
      label: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: headline
                ? Colors.white.withValues(alpha: 0.85)
                : Colors.white.withValues(alpha: 0.55),
            fontSize: headline ? 12.5 : 12,
            fontWeight: headline ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
      cell: (column) {
        if (column >= details.length) return _buildMissingCell();
        return _buildScoreCell(
          value: valueOf(details[column]),
          best: best,
          reference: reference,
          isReference: column == 0,
          color: _colorOf(column),
          headline: headline,
        );
      },
    );
  }

  Widget _buildScoreCell({
    required double value,
    required double best,
    required double reference,
    required bool isReference,
    required Color color,
    required bool headline,
  }) {
    if (value <= 0) return _buildMissingCell();

    final leads = value >= best && best > 0;
    final diff = value - reference;
    final span = board.scoreMax - board.scoreFloor;
    final fraction = span <= 0
        ? 0.0
        : ((value - board.scoreFloor) / span).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              formatScore(value, scoreKind: board.scoreKind),
              maxLines: 1,
              style: TextStyle(
                color: leads ? color : Colors.white.withValues(alpha: 0.7),
                fontSize: headline ? 16 : 13.5,
                fontWeight: leads ? FontWeight.w800 : FontWeight.w600,
                letterSpacing: -0.3,
              ),
            ),
            if (leads) ...[
              const SizedBox(width: 4),
              Tooltip(
                message: tr('benchmark.compareBest'),
                child: Icon(
                  Icons.arrow_drop_up_rounded,
                  size: 17,
                  color: color.withValues(alpha: 0.9),
                ),
              ),
            ],

            if (!isReference && diff != 0) ...[
              const SizedBox(width: 5),
              Text(
                (diff > 0 ? '+' : '−') +
                    formatScore(diff.abs(), scoreKind: board.scoreKind),
                maxLines: 1,
                style: TextStyle(
                  color: diff > 0
                      ? const Color(0xFF5FBF8C)
                      : Colors.white.withValues(alpha: 0.3),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 5),

        SizedBox(
          height: 3,
          child: Stack(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: const SizedBox.expand(),
              ),
              FractionallySizedBox(
                widthFactor: fraction,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: leads ? 0.95 : 0.45),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMissingCell() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        '—',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.2),
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  _CompareRow _factRow({
    required String label,
    required String Function(BenchmarkModelDetail detail) valueOf,
    Color Function(BenchmarkModelDetail detail)? colorOf,
  }) {
    return _CompareRow(
      height: 38,
      label: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      cell: (column) {
        if (column >= details.length) return _buildMissingCell();
        final detail = details[column];
        return Align(
          alignment: Alignment.centerLeft,
          child: Text(
            valueOf(detail),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color:
                  colorOf?.call(detail) ?? Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      },
    );
  }
}

class _CompareRow {
  const _CompareRow({
    required this.height,
    required this.label,
    required this.cell,
    this.divider = true,
  });

  final double height;
  final Widget label;
  final Widget Function(int column) cell;
  final bool divider;
}
