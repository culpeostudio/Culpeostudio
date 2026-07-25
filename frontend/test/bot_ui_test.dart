import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myphilostudio/state/app_state.dart';
import 'package:myphilostudio/engine/models.dart';
import 'package:myphilostudio/screens/bots/bot_management_screen.dart';
import 'package:myphilostudio/screens/chat/bot_picker.dart';
import 'package:myphilostudio/screens/chat/chat_model_picker.dart';

void main() {
  const binding = BotModelBinding(
    kind: 'local',
    modelRef: 'local:local-1',
    provider: 'local',
    modelId: 'local-1',
    instanceId: 'local-1',
    displayName: 'Lokales Modell',
  );
  const bots = [
    PhiloBotChoice(id: 'philobot', name: 'PhiloBot', isDefault: true),
    PhiloBotChoice(id: 'kant', name: 'Kant-Bot', modelBinding: binding),
  ];

  testWidgets('narrow bot picker uses sheet and selects an explicit bot', (
    tester,
  ) async {
    await _setViewport(tester, const Size(390, 800));
    String? selected;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: BotPicker(
            bots: bots,
            selectedBotId: null,
            onSelected: (value) => selected = value,
          ),
        ),
      ),
    );

    expect(find.text('Automatisch'), findsOneWidget);
    await tester.tap(find.byKey(const Key('bot-picker')));
    await tester.pumpAndSettle();
    expect(find.text('Bot auswählen'), findsOneWidget);
    expect(find.text('Fest verbunden: Lokales Modell'), findsOneWidget);
    await tester.tap(find.byKey(const Key('bot-sheet-choice-kant')));
    await tester.pumpAndSettle();
    expect(selected, 'kant');
  });

  testWidgets('wide chat uses popup even when the picker itself is narrow', (
    tester,
  ) async {
    await _setViewport(tester, const Size(1000, 800));
    String? selected;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 420,
              child: BotPicker(
                bots: bots,
                selectedBotId: null,
                useBottomSheet: false,
                onSelected: (value) => selected = value,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(PopupMenuButton<String>), findsOneWidget);
    await tester.tap(find.byKey(const Key('bot-picker')));
    await tester.pumpAndSettle();
    expect(find.text('Bot auswählen'), findsNothing);
    await tester.tap(find.byKey(const Key('bot-choice-kant')));
    await tester.pumpAndSettle();
    expect(selected, 'kant');
  });

  testWidgets('bot management stacks below 760 and uses binding sheet', (
    tester,
  ) async {
    await _setViewport(tester, const Size(390, 844));
    await tester.pumpWidget(_managementApp());
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('bot-management-stacked-layout')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('bot-model-binding-sheet-trigger')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('bot management switches to two columns at 760', (tester) async {
    await _setViewport(tester, const Size(760, 900));
    await tester.pumpWidget(_managementApp());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('bot-management-wide-layout')), findsOneWidget);
    expect(
      find.byKey(const Key('bot-management-stacked-layout')),
      findsNothing,
    );
    expect(find.byKey(const Key('bot-model-binding-dropdown')), findsOneWidget);
    expect(
      find.byKey(const Key('bot-model-binding-sheet-trigger')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('700px stacks management but keeps desktop dropdown menus', (
    tester,
  ) async {
    await _setViewport(tester, const Size(700, 900));
    await tester.pumpWidget(_managementApp());
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('bot-management-stacked-layout')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('bot-model-binding-dropdown')), findsOneWidget);
    expect(
      find.byKey(const Key('bot-model-binding-sheet-trigger')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('wide bot management exposes local and API model binding', (
    tester,
  ) async {
    await _setViewport(tester, const Size(1100, 900));
    await tester.pumpWidget(_managementApp());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('bot-model-binding-dropdown')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Widget _managementApp() {
  final local = ChatModelChoice.local(
    EngineInstance.fromJson(const {
      'id': 'local-1',
      'state': 'stopped',
      'model_id': 'catalog-1',
      'served_model_name': 'Lokales Modell',
      'show_in_chat_picker': true,
      'placement': 'gpu',
      'requested_config': <String, dynamic>{},
      'effective_config': <String, dynamic>{},
    }),
  );
  final cloud = ChatModelChoice.cloud(
    ActiveApiModel(
      provider: 'openrouter',
      modelId: 'cloud/model',
      displayName: 'Cloud Modell',
      modelRef: 'openrouter:cloud/model',
    ),
  );
  return MaterialApp(
    theme: ThemeData.dark(useMaterial3: true),
    home: BotManagementScreen(
      loadRemoteData: false,
      initialBots: const [
        {
          'id': 'philobot',
          'name': 'PhiloBot',
          'is_default': true,
          'system_prompt': 'Hilf freundlich.',
          'keywords': <String>[],
        },
      ],
      initialModelChoices: [local, cloud],
    ),
  );
}

Future<void> _setViewport(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}
