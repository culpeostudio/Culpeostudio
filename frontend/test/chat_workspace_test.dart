import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:culpeo_studio/core/api_service.dart';
import 'package:culpeo_studio/core/app_state.dart';
import 'package:culpeo_studio/modules/engine/models.dart';
import 'package:culpeo_studio/modules/marketplace/marketplace_api.dart';
import 'package:culpeo_studio/modules/scout/chat_tabs_strings.dart';
import 'package:culpeo_studio/modules/scout/chat_workspace.dart';
import 'package:culpeo_studio/modules/scout/scout_api.dart';

void main() {
  testWidgets('opens, focuses and closes independent chat panes', (
    tester,
  ) async {
    final api = _WorkspaceApi();
    final appState = _seededState(api);
    await _pumpWorkspace(tester, api, appState);

    // In the default one-chat view the workspace controls live in Scout's
    // existing title bar, so its original surface and vertical rhythm remain.
    expect(find.byKey(const Key('chat-workspace-menu')), findsOneWidget);
    expect(find.byKey(const Key('chat-workspace-add')), findsNothing);

    await _selectSplitLayout(tester);
    expect(find.byKey(const Key('chat-pane-chat-a')), findsOneWidget);
    expect(find.byKey(const Key('chat-pane-empty-1')), findsOneWidget);

    await tester.tap(find.byKey(const Key('chat-workspace-add')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(PopupMenuItem<String>, 'Chat B'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('chat-pane-chat-a')), findsOneWidget);
    expect(find.byKey(const Key('chat-pane-chat-b')), findsOneWidget);
    expect(find.byKey(const Key('chat-composer-chat-a')), findsOneWidget);
    expect(find.byKey(const Key('chat-composer-chat-b')), findsOneWidget);
    expect(appState.currentChatSessionId, 'chat-b');

    await tester.tap(find.byKey(const Key('chat-pane-chat-a')));
    await tester.pumpAndSettle();
    expect(appState.currentChatSessionId, 'chat-a');

    final semantics = tester.ensureSemantics();
    expect(
      tester
          .getSemantics(find.byKey(const Key('chat-pane-chat-a')))
          .getSemanticsData()
          .flagsCollection
          .isSelected
          .toBoolOrNull(),
      isTrue,
    );
    semantics.dispose();

    await tester.tap(find.byKey(const Key('chat-pane-close-chat-a')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chat-pane-chat-a')), findsNothing);
    expect(find.byKey(const Key('chat-pane-chat-b')), findsOneWidget);
    expect(appState.currentChatSessionId, 'chat-b');
    expect(tester.takeException(), isNull);
  });

  testWidgets('different panes keep concurrent streams and composers active', (
    tester,
  ) async {
    final api = _WorkspaceApi();
    final appState = _seededState(api);
    await _pumpWorkspace(tester, api, appState);
    await _openSplitPanes(tester);

    await tester.enterText(
      find.byKey(const Key('chat-composer-chat-a')),
      'Nachricht A',
    );
    await tester.pump();
    _pressSend(tester, 'chat-a');
    await _pumpUntil(tester, () => api.streamSessions.contains('chat-a'));
    expect(api.streamSessions, ['chat-a']);

    await tester.enterText(
      find.byKey(const Key('chat-composer-chat-b')),
      'Nachricht B',
    );
    await tester.pump();
    final sendB = tester.widget<IconButton>(
      find.byKey(const Key('chat-send-button-chat-b')),
    );
    expect(sendB.onPressed, isNotNull);
    _pressSend(tester, 'chat-b');
    await _pumpUntil(tester, () => api.streamSessions.contains('chat-b'));
    expect(api.streamSessions, ['chat-a', 'chat-b']);

    api.emit('chat-a', 'Antwort A');
    api.emit('chat-b', 'Antwort B');
    await tester.pump(const Duration(milliseconds: 60));

    expect(
      find.descendant(
        of: find.byKey(const Key('chat-pane-chat-a')),
        matching: find.textContaining('Antwort A'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('chat-pane-chat-b')),
        matching: find.textContaining('Antwort B'),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('falls back to one usable pane when the workspace is narrow', (
    tester,
  ) async {
    final api = _WorkspaceApi();
    final appState = _seededState(api);
    await _pumpWorkspace(tester, api, appState, viewport: const Size(820, 900));
    await _openSplitPanes(tester);

    expect(find.byKey(const Key('chat-pane-chat-a')), findsNothing);
    expect(find.byKey(const Key('chat-pane-chat-b')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('routes a new-chat action to the focused pane only', (
    tester,
  ) async {
    final api = _WorkspaceApi();
    final appState = _seededState(api);
    await _pumpWorkspace(tester, api, appState);
    await _openSplitPanes(tester);

    // Chat B was the most recently opened and is therefore the workspace
    // focus. The broadcast action must create exactly one pane, not one per
    // mounted ScoutTab.
    appState.triggerAction('new_chat_session');
    await _pumpUntil(tester, () => api.createdSessions == 1);
    await tester.pumpAndSettle();

    expect(api.createdSessions, 1);
    expect(appState.currentChatSessionId, 'chat-new-1');
    expect(find.byKey(const Key('chat-pane-chat-new-1')), findsOneWidget);
    expect(find.byKey(const Key('chat-pane-chat-b')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('starts a new chat from the styled workspace menu', (
    tester,
  ) async {
    final api = _WorkspaceApi();
    final appState = _seededState(api);
    await _pumpWorkspace(tester, api, appState);

    await tester.tap(find.byKey(const Key('chat-workspace-menu')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('chat-workspace-new')), findsOneWidget);
    expect(find.text(chatTabsText('scout.multiChat.newHint')), findsOneWidget);

    await tester.tap(find.byKey(const Key('chat-workspace-new')));
    await _pumpUntil(tester, () => api.createdSessions == 1);
    await tester.pumpAndSettle();

    expect(appState.currentChatSessionId, 'chat-new-1');
    expect(find.byKey(const Key('chat-pane-chat-new-1')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('multi-pane toolbar also starts a new chat directly', (
    tester,
  ) async {
    final api = _WorkspaceApi();
    final appState = _seededState(api);
    await _pumpWorkspace(tester, api, appState);
    await _selectSplitLayout(tester);

    await tester.tap(find.byKey(const Key('chat-workspace-add')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('chat-workspace-new')));
    await _pumpUntil(tester, () => api.createdSessions == 1);
    await tester.pumpAndSettle();

    expect(appState.currentChatSessionId, 'chat-new-1');
    expect(find.byKey(const Key('chat-pane-chat-new-1')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the focused pane receives a model change independently', (
    tester,
  ) async {
    final api = _WorkspaceApi();
    final appState = _seededState(api);
    await _pumpWorkspace(tester, api, appState);
    await _openSplitPanes(tester);

    // Both sessions initially show the same model. This is the important
    // regression case: a visually equal sidebar snapshot must still replace
    // its callback when focus moves from Chat B back to Chat A.
    expect(
      appState.chatModelPicker?.selectedKey,
      'cloud:openrouter:test/model',
    );
    await tester.tap(find.byKey(const Key('chat-pane-chat-a')));
    await tester.pumpAndSettle();

    appState.chatModelPicker!.onSelect('cloud:openrouter:alternate/model');
    await tester.pumpAndSettle();

    expect(api.modelSwitchSessions, ['chat-a']);
    expect(
      appState.chatModelPicker?.selectedKey,
      'cloud:openrouter:alternate/model',
    );

    await tester.tap(find.byKey(const Key('chat-pane-chat-b')));
    await tester.pumpAndSettle();
    expect(
      appState.chatModelPicker?.selectedKey,
      'cloud:openrouter:test/model',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('asks which open chat the model sidebar should control', (
    tester,
  ) async {
    final api = _WorkspaceApi();
    final appState = _seededState(api);
    await _pumpWorkspace(tester, api, appState);
    await _openSplitPanes(tester);

    // The left sidebar requests a target before it changes a model. Chat B is
    // focused right now, but A remains an equally explicit choice.
    appState.requestChatModelTargetSelection();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('chat-model-target-dialog')), findsOneWidget);
    expect(find.byKey(const Key('chat-model-target-chat-a')), findsOneWidget);
    expect(find.byKey(const Key('chat-model-target-chat-b')), findsOneWidget);
    expect(
      find.text(chatTabsText('scout.multiChat.modelTarget.body')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('chat-model-target-chat-a')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('chat-model-target-dialog')), findsNothing);
    expect(appState.currentChatSessionId, 'chat-a');

    // After choosing A, the normal sidebar callback is scoped to A; no extra
    // model controls need to exist in the chat headers.
    appState.chatModelPicker!.onSelect('cloud:openrouter:alternate/model');
    await tester.pumpAndSettle();
    expect(api.modelSwitchSessions, ['chat-a']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps the model sidebar direct with one open chat pane', (
    tester,
  ) async {
    final api = _WorkspaceApi();
    final appState = _seededState(api);
    await _pumpWorkspace(tester, api, appState);

    // Chat B exists in the history but is not open in the workspace. The
    // target chooser must therefore stay out of the single-chat flow.
    appState.requestChatModelTargetSelection();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('chat-model-target-dialog')), findsNothing);
    expect(appState.currentChatSessionId, 'chat-a');
    expect(tester.takeException(), isNull);
  });

  testWidgets('swaps chat pane positions when Chat A is dragged onto Chat B', (
    tester,
  ) async {
    final api = _WorkspaceApi();
    final appState = _seededState(api);
    await _pumpWorkspace(tester, api, appState);
    await _openSplitPanes(tester);

    // The workspace initially inserts B in the first split position. A drag
    // from A onto B must exchange their positions while retaining A's local
    // composer state and making the picked-up chat the focused chat.
    await tester.enterText(
      find.byKey(const Key('chat-composer-chat-a')),
      'Entwurf von Chat A',
    );
    await tester.pump();

    final paneA = find.byKey(const Key('chat-pane-chat-a'));
    final paneB = find.byKey(const Key('chat-pane-chat-b'));
    expect(
      tester.getTopLeft(paneA).dx,
      greaterThan(tester.getTopLeft(paneB).dx),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const Key('chat-pane-drag-chat-a'))),
    );
    await gesture.moveTo(tester.getCenter(paneB));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(paneA).dx, lessThan(tester.getTopLeft(paneB).dx));
    expect(appState.currentChatSessionId, 'chat-a');
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('chat-composer-chat-a')))
          .controller!
          .text,
      'Entwurf von Chat A',
    );
    expect(tester.takeException(), isNull);
  });
}

AppState _seededState(_WorkspaceApi api) {
  final state = AppState.test(api);
  state.chatSessions.addAll(['chat-a', 'chat-b']);
  state.sessionTitles.addAll({'chat-a': 'Chat A', 'chat-b': 'Chat B'});
  state.currentChatSessionId = 'chat-a';
  return state;
}

Future<void> _pumpWorkspace(
  WidgetTester tester,
  _WorkspaceApi api,
  AppState appState, {
  Size viewport = const Size(1400, 900),
}) async {
  tester.view.physicalSize = viewport;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(api.dispose);
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.dark(useMaterial3: true),
      home: Scaffold(
        body: ChatWorkspace(api: api, appState: appState),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _openSplitPanes(WidgetTester tester) async {
  await _selectSplitLayout(tester);
  final addButton = find.byKey(const Key('chat-workspace-add'));
  await tester.tap(
    addButton.evaluate().isNotEmpty
        ? addButton
        : find.byKey(const Key('chat-workspace-menu')),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(PopupMenuItem<String>, 'Chat B'));
  await tester.pumpAndSettle();
}

Future<void> _selectSplitLayout(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('chat-workspace-menu')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('chat-workspace-layout-option-split')));
  await tester.pumpAndSettle();
}

void _pressSend(WidgetTester tester, String sessionId) {
  final composer = tester.widget<TextField>(
    find.byKey(Key('chat-composer-$sessionId')),
  );
  final button = tester.widget<IconButton>(
    find.byKey(Key('chat-send-button-$sessionId')),
  );
  expect(
    button.onPressed,
    isNotNull,
    reason: 'text=${composer.controller?.text}; tooltip=${button.tooltip}',
  );
  button.onPressed!.call();
}

Future<void> _pumpUntil(WidgetTester tester, bool Function() condition) async {
  for (var i = 0; i < 30 && !condition(); i++) {
    await tester.pump(const Duration(milliseconds: 10));
  }
  expect(condition(), isTrue);
}

class _WorkspaceApi extends ApiService {
  _WorkspaceApi() : super.test();

  late final ScoutApi _scout = _WorkspaceScoutApi(this);
  late final MarketplaceApi _marketplace = _WorkspaceMarketplaceApi(this);
  final Map<String, StreamController<ScoutStreamEvent>> _streams = {};
  final List<String> streamSessions = [];
  final List<String> modelSwitchSessions = [];
  int createdSessions = 0;

  @override
  ScoutApi get scout => _scout;

  @override
  MarketplaceApi get marketplace => _marketplace;

  @override
  Future<List<EngineInstance>> getEngineInstances() async => const [];

  @override
  Stream<EngineStreamEvent> streamEngineEvents() =>
      const Stream<EngineStreamEvent>.empty();

  Stream<ScoutStreamEvent> streamFor(String sessionId) {
    streamSessions.add(sessionId);
    return _streams
        .putIfAbsent(
          sessionId,
          () => StreamController<ScoutStreamEvent>.broadcast(),
        )
        .stream;
  }

  void emit(String sessionId, String text) {
    _streams[sessionId]?.add(
      ScoutStreamEvent(type: 'text_delta', data: {'chunk': text}),
    );
  }

  Future<void> dispose() async {
    for (final stream in _streams.values) {
      await stream.close();
    }
  }
}

class _WorkspaceScoutApi extends ScoutApi {
  _WorkspaceScoutApi(this._api) : super(_api.client);

  final _WorkspaceApi _api;

  @override
  Future<Map<String, dynamic>> getBots() async => {
    'bots': [
      {'id': 'scout', 'name': 'Scout', 'is_default': true},
    ],
  };

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
    _api.createdSessions++;
    return {
      'session_id': 'chat-new-${_api.createdSessions}',
      'provider': provider ?? 'openrouter',
      'model_id': modelId ?? 'test/model',
      'model_ref': modelRef ?? 'openrouter:test/model',
      'display_name': 'Cloudmodell',
    };
  }

  @override
  Future<Map<String, dynamic>> getHistory(String sessionId) async => {
    'session_id': sessionId,
    'provider': 'openrouter',
    'model_id': 'test/model',
    'model_ref': 'openrouter:test/model',
    'display_name': 'Cloudmodell',
    'messages': [
      {'role': 'assistant', 'content': 'Verlauf $sessionId'},
    ],
  };

  @override
  Future<Map<String, dynamic>> setSessionModel(
    String sessionId, {
    required String provider,
    required String modelId,
    String? modelRef,
    String? displayName,
    String? connectionId,
  }) async {
    _api.modelSwitchSessions.add(sessionId);
    return {'status': 'ok'};
  }

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
  }) => _api.streamFor(sessionId);
}

class _WorkspaceMarketplaceApi extends MarketplaceApi {
  _WorkspaceMarketplaceApi(_WorkspaceApi api) : super(api.client);

  @override
  Future<Map<String, dynamic>> listActiveAPIModels() async => {
    'models': [
      {
        'provider': 'openrouter',
        'model_id': 'test/model',
        'display_name': 'Cloudmodell',
        'model_ref': 'openrouter:test/model',
      },
      {
        'provider': 'openrouter',
        'model_id': 'alternate/model',
        'display_name': 'Alternatives Modell',
        'model_ref': 'openrouter:alternate/model',
      },
    ],
  };
}
