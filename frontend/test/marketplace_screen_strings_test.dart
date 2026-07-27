import 'package:flutter_test/flutter_test.dart';
import 'package:myphilostudio/l10n/app_strings.dart' as app_strings;
import 'package:myphilostudio/l10n/marketplace_screen_strings.dart';

void main() {
  test(
    'Marketplace screen translations have identical German and English keys',
    () {
      expect(
        marketplaceScreenStringsEn.keys.toSet(),
        marketplaceScreenStringsDe.keys.toSet(),
      );
    },
  );

  test(
    'Marketplace screen tr resolves the active language and placeholders',
    () {
      final originalLanguage = app_strings.appLanguage;
      addTearDown(() => app_strings.appLanguage = originalLanguage);

      app_strings.appLanguage = 'de';
      expect(
        tr('marketplaceScreen.notification.downloadStarted', {
          'modelId': 'modell-a',
        }),
        'modell-a: Download gestartet',
      );

      app_strings.appLanguage = 'en';
      expect(
        tr('marketplaceScreen.notification.downloadStarted', {
          'modelId': 'model-a',
        }),
        'model-a: download started',
      );
    },
  );
}
