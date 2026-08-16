import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:culpeo_studio/modules/scout/context_meter.dart';

/// The ring on the composer is the only place a user sees how full the model's
/// context window is, so these cover what it reports: the percentage it shows,
/// the colour it turns when the window gets tight, and that it stays out of the
/// way until the backend has measured something.
void main() {
  const metric = Color(0xFFC9A24A);
  const warning = Color(0xFFFF7043);
  const danger = Color(0xFFEF5350);

  Widget harness(ContextUsage usage) {
    return MaterialApp(
      home: Scaffold(
        body: Center(child: ContextMeter(usage: usage)),
      ),
    );
  }

  ContextUsage usageAt(int used, {int limit = 100, String source = 'catalog'}) {
    return ContextUsage(limitTokens: limit, usedTokens: used, source: source);
  }

  Color textColor(WidgetTester tester) {
    return tester.widget<Text>(find.byType(Text)).style!.color!;
  }

  testWidgets('an unmeasured chat shows no ring at all', (tester) async {
    await tester.pumpWidget(harness(ContextUsage.unknown));
    expect(find.byType(Text), findsNothing);
  });

  testWidgets('the ring reports the share of the window in use', (
    tester,
  ) async {
    await tester.pumpWidget(harness(usageAt(42)));
    await tester.pumpAndSettle();
    expect(find.text('42'), findsOneWidget);
  });

  testWidgets('a reading stays gold, a tight window warns and then alarms', (
    tester,
  ) async {
    await tester.pumpWidget(harness(usageAt(40)));
    await tester.pumpAndSettle();
    expect(textColor(tester), metric);

    await tester.pumpWidget(harness(usageAt(80)));
    await tester.pumpAndSettle();
    expect(textColor(tester), warning);

    await tester.pumpWidget(harness(usageAt(95)));
    await tester.pumpAndSettle();
    expect(textColor(tester), danger);
  });

  testWidgets('an overfull window is capped at a full ring', (tester) async {
    await tester.pumpWidget(harness(usageAt(140)));
    await tester.pumpAndSettle();
    expect(find.text('100'), findsOneWidget);
  });

  test('an estimated window is marked as one', () {
    expect(usageAt(10, source: 'average').isEstimated, isTrue);
    expect(usageAt(10, source: 'local').isEstimated, isFalse);
  });

  test('a map from the backend survives the trip unchanged', () {
    final usage = ContextUsage.fromMap(const {
      'limit_tokens': 128000,
      'used_tokens': 32000,
      'source': 'catalog',
      'compactions': 2,
      'compacted': true,
    });
    expect(usage.percent, 25);
    expect(usage.compactions, 2);
    expect(usage.compacted, isTrue);
    // Equality is what keeps a repeated reading from rebuilding the composer.
    expect(usage, isNot(usageAt(32000, limit: 128000)));
    expect(usageAt(32000, limit: 128000), usageAt(32000, limit: 128000));
  });
}
