import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:culpeo_studio/modules/spark/plan_checklist.dart';

/// The worklist Spark works off after a plan is approved: every step is on
/// screen from the start and the rows change state as the run reports back.
/// These cover what a row shows in each of those states.
void main() {
  testWidgets('folded it names the step it is at, opened the whole list', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(
        steps: const [
          {'number': 1, 'title': 'Config lesen', 'status': 'done'},
          {'number': 2, 'title': 'Timeout setzen', 'status': 'running'},
          {'number': 3, 'title': 'Build pruefen', 'status': 'pending'},
        ],
      ),
    );

    // Folded: the running step carries the line, the rest stays out of the way.
    expect(find.text('Timeout setzen'), findsOneWidget);
    expect(find.text('Config lesen'), findsNothing);
    expect(find.text('Build pruefen'), findsNothing);

    await _open(tester);

    expect(find.text('Config lesen'), findsOneWidget);
    expect(find.text('Timeout setzen'), findsOneWidget);
    expect(find.text('Build pruefen'), findsOneWidget);
  });

  testWidgets('the running step is the one with the spinner', (tester) async {
    await tester.pumpWidget(
      _harness(
        steps: const [
          {'number': 1, 'title': 'Erst', 'status': 'done', 'result': 'gelesen'},
          {'number': 2, 'title': 'Dann', 'status': 'running'},
        ],
      ),
    );

    await _open(tester);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.text('gelesen'), findsOneWidget);
  });

  testWidgets('a step left over after a failure reads as never started', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(
        running: false,
        steps: const [
          {
            'number': 1,
            'title': 'Erst',
            'status': 'failed',
            'result': 'Fehler: Zeit abgelaufen',
          },
          {'number': 2, 'title': 'Dann', 'status': 'pending'},
        ],
      ),
    );

    await _open(tester);

    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    expect(find.text('Fehler: Zeit abgelaufen'), findsOneWidget);
    expect(find.text('offen geblieben'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('a stopped run offers to keep going, a finished one does not', (
    tester,
  ) async {
    var resumed = 0;
    await tester.pumpWidget(
      _harness(
        running: false,
        onResume: () => resumed++,
        steps: const [
          {'number': 1, 'title': 'Erst', 'status': 'done'},
          {'number': 2, 'title': 'Dann', 'status': 'pending'},
        ],
      ),
    );

    expect(find.text('noch 1 offen'), findsOneWidget);
    await tester.tap(find.text('Weiterarbeiten'));
    await tester.pump();
    expect(resumed, 1);

    await tester.pumpWidget(
      _harness(
        running: false,
        onResume: () => resumed++,
        steps: const [
          {'number': 1, 'title': 'Erst', 'status': 'done'},
          {'number': 2, 'title': 'Dann', 'status': 'done'},
        ],
      ),
    );
    expect(find.text('Weiterarbeiten'), findsNothing);
  });

  testWidgets('a running plan hides the buttons', (tester) async {
    await tester.pumpWidget(
      _harness(
        onResume: () {},
        onDiscard: () {},
        steps: const [
          {'number': 1, 'title': 'Erst', 'status': 'running'},
        ],
      ),
    );

    expect(find.text('Weiterarbeiten'), findsNothing);
    expect(find.text('Plan verwerfen'), findsNothing);
  });

  testWidgets('the header counts the run, then what came of it', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(
        steps: const [
          {'number': 1, 'title': 'Erst', 'status': 'done'},
          {'number': 2, 'title': 'Dann', 'status': 'running'},
        ],
      ),
    );
    expect(find.text('Schritt 2 von 2'), findsOneWidget);

    await tester.pumpWidget(
      _harness(
        running: false,
        steps: const [
          {'number': 1, 'title': 'Erst', 'status': 'done'},
          {'number': 2, 'title': 'Dann', 'status': 'done'},
        ],
      ),
    );
    expect(find.text('2 von 2 erledigt'), findsOneWidget);
  });
}

/// The list is folded down by default, so anything about its rows needs it
/// opened first.
Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('plan-checklist-header')));
  // Not pumpAndSettle: a running step spins forever, so the frame budget has
  // to be spent by hand.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 250));
}

Widget _harness({
  required List<Map<String, dynamic>> steps,
  String summary = 'Kurz und knapp',
  bool running = true,
  VoidCallback? onResume,
  VoidCallback? onDiscard,
}) {
  return MaterialApp(
    home: Scaffold(
      backgroundColor: const Color(0xFF0F0F14),
      body: PlanChecklist(
        summary: summary,
        steps: steps,
        running: running,
        onResume: onResume,
        onDiscard: onDiscard,
      ),
    ),
  );
}
