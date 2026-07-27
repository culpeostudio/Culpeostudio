import 'package:flutter_test/flutter_test.dart';
import 'package:myphilostudio/l10n/app_strings.dart' as app_strings;
import 'package:myphilostudio/l10n/remaining_ui_strings.dart';

void main() {
  test('remaining UI translations have identical German and English keys', () {
    expect(
      remainingUiStringsEn.keys.toSet(),
      remainingUiStringsDe.keys.toSet(),
    );
  });

  test(
    'remaining UI text follows the selected language and resolves values',
    () {
      final originalLanguage = app_strings.appLanguage;
      addTearDown(() => app_strings.appLanguage = originalLanguage);

      app_strings.appLanguage = 'de';
      expect(
        remainingUiText('phaseLock.description', {
          'feature': 'Training',
          'phase': '4',
          'currentPhase': '1',
        }),
        contains('wird in Phase 4 freigeschaltet'),
      );

      app_strings.appLanguage = 'en';
      expect(
        remainingUiText('api.newsLoadHttpFailed', {'statusCode': '503'}),
        'Could not load news (HTTP 503).',
      );
    },
  );
}
