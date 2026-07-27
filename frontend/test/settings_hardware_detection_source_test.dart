import 'package:flutter_test/flutter_test.dart';
import 'package:myphilostudio/l10n/app_strings.dart' as app_strings;
import 'package:myphilostudio/screens/settings/settings_cards.dart';

void main() {
  test(
    'uses PhiloEngine branding for current and legacy detection sources',
    () {
      final originalLanguage = app_strings.appLanguage;
      addTearDown(() => app_strings.appLanguage = originalLanguage);

      app_strings.appLanguage = 'de';
      expect(
        settingsHardwareDetectionSourceLabel(
          'philoengine_hardware+native_live',
        ),
        'PhiloEngine-Systemerkennung + Live-Daten',
      );
      expect(
        settingsHardwareDetectionSourceLabel('whichllm+native_live'),
        'PhiloEngine-Systemerkennung + Live-Daten',
      );

      app_strings.appLanguage = 'en';
      expect(
        settingsHardwareDetectionSourceLabel('philoengine_hardware'),
        'PhiloEngine Hardware Detection',
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
