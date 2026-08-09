import 'package:grpc/grpc.dart';

import '../../generated/culpeostudio/benchmark/v1/benchmark.pbgrpc.dart'
    as bmpb;
import '../../core/api_client.dart';
import '../../core/remaining_ui_strings.dart';

/// Bestenlisten und Modellvergleiche.
///
/// The screen parses plain maps through benchmark_models.dart, so every
/// response is flattened back into the shape the JSON API produced.
class BenchmarkApi {
  BenchmarkApi(this._c);

  final ApiClient _c;

  Future<Map<String, dynamic>> getBoards() {
    return _guard(() async {
      final response = await _c.benchmarkClient.listBoards(
        bmpb.ListBoardsRequest(),
      );
      return {
        'boards': response.boards.map(_boardToMap).toList(),
        'default': response.defaultBoard,
      };
    });
  }

  Future<Map<String, dynamic>> getOverview({String board = ''}) {
    return _guard(() async {
      final response = await _c.benchmarkClient.getOverview(
        bmpb.GetOverviewRequest(board: board.trim()),
      );
      return {
        'board': _boardToMap(response.board),
        'boards': response.boards.map(_boardToMap).toList(),
        'total_entries': response.totalEntries,
        'total_models': response.totalModels,
        'metric_stats': response.metricStats.map(_metricStatsToMap).toList(),
        'top_overall': response.topOverall.map(_entryToMap).toList(),
        'top_by_metric': _entriesByMetric(response.topByMetric),
        'top_open_weights': response.topOpenWeights.map(_entryToMap).toList(),
        'top_open_by_metric': _entriesByMetric(response.topOpenByMetric),
        'type_share': response.typeShare.map(_facetToMap).toList(),
        'org_share': response.orgShare.map(_facetToMap).toList(),
      };
    });
  }

  Future<Map<String, dynamic>> getStatus({String board = ''}) {
    return _guard(() async {
      final response = await _c.benchmarkClient.getStatus(
        bmpb.GetStatusRequest(board: board.trim()),
      );
      return {
        'state': _stateName(response.state),
        'loaded': response.loaded,
        'expected': response.expected,
        'error': response.error,
        'refreshing': response.refreshing,
        'boards': response.boards.map(_boardToMap).toList(),
        'source': _sourceToMap(response.source),
      };
    });
  }

  Future<Map<String, dynamic>> getLeaderboard({
    String board = '',
    String query = '',
    List<String> types = const [],
    List<String> orgs = const [],
    bool bestPerModel = true,
    bool openWeightsOnly = false,
    String sort = 'primary',
    String order = 'desc',
    int offset = 0,
    int limit = 50,
  }) {
    return _guard(() async {
      final response = await _c.benchmarkClient.getLeaderboard(
        bmpb.GetLeaderboardRequest(
          board: board.trim(),
          query: query.trim(),
          types: types,
          orgs: orgs,
          openWeightsOnly: openWeightsOnly,
          bestPerModel: bestPerModel,
          sort: sort,
          order: _orderFromName(order),
          offset: offset,
          limit: limit,
        ),
      );
      return {
        'board': _boardToMap(response.board),
        'items': response.items.map(_entryToMap).toList(),
        'total': response.total,
        'offset': response.offset,
        'limit': response.limit,
        'sort': response.sort,
        'order': _orderName(response.order),
        'facets': {
          'types': response.facets.types.map(_facetToMap).toList(),
          'orgs': response.facets.orgs.map(_facetToMap).toList(),
          'licenses': response.facets.licenses.map(_facetToMap).toList(),
        },
        if (response.warning != bmpb.BoardState.BOARD_STATE_UNSPECIFIED)
          'warning': _stateName(response.warning),
      };
    });
  }

  Future<Map<String, dynamic>> getModel(
    String modelId, {
    String board = '',
    bool withHub = true,
  }) {
    return _guard(
      () async {
        final response = await _c.benchmarkClient.getModel(
          bmpb.GetModelRequest(
            board: board.trim(),
            id: modelId,
            withHub: withHub,
          ),
        );
        return _modelDetailToMap(response.detail);
      },
      notFoundMessage: remainingUiText('api.benchmarkModelUnknown', {
        'model': modelId,
      }),
    );
  }

  Future<Map<String, dynamic>> compareModels(
    List<String> modelIds, {
    String board = '',
    bool withHub = true,
  }) {
    return _guard(() async {
      // The ids used to be joined with commas into one parameter; each one now
      // travels on its own.
      final response = await _c.benchmarkClient.compareModels(
        bmpb.CompareModelsRequest(
          board: board.trim(),
          ids: modelIds,
          withHub: withHub,
        ),
      );
      return {
        'models': response.models.map(_modelDetailToMap).toList(),
        'board': _boardToMap(response.board),
      };
    });
  }

  Future<void> refreshData({String board = ''}) async {
    await _guard(() async {
      await _c.benchmarkClient.refreshBoards(
        bmpb.RefreshBoardsRequest(board: board.trim()),
      );
      return const <String, dynamic>{};
    });
  }

  /// Turns every failure into the ApiException the screen renders, keeping the
  /// wording the HTTP client used. A model that is nowhere known keeps its own
  /// message, which NOT_FOUND carries the way the 404 did.
  Future<Map<String, dynamic>> _guard(
    Future<Map<String, dynamic>> Function() call, {
    String? notFoundMessage,
  }) async {
    try {
      return await call();
    } catch (e) {
      if (notFoundMessage != null &&
          e is GrpcError &&
          e.code == StatusCode.notFound) {
        throw ApiException(notFoundMessage);
      }
      throw ApiException(
        remainingUiText('api.benchmarkFailed', {
          'error': _c.grpcErrorMessage(e),
        }),
      );
    }
  }

  static const Map<bmpb.BoardState, String> _stateNames = {
    bmpb.BoardState.BOARD_STATE_EMPTY: 'empty',
    bmpb.BoardState.BOARD_STATE_LOADING: 'loading',
    bmpb.BoardState.BOARD_STATE_READY: 'ready',
    bmpb.BoardState.BOARD_STATE_ERROR: 'error',
  };

  /// An unset state reads as "empty", which is what the models fall back to.
  String _stateName(bmpb.BoardState state) => _stateNames[state] ?? 'empty';

  bmpb.SortOrder _orderFromName(String order) =>
      order.trim().toLowerCase() == 'asc'
      ? bmpb.SortOrder.SORT_ORDER_ASC
      : bmpb.SortOrder.SORT_ORDER_DESC;

  String _orderName(bmpb.SortOrder order) =>
      order == bmpb.SortOrder.SORT_ORDER_ASC ? 'asc' : 'desc';

  Map<String, dynamic> _entryToMap(bmpb.Entry entry) {
    return {
      'board': entry.board,
      'key': entry.key,
      'name': entry.name,
      'model_id': entry.modelId,
      'org': entry.org,
      'license': entry.license,
      'url': entry.url,
      'type': entry.type,
      'open_weights': entry.openWeights,
      'eval_date': entry.evalDate,
      'primary': entry.primary,
      'scores': Map<String, double>.from(entry.scores),
      'rank': entry.rank,
      'details': entry.details
          .map((detail) => {'key': detail.key, 'value': detail.value})
          .toList(),
    };
  }

  Map<String, dynamic> _metricToMap(bmpb.MetricInfo metric) {
    return {
      'key': metric.key,
      'label': metric.label,
      'family': metric.family,
      'shots': metric.shots,
      'dataset': metric.dataset,
      'url': metric.url,
    };
  }

  Map<String, dynamic> _metricStatsToMap(bmpb.MetricStats stats) {
    return {
      'key': stats.key,
      'min': stats.min,
      'max': stats.max,
      'mean': stats.mean,
      'median': stats.median,
      'top_model': stats.topModel,
      'top_score': stats.topScore,
      'evaluated': stats.evaluated,
    };
  }

  Map<String, dynamic> _sourceToMap(bmpb.SourceInfo source) {
    return {
      'provider': source.provider,
      'dataset': source.dataset,
      'url': source.url,
      'live': source.live,
      'archived': source.archived,
      'archived_at': source.archivedAt,
      'published_at': source.publishedAt,
      'fetched_at': source.fetchedAt,
      'from_cache': source.fromCache,
      'entries': source.entries,
      'models': source.models,
      'state': _stateName(source.state),
      'error': source.error,
    };
  }

  Map<String, dynamic> _boardToMap(bmpb.BoardInfo board) {
    return {
      'key': board.key,
      'label': board.label,
      'kind': board.kind,
      'score_kind': board.scoreKind,
      'primary_label': board.primaryLabel,
      'score_max': board.scoreMax,
      'metrics': board.metrics.map(_metricToMap).toList(),
      'source': _sourceToMap(board.source),
    };
  }

  Map<String, dynamic> _facetToMap(bmpb.FacetValue facet) {
    return {'value': facet.value, 'label': facet.label, 'count': facet.count};
  }

  Map<String, dynamic> _hubToMap(bmpb.HubStats hub) {
    return {
      'model_id': hub.modelId,
      'likes': hub.likes,
      'downloads_30d': hub.downloads30d.toInt(),
      'downloads_all_time': hub.downloadsAllTime.toInt(),
      'trending_score': hub.trendingScore,
      'last_modified': hub.lastModified,
      'pipeline_tag': hub.pipelineTag,
      'gated': hub.gated,
      'params_total': hub.paramsTotal.toInt(),
      'tags': hub.tags.toList(),
      'inference_providers': hub.inferenceProviders.toList(),
      'missing': hub.missing,
    };
  }

  Map<String, dynamic> _cardResultToMap(bmpb.CardResult result) {
    return {
      'task': result.task,
      'dataset': result.dataset,
      'metric': result.metric,
      'value': result.value,
      'verified': result.verified,
    };
  }

  Map<String, dynamic> _modelDetailToMap(bmpb.ModelDetail detail) {
    return {
      'board': detail.board,
      'model_id': detail.modelId,
      'name': detail.name,
      'entries': detail.entries.map(_entryToMap).toList(),
      // Absent rather than empty when the board knows nothing about the model,
      // because the screen reads that as "hub result only".
      if (detail.hasBest()) 'best': _entryToMap(detail.best),
      'metric_ranks': Map<String, int>.from(detail.metricRanks),
      'percentile': detail.percentile,
      'peers': detail.peers.map(_entryToMap).toList(),
      if (detail.hasHub()) 'hub': _hubToMap(detail.hub),
      'card_results': detail.cardResults.map(_cardResultToMap).toList(),
      'deltas': detail.deltas.map(
        (key, delta) => MapEntry(key, {
          'value': delta.value,
          'median': delta.median,
          'diff': delta.diff,
        }),
      ),
      'metrics': detail.metrics.map(_metricToMap).toList(),
      'source': _sourceToMap(detail.source),
      'totals': Map<String, int>.from(detail.totals),
      'score_kind': detail.scoreKind,
    };
  }

  Map<String, dynamic> _entriesByMetric(Map<String, bmpb.EntryList> byMetric) {
    return byMetric.map(
      (key, list) => MapEntry(key, list.entries.map(_entryToMap).toList()),
    );
  }
}
