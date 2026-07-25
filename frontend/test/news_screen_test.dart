import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myphilostudio/services/api_service.dart';
import 'package:myphilostudio/screens/news/news_screen.dart';

void main() {
  testWidgets('shows backend error state when loading news fails', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: NewsScreen(
          loadNews: () async => throw const ApiException('Backend offline'),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Backend offline'), findsOneWidget);
    expect(find.text('Erneut versuchen'), findsOneWidget);
  });

  testWidgets('shows empty filter state separately from load errors', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: NewsScreen(
          loadNews: () async => [
            {
              'title': 'OpenAI veröffentlicht neues Modell',
              'content': 'Mehr Kontext und bessere Tools.',
              'author': 'OpenAI News',
              'published_at': '2026-07-09T13:32:30Z',
              'category': 'KI-Releases',
              'tags': ['OpenAI', 'AI'],
              'url': 'https://example.com/openai',
            },
          ],
        ),
      ),
    );

    await tester.pump();
    await tester.enterText(find.byType(TextField), 'hardware');
    await tester.pump();

    expect(find.text('Keine passenden Artikel gefunden.'), findsOneWidget);
    expect(find.text('Filter zurücksetzen'), findsOneWidget);
  });

  testWidgets('shows unknown date for invalid zero timestamp', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: NewsScreen(
          loadNews: () async => [
            {
              'title': 'Feed ohne Datum',
              'content': 'Datum konnte nicht gelesen werden.',
              'author': 'Test Feed',
              'published_at': '0001-01-01T00:00:00Z',
              'category': 'Research',
              'tags': ['Test'],
              'url': 'https://example.com/test-feed',
            },
          ],
        ),
      ),
    );

    await tester.pump();

    expect(find.textContaining('Unbekannt'), findsOneWidget);
    expect(find.textContaining('01.01.0001'), findsNothing);
  });
}
