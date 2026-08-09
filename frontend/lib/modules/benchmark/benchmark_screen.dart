import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/app_strings.dart';
import '../../core/api_service.dart';
import '../../core/dark_theme.dart';
import '../../core/startup_warmup.dart';
import '../../core/top_notification.dart';
import './benchmark_compare_tab.dart';
import './benchmark_detail_dialog.dart';
import './benchmark_leaderboard_tab.dart';
import './benchmark_models.dart';
import './benchmark_widgets.dart';
import './benchmark_wiki_dialog.dart';

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
      ApiService().benchmark.getBoards();

  static Future<Map<String, dynamic>> _defaultLoadOverview(String board) =>
      ApiService().benchmark.getOverview(board: board);

  static Future<Map<String, dynamic>> _defaultLoadStatus(String board) =>
      ApiService().benchmark.getStatus(board: board);

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
    return ApiService().benchmark.getLeaderboard(
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
  ) => ApiService().benchmark.getModel(modelId, board: board);

  static Future<Map<String, dynamic>> _defaultLoadCompare(
    String board,
    List<String> modelIds,
  ) => ApiService().benchmark.compareModels(modelIds, board: board);

  static Future<void> _defaultRefresh(String board) =>
      ApiService().benchmark.refreshData(board: board);

  @override
  State<BenchmarkScreen> createState() => _BenchmarkScreenState();
}

class _BenchmarkScreenState extends State<BenchmarkScreen>
    with SingleTickerProviderStateMixin {
  static const int _maxCompare = 12;

  static const Duration _statusPollInterval = Duration(seconds: 2);

  late final TabController _tabController = TabController(
    length: 2,
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

  /// The ceiling of every score bar: the best the field currently reaches.
  BenchmarkFieldTops get _fieldTops {
    final overview = _overview;
    return overview == null
        ? BenchmarkFieldTops.empty
        : BenchmarkFieldTops.of(overview);
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

    final warm = StartupWarmup.instance.take<Map<String, dynamic>>(
      'benchmark.bootstrap',
      ttl: StartupWarmup.benchmarkTtl,
    );
    if (warm != null &&
        BenchmarkBoard.listFrom(warm['boards'] ?? const []).isNotEmpty) {
      _applyWarmBenchmark(warm);
      unawaited(_loadBoard(silent: true));
      return;
    }

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

  /// Uebernimmt den beim Start vorgeladenen Benchmark-Zustand (Boards,
  /// Status und ggf. schon die Uebersicht des Standardboards), damit die
  /// Seite ohne Ladezustand aufgebaut wird. Der stille Refresh in
  /// [_loadBoard] aktualisiert die Daten im Hintergrund.
  void _applyWarmBenchmark(Map<String, dynamic> warm) {
    final warmBoards = BenchmarkBoard.listFrom(warm['boards']);
    final fallback = (warm['default'] ?? '').toString();
    final statusRaw = warm['status'];
    final overviewRaw = warm['overview'];

    var boardKey = _boardKey;
    if (boardKey.isEmpty) {
      boardKey = fallback.isNotEmpty
          ? fallback
          : (warmBoards.isNotEmpty ? warmBoards.first.key : '');
    }

    setState(() {
      _boards = warmBoards;
      _boardKey = boardKey;
      if (statusRaw is Map<String, dynamic>) {
        _status = BenchmarkStatus.fromJson(statusRaw);
      }
      if (overviewRaw is Map<String, dynamic>) {
        final overview = BenchmarkOverview.fromJson(overviewRaw);
        _overview = overview;
        if (overview.boards.isNotEmpty) _boards = overview.boards;
      }
      _error = null;
      _isLoading = false;
    });
  }

  Future<void> _loadBoard({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final statusResponse = await widget.loadStatus(_boardKey);
      if (!mounted) return;
      final status = BenchmarkStatus.fromJson(statusResponse);
      setState(() {
        _status = status;
        if (status.boards.isNotEmpty) _boards = status.boards;
      });

      if (!status.isReady) {
        if (!silent) {
          _scheduleStatusPoll();
          setState(() => _isLoading = false);
        }
        return;
      }

      await _loadOverview(silent: silent);
    } catch (error) {
      if (!mounted) return;
      if (!silent) {
        setState(() {
          _error = '$error';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadOverview({bool silent = false}) async {
    try {
      final response = await widget.loadOverview(_boardKey);
      if (!mounted) return;
      final overview = BenchmarkOverview.fromJson(response);
      setState(() {
        _overview = overview;
        if (overview.boards.isNotEmpty) _boards = overview.boards;
        if (!silent) {
          _isLoading = false;
          _error = null;
        }
      });
    } catch (error) {
      if (!mounted) return;
      if (!silent) {
        setState(() {
          _error = '$error';
          _isLoading = false;
        });
      }
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
        fieldTops: _fieldTops,
        onOpenMetric: _openWiki,
        onCompare: (id) {
          Navigator.of(dialogContext).pop();
          _addToCompare(id);
        },
      ),
    );
  }

  /// The wiki carries the category copy the overview tab used to hold, so it
  /// opens either from the header or from any category name in the board.
  void _openWiki([String metricKey = '']) {
    final overview = _overview;
    showBenchmarkWiki(
      context,
      board: _board,
      stats: overview?.metricStats ?? const {},
      leaders: overview?.topByMetric ?? const {},
      metricKey: metricKey,
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
      padding: const EdgeInsets.fromLTRB(kBenchmarkInset, 16, 24, 0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 640;
          final titleWidget = _buildHeaderTitle();
          final statusWidget = _buildDataAge();

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                titleWidget,
                const SizedBox(height: 12),
                Align(alignment: Alignment.centerLeft, child: statusWidget),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: titleWidget),
              const SizedBox(width: 24),
              statusWidget,
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeaderTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          tr('benchmark.title'),
          style: const TextStyle(
            color: kBenchmarkInk,
            fontSize: 27,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.7,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 7),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Text(
            tr('benchmark.subtitle'),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: kBenchmarkInkMuted,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDataAge() {
    final source = _board.source;
    final stand = source.archived && source.archivedAt.isNotEmpty
        ? source.archivedAt
        : source.publishedAt;
    final isLive = source.live;

    return Container(
      padding: const EdgeInsets.only(left: 12, right: 6, top: 6, bottom: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kBenchmarkBorderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: isLive ? const Color(0xFF8AC194) : DarkColors.accent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 9),
          Text(
            isLive
                ? tr('benchmark.sourceLive')
                : '${tr('benchmark.sourceAsOf')}:',
            style: TextStyle(
              color: kBenchmarkInkSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (stand.isNotEmpty) ...[
            const SizedBox(width: 7),
            Text(
              stand,
              style: TextStyle(
                color: kBenchmarkInkMuted,
                fontFeatures: const [FontFeature.tabularFigures()],
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(width: 6),
          IconButton(
            key: const ValueKey('benchmark-refresh'),
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            color: kBenchmarkInkMuted,
            hoverColor: Colors.white.withValues(alpha: 0.07),
            tooltip: tr('benchmark.refreshAction'),
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints.tightFor(width: 28, height: 28),
          ),
          Container(
            width: 1,
            height: 16,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            color: kBenchmarkHairline,
          ),
          IconButton(
            key: const ValueKey('benchmark-wiki'),
            onPressed: _openWiki,
            icon: const Icon(Icons.menu_book_outlined, size: 16),
            color: DarkColors.accent.withValues(alpha: 0.85),
            hoverColor: DarkColors.accent.withValues(alpha: 0.12),
            tooltip: tr('benchmark.wikiOpen'),
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints.tightFor(width: 28, height: 28),
          ),
        ],
      ),
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
                ? DarkColors.accent.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              key: ValueKey('benchmark-board-${board.key}'),
              onTap: () => _selectBoard(board.key),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 13),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: selected
                        ? DarkColors.accent.withValues(alpha: 0.38)
                        : kBenchmarkBorderColor,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      board.source.live
                          ? Icons.sensors_rounded
                          : Icons.inventory_2_outlined,
                      size: 13,
                      color: selected ? DarkColors.accent : kBenchmarkInkFaint,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      benchmarkBoardLabel(board),
                      style: TextStyle(
                        color: selected ? kBenchmarkInk : kBenchmarkInkMuted,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
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
      tr('benchmark.tabLeaderboard'),
      _compareIds.isEmpty
          ? tr('benchmark.tabCompare')
          : '${tr('benchmark.tabCompare')} (${_compareIds.length})',
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kBenchmarkInset),
      child: LayoutBuilder(
        builder: (context, constraints) => Align(
          alignment: Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: constraints.maxWidth < 340 ? constraints.maxWidth : 340,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              ),
              child: Row(
                children: [
                  for (var index = 0; index < labels.length; index++)
                    Expanded(child: _buildTabButton(index, labels[index])),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton(int index, String label) {
    final selected = _tabController.index == index;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _tabController.animateTo(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          height: 40,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                width: 1.5,
                color: selected ? DarkColors.accent : Colors.transparent,
              ),
            ),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected ? kBenchmarkInk : kBenchmarkInkMuted,
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
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
              style: const TextStyle(
                color: Color(0xFFDE8F8F),
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: kBenchmarkInkMuted, fontSize: 12.5),
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

    final tops = BenchmarkFieldTops.of(overview);

    return TabBarView(
      controller: _tabController,
      children: [
        BenchmarkLeaderboardTab(
          board: overview.board,
          loadPage: widget.loadLeaderboard,
          fieldTops: tops,
          onOpenModel: (entry) => _openModel(entry.lookupId),
          onCompare: (entry) => _addToCompare(entry.lookupId),
          onOpenMetric: _openWiki,
        ),
        BenchmarkCompareTab(
          board: overview.board,
          fieldTops: tops,
          modelIds: _compareIds,
          details: _compareDetails,
          isLoading: _isComparing,
          error: _compareError,
          onRemove: _removeFromCompare,
          onClear: _clearCompare,
          onOpenModel: _openModel,
          onOpenMetric: _openWiki,
        ),
      ],
    );
  }

  Widget _buildLoadingState(BenchmarkStatus status) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: BenchmarkCard(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      tr('benchmark.loadingTitle'),
                      style: const TextStyle(
                        color: kBenchmarkInk,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  if (status.progress != null)
                    Text(
                      '${(status.progress! * 100).round()} %',
                      style: const TextStyle(
                        color: DarkColors.accent,
                        fontFeatures: [FontFeature.tabularFigures()],
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: status.progress,
                  minHeight: 4,
                  backgroundColor: Colors.white.withValues(alpha: 0.07),
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
                  color: kBenchmarkInkSecondary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                tr('benchmark.loadingHint'),
                style: TextStyle(
                  color: kBenchmarkInkFaint,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
              if (status.error.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  status.error,
                  style: const TextStyle(
                    color: Color(0xFFDE8F8F),
                    fontSize: 12,
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
