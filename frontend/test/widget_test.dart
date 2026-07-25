import 'package:flutter_test/flutter_test.dart';

import 'package:myphilostudio/services/api_service.dart';
import 'package:myphilostudio/main.dart';

void main() {
  testWidgets('shows login shell on startup', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('MYPHILO ENGINE'), findsOneWidget);
    expect(find.text('STUDIO PLATFORM'), findsOneWidget);
  });

  testWidgets(
    'dashboard shell builds after login without framework exceptions',
    (WidgetTester tester) async {
      final api = ApiService();
      api.token = 'test-token';
      api.username = 'tester';

      await tester.pumpWidget(const MyApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(tester.takeException(), isNull);

      api.logout();
    },
  );
}
