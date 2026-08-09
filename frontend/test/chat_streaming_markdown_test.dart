import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_markdown_latex/flutter_markdown_latex.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:culpeo_studio/modules/scout/chat_markdown_helpers.dart';

Widget _markdownBody(String data) {
  final content = normalizeChatMarkdown(data);
  return MarkdownBody(
    data: content,
    selectable: true,
    checkboxBuilder: (checked) => buildMarkdownCheckbox(checked),
    builders: {
      if (shouldUseInputCheckboxBuilder(content))
        'input': TaskCheckboxElementBuilder(),
      'latex': LatexElementBuilder(),
    },
    blockSyntaxes: [LatexBlockSyntax()],
    inlineSyntaxes: [LatexInlineSyntax()],
    extensionSet: md.ExtensionSet.gitHubFlavored,
  );
}

Widget _messageBody(String content, {required bool streaming}) {
  final displayContent = streaming
      ? (content.isEmpty ? '|' : '$content |')
      : content;
  final child = streaming
      ? Text(displayContent)
      : _markdownBody(displayContent);
  return MaterialApp(
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
}

const _mediumTable = '''
| Priorität | Aufgabe | Grund (max. 10 Wörter) |
|-----------|---------|------------------------|
| Hoch | 1. Datenbank‑Backup erstellen (Fehlgeschlagen) | Wichtige Daten könnten verloren gehen. |
| Hoch | 3. Kritischen Memory‑Leak im Backend‑Server beheben | Server kann abstürzen, Service unterbrochen. |
| Niedrig | 2. UI‑Button‑Farbe von Blau auf Dunkelblau ändern | Änderung wirkt nicht sofort auf Nutzer. |
| Niedrig | 4. Readme‑Datei im Repository aktualisieren | Dokumentation fehlt für neue Entwickler. |

---
''';

void main() {
  testWidgets('streaming a table row-by-row never throws (plain text path)', (
    tester,
  ) async {
    for (var i = 1; i <= _mediumTable.length; i++) {
      await tester.pumpWidget(
        _messageBody(_mediumTable.substring(0, i), streaming: true),
      );
      await tester.pump();
      final err = tester.takeException();
      if (err != null) {
        fail('streaming prefix length $i threw: $err');
      }
    }
  });

  testWidgets('completed table renders as markdown without asserting', (
    tester,
  ) async {
    await tester.pumpWidget(_messageBody(_mediumTable, streaming: false));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
