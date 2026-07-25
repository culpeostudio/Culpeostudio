import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myphilostudio/screens/marketplace/marketplace_screen.dart';

void main() {
  testWidgets('marketplace search stays overflow-free at narrow width', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(620, 820);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: MarketplaceScreen()));
    await tester.pump();

    expect(find.byTooltip('Modelle suchen'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('Modelle suchen'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(TextField), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
