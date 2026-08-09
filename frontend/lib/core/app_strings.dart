import './app_strings_de.dart';
import './app_strings_en.dart';
import '../modules/engine/engine_strings.dart';

String appLanguage = 'de';

String tr(String key, [Map<String, String>? params]) {
  return AppStrings.tr(key, params);
}

class AppStrings {
  AppStrings._();

  static final Map<String, String> _de = Map.unmodifiable({
    ...appStringsDe,
    ...engineStringsDe,
  });
  static final Map<String, String> _en = Map.unmodifiable({
    ...appStringsEn,
    ...engineStringsEn,
  });

  static String tr(String key, [Map<String, String>? params]) {
    final map = appLanguage == 'en' ? _en : _de;
    var value = map[key] ?? _de[key] ?? key;
    if (params != null) {
      params.forEach((name, replacement) {
        value = value.replaceAll('{$name}', replacement);
      });
    }
    return value;
  }
}
