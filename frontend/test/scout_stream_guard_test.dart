import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:culpeo_studio/core/api_service.dart';
import 'package:culpeo_studio/modules/marketplace/marketplace_api.dart';
import 'package:culpeo_studio/modules/scout/scout_api.dart';
import 'package:culpeo_studio/core/app_state.dart';
import 'package:culpeo_studio/modules/engine/models.dart';
import 'package:culpeo_studio/modules/scout/model_warmup.dart';
import 'package:culpeo_studio/modules/scout/scout_tab.dart';
import 'package:culpeo_studio/modules/spark/plan_checklist.dart';

void main() {
  testWidgets(
    'active stream locks restart and ignores callbacks after session switch',
    (tester) async {
      final streamGate = Completer<void>();
      final api = _FakeChatApi(
        streamGate: streamGate,
        streamBeforeGate: const [
          ScoutStreamEvent(type: 'status', data: {'action': 'starting'}),
        ],
        streamAfterGate: const [
          ScoutStreamEvent(
            type: 'text_delta',
            data: {'chunk': 'STALE_OLD_RESPONSE'},
          ),
          ScoutStreamEvent(type: 'done', data: {}),
        ],
      );
      final appState = AppState.test(api);
      await _pumpChat(tester, api, appState);

      await tester.enterText(find.byType(TextField).last, 'Langsame Antwort');
      await tester.pump();
      _pressIconButton(tester, const Key('chat-send-button'));
      await _pumpUntil(tester, () => api.streamCalls == 1);

      expect(api.streamCalls, 1);
      expect(
        tester
            .widget<IconButton>(find.byKey(const Key('chat-add-button')))
            .onPressed,
        isNull,
      );
      appState.triggerAction('new_chat_session');
      await tester.pump();
      expect(api.createdSessions, 1);

      appState.currentChatSessionId = 'external-session';
      appState.notifyListeners();
      await tester.pump();
      streamGate.complete();
      await _pumpFrames(tester);

      expect(find.textContaining('STALE_OLD_RESPONSE'), findsNothing);
      expect(api.createdSessions, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('a planned run puts its worklist on screen and ticks it off', (
    tester,
  ) async {
    final api = _FakeChatApi(
      firstStreamEvents: const [
        ScoutStreamEvent(
          type: 'plan_started',
          data: {
            'session_id': 'session-1',
            'total': 2,
            'planning': {
              'plan_summary': 'Zwei Schritte',
              'plan_steps': [
                {'number': 1, 'title': 'Config lesen', 'status': 'pending'},
                {'number': 2, 'title': 'Timeout setzen', 'status': 'pending'},
              ],
            },
          },
        ),
        ScoutStreamEvent(
          type: 'plan_step_start',
          data: {
            'step': 1,
            'total': 2,
            'title': 'Config lesen',
            'status': 'running',
          },
        ),
        ScoutStreamEvent(
          type: 'plan_step_result',
          data: {
            'step': 1,
            'total': 2,
            'title': 'Config lesen',
            'status': 'done',
            'result': 'Timeout steht auf 10s',
          },
        ),
        ScoutStreamEvent(
          type: 'plan_step_start',
          data: {
            'step': 2,
            'total': 2,
            'title': 'Timeout setzen',
            'status': 'running',
          },
        ),
      ],
    );

    final appState = AppState.test(api);
    await _pumpChat(tester, api, appState);

    await tester.enterText(find.byType(TextField).last, 'Timeout erhoehen');
    await tester.pump();
    _pressIconButton(tester, const Key('chat-send-button'));
    await _pumpUntil(
      tester,
      () => find.byType(PlanChecklist).evaluate().isNotEmpty,
    );
    await _pumpFrames(tester);

    final checklist = tester.widget<PlanChecklist>(find.byType(PlanChecklist));
    expect(checklist.steps.length, 2);
    expect(checklist.steps[0]['status'], 'done');
    expect(checklist.steps[0]['result'], 'Timeout steht auf 10s');
    expect(checklist.steps[1]['status'], 'running');
    expect(checklist.running, isTrue);
    expect(find.text('Timeout setzen'), findsOneWidget);
  });

  testWidgets('a worklist with every point green leaves the composer', (
    tester,
  ) async {
    final api = _FakeChatApi(
      firstStreamEvents: const [
        ScoutStreamEvent(
          type: 'plan_started',
          data: {
            'session_id': 'session-1',
            'total': 1,
            'planning': {
              'plan_summary': 'Ein Schritt',
              'plan_steps': [
                {'number': 1, 'title': 'Config lesen', 'status': 'pending'},
              ],
            },
          },
        ),
        ScoutStreamEvent(
          type: 'plan_step_result',
          data: {'step': 1, 'total': 1, 'status': 'done', 'result': 'fertig'},
        ),
        ScoutStreamEvent(
          type: 'plan_finished',
          data: {
            'session_id': 'session-1',
            'total': 1,
            'done': 1,
            'failed': 0,
            'pending': 0,
            'planning': {
              'plan_steps': [
                {'number': 1, 'title': 'Config lesen', 'status': 'done'},
              ],
            },
          },
        ),
      ],
    );

    final appState = AppState.test(api);
    await _pumpChat(tester, api, appState);

    await tester.enterText(find.byType(TextField).last, 'Timeout erhoehen');
    await tester.pump();
    _pressIconButton(tester, const Key('chat-send-button'));
    await _pumpUntil(tester, () => api.streamCalls == 1);
    await _pumpFrames(tester);

    expect(find.byType(PlanChecklist), findsNothing);
  });

  testWidgets('a fast double retry starts only one additional SSE request', (
    tester,
  ) async {
    final retryGate = Completer<void>();
    final api = _FakeChatApi(
      firstStreamEvents: const [
        ScoutStreamEvent(
          type: 'error',
          data: {
            'code': 'model_binding_missing',
            'message': 'Gebundenes Modell fehlt',
          },
        ),
      ],
      streamGate: retryGate,
      streamAfterGate: const [ScoutStreamEvent(type: 'done', data: {})],
    );
    final appState = AppState.test(api);
    await _pumpChat(tester, api, appState);

    await tester.enterText(find.byType(TextField).last, 'Einmal senden');
    await tester.pump();
    _pressIconButton(tester, const Key('chat-send-button'));
    await _pumpUntil(
      tester,
      () => find.text('Erneut versuchen').evaluate().isNotEmpty,
    );
    expect(find.text('Erneut versuchen'), findsOneWidget);
    expect(api.streamCalls, 1);

    final retry = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('Erneut versuchen'),
        matching: find.byType(FilledButton),
      ),
    );
    expect(retry.onPressed, isNotNull);
    retry.onPressed!.call();
    retry.onPressed!.call();
    await _pumpUntil(tester, () => api.streamCalls == 2);
    expect(api.streamCalls, 2);

    retryGate.complete();
    await _pumpFrames(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cancel during delayed ensure cancels the late operation', (
    tester,
  ) async {
    final ensureGate = Completer<void>();
    final api = _FakeChatApi(
      engineInstances: [_engineInstance(state: 'stopped')],
      ensureGate: ensureGate,
    );
    final appState = AppState.test(api);
    await _pumpChat(tester, api, appState);

    // Model selection now happens through the sidebar's published callback,
    // not a picker button in the composer.
    appState.chatModelPicker!.onSelect('local:local-stopped');
    await tester.pump();
    expect(api.ensureCalls, 1);
    expect(find.byKey(const Key('model-warmup-cancel')), findsOneWidget);

    final cancel = tester.widget<TextButton>(
      find.byKey(const Key('model-warmup-cancel')),
    );
    expect(cancel.onPressed, isNotNull);
    cancel.onPressed!.call();
    await tester.pump();
    expect(
      tester
          .widget<ModelWarmupPanel>(find.byType(ModelWarmupPanel))
          .progress
          .status,
      'cancelled',
    );
    await _pumpUntil(
      tester,
      () => find.text('Modellstart wurde abgebrochen').evaluate().isNotEmpty,
    );
    ensureGate.complete();
    await _pumpUntil(tester, () => api.cancelCalls == 1);

    expect(api.cancelCalls, 1);
    expect(find.text('Modellstart wurde abgebrochen'), findsOneWidget);
    expect(api.createdSessions, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('choose another model drops the old locked bot session', (
    tester,
  ) async {
    final api = _FakeChatApi(
      engineInstances: [_engineInstance(state: 'ready')],
      bots: const [
        {'id': 'scout', 'name': 'Scout', 'is_default': true},
        {
          'id': 'bound-bot',
          'name': 'Gebundener Bot',
          'keywords': <String>[],
          'model_binding': {
            'kind': 'local',
            'provider': 'local',
            'model_ref': 'local:local-stopped',
            'model_id': 'local-stopped',
            'instance_id': 'local-stopped',
            'display_name': 'Lokales Modell',
          },
        },
      ],
      firstStreamEvents: const [
        ScoutStreamEvent(
          type: 'bot_selected',
          data: {'id': 'bound-bot', 'name': 'Gebundener Bot'},
        ),
        ScoutStreamEvent(
          type: 'error',
          data: {
            'code': 'model_binding_missing',
            'message': 'Gebundenes Modell fehlt',
          },
        ),
      ],
    );
    final appState = AppState.test(api);
    appState.setPreferredBotId('bound-bot');
    await _pumpChat(tester, api, appState);

    expect(api.lastCreatedBotId, 'bound-bot');
    expect(appState.currentChatSessionId, isNotNull);

    await tester.enterText(find.byType(TextField).last, 'Fehler auslösen');
    await tester.pump();
    _pressIconButton(tester, const Key('chat-send-button'));
    await _pumpUntil(
      tester,
      () => find.text('Anderes Modell wählen').evaluate().isNotEmpty,
    );
    expect(find.text('Anderes Modell wählen'), findsOneWidget);

    expect(find.text('Bindung ändern'), findsOneWidget);
    final chooseAnother = tester.widget<TextButton>(
      find.ancestor(
        of: find.text('Anderes Modell wählen'),
        matching: find.byType(TextButton),
      ),
    );
    expect(chooseAnother.onPressed, isNotNull);
    chooseAnother.onPressed!.call();
    await tester.pump();
    expect(appState.currentChatSessionId, isNull);
    expect(
      tester
          .widget<IconButton>(find.byKey(const Key('chat-send-button')))
          .onPressed,
      isNull,
    );
    expect(appState.chatModelPicker!.selectedKey, isNull);
  });
}

void _pressIconButton(WidgetTester tester, Key key) {
  final button = tester.widget<IconButton>(find.byKey(key));
  expect(
    button.onPressed,
    isNotNull,
    reason:
        'tooltip=${button.tooltip}; composer='
        '${tester.widget<TextField>(find.byType(TextField).last).controller?.text}',
  );
  button.onPressed!.call();
}

Future<void> _pumpChat(
  WidgetTester tester,
  _FakeChatApi api,
  AppState appState,
) async {
  tester.view.physicalSize = const Size(1200, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.dark(useMaterial3: true),
      home: Scaffold(
        body: ScoutTab(api: api, appState: appState),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(api.createdSessions, 1);
}

Future<void> _pumpUntil(WidgetTester tester, bool Function() condition) async {
  for (var i = 0; i < 30 && !condition(); i++) {
    await tester.pump(const Duration(milliseconds: 10));
  }
  expect(condition(), isTrue);
}

Future<void> _pumpFrames(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
}

class _FakeChatApi extends ApiService {
  _FakeChatApi({
    this.engineInstances = const [],
    this.bots = const [
      {'id': 'scout', 'name': 'Scout', 'is_default': true},
    ],
    this.firstStreamEvents = const [],
    this.streamBeforeGate = const [],
    this.streamAfterGate = const [],
    this.streamGate,
    this.ensureGate,
  }) : super.test();

  final List<EngineInstance> engineInstances;
  final List<Map<String, dynamic>> bots;
  final List<ScoutStreamEvent> firstStreamEvents;
  final List<ScoutStreamEvent> streamBeforeGate;
  final List<ScoutStreamEvent> streamAfterGate;
  final Completer<void>? streamGate;
  final Completer<void>? ensureGate;
  final Map<String, String?> lockedBotBySession = {};

  late final ScoutApi _scout = _FakeScoutApi(this);
  late final MarketplaceApi _marketplace = _FakeMarketplaceApi(this);

  @override
  ScoutApi get scout => _scout;

  @override
  MarketplaceApi get marketplace => _marketplace;

  int createdSessions = 0;
  int streamCalls = 0;
  int ensureCalls = 0;
  int cancelCalls = 0;
  String? lastCreatedBotId;

  @override
  Future<List<EngineInstance>> getEngineInstances() async => engineInstances;

  @override
  Stream<EngineStreamEvent> streamEngineEvents() =>
      const Stream<EngineStreamEvent>.empty();

  @override
  Future<EngineEnsureReadyResult> ensureEngineInstanceReady(
    String instanceId,
  ) async {
    ensureCalls++;
    if (ensureGate != null) await ensureGate!.future;
    return EngineEnsureReadyResult(
      operationId: 'op-delayed',
      status: 'queued',
      queuePosition: 1,
      instance: _engineInstance(state: 'stopped'),
    );
  }

  @override
  Future<EngineOperation> cancelEngineOperation(String operationId) async {
    cancelCalls++;
    return EngineOperation(
      id: operationId,
      type: 'start',
      state: 'cancelled',
      instanceId: 'local-stopped',
      progress: 1,
      message: null,
      error: null,
      phase: 'cancelled',
    );
  }
}

class _FakeScoutApi extends ScoutApi {
  _FakeScoutApi(this._fake) : super(_fake.client);

  final _FakeChatApi _fake;

  @override
  Future<Map<String, dynamic>> getBots() async => {'bots': _fake.bots};

  @override
  Future<Map<String, dynamic>> createSession({
    String? modelRef,
    String? provider,
    String? modelId,
    String? instanceId,
    String? thinkingLevel,
    String? responseStyle,
    String? botId,
    String? projectId,
    String? connectionId,
  }) async {
    _fake.createdSessions++;
    _fake.lastCreatedBotId = botId;
    final sessionId = 'session-$_fake.createdSessions';
    _fake.lockedBotBySession[sessionId] = botId;
    return {
      'session_id': sessionId,
      'provider': provider ?? 'openrouter',
      'model_id': modelId ?? 'test/model',
      'model_ref': modelRef ?? 'openrouter:test/model',
      'display_name': instanceId == null ? 'Cloudmodell' : 'Lokales Modell',
      'instance_id': ?instanceId,
      'locked_bot_id': ?botId,
    };
  }

  @override
  Future<Map<String, dynamic>> getHistory(String sessionId) async => {
    'session_id': sessionId,
    'provider': 'openrouter',
    'model_id': 'test/model',
    'model_ref': 'openrouter:test/model',
    'display_name': 'Cloudmodell',
    if (_fake.lockedBotBySession[sessionId] != null)
      'locked_bot_id': _fake.lockedBotBySession[sessionId],
    'messages': <Object>[],
  };

  @override
  Stream<ScoutStreamEvent> streamMessage(
    String sessionId,
    String message, {
    String? thinkingLevel,
    String? responseStyle,
    int? editMessageIndex,
    String? mode,
    List<String>? allowedRoots,
    bool? approvePlan,
    bool? planning,
    String? reasoningEffort,
    String? outputLevel,
  }) async* {
    _fake.streamCalls++;
    if (_fake.streamCalls == 1 && _fake.firstStreamEvents.isNotEmpty) {
      yield* Stream.fromIterable(_fake.firstStreamEvents);
      return;
    }
    yield* Stream.fromIterable(_fake.streamBeforeGate);
    if (_fake.streamGate != null) await _fake.streamGate!.future;
    yield* Stream.fromIterable(_fake.streamAfterGate);
  }
}

class _FakeMarketplaceApi extends MarketplaceApi {
  _FakeMarketplaceApi(_FakeChatApi fake) : super(fake.client);

  @override
  Future<Map<String, dynamic>> listActiveAPIModels() async => {
    'models': [
      {
        'provider': 'openrouter',
        'model_id': 'test/model',
        'display_name': 'Cloudmodell',
        'model_ref': 'openrouter:test/model',
      },
    ],
  };
}

EngineInstance _engineInstance({required String state}) {
  return EngineInstance.fromJson({
    'id': 'local-stopped',
    'state': state,
    'phase': state,
    'progress': state == 'ready' ? 1 : 0,
    'model_id': 'catalog-model',
    'served_model_name': 'Lokales Modell',
    'show_in_chat_picker': true,
    'placement': 'gpu',
    'requested_config': const <String, dynamic>{},
    'effective_config': const <String, dynamic>{},
  });
}
