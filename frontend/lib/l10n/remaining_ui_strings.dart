import 'app_strings.dart' show appLanguage;

const Map<String, String> remainingUiStringsDe = {
  'phaseLock.badge': 'PHASE {phase}',
  'phaseLock.title': 'Noch nicht verfügbar',
  'phaseLock.description':
      '{feature} wird in Phase {phase} freigeschaltet. Die Plattform befindet sich derzeit in Phase {currentPhase} – dieser Bereich ist daher noch gesperrt und kann noch nicht verwendet werden.',

  'genStudio.modelId': 'MODELL-ID',
  'genStudio.steps': 'SCHRITTE',
  'genStudio.activeRenderings': 'Aktive Renderings',
  'genStudio.noActiveRenderJobs': 'Keine aktiven Render-Jobs.',

  'news.openLinkFailed': 'Link konnte nicht geöffnet werden: {url}',
  'news.openArticleFailed': 'Der Artikel konnte nicht geöffnet werden: {error}',
  'news.unknown': 'Unbekannt',
  'news.minutesAgo': 'vor {count} Min.',
  'news.hoursAgo': 'vor {count} Std.',
  'news.date': '{day}.{month}.{year}',
  'news.untitled': 'Kein Titel',
  'news.source': 'Quelle',

  'preferences.invalidReceived': 'Ungültige Benutzerpräferenzen erhalten.',
  'preferences.invalidChoice': 'Ungültige Sprache oder Frontend-Version.',
  'preferences.notSignedIn': 'Nicht angemeldet.',
  'preferences.invalidSaved': 'Ungültige Benutzerpräferenzen gespeichert.',
  'appState.sessionExpired':
      'Die Sitzung ist abgelaufen. Bitte melde dich erneut an.',
  'appState.sessionCreateFailed': 'Chat-Sitzung konnte nicht erstellt werden.',
  'appState.projectCreateFailed': 'Projekt konnte nicht erstellt werden.',
  'appState.loginFailed': 'Login fehlgeschlagen.',
  'appState.fileNotFound': 'Datei existiert nicht: {path}',
  'appState.fileReadFailed': 'Fehler beim Lesen der Datei: {error}',

  'engineController.vulkanOperationMissing':
      'Der Vulkan-Runtime-Neubau lieferte keinen Vorgang zurück.',
  'engineController.gpuSetupOperationMissing':
      'Die GPU-Einrichtung lieferte keinen Vorgang zurück.',
  'engineController.gpuSetupTimedOut':
      'Zeitüberschreitung bei der GPU-Einrichtung.',

  'engineModel.unnamed': 'Unbenanntes Modell',
  'engineModel.unknown': 'Unbekannt',

  'api.unsupportedHttpMethod': 'Nicht unterstützte HTTP-Methode: {method}',
  'api.engineRequestFailed': 'Engine-Anfrage fehlgeschlagen ({statusCode})',
  'api.engineUnavailable': 'Engine ist nicht erreichbar: {error}',
  'api.eventTicketMissing': 'Engine-Event-Ticket fehlt in der Antwort.',
  'api.eventStreamOpenFailed':
      'Engine-Eventstream konnte nicht geöffnet werden.',
  'api.streamFailed': 'Stream fehlgeschlagen',
  'api.streamDataUnreadable': 'Stream-Daten konnten nicht gelesen werden',
  'api.newsUnexpectedResponse': 'Unerwartetes Antwortformat vom News-Backend.',
  'api.newsLoadHttpFailed':
      'News konnten nicht geladen werden (HTTP {statusCode}).',
  'api.newsLoadFailed': 'News konnten nicht geladen werden: {error}',
  'api.newsSavedLoadFailed':
      'Gespeicherte Berichte konnten nicht geladen werden (HTTP {statusCode}).',
  'api.newsSaveFailed':
      'Bericht konnte nicht gespeichert werden ({statusCode}).',
  'api.newsUnsaveFailed':
      'Bericht konnte nicht aus der Merkliste entfernt werden ({statusCode}).',
  'api.benchmarkUnexpectedResponse':
      'Unerwartetes Antwortformat vom Benchmark-Backend.',
  'api.benchmarkHttpFailed':
      'Benchmark-Daten konnten nicht geladen werden (HTTP {statusCode}).',
  'api.benchmarkFailed':
      'Benchmark-Daten konnten nicht geladen werden: {error}',
  'api.benchmarkModelUnknown':
      'Zu {model} liegen weder Leaderboard-Werte noch Hub-Daten vor.',
};

const Map<String, String> remainingUiStringsEn = {
  'phaseLock.badge': 'PHASE {phase}',
  'phaseLock.title': 'Not available yet',
  'phaseLock.description':
      '{feature} will be unlocked in phase {phase}. The platform is currently in phase {currentPhase}, so this area is still locked and cannot be used yet.',

  'genStudio.modelId': 'MODEL ID',
  'genStudio.steps': 'STEPS',
  'genStudio.activeRenderings': 'Active renders',
  'genStudio.noActiveRenderJobs': 'No active render jobs.',

  'news.openLinkFailed': 'Could not open link: {url}',
  'news.openArticleFailed': 'Could not open article: {error}',
  'news.unknown': 'Unknown',
  'news.minutesAgo': '{count} min ago',
  'news.hoursAgo': '{count} hr ago',
  'news.date': '{month}/{day}/{year}',
  'news.untitled': 'Untitled',
  'news.source': 'Source',

  'preferences.invalidReceived': 'Received invalid user preferences.',
  'preferences.invalidChoice': 'Invalid language or frontend version.',
  'preferences.notSignedIn': 'Not signed in.',
  'preferences.invalidSaved': 'Invalid user preferences were saved.',
  'appState.sessionExpired': 'Your session has expired. Please sign in again.',
  'appState.sessionCreateFailed': 'Could not create chat session.',
  'appState.projectCreateFailed': 'Could not create project.',
  'appState.loginFailed': 'Login failed.',
  'appState.fileNotFound': 'File does not exist: {path}',
  'appState.fileReadFailed': 'Could not read file: {error}',

  'engineController.vulkanOperationMissing':
      'Rebuilding the Vulkan runtime did not return an operation.',
  'engineController.gpuSetupOperationMissing':
      'GPU setup did not return an operation.',
  'engineController.gpuSetupTimedOut': 'GPU setup timed out.',

  'engineModel.unnamed': 'Unnamed model',
  'engineModel.unknown': 'Unknown',

  'api.unsupportedHttpMethod': 'Unsupported HTTP method: {method}',
  'api.engineRequestFailed': 'Engine request failed ({statusCode})',
  'api.engineUnavailable': 'Engine is unavailable: {error}',
  'api.eventTicketMissing': 'Engine event ticket is missing from the response.',
  'api.eventStreamOpenFailed': 'Could not open Engine event stream.',
  'api.streamFailed': 'Stream failed',
  'api.streamDataUnreadable': 'Could not read stream data',
  'api.newsUnexpectedResponse': 'Unexpected response format from news backend.',
  'api.newsLoadHttpFailed': 'Could not load news (HTTP {statusCode}).',
  'api.newsLoadFailed': 'Could not load news: {error}',
  'api.newsSavedLoadFailed':
      'Could not load saved articles (HTTP {statusCode}).',
  'api.newsSaveFailed': 'Could not save the article ({statusCode}).',
  'api.newsUnsaveFailed': 'Could not remove the article ({statusCode}).',
  'api.benchmarkUnexpectedResponse':
      'Unexpected response format from benchmark backend.',
  'api.benchmarkHttpFailed':
      'Could not load benchmark data (HTTP {statusCode}).',
  'api.benchmarkFailed': 'Could not load benchmark data: {error}',
  'api.benchmarkModelUnknown':
      'No leaderboard scores and no hub data available for {model}.',
};

String remainingUiText(String key, [Map<String, String>? params]) {
  final strings = appLanguage == 'en'
      ? remainingUiStringsEn
      : remainingUiStringsDe;
  var value = strings[key] ?? remainingUiStringsDe[key] ?? key;
  if (params != null) {
    params.forEach((name, replacement) {
      value = value.replaceAll('{$name}', replacement);
    });
  }
  return value;
}
