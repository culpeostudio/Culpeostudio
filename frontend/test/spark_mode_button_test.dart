import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:culpeo_studio/modules/scout/chat_widgets.dart';

/// Spark was the sixth segment of the thinking bar until it moved onto its own
/// switch, where it reads as what it is: a different way of answering, not a
/// deeper one. These cover the switch itself - it toggles, it colours up while
/// it is on, and it drops to its icon on a narrow pane.
void main() {
  const rust = Color(0xFFC1440E);

  testWidgets('the switch turns Spark on and off again', (tester) async {
    await tester.pumpWidget(_harness());
    expect(find.text('spark:false'), findsOneWidget);

    await tester.tap(find.byKey(const Key('spark-mode-toggle')));
    await tester.pumpAndSettle();
    expect(find.text('spark:true'), findsOneWidget);

    await tester.tap(find.byKey(const Key('spark-mode-toggle')));
    await tester.pumpAndSettle();
    expect(find.text('spark:false'), findsOneWidget);
  });

  testWidgets('rust marks it as engaged, the quiet outline as idle', (
    tester,
  ) async {
    await tester.pumpWidget(_harness());

    BoxDecoration decoration() {
      final container = tester.widget<AnimatedContainer>(
        find.descendant(
          of: find.byKey(const Key('spark-mode-toggle')),
          matching: find.byType(AnimatedContainer),
        ),
      );
      return container.decoration! as BoxDecoration;
    }

    expect(
      decoration().color,
      isNot(isSameColorAs(rust.withValues(alpha: 0.16))),
    );

    await tester.tap(find.byKey(const Key('spark-mode-toggle')));
    await tester.pumpAndSettle();

    expect(decoration().color, isSameColorAs(rust.withValues(alpha: 0.16)));
  });

  testWidgets('a narrow pane drops the label and keeps the icon', (
    tester,
  ) async {
    await tester.pumpWidget(_harness());
    expect(find.text('Spark'), findsOneWidget);

    await tester.pumpWidget(_harness(compact: true));
    await tester.pumpAndSettle();

    expect(find.text('Spark'), findsNothing);
    expect(find.byIcon(Icons.electric_bolt), findsOneWidget);
  });
}

Widget _harness({bool initialSpark = false, bool compact = false}) {
  return MaterialApp(
    home: Scaffold(
      body: _SparkModeHarness(initialSpark: initialSpark, compact: compact),
    ),
  );
}

class _SparkModeHarness extends StatefulWidget {
  final bool initialSpark;
  final bool compact;

  const _SparkModeHarness({required this.initialSpark, required this.compact});

  @override
  State<_SparkModeHarness> createState() => _SparkModeHarnessState();
}

class _SparkModeHarnessState extends State<_SparkModeHarness> {
  late bool _spark = widget.initialSpark;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0F0F14),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SparkModeButton(
            active: _spark,
            label: 'Spark',
            tooltip: 'Agent with tools and file access',
            compact: widget.compact,
            themeColor: const Color(0xFFC1440E),
            onChanged: (spark) {
              setState(() {
                _spark = spark;
              });
            },
          ),
          const SizedBox(height: 40),
          Text('spark:$_spark', style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}
