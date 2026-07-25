import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myphilostudio/state/app_state.dart';
import 'package:myphilostudio/engine/models.dart';
import 'package:myphilostudio/screens/chat/chat_model_picker.dart';

void main() {
  test('local chat choices include only ready instances with stable ids', () {
    final choices = buildChatModelChoices(
      cloudModels: [
        ActiveApiModel(
          provider: 'openrouter',
          modelId: 'cloud/model',
          displayName: 'Cloud Modell',
          modelRef: 'openrouter:cloud/model',
        ),
      ],
      engineInstances: [
        _instance(id: 'ready-instance', state: 'ready', name: 'Mein Modell'),
        _instance(id: 'starting-instance', state: 'starting'),
        _instance(id: 'failed-instance', state: 'failed'),
      ],
    );

    expect(choices, hasLength(2));
    final local = choices.singleWhere((choice) => choice.isLocal);
    expect(local.stableKey, 'local:ready-instance');
    expect(local.modelRef, 'local:ready-instance');
    expect(local.provider, 'local');
    expect(local.modelId, 'ready-instance');
    expect(local.instanceId, 'ready-instance');
    expect(local.subtitle, 'Lokal • Bereit');
  });

  test('includes a remembered stopped instance with planned placement', () {
    final choices = buildChatModelChoices(
      cloudModels: const [],
      engineInstances: [
        _instance(
          id: 'sleeping-instance',
          state: 'stopped',
          name: 'Schlafendes Modell',
          showInChatPicker: true,
          placement: 'hybrid',
        ),
        _instance(id: 'hidden-instance', state: 'stopped'),
      ],
    );

    expect(choices, hasLength(1));
    expect(choices.single.requiresWarmup, isTrue);
    expect(choices.single.selectable, isTrue);
    expect(choices.single.placementLabel, 'Geplant: GPU + RAM');
    expect(
      choices.single.subtitle,
      'Lokal • Ausgeschaltet – startet bei Auswahl',
    );
  });

  test('stopped current session stays visible but cannot be selected', () {
    final current = chatModelChoiceFromSessionMetadata(const {
      'session': {
        'model_ref': 'local:stopped-instance',
        'provider': 'local',
        'model_id': 'stopped-instance',
        'instance_id': 'stopped-instance',
        'display_name': 'Bisheriger lokaler Chat',
      },
    }, const []);

    expect(current?.stableKey, 'local:stopped-instance');
    expect(current?.label, 'Bisheriger lokaler Chat');
    expect(current?.subtitle, 'Lokal • Derzeit nicht bereit');
    expect(current?.selectable, isFalse);
  });

  testWidgets('picker clearly selects a ready local model', (tester) async {
    final cloud = ChatModelChoice.cloud(
      ActiveApiModel(
        provider: 'openrouter',
        modelId: 'cloud/model',
        displayName: 'Cloud Modell',
        modelRef: 'openrouter:cloud/model',
      ),
    );
    final local = ChatModelChoice.local(
      _instance(id: 'local-instance', state: 'ready', name: 'Lokales Modell'),
    );
    ChatModelChoice? selected;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: Center(
            child: ChatModelPicker(
              selected: cloud,
              choices: [cloud, local],
              onSelected: (choice) => selected = choice,
              onRefreshLocalModels: () {},
              onOpenEngine: () {},
              onManageCloudModels: () {},
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('chat-model-picker')));
    await tester.pumpAndSettle();

    expect(find.text('LOKALE MODELLE'), findsNothing);
    expect(find.text('Lokal • Bereit'), findsOneWidget);
    await tester.tap(
      find.byKey(const Key('chat-model-choice-local:local-instance')),
    );
    await tester.pumpAndSettle();

    expect(selected?.instanceId, 'local-instance');
    expect(selected?.provider, 'local');
  });

  testWidgets('picker explains when no model is available', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: Center(
            child: ChatModelPicker(
              selected: null,
              choices: const [],
              onSelected: (_) {},
              onRefreshLocalModels: () {},
              onOpenEngine: () {},
              onManageCloudModels: () {},
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('chat-model-picker')));
    await tester.pumpAndSettle();

    expect(find.text('Noch kein Modell verfügbar'), findsOneWidget);
  });

  testWidgets('picker is disabled when Agentic uses Philox', (tester) async {
    final local = ChatModelChoice.local(
      _instance(id: 'local-instance', state: 'ready', name: 'Lokales Modell'),
    );
    var selected = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: Center(
            child: ChatModelPicker(
              selected: local,
              choices: [local],
              enabled: false,
              disabledReason: 'Agentic verwendet Philox',
              onSelected: (_) => selected = true,
              onRefreshLocalModels: () {},
              onOpenEngine: () {},
              onManageCloudModels: () {},
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('chat-model-picker')));
    await tester.pumpAndSettle();
    expect(find.text('LOKALE MODELLE'), findsNothing);
    expect(selected, isFalse);
    expect(find.text('Agentic verwendet Philox'), findsNothing);
  });

  testWidgets('uses a wide bottom sheet below 600px', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final local = ChatModelChoice.local(
      _instance(
        id: 'sleeping',
        state: 'stopped',
        name: 'Lokales Modell',
        showInChatPicker: true,
      ),
    );
    ChatModelChoice? selected;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: ChatModelPicker(
            selected: null,
            choices: [local],
            onSelected: (choice) => selected = choice,
            onRefreshLocalModels: () {},
            onOpenEngine: () {},
            onManageCloudModels: () {},
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('chat-model-picker')));
    await tester.pumpAndSettle();
    expect(find.text('Chat-Modell auswählen'), findsOneWidget);
    expect(
      find.byKey(const Key('chat-model-sheet-choice-local:sleeping')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const Key('chat-model-sheet-choice-local:sleeping')),
    );
    await tester.pumpAndSettle();
    expect(selected?.instanceId, 'sleeping');
  });
}

EngineInstance _instance({
  required String id,
  required String state,
  String name = '',
  bool showInChatPicker = false,
  String placement = 'unknown',
}) {
  return EngineInstance.fromJson({
    'id': id,
    'state': state,
    'model_id': 'catalog-model',
    'served_model_name': name,
    'show_in_chat_picker': showInChatPicker,
    'placement': placement,
    'requested_config': const <String, dynamic>{},
    'effective_config': const <String, dynamic>{},
  });
}
