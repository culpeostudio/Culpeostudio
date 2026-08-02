import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../services/api_service.dart';
import '../../theme/dark_theme.dart';
import '../../widgets/top_notification.dart';
import 'benchmark_compare_tab.dart';
import 'benchmark_detail_dialog.dart';
import 'benchmark_leaderboard_tab.dart';
import 'benchmark_models.dart';
import 'benchmark_overview_tab.dart';
import 'benchmark_widgets.dart';

class BenchmarkScreen extends StatefulWidget {
  const BenchmarkScreen({
    super.key,
    Future<Map<String, dynamic>> Function()? loadBoards,
    Future<Map<String, dynamic>> Function(String board)? loadOverview,
    Future<Map<String, dynamic>> Function(String board)? loadStatus,
    BenchmarkLeaderboardLoader? loadLeaderboard,
    Future<Map<String, dynamic>> Function(String board, String modelId)?
    loadModel,
    Future<Map<String, dynamic>> Function(String board, List<String> modelIds)?
    loadCompare,
    Future<void> Function(String board)? refreshData,
  }) : loadBoards = loadBoards ?? _defaultLoadBoards,
       loadOverview = loadOverview ?? _defaultLoadOverview,
       loadStatus = loadStatus ?? _defaultLoadStatus,
       loadLeaderboard = loadLeaderboard ?? _defaultLoadLeaderboard,
       loadModel = loadModel ?? _defaultLoadModel,
       loadCompare = loadCompare ?? _defaultLoadCompare,
       refreshData = refreshData ?? _defaultRefresh;

  final Future<Map<String, dynamic>> Function() loadBoards;
  final Future<Map<String, dynamic>> Function(String board) loadOverview;
  final Future<Map<String, dynamic>> Function(String board) loadStatus;
  final BenchmarkLeaderboardLoader loadLeaderboard;
  final Future<Map<String, dynamic>> Function(String board, String modelId)
  loadModel;
  final Future<Map<String, dynamic>> Function(
    String board,
    List<String> modelIds,
  )
  loadCompare;
  final Future<void> Function(String board) refreshData;

  static Future<Map<String, dynamic>> _defaultLoadBoards() =>
      ApiService().getBenchmarkBoards();

  static Future<Map<String, dynamic>> _defaultLoadOverview(String board) =>
      ApiService().getBenchmarkOverview(board: board);

  static Future<Map<String, dynamic>> _defaultLoadStatus(String board) =>
      ApiService().getBenchmarkStatus(board: board);

  static Future<Map<String, dynamic>> _defaultLoadLeaderboard({
    required String board,
    required String query,
    required List<String> types,
    required List<String> orgs,
    required bool openWeightsOnly,
    required String sort,
    required String order,
    required int offset,
    required int limit,
  }) {
    return ApiService().getBenchmarkLeaderboard(
      board: board,
      query: query,
      types: types,
      orgs: orgs,
      openWeightsOnly: openWeightsOnly,
      sort: sort,
      order: order,
      offset: offset,
      limit: limit,
    );
  }

  static Future<Map<String, dynamic>> _defaultLoadModel(
    String board,
    String modelId,
  ) => ApiService().getBenchmarkModel(modelId, board: board);

  static Future<Map<String, dynamic>> _defaultLoadCompare(
    String board,
    List<String> modelIds,
  ) => ApiService().compareBenchmarkModels(modelIds, board: board);

  static Future<void> _defaultRefresh(String board) =>
      ApiService().refreshBenchmarkData(board: board);

  @override
  State<BenchmarkScreen> createState() => _BenchmarkScreenState();
}

class _BenchmarkScreenState extends State<BenchmarkScreen>
    with SingleTickerProviderStateMixin {
  static const int _maxCompare = 12;

  static const Duration _statusPollInterval = Duration(seconds: 2);

  late final TabController _tabController = TabController(
    length: 3,
    vsync: this,
  );

  List<BenchmarkBoard> _boards = const [];
  String _boardKey = '';
  BenchmarkOverview? _overview;
  BenchmarkStatus? _status;
  String? _error;
  bool _isLoading = true;
  Timer? _statusTimer;

  final List<String> _compareIds = [];
  List<BenchmarkModelDetail> _compareDetails = [];
  bool _isComparing = false;
  String? _compareError;

  @override
  void initState() {
    super.initState();

    _tabController.addListener(_onTabChanged);
    _bootstrap();
  }

  void _onTabChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  BenchmarkBoard get _board {
    final overview = _overview;
    if (overview != null && overview.board.key == _boardKey) {
      return overview.board;
    }
    for (final board in _boards) {
      if (board.key == _boardKey) return board;
    }
    return BenchmarkBoard.unknown;
  }

  Future<void> _bootstrap() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await widget.loadBoards();
      if (!mounted) return;

      final boards = BenchmarkBoard.listFrom(response['boards']);
      final fallback = response['default'];
      setState(() {
        _boards = boards;
        if (_boardKey.isEmpty) {
          _boardKey = fallback is String && fallback.isNotEmpty
              ? fallback
              : (boards.isNotEmpty ? boards.first.key : '');
        }
      });

      await _loadBoard();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = '$error';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadBoard() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final statusResponse = await widget.loadStatus(_boardKey);
      if (!mounted) return;
      final status = BenchmarkStatus.fromJson(statusResponse);
      setState(() {
        _status = status;
        if (status.boards.isNotEmpty) _boards = status.boards;
      });

      if (!status.isReady) {
        _scheduleStatusPoll();
        setState(() => _isLoading = false);
        return;
      }

      await _loadOverview();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = '$error';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadOverview() async {
    try {
      final response = await widget.loadOverview(_boardKey);
      if (!mounted) return;
      final overview = BenchmarkOverview.fromJson(response);
      setState(() {
        _overview = overview;
        if (overview.boards.isNotEmpty) _boards = overview.boards;
        _isLoading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = '$error';
        _isLoading = false;
      });
    }
  }

  void _selectBoard(String key) {
    if (key == _boardKey) return;
    _statusTimer?.cancel();
    setState(() {
      _boardKey = key;
      _overview = null;
      _status = null;

      _compareIds.clear();
      _compareDetails = [];
      _compareError = null;
    });
    _loadBoard();
  }

  void _scheduleStatusPoll() {
    _statusTimer?.cancel();
    _statusTimer = Timer(_statusPollInterval, () async {
      if (!mounted) return;
      try {
        final response = await widget.loadStatus(_boardKey);
        if (!mounted) return;
        final status = BenchmarkStatus.fromJson(response);
        setState(() {
          _status = status;
          if (status.boards.isNotEmpty) _boards = status.boards;
        });
        if (status.isReady) {
          await _loadOverview();
        } else {
          _scheduleStatusPoll();
        }
      } catch (error) {
        if (!mounted) return;
        setState(() => _error = '$error');
      }
    });
  }

  Future<void> _refresh() async {
    try {
      await widget.refreshData(_boardKey);
      if (!mounted) return;
      showTopNotification(context, tr('benchmark.refreshStarted'));
      _scheduleStatusPoll();
    } catch (error) {
      if (!mounted) return;
      showTopNotification(context, '$error', color: Colors.redAccent);
    }
  }

  void _openModel(String modelId) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => BenchmarkDetailDialog(
        modelId: modelId,
        board: _board,
        loadDetail: (id) => widget.loadModel(_boardKey, id),
        onCompare: (id) {
          Navigator.of(dialogContext).pop();
          _addToCompare(id);
        },
      ),
    );
  }

  void _addToCompare(String modelId) {
    if (_compareIds.contains(modelId)) {
      showTopNotification(
        context,
        tr('benchmark.compareAlready', {'model': modelId}),
      );
      return;
    }
    if (_compareIds.length >= _maxCompare) {
      showTopNotification(
        context,
        tr('benchmark.compareLimit'),
        color: Colors.orangeAccent,
      );
      return;
    }

    setState(() => _compareIds.add(modelId));
    showTopNotification(
      context,
      tr('benchmark.compareAdded', {'model': modelId}),
    );
    _loadCompare();
  }

  void _removeFromCompare(String modelId) {
    setState(() => _compareIds.remove(modelId));
    if (_compareIds.isEmpty) {
      setState(() => _compareDetails = []);
      return;
    }
    _loadCompare();
  }

  void _clearCompare() {
    setState(() {
      _compareIds.clear();
      _compareDetails = [];
      _compareError = null;
    });
  }

  Future<void> _loadCompare() async {
    if (_compareIds.isEmpty) return;
    setState(() {
      _isComparing = true;
      _compareError = null;
    });

    try {
      final response = await widget.loadCompare(
        _boardKey,
        List.of(_compareIds),
      );
      if (!mounted) return;
      setState(() {
        _compareDetails = BenchmarkModelDetail.listFrom(response['models']);
        _isComparing = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _compareError = '$error';
        _isComparing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 14),
          if (_boards.length > 1) ...[
            _buildBoardSwitcher(),
            const SizedBox(height: 14),
          ],
          _buildTabBar(),
          const SizedBox(height: 18),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(kBenchmarkInset, 10, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  DarkColors.accent.withValues(alpha: 0.26),
                  DarkColors.accent.withValues(alpha: 0.07),
                ],
              ),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: DarkColors.accent.withValues(alpha: 0.32),
              ),
            ),
            child: const Icon(
              Icons.leaderboard_rounded,
              size: 21,
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
                  tr('benchmark.title'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  tr('benchmark.subtitle'),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.42),
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          _buildDataAge(),
        ],
      ),
    );
  }

  Widget _buildDataAge() {
    final source = _board.source;
    final stand = source.archived && source.archivedAt.isNotEmpty
        ? source.archivedAt
        : source.publishedAt;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (stand.isNotEmpty)
          Text(
            stand,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.42),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        const SizedBox(width: 10),
        IconButton(
          key: const ValueKey('benchmark-refresh'),
          icon: const Icon(Icons.refresh_rounded, size: 18),
          color: Colors.white.withValues(alpha: 0.45),
          hoverColor: DarkColors.accent.withValues(alpha: 0.14),
          tooltip: tr('benchmark.refreshAction'),
          constraints: const BoxConstraints.tightFor(width: 34, height: 34),
          padding: EdgeInsets.zero,
          onPressed: _refresh,
        ),
      ],
    );
  }

  Widget _buildBoardSwitcher() {
    if (_boards.length < 2) return const SizedBox.shrink();

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: kBenchmarkInset),
        itemCount: _boards.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final board = _boards[index];
          final selected = board.key == _boardKey;

          return Material(
            color: selected
                ? DarkColors.accent.withValues(alpha: 0.13)
                : kBenchmarkCardColor,
            borderRadius: BorderRadius.circular(10),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              key: ValueKey('benchmark-board-${board.key}'),
              onTap: () => _selectBoard(board.key),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected
                        ? DarkColors.accent.withValues(alpha: 0.42)
                        : kBenchmarkBorderColor,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      board.source.live
                          ? Icons.sensors
                          : Icons.inventory_2_outlined,
                      size: 13,
                      color: selected
                          ? DarkColors.accent
                          : Colors.white.withValues(alpha: 0.35),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      benchmarkBoardLabel(board),
                      style: TextStyle(
                        color: selected
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.6),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabBar() {
    final labels = [
      tr('benchmark.tabOverview'),
      tr('benchmark.tabLeaderboard'),
      _compareIds.isEmpty
          ? tr('benchmark.tabCompare')
          : '${tr('benchmark.tabCompare')} (${_compareIds.length})',
    ];
    const icons = [
      Icons.dashboard_outlined,
      Icons.format_list_numbered_rounded,
      Icons.compare_arrows_rounded,
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kBenchmarkInset),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: kBenchmarkFieldColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var index = 0; index < labels.length; index++)
                _buildTabButton(index, labels[index], icons[index]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton(int index, String label, IconData icon) {
    final selected = _tabController.index == index;

    return Padding(
      padding: EdgeInsets.only(right: index < 2 ? 4 : 0),
      child: Material(
        color: selected
            ? DarkColors.accent.withValues(alpha: 0.13)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(9),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _tabController.animateTo(index),
          child: Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: selected
                    ? DarkColors.accent.withValues(alpha: 0.38)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 15,
                  color: selected
                      ? DarkColors.accent
                      : Colors.white.withValues(alpha: 0.38),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: selected
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.5),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final status = _status;
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
              tr('benchmark.loadFailed'),
              style: const TextStyle(color: Colors.redAccent, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _bootstrap,
              child: Text(tr('common.retry')),
            ),
          ],
        ),
      );
    }
    if (status != null && !status.isReady) {
      return _buildLoadingState(status);
    }

    final overview = _overview;
    if (overview == null) {
      return const SizedBox.shrink();
    }

    return TabBarView(
      controller: _tabController,
      children: [
        BenchmarkOverviewTab(
          overview: overview,
          onOpenModel: (entry) => _openModel(entry.lookupId),
          onShowLeaderboard: () => _tabController.animateTo(1),
        ),
        BenchmarkLeaderboardTab(
          board: overview.board,
          loadPage: widget.loadLeaderboard,
          onOpenModel: (entry) => _openModel(entry.lookupId),
          onCompare: (entry) => _addToCompare(entry.lookupId),
        ),
        BenchmarkCompareTab(
          board: overview.board,
          modelIds: _compareIds,
          details: _compareDetails,
          isLoading: _isComparing,
          error: _compareError,
          onRemove: _removeFromCompare,
          onClear: _clearCompare,
          onOpenModel: _openModel,
        ),
      ],
    );
  }

  Widget _buildLoadingState(BenchmarkStatus status) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: BenchmarkCard(
          accent: DarkColors.accent,
          glow: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: DarkColors.accent.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: DarkColors.accent.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Icon(
                      Icons.cloud_download_outlined,
                      size: 17,
                      color: DarkColors.accent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      tr('benchmark.loadingTitle'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (status.progress != null)
                    Text(
                      '${(status.progress! * 100).round()} %',
                      style: const TextStyle(
                        color: DarkColors.accent,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: status.progress,
                  minHeight: 7,
                  backgroundColor: Colors.white.withValues(alpha: 0.06),
                  valueColor: const AlwaysStoppedAnimation(DarkColors.accent),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                tr('benchmark.loadingProgress', {
                  'loaded': formatCount(status.loaded),
                  'total': status.expected > 0
                      ? formatCount(status.expected)
                      : '…',
                }),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                tr('benchmark.loadingHint'),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.35),
                  fontSize: 11.5,
                  height: 1.5,
                ),
              ),
              if (status.error.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  status.error,
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
