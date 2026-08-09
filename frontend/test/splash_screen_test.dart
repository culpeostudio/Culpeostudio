import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:culpeo_studio/core/app_info.dart';
import 'package:culpeo_studio/core/startup_warmup.dart';
import 'package:culpeo_studio/modules/splash/splash_screen.dart';

void main() {
  Widget host() => MaterialApp(
    home: SplashGate(
      child: Scaffold(body: Container(key: const Key('app'))),
    ),
  );

  testWidgets('zeigt Zeichen und Versionszeile beim Start', (tester) async {
    await tester.pumpWidget(host());
    await tester.pump(const Duration(milliseconds: 600));

    expect(
      find.image(const AssetImage('assets/wordmark_light.png')),
      findsOneWidget,
    );
    expect(find.text(AppInfo.versionLine), findsOneWidget);
  });

  testWidgets('gibt die Oberflaeche nach der Startanimation frei', (
    tester,
  ) async {
    await tester.pumpWidget(host());
    await tester.pump(const Duration(seconds: 6));
    await tester.pump();

    expect(find.byKey(const Key('app')), findsOneWidget);
    expect(find.text(AppInfo.versionLine), findsNothing);
  });

  testWidgets('ueberspringt die Animation bei reduzierter Bewegung', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    await tester.pumpWidget(host());
    await tester.pump();

    expect(find.byKey(const Key('app')), findsOneWidget);
    expect(find.text(AppInfo.versionLine), findsNothing);
  });

  testWidgets('Fortschrittsbalken folgt dem Warmup-Fortschritt', (
    tester,
  ) async {
    StartupWarmup.instance.debugReset();
    addTearDown(StartupWarmup.instance.debugReset);

    await tester.pumpWidget(host());
    await tester.pump(const Duration(milliseconds: 100));

    double barFraction() {
      final bar = tester.widget<FractionallySizedBox>(
        find.byKey(const Key('splash-progress-fill')),
      );
      return bar.widthFactor ?? 0;
    }

    // Ohne Warmup folgt der Balken allein der Animation (bei 100 ms
    // gerade einmal begonnen).
    expect(barFraction(), lessThan(0.2));

    StartupWarmup.instance.debugSetProgress(1.0);
    await tester.pump();

    // Bei vollem Warmup steht der Balken auf dem Ziel der Animation
    // (86 %), nicht erst auf dem Zeitanteil der ersten 100 ms.
    expect(barFraction(), closeTo(0.86, 0.01));
  });
}
