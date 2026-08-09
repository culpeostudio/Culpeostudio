import 'package:flutter_test/flutter_test.dart';
import 'package:culpeo_studio/core/app_strings.dart' as app_strings;
import 'package:culpeo_studio/modules/scout/chat_tabs_strings.dart';

void main() {
  test('chat-tab translations have identical German and English keys', () {
    expect(chatTabsStringsEn.keys.toSet(), chatTabsStringsDe.keys.toSet());
  });

  test('the plus menu no longer offers to restart the conversation', () {
    for (final key in const ['common.restart', 'common.resetConversation']) {
      expect(chatTabsStringsDe, isNot(contains(key)));
      expect(chatTabsStringsEn, isNot(contains(key)));
    }
  });

  test('chat-tab text resolves the active language and placeholders', () {
    final originalLanguage = app_strings.appLanguage;
    addTearDown(() => app_strings.appLanguage = originalLanguage);

    app_strings.appLanguage = 'de';
    expect(
      chatTabsText('scout.modelSwitched', {'model': 'Example'}),
      'Modell gewechselt: Example',
    );

    app_strings.appLanguage = 'en';
    expect(
      chatTabsText('scout.modelSwitched', {'model': 'Example'}),
      'Model switched: Example',
    );
  });
}
