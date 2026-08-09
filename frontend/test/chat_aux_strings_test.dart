import 'package:flutter_test/flutter_test.dart';
import 'package:culpeo_studio/core/app_strings.dart' as app_strings;
import 'package:culpeo_studio/modules/scout/chat_aux_strings.dart';

void main() {
  test(
    'chat auxiliary translations have identical German and English keys',
    () {
      expect(chatAuxStringsEn.keys.toSet(), chatAuxStringsDe.keys.toSet());
    },
  );

  test('chat auxiliary tr resolves the active language and placeholders', () {
    final originalLanguage = app_strings.appLanguage;
    addTearDown(() => app_strings.appLanguage = originalLanguage);

    app_strings.appLanguage = 'de';
    expect(
      tr('chatAux.modelPicker.providerInactive', {'provider': 'Example'}),
      'Example • Derzeit nicht aktiv',
    );

    app_strings.appLanguage = 'en';
    expect(
      tr('chatAux.modelPicker.providerInactive', {'provider': 'Example'}),
      'Example • Currently inactive',
    );
  });
}
