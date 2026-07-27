import 'package:flutter_test/flutter_test.dart';
import 'package:myphilostudio/l10n/app_strings.dart';
import 'package:myphilostudio/l10n/app_strings_de.dart';
import 'package:myphilostudio/l10n/app_strings_en.dart';
import 'package:myphilostudio/l10n/engine_strings.dart';

void main() {
  test('German and English localization bundles expose identical keys', () {
    final germanKeys = {...appStringsDe.keys, ...engineStringsDe.keys};
    final englishKeys = {...appStringsEn.keys, ...engineStringsEn.keys};

    expect(englishKeys, equals(germanKeys));
  });

  test('translation resolves the selected language and replaces parameters', () {
    final previousLanguage = appLanguage;
    addTearDown(() => appLanguage = previousLanguage);

    appLanguage = 'en';
    expect(tr('engineWidget.status.ready'), 'Ready');
    expect(
      tr('engineWidget.placement.planned', {'label': 'GPU'}),
      'Planned: GPU',
    );

    appLanguage = 'de';
    expect(tr('engineWidget.status.ready'), 'Bereit');
  });
}
