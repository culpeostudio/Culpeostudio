import 'app_strings.dart' as base;

/// Isolated translations for the reusable chat UI building blocks.
///
/// This overlay deliberately delegates existing keys to [base.AppStrings] so
/// the auxiliary widgets can be migrated without changing the established
/// localization maps in the same change.
const Map<String, String> chatAuxStringsDe = {
  // Markdown and code previews
  'chatAux.markdown.codePreview': '{count} Zeilen Code • Klicken zum Anzeigen',
  'chatAux.markdown.linkOpenFailed': 'Link konnte nicht geöffnet werden',
  'chatAux.markdown.linkOpenFailedWithUrl':
      'Link konnte nicht geöffnet werden: {url}',
  'chatAux.markdown.sourceCopied': 'Quelltext kopiert',
  'chatAux.markdown.plainText': 'TEXT',
  'chatAux.markdown.preview': 'Vorschau',
  'chatAux.markdown.source': 'Quelltext',
  'chatAux.markdown.copySource': 'Quelltext kopieren',
  'chatAux.code.defaultLanguage': 'CODE',
  'chatAux.code.view': 'Anschauen',

  // Local model warm-up
  'chatAux.warmup.placementPending': 'Platzierung wird geplant',
  'chatAux.warmup.waiting': 'Bitte kurz warten – Modell läuft warm',
  'chatAux.warmup.cancelled': 'Modellstart wurde abgebrochen',
  'chatAux.warmup.semanticProgress': '{model}: {percent} Prozent, {phase}',
  'chatAux.warmup.startFailed': 'Modell konnte nicht gestartet werden',
  'chatAux.warmup.queuePosition': 'Warteschlange: {position}',
  'chatAux.warmup.chooseAnother': 'Anderes Modell wählen',
  'chatAux.warmup.changeBinding': 'Bindung ändern',
  'chatAux.warmup.phase.queued': 'Wartet auf sichere Ressourcen',
  'chatAux.warmup.phase.admission': 'Ressourcenfreigabe wird geprüft',
  'chatAux.warmup.phase.preparingRuntime': 'Laufzeit wird vorbereitet',
  'chatAux.warmup.phase.runtimeReady': 'Laufzeit ist bereit',
  'chatAux.warmup.phase.refreshingPlan': 'Speicherplan wird erneut geprüft',
  'chatAux.warmup.phase.evicting': 'Ungenutztes Modell wird entladen',
  'chatAux.warmup.phase.startingInstances': 'Modellstart wird koordiniert',
  'chatAux.warmup.phase.launchingWorker': 'Modellprozess wird gestartet',
  'chatAux.warmup.phase.loadingModel': 'Modellgewichte werden geladen',
  'chatAux.warmup.phase.workerInitializing':
      'Healthcheck: Modellserver startet',
  'chatAux.warmup.phase.workerReady': 'Healthcheck erfolgreich',
  'chatAux.warmup.phase.verifyingWorker': 'Mini-Inferenz wird geprüft',
  'chatAux.warmup.phase.instanceVerified': 'Mini-Inferenz erfolgreich',
  'chatAux.warmup.phase.resourcePlan': 'Speicherplan wird geprüft',
  'chatAux.warmup.phase.healthcheck': 'Healthcheck des Modellservers läuft',
  'chatAux.warmup.phase.preparing': 'Modellstart wird vorbereitet',

  // Permission requests
  'chatAux.permission.title': 'Zugriffsanfrage',
  'chatAux.permission.body':
      'PhiloBot möchte außerhalb des Projektpfads arbeiten ({tool}):',
  'chatAux.permission.allowOnce': 'Einmal erlauben',
  'chatAux.permission.allowSession': 'Für Sitzung erlauben',
  'chatAux.permission.tool.readFile': 'Datei lesen',
  'chatAux.permission.tool.writeFile': 'Datei schreiben',
  'chatAux.permission.tool.patchFile': 'Datei ändern',
  'chatAux.permission.tool.deletePath': 'Löschen (rekursiv)',
  'chatAux.permission.tool.listDir': 'Ordner auflisten',
  'chatAux.permission.tool.makeDir': 'Ordner erstellen',
  'chatAux.permission.tool.movePath': 'Verschieben/Umbenennen',
  'chatAux.permission.tool.statPath': 'Datei-Info lesen',
  'chatAux.permission.tool.grepSearch': 'Projekt durchsuchen',
  'chatAux.permission.tool.findFiles': 'Dateien suchen',
  'chatAux.permission.tool.runCommand': 'Befehl ausführen',

  // Model management and selectors
  'chatAux.modelManagement.folderNameHint': 'Ordnername...',
  'chatAux.modelManagement.chooseColor': 'Farbe auswählen:',
  'chatAux.modelManagement.catalogTitle': 'Modell-Katalog',
  'chatAux.modelManagement.allModels': 'Alle Modelle',
  'chatAux.modelManagement.categories': 'KATEGORIEN',
  'chatAux.modelManagement.inputFade': 'EINGABE-BLENDE (AB X MODELLE)',
  'chatAux.modelManagement.thresholdSmall': 'Klein',
  'chatAux.modelManagement.thresholdMedium': 'Mittel',
  'chatAux.modelManagement.thresholdLarge': 'Groß',
  'chatAux.modelManagement.searchHint': 'Modell suchen...',
  'chatAux.modelManagement.noModels': 'Keine Modelle gefunden.',
  'chatAux.modelManagement.moveToFolder': 'In Ordner verschieben',
  'chatAux.botPicker.automatic': 'Automatisch',
  'chatAux.botPicker.selectionLabel': 'Bot auswählen: {label}',
  'chatAux.botPicker.select': 'Bot auswählen',
  'chatAux.botPicker.lockedModelTooltip':
      'Dieser Bot verwendet immer sein fest gebundenes Modell',
  'chatAux.botPicker.autoDescription': 'Bot anhand der Nachricht auswählen',
  'chatAux.botPicker.normalModelDescription':
      'Verwendet die normale Modellauswahl',
  'chatAux.botPicker.fixedModelDescription': 'Fest verbunden: {model}',
  'chatAux.modelPicker.plannedPlacement': 'Geplant: {placement}',
  'chatAux.modelPicker.localStarting':
      'Lokal • Ausgeschaltet – startet bei Auswahl',
  'chatAux.modelPicker.localUnavailable': 'Lokal • Derzeit nicht bereit',
  'chatAux.modelPicker.providerInactive': '{provider} • Derzeit nicht aktiv',
  'chatAux.modelPicker.boundLocalUnavailable':
      'Lokal • Gebundenes Modell ist nicht verfügbar',
  'chatAux.modelPicker.boundProviderInactive':
      '{provider} • Gebundenes Modell ist nicht aktiv',
  'chatAux.modelPicker.newChatTooltip': 'Modell für einen neuen Chat auswählen',
  'chatAux.modelPicker.select': 'Modell auswählen',
  'chatAux.modelPicker.searching': 'Modelle werden gesucht…',
  'chatAux.modelPicker.title': 'Chat-Modell auswählen',
  'chatAux.modelPicker.noneAvailable': 'Noch kein Modell verfügbar',

  // Miscellaneous chat components
  'chatAux.fileChange.diffSkipped': 'Diff übersprungen (Datei zu groß)',
  'chatAux.reasoning.title': 'Gedankengang',
  'chatAux.reasoning.titleWithWords': 'Gedankengang · {count} Wörter',
  'chatAux.visual.defaultTitle': 'Visualisierung',
  'chatAux.visual.invalidJson': 'Die KI-Grafik enthält kein gültiges JSON.',
  'chatAux.visual.valueFallback': 'Wert {number}',
};

const Map<String, String> chatAuxStringsEn = {
  // Markdown and code previews
  'chatAux.markdown.codePreview': '{count} lines of code • Click to view',
  'chatAux.markdown.linkOpenFailed': 'Could not open link',
  'chatAux.markdown.linkOpenFailedWithUrl': 'Could not open link: {url}',
  'chatAux.markdown.sourceCopied': 'Source copied',
  'chatAux.markdown.plainText': 'TEXT',
  'chatAux.markdown.preview': 'Preview',
  'chatAux.markdown.source': 'Source',
  'chatAux.markdown.copySource': 'Copy source',
  'chatAux.code.defaultLanguage': 'CODE',
  'chatAux.code.view': 'View',

  // Local model warm-up
  'chatAux.warmup.placementPending': 'Placement is being planned',
  'chatAux.warmup.waiting': 'Please wait – model is warming up',
  'chatAux.warmup.cancelled': 'Model start was cancelled',
  'chatAux.warmup.semanticProgress': '{model}: {percent} percent, {phase}',
  'chatAux.warmup.startFailed': 'The model could not be started',
  'chatAux.warmup.queuePosition': 'Queue: {position}',
  'chatAux.warmup.chooseAnother': 'Choose another model',
  'chatAux.warmup.changeBinding': 'Change binding',
  'chatAux.warmup.phase.queued': 'Waiting for safe resources',
  'chatAux.warmup.phase.admission': 'Checking resource admission',
  'chatAux.warmup.phase.preparingRuntime': 'Preparing runtime',
  'chatAux.warmup.phase.runtimeReady': 'Runtime is ready',
  'chatAux.warmup.phase.refreshingPlan': 'Rechecking memory plan',
  'chatAux.warmup.phase.evicting': 'Unloading unused model',
  'chatAux.warmup.phase.startingInstances': 'Coordinating model start',
  'chatAux.warmup.phase.launchingWorker': 'Starting model process',
  'chatAux.warmup.phase.loadingModel': 'Loading model weights',
  'chatAux.warmup.phase.workerInitializing':
      'Health check: model server is starting',
  'chatAux.warmup.phase.workerReady': 'Health check successful',
  'chatAux.warmup.phase.verifyingWorker': 'Checking mini inference',
  'chatAux.warmup.phase.instanceVerified': 'Mini inference successful',
  'chatAux.warmup.phase.resourcePlan': 'Checking memory plan',
  'chatAux.warmup.phase.healthcheck': 'Model server health check is running',
  'chatAux.warmup.phase.preparing': 'Preparing model start',

  // Permission requests
  'chatAux.permission.title': 'Access request',
  'chatAux.permission.body':
      'PhiloBot wants to work outside the project path ({tool}):',
  'chatAux.permission.allowOnce': 'Allow once',
  'chatAux.permission.allowSession': 'Allow for session',
  'chatAux.permission.tool.readFile': 'Read file',
  'chatAux.permission.tool.writeFile': 'Write file',
  'chatAux.permission.tool.patchFile': 'Modify file',
  'chatAux.permission.tool.deletePath': 'Delete (recursively)',
  'chatAux.permission.tool.listDir': 'List folder',
  'chatAux.permission.tool.makeDir': 'Create folder',
  'chatAux.permission.tool.movePath': 'Move/rename',
  'chatAux.permission.tool.statPath': 'Read file info',
  'chatAux.permission.tool.grepSearch': 'Search project',
  'chatAux.permission.tool.findFiles': 'Find files',
  'chatAux.permission.tool.runCommand': 'Run command',

  // Model management and selectors
  'chatAux.modelManagement.folderNameHint': 'Folder name...',
  'chatAux.modelManagement.chooseColor': 'Choose color:',
  'chatAux.modelManagement.catalogTitle': 'Model catalog',
  'chatAux.modelManagement.allModels': 'All models',
  'chatAux.modelManagement.categories': 'CATEGORIES',
  'chatAux.modelManagement.inputFade': 'INPUT FADE (FROM X MODELS)',
  'chatAux.modelManagement.thresholdSmall': 'Small',
  'chatAux.modelManagement.thresholdMedium': 'Medium',
  'chatAux.modelManagement.thresholdLarge': 'Large',
  'chatAux.modelManagement.searchHint': 'Search models...',
  'chatAux.modelManagement.noModels': 'No models found.',
  'chatAux.modelManagement.moveToFolder': 'Move to folder',
  'chatAux.botPicker.automatic': 'Automatic',
  'chatAux.botPicker.selectionLabel': 'Select bot: {label}',
  'chatAux.botPicker.select': 'Select bot',
  'chatAux.botPicker.lockedModelTooltip':
      'This bot always uses its bound model',
  'chatAux.botPicker.autoDescription': 'Select a bot based on the message',
  'chatAux.botPicker.normalModelDescription': 'Uses the normal model selection',
  'chatAux.botPicker.fixedModelDescription': 'Bound: {model}',
  'chatAux.modelPicker.plannedPlacement': 'Planned: {placement}',
  'chatAux.modelPicker.localStarting': 'Local • Off – starts on selection',
  'chatAux.modelPicker.localUnavailable': 'Local • Currently unavailable',
  'chatAux.modelPicker.providerInactive': '{provider} • Currently inactive',
  'chatAux.modelPicker.boundLocalUnavailable':
      'Local • Bound model is unavailable',
  'chatAux.modelPicker.boundProviderInactive':
      '{provider} • Bound model is inactive',
  'chatAux.modelPicker.newChatTooltip': 'Select a model for a new chat',
  'chatAux.modelPicker.select': 'Select model',
  'chatAux.modelPicker.searching': 'Searching for models…',
  'chatAux.modelPicker.title': 'Select chat model',
  'chatAux.modelPicker.noneAvailable': 'No model available yet',

  // Miscellaneous chat components
  'chatAux.fileChange.diffSkipped': 'Diff skipped (file too large)',
  'chatAux.reasoning.title': 'Reasoning',
  'chatAux.reasoning.titleWithWords': 'Reasoning · {count} words',
  'chatAux.visual.defaultTitle': 'Visualization',
  'chatAux.visual.invalidJson': 'The AI graphic contains invalid JSON.',
  'chatAux.visual.valueFallback': 'Value {number}',
};

/// Translates a chat auxiliary key and falls back to the established app maps.
///
/// Keeping this wrapper local lets the migration remain isolated while old and
/// new chat keys can be used uniformly as `tr('…')`.
String tr(String key, [Map<String, String>? params]) {
  final strings = base.appLanguage == 'en'
      ? chatAuxStringsEn
      : chatAuxStringsDe;
  var value = strings[key] ?? base.AppStrings.tr(key);
  if (params != null) {
    params.forEach((name, replacement) {
      value = value.replaceAll('{$name}', replacement);
    });
  }
  return value;
}
