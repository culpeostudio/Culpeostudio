import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:culpeo_studio/core/app_strings.dart' as app_strings;
import 'package:culpeo_studio/core/api_service.dart';
import 'package:culpeo_studio/modules/news/news_screen.dart';

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

    await tester.pump(const Duration(milliseconds: 10));

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

    await tester.pump(const Duration(milliseconds: 10));
    await tester.enterText(find.byType(TextField), 'hardware');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));

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

    await tester.pump(const Duration(milliseconds: 10));

    expect(find.textContaining('Unbekannt'), findsOneWidget);
    expect(find.textContaining('01.01.0001'), findsNothing);
  });

  testWidgets('renders the card grid without overflow on wide and narrow panes', (
    WidgetTester tester,
  ) async {
    final items = List.generate(
      6,
      (index) => {
        'title':
            'Schlagzeile $index mit einer bewusst langen Zeile, die über zwei Zeilen läuft',
        'content':
            'Ein längerer Anriss, der den verfügbaren Platz in der Karte ausreizt '
            'und dabei mehrere Zeilen belegt, damit Überläufe auffallen.',
        'author': 'heise online',
        'published_at': '2026-07-30T13:32:30Z',
        'category': 'Hardware',
        'tags': const <String>[],
        'url': 'https://example.com/artikel-$index',
      },
    );

    addTearDown(tester.view.reset);

    for (final size in const [Size(1280, 800), Size(420, 900)]) {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = size;

      await tester.pumpWidget(
        MaterialApp(home: NewsScreen(loadNews: () async => items)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 10));

      expect(tester.takeException(), isNull, reason: 'Layout bei $size');
      expect(find.byType(GridView), findsOneWidget);
      expect(find.textContaining('Schlagzeile 0'), findsOneWidget);
    }
  });

  testWidgets('offers the security and software categories', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: NewsScreen(
          loadNews: () async => [
            {
              'id': 'heise-1',
              'title': 'Lücke in Firewall',
              'content': 'Angreifer nutzen sie aus.',
              'author': 'heise online',
              'published_at': '2026-07-30T13:32:30Z',
              'category': 'Security',
              'tags': <String>[],
              'url': 'https://example.com/heise-1',
            },
            {
              'id': 'heise-2',
              'title': 'Neues in .NET 10',
              'content': 'Die Bibliothek wächst.',
              'author': 'heise online',
              'published_at': '2026-07-30T12:00:00Z',
              'category': 'Software',
              'tags': <String>[],
              'url': 'https://example.com/heise-2',
            },
          ],
          loadSavedNews: () async => <dynamic>[],
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));

    await tester.tap(
      find.byKey(const ValueKey('news-category-dropdown-trigger')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('news-category-option-news.categorySecurity')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Lücke in Firewall'), findsOneWidget);
    expect(find.text('Neues in .NET 10'), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey('news-category-dropdown-trigger')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('news-category-option-news.categorySoftware')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Neues in .NET 10'), findsOneWidget);
    expect(find.text('Lücke in Firewall'), findsNothing);
  });

  testWidgets('filters by provider and shows its colour mark', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: NewsScreen(
          loadNews: () async => [
            {
              'id': 'heise-1',
              'title': 'Meldung von heise',
              'content': 'Inhalt.',
              'author': 'heise online',
              'published_at': '2026-07-30T13:32:30Z',
              'category': 'Hardware',
              'tags': <String>[],
              'url': 'https://example.com/heise-1',
            },
            {
              'id': 'anthropic-1',
              'title': 'Meldung von Anthropic',
              'content': 'Inhalt.',
              'author': 'Anthropic News',
              'published_at': '2026-07-30T12:00:00Z',
              'category': 'KI-Releases',
              'tags': <String>[],
              'url': 'https://example.com/anthropic-1',
            },
          ],
          loadSavedNews: () async => <dynamic>[],
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));

    expect(find.text('HE'), findsOneWidget);
    expect(find.text('AN'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('news-source-dropdown-trigger')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('news-source-option-Anthropic News')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Meldung von Anthropic'), findsOneWidget);
    expect(find.text('Meldung von heise'), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey('news-source-dropdown-trigger')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('news-source-option-')));
    await tester.pumpAndSettle();
    expect(find.text('Meldung von heise'), findsOneWidget);
  });

  testWidgets('saves an article and shows it in the saved view', (
    WidgetTester tester,
  ) async {
    final saved = <Map<String, dynamic>>[];
    final unsaved = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        home: NewsScreen(
          loadNews: () async => [
            {
              'id': 'heise-1',
              'title': 'Speicherkrise verschärft sich',
              'content': 'Speicher wird teurer.',
              'author': 'heise online',
              'published_at': '2026-07-30T13:32:30Z',
              'category': 'Hardware',
              'tags': <String>[],
              'url': 'https://example.com/heise-1',
            },
          ],
          loadSavedNews: () async => <dynamic>[],
          saveNews: (article) async => saved.add(article),
          unsaveNews: (id) async => unsaved.add(id),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));

    await tester.tap(find.byKey(const ValueKey('news-saved-toggle')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));
    expect(
      find.text('Du hast noch keine Berichte gespeichert.'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('news-saved-toggle')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));

    await tester.tap(find.byKey(const ValueKey('news-save-toggle-heise-1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));

    expect(saved, hasLength(1));
    expect(saved.single['id'], 'heise-1');

    await tester.tap(find.byKey(const ValueKey('news-saved-toggle')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));
    expect(find.text('Speicherkrise verschärft sich'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('news-save-toggle-heise-1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));
    expect(unsaved, ['heise-1']);
    expect(
      find.text('Du hast noch keine Berichte gespeichert.'),
      findsOneWidget,
    );
  });

  testWidgets('restores the previous state when saving fails', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: NewsScreen(
          loadNews: () async => [
            {
              'id': 'heise-1',
              'title': 'Speicherkrise verschärft sich',
              'content': 'Speicher wird teurer.',
              'author': 'heise online',
              'published_at': '2026-07-30T13:32:30Z',
              'category': 'Hardware',
              'tags': <String>[],
              'url': 'https://example.com/heise-1',
            },
          ],
          loadSavedNews: () async => <dynamic>[],
          saveNews: (article) async =>
              throw const ApiException('Backend offline'),
          unsaveNews: (id) async {},
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));

    await tester.tap(find.byKey(const ValueKey('news-save-toggle-heise-1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));

    await tester.tap(find.byKey(const ValueKey('news-saved-toggle')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));
    expect(
      find.text('Du hast noch keine Berichte gespeichert.'),
      findsOneWidget,
    );
  });

  testWidgets('keeps the feed usable when the saved list cannot be loaded', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: NewsScreen(
          loadNews: () async => [
            {
              'id': 'heise-1',
              'title': 'Speicherkrise verschärft sich',
              'content': 'Speicher wird teurer.',
              'author': 'heise online',
              'published_at': '2026-07-30T13:32:30Z',
              'category': 'Hardware',
              'tags': <String>[],
              'url': 'https://example.com/heise-1',
            },
          ],
          loadSavedNews: () async =>
              throw const ApiException('Backend offline'),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));

    expect(find.text('Speicherkrise verschärft sich'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('news-saved-toggle')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));
    expect(find.text('Backend offline'), findsOneWidget);
  });

  testWidgets('uses stable backend categories behind English filter labels', (
    WidgetTester tester,
  ) async {
    final previousLanguage = app_strings.appLanguage;
    app_strings.appLanguage = 'en';
    addTearDown(() => app_strings.appLanguage = previousLanguage);

    await tester.pumpWidget(
      MaterialApp(
        home: NewsScreen(
          loadNews: () async => [
            {
              'title': 'Release result',
              'content': 'A release.',
              'author': 'Test Feed',
              'published_at': '2026-07-09T13:32:30Z',
              'category': 'KI-Releases',
              'tags': <String>[],
              'url': 'https://example.com/release',
            },
            {
              'title': 'Hardware result',
              'content': 'A hardware update.',
              'author': 'Test Feed',
              'published_at': '2026-07-09T13:32:30Z',
              'category': 'Hardware',
              'tags': <String>[],
              'url': 'https://example.com/hardware',
            },
          ],
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));

    await tester.tap(
      find.byKey(const ValueKey('news-category-dropdown-trigger')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('AI Releases'));
    await tester.pumpAndSettle();

    expect(find.text('Release result'), findsOneWidget);
    expect(find.text('Hardware result'), findsNothing);
  });
}
