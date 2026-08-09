import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:culpeo_studio/modules/benchmark/benchmark_screen.dart';
import 'package:culpeo_studio/core/api_service.dart';
import 'package:culpeo_studio/core/app_state.dart';
import 'package:culpeo_studio/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final api = ApiService();
  final appState = AppState();

  setUp(() {
    api.token = 'test-token';
    api.username = 'tester';
    appState.setScreen('chat');
  });

  tearDown(() {
    api.login.logout();
    appState.setScreen('chat');
  });

  testWidgets('benchmark tab opens the module inside the app', (
    WidgetTester tester,
  ) async {
    await _pumpDashboardApp(tester);

    await tester.tap(find.byIcon(Icons.speed_outlined));
    await tester.pump();

    expect(appState.currentScreen, 'benchmark');
    expect(find.byType(BenchmarkScreen), findsOneWidget);

    // The screen asks for its boards over gRPC while it mounts. No backend
    // answers here, so let that call reach its test-shortened deadline instead
    // of leaving its timer behind when the tree is torn down.
    await tester.pump(const Duration(milliseconds: 10));
  });

  testWidgets('benchmark tab no longer advertises an external link', (
    WidgetTester tester,
  ) async {
    await _pumpDashboardApp(tester);

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer();
    addTearDown(gesture.removePointer);

    await gesture.moveTo(tester.getCenter(find.byIcon(Icons.speed_outlined)));
    await tester.pump();

    expect(find.byIcon(Icons.open_in_new), findsNothing);
    expect(find.text('Externe Website öffnen'), findsNothing);
  });

  testWidgets('dashboard has no theme selector', (WidgetTester tester) async {
    await _pumpDashboardApp(tester);

    expect(find.byIcon(Icons.light_mode_outlined), findsNothing);
    expect(find.byIcon(Icons.dark_mode_outlined), findsNothing);
  });
}

Future<void> _pumpDashboardApp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1600, 1000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(const MyApp());
  await tester.pump();
  // Startanimation abwarten, sonst faengt das Splash-Overlay die Gesten ab.
  await tester.pump(const Duration(seconds: 6));
  await tester.pump(const Duration(milliseconds: 50));
}
