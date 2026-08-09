import '../../core/app_strings.dart' as base;

const Map<String, String> botManagementStringsDe = {
  'botManagement.notification.lockedSave':
      'Der Bot-Builder ist gesperrt und kann nicht bearbeitet werden.',
  'botManagement.notification.saveError': 'Fehler beim Speichern',
  'botManagement.notification.deleteError': 'Fehler beim Löschen',
  'botManagement.delete.title': 'Bot löschen?',
  'botManagement.list.unnamed': 'Unbenannt',
  'botManagement.list.default': 'Standard',
  'botManagement.list.locked': 'Gesperrt',
  'botManagement.list.triggers': 'Trigger: {keywords}',
  'botManagement.list.defaultWithoutKeywords':
      'Triggert standardmäßig ohne Keywords',
  'botManagement.list.noTriggers': 'Keine Trigger',

  'botManagement.binding.normalSelection': 'Normale Chat-Modellauswahl',
  'botManagement.binding.usesChatModel':
      'Der Bot verwendet das im Chat ausgewählte Modell.',
  'botManagement.binding.local': 'Lokal',
  'botManagement.binding.modelSubtitle': '{provider} • {model}',
  'botManagement.binding.title': 'FESTE MODELLBINDUNG',
  'botManagement.binding.selectionLabel':
      'Feste Modellbindung auswählen: {title}',
  'botManagement.binding.choiceLabel': '{provider}: {model}',
  'botManagement.binding.overridesSelection':
      'Eine feste Bindung überschreibt im Chat immer die normale Modellauswahl.',
  'botManagement.binding.sheetTitle': 'Modell fest mit Bot verbinden',
  'botManagement.binding.none': 'Keine feste Bindung',

  'botManagement.editor.empty': 'Wähle einen Bot aus oder erstelle einen neuen',
  'botManagement.editor.configureTitle': 'Bot konfigurieren: {name}',
  'botManagement.editor.lockedTitle': 'Bot-Builder gesperrt',
  'botManagement.editor.lockedBody':
      'Der Bot-Builder ist ein gesperrter System-Bot. Du kannst ihn ansehen, aber nicht bearbeiten oder speichern.',

  'botManagement.name.label': 'BOT-NAME',
  'botManagement.name.tooltip':
      'Der Name dieses Bots. Er wird im Chat über den Antworten des Assistenten eingeblendet.',
  'botManagement.name.hint': 'Z. B. MatheBot...',
  'botManagement.name.required': 'Name ist erforderlich',
  'botManagement.default.label': 'ALS STANDARD-BOT FESTLEGEN',
  'botManagement.default.tooltip':
      'Dieser Bot antwortet auf alle Nachrichten, die keine Schlüsselwörter von anderen Bots triggern. Es kann immer nur ein Bot als Standard festgelegt sein.',
  'botManagement.default.active':
      'Dieser Bot ist der aktive Standard-Bot (kann nicht direkt deaktiviert werden)',
  'botManagement.default.enable':
      'Als Standard-Bot aktivieren (ersetzt vorherigen)',
  'botManagement.default.inactive':
      'Diesen Bot standardmäßig verwenden, wenn kein Keyword passt',

  'botManagement.style.label': 'ANTWORTSTIL',
  'botManagement.style.tooltip':
      'Legt fest, wie dieser Bot standardmäßig antwortet. Der Stil gehört zum Bot und wird im Chat automatisch verwendet.',
  'botManagement.style.balanced': 'Ausgewogen',
  'botManagement.style.short': 'Kurz',
  'botManagement.style.explain': 'Erklärend',
  'botManagement.style.steps': 'Schritte',
  'botManagement.style.critical': 'Kritisch',
  'botManagement.style.brainstorm': 'Brainstorm',
  'botManagement.agentic.label': 'AGENTIC AKTIVIEREN',
  'botManagement.agentic.tooltip':
      'Erlaubt diesem Bot, den agentischen Spark-gRPC-Pfad mit Tools und Planung zu verwenden.',
  'botManagement.agentic.enabled': 'Agentic ist für diesen Bot freigegeben',
  'botManagement.agentic.disabled': 'Normaler Chat bleibt Standard',
  'botManagement.agentic.rootsHint': 'Erlaubte Pfade, kommagetrennt',

  'botManagement.keywords.label': 'TRIGGER-KEYWORDS (KOMMAGETRENNT)',
  'botManagement.keywords.tooltip':
      'Schlüsselwörter, nach denen im Text gesucht wird. Beispiel: „mathe, rechnen“. Falls der Benutzer eines dieser Wörter tippt, antwortet dieser Bot. Standard-Bots benötigen dies nicht zwingend, können aber Keywords haben.',
  'botManagement.keywords.defaultHint':
      'Optional für Standard-Bot, z. B. mathe, rechnen...',
  'botManagement.keywords.hint': 'Z. B. mathe, rechnen, formel...',
  'botManagement.keywords.required':
      'Mindestens ein Trigger-Keyword ist erforderlich',
  'botManagement.prompt.label': 'SYSTEM-INSTRUCTIONS (PROMPTS)',
  'botManagement.prompt.tooltip':
      'Definiert das Verhalten und die Identität des Modells für diesen Bot. Anweisungen können Rolle, Sprachstil, Fachgebiet oder Formatierungsregeln festlegen.',
  'botManagement.prompt.hint':
      'Gib dem Bot Anweisungen, wer er ist und wie er sich verhalten soll...',
  'botManagement.prompt.required': 'Anweisungen sind erforderlich',
};

const Map<String, String> botManagementStringsEn = {
  'botManagement.notification.lockedSave':
      'The Bot Builder is locked and cannot be edited.',
  'botManagement.notification.saveError': 'Error while saving',
  'botManagement.notification.deleteError': 'Error while deleting',
  'botManagement.delete.title': 'Delete bot?',
  'botManagement.list.unnamed': 'Unnamed',
  'botManagement.list.default': 'Default',
  'botManagement.list.locked': 'Locked',
  'botManagement.list.triggers': 'Triggers: {keywords}',
  'botManagement.list.defaultWithoutKeywords':
      'Triggers by default without keywords',
  'botManagement.list.noTriggers': 'No triggers',

  'botManagement.binding.normalSelection': 'Normal chat model selection',
  'botManagement.binding.usesChatModel':
      'The bot uses the model selected in chat.',
  'botManagement.binding.local': 'Local',
  'botManagement.binding.modelSubtitle': '{provider} • {model}',
  'botManagement.binding.title': 'FIXED MODEL BINDING',
  'botManagement.binding.selectionLabel': 'Select fixed model binding: {title}',
  'botManagement.binding.choiceLabel': '{provider}: {model}',
  'botManagement.binding.overridesSelection':
      'A fixed binding always overrides the normal chat model selection.',
  'botManagement.binding.sheetTitle': 'Bind model to bot',
  'botManagement.binding.none': 'No fixed binding',

  'botManagement.editor.empty': 'Select a bot or create a new one',
  'botManagement.editor.configureTitle': 'Configure bot: {name}',
  'botManagement.editor.lockedTitle': 'Bot Builder locked',
  'botManagement.editor.lockedBody':
      'The Bot Builder is a locked system bot. You can view it, but cannot edit or save it.',

  'botManagement.name.label': 'BOT NAME',
  'botManagement.name.tooltip':
      'This bot’s name is shown above assistant responses in chat.',
  'botManagement.name.hint': 'e.g. MathBot...',
  'botManagement.name.required': 'Name is required',
  'botManagement.default.label': 'SET AS DEFAULT BOT',
  'botManagement.default.tooltip':
      'This bot answers messages that do not trigger another bot’s keywords. Only one bot can be the default at a time.',
  'botManagement.default.active':
      'This bot is the active default bot (it cannot be disabled directly)',
  'botManagement.default.enable': 'Set as default bot (replaces the previous)',
  'botManagement.default.inactive':
      'Use this bot by default when no keyword matches',

  'botManagement.style.label': 'RESPONSE STYLE',
  'botManagement.style.tooltip':
      'Sets how this bot responds by default. The style belongs to the bot and is automatically used in chat.',
  'botManagement.style.balanced': 'Balanced',
  'botManagement.style.short': 'Short',
  'botManagement.style.explain': 'Explanatory',
  'botManagement.style.steps': 'Step by step',
  'botManagement.style.critical': 'Critical',
  'botManagement.style.brainstorm': 'Brainstorm',
  'botManagement.agentic.label': 'ENABLE AGENTIC MODE',
  'botManagement.agentic.tooltip':
      'Allows this bot to use the agentic Spark gRPC path with tools and planning.',
  'botManagement.agentic.enabled': 'Agentic mode is enabled for this bot',
  'botManagement.agentic.disabled': 'Normal chat remains the default',
  'botManagement.agentic.rootsHint': 'Allowed paths, comma-separated',

  'botManagement.keywords.label': 'TRIGGER KEYWORDS (COMMA-SEPARATED)',
  'botManagement.keywords.tooltip':
      'Keywords that are searched in the text. For example: “math, calculate”. If the user types one of these words, this bot responds. Default bots do not require them, but may still have keywords.',
  'botManagement.keywords.defaultHint':
      'Optional for the default bot, e.g. math, calculate...',
  'botManagement.keywords.hint': 'e.g. math, calculate, formula...',
  'botManagement.keywords.required': 'At least one trigger keyword is required',
  'botManagement.prompt.label': 'SYSTEM INSTRUCTIONS (PROMPTS)',
  'botManagement.prompt.tooltip':
      'Defines this bot’s behavior and identity. Instructions can set its role, language style, domain knowledge, or formatting rules.',
  'botManagement.prompt.hint':
      'Tell the bot who it is and how it should behave...',
  'botManagement.prompt.required': 'Instructions are required',
};

String tr(String key, [Map<String, String>? params]) {
  final strings = base.appLanguage == 'en'
      ? botManagementStringsEn
      : botManagementStringsDe;
  var value = strings[key] ?? base.AppStrings.tr(key);
  if (params != null) {
    params.forEach((name, replacement) {
      value = value.replaceAll('{$name}', replacement);
    });
  }
  return value;
}
