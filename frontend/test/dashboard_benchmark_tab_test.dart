import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myphilostudio/screens/benchmark/benchmark_screen.dart';
import 'package:myphilostudio/services/api_service.dart';
import 'package:myphilostudio/state/app_state.dart';
import 'package:myphilostudio/main.dart';

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
    api.logout();
    appState.setScreen('chat');
  });

  testWidgets('benchmark tab opens the module inside the app', (
    WidgetTester tester,
  ) async {
    await _pumpDashboardApp(tester);

    await tester.tap(find.text('Benchmark'));
    await tester.pump();

    expect(appState.currentScreen, 'benchmark');
    expect(find.byType(BenchmarkScreen), findsOneWidget);
  });

  testWidgets('benchmark tab no longer advertises an external link', (
    WidgetTester tester,
  ) async {
    await _pumpDashboardApp(tester);

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer();
    addTearDown(gesture.removePointer);

    await gesture.moveTo(tester.getCenter(find.text('Benchmark')));
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
  await tester.pump(const Duration(milliseconds: 50));
}
