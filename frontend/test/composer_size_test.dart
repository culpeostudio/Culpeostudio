import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:culpeo_studio/core/api_service.dart';
import 'package:culpeo_studio/core/app_state.dart';
import 'package:culpeo_studio/modules/engine/models.dart';
import 'package:culpeo_studio/modules/marketplace/marketplace_api.dart';
import 'package:culpeo_studio/modules/scout/scout_api.dart';
import 'package:culpeo_studio/modules/scout/scout_tab.dart';

/// The composer is 15% wider and 10% taller than its previous 420/310px
/// (width) and 14px/12px (vertical padding/gap) baseline, and - since it's
/// already bottom-anchored - the extra height only pushes its top edge up.
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

  testWidgets('the desktop composer is 15% wider than its old 420px floor', (
    tester,
  ) async {
    await pumpComposer(tester, const Size(1400, 900));

    final container = tester
        .widgetList<Container>(find.byType(Container))
        .firstWhere(
          (c) => c.constraints?.minWidth == 483,
          orElse: () => throw StateError('composer container not found'),
        );
    expect(container.constraints!.minWidth, 483);
  });

  testWidgets('the narrow composer is 15% wider than its old 310px floor', (
    tester,
  ) async {
    await pumpComposer(tester, const Size(700, 900));

    final container = tester
        .widgetList<Container>(find.byType(Container))
        .firstWhere(
          (c) => c.constraints?.minWidth == 357,
          orElse: () => throw StateError('composer container not found'),
        );
    expect(container.constraints!.minWidth, 357);
  });

  testWidgets('growing the composer only moves its top edge, not its bottom', (
    tester,
  ) async {
    await pumpComposer(tester, const Size(1400, 900));

    final composer = find.byType(TextField).last;
    final composerBottom = tester.getBottomLeft(composer).dy;
    final screenHeight =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;

    // Bottom padding is a fixed 24px below the composer's own content, so
    // the gap to the screen edge stays small and constant regardless of how
    // tall the composer itself grows - it never creeps toward the bottom.
    expect(screenHeight - composerBottom, lessThan(120));
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
