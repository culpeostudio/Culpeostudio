import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:myphilostudio/screens/chat/chat_markdown_helpers.dart';

void main() {
  test('normalizeChatMarkdown converts multiline bracket latex blocks', () {
    const input = '''
Vorher
\\[
f(x) = x^2
\\]
Nachher
''';

    expect(normalizeChatMarkdown(input), '''
Vorher
\$\$
f(x) = x^2
\$\$
Nachher
''');
  });

  test('buildCodePreviewLabel keeps the intended copy', () {
    expect(
      buildCodePreviewLabel('print("a");\nprint("b");'),
      '2 Zeilen Code \u2022 Klicken zum Anzeigen',
    );
  });

  test('isMarkdownSourceLanguage only allows text-like languages', () {
    expect(isMarkdownSourceLanguage('markdown'), isTrue);
    expect(isMarkdownSourceLanguage('md'), isTrue);
    expect(isMarkdownSourceLanguage('text'), isTrue);
    expect(isMarkdownSourceLanguage('plaintext'), isTrue);
    expect(isMarkdownSourceLanguage('python'), isFalse);
    expect(isMarkdownSourceLanguage('go'), isFalse);
    expect(isMarkdownSourceLanguage(''), isFalse);
  });

  test('shouldUseInputCheckboxBuilder only enables raw checkbox inputs', () {
    expect(
      shouldUseInputCheckboxBuilder('<input type="checkbox"> Offen'),
      isTrue,
    );
    expect(
      shouldUseInputCheckboxBuilder('- [x] Erledigt\n- [ ] Offen'),
      isFalse,
    );
  });

  testWidgets('TaskCheckboxElementBuilder renders input checkbox elements', (
    tester,
  ) async {
    final checkedInput = md.Element.empty('input')
      ..attributes['type'] = 'checkbox'
      ..attributes['checked'] = 'checked';
    final uncheckedInput = md.Element.empty('input')
      ..attributes['type'] = 'checkbox';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              final builder = TaskCheckboxElementBuilder(
                accentColor: Colors.green,
              );
              return Row(
                children: [
                  builder.visitElementAfterWithContext(
                    context,
                    checkedInput,
                    null,
                    null,
                  )!,
                  builder.visitElementAfterWithContext(
                    context,
                    uncheckedInput,
                    null,
                    null,
                  )!,
                ],
              );
            },
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.check_box), findsOneWidget);
    expect(find.byIcon(Icons.check_box_outline_blank), findsOneWidget);
  });

  testWidgets('MarkdownSourceBlock previews and exposes raw source', (
    tester,
  ) async {
    const source = '- [x] Erledigt\n- [ ] Offen';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MarkdownSourceBlock(
            source: source,
            language: 'markdown',
            accentColor: Colors.blue,
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.check_box), findsOneWidget);
    expect(find.byIcon(Icons.check_box_outline_blank), findsOneWidget);
    expect(find.text('Erledigt'), findsOneWidget);
    expect(find.text('Offen'), findsOneWidget);
    expect(find.byTooltip('Quelltext kopieren'), findsOneWidget);

    await tester.tap(find.text('Quelltext'));
    await tester.pumpAndSettle();

    expect(find.text(source), findsOneWidget);
  });
}
