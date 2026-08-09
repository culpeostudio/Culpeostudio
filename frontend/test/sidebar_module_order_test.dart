import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:culpeo_studio/core/api_service.dart';
import 'package:culpeo_studio/core/app_state.dart';
import 'package:culpeo_studio/main.dart';

const _orderKey = 'sidebar_module_order';

AppState _freshState() {
  final api = ApiService();
  api.baseUrl = 'http://127.0.0.1:1/api';
  return AppState.test(api);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('modules start as marketplace, engine, news, benchmark', () {
    expect(_freshState().moduleOrder, const [
      'marketplace',
      'engine',
      'news',
      'benchmark',
    ]);
  });

  test('reordering moves the module and survives a restart', () async {
    final state = _freshState();

    // Benchmark (last) to the front.
    await state.reorderModules(3, 0);
    expect(state.moduleOrder, const [
      'benchmark',
      'marketplace',
      'engine',
      'news',
    ]);

    final restarted = _freshState();
    await restarted.loadModuleOrder();
    expect(restarted.moduleOrder, state.moduleOrder);
  });

  test('a move onto the same spot is not written back', () async {
    final state = _freshState();
    await state.reorderModules(1, 1);

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getStringList(_orderKey), isNull);
    expect(state.moduleOrder, AppState.defaultModuleOrder);
  });

  test('a stored order keeps only known modules and gains new ones', () async {
    SharedPreferences.setMockInitialValues({
      _orderKey: ['news', 'gone', 'news', 'engine'],
    });

    final state = _freshState();
    await state.loadModuleOrder();

    expect(state.moduleOrder, const [
      'news',
      'engine',
      'marketplace',
      'benchmark',
    ]);
  });

  testWidgets('the sidebar lists the modules in the stored order', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      _orderKey: ['news', 'benchmark', 'marketplace', 'engine'],
    });
    final appState = await _pumpDashboard(tester);

    expect(appState.moduleOrder, const [
      'news',
      'benchmark',
      'marketplace',
      'engine',
    ]);
    expect(_moduleLabelOrder(tester), const [
      'News',
      'Benchmark',
      'Marktplatz',
      'Engine',
    ]);
  });

  testWidgets('dragging a module to the top reorders and persists it', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      _orderKey: AppState.defaultModuleOrder,
    });
    final appState = await _pumpDashboard(tester);

    await _dragModule(tester, 'News', to: 'Marktplatz');

    expect(appState.moduleOrder, const [
      'news',
      'marketplace',
      'engine',
      'benchmark',
    ]);
    expect(_moduleLabelOrder(tester), const [
      'News',
      'Marktplatz',
      'Engine',
      'Benchmark',
    ]);

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getStringList(_orderKey), const [
      'news',
      'marketplace',
      'engine',
      'benchmark',
    ]);
  });

  testWidgets('the module panel slides away when the chat view is picked', (
    tester,
  ) async {
    await _pumpDashboard(tester);

    final modules = find.byKey(const Key('sidebar-module-list'));
    final left = tester.getTopLeft(modules).dx;

    await tester.tap(find.text('Chat').first);
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(modules).dx, lessThan(left));
    expect(find.byKey(const Key('chat-history-panel')), findsOneWidget);
  });

  testWidgets('the Modell tab switches to chat and slides the model panel in', (
    tester,
  ) async {
    final appState = await _pumpDashboard(tester);
    expect(appState.currentScreen, 'chat');

    // All three sidebar panels stay mounted (just translated off to the
    // side) so switching between them never remounts anything - the model
    // panel starts off-screen to the right of the module view.
    final models = find.byKey(const Key('sidebar-models'));
    final offscreenLeft = tester.getTopLeft(models).dx;

    // Leave chat first so switching to Modell has to bring it back, the
    // same way the Chat tab already does.
    appState.setScreen('engine');
    await tester.pump();

    await tester.tap(find.text('Modell'));
    await tester.pumpAndSettle();

    expect(appState.currentScreen, 'chat');
    expect(tester.getTopLeft(models).dx, lessThan(offscreenLeft));
  });

  testWidgets('the module drag grip is nine dots pinned to the row edge', (
    tester,
  ) async {
    await _pumpDashboard(tester);

    final row = find.byKey(const Key('sidebar-module-marketplace'));
    final dots = find.descendant(
      of: row,
      matching: find.byWidgetPredicate(
        (w) =>
            w is Container &&
            w.decoration is BoxDecoration &&
            (w.decoration as BoxDecoration).shape == BoxShape.circle,
      ),
    );
    expect(dots, findsNWidgets(9));

    final rowRight = tester.getTopRight(row).dx;
    final gripRight = tester.getTopRight(dots.at(2)).dx;
    // ~2mm (about 8dp) from the row's own right edge, not the label's.
    expect(rowRight - gripRight, closeTo(8, 3));
  });

  testWidgets('the desktop sidebar widened for the extra Modell tab', (
    tester,
  ) async {
    await _pumpDashboard(tester);

    expect(
      find.byWidgetPredicate((w) => w is SizedBox && w.width == 300),
      findsWidgets,
    );
    expect(
      find.byWidgetPredicate((w) => w is SizedBox && w.width == 260),
      findsNothing,
    );
  });
}

/// Boots the app the way [DashboardScreen] runs it: wide enough for the
/// desktop layout and past the splash animation, which would swallow taps.
Future<AppState> _pumpDashboard(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1600, 1000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final api = ApiService();
  api.token = 'test-token';
  api.username = 'tester';
  addTearDown(api.login.logout);

  await tester.pumpWidget(const MyApp());
  await tester.pump();
  await tester.pump(const Duration(seconds: 6));
  await tester.pump(const Duration(milliseconds: 50));
  return AppState();
}

List<String> _moduleLabelOrder(WidgetTester tester) {
  final labels = find.descendant(
    of: find.byKey(const Key('sidebar-module-list')),
    matching: find.byType(Text),
  );
  final found = tester
      .widgetList<Text>(labels)
      .map((text) => text.data ?? '')
      .where((label) => label.isNotEmpty)
      .toList();
  found.sort(
    (a, b) => tester
        .getTopLeft(
          find.descendant(
            of: find.byKey(const Key('sidebar-module-list')),
            matching: find.text(a),
          ),
        )
        .dy
        .compareTo(
          tester
              .getTopLeft(
                find.descendant(
                  of: find.byKey(const Key('sidebar-module-list')),
                  matching: find.text(b),
                ),
              )
              .dy,
        ),
  );
  return found;
}

/// Long-press drags [label] onto the row that currently shows [to]. Widget
/// tests report themselves as a touch platform, so the drag needs the press
/// delay that touch devices ask for.
Future<void> _dragModule(
  WidgetTester tester,
  String label, {
  required String to,
}) async {
  final source = find.descendant(
    of: find.byKey(const Key('sidebar-module-list')),
    matching: find.text(label),
  );
  final target = find.descendant(
    of: find.byKey(const Key('sidebar-module-list')),
    matching: find.text(to),
  );
  final start = tester.getCenter(source);
  final distance = tester.getCenter(target).dy - start.dy;

  final gesture = await tester.startGesture(start);
  await tester.pump(kLongPressTimeout + kPressTimeout);
  await gesture.moveBy(Offset(0, distance));
  await tester.pump();
  await gesture.up();
  await tester.pumpAndSettle();
}
