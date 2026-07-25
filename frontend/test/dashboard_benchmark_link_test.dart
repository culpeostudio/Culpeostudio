import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myphilostudio/services/api_service.dart';
import 'package:myphilostudio/state/app_state.dart';
import 'package:myphilostudio/main.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

class _FakeUrlLauncher extends UrlLauncherPlatform {
  final List<String> launchedUrls = [];

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> canLaunch(String url) async => true;

  @override
  Future<bool> launch(
    String url, {
    required bool useSafariVC,
    required bool useWebView,
    required bool enableJavaScript,
    required bool enableDomStorage,
    required bool universalLinksOnly,
    required Map<String, String> headers,
    String? webOnlyWindowName,
  }) async {
    launchedUrls.add(url);
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late UrlLauncherPlatform originalUrlLauncher;
  late _FakeUrlLauncher fakeUrlLauncher;
  final api = ApiService();
  final appState = AppState();

  setUp(() {
    originalUrlLauncher = UrlLauncherPlatform.instance;
    fakeUrlLauncher = _FakeUrlLauncher();
    UrlLauncherPlatform.instance = fakeUrlLauncher;

    api.token = 'test-token';
    api.username = 'tester';
    appState.setScreen('chat');
  });

  tearDown(() {
    UrlLauncherPlatform.instance = originalUrlLauncher;
    api.logout();
    appState.setScreen('chat');
  });

  testWidgets('benchmark tab opens confirmation dialog', (
    WidgetTester tester,
  ) async {
    await _pumpDashboardApp(tester);

    await tester.tap(find.text('Benchmark'));
    await tester.pump();

    expect(find.text('Externe Website öffnen'), findsOneWidget);
    expect(
      find.textContaining('artificialanalysis.ai im Browser zu öffnen'),
      findsOneWidget,
    );
    expect(appState.currentScreen, 'chat');
  });

  testWidgets('benchmark tab shows external-link icon on hover', (
    WidgetTester tester,
  ) async {
    await _pumpDashboardApp(tester);

    expect(find.byIcon(Icons.open_in_new), findsNothing);

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer();
    addTearDown(gesture.removePointer);

    await gesture.moveTo(tester.getCenter(find.text('Benchmark')));
    await tester.pump();

    expect(find.byIcon(Icons.open_in_new), findsOneWidget);
  });

  testWidgets('cancel keeps the current screen unchanged', (
    WidgetTester tester,
  ) async {
    await _pumpDashboardApp(tester);

    await tester.tap(find.text('Benchmark'));
    await tester.pump();
    await tester.tap(find.text('Abbrechen'));
    await tester.pump();

    expect(find.text('Externe Website öffnen'), findsNothing);
    expect(fakeUrlLauncher.launchedUrls, isEmpty);
    expect(appState.currentScreen, 'chat');
  });

  testWidgets('confirm opens the external benchmark page', (
    WidgetTester tester,
  ) async {
    await _pumpDashboardApp(tester);

    await tester.tap(find.text('Benchmark'));
    await tester.pump();
    await tester.tap(find.text('Weiter'));
    await tester.pump();

    expect(
      fakeUrlLauncher.launchedUrls,
      contains('https://artificialanalysis.ai/models'),
    );
    expect(appState.currentScreen, 'chat');
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
