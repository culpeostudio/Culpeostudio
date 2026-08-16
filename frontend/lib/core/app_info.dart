/// Produktidentitaet von Culpeo Studio.
///
/// Die Version kommt beim Release-Build ueber `--dart-define=APP_VERSION` aus
/// `quikinstall/build_release.py`. Im Entwicklungsbuild greift der Fallback.
class AppInfo {
  AppInfo._();

  static const String name = 'Culpeo Studio';

  static const String vendor = 'culpeohq';

  static const String version = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: '2.0.0 beta',
  );

  /// Fusszeile fuer Splash und Info-Ansichten, z. B. `1.2.0-alpha · by culpeohq`.
  static String get versionLine => '$version · by $vendor';
}
