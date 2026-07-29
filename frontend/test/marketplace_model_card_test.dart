import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:myphilostudio/l10n/app_strings.dart' as app_strings;
import 'package:myphilostudio/screens/marketplace/marketplace_screen.dart';
import 'package:myphilostudio/services/api_service.dart';

/// Beantwortet nur die Endpunkte, die der Marktplatz beim Start abfragt.
/// Alles andere bekommt ein leeres Objekt, damit kein echtes Backend noetig ist.
class _MarketplaceStubClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final path = request.url.path;
    Map<String, dynamic> body = const {};
    if (path.endsWith('/marktplatz/search')) {
      body = {
        'models': [
          {
            'model_id': 'anthropic/claude-opus-5',
            'display_name': 'Claude Opus 5',
            'provider': 'openrouter',
            'provider_badge': 'OpenRouter',
            'description':
                'Claude Opus 5 is Anthropic\'s flagship model for demanding '
                'reasoning, coding, and long-horizon agentic work.',
            'price_per_1m_input': 5.0,
            'price_per_1m_output': 25.0,
            'context_length': 1000000,
            'intelligence_score': 68,
            'capability_tags': [
              'code',
              'api',
              'long-context',
              'reasoning',
              'vision',
            ],
          },
          {
            'model_id': 'TheBloke/Mistral-7B-GGUF',
            'display_name': 'Mistral 7B Instruct',
            'provider': 'huggingface',
            'provider_badge': 'HuggingFace',
            'description': 'Kompaktes Open-Weight-Modell fuer lokale Nutzung.',
            'parameter_badge': '7B',
            'price_per_1m': 'lokal',
            'context_length': 32768,
            'intelligence_score': 41,
            'local_model': true,
            'estimated_vram_gb': 5.4,
            'fits_detected_gpu': true,
            // Reproduziert die reale Kombination aus normalen Capability-Tags
            // und einer breiten Quantisierungs-Zusammenfassung. Die Tags passen
            // gemeinsam in die Karte und duerfen deshalb weder gleichmaessig
            // zusammengestaucht noch abgeschnitten werden.
            'capability_tags': ['chat', 'math', 'q4_k_m', 'q8_0'],
          },
        ],
        'has_more': false,
      };
    }
    return http.StreamedResponse(
      Stream.value(utf8.encode(jsonEncode(body))),
      200,
      headers: const {'content-type': 'application/json'},
    );
  }
}

Widget _marketplaceTestApp() {
  return MaterialApp(
    theme: ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      // Entspricht der produktiven Typografie aus main.dart. Ohne diese
      // Line-Height bleiben vertikal abgeschnittene Pills im Test unsichtbar.
      textTheme: const TextTheme(bodyMedium: TextStyle(height: 1.4)),
    ),
    home: const MarketplaceScreen(),
  );
}

void main() {
  setUp(() => ApiService().debugSetHttpClient(_MarketplaceStubClient()));

  testWidgets('model cards keep provider accent and fit the grid tile', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final originalLanguage = app_strings.appLanguage;
    app_strings.appLanguage = 'de';
    addTearDown(() => app_strings.appLanguage = originalLanguage);

    await tester.pumpWidget(_marketplaceTestApp());
    await tester.pumpAndSettle();

    expect(find.text('Claude Opus 5'), findsOneWidget);
    // Der Anbietername steht zusaetzlich im Filter-Dropdown.
    expect(find.text('OpenRouter'), findsWidgets);

    // Preis-, Kontext- und Score-Pillen der neuen Karte.
    expect(find.text(r'IN $5.00'), findsOneWidget);
    expect(find.text(r'OUT $25.00'), findsOneWidget);
    expect(find.text('1.0M ctx'), findsOneWidget);
    expect(find.text('68 IQ'), findsOneWidget);
    expect(find.text('Q4 · Q8'), findsOneWidget);

    void expectFullTagText(String value) {
      final finder = find.text(value);
      final element = tester.element(finder);
      final text = tester.widget<Text>(finder);
      final painter = TextPainter(
        text: TextSpan(
          text: text.data,
          style: DefaultTextStyle.of(element).style.merge(text.style),
        ),
        textDirection: Directionality.of(element),
        textScaler: MediaQuery.textScalerOf(element),
        maxLines: 1,
      )..layout();

      expect(
        tester.getSize(finder).width,
        greaterThanOrEqualTo(painter.width),
        reason: '$value darf im sichtbaren Tag nicht ellipsiert werden',
      );
    }

    expectFullTagText('chat');
    expectFullTagText('math');
    expectFullTagText('Q4 · Q8');

    Rect nearestAncestorRect(
      Finder descendant,
      bool Function(Widget widget) matches,
    ) {
      final descendantElement = tester.element(descendant);
      Element? matchingElement;
      descendantElement.visitAncestorElements((ancestor) {
        if (!matches(ancestor.widget)) return true;
        matchingElement = ancestor;
        return false;
      });
      expect(matchingElement, isNotNull);
      final box = matchingElement!.renderObject! as RenderBox;
      return box.localToGlobal(Offset.zero) & box.size;
    }

    void expectPillInsideSlot(String label) {
      final text = find.text(label);
      final pillRect = nearestAncestorRect(
        text,
        (widget) =>
            widget is Container &&
            widget.padding ==
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      );
      final slotRect = nearestAncestorRect(
        text,
        (widget) =>
            widget is ConstrainedBox && widget.constraints.minHeight == 32,
      );

      expect(
        pillRect.bottom,
        lessThanOrEqualTo(slotRect.bottom),
        reason:
            '$label darf an der unteren Slot-Kante nicht beschnitten werden',
      );
    }

    expectPillInsideSlot(r'IN $5.00');
    expectPillInsideSlot('1.0M ctx');
    expectPillInsideSlot('5.4 GB VRAM');

    // Cloud-Modell wird hinzugefuegt, lokales Modell geladen – und beide
    // Buttons tragen die Farbe ihres Anbieters.
    final addButton = find.widgetWithText(ElevatedButton, 'Hinzufügen');
    final downloadButton = find.widgetWithText(ElevatedButton, 'Download');
    expect(addButton, findsOneWidget);
    expect(downloadButton, findsOneWidget);

    Color backgroundOf(Finder finder) {
      final button = tester.widget<ElevatedButton>(finder);
      return button.style!.backgroundColor!.resolve(<WidgetState>{})!;
    }

    expect(backgroundOf(addButton), const Color(0xFF8E7CFF));
    expect(backgroundOf(downloadButton), const Color(0xFFC9A24A));

    // Kachelgroesse bleibt unveraendert und die Karte laeuft nicht ueber.
    final cardHeight = tester
        .getSize(
          find
              .ancestor(
                of: find.text('Claude Opus 5'),
                matching: find.byType(Container),
              )
              .last,
        )
        .height;
    expect(cardHeight, 336);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('context and score stay on one line in narrow columns', (
    WidgetTester tester,
  ) async {
    // Schmale Spalte: frueher rutschte die zweite Kennzahl in eine verdeckte
    // Wrap-Zeile und war abgeschnitten.
    tester.view.physicalSize = const Size(560, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final originalLanguage = app_strings.appLanguage;
    app_strings.appLanguage = 'de';
    addTearDown(() => app_strings.appLanguage = originalLanguage);

    await tester.pumpWidget(_marketplaceTestApp());
    await tester.pumpAndSettle();

    final contextText = find.text('1.0M ctx');
    final scoreText = find.text('68 IQ');
    expect(contextText, findsOneWidget);
    expect(scoreText, findsOneWidget);
    expect(
      tester.getTopLeft(scoreText).dy,
      tester.getTopLeft(contextText).dy,
      reason: 'ctx und IQ gehoeren in dieselbe Pillenzeile',
    );
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('tags that do not fit are counted instead of clipped', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final originalLanguage = app_strings.appLanguage;
    app_strings.appLanguage = 'de';
    addTearDown(() => app_strings.appLanguage = originalLanguage);

    await tester.pumpWidget(_marketplaceTestApp());
    await tester.pumpAndSettle();

    // Das Cloud-Modell bringt fuenf Tags mit. Was nicht in die Zeile passt,
    // steckt sichtbar im Zaehler – frueher verschwand es ersatzlos.
    final tagRow = find.byType(Tooltip).evaluate().isNotEmpty;
    expect(tagRow, isTrue);

    final counter = find.textContaining(RegExp(r'^\+\d+$'));
    expect(counter, findsOneWidget);

    // Der Zaehler nennt genau die Zahl der nicht gezeigten Tags.
    const allTags = ['code', 'api', 'long-context', 'reasoning', 'vision'];
    final shown = allTags.where((t) => find.text(t).evaluate().isNotEmpty);
    final counterText = tester.widget<Text>(counter).data!;
    expect(counterText, '+${allTags.length - shown.length}');

    // Alles bleibt auf einer Zeile und nichts laeuft ueber.
    final tops = [
      ...shown.map((t) => tester.getTopLeft(find.text(t)).dy),
      tester.getTopLeft(counter).dy,
    ];
    expect(tops.toSet().length, 1);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('cloud and local cards place every block on the same line', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final originalLanguage = app_strings.appLanguage;
    app_strings.appLanguage = 'de';
    addTearDown(() => app_strings.appLanguage = originalLanguage);

    await tester.pumpWidget(_marketplaceTestApp());
    await tester.pumpAndSettle();

    // Das Parameter-Badge neben dem Anbieter ist entfallen.
    expect(find.text('7B'), findsNothing);

    // Erste Kennzahlenzeile: Cloud zeigt den Preis, lokal die Hardware-Passung
    // – beide auf derselben Hoehe direkt unter der Beschreibung.
    final priceTop = tester.getTopLeft(find.text(r'IN $5.00')).dy;
    final vramTop = tester.getTopLeft(find.text('5.4 GB VRAM')).dy;
    expect(vramTop, priceTop);

    // Zweite Zeile traegt auf beiden Karten Kontext und Score.
    final cloudContextTop = tester.getTopLeft(find.text('1.0M ctx')).dy;
    final localContextTop = tester.getTopLeft(find.text('33K ctx')).dy;
    expect(localContextTop, cloudContextTop);
    expect(cloudContextTop, greaterThan(priceTop));

    // Tags stehen direkt ueber der Aktion und auf beiden Karten gleich hoch.
    final cloudTagTop = tester.getTopLeft(find.text('code')).dy;
    final localTagTop = tester.getTopLeft(find.text('chat')).dy;
    expect(localTagTop, cloudTagTop);
    expect(cloudTagTop, greaterThan(cloudContextTop));

    final buttonTop = tester
        .getTopLeft(find.widgetWithText(ElevatedButton, 'Hinzufügen'))
        .dy;
    expect(buttonTop, greaterThan(cloudTagTop));
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
