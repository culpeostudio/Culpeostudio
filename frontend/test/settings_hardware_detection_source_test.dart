import 'package:flutter_test/flutter_test.dart';
import 'package:culpeo_studio/core/app_strings.dart' as app_strings;
import 'package:culpeo_studio/modules/settings/settings_cards.dart';

void main() {
  test(
    'uses Culpeo Studio branding for current and legacy detection sources',
    () {
      final originalLanguage = app_strings.appLanguage;
      addTearDown(() => app_strings.appLanguage = originalLanguage);

      app_strings.appLanguage = 'de';
      expect(
        settingsHardwareDetectionSourceLabel(
          'culpeostudio_hardware+native_live',
        ),
        'Culpeo-Studio-Systemerkennung + Live-Daten',
      );
      expect(
        settingsHardwareDetectionSourceLabel('whichllm+native_live'),
        'Culpeo-Studio-Systemerkennung + Live-Daten',
      );

      app_strings.appLanguage = 'en';
      expect(
        settingsHardwareDetectionSourceLabel('culpeostudio_hardware'),
        'Culpeo Studio Hardware Detection',
      );
    },
  );

  test('keeps unknown sources inspectable', () {
    expect(
      settingsHardwareDetectionSourceLabel('custom_probe'),
      'custom_probe',
    );
    expect(settingsHardwareDetectionSourceLabel('  '), isNull);
  });
}
