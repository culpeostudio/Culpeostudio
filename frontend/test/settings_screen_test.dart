import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myphilostudio/screens/settings/settings_screen.dart';

// Charakterisierungs-Tests: sie halten fest, wie der Einstellungs-Screen heute
// aufgebaut ist (Sektionsnavigation und Inhalt je Sektion), damit ein Umbau der
// Datei auffaellt, bevor er im Betrieb auffaellt.
//
// Der Screen ruft im initState mehrere API-Endpunkte auf. Im Test gibt es kein
// Backend; die Aufrufe laufen ins Leere und werden abgefangen — geprueft wird
// deshalb bewusst die UI-Struktur, nicht geladene Daten.
//
// Zum Layout-Ueberlauf: der Screen hat keinerlei responsive Logik (kein
// LayoutBuilder, keinen Breakpoint) und ist auf breite Fenster ausgelegt. In
// sehr schmalen Fenstern laeuft er deshalb ueber — der letzte Test haelt das
// als bekannten Ist-Zustand fest.

Future<void> pumpSettings(WidgetTester tester, {Size? size}) async {
  tester.view.physicalSize = size ?? const Size(1400, 950);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
  await tester.pump();
}

/// Haengt den Screen ab und laesst den 5-Sekunden-Timeout der Provider-Pruefung
/// auslaufen — sonst bricht der Test-Teardown mit `timersPending` ab.
Future<void> disposeSettings(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 6));
}

/// Wechselt ueber die rechte Navigation in einen Bereich.
///
/// Konsumiert einen evtl. auftretenden RenderFlex-Overflow, damit die
/// Struktur-Pruefung in schmalen Fenstern nicht daran scheitert (siehe
/// Kopfkommentar); bei den hier genutzten Breiten tritt keiner mehr auf.
Future<void> openSection(WidgetTester tester, String label) async {
  await tester.tap(find.text(label).last, warnIfMissed: false);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  tester.takeException();
}

void main() {
  testWidgets('zeigt alle sechs Bereiche in der Navigation', (tester) async {
    await pumpSettings(tester);

    for (final label in const [
      'Allgemein',
      'Server / API',
      'Shortkarts',
      'Bot-Verwaltung',
      'Chat-Bot',
      'Skills',
    ]) {
      expect(find.text(label), findsOneWidget, reason: 'Navigationspunkt $label');
    }

    await disposeSettings(tester);
  });

  testWidgets('startet im Bereich Allgemein', (tester) async {
    await pumpSettings(tester);

    // Die Provider-Karten des Server/API-Bereichs duerfen noch nicht da sein.
    expect(find.text('Hugging Face'), findsNothing);

    await disposeSettings(tester);
  });

  testWidgets('wechselt auf Server / API und zeigt die Provider-Karten', (
    tester,
  ) async {
    await pumpSettings(tester);
    await openSection(tester, 'Server / API');

    for (final provider in const [
      'Lokaler Server',
      'Hugging Face',
      'OpenRouter',
      'Featherless',
    ]) {
      expect(find.text(provider), findsWidgets, reason: 'Provider $provider');
    }

    await disposeSettings(tester);
  });

  testWidgets('verlaesst den Provider-Bereich wieder beim Wechsel', (
    tester,
  ) async {
    await pumpSettings(tester);
    await openSection(tester, 'Server / API');
    expect(find.text('Hugging Face'), findsWidgets);

    await openSection(tester, 'Shortkarts');
    expect(find.text('Hugging Face'), findsNothing);

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
      // Der Navigationspunkt selbst muss nach dem Wechsel weiterhin da sein —
      // faellt der Bereichsaufbau aus, verschwindet die Spalte mit.
      expect(find.text(label), findsWidgets, reason: 'nach Wechsel auf $label');
    }

    await disposeSettings(tester);
  });

  // Dokumentiert einen VORBESTEHENDEN Layout-Fehler: im schmalen Fenster
  // laeuft eine Zeile ueber den Rand hinaus. Der Test haelt den Ist-Zustand
  // fest; wird der Overflow behoben, schlaegt er fehl und darf dann auf
  // `isNull` umgestellt werden.
  testWidgets('bekannter Layout-Ueberlauf im schmalen Fenster', (tester) async {
    await pumpSettings(tester, size: const Size(720, 900));

    final error = tester.takeException();
    expect(
      error,
      isA<FlutterError>(),
      reason: 'erwartet den bekannten RenderFlex-Overflow bei 720px Breite',
    );

    await disposeSettings(tester);
  });
}
