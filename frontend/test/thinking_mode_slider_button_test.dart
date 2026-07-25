import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myphilostudio/screens/chat/chat_widgets.dart';

void main() {
  testWidgets('opens popup when trigger is tapped', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: _ThinkingSliderHarness(
            initialValue: 'fast',
            options: [
              ThinkingModeOption(
                value: 'fast',
                label: 'Fast Thinking',
                icon: Icons.bolt,
              ),
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
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('thinking-trigger')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('thinking-popup')), findsOneWidget);
    expect(find.byKey(const ValueKey('thinking-slider')), findsOneWidget);
  });

  testWidgets('drag keeps popup open and updates selected value', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: _ThinkingSliderHarness(
            initialValue: 'fast',
            options: [
              ThinkingModeOption(
                value: 'fast',
                label: 'Fast Thinking',
                icon: Icons.bolt,
              ),
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
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('thinking-trigger')));
    await tester.pumpAndSettle();

    final popupRect = tester.getRect(
      find.byKey(const ValueKey('thinking-popup')),
    );
    await tester.dragFrom(
      Offset(popupRect.left + 36, popupRect.top + 28),
      const Offset(180, 0),
    );
    // Agentic keeps its visual pulse running, so there is no settled frame.
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byKey(const ValueKey('thinking-popup')), findsOneWidget);
    expect(find.text('selected:agentic'), findsOneWidget);
  });

  testWidgets('outside tap closes popup', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: _ThinkingSliderHarness(
            initialValue: 'fast',
            options: [
              ThinkingModeOption(
                value: 'fast',
                label: 'Fast Thinking',
                icon: Icons.bolt,
              ),
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
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('thinking-trigger')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('thinking-popup')), findsOneWidget);

    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('thinking-popup')), findsNothing);
  });

  testWidgets('supports philox value set and syncs callback', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: _ThinkingSliderHarness(
            initialValue: 'medium',
            options: [
              ThinkingModeOption(
                value: 'medium',
                label: 'Fast Thinking',
                icon: Icons.bolt,
              ),
              ThinkingModeOption(
                value: 'deep',
                label: 'Dual Thinking',
                icon: Icons.psychology,
              ),
              ThinkingModeOption(
                value: 'agents',
                label: 'Agents',
                icon: Icons.groups,
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('thinking-trigger')));
    await tester.pumpAndSettle();

    final popupRect = tester.getRect(
      find.byKey(const ValueKey('thinking-popup')),
    );
    await tester.dragFrom(
      Offset(popupRect.left + 36, popupRect.top + 28),
      const Offset(180, 0),
    );
    // Agentic keeps its visual pulse running, so there is no settled frame.
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('selected:agents'), findsOneWidget);
    expect(find.byKey(const ValueKey('thinking-popup')), findsOneWidget);
  });

  testWidgets('disabled (in-development) option cannot be committed', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: _ThinkingSliderHarness(
            initialValue: 'fast',
            options: [
              ThinkingModeOption(
                value: 'fast',
                label: 'Fast',
                icon: Icons.bolt,
              ),
              ThinkingModeOption(
                value: 'medium',
                label: 'Fast Thinking',
                icon: Icons.speed,
              ),
              ThinkingModeOption(
                value: 'agent',
                label: 'Agent',
                icon: Icons.smart_toy_outlined,
                enabled: false,
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('thinking-trigger')));
    await tester.pumpAndSettle();

    final popupRect = tester.getRect(
      find.byKey(const ValueKey('thinking-popup')),
    );
    // Drag the thumb all the way onto the disabled 'agent' stop.
    await tester.dragFrom(
      Offset(popupRect.left + 36, popupRect.top + 28),
      const Offset(400, 0),
    );
    await tester.pump(const Duration(milliseconds: 200));

    // The disabled option must never become the committed value, and the popup
    // stays open (selection did not settle onto a real mode).
    expect(find.text('selected:agent'), findsNothing);
    expect(find.byKey(const ValueKey('thinking-popup')), findsOneWidget);
  });
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
            triggerKey: const ValueKey('thinking-trigger'),
            popupKey: const ValueKey('thinking-popup'),
            sliderKey: const ValueKey('thinking-slider'),
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
