import 'package:culpeo_studio/core/app_strings.dart';
import 'package:culpeo_studio/modules/nodes/node_add_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('zeigt nur den direkten Node-Verbindungslink', (tester) async {
    final previousLanguage = appLanguage;
    appLanguage = 'de';
    addTearDown(() => appLanguage = previousLanguage);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => FilledButton(
            onPressed: () => showNodeAddDialog(context),
            child: const Text('Node verbinden'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Node verbinden'));
    await tester.pumpAndSettle();

    expect(find.text('Node-Verbindungslink'), findsOneWidget);
    expect(find.textContaining('culpeo-node://pair/'), findsWidgets);
    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.text('Tunnel steht schon? Manuell eintragen'), findsNothing);
    expect(find.text('Pairing-Token'), findsNothing);
    expect(find.text('gRPC-Port'), findsNothing);
  });
}
