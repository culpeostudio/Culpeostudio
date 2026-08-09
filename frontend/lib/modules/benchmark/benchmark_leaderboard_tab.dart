import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/app_strings.dart';
import '../../core/dark_theme.dart';
import './benchmark_models.dart';
import './benchmark_orgs.dart';
import './benchmark_widgets.dart';

typedef BenchmarkLeaderboardLoader =
    Future<Map<String, dynamic>> Function({
      required String board,
      required String query,
      required List<String> types,
      required List<String> orgs,
      required bool openWeightsOnly,
      required String sort,
      required String order,
      required int offset,
      required int limit,
    });

class BenchmarkLeaderboardTab extends StatefulWidget {
  const BenchmarkLeaderboardTab({
    super.key,
    required this.board,
    required this.loadPage,
    required this.onOpenModel,
    required this.onCompare,
    this.fieldTops = BenchmarkFieldTops.empty,
    this.onOpenMetric,
  });

  final BenchmarkBoard board;
  final BenchmarkLeaderboardLoader loadPage;

  /// The leader's score, which ends every bar in the table.
  final BenchmarkFieldTops fieldTops;
  final void Function(BenchmarkEntry entry) onOpenModel;
  final void Function(BenchmarkEntry entry) onCompare;

  /// Opens the wiki on a category, for readers who wonder what it measures.
  final void Function(String metricKey)? onOpenMetric;

  @override
  State<BenchmarkLeaderboardTab> createState() =>
      _BenchmarkLeaderboardTabState();
}

class _BenchmarkLeaderboardTabState extends State<BenchmarkLeaderboardTab> {
  static const int _pageSize = 50;
  static const double _searchWidth = 300;

  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  List<BenchmarkEntry> _entries = [];
  BenchmarkLeaderboard _page = BenchmarkLeaderboard.empty;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;

  String _query = '';
  String _selectedType = '';
  String _selectedOrg = '';
  String _sort = kBenchmarkSortPrimary;
  String _order = 'desc';

  double _metricScroll = 0;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void didUpdateWidget(BenchmarkLeaderboardTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.board.key != widget.board.key) {
      _clearOwnFilters();
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetch({bool append = false}) async {
    setState(() {
      if (append) {
        _isLoadingMore = true;
      } else {
        _isLoading = true;
        _error = null;
      }
    });

    try {
      final response = await widget.loadPage(
        board: widget.board.key,
        query: _query,
        types: _selectedType.isEmpty ? const [] : [_selectedType],
        orgs: _selectedOrg.isEmpty ? const [] : [_selectedOrg],
        openWeightsOnly: false,
        sort: _sort,
        order: _order,
        offset: append ? _entries.length : 0,
        limit: _pageSize,
      );
      if (!mounted) return;

      final page = BenchmarkLeaderboard.fromJson(response);
      setState(() {
        _page = page;
        _entries = append ? [..._entries, ...page.items] : page.items;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = '$error';
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  void _onSearchChanged(String value) {
    setState(() {});
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() => _query = value.trim());
      _fetch();
    });
  }

  void _clearOwnFilters() {
    _searchController.clear();
    setState(_resetFilterState);
    _fetch();
  }

  void _resetFilterState() {
    _query = '';
    _selectedType = '';
    _selectedOrg = '';
    _sort = kBenchmarkSortPrimary;
    _order = 'desc';

    _metricScroll = 0;
  }

  void _onSortColumn(String key) {
    setState(() {
      if (_sort == key) {
        _order = _order == 'desc' ? 'asc' : 'desc';
      } else {
        _sort = key;
        _order = key == kBenchmarkSortName ? 'asc' : 'desc';
      }
    });
    _fetch();
  }

  bool get _hasActiveFilters =>
      _query.isNotEmpty ||
      _selectedType.isNotEmpty ||
      _selectedOrg.isNotEmpty ||
      _sort != kBenchmarkSortPrimary ||
      _order != 'desc';

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = BenchmarkTableLayout.of(
          width: constraints.maxWidth - kBenchmarkInset - 24,
          board: widget.board,
          hasCompare: true,
          metricScroll: _metricScroll,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(kBenchmarkInset, 0, 24, 0),
              child: _buildToolbar(layout),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(kBenchmarkInset, 0, 24, 0),
                child: _buildList(layout),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildToolbar(BenchmarkTableLayout layout) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(width: _searchWidth, child: _buildSearchField()),
            if (_page.types.isNotEmpty) _buildTypeFilter(),
            if (_page.orgs.isNotEmpty) _buildOrgFilter(),
            _buildSortFilter(),
            if (_hasActiveFilters)
              TextButton.icon(
                onPressed: _clearOwnFilters,
                icon: const Icon(Icons.close_rounded, size: 14),
                label: Text(tr('benchmark.filterReset')),
                style: TextButton.styleFrom(
                  foregroundColor: DarkColors.accent,
                  textStyle: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          tr('benchmark.resultCount', {'count': formatCount(_page.total)}),
          style: TextStyle(
            color: kBenchmarkInkMuted,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return TextField(
      key: const ValueKey('benchmark-search'),
      controller: _searchController,
      onChanged: _onSearchChanged,
      style: const TextStyle(color: kBenchmarkInk, fontSize: 13),
      cursorColor: kBenchmarkInfoColor,
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 11),
        prefixIcon: Icon(
          Icons.search_rounded,
          size: 17,
          color: kBenchmarkInkSecondary,
        ),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 38,
          minHeight: 34,
        ),
        hintText: tr('benchmark.searchHint'),
        hintStyle: TextStyle(color: kBenchmarkInkFaint, fontSize: 12.5),
        suffixIcon: _searchController.text.isEmpty
            ? null
            : IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  color: kBenchmarkInkMuted,
                  size: 15,
                ),
                splashRadius: 16,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                onPressed: () {
                  _searchController.clear();
                  _onSearchChanged('');
                },
              ),
        suffixIconConstraints: const BoxConstraints(
          minWidth: 34,
          minHeight: 34,
        ),
        filled: true,
        fillColor: kBenchmarkFieldColor,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.14),
            width: 1.2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: kBenchmarkInfoColor, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildTypeFilter() {
    return BenchmarkFilterMenu(
      menuKey: const ValueKey('benchmark-type-filter'),
      label: tr('benchmark.filterType'),
      width: 190,
      selected: _selectedType,
      options: [
        BenchmarkFilterOption(
          value: '',
          label: tr('benchmark.filterAll'),
          color: const Color(0xFF5FBB90),
        ),
        for (final facet in _page.types)
          BenchmarkFilterOption(
            value: facet.value,
            label: benchmarkTypeLabel(facet.value),
            color: benchmarkTypeColor(facet.value),
            count: facet.count,
          ),
      ],
      onSelected: (value) {
        setState(() => _selectedType = value);
        _fetch();
      },
    );
  }

  Widget _buildOrgFilter() {
    return BenchmarkFilterMenu(
      menuKey: const ValueKey('benchmark-org-filter'),
      label: tr('benchmark.filterOrg'),
      width: 210,
      selected: _selectedOrg,
      options: [
        BenchmarkFilterOption(
          value: '',
          label: tr('benchmark.filterAll'),
          color: const Color(0xFF7AA5E0),
        ),
        for (final facet in _page.orgs)
          BenchmarkFilterOption(
            value: facet.value,
            label: formatOrgName(facet.value),
            color: benchmarkOrgInk(benchmarkOrgBrand(facet.value).color),
            count: facet.count,
          ),
      ],
      onSelected: (value) {
        setState(() => _selectedOrg = value);
        _fetch();
      },
    );
  }

  Widget _buildSortFilter() {
    return BenchmarkFilterMenu(
      menuKey: const ValueKey('benchmark-sort-filter'),
      label: tr('benchmark.sortLabel'),
      width: 200,
      selected: _sort,
      options: [
        BenchmarkFilterOption(
          value: kBenchmarkSortPrimary,
          label: widget.board.primaryLabel.isEmpty
              ? tr('benchmark.sortAverage')
              : widget.board.primaryLabel,
          color: const Color(0xFFFFB800),
        ),
        BenchmarkFilterOption(
          value: kBenchmarkSortName,
          label: tr('benchmark.sortName'),
          color: kBenchmarkInfoColor,
        ),
        for (final metric in widget.board.metrics)
          BenchmarkFilterOption(
            value: metric.key,
            label: metric.label,
            color: benchmarkMetricColor(metric),
          ),
      ],
      onSelected: (value) {
        setState(() {
          _sort = value;
          _order = value == kBenchmarkSortName ? 'asc' : 'desc';
        });
        _fetch();
      },
    );
  }

  Widget _buildList(BenchmarkTableLayout layout) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(DarkColors.accent),
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFDE8F8F), fontSize: 13),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _fetch(),
              child: Text(tr('common.retry')),
            ),
          ],
        ),
      );
    }
    if (_entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              tr('benchmark.empty'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: kBenchmarkInkSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (_hasActiveFilters) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: _clearOwnFilters,
                style: TextButton.styleFrom(
                  foregroundColor: DarkColors.accent,
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: Text(tr('benchmark.filterReset')),
              ),
            ],
          ],
        ),
      );
    }

    final hasMore = _entries.length < _page.total;
    return Column(
      children: [
        BenchmarkTableHeader(
          layout: layout,
          board: widget.board,
          sort: _sort,
          descending: _order != 'asc',
          onSort: _onSortColumn,
          onMetricWindow: (scroll) => setState(() => _metricScroll = scroll),
          onExplainMetric: widget.onOpenMetric,
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 32),
            itemCount: _entries.length + (hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= _entries.length) return _buildLoadMore();

              final entry = _entries[index];
              return BenchmarkTableRow(
                entry: entry,

                position: entry.rank > 0 ? entry.rank : index + 1,
                board: widget.board,
                layout: layout,
                fieldTop: widget.fieldTops.primary,
                highlightMetric: _sort,
                onTap: () => widget.onOpenModel(entry),
                onCompare: () => widget.onCompare(entry),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLoadMore() {
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Center(
        child: _isLoadingMore
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(DarkColors.accent),
                ),
              )
            : OutlinedButton.icon(
                key: const ValueKey('benchmark-load-more'),
                onPressed: () => _fetch(append: true),
                icon: const Icon(Icons.expand_more_rounded, size: 17),
                label: Text(tr('benchmark.loadMore')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: DarkColors.accent,
                  side: BorderSide(color: kBenchmarkBorderColor),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
      ),
    );
  }
}
