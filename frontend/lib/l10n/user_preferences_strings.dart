import 'app_strings.dart' show appLanguage;

/// Isolated texts for the server-backed user-preferences flow.
///
/// These are intentionally separate from the existing app string maps while
/// that broader localization migration is in progress.
const _userPreferencesStringsDe = <String, String>{
  'saving': 'Wird gespeichert…',
  'saveFailed':
      'Deine Einstellungen konnten nicht gespeichert werden. Bitte versuche es erneut.',
  'retry': 'Erneut versuchen',
  'loadFailed':
      'Deine gespeicherten Einstellungen konnten nicht geladen werden. Triff eine Auswahl und versuche es erneut.',
};

const _userPreferencesStringsEn = <String, String>{
  'saving': 'Saving…',
  'saveFailed': 'Your preferences could not be saved. Please try again.',
  'retry': 'Try again',
  'loadFailed':
      'Your saved preferences could not be loaded. Choose an option and try again.',
};

String userPreferencesText(String key) {
  final strings = appLanguage == 'en'
      ? _userPreferencesStringsEn
      : _userPreferencesStringsDe;
  return strings[key] ?? _userPreferencesStringsDe[key] ?? key;
}
