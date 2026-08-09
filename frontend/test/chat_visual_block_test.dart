import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:culpeo_studio/modules/scout/chat_visual_block.dart';

void main() {
  testWidgets('renders a native bar graphic from visual JSON', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ChatVisualBlock(
            source:
                '{"type":"bar","title":"Monate","labels":["Jan","Feb"],"values":[12,18]}',
          ),
        ),
      ),
    );

    expect(find.text('Monate'), findsOneWidget);
  });

  testWidgets('shows an error card for invalid visual JSON', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ChatVisualBlock(source: 'not-json')),
      ),
    );

    expect(find.textContaining('kein gültiges JSON'), findsOneWidget);
  });
}
