import 'package:flutter_test/flutter_test.dart';
import 'package:myphilostudio/l10n/app_strings.dart' as app_strings;
import 'package:myphilostudio/l10n/marketplace_detail_strings.dart';

void main() {
  test(
    'Marketplace detail translations have identical German and English keys',
    () {
      expect(
        marketplaceDetailStringsEn.keys.toSet(),
        marketplaceDetailStringsDe.keys.toSet(),
      );
    },
  );

  test(
    'Marketplace detail tr resolves the active language and placeholders',
    () {
      final originalLanguage = app_strings.appLanguage;
      addTearDown(() => app_strings.appLanguage = originalLanguage);

      app_strings.appLanguage = 'de';
      expect(
        tr('marketplaceDetail.model.price', {'price': '€0.10'}),
        'Preis: €0.10',
      );

      app_strings.appLanguage = 'en';
      expect(
        tr('marketplaceDetail.model.price', {'price': '€0.10'}),
        'Price: €0.10',
      );
    },
  );
}
