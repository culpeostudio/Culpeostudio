import 'package:flutter_test/flutter_test.dart';
import 'package:myphilostudio/l10n/app_strings.dart' as app_strings;
import 'package:myphilostudio/l10n/chat_tabs_strings.dart';

void main() {
  test('chat-tab translations have identical German and English keys', () {
    expect(chatTabsStringsEn.keys.toSet(), chatTabsStringsDe.keys.toSet());
  });

  test('chat-tab text resolves the active language and placeholders', () {
    final originalLanguage = app_strings.appLanguage;
    addTearDown(() => app_strings.appLanguage = originalLanguage);

    app_strings.appLanguage = 'de';
    expect(
      chatTabsText('philobot.modelSwitched', {'model': 'Example'}),
      'Modell gewechselt: Example',
    );

    app_strings.appLanguage = 'en';
    expect(
      chatTabsText('philobot.modelSwitched', {'model': 'Example'}),
      'Model switched: Example',
    );
  });
}
