import 'package:flutter_test/flutter_test.dart';

import 'package:culpeo_studio/core/api_service.dart';
import 'package:culpeo_studio/main.dart';

void main() {
  testWidgets('shows login shell on startup', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(seconds: 6));

    expect(find.text('CULPEO STUDIO'), findsOneWidget);
    expect(find.text('BY CULPEOHQ'), findsOneWidget);
  });

  testWidgets(
    'dashboard shell builds after login without framework exceptions',
    (WidgetTester tester) async {
      final api = ApiService();
      api.token = 'test-token';
      api.username = 'tester';

      await tester.pumpWidget(const MyApp());
      await tester.pump();
      await tester.pump(const Duration(seconds: 6));
      await tester.pump(const Duration(milliseconds: 50));

      expect(tester.takeException(), isNull);

      api.login.logout();
    },
  );
}
