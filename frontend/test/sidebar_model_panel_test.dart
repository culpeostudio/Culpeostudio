import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:culpeo_studio/core/api_service.dart';
import 'package:culpeo_studio/core/app_state.dart';
import 'package:culpeo_studio/modules/marketplace/marketplace_api.dart';
import 'package:culpeo_studio/modules/scout/sidebar_model_panel.dart';

/// Tests [SidebarModelPanel] against a directly-constructed
/// [ChatModelPickerState] plus [AppState.modelFolders], the same boundary the
/// widget itself is built to - it never talks to ScoutTab, only to whatever
/// the active session last published, and to the folders the user organised
/// cloud models into (a pre-existing AppState feature this panel now
/// surfaces inline instead of a separate management dialog).
/// `test/sidebar_model_publish_test.dart` covers the publish side of the
/// contract; this file covers rendering and the folder interactions.
void main() {
  AppState buildState() {
    final api = ApiService();
    api.baseUrl = 'http://127.0.0.1:1/api';
    return AppState.test(api);
  }

  Widget buildPanel(AppState state, {Set<String>? collapsed}) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 300,
          height: 600,
          child: SidebarModelPanel(
            appState: state,
            collapsedFolders: collapsed ?? <String>{},
          ),
        ),
      ),
    );
  }

  testWidgets('shows a placeholder when no session has published yet', (
    tester,
  ) async {
    final state = buildState();
    await tester.pumpWidget(buildPanel(state));

    expect(find.text('Öffne den Chat, um Modelle zu laden'), findsOneWidget);
  });

  testWidgets('shows the loading state while models are still coming in', (
    tester,
  ) async {
    final state = buildState();
    state.publishChatModelPicker(_pickerState(loading: true, entries: []));
    await tester.pumpWidget(buildPanel(state));

    expect(find.text('Modelle werden gesucht…'), findsOneWidget);
  });

  testWidgets('shows the backend error message', (tester) async {
    final state = buildState();
    state.publishChatModelPicker(
      _pickerState(entries: [], error: 'Engine nicht erreichbar'),
    );
    await tester.pumpWidget(buildPanel(state));

    expect(find.text('Engine nicht erreichbar'), findsOneWidget);
  });

  testWidgets('shows the locked reason instead of a model list', (
    tester,
  ) async {
    final state = buildState();
    state.modelFolders.first.modelIds.add('a');
    state.publishChatModelPicker(
      _pickerState(
        locked: true,
        lockedReason: 'Das Modell ist fest mit dem gewählten Bot verbunden',
        entries: [
          const ChatModelPickerEntry(
            stableKey: 'cloud:a',
            label: 'Modell A',
            subtitle: 'openrouter • a',
            isLocal: false,
            selectable: true,
            ready: true,
            placementLabel: '',
          ),
        ],
      ),
    );
    await tester.pumpWidget(buildPanel(state));

    expect(
      find.text('Das Modell ist fest mit dem gewählten Bot verbunden'),
      findsOneWidget,
    );
    expect(find.text('Modell A'), findsNothing);
  });

  testWidgets(
    'lists cloud entries under their folder and local ones below, marks the selection',
    (tester) async {
      final state = buildState();
      state.modelFolders.first.modelIds.add('a');
      final selections = <String>[];
      state.publishChatModelPicker(
        _pickerState(
          entries: [
            const ChatModelPickerEntry(
              stableKey: 'cloud:a',
              label: 'Cloud-Modell',
              subtitle: 'openrouter • a',
              isLocal: false,
              selectable: true,
              ready: true,
              placementLabel: '',
            ),
            const ChatModelPickerEntry(
              stableKey: 'local:b',
              label: 'Lokales Modell',
              subtitle: 'Lokal • Bereit',
              isLocal: true,
              selectable: true,
              ready: true,
              placementLabel: 'GPU',
            ),
          ],
          selectedKey: 'cloud:a',
          onSelect: selections.add,
        ),
      );
      await tester.pumpWidget(buildPanel(state));

      // The default ("API-Modelle") folder is expanded out of the box.
      expect(find.text('API-Modelle'), findsOneWidget);
      expect(find.text('Cloud-Modell'), findsOneWidget);
      expect(find.text('LOKAL'), findsOneWidget);
      expect(find.text('Lokales Modell'), findsOneWidget);
      expect(find.text('Lokal • Bereit • GPU'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);

      await tester.tap(find.text('Lokales Modell'));
      expect(selections, ['local:b']);
    },
  );

  testWidgets('collapsing a folder hides its models until expanded again', (
    tester,
  ) async {
    final state = buildState();
    state.modelFolders.first.modelIds.add('a');
    state.publishChatModelPicker(
      _pickerState(
        entries: [
          const ChatModelPickerEntry(
            stableKey: 'cloud:a',
            label: 'Cloud-Modell',
            subtitle: 'openrouter • a',
            isLocal: false,
            selectable: true,
            ready: true,
            placementLabel: '',
          ),
        ],
      ),
    );
    await tester.pumpWidget(buildPanel(state));
    expect(find.text('Cloud-Modell'), findsOneWidget);

    await tester.tap(find.text('API-Modelle'));
    await tester.pumpAndSettle();
    expect(find.text('Cloud-Modell'), findsNothing);

    await tester.tap(find.text('API-Modelle'));
    await tester.pumpAndSettle();
    expect(find.text('Cloud-Modell'), findsOneWidget);
  });

  testWidgets('an unselectable entry does not forward taps', (tester) async {
    final state = buildState();
    final selections = <String>[];
    state.publishChatModelPicker(
      _pickerState(
        entries: [
          const ChatModelPickerEntry(
            stableKey: 'local:unavailable',
            label: 'Nicht verfügbar',
            subtitle: 'Lokal • Derzeit nicht bereit',
            isLocal: true,
            selectable: false,
            ready: false,
            placementLabel: '',
          ),
        ],
        onSelect: selections.add,
      ),
    );
    await tester.pumpWidget(buildPanel(state));

    await tester.tap(find.text('Nicht verfügbar'));
    expect(selections, isEmpty);
  });

  testWidgets('shows warmup progress and forwards the cancel tap', (
    tester,
  ) async {
    final state = buildState();
    var cancelled = false;
    state.publishChatModelPicker(
      _pickerState(
        entries: [],
        warmupActive: true,
        warmupProgress: 0.42,
        warmupMessage: 'Modell wird geladen',
        onCancelWarmup: () => cancelled = true,
      ),
    );
    await tester.pumpWidget(buildPanel(state));

    expect(find.textContaining('42%'), findsOneWidget);
    await tester.tap(find.text('Abbrechen'));
    expect(cancelled, isTrue);
  });

  testWidgets('the refresh and engine actions forward their taps', (
    tester,
  ) async {
    final state = buildState();
    var refreshed = false;
    var openedEngine = false;
    state.publishChatModelPicker(
      _pickerState(
        entries: [],
        onRefresh: () => refreshed = true,
        onOpenEngine: () => openedEngine = true,
      ),
    );
    await tester.pumpWidget(buildPanel(state));

    await tester.tap(find.text('Modelle aktualisieren'));
    await tester.tap(find.text('Engine öffnen'));

    expect(refreshed, isTrue);
    expect(openedEngine, isTrue);
  });

  testWidgets('creating a folder through the dialog adds it to AppState', (
    tester,
  ) async {
    final state = buildState();
    state.modelFolders.first.modelIds.add('a');
    state.publishChatModelPicker(
      _pickerState(
        entries: [
          const ChatModelPickerEntry(
            stableKey: 'cloud:a',
            label: 'Cloud-Modell',
            subtitle: 'openrouter • a',
            isLocal: false,
            selectable: true,
            ready: true,
            placementLabel: '',
          ),
        ],
      ),
    );
    await tester.pumpWidget(buildPanel(state));

    expect(state.modelFolders, hasLength(1));
    await tester.tap(find.byKey(const Key('sidebar-model-new-folder')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('model-folder-name-field')),
      'Forschung',
    );
    await tester.tap(find.text('Erstellen'));
    await tester.pumpAndSettle();

    expect(state.modelFolders, hasLength(2));
    expect(state.modelFolders.last.name, 'Forschung');
    expect(find.text('Forschung'), findsOneWidget);
  });

  testWidgets('the general folder offers no delete action', (tester) async {
    final state = buildState();
    state.modelFolders.first.modelIds.add('a');
    state.publishChatModelPicker(
      _pickerState(
        entries: [
          const ChatModelPickerEntry(
            stableKey: 'cloud:a',
            label: 'Cloud-Modell',
            subtitle: 'openrouter • a',
            isLocal: false,
            selectable: true,
            ready: true,
            placementLabel: '',
          ),
        ],
      ),
    );
    await tester.pumpWidget(buildPanel(state));

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer();
    addTearDown(gesture.removePointer);
    await gesture.moveTo(tester.getCenter(find.text('API-Modelle')));
    await tester.pump();

    expect(find.byIcon(Icons.delete_outline), findsNothing);
    expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
  });

  testWidgets('deleting a folder keeps its models by folding them back', (
    tester,
  ) async {
    final state = buildState();
    state.createModelFolder('Archiv', const Color(0xFF62B5AB));
    final archive = state.modelFolders.last;
    state.moveModelToFolder('a', archive.id);
    state.publishChatModelPicker(
      _pickerState(
        entries: [
          const ChatModelPickerEntry(
            stableKey: 'cloud:a',
            label: 'Cloud-Modell',
            subtitle: 'openrouter • a',
            isLocal: false,
            selectable: true,
            ready: true,
            placementLabel: '',
          ),
        ],
      ),
    );
    await tester.pumpWidget(buildPanel(state));
    expect(find.text('Archiv'), findsOneWidget);

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer();
    addTearDown(gesture.removePointer);
    await gesture.moveTo(tester.getCenter(find.text('Archiv')));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Löschen'));
    await tester.pumpAndSettle();

    expect(state.modelFolders.map((f) => f.id), isNot(contains(archive.id)));
    expect(state.modelFolders.first.modelIds, contains('a'));
    expect(find.text('Cloud-Modell'), findsOneWidget);
  });

  testWidgets('moving a model to another folder updates AppState', (
    tester,
  ) async {
    final state = buildState();
    state.modelFolders.first.modelIds.add('a');
    state.createModelFolder('Archiv', const Color(0xFF62B5AB));
    final archive = state.modelFolders.last;
    state.publishChatModelPicker(
      _pickerState(
        entries: [
          const ChatModelPickerEntry(
            stableKey: 'cloud:a',
            label: 'Cloud-Modell',
            subtitle: 'openrouter • a',
            isLocal: false,
            selectable: true,
            ready: true,
            placementLabel: '',
          ),
        ],
      ),
    );
    await tester.pumpWidget(buildPanel(state));

    await tester.tap(find.byKey(const Key('sidebar-model-move-cloud:a')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Archiv').last);
    await tester.pumpAndSettle();

    expect(archive.modelIds, contains('a'));
    expect(state.modelFolders.first.modelIds, isNot(contains('a')));
  });

  /// Picking a row up is a long press here because widget tests report
  /// `TargetPlatform.android`; on desktop the same drag starts immediately.
  Future<void> dragRow(
    WidgetTester tester, {
    required Finder row,
    required Finder onto,
  }) async {
    final gesture = await tester.startGesture(tester.getCenter(row));
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 100));
    await gesture.moveTo(tester.getCenter(onto));
    await tester.pump(const Duration(milliseconds: 50));
    await gesture.up();
    await tester.pumpAndSettle();
  }

  testWidgets('dragging a model row onto another folder moves it', (
    tester,
  ) async {
    final state = buildState();
    state.modelFolders.first.modelIds.add('a');
    state.createModelFolder('Archiv', const Color(0xFF62B5AB));
    final archive = state.modelFolders.last;
    state.publishChatModelPicker(
      _pickerState(
        entries: [
          const ChatModelPickerEntry(
            stableKey: 'cloud:a',
            label: 'Cloud-Modell',
            subtitle: 'openrouter • a',
            isLocal: false,
            selectable: true,
            ready: true,
            placementLabel: '',
          ),
        ],
      ),
    );
    await tester.pumpWidget(buildPanel(state));

    await dragRow(
      tester,
      row: find.byKey(const ValueKey('sidebar-model-row-cloud:a')),
      onto: find.text('Archiv'),
    );

    expect(archive.modelIds, contains('a'));
    expect(state.modelFolders.first.modelIds, isNot(contains('a')));
  });

  testWidgets('dropping a model back onto its own folder is a no-op', (
    tester,
  ) async {
    final state = buildState();
    state.modelFolders.first.modelIds.add('a');
    state.publishChatModelPicker(
      _pickerState(
        entries: [
          const ChatModelPickerEntry(
            stableKey: 'cloud:a',
            label: 'Cloud-Modell',
            subtitle: 'openrouter • a',
            isLocal: false,
            selectable: true,
            ready: true,
            placementLabel: '',
          ),
        ],
      ),
    );
    await tester.pumpWidget(buildPanel(state));

    await dragRow(
      tester,
      row: find.byKey(const ValueKey('sidebar-model-row-cloud:a')),
      onto: find.text('API-Modelle'),
    );

    expect(state.modelFolders.first.modelIds, ['a']);
  });

  testWidgets('a local model can be dragged out of its flat section into a '
      'folder', (tester) async {
    final state = buildState();
    state.createModelFolder('Lokal', const Color(0xFF62B5AB));
    final target = state.modelFolders.last;
    state.publishChatModelPicker(
      _pickerState(
        entries: [
          const ChatModelPickerEntry(
            stableKey: 'local:instance-1',
            label: 'Engine-Modell',
            subtitle: 'llama.cpp',
            isLocal: true,
            selectable: true,
            ready: true,
            placementLabel: '',
          ),
        ],
      ),
    );
    await tester.pumpWidget(buildPanel(state));

    await dragRow(
      tester,
      row: find.byKey(const ValueKey('sidebar-model-row-local:instance-1')),
      onto: find.text('Lokal'),
    );

    // Folders key local models by their whole picker key, and the row moves
    // out of the loose section into the folder.
    expect(target.modelIds, ['local:instance-1']);
    expect(find.text('LOKAL'), findsNothing);
    expect(find.text('Engine-Modell'), findsOneWidget);
  });

  test('refreshing the cloud models leaves filed local ones alone', () async {
    final state = AppState.test(_StubApi());
    state.modelFolders.first.modelIds.addAll(['a', 'gone', 'local:instance-1']);

    await state.refreshActiveApiModels();

    // The refresh prunes cloud refs the account no longer has ('gone') and
    // leaves local ones alone - it has no list to check those against, and
    // dropping them would empty the folder on every refresh.
    expect(state.modelFolders.first.modelIds, ['a', 'local:instance-1']);
  });

  testWidgets('the drag handle sorts a model inside its own folder', (
    tester,
  ) async {
    final state = buildState();
    state.modelFolders.first.modelIds.addAll(['a', 'b']);
    state.publishChatModelPicker(
      _pickerState(
        entries: [
          for (final ref in ['a', 'b'])
            ChatModelPickerEntry(
              stableKey: 'cloud:$ref',
              label: 'Modell $ref',
              subtitle: 'openrouter • $ref',
              isLocal: false,
              selectable: true,
              ready: true,
              placementLabel: '',
            ),
        ],
      ),
    );
    await tester.pumpWidget(buildPanel(state));

    final handle = find.byKey(const Key('sidebar-model-drag-handle-cloud:a'));
    final second = find.byKey(const ValueKey('sidebar-model-row-cloud:b'));
    final drop = tester.getCenter(second).dy - tester.getCenter(handle).dy;

    final gesture = await tester.startGesture(tester.getCenter(handle));
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 100));
    // Stepped, not one jump: the list tracks the pointer frame by frame and
    // only picks a new slot once it has crossed the row below.
    for (var moved = 0.0; moved < drop + 8; moved += 10) {
      await gesture.moveBy(const Offset(0, 10));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await tester.pumpAndSettle();

    expect(state.modelFolders.first.modelIds, ['b', 'a']);
  });
}

ChatModelPickerState _pickerState({
  required List<ChatModelPickerEntry> entries,
  String? selectedKey,
  bool loading = false,
  String? error,
  bool locked = false,
  String? lockedReason,
  bool warmupActive = false,
  double warmupProgress = 0,
  String warmupMessage = '',
  ValueChanged<String>? onSelect,
  VoidCallback? onRefresh,
  VoidCallback? onOpenEngine,
  VoidCallback? onManageCloudModels,
  VoidCallback? onCancelWarmup,
}) {
  return ChatModelPickerState(
    entries: entries,
    selectedKey: selectedKey,
    loading: loading,
    error: error,
    locked: locked,
    lockedReason: lockedReason,
    warmupActive: warmupActive,
    warmupProgress: warmupProgress,
    warmupMessage: warmupMessage,
    onSelect: onSelect ?? (_) {},
    onRefresh: onRefresh ?? () {},
    onOpenEngine: onOpenEngine ?? () {},
    onManageCloudModels: onManageCloudModels ?? () {},
    onCancelWarmup: onCancelWarmup ?? () {},
  );
}

/// Just enough backend for [AppState.refreshActiveApiModels]: one cloud
/// model the account still has.
class _StubApi extends ApiService {
  _StubApi() : super.test();

  late final MarketplaceApi _marketplace = _StubMarketplaceApi(client);

  @override
  MarketplaceApi get marketplace => _marketplace;
}

class _StubMarketplaceApi extends MarketplaceApi {
  _StubMarketplaceApi(super.client);

  @override
  Future<Map<String, dynamic>> listActiveAPIModels() async => {
    'models': [
      {
        'provider': 'openrouter',
        'model_id': 'a',
        'display_name': 'Cloud-Modell',
        'model_ref': 'a',
      },
    ],
  };
}
