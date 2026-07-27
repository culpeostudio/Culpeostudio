import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myphilostudio/services/api_service.dart';
import 'package:myphilostudio/state/app_state.dart';
import 'package:myphilostudio/engine/models.dart';
import 'package:myphilostudio/screens/chat/chat_model_picker.dart';
import 'package:myphilostudio/screens/chat/model_warmup.dart';
import 'package:myphilostudio/screens/chat/philobot_tab.dart';

void main() {
  testWidgets(
    'active stream locks restart and ignores callbacks after session switch',
    (tester) async {
      final streamGate = Completer<void>();
      final api = _FakeChatApi(
        streamGate: streamGate,
        streamBeforeGate: const [
          PhiloBotStreamEvent(type: 'status', data: {'action': 'starting'}),
        ],
        streamAfterGate: const [
          PhiloBotStreamEvent(
            type: 'text_delta',
            data: {'chunk': 'STALE_OLD_RESPONSE'},
          ),
          PhiloBotStreamEvent(type: 'done', data: {}),
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

  testWidgets('a fast double retry starts only one additional SSE request', (
    tester,
  ) async {
    final retryGate = Completer<void>();
    final api = _FakeChatApi(
      firstStreamEvents: const [
        PhiloBotStreamEvent(
          type: 'error',
          data: {
            'code': 'model_binding_missing',
            'message': 'Gebundenes Modell fehlt',
          },
        ),
      ],
      streamGate: retryGate,
      streamAfterGate: const [PhiloBotStreamEvent(type: 'done', data: {})],
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

    await tester.tap(find.byKey(const Key('chat-model-picker')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('chat-model-choice-local:local-stopped')),
    );
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
        {'id': 'philobot', 'name': 'PhiloBot', 'is_default': true},
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
        PhiloBotStreamEvent(
          type: 'bot_selected',
          data: {'id': 'bound-bot', 'name': 'Gebundener Bot'},
        ),
        PhiloBotStreamEvent(
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
    expect(
      tester.widget<ChatModelPicker>(find.byType(ChatModelPicker)).selected,
      isNull,
    );
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
        body: PhiloBotTab(api: api, appState: appState),
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
      {'id': 'philobot', 'name': 'PhiloBot', 'is_default': true},
    ],
    this.firstStreamEvents = const [],
    this.streamBeforeGate = const [],
    this.streamAfterGate = const [],
    this.streamGate,
    this.ensureGate,
  }) : super.test();

  final List<EngineInstance> engineInstances;
  final List<Map<String, dynamic>> bots;
  final List<PhiloBotStreamEvent> firstStreamEvents;
  final List<PhiloBotStreamEvent> streamBeforeGate;
  final List<PhiloBotStreamEvent> streamAfterGate;
  final Completer<void>? streamGate;
  final Completer<void>? ensureGate;
  final Map<String, String?> _lockedBotBySession = {};

  int createdSessions = 0;
  int streamCalls = 0;
  int ensureCalls = 0;
  int cancelCalls = 0;
  String? lastCreatedBotId;

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

  @override
  Future<Map<String, dynamic>> getPhiloBots() async => {'bots': bots};

  @override
  Future<List<EngineInstance>> getEngineInstances() async => engineInstances;

  @override
  Future<Map<String, dynamic>> createPhiloBotSession({
    String? modelRef,
    String? provider,
    String? modelId,
    String? instanceId,
    String? thinkingLevel,
    String? responseStyle,
    String? botId,
    String? projectId,
  }) async {
    createdSessions++;
    lastCreatedBotId = botId;
    final sessionId = 'session-$createdSessions';
    _lockedBotBySession[sessionId] = botId;
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
  Future<Map<String, dynamic>> getPhiloBotHistory(String sessionId) async => {
    'session_id': sessionId,
    'provider': 'openrouter',
    'model_id': 'test/model',
    'model_ref': 'openrouter:test/model',
    'display_name': 'Cloudmodell',
    if (_lockedBotBySession[sessionId] != null)
      'locked_bot_id': _lockedBotBySession[sessionId],
    'messages': <Object>[],
  };

  @override
  Stream<PhiloBotStreamEvent> streamPhiloBotMessage(
    String sessionId,
    String message, {
    String? thinkingLevel,
    String? responseStyle,
    int? editMessageIndex,
    String? mode,
    List<String>? allowedRoots,
    bool? approvePlan,
    bool? planning,
  }) async* {
    streamCalls++;
    if (streamCalls == 1 && firstStreamEvents.isNotEmpty) {
      yield* Stream.fromIterable(firstStreamEvents);
      return;
    }
    yield* Stream.fromIterable(streamBeforeGate);
    if (streamGate != null) await streamGate!.future;
    yield* Stream.fromIterable(streamAfterGate);
  }

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
