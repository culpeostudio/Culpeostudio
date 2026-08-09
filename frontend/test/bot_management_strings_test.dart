import 'package:flutter_test/flutter_test.dart';
import 'package:culpeo_studio/core/app_strings.dart' as app_strings;
import 'package:culpeo_studio/modules/bots/bot_management_strings.dart';

void main() {
  test(
    'Bot Management translations have identical German and English keys',
    () {
      expect(
        botManagementStringsEn.keys.toSet(),
        botManagementStringsDe.keys.toSet(),
      );
    },
  );

  test('Bot Management tr resolves the active language and placeholders', () {
    final originalLanguage = app_strings.appLanguage;
    addTearDown(() => app_strings.appLanguage = originalLanguage);

    app_strings.appLanguage = 'de';
    expect(
      tr('botManagement.binding.selectionLabel', {'title': 'Modell A'}),
      'Feste Modellbindung auswählen: Modell A',
    );

    app_strings.appLanguage = 'en';
    expect(
      tr('botManagement.binding.selectionLabel', {'title': 'Model A'}),
      'Select fixed model binding: Model A',
    );
  });
}
