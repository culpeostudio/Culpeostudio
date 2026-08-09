import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:culpeo_studio/core/api_service.dart';
import 'package:culpeo_studio/core/app_state.dart';
import 'package:culpeo_studio/core/design_tokens.dart';
import 'package:culpeo_studio/modules/scout/chat_history_panel.dart';

AppState buildTestState() {
  final api = ApiService();
  api.baseUrl = 'http://127.0.0.1:1/api';
  final state = AppState.test(api);
  state.chatProjects.addAll([
    ChatProject(id: 'proj-1', name: 'Arbeit', color: '#6E8FE0'),
    ChatProject(id: 'proj-2', name: 'Privat'),
  ]);
  state.chatSessions.addAll(['chat-1', 'chat-2', 'chat-3']);
  state.sessionTitles.addAll({
    'chat-1': 'Erster Chat',
    'chat-2': 'Ordner-Chat',
    'chat-3': 'Freier Chat',
  });
  state.sessionProjects['chat-2'] = 'proj-1';
  return state;
}

class Harness {
  final List<String> selected = [];
  final List<String?> newChatProjects = [];
}

Widget buildPanel(
  AppState state,
  Harness harness, {
  String? currentChatId,
  Set<String>? expanded,
  Set<String>? expandedSubfolders,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 420,
        child: ChatHistoryPanel(
          appState: state,
          currentChatId: currentChatId,
          expandedProjects: expanded ?? <String>{},
          expandedSubfolders: expandedSubfolders ?? <String>{},
          onNewChatInProject: (pid) => harness.newChatProjects.add(pid),
          onSelectChat: harness.selected.add,
          onRenameChat: (_) {},
          onDeleteChat: (_) {},
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('zeigt Ordner und freie Chats; Ordner-Chats klappen auf', (
    tester,
  ) async {
    final state = buildTestState();
    final harness = Harness();
    final expanded = <String>{};
    await tester.pumpWidget(buildPanel(state, harness, expanded: expanded));

    expect(find.text('Arbeit'), findsOneWidget);
    expect(find.text('Privat'), findsOneWidget);
    expect(find.text('PROJEKTE'), findsOneWidget);
    expect(find.text('Freier Chat'), findsOneWidget);
    expect(find.text('Ordner-Chat'), findsNothing);

    await tester.tap(find.text('Arbeit'));
    await tester.pumpAndSettle();
    expect(expanded, contains('proj-1'));
    expect(find.text('Ordner-Chat'), findsOneWidget);

    await tester.tap(find.text('Arbeit'));
    await tester.pumpAndSettle();
    expect(expanded, isNot(contains('proj-1')));
  });

  testWidgets('Chat-Auswahl meldet onSelectChat', (tester) async {
    final state = buildTestState();
    final harness = Harness();
    await tester.pumpWidget(buildPanel(state, harness));

    await tester.tap(find.text('Freier Chat'));
    expect(harness.selected, ['chat-3']);
  });

  testWidgets('Neuer-Ordner-Dialog zeigt Name und Farbauswahl', (tester) async {
    final state = buildTestState();
    final harness = Harness();
    await tester.pumpWidget(buildPanel(state, harness));

    await tester.tap(find.byKey(const Key('chat-history-panel-new-project')));
    await tester.pumpAndSettle();

    expect(find.text('Neuer Ordner'), findsWidgets);
    expect(find.text('FARBE'), findsOneWidget);
    expect(find.text('Erstellen'), findsOneWidget);

    await tester.tap(find.text('Abbrechen'));
    await tester.pumpAndSettle();
    expect(find.text('Erstellen'), findsNothing);
    expect(find.text('Neuer Ordner'), findsOneWidget);
  });

  testWidgets('Neuer Chat im Ordner meldet die Projekt-ID', (tester) async {
    final state = buildTestState();
    final harness = Harness();
    await tester.pumpWidget(buildPanel(state, harness));

    await tester.tap(
      find.byTooltip('Neuer Chat im Ordner').first,
      warnIfMissed: false,
    );
    expect(harness.newChatProjects, ['proj-1']);
  });

  testWidgets('Verschieben-Menue ordnet einen freien Chat einem Ordner zu', (
    tester,
  ) async {
    final state = buildTestState();
    final harness = Harness();
    await tester.pumpWidget(buildPanel(state, harness));

    expect(state.projectIdForSession('chat-3'), isNull);

    await tester.tap(
      find.byKey(const Key('chat-history-move-chat-3')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(find.text('Arbeit'), findsWidgets);
    expect(find.text('Privat'), findsWidgets);

    await tester.tap(find.widgetWithText(PopupMenuItem<String>, 'Privat'));
    await tester.pumpAndSettle();

    expect(state.projectIdForSession('chat-3'), 'proj-2');
  });

  testWidgets('Ordner-Dialog benutzt die Flaechen der uebrigen Module', (
    tester,
  ) async {
    final state = buildTestState();
    final harness = Harness();
    await tester.pumpWidget(buildPanel(state, harness));

    await tester.tap(find.byKey(const Key('chat-history-panel-new-project')));
    await tester.pumpAndSettle();

    final dialog = tester.widget<AlertDialog>(find.byType(AlertDialog));
    expect(dialog.backgroundColor, CulpeoColors.panel);

    // Die Symbolliste scrollt in sich, statt den Dialog in die Laenge zu
    // ziehen - das war der Ueberlauf, den die lange Icon-Liste ausgeloest hat.
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(Scrollbar),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Ordner- und Chatsymbole stehen auf einer Linie, Pfeil rechts', (
    tester,
  ) async {
    final state = buildTestState();
    final harness = Harness();
    await tester.pumpWidget(buildPanel(state, harness));

    final projectRow = find.byKey(const Key('chat-history-project-proj-1'));
    final folderIcon = find.descendant(
      of: projectRow,
      matching: find.byIcon(Icons.folder_outlined),
    );
    final chatIcon = find.descendant(
      of: find.byKey(const Key('chat-history-chat-chat-3')),
      matching: find.byIcon(Icons.chat_bubble_outline),
    );

    expect(
      tester.getTopLeft(folderIcon).dx,
      tester.getTopLeft(chatIcon).dx,
      reason: 'Ordner und freie Chats beginnen an derselben Kante',
    );

    final chevron = find.descendant(
      of: projectRow,
      matching: find.byIcon(Icons.chevron_right),
    );
    expect(
      tester.getCenter(chevron).dx,
      greaterThan(tester.getCenter(folderIcon).dx),
      reason: 'Der Aufklapp-Pfeil sitzt am rechten Rand der Zeile',
    );
  });

  testWidgets(
    'ein neuer Unterordner im Projekt wird erstellt und ist sofort aufgeklappt',
    (tester) async {
      final state = buildTestState();
      final harness = Harness();
      final expanded = {'proj-1'};
      await tester.pumpWidget(buildPanel(state, harness, expanded: expanded));

      await tester.tap(
        find.byKey(const Key('chat-history-project-new-subfolder-proj-1')),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('chat-subfolder-name-field')),
        'Recherche',
      );
      await tester.tap(find.text('Erstellen'));
      await tester.pumpAndSettle();

      expect(state.chatSubfolders, hasLength(1));
      expect(state.chatSubfolders.single.projectId, 'proj-1');
      expect(find.text('Recherche'), findsOneWidget);
    },
  );

  testWidgets(
    'ueber das Verschieben-Menue landet ein Chat im Unterordner und wieder direkt im Projekt',
    (tester) async {
      final state = buildTestState();
      final folder = await state.createChatSubfolder('proj-1', 'Recherche');
      final harness = Harness();
      await tester.pumpWidget(
        buildPanel(
          state,
          harness,
          expanded: {'proj-1'},
          expandedSubfolders: {folder.id},
        ),
      );

      // "Ordner-Chat" (chat-2) is directly in proj-1; move it into the
      // subfolder through the same move menu used for cross-project moves.
      await tester.tap(
        find.byKey(const Key('chat-history-move-chat-2')),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(PopupMenuItem<String>, 'Recherche'));
      await tester.pumpAndSettle();

      expect(state.subfolderIdForSession('chat-2'), folder.id);
      expect(state.sessionsDirectlyInProject('proj-1'), isEmpty);

      await tester.tap(
        find.byKey(const Key('chat-history-move-chat-2')),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(PopupMenuItem<String>, 'Aus Unterordner entfernen'),
      );
      await tester.pumpAndSettle();

      expect(state.subfolderIdForSession('chat-2'), isNull);
      expect(state.sessionsDirectlyInProject('proj-1'), contains('chat-2'));
    },
  );

  testWidgets('ein Unterordner klappt seine Chats auf und wieder zu', (
    tester,
  ) async {
    final state = buildTestState();
    final folder = await state.createChatSubfolder('proj-1', 'Recherche');
    await state.assignSessionToSubfolder('chat-2', folder.id);
    final harness = Harness();
    final expanded = {'proj-1'};
    await tester.pumpWidget(buildPanel(state, harness, expanded: expanded));

    expect(find.text('Recherche'), findsOneWidget);
    expect(find.text('Ordner-Chat'), findsNothing);

    await tester.tap(find.text('Recherche'));
    await tester.pumpAndSettle();
    expect(find.text('Ordner-Chat'), findsOneWidget);

    await tester.tap(find.text('Recherche'));
    await tester.pumpAndSettle();
    expect(find.text('Ordner-Chat'), findsNothing);
  });

  testWidgets('ein geloeschter Unterordner behaelt seine Chats im Projekt', (
    tester,
  ) async {
    final state = buildTestState();
    final folder = await state.createChatSubfolder('proj-1', 'Recherche');
    await state.assignSessionToSubfolder('chat-2', folder.id);
    final harness = Harness();
    await tester.pumpWidget(
      buildPanel(
        state,
        harness,
        expanded: {'proj-1'},
        expandedSubfolders: {folder.id},
      ),
    );
    expect(find.text('Ordner-Chat'), findsOneWidget);

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer();
    addTearDown(gesture.removePointer);
    await gesture.moveTo(tester.getCenter(find.text('Recherche')));
    await tester.pump();
    await tester.tap(
      find.descendant(
        of: find.byKey(Key('chat-history-subfolder-${folder.id}')),
        matching: find.byIcon(Icons.delete_outline),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Löschen'));
    await tester.pumpAndSettle();

    expect(state.chatSubfolders, isEmpty);
    expect(find.text('Recherche'), findsNothing);
    expect(find.text('Ordner-Chat'), findsOneWidget);
  });

  testWidgets('Projekt-Chip zeigt Ordnername und Farbe', (tester) async {
    final project = ChatProject(id: 'p', name: 'Forschung', color: '#7BAE7F');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatProjectBadge(
            project: ChatProject(id: 'p', name: 'Forschung'),
          ),
        ),
      ),
    );
    expect(find.text('Forschung'), findsOneWidget);
    expect(chatProjectColor(project), const Color(0xFF7BAE7F));
    expect(chatProjectColor(null), kChatAccent);
  });
}
