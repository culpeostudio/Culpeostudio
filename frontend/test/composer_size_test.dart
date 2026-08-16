import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:culpeo_studio/core/api_service.dart';
import 'package:culpeo_studio/core/app_state.dart';
import 'package:culpeo_studio/modules/engine/models.dart';
import 'package:culpeo_studio/modules/marketplace/marketplace_api.dart';
import 'package:culpeo_studio/modules/scout/scout_api.dart';
import 'package:culpeo_studio/modules/scout/scout_tab.dart';

/// The composer is a quarter larger than its previous 483/357px (width) and
/// 14/15px (padding) baseline, and - since it's already bottom-anchored - the
/// extra height only pushes its top edge up.
void main() {
  Future<void> pumpComposer(WidgetTester tester, Size viewport) async {
    tester.view.physicalSize = viewport;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final api = _FakeChatApi();
    final appState = AppState.test(api);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: Scaffold(
          body: ScoutTab(api: api, appState: appState),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the desktop composer is a quarter wider than its 483px floor', (
    tester,
  ) async {
    await pumpComposer(tester, const Size(1400, 900));

    final container = tester
        .widgetList<Container>(find.byType(Container))
        .firstWhere(
          (c) => c.constraints?.minWidth == 604,
          orElse: () => throw StateError('composer container not found'),
        );
    expect(container.constraints!.minWidth, 604);
  });

  testWidgets('the narrow composer is a quarter wider than its 357px floor', (
    tester,
  ) async {
    await pumpComposer(tester, const Size(700, 900));

    final container = tester
        .widgetList<Container>(find.byType(Container))
        .firstWhere(
          (c) => c.constraints?.minWidth == 446,
          orElse: () => throw StateError('composer container not found'),
        );
    expect(container.constraints!.minWidth, 446);
  });

  testWidgets('the composer text is a quarter larger than its 13px baseline', (
    tester,
  ) async {
    await pumpComposer(tester, const Size(1400, 900));

    final field = tester.widget<TextField>(
      find.byKey(const Key('chat-composer')),
    );
    expect(field.style?.fontSize, 16);
  });

  testWidgets('growing the composer only moves its top edge, not its bottom', (
    tester,
  ) async {
    await pumpComposer(tester, const Size(1400, 900));

    final sendBottom = tester
        .getBottomLeft(find.byKey(const Key('chat-send-button')))
        .dy;
    final screenHeight =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;

    // Below the last control there is only the composer's own 19px padding,
    // the fixed 24px inset and the 10px under it. The gap to the screen edge
    // is that sum and nothing else, however tall the composer itself grows.
    expect(screenHeight - sendBottom, closeTo(19 + 24 + 10, 1));
  });
}

class _FakeChatApi extends ApiService {
  _FakeChatApi() : super.test();

  late final ScoutApi _scout = _FakeScoutApi(this);
  late final MarketplaceApi _marketplace = _FakeMarketplaceApi(this);

  @override
  ScoutApi get scout => _scout;

  @override
  MarketplaceApi get marketplace => _marketplace;

  int createdSessions = 0;

  @override
  Future<List<EngineInstance>> getEngineInstances() async => const [];

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
    String? connectionId,
  }) async {
    _fake.createdSessions++;
    return {
      'session_id': 'session-${_fake.createdSessions}',
      'provider': provider ?? 'openrouter',
      'model_id': modelId ?? 'test/model',
      'model_ref': modelRef ?? 'openrouter:test/model',
      'display_name': 'Cloudmodell',
    };
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
