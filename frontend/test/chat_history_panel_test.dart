import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myphilostudio/services/api_service.dart';
import 'package:myphilostudio/state/app_state.dart';
import 'package:myphilostudio/screens/chat/chat_history_panel.dart';

/// Baut einen AppState mit zwei Ordnern und drei Chats (einer zugeordnet).
/// Die API zeigt ins Leere; Fehler der Fire-and-forget-Calls werden in
/// ApiService/AppState geschluckt.
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
}) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 420,
        child: ChatHistoryPanel(
          appState: state,
          currentChatId: currentChatId,
          expandedProjects: expanded ?? <String>{},
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

    // Ordner und freie Chats sind sichtbar, der zugeordnete Chat nicht.
    expect(find.text('Arbeit'), findsOneWidget);
    expect(find.text('Privat'), findsOneWidget);
    expect(find.text('PROJEKTE'), findsOneWidget);
    expect(find.text('Freier Chat'), findsOneWidget);
    expect(find.text('Ordner-Chat'), findsNothing);

    // Aufklappen des Ordners zeigt den Chat darin.
    await tester.tap(find.text('Arbeit'));
    await tester.pumpAndSettle();
    expect(expanded, contains('proj-1'));
    expect(find.text('Ordner-Chat'), findsOneWidget);

    // Erneutes Tippen klappt wieder zu.
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

    // Titel steht im Dialog (die Panel-Zeile heisst ebenfalls "Neuer Ordner").
    expect(find.text('Neuer Ordner'), findsWidgets);
    expect(find.text('FARBE'), findsOneWidget);
    expect(find.text('Erstellen'), findsOneWidget);

    await tester.tap(find.text('Abbrechen'));
    await tester.pumpAndSettle();
    expect(find.text('Erstellen'), findsNothing);
    expect(find.text('Neuer Ordner'), findsOneWidget); // nur die Panel-Zeile
  });

  testWidgets('Neuer Chat im Ordner meldet die Projekt-ID', (tester) async {
    final state = buildTestState();
    final harness = Harness();
    await tester.pumpWidget(buildPanel(state, harness));

    // Der Button liegt in einer Hover-Reveal-Row und ist ohne Hover
    // transparent; fuer den Test direkt antippen.
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

    // Beide Ordner werden im Menue angeboten.
    expect(find.text('Arbeit'), findsWidgets);
    expect(find.text('Privat'), findsWidgets);

    // Gezielt den Menue-Eintrag (nicht die Ordner-Zeile) antippen.
    await tester.tap(find.widgetWithText(PopupMenuItem<String>, 'Privat'));
    await tester.pumpAndSettle();

    expect(state.projectIdForSession('chat-3'), 'proj-2');
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
