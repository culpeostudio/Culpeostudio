library;

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

int _toInt(dynamic value) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

String _toStr(dynamic value) => value is String ? value : '';

bool _toBool(dynamic value) => value is bool ? value : false;

List<String> _toStringList(dynamic value) {
  if (value is List) {
    return value.whereType<String>().toList(growable: false);
  }
  return const [];
}

Map<String, dynamic> _toMap(dynamic value) =>
    value is Map<String, dynamic> ? value : const {};

Map<String, double> _toScores(dynamic value) {
  if (value is! Map) return const {};
  final result = <String, double>{};
  value.forEach((key, item) {
    if (key is String) result[key] = _toDouble(item);
  });
  return result;
}

class BenchmarkDetail {
  const BenchmarkDetail({required this.key, required this.value});

  factory BenchmarkDetail.fromJson(Map<String, dynamic> json) =>
      BenchmarkDetail(key: _toStr(json['key']), value: _toStr(json['value']));

  static List<BenchmarkDetail> listFrom(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map<String, dynamic>>()
        .map(BenchmarkDetail.fromJson)
        .where((detail) => detail.key.isNotEmpty)
        .toList(growable: false);
  }

  final String key;
  final String value;
}

class BenchmarkEntry {
  const BenchmarkEntry({
    required this.board,
    required this.key,
    required this.name,
    required this.modelId,
    required this.org,
    required this.license,
    required this.url,
    required this.type,
    required this.openWeights,
    required this.evalDate,
    required this.primary,
    required this.scores,
    required this.rank,
    required this.details,
  });

  factory BenchmarkEntry.fromJson(Map<String, dynamic> json) {
    return BenchmarkEntry(
      board: _toStr(json['board']),
      key: _toStr(json['key']),
      name: _toStr(json['name']),
      modelId: _toStr(json['model_id']),
      org: _toStr(json['org']),
      license: _toStr(json['license']),
      url: _toStr(json['url']),
      type: _toStr(json['type']),
      openWeights: _toBool(json['open_weights']),
      evalDate: _toStr(json['eval_date']),
      primary: _toDouble(json['primary']),
      scores: _toScores(json['scores']),
      rank: _toInt(json['rank']),
      details: BenchmarkDetail.listFrom(json['details']),
    );
  }

  static List<BenchmarkEntry> listFrom(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map<String, dynamic>>()
        .map(BenchmarkEntry.fromJson)
        .toList(growable: false);
  }

  final String board;
  final String key;
  final String name;
  final String modelId;
  final String org;
  final String license;
  final String url;
  final String type;
  final bool openWeights;
  final String evalDate;
  final double primary;
  final Map<String, double> scores;
  final int rank;
  final List<BenchmarkDetail> details;

  double scoreOf(String metricKey) => scores[metricKey] ?? 0;

  String get lookupId => modelId.isNotEmpty ? modelId : name;

  String get shortName {
    final slash = name.lastIndexOf('/');
    return slash >= 0 ? name.substring(slash + 1) : name;
  }

  String get subtitle {
    if (org.isNotEmpty) return org;
    final slash = name.indexOf('/');
    return slash > 0 ? name.substring(0, slash) : '';
  }
}

class BenchmarkMetric {
  const BenchmarkMetric({
    required this.key,
    required this.label,
    required this.family,
    required this.shots,
    required this.dataset,
    required this.url,
  });

  factory BenchmarkMetric.fromJson(Map<String, dynamic> json) {
    return BenchmarkMetric(
      key: _toStr(json['key']),
      label: _toStr(json['label']),
      family: _toStr(json['family']),
      shots: _toStr(json['shots']),
      dataset: _toStr(json['dataset']),
      url: _toStr(json['url']),
    );
  }

  static List<BenchmarkMetric> listFrom(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map<String, dynamic>>()
        .map(BenchmarkMetric.fromJson)
        .toList(growable: false);
  }

  final String key;
  final String label;
  final String family;
  final String shots;
  final String dataset;
  final String url;

  String get setup {
    final parts = [
      if (shots.isNotEmpty) shots,
      if (dataset.isNotEmpty) dataset,
    ];
    return parts.join(' · ');
  }
}

class BenchmarkMetricStats {
  const BenchmarkMetricStats({
    required this.key,
    required this.min,
    required this.max,
    required this.mean,
    required this.median,
    required this.topModel,
    required this.topScore,
    required this.evaluated,
  });

  factory BenchmarkMetricStats.fromJson(Map<String, dynamic> json) {
    return BenchmarkMetricStats(
      key: _toStr(json['key']),
      min: _toDouble(json['min']),
      max: _toDouble(json['max']),
      mean: _toDouble(json['mean']),
      median: _toDouble(json['median']),
      topModel: _toStr(json['top_model']),
      topScore: _toDouble(json['top_score']),
      evaluated: _toInt(json['evaluated']),
    );
  }

  static Map<String, BenchmarkMetricStats> mapFrom(dynamic value) {
    if (value is! List) return const {};
    final result = <String, BenchmarkMetricStats>{};
    for (final item in value.whereType<Map<String, dynamic>>()) {
      final stats = BenchmarkMetricStats.fromJson(item);
      if (stats.key.isNotEmpty) result[stats.key] = stats;
    }
    return result;
  }

  final String key;
  final double min;
  final double max;
  final double mean;
  final double median;
  final String topModel;
  final double topScore;
  final int evaluated;
}

class BenchmarkSource {
  const BenchmarkSource({
    required this.provider,
    required this.dataset,
    required this.url,
    required this.live,
    required this.archived,
    required this.archivedAt,
    required this.publishedAt,
    required this.fetchedAt,
    required this.fromCache,
    required this.entries,
    required this.models,
    required this.state,
    required this.error,
  });

  factory BenchmarkSource.fromJson(Map<String, dynamic> json) {
    final state = _toStr(json['state']);
    return BenchmarkSource(
      provider: _toStr(json['provider']),
      dataset: _toStr(json['dataset']),
      url: _toStr(json['url']),
      live: _toBool(json['live']),
      archived: _toBool(json['archived']),
      archivedAt: _toStr(json['archived_at']),
      publishedAt: _toStr(json['published_at']),
      fetchedAt: _toStr(json['fetched_at']),
      fromCache: _toBool(json['from_cache']),
      entries: _toInt(json['entries']),
      models: _toInt(json['models']),

      state: state.isEmpty ? 'empty' : state,
      error: _toStr(json['error']),
    );
  }

  static const BenchmarkSource unknown = BenchmarkSource(
    provider: '',
    dataset: '',
    url: '',
    live: false,
    archived: false,
    archivedAt: '',
    publishedAt: '',
    fetchedAt: '',
    fromCache: false,
    entries: 0,
    models: 0,
    state: 'empty',
    error: '',
  );

  final String provider;
  final String dataset;
  final String url;
  final bool live;
  final bool archived;
  final String archivedAt;
  final String publishedAt;
  final String fetchedAt;
  final bool fromCache;
  final int entries;
  final int models;
  final String state;
  final String error;

  bool get isReady => state == 'ready';
  bool get isLoading => state == 'loading' || state == 'empty';
  bool get hasFailed => state == 'error';
}

class BenchmarkBoard {
  const BenchmarkBoard({
    required this.key,
    required this.label,
    required this.kind,
    required this.scoreKind,
    required this.primaryLabel,
    required this.scoreMax,
    required this.metrics,
    required this.source,
  });

  factory BenchmarkBoard.fromJson(Map<String, dynamic> json) {
    return BenchmarkBoard(
      key: _toStr(json['key']),
      label: _toStr(json['label']),
      kind: _toStr(json['kind']),
      scoreKind: _toStr(json['score_kind']),
      primaryLabel: _toStr(json['primary_label']),
      scoreMax: _toDouble(json['score_max']),
      metrics: BenchmarkMetric.listFrom(json['metrics']),
      source: BenchmarkSource.fromJson(_toMap(json['source'])),
    );
  }

  static List<BenchmarkBoard> listFrom(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map<String, dynamic>>()
        .map(BenchmarkBoard.fromJson)
        .where((board) => board.key.isNotEmpty)
        .toList(growable: false);
  }

  static const BenchmarkBoard unknown = BenchmarkBoard(
    key: '',
    label: '',
    kind: '',
    scoreKind: 'percent',
    primaryLabel: '',
    scoreMax: 100,
    metrics: [],
    source: BenchmarkSource.unknown,
  );

  final String key;
  final String label;
  final String kind;
  final String scoreKind;
  final String primaryLabel;
  final double scoreMax;
  final List<BenchmarkMetric> metrics;
  final BenchmarkSource source;

  double get scoreFloor => scoreKind == 'elo' ? 900 : 0;
}

class BenchmarkStatus {
  const BenchmarkStatus({
    required this.state,
    required this.loaded,
    required this.expected,
    required this.error,
    required this.refreshing,
    required this.source,
    required this.boards,
  });

  factory BenchmarkStatus.fromJson(Map<String, dynamic> json) {
    return BenchmarkStatus(
      state: _toStr(json['state']),
      loaded: _toInt(json['loaded']),
      expected: _toInt(json['expected']),
      error: _toStr(json['error']),
      refreshing: _toBool(json['refreshing']),
      source: BenchmarkSource.fromJson(_toMap(json['source'])),
      boards: BenchmarkBoard.listFrom(json['boards']),
    );
  }

  final String state;
  final int loaded;
  final int expected;
  final String error;
  final bool refreshing;
  final BenchmarkSource source;
  final List<BenchmarkBoard> boards;

  bool get isReady => state == 'ready';

  double? get progress {
    if (expected <= 0) return null;
    return (loaded / expected).clamp(0.0, 1.0);
  }
}

class BenchmarkFacet {
  const BenchmarkFacet({required this.value, required this.count});

  factory BenchmarkFacet.fromJson(Map<String, dynamic> json) {
    return BenchmarkFacet(
      value: _toStr(json['value']),
      count: _toInt(json['count']),
    );
  }

  static List<BenchmarkFacet> listFrom(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map<String, dynamic>>()
        .map(BenchmarkFacet.fromJson)
        .where((facet) => facet.value.isNotEmpty)
        .toList(growable: false);
  }

  final String value;
  final int count;
}

class BenchmarkLeaderboard {
  const BenchmarkLeaderboard({
    required this.board,
    required this.items,
    required this.total,
    required this.offset,
    required this.limit,
    required this.sort,
    required this.order,
    required this.types,
    required this.orgs,
  });

  factory BenchmarkLeaderboard.fromJson(Map<String, dynamic> json) {
    final facets = _toMap(json['facets']);
    return BenchmarkLeaderboard(
      board: BenchmarkBoard.fromJson(_toMap(json['board'])),
      items: BenchmarkEntry.listFrom(json['items']),
      total: _toInt(json['total']),
      offset: _toInt(json['offset']),
      limit: _toInt(json['limit']),
      sort: _toStr(json['sort']),
      order: _toStr(json['order']),
      types: BenchmarkFacet.listFrom(facets['types']),
      orgs: BenchmarkFacet.listFrom(facets['orgs']),
    );
  }

  static const BenchmarkLeaderboard empty = BenchmarkLeaderboard(
    board: BenchmarkBoard.unknown,
    items: [],
    total: 0,
    offset: 0,
    limit: 50,
    sort: 'primary',
    order: 'desc',
    types: [],
    orgs: [],
  );

  final BenchmarkBoard board;
  final List<BenchmarkEntry> items;
  final int total;
  final int offset;
  final int limit;
  final String sort;
  final String order;
  final List<BenchmarkFacet> types;
  final List<BenchmarkFacet> orgs;
}

class BenchmarkHubStats {
  const BenchmarkHubStats({
    required this.modelId,
    required this.likes,
    required this.downloads30d,
    required this.downloadsAllTime,
    required this.trendingScore,
    required this.lastModified,
    required this.pipelineTag,
    required this.gated,
    required this.paramsTotal,
    required this.tags,
    required this.providers,
    required this.missing,
  });

  factory BenchmarkHubStats.fromJson(Map<String, dynamic> json) {
    return BenchmarkHubStats(
      modelId: _toStr(json['model_id']),
      likes: _toInt(json['likes']),
      downloads30d: _toInt(json['downloads_30d']),
      downloadsAllTime: _toInt(json['downloads_all_time']),
      trendingScore: _toDouble(json['trending_score']),
      lastModified: _toStr(json['last_modified']),
      pipelineTag: _toStr(json['pipeline_tag']),
      gated: _toBool(json['gated']),
      paramsTotal: _toInt(json['params_total']),
      tags: _toStringList(json['tags']),
      providers: _toStringList(json['inference_providers']),
      missing: _toBool(json['missing']),
    );
  }

  final String modelId;
  final int likes;
  final int downloads30d;
  final int downloadsAllTime;
  final double trendingScore;
  final String lastModified;
  final String pipelineTag;
  final bool gated;
  final int paramsTotal;
  final List<String> tags;
  final List<String> providers;
  final bool missing;
}

class BenchmarkCardResult {
  const BenchmarkCardResult({
    required this.task,
    required this.dataset,
    required this.metric,
    required this.value,
    required this.verified,
  });

  factory BenchmarkCardResult.fromJson(Map<String, dynamic> json) {
    return BenchmarkCardResult(
      task: _toStr(json['task']),
      dataset: _toStr(json['dataset']),
      metric: _toStr(json['metric']),
      value: _toDouble(json['value']),
      verified: _toBool(json['verified']),
    );
  }

  static List<BenchmarkCardResult> listFrom(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map<String, dynamic>>()
        .map(BenchmarkCardResult.fromJson)
        .toList(growable: false);
  }

  final String task;
  final String dataset;
  final String metric;
  final double value;
  final bool verified;
}

class BenchmarkDelta {
  const BenchmarkDelta({
    required this.value,
    required this.median,
    required this.diff,
  });

  factory BenchmarkDelta.fromJson(Map<String, dynamic> json) {
    return BenchmarkDelta(
      value: _toDouble(json['value']),
      median: _toDouble(json['median']),
      diff: _toDouble(json['diff']),
    );
  }

  static Map<String, BenchmarkDelta> mapFrom(dynamic value) {
    if (value is! Map) return const {};
    final result = <String, BenchmarkDelta>{};
    value.forEach((key, item) {
      if (key is String && item is Map<String, dynamic>) {
        result[key] = BenchmarkDelta.fromJson(item);
      }
    });
    return result;
  }

  final double value;
  final double median;
  final double diff;
}

class BenchmarkModelDetail {
  const BenchmarkModelDetail({
    required this.board,
    required this.modelId,
    required this.name,
    required this.entries,
    required this.best,
    required this.metricRanks,
    required this.percentile,
    required this.peers,
    required this.hub,
    required this.cardResults,
    required this.deltas,
    required this.metrics,
    required this.source,
    required this.scoreKind,
  });

  factory BenchmarkModelDetail.fromJson(Map<String, dynamic> json) {
    final ranks = <String, int>{};
    final rawRanks = json['metric_ranks'];
    if (rawRanks is Map) {
      rawRanks.forEach((key, value) {
        if (key is String) ranks[key] = _toInt(value);
      });
    }

    final rawBest = json['best'];
    final rawHub = json['hub'];
    return BenchmarkModelDetail(
      board: _toStr(json['board']),
      modelId: _toStr(json['model_id']),
      name: _toStr(json['name']),
      entries: BenchmarkEntry.listFrom(json['entries']),
      best: rawBest is Map<String, dynamic>
          ? BenchmarkEntry.fromJson(rawBest)
          : null,
      metricRanks: ranks,
      percentile: _toDouble(json['percentile']),
      peers: BenchmarkEntry.listFrom(json['peers']),
      hub: rawHub is Map<String, dynamic>
          ? BenchmarkHubStats.fromJson(rawHub)
          : null,
      cardResults: BenchmarkCardResult.listFrom(json['card_results']),
      deltas: BenchmarkDelta.mapFrom(json['deltas']),
      metrics: BenchmarkMetric.listFrom(json['metrics']),
      source: BenchmarkSource.fromJson(_toMap(json['source'])),
      scoreKind: _toStr(json['score_kind']),
    );
  }

  static List<BenchmarkModelDetail> listFrom(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map<String, dynamic>>()
        .map(BenchmarkModelDetail.fromJson)
        .toList(growable: false);
  }

  final String board;
  final String modelId;
  final String name;
  final List<BenchmarkEntry> entries;
  final BenchmarkEntry? best;
  final Map<String, int> metricRanks;
  final double percentile;
  final List<BenchmarkEntry> peers;
  final BenchmarkHubStats? hub;
  final List<BenchmarkCardResult> cardResults;
  final Map<String, BenchmarkDelta> deltas;
  final List<BenchmarkMetric> metrics;
  final BenchmarkSource source;
  final String scoreKind;

  bool get hasLeaderboardData => best != null;

  String get hubUrl => modelId.isEmpty ? '' : 'https://huggingface.co/$modelId';
}

class BenchmarkOverview {
  const BenchmarkOverview({
    required this.board,
    required this.boards,
    required this.totalEntries,
    required this.totalModels,
    required this.metricStats,
    required this.topOverall,
    required this.topByMetric,
    required this.topOpenWeights,
    required this.topOpenByMetric,
    required this.typeShare,
    required this.orgShare,
  });

  factory BenchmarkOverview.fromJson(Map<String, dynamic> json) {
    Map<String, List<BenchmarkEntry>> entriesByMetric(dynamic raw) {
      final result = <String, List<BenchmarkEntry>>{};
      if (raw is Map) {
        raw.forEach((key, value) {
          if (key is String) result[key] = BenchmarkEntry.listFrom(value);
        });
      }
      return result;
    }

    final topByMetric = entriesByMetric(json['top_by_metric']);

    return BenchmarkOverview(
      board: BenchmarkBoard.fromJson(_toMap(json['board'])),
      boards: BenchmarkBoard.listFrom(json['boards']),
      totalEntries: _toInt(json['total_entries']),
      totalModels: _toInt(json['total_models']),
      metricStats: BenchmarkMetricStats.mapFrom(json['metric_stats']),
      topOverall: BenchmarkEntry.listFrom(json['top_overall']),
      topByMetric: topByMetric,
      topOpenWeights: BenchmarkEntry.listFrom(json['top_open_weights']),
      topOpenByMetric: entriesByMetric(json['top_open_by_metric']),
      typeShare: BenchmarkFacet.listFrom(json['type_share']),
      orgShare: BenchmarkFacet.listFrom(json['org_share']),
    );
  }

  final BenchmarkBoard board;
  final List<BenchmarkBoard> boards;
  final int totalEntries;
  final int totalModels;
  final Map<String, BenchmarkMetricStats> metricStats;
  final List<BenchmarkEntry> topOverall;
  final Map<String, List<BenchmarkEntry>> topByMetric;

  final List<BenchmarkEntry> topOpenWeights;
  final Map<String, List<BenchmarkEntry>> topOpenByMetric;
  final List<BenchmarkFacet> typeShare;
  final List<BenchmarkFacet> orgShare;
}
