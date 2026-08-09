import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:culpeo_studio/core/app_strings.dart';
import 'package:culpeo_studio/modules/benchmark/benchmark_compare_tab.dart';
import 'package:culpeo_studio/modules/benchmark/benchmark_models.dart';
import 'package:culpeo_studio/modules/benchmark/benchmark_orgs.dart';
import 'package:culpeo_studio/modules/benchmark/benchmark_widgets.dart';
import 'package:culpeo_studio/modules/benchmark/benchmark_screen.dart';
import 'package:culpeo_studio/modules/benchmark/benchmark_wiki_dialog.dart';

const List<Map<String, dynamic>> _metrics = [
  {'key': 'coding', 'label': 'Coding', 'family': 'coding', 'url': 'https://x'},
  {'key': 'math', 'label': 'Math', 'family': 'math', 'url': 'https://x'},
];

Map<String, dynamic> _source({String state = 'ready'}) => {
  'provider': 'LMArena',
  'dataset': 'lmarena-ai/leaderboard-dataset',
  'url': 'https://huggingface.co/datasets/lmarena-ai/leaderboard-dataset',
  'live': true,
  'archived': false,
  'published_at': '2026-07-30',
  'fetched_at': '2026-07-31T10:00:00Z',
  'from_cache': true,
  'entries': 383,
  'models': 383,
  'state': state,
};

List<Map<String, dynamic>> _manyMetrics(int count) => [
  for (var index = 1; index <= count; index++)
    {'key': 'm$index', 'label': 'Wertung $index', 'family': '', 'url': ''},
];

Map<String, dynamic> _board({
  String state = 'ready',
  List<Map<String, dynamic>>? metrics,
}) => {
  'key': 'arena_text',
  'label': 'LMArena · Text',
  'kind': 'arena',
  'score_kind': 'elo',
  'primary_label': 'Elo',
  'score_max': 1600,
  'metrics': metrics ?? _metrics,
  'source': _source(state: state),
};

Map<String, dynamic> _entry(
  String name, {
  double primary = 1500,
  int rank = 1,
  String org = 'anthropic',
  String type = 'proprietary',
}) => {
  'board': 'arena_text',
  'key': name,
  'name': name,
  'org': org,
  'license': type == 'proprietary' ? 'Proprietary' : 'Apache 2.0',
  'type': type,
  'open_weights': type != 'proprietary',
  'primary': primary,
  'rank': rank,
  'scores': {'coding': primary + 10, 'math': primary - 20},
  'details': [
    {'key': 'votes', 'value': '2386'},
  ],
};

Map<String, dynamic> _boardsResponse() => {
  'boards': [_board()],
  'default': 'arena_text',
};

Map<String, dynamic> _status({String state = 'ready'}) => {
  'state': state,
  'loaded': state == 'ready' ? 383 : 120,
  'expected': 383,
  'refreshing': state != 'ready',
  'source': _source(state: state),
  'boards': [_board(state: state)],
};

Map<String, dynamic> _overview() => {
  'board': _board(),
  'boards': [_board()],
  'total_entries': 383,
  'total_models': 383,
  'metric_stats': [
    {
      'key': 'coding',
      'min': 1000,
      'max': 1530,
      'mean': 1200,
      'median': 1190,
      'top_model': 'claude-opus-5',
      'top_score': 1530,
      'evaluated': 378,
    },
  ],
  'top_overall': [
    _entry('claude-opus-5', primary: 1511.6, rank: 1),
    _entry(
      'qwen3-235b',
      primary: 1402.1,
      rank: 2,
      org: 'alibaba',
      type: 'open_weights',
    ),
  ],
  'top_by_metric': {
    'coding': [_entry('claude-opus-5', primary: 1511.6)],
  },

  'top_open_weights': [
    _entry(
      'qwen3-235b',
      primary: 1402.1,
      rank: 2,
      org: 'alibaba',
      type: 'open_weights',
    ),
  ],
  'top_open_by_metric': {
    'coding': [
      _entry(
        'qwen3-235b',
        primary: 1402.1,
        org: 'alibaba',
        type: 'open_weights',
      ),
    ],
  },
  'type_share': [
    {'value': 'proprietary', 'count': 120},
  ],
  'org_share': [
    {'value': 'anthropic', 'count': 18},
  ],
};

Map<String, dynamic> _leaderboard() => {
  'board': _board(),
  'items': [
    _entry('claude-opus-5', primary: 1511.6, rank: 1),
    _entry(
      'qwen3-235b',
      primary: 1402.1,
      rank: 2,
      org: 'alibaba',
      type: 'open_weights',
    ),
  ],
  'total': 2,
  'offset': 0,
  'limit': 50,
  'sort': 'primary',
  'order': 'desc',
  'facets': {
    'types': [
      {'value': 'proprietary', 'count': 120},
      {'value': 'open_weights', 'count': 263},
    ],
    'orgs': [
      {'value': 'anthropic', 'count': 18},
    ],
  },
};

Map<String, dynamic> _detail(String modelId, {double primary = 1511.6}) => {
  'board': 'arena_text',
  'model_id': '',
  'name': modelId,
  'entries': [_entry(modelId)],
  'best': _entry(modelId, primary: primary, rank: 1),
  'metric_ranks': {'coding': 1, 'math': 3},
  'percentile': 99.7,
  'deltas': {
    'primary': {'value': 1511.6, 'median': 1150.0, 'diff': 361.6},
    'coding': {'value': 1521.6, 'median': 1140.0, 'diff': 381.6},
  },
  'metrics': _metrics,
  'score_kind': 'elo',
  'source': _source(),
  'hub': {
    'model_id': 'acme/model',
    'likes': 342,
    'downloads_30d': 125000,
    'downloads_all_time': 4200000,
    'trending_score': 7.0,
    'gated': false,
    'missing': false,
  },
  'peers': [_entry('gpt-5.5', primary: 1469.0, rank: 4, org: 'openai')],
};

Future<void> _pumpScreen(
  WidgetTester tester,
  Widget screen, {
  Size size = const Size(1600, 1200),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(backgroundColor: const Color(0xFF0A0A0B), body: screen),
    ),
  );
  await tester.pump();
}

/// Unfolds a wiki point, scrolling the list to it first. Points below the fold
/// are not built yet, so they have to be scrolled up to rather than revealed.
Future<void> _openWikiPoint(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      160,
      scrollable: find
          .descendant(
            of: find.byType(BenchmarkWikiDialog),
            matching: find.byType(Scrollable),
          )
          .first,
    );
  } else {
    await tester.ensureVisible(finder);
  }
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Restricts a finder to the wiki, so the board behind it cannot answer.
Finder _inWiki(Finder matching) =>
    find.descendant(of: find.byType(BenchmarkWikiDialog), matching: matching);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => appLanguage = 'de');

  BenchmarkScreen buildScreen({
    Map<String, dynamic>? status,
    Map<String, dynamic>? overview,
    Map<String, dynamic>? leaderboard,
    void Function(Map<String, dynamic> params)? onLeaderboardRequest,
    List<String>? comparedIds,
  }) {
    return BenchmarkScreen(
      loadBoards: () async => _boardsResponse(),
      loadStatus: (board) async => status ?? _status(),
      loadOverview: (board) async => overview ?? _overview(),
      loadLeaderboard:
          ({
            required String board,
            required String query,
            required List<String> types,
            required List<String> orgs,
            required bool openWeightsOnly,
            required String sort,
            required String order,
            required int offset,
            required int limit,
          }) async {
            onLeaderboardRequest?.call({
              'board': board,
              'query': query,
              'types': types,
              'openWeightsOnly': openWeightsOnly,
              'sort': sort,
              'order': order,
              'offset': offset,
            });
            return leaderboard ?? _leaderboard();
          },
      loadModel: (board, modelId) async => _detail(modelId),
      loadCompare: (board, modelIds) async {
        comparedIds
          ?..clear()
          ..addAll(modelIds);
        return {
          'models': [for (final id in modelIds) _detail(id)],
          'board': _board(),
        };
      },
      refreshData: (board) async {},
    );
  }

  testWidgets('the header corner carries the date and the refresh', (
    tester,
  ) async {
    await _pumpScreen(tester, buildScreen());
    await tester.pumpAndSettle();

    expect(find.text('2026-07-30'), findsOneWidget);
    expect(find.byKey(const ValueKey('benchmark-refresh')), findsOneWidget);

    expect(find.byKey(const ValueKey('benchmark-open-source')), findsNothing);
    expect(find.textContaining('Stand der Daten'), findsNothing);
    expect(find.text('LMArena'), findsNothing);
  });

  testWidgets('hides the board switcher while there is only one source', (
    tester,
  ) async {
    await _pumpScreen(tester, buildScreen());
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('benchmark-board-arena_text')),
      findsNothing,
    );
  });

  testWidgets('the board opens on the leaderboard, without an overview tab', (
    tester,
  ) async {
    await _pumpScreen(tester, buildScreen());
    await tester.pumpAndSettle();

    expect(find.text('Überblick'), findsNothing);
    expect(find.text('Spitzenreiter gesamt'), findsNothing);
    expect(find.byKey(const ValueKey('benchmark-podium-1')), findsNothing);

    expect(find.text('Rangliste'), findsOneWidget);
    expect(find.text('Vergleich'), findsOneWidget);
    expect(find.text('2 Modelle'), findsOneWidget);

    expect(find.text('1512'), findsWidgets);
    expect(find.text('CODING'), findsOneWidget);

    expect(find.byType(Image), findsNothing);
    expect(find.byIcon(Icons.workspace_premium_rounded), findsNothing);
    expect(find.byIcon(Icons.terminal_rounded), findsNothing);
    expect(find.byIcon(Icons.functions_rounded), findsNothing);
    expect(find.byIcon(Icons.leaderboard_rounded), findsNothing);
    expect(find.byIcon(Icons.dashboard_outlined), findsNothing);
  });

  testWidgets('the wiki keeps every category folded until it is asked for', (
    tester,
  ) async {
    await _pumpScreen(tester, buildScreen());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('benchmark-wiki')));
    await tester.pumpAndSettle();

    expect(find.byType(BenchmarkWikiDialog), findsOneWidget);
    expect(find.text('Benchmark-Wiki'), findsOneWidget);
    expect(_inWiki(find.text('Coding')), findsOneWidget);
    expect(
      find.textContaining('Wer schreibt den Code'),
      findsNothing,
      reason: 'die Kategorie steht offen, bevor jemand sie antippt',
    );

    await _openWikiPoint(tester, 'benchmark-wiki-metric-coding');

    expect(find.textContaining('Wer schreibt den Code'), findsOneWidget);

    final art = find.byKey(const ValueKey('benchmark-wiki-art-coding'));
    expect(art, findsOneWidget);
    expect(
      find.descendant(of: art, matching: find.text('1190')),
      findsOneWidget,
      reason: 'der Median fehlt',
    );
    expect(
      find.descendant(of: art, matching: find.text('1530')),
      findsOneWidget,
      reason: 'der Bestwert fehlt',
    );
    expect(
      _inWiki(find.text('1522')),
      findsOneWidget,
      reason: 'der Kategoriesieger zeigt nicht seinen Kategoriewert',
    );

    await _openWikiPoint(tester, 'benchmark-wiki-score');
    expect(
      find.textContaining('ist eine Vergleichszahl, keine Prozentzahl'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Wer schreibt den Code'),
      findsNothing,
      reason: 'zwei Punkte stehen gleichzeitig offen',
    );

    await tester.tap(find.byKey(const ValueKey('benchmark-wiki-close')));
    await tester.pumpAndSettle();
    expect(find.byType(BenchmarkWikiDialog), findsNothing);
  });

  testWidgets('a category without values keeps its empty state in the wiki', (
    tester,
  ) async {
    await _pumpScreen(tester, buildScreen());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('benchmark-wiki')));
    await tester.pumpAndSettle();
    await _openWikiPoint(tester, 'benchmark-wiki-metric-math');

    final art = find.byKey(const ValueKey('benchmark-wiki-art-math'));
    expect(
      find.descendant(
        of: art,
        matching: find.textContaining('keine Werte vor'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('the wiki holds the real copy at every window width', (
    tester,
  ) async {
    const keys = [
      'hard_prompts',
      'coding',
      'math',
      'creative_writing',
      'instruction_following',
      'multi_turn',
      'longer_query',
      'non_english',
    ];
    final data = _overview();
    data['board'] = _board(
      metrics: [
        for (final key in keys)
          {'key': key, 'label': 'Wertung $key', 'family': key, 'url': ''},
      ],
    );
    data['metric_stats'] = [
      for (final key in keys)
        {
          'key': key,
          'min': 1000,
          'max': 1530,
          'mean': 1200,
          'median': 1190,
          'top_model': 'claude-opus-5',
          'top_score': 1530,
          'evaluated': 378,
        },
    ];

    for (final width in [480.0, 1100.0, 1600.0]) {
      await _pumpScreen(
        tester,
        buildScreen(overview: data),
        size: Size(width, 1200),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('benchmark-wiki')));
      await tester.pumpAndSettle();
      await _openWikiPoint(tester, 'benchmark-wiki-metric-coding');

      expect(
        find.byKey(const ValueKey('benchmark-wiki-art-coding')),
        findsOneWidget,
        reason: 'bei $width px fehlt die Verteilungsgrafik',
      );
      expect(tester.takeException(), isNull, reason: 'Überlauf bei $width px');

      await tester.tap(find.byKey(const ValueKey('benchmark-wiki-close')));
      await tester.pumpAndSettle();
    }
  });

  testWidgets('a category score in the detail view opens its wiki entry', (
    tester,
  ) async {
    await _pumpScreen(tester, buildScreen());
    await tester.pumpAndSettle();

    await tester.tap(find.text('claude-opus-5').first);
    await tester.pumpAndSettle();

    expect(find.text('Teilwertungen'), findsOneWidget);
    expect(find.textContaining('Wer schreibt den Code'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('benchmark-explain-coding')));
    await tester.pumpAndSettle();

    expect(find.byType(BenchmarkWikiDialog), findsOneWidget);
    expect(
      find.textContaining('Wer schreibt den Code'),
      findsOneWidget,
      reason: 'das Wiki öffnet nicht bei der angetippten Kategorie',
    );
  });

  testWidgets('no open-weights switch and no size classes remain', (
    tester,
  ) async {
    await _pumpScreen(tester, buildScreen());
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('benchmark-open-weights')), findsNothing);
    expect(find.byKey(const ValueKey('benchmark-size-filter')), findsNothing);
    expect(find.text('Was auf deine Hardware passt'), findsNothing);
  });

  testWidgets('the leaderboard stays overflow-free when narrow', (
    tester,
  ) async {
    await _pumpScreen(tester, buildScreen(), size: const Size(720, 900));
    await tester.pumpAndSettle();

    expect(find.text('2 Modelle'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a running sync shows the progress instead of an empty list', (
    tester,
  ) async {
    await _pumpScreen(tester, buildScreen(status: _status(state: 'loading')));
    await tester.pump();

    expect(find.text('Rangliste wird geladen'), findsOneWidget);
    expect(find.text('120 von 383 Läufen'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets('leaderboard requests carry search, sort and filters', (
    tester,
  ) async {
    final requests = <Map<String, dynamic>>[];
    await _pumpScreen(tester, buildScreen(onLeaderboardRequest: requests.add));
    await tester.pumpAndSettle();

    expect(requests.last['board'], 'arena_text');
    expect(requests.last['sort'], 'primary');
    expect(find.text('2 Modelle'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('benchmark-search')),
      'qwen',
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(requests.last['query'], 'qwen');

    await tester.tap(find.byKey(const ValueKey('benchmark-sort-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Math').last);
    await tester.pumpAndSettle();
    expect(requests.last['sort'], 'math');
  });

  testWidgets('a column header sorts, a second tap turns it around', (
    tester,
  ) async {
    final requests = <Map<String, dynamic>>[];
    await _pumpScreen(tester, buildScreen(onLeaderboardRequest: requests.add));
    await tester.pumpAndSettle();

    expect(requests.last['order'], 'desc');

    await tester.tap(find.byKey(const ValueKey('benchmark-column-name')));
    await tester.pumpAndSettle();
    expect(requests.last['sort'], 'name');

    expect(requests.last['order'], 'asc');

    await tester.tap(find.byKey(const ValueKey('benchmark-column-name')));
    await tester.pumpAndSettle();
    expect(requests.last['sort'], 'name');
    expect(requests.last['order'], 'desc');

    await tester.tap(find.byKey(const ValueKey('benchmark-column-coding')));
    await tester.pumpAndSettle();
    expect(requests.last['sort'], 'coding');
    expect(requests.last['order'], 'desc');
  });

  testWidgets('a wide window fills its columns with scores', (tester) async {
    await _pumpScreen(tester, buildScreen());
    await tester.pumpAndSettle();

    expect(find.text('PLATZ'), findsOneWidget);
    expect(find.text('MODELL'), findsOneWidget);
    expect(find.text('ANBIETER'), findsOneWidget);
    expect(find.text('CODING'), findsOneWidget);

    expect(find.text('1522'), findsOneWidget);
  });

  testWidgets('the rank column shows the place of the board, not the row', (
    tester,
  ) async {
    final page = _leaderboard();
    page['items'] = [
      _entry(
        'qwen3-235b',
        primary: 1402.1,
        rank: 7,
        org: 'alibaba',
        type: 'open_weights',
      ),
    ];
    page['total'] = 1;

    await _pumpScreen(tester, buildScreen(leaderboard: page));
    await tester.pumpAndSettle();

    expect(find.text('7'), findsOneWidget);
  });

  testWidgets('tapping a model opens its detail view with hub numbers', (
    tester,
  ) async {
    await _pumpScreen(tester, buildScreen());
    await tester.pumpAndSettle();

    await tester.tap(find.text('claude-opus-5').first);
    await tester.pumpAndSettle();

    expect(find.textContaining('Stärker als 99.7'), findsOneWidget);
    expect(find.text('Live vom Hugging-Face-Hub'), findsOneWidget);
    expect(find.text('125.0 Tsd.'), findsOneWidget);
    expect(find.text('Platz 1'), findsWidgets);

    expect(find.text('Abstimmungen'), findsOneWidget);
    expect(find.text('Vergleichbare Modelle'), findsNothing);
  });

  testWidgets('every detail bar runs from zero to the best of its category', (
    tester,
  ) async {
    await _pumpScreen(tester, buildScreen());
    await tester.pumpAndSettle();

    await tester.tap(find.text('claude-opus-5').first);
    await tester.pumpAndSettle();

    final bars = tester
        .widgetList<BenchmarkScoreBar>(find.byType(BenchmarkScoreBar))
        .toList();

    expect(bars, hasLength(3));
    expect(
      bars.first.scoreMax,
      1511.6,
      reason: 'die Gesamtwertung endet nicht beim Spitzenreiter des Feldes',
    );
    expect(
      bars[1].scoreMax,
      1530,
      reason: 'Coding endet nicht beim Bestwert dieser Kategorie',
    );
    expect(
      bars.last.scoreMax,
      1600,
      reason: 'ohne Statistik fehlt der Rückfall auf das Board-Maximum',
    );

    // A filled bar, not an empty track with a median tick: the leader in a
    // category reaches the end, everyone else a real share of it.
    final coding = bars[1];
    expect(coding.value / coding.scoreMax, greaterThan(0.9));
    expect(bars.first.value / bars.first.scoreMax, greaterThan(0.9));
  });

  testWidgets('models can be collected for the comparison tab', (tester) async {
    final compared = <String>[];
    await _pumpScreen(tester, buildScreen(comparedIds: compared));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.compare_arrows).first);
    await tester.pumpAndSettle();

    expect(compared, ['claude-opus-5']);
    expect(find.text('Vergleich (1)'), findsOneWidget);

    await tester.tap(find.text('Vergleich (1)'));
    await tester.pumpAndSettle();

    expect(find.text('WERTUNGEN IM VERGLEICH'), findsOneWidget);
    expect(find.text('Coding'), findsOneWidget);
    expect(find.byTooltip('Bester Wert der Auswahl'), findsWidgets);
  });

  testWidgets('the comparison tab stays informative while empty', (
    tester,
  ) async {
    await _pumpScreen(tester, buildScreen());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Vergleich'));
    await tester.pumpAndSettle();

    expect(find.textContaining('bis zu vier Modelle'), findsOneWidget);
  });

  testWidgets('a failing backend surfaces the error and offers a retry', (
    tester,
  ) async {
    var attempts = 0;
    final screen = BenchmarkScreen(
      loadBoards: () async {
        attempts++;
        throw Exception('Backend nicht erreichbar');
      },
      loadStatus: (board) async => _status(),
      loadOverview: (board) async => _overview(),
      loadLeaderboard:
          ({
            required String board,
            required String query,
            required List<String> types,
            required List<String> orgs,
            required bool openWeightsOnly,
            required String sort,
            required String order,
            required int offset,
            required int limit,
          }) async => _leaderboard(),
      loadModel: (board, modelId) async => _detail(modelId),
      loadCompare: (board, modelIds) async => {'models': const []},
      refreshData: (board) async {},
    );

    await _pumpScreen(tester, screen);
    await tester.pumpAndSettle();

    expect(
      find.text('Benchmark-Daten konnten nicht geladen werden.'),
      findsOneWidget,
    );
    expect(find.textContaining('Backend nicht erreichbar'), findsOneWidget);

    await tester.tap(find.text('Erneut versuchen'));
    await tester.pumpAndSettle();
    expect(attempts, 2);
  });

  testWidgets('only the first three ranks carry a coloured rule', (
    tester,
  ) async {
    final entry = BenchmarkEntry.fromJson(_entry('claude-opus-5', rank: 1));
    final board = BenchmarkBoard.fromJson(_board());

    tester.view.physicalSize = const Size(1200, 400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final layout = BenchmarkTableLayout.of(width: 1200, board: board);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              BenchmarkTableRow(
                entry: entry,
                position: 1,
                board: board,
                layout: layout,
              ),
              BenchmarkTableRow(
                entry: entry,
                position: 9,
                board: board,
                layout: layout,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final stripes = tester
        .widgetList<DecoratedBox>(find.byType(DecoratedBox))
        .map((box) => (box.decoration as BoxDecoration).color)
        .whereType<Color>()
        .toList();

    final brand = benchmarkOrgBrand('anthropic').color;

    expect(
      stripes.contains(benchmarkRankColor(1).withValues(alpha: 0.7)),
      isTrue,
      reason: 'Platz 1 zeigt nicht die Medaillenfarbe',
    );

    expect(
      stripes.any((color) => color.a > 0 && color.r == brand.r),
      isFalse,
      reason: 'die Anbieterfarbe färbt weiterhin ganze Zeilen ein',
    );

    final providers = tester
        .widgetList<Text>(find.text('Anthropic'))
        .map((text) => text.style?.color)
        .toList();
    expect(
      providers,
      everyElement(benchmarkOrgInk(brand)),
      reason: 'die Anbieterspalte trägt die Herstellerfarbe nicht mehr',
    );

    final scores = tester
        .widgetList<Text>(find.text('1500'))
        .map((text) => text.style?.color)
        .toList();
    expect(scores, hasLength(2));
    expect(scores.first, benchmarkRankColor(1));
    expect(scores.last, benchmarkRankColor(9));
    expect(scores.last, isNot(benchmarkRankColor(1)));
  });

  test('the column layout never asks for more width than it has', () {
    final board = BenchmarkBoard.fromJson(_board());

    for (final width in [420.0, 560.0, 719.0, 720.0, 900.0, 1200.0, 2400.0]) {
      for (final dense in [false, true]) {
        for (final hasCompare in [false, true]) {
          final layout = BenchmarkTableLayout.of(
            width: width,
            board: board,
            dense: dense,
            hasCompare: hasCompare,
          );
          expect(
            layout.wantedWidth,
            lessThanOrEqualTo(width),
            reason: 'Breite $width, dicht: $dense, Vergleich: $hasCompare',
          );
        }
      }
    }
  });

  test('the metric window shows five scores and slides over the rest', () {
    final board = BenchmarkBoard.fromJson(_board(metrics: _manyMetrics(8)));

    final start = BenchmarkTableLayout.of(width: 2200, board: board);
    expect(start.metricSlots, BenchmarkTableLayout.maxMetrics);
    expect(start.metrics, hasLength(8));
    expect(start.firstVisibleMetric, 1);
    expect(start.lastVisibleMetric, 5);

    final step = start.metricWidth + BenchmarkTableLayout.gap;
    expect(start.metricScrollMax, moreOrLessEquals(3 * step, epsilon: 0.5));

    final nudged = BenchmarkTableLayout.of(
      width: 2200,
      board: board,
      metricScroll: step * 1.5,
    );
    expect(nudged.metricScroll, moreOrLessEquals(step * 1.5, epsilon: 0.5));
    expect(nudged.firstVisibleMetric, 2);

    final clamped = BenchmarkTableLayout.of(
      width: 2200,
      board: board,
      metricScroll: 9999,
    );
    expect(clamped.metricScroll, clamped.metricScrollMax);
    expect(clamped.lastVisibleMetric, 8);

    final few = BenchmarkBoard.fromJson(_board());
    expect(BenchmarkTableLayout.of(width: 2200, board: few).metricScrollMax, 0);
  });

  testWidgets('the header carries the slider over the score columns', (
    tester,
  ) async {
    final board = BenchmarkBoard.fromJson(_board(metrics: _manyMetrics(8)));
    var moved = -1.0;

    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Future<void> pumpHeader(double width, {bool sliding = true}) async {
      tester.view.physicalSize = Size(width, 200);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BenchmarkTableHeader(
              layout: BenchmarkTableLayout.of(width: width, board: board),
              board: board,
              onMetricWindow: sliding ? (scroll) => moved = scroll : null,
            ),
          ),
        ),
      );
      await tester.pump();
    }

    await pumpHeader(2200, sliding: false);
    expect(find.byType(Slider), findsNothing);

    await pumpHeader(460);
    expect(find.byType(Slider), findsNothing);

    await pumpHeader(2200);
    final slider = tester.widget<Slider>(find.byType(Slider));

    expect(slider.divisions, isNull);
    expect(slider.max, greaterThan(0));

    slider.onChanged!(37.5);
    expect(moved, 37.5);

    double opacity() =>
        tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity;
    expect(opacity(), 0);

    final pointer = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await pointer.addPointer(location: Offset.zero);
    addTearDown(pointer.removePointer);
    await pointer.moveTo(tester.getCenter(find.byType(BenchmarkTableHeader)));
    await tester.pumpAndSettle();
    expect(opacity(), 1);
  });

  testWidgets('every header label sits exactly over its own column', (
    tester,
  ) async {
    final board = BenchmarkBoard.fromJson(_board(metrics: _manyMetrics(8)));
    final entryJson = _entry('claude-opus-5', rank: 4);

    entryJson['scores'] = {'m1': 1510.0, 'm2': 1490.0};
    final entry = BenchmarkEntry.fromJson(entryJson);
    const width = 2200.0;

    tester.view.physicalSize = const Size(width, 400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final layout = BenchmarkTableLayout.of(
      width: width,
      board: board,
      hasCompare: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              BenchmarkTableHeader(layout: layout, board: board),
              BenchmarkTableRow(
                entry: entry,
                position: 4,
                board: board,
                layout: layout,
                onCompare: () {},
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.getTopLeft(find.text('ANBIETER')).dx,
      moreOrLessEquals(
        tester.getTopLeft(find.text('Anthropic')).dx,
        epsilon: 1,
      ),
    );

    expect(
      tester.getTopLeft(find.text('ELO')).dx,
      moreOrLessEquals(tester.getTopLeft(find.text('1500')).dx, epsilon: 1),
    );

    expect(
      tester.getTopLeft(find.text('WERTUNG 1')).dx,
      moreOrLessEquals(tester.getTopLeft(find.text('1510')).dx, epsilon: 1),
    );

    final first = tester.getTopLeft(find.text('WERTUNG 1')).dx;
    final second = tester.getTopLeft(find.text('WERTUNG 2')).dx;
    final third = tester.getTopLeft(find.text('WERTUNG 3')).dx;
    expect(second - first, moreOrLessEquals(third - second, epsilon: 0.5));
  });

  test('a wide table keeps the scores clear of the bar', () {
    final board = BenchmarkBoard.fromJson(_board(metrics: _manyMetrics(8)));
    const width = 2200.0;
    final layout = BenchmarkTableLayout.of(
      width: width,
      board: board,
      hasCompare: true,
    );

    expect(layout.scoreGap, greaterThan(0));

    final modelWidth = layout.modelMin + (width - layout.wantedWidth);
    expect(modelWidth, lessThanOrEqualTo(460));
  });

  testWidgets('the comparison keeps its column width beyond four models', (
    tester,
  ) async {
    final board = BenchmarkBoard.fromJson(_board());

    tester.view.physicalSize = const Size(1400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Future<void> pumpCompare(int count) async {
      final ids = [for (var i = 1; i <= count; i++) 'm$i'];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BenchmarkCompareTab(
              board: board,
              modelIds: ids,
              details: [
                for (var i = 0; i < count; i++)
                  BenchmarkModelDetail.fromJson(
                    _detail(ids[i], primary: 1500 - i * 10.0),
                  ),
              ],
              isLoading: false,
              error: null,
              onRemove: (_) {},
              onClear: () {},
              onOpenModel: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    double pitch() =>
        tester.getTopLeft(find.text('m2')).dx -
        tester.getTopLeft(find.text('m1')).dx;

    await pumpCompare(4);
    final withFour = pitch();

    await pumpCompare(7);

    expect(find.text('m7'), findsOneWidget);
    expect(pitch(), moreOrLessEquals(withFour, epsilon: 0.5));

    expect(find.text('−10'), findsWidgets);

    final before = tester.getTopLeft(find.text('m1')).dx;
    await tester.tap(find.byKey(const ValueKey('benchmark-compare-on')));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('m1')).dx, lessThan(before));

    await tester.tap(find.byKey(const ValueKey('benchmark-compare-back')));
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.text('m1')).dx,
      moreOrLessEquals(before, epsilon: 0.5),
    );

    await pumpCompare(4);
    expect(find.byKey(const ValueKey('benchmark-compare-on')), findsNothing);
  });

  test('leaderboard responses are parsed into typed models', () {
    final page = BenchmarkLeaderboard.fromJson(_leaderboard());

    expect(page.items, hasLength(2));
    expect(page.items.first.name, 'claude-opus-5');
    expect(page.items.first.scoreOf('coding'), 1521.6);
    expect(page.items.first.openWeights, isFalse);
    expect(page.board.scoreKind, 'elo');
    expect(page.board.source.live, isTrue);
    expect(page.types.map((facet) => facet.value), [
      'proprietary',
      'open_weights',
    ]);
  });

  test('a bar track carries the fill hue instead of a neutral wash', () {
    const fill = Color(0xFF8AC194);
    final track = benchmarkTrackColor(fill);

    expect(track.r, fill.r);
    expect(track.g, fill.g);
    expect(track.b, fill.b);
    expect(
      track.a,
      greaterThan(0.12),
      reason: 'ein zu blasser Track lässt einen vollen Balken ungefüllt wirken',
    );
  });

  test('each category is capped by its own leader, the board by the first', () {
    final data = _overview();
    data['metric_stats'] = [
      {
        'key': 'coding',
        'median': 1190,
        'max': 1530,
        'top_model': 'claude-opus-5',
        'evaluated': 378,
      },
      {'key': 'math', 'median': 1358, 'max': 1564, 'evaluated': 370},
      {'key': 'leer', 'median': 0, 'max': 0, 'evaluated': 0},
    ];

    final tops = BenchmarkFieldTops.of(BenchmarkOverview.fromJson(data));

    expect(tops.primary, 1511.6, reason: 'Platz 1 deckelt die Gesamtwertung');
    expect(tops.ceilingOf('coding'), 1530);
    expect(tops.ceilingOf('math'), 1564);

    expect(
      tops.ceilingOf('leer', fallback: 1600),
      1600,
      reason: 'eine Kategorie ohne Werte fällt nicht auf das Board zurück',
    );
    expect(tops.ceilingOf('gibt-es-nicht', fallback: 1600), 1600);
    expect(BenchmarkFieldTops.empty.primaryCeiling(fallback: 1600), 1600);
  });

  test('missing or malformed fields fall back instead of throwing', () {
    final detail = BenchmarkModelDetail.fromJson({
      'model_id': 'ghost/model',
      'entries': 'kaputt',
      'metric_ranks': {'coding': 'zwei'},
      'hub': null,
    });

    expect(detail.entries, isEmpty);
    expect(detail.best, isNull);
    expect(detail.hasLeaderboardData, isFalse);
    expect(detail.metricRanks['coding'], 0);
    expect(detail.hub, isNull);
    expect(detail.source.state, 'empty');

    final entry = BenchmarkEntry.fromJson({'name': 'nur-name'});
    expect(entry.scores, isEmpty);
    expect(entry.scoreOf('was-auch-immer'), 0);
    expect(entry.lookupId, 'nur-name');
  });
}
