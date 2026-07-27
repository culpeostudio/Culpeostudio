import 'app_strings_de.dart';
import 'app_strings_en.dart';
import 'engine_strings.dart';

/// Aktuell gewaehlte UI-Sprache ('de' oder 'en').
///
/// Wird von `AppState.setLanguage` / `AppState.loadUserPrefs` gesetzt.
/// Bewusst entkoppelt von `AppState`, damit auch `AppState` selbst (und
/// Services ohne Widget-Kontext) `tr` nutzen koennen, ohne eine zyklische
/// Abhaengigkeit zu erzeugen. Widgets, die `tr` verwenden, muessen auf
/// `AppState` hoeren (z. B. ueber `AnimatedBuilder`), damit ein
/// Sprachwechsel sofort sichtbar wird.
String appLanguage = 'de';

/// Übersetzt einen UI-Text-Schlüssel in die aktuell gewählte Sprache.
///
/// Fallback-Reihenfolge: aktuelle Sprache → Deutsch → Schlüsselname.
/// Platzhalter `{name}` im Text werden aus [params] ersetzt.
String tr(String key, [Map<String, String>? params]) {
  return AppStrings.tr(key, params);
}

/// Zugriff auf die statischen String-Maps.
class AppStrings {
  AppStrings._();

  /// Alle Textpakete werden hier zu einer vollständigen Sprache vereinigt.
  /// Bereichsdateien halten umfangreiche Oberflächen (z. B. die Engine)
  /// wartbar, ohne dass die zentrale Übersetzungs-API auseinanderfällt.
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
