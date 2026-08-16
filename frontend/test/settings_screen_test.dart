import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:culpeo_studio/modules/settings/settings_screen.dart';

Future<void> pumpSettings(WidgetTester tester, {Size? size}) async {
  tester.view.physicalSize = size ?? const Size(1400, 950);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
  await tester.pump();
  // Let the calls the screen fires while mounting give up, so it renders its
  // real state rather than the loading placeholder.
  await tester.pump(const Duration(milliseconds: 10));
}

Future<void> disposeSettings(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 6));
}

Future<void> openSection(WidgetTester tester, String label) async {
  await tester.tap(find.text(label).last, warnIfMissed: false);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  expect(
    tester.takeException(),
    isNull,
    reason: 'Bereich "$label" darf keinen Layout-Fehler werfen',
  );
}

void main() {
  testWidgets('zeigt jeden Bereich in der Navigation', (tester) async {
    await pumpSettings(tester);

    for (final label in const [
      'Allgemein',
      'Server / API',
      'Shortkarts',
      'Bot-Verwaltung',
      'Chat-Bot',
      'Skills',
      'Nodes',
    ]) {
      expect(
        // Scoped to the navigation itself: the window header repeats the
        // active section as a breadcrumb, so the label legitimately appears
        // twice on screen.
        find.descendant(
          of: find.byKey(const PageStorageKey('settings-left-navigation')),
          matching: find.text(label),
        ),
        findsOneWidget,
        reason: 'Navigationspunkt $label',
      );
    }

    await disposeSettings(tester);
  });

  testWidgets('startet im Bereich Allgemein', (tester) async {
    await pumpSettings(tester);

    expect(find.text('Hugging Face'), findsNothing);

    await disposeSettings(tester);
  });

  testWidgets(
    'wechselt auf Server / API und zeigt die sichere Provider-Verwaltung',
    (tester) async {
      await pumpSettings(tester);
      await openSection(tester, 'Server / API');

      expect(find.text('KI-Anbieter & API-Modelle'), findsOneWidget);
      expect(find.text('Hugging Face'), findsNothing);

      await disposeSettings(tester);
    },
  );

  testWidgets('verlaesst den Provider-Bereich wieder beim Wechsel', (
    tester,
  ) async {
    await pumpSettings(tester);
    await openSection(tester, 'Server / API');
    expect(find.text('KI-Anbieter & API-Modelle'), findsOneWidget);

    await openSection(tester, 'Shortkarts');
    expect(find.text('KI-Anbieter & API-Modelle'), findsNothing);

    await disposeSettings(tester);
  });

  testWidgets('zeigt keinen Theme-Kurzbefehl mehr', (tester) async {
    await pumpSettings(tester);
    await openSection(tester, 'Shortkarts');

    expect(find.text('Theme umschalten'), findsNothing);

    await disposeSettings(tester);
  });

  testWidgets('baut jeden Bereich ohne Absturz auf', (tester) async {
    await pumpSettings(tester);

    for (final label in const [
      'Server / API',
      'Shortkarts',
      'Bot-Verwaltung',
      'Chat-Bot',
      'Skills',
      'Allgemein',
    ]) {
      await openSection(tester, label);

      expect(find.text(label), findsWidgets, reason: 'nach Wechsel auf $label');
    }

    await disposeSettings(tester);
  });

  testWidgets(
    'zeigt im Chat-Bot-Bereich einen Empty-State statt Endlos-Spinner',
    (tester) async {
      await pumpSettings(tester);
      await openSection(tester, 'Chat-Bot');

      expect(
        find.text(
          'Keine Bots verfügbar. Erstelle zuerst einen Bot in der Bot-Verwaltung.',
        ),
        findsOneWidget,
      );
      expect(find.text('Bot-Verwaltung öffnen'), findsOneWidget);

      // Der Verweis springt in die Bot-Verwaltung.
      await tester.tap(find.text('Bot-Verwaltung öffnen'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
      expect(
        find.byKey(const Key('bot-management-wide-layout')),
        findsOneWidget,
      );

      await disposeSettings(tester);
    },
  );

  testWidgets(
    'baut die Server/API-Verwaltung im schmalen Fenster ohne Ueberlauf auf',
    (tester) async {
      await pumpSettings(tester, size: const Size(720, 900));
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Server / API').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('KI-Anbieter & API-Modelle'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await disposeSettings(tester);
    },
  );
}
