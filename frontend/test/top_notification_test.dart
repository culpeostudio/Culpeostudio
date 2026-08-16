import 'package:culpeo_studio/core/top_notification.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pumps a screen whose only job is to raise one notification on demand.
Future<void> pumpHost(
  WidgetTester tester,
  void Function(BuildContext context) show,
) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () => show(context),
              child: const Text('auslösen'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('auslösen'));
  await tester.pumpAndSettle();
}

void main() {
  // The card used to sit under an IgnorePointer(ignoring: true), which aborts
  // the hit test before it reaches any of the buttons. Nothing inside was
  // clickable, so this covers the whole card, not just one control.
  testWidgets('the card reacts to taps', (tester) async {
    var acted = false;
    await pumpHost(
      tester,
      (context) => showTopNotification(
        context,
        'Fehler beim Start',
        actionLabel: 'Einstellungen',
        onAction: () => acted = true,
      ),
    );

    expect(find.text('Fehler beim Start'), findsOneWidget);
    await tester.tap(find.text('Einstellungen'));
    await tester.pumpAndSettle();

    expect(acted, isTrue);
    expect(find.text('Fehler beim Start'), findsNothing);
  });

  testWidgets('closing dismisses the card', (tester) async {
    await pumpHost(
      tester,
      (context) => showTopNotification(context, 'Nur eine Meldung'),
    );

    expect(find.text('Nur eine Meldung'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Nur eine Meldung'), findsNothing);
  });

  testWidgets('several recovery actions each report their own tap', (
    tester,
  ) async {
    final tapped = <String>[];
    await pumpHost(
      tester,
      (context) => showTopNotification(
        context,
        'Modell konnte nicht gestartet werden',
        actions: [
          TopNotificationAction(
            label: 'Erneut versuchen',
            onPressed: () => tapped.add('retry'),
            primary: true,
          ),
          TopNotificationAction(
            label: 'Anderes Modell wählen',
            onPressed: () => tapped.add('other'),
          ),
          TopNotificationAction(
            label: 'Bindung ändern',
            onPressed: () => tapped.add('binding'),
          ),
        ],
      ),
    );

    expect(find.text('Erneut versuchen'), findsOneWidget);
    expect(find.text('Anderes Modell wählen'), findsOneWidget);
    expect(find.text('Bindung ändern'), findsOneWidget);

    await tester.tap(find.text('Anderes Modell wählen'));
    await tester.pumpAndSettle();
    expect(tapped, ['other']);
  });

  // Replacing a visible notification removed its entry directly while the
  // first card still owned a dismiss timer, so the timer removed the same
  // entry a second time and tripped an assertion.
  testWidgets('a second notification replaces the first one cleanly', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: () =>
                        showTopNotification(context, 'erste Meldung'),
                    child: const Text('erste'),
                  ),
                  ElevatedButton(
                    onPressed: () =>
                        showTopNotification(context, 'zweite Meldung'),
                    child: const Text('zweite'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('erste'));
    await tester.pump();
    await tester.tap(find.text('zweite'));
    await tester.pumpAndSettle();

    expect(find.text('erste Meldung'), findsNothing);
    expect(find.text('zweite Meldung'), findsOneWidget);

    // Outlives both dismiss timers: the first card's timer must not remove an
    // entry the replacement already took away.
    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();
    expect(find.text('zweite Meldung'), findsNothing);
  });
}
