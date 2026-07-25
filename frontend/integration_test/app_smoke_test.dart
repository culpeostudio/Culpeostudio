import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:myphilostudio/main.dart';
import 'package:myphilostudio/services/api_service.dart';

// Durchlauf durch die echte App auf dem Linux-Desktop — im Gegensatz zu den
// Widget-Tests unter test/ laeuft hier die vollstaendige Anwendung inklusive
// echter HTTP-Aufrufe.
//
// Vorbedingung: ein Backend unter BACKEND_URL (Standard: der Testserver auf
// Port 18099, damit die echte Instanz auf 8080 unberuehrt bleibt). Zugang wird
// ueber TEST_USER/TEST_PASSWORD gesetzt.
//
// Start:
//   flutter test integration_test/app_smoke_test.dart -d linux \
//     --dart-define=BACKEND_URL=http://127.0.0.1:18099/api \
//     --dart-define=TEST_USER=alphatest --dart-define=TEST_PASSWORD=neu5678

const _backendUrl = String.fromEnvironment(
  'BACKEND_URL',
  defaultValue: 'http://127.0.0.1:18099/api',
);
const _testUser = String.fromEnvironment('TEST_USER', defaultValue: '');
const _testPassword = String.fromEnvironment('TEST_PASSWORD', defaultValue: '');

/// Wartet, bis [finder] auftaucht — statt pumpAndSettle, das bei dauerhaften
/// Animationen (Ladeanzeigen, Puls-Effekte) nie zur Ruhe kommt.
Future<bool> waitFor(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 20),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 200));
    if (finder.evaluate().isNotEmpty) return true;
  }
  return false;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    ApiService().baseUrl = _backendUrl;
  });

  testWidgets('Anmeldemaske erscheint beim Start', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(seconds: 1));

    expect(await waitFor(tester, find.text('MYPHILO ENGINE')), isTrue);
    expect(find.text('STUDIO PLATFORM'), findsOneWidget);
  });

  testWidgets('Anmeldung fuehrt in die Oberflaeche und die Bereiche oeffnen', (
    tester,
  ) async {
    if (_testUser.isEmpty || _testPassword.isEmpty) {
      markTestSkipped('TEST_USER/TEST_PASSWORD nicht gesetzt');
      return;
    }

    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(seconds: 1));
    expect(await waitFor(tester, find.text('MYPHILO ENGINE')), isTrue);

    // Anmeldeformular ausfuellen: erstes Feld Benutzer, zweites Passwort.
    final fields = find.byType(TextField);
    expect(fields, findsAtLeastNWidgets(2));
    await tester.enterText(fields.at(0), _testUser);
    await tester.pump();
    await tester.enterText(fields.at(1), _testPassword);
    await tester.pump();

    await tester.tap(find.text('Anmelden').last, warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 500));

    // Nach erfolgreicher Anmeldung haelt der Service ein Token und die
    // Oberflaeche zeigt die Bereichsleiste.
    final angemeldet = await waitFor(
      tester,
      find.text('Marktplatz'),
      timeout: const Duration(seconds: 25),
    );
    expect(
      angemeldet,
      isTrue,
      reason:
          'Anmeldung hat die Oberflaeche nicht geoeffnet '
          '(Token: ${ApiService().token != null})',
    );

    // Reihum die Hauptbereiche oeffnen; jeder muss ohne Ausnahme aufbauen.
    for (final bereich in const ['Engine', 'Marktplatz', 'News', 'Chat']) {
      final ziel = find.text(bereich);
      if (ziel.evaluate().isEmpty) continue;
      await tester.tap(ziel.first, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 600));
      expect(
        tester.takeException(),
        isNull,
        reason: 'Bereich $bereich hat eine Ausnahme ausgeloest',
      );
    }
  });
}
