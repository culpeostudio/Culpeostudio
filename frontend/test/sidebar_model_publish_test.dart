import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:culpeo_studio/core/api_service.dart';
import 'package:culpeo_studio/core/app_state.dart';
import 'package:culpeo_studio/modules/engine/models.dart';
import 'package:culpeo_studio/modules/scout/scout_api.dart';
import 'package:culpeo_studio/modules/scout/scout_tab.dart';
import 'package:culpeo_studio/modules/marketplace/marketplace_api.dart';

/// Proves the wiring the sidebar's model panel depends on: the running chat
/// session (ScoutTab) mirrors its model list into [AppState.chatModelPicker],
/// that mirror only actually notifies when something the sidebar would show
/// changed (not on every composer keystroke), and driving the mirrored
/// [ChatModelPickerState.onSelect] callback really switches the session's
/// model - the sidebar never touches ScoutTab directly, so if this callback
/// is wired wrong the sidebar would look interactive but do nothing.
void main() {
  testWidgets('publishes the session model list and selection', (tester) async {
    final api = _FakeChatApi(
      engineInstances: [_readyInstance('local-ready', 'Lokales Modell')],
    );
    final appState = AppState.test(api);
    await _pumpChat(tester, api, appState);

    final published = appState.chatModelPicker;
    expect(published, isNotNull);
    expect(published!.entries.map((e) => e.stableKey), [
      'cloud:openrouter:test/model',
      'local:local-ready',
    ]);
    expect(published.selectedKey, 'cloud:openrouter:test/model');
    expect(published.loading, isFalse);
    expect(published.locked, isFalse);
    expect(published.warmupActive, isFalse);
  });

  testWidgets('typing in the composer does not republish the picker', (
    tester,
  ) async {
    final api = _FakeChatApi(
      engineInstances: [_readyInstance('local-ready', 'Lokales Modell')],
    );
    final appState = AppState.test(api);
    await _pumpChat(tester, api, appState);

    var notifications = 0;
    appState.addListener(() => notifications++);

    await tester.enterText(find.byType(TextField).last, 'Hallo Welt');
    await tester.pump();

    expect(
      notifications,
      0,
      reason:
          'a keystroke setStates on ScoutTab but must not rebuild the '
          'sidebar - the model list, selection and warmup state did not '
          'change',
    );
  });

  testWidgets('selecting a model through the published callback switches it', (
    tester,
  ) async {
    final api = _FakeChatApi(
      engineInstances: [_readyInstance('local-ready', 'Lokales Modell')],
    );
    final appState = AppState.test(api);
    await _pumpChat(tester, api, appState);

    expect(
      appState.chatModelPicker!.selectedKey,
      'cloud:openrouter:test/model',
    );

    appState.chatModelPicker!.onSelect('local:local-ready');
    await tester.pumpAndSettle();

    expect(appState.chatModelPicker!.selectedKey, 'local:local-ready');
    expect(api.setModelCalls, 1);
  });
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

EngineInstance _readyInstance(String id, String name) {
  return EngineInstance.fromJson({
    'id': id,
    'state': 'ready',
    'phase': 'ready',
    'progress': 1,
    'model_id': 'catalog-model',
    'served_model_name': name,
    'show_in_chat_picker': true,
    'placement': 'gpu',
    'requested_config': const <String, dynamic>{},
    'effective_config': const <String, dynamic>{},
  });
}

class _FakeChatApi extends ApiService {
  _FakeChatApi({this.engineInstances = const []}) : super.test();

  final List<EngineInstance> engineInstances;

  late final ScoutApi _scout = _FakeScoutApi(this);
  late final MarketplaceApi _marketplace = _FakeMarketplaceApi(this);

  @override
  ScoutApi get scout => _scout;

  @override
  MarketplaceApi get marketplace => _marketplace;

  int createdSessions = 0;
  int setModelCalls = 0;
  String? currentSessionId;

  @override
  Future<List<EngineInstance>> getEngineInstances() async => engineInstances;

  @override
  Stream<EngineStreamEvent> streamEngineEvents() =>
      const Stream<EngineStreamEvent>.empty();
}

class _FakeScoutApi extends ScoutApi {
  _FakeScoutApi(this._fake) : super(_fake.client);

  final _FakeChatApi _fake;

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
  }) async {
    _fake.createdSessions++;
    final sessionId = 'session-${_fake.createdSessions}';
    _fake.currentSessionId = sessionId;
    return {
      'session_id': sessionId,
      'provider': provider ?? 'openrouter',
      'model_id': modelId ?? 'test/model',
      'model_ref': modelRef ?? 'openrouter:test/model',
      'display_name': instanceId == null ? 'Cloudmodell' : 'Lokales Modell',
      'instance_id': ?instanceId,
    };
  }

  @override
  Future<Map<String, dynamic>> setSessionModel(
    String sessionId, {
    required String provider,
    required String modelId,
    String? modelRef,
    String? displayName,
  }) async {
    _fake.setModelCalls++;
    return {
      'status': 'ok',
      'session': {
        'session_id': sessionId,
        'provider': provider,
        'model_id': modelId,
        'model_ref': modelRef ?? '',
      },
    };
  }

  @override
  Future<Map<String, dynamic>> getHistory(String sessionId) async => {
    'session_id': sessionId,
    'provider': 'openrouter',
    'model_id': 'test/model',
    'model_ref': 'openrouter:test/model',
    'display_name': 'Cloudmodell',
    'messages': <Object>[],
  };
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
