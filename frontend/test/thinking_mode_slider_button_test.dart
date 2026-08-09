import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:culpeo_studio/modules/scout/chat_widgets.dart';

/// [ThinkingModeSliderButton] used to open a popup with a drag slider; it's
/// now an always-visible segmented pill (styled like the sidebar's
/// module/chat/model switcher) where tapping a segment commits it directly.
/// These tests exercise that: no popup or drag gestures, just taps on the
/// option's icon.
void main() {
  const options = [
    ThinkingModeOption(value: 'fast', label: 'Fast Thinking', icon: Icons.bolt),
    ThinkingModeOption(
      value: 'deep',
      label: 'Dual Thinking',
      icon: Icons.psychology,
    ),
    ThinkingModeOption(
      value: 'agentic',
      label: 'Agentic',
      icon: Icons.smart_toy_outlined,
    ),
  ];

  testWidgets('every option renders on the bar with no popup involved', (
    tester,
  ) async {
    await tester.pumpWidget(_harness(initialValue: 'fast', options: options));

    expect(find.byKey(const Key('thinking-mode-switcher')), findsOneWidget);
    for (final option in options) {
      expect(
        find.byKey(ValueKey('thinking-option-${option.value}')),
        findsOneWidget,
      );
    }
  });

  testWidgets('tapping a segment commits it immediately', (tester) async {
    await tester.pumpWidget(_harness(initialValue: 'fast', options: options));
    expect(find.text('selected:fast'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('thinking-option-agentic')));
    await tester.pump();

    expect(find.text('selected:agentic'), findsOneWidget);
  });

  testWidgets('a disabled option cannot be committed', (tester) async {
    await tester.pumpWidget(
      _harness(
        initialValue: 'fast',
        options: const [
          ThinkingModeOption(value: 'fast', label: 'Fast', icon: Icons.bolt),
          ThinkingModeOption(
            value: 'medium',
            label: 'Fast Thinking',
            icon: Icons.speed,
          ),
          ThinkingModeOption(
            value: 'spark',
            label: 'Agent',
            icon: Icons.smart_toy_outlined,
            enabled: false,
          ),
        ],
      ),
    );

    await tester.tap(
      find.byKey(const ValueKey('thinking-option-spark')),
      warnIfMissed: false,
    );
    await tester.pump();

    expect(find.text('selected:agent'), findsNothing);
    expect(find.text('selected:fast'), findsOneWidget);
  });

  /// The highlight is painted, not built out of widgets, so these read back
  /// what the painter drew: one outline at rest, and while it travels, a
  /// shape stretched across the segments it's moving between.
  Path highlight(WidgetTester tester) {
    final painter = tester
        .widget<CustomPaint>(
          find.descendant(
            of: find.byKey(const Key('thinking-mode-switcher')),
            matching: find.byType(CustomPaint),
          ),
        )
        .painter!;
    final canvas = _RecordingCanvas();
    painter.paint(canvas, const Size(200, 30));
    return canvas.paths.single;
  }

  /// Where the segment's icon actually sits, in the painter's own
  /// coordinates. The ring has to land on exactly this - measuring it
  /// rather than recomputing it is what catches the painter counting the
  /// bar's padding or border a second time and drawing beside the icons.
  double segmentCenter(WidgetTester tester, int index) {
    final canvas = tester.getRect(
      find.descendant(
        of: find.byKey(const Key('thinking-mode-switcher')),
        matching: find.byType(CustomPaint),
      ),
    );
    final icon = tester.getRect(
      find.byKey(ValueKey('thinking-option-${options[index].value}')),
    );
    return icon.center.dx - canvas.left;
  }

  testWidgets('at rest the highlight is one ring around the selected icon', (
    tester,
  ) async {
    await tester.pumpWidget(_harness(initialValue: 'deep', options: options));

    final resting = highlight(tester).getBounds();
    expect(resting.width, closeTo(24, 0.5));
    expect(resting.height, closeTo(24, 0.5));
    expect(resting.center.dx, closeTo(segmentCenter(tester, 1), 0.5));
  });

  testWidgets(
    'switching segments stretches the highlight across them, then settles '
    'back onto one',
    (tester) async {
      await tester.pumpWidget(_harness(initialValue: 'fast', options: options));
      final start = highlight(tester).getBounds();

      await tester.tap(find.byKey(const ValueKey('thinking-option-agentic')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 140));

      // Mid-flight the leader has moved on while the remnant hangs back, so
      // the shape covers more ground than a single segment does.
      final inFlight = highlight(tester).getBounds();
      expect(inFlight.width, greaterThan(start.width + 8));
      expect(inFlight.left, lessThan(start.center.dx));
      expect(inFlight.right, greaterThan(start.right));

      await tester.pumpAndSettle();

      final settled = highlight(tester).getBounds();
      expect(settled.width, closeTo(24, 0.5));
      expect(settled.center.dx, closeTo(segmentCenter(tester, 2), 0.5));
    },
  );

  testWidgets('the two droplets are one closed outline while they touch', (
    tester,
  ) async {
    await tester.pumpWidget(_harness(initialValue: 'fast', options: options));
    expect(highlight(tester).computeMetrics().length, 1);

    // A step to the neighbouring segment: close enough the whole way that
    // the trailing droplet stays joined to the leading one and is drawn as
    // a single contour, rather than one shape fading out beside another.
    await tester.tap(find.byKey(const ValueKey('thinking-option-deep')));
    await tester.pump();
    for (var elapsed = 0; elapsed < 420; elapsed += 60) {
      await tester.pump(const Duration(milliseconds: 60));
      expect(
        highlight(tester).computeMetrics().length,
        1,
        reason: 'split into separate shapes ${elapsed}ms in',
      );
    }
  });

  testWidgets('every segment stays icon-only, even the selected one', (
    tester,
  ) async {
    await tester.pumpWidget(_harness(initialValue: 'fast', options: options));

    expect(find.text('Fast Thinking'), findsNothing);
    expect(find.text('Dual Thinking'), findsNothing);
    expect(find.text('Agentic'), findsNothing);
    for (final option in options) {
      expect(
        find.descendant(
          of: find.byKey(ValueKey('thinking-option-${option.value}')),
          matching: find.byIcon(option.icon),
        ),
        findsOneWidget,
      );
    }
  });
}

/// Keeps the paths a painter draws and ignores everything else, so a test
/// can assert on the shape instead of on a golden image.
class _RecordingCanvas implements Canvas {
  final List<Path> paths = [];

  @override
  void drawPath(Path path, Paint paint) {
    // Fill and stroke are the same shape drawn twice; keep it once.
    if (paths.isEmpty) paths.add(path);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

Widget _harness({
  required String initialValue,
  required List<ThinkingModeOption> options,
}) {
  return MaterialApp(
    home: Scaffold(
      body: _ThinkingSliderHarness(
        initialValue: initialValue,
        options: options,
      ),
    ),
  );
}

class _ThinkingSliderHarness extends StatefulWidget {
  final String initialValue;
  final List<ThinkingModeOption> options;

  const _ThinkingSliderHarness({
    required this.initialValue,
    required this.options,
  });

  @override
  State<_ThinkingSliderHarness> createState() => _ThinkingSliderHarnessState();
}

class _ThinkingSliderHarnessState extends State<_ThinkingSliderHarness> {
  late String _selected = widget.initialValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0F0F14),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ThinkingModeSliderButton(
            value: _selected,
            options: widget.options,
            themeColor: const Color(0xFF2196F3),
            onChanged: (value) {
              setState(() {
                _selected = value;
              });
            },
          ),
          const SizedBox(height: 80),
          Text(
            'selected:$_selected',
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }
}
