import '../../core/app_strings.dart' as base;

const Map<String, String> marketplaceScreenStringsDe = {
  'marketplaceScreen.searchHint': 'Suche nach Modellen, Anbietern oder Tags...',
  'marketplaceScreen.search.submit': 'Suche ausführen',
  'marketplaceScreen.search.open': 'Modelle suchen',
  'marketplaceScreen.view.grid': 'Grid',
  'marketplaceScreen.view.list': 'Liste',
  'marketplaceScreen.wiki.title': 'Marketplace-Wiki',
  'marketplaceScreen.wiki.close': 'Schließen',
  'marketplaceScreen.wiki.intro':
      'Die wichtigsten Begriffe kurz erklärt – damit du ein Modell auch ohne Vorkenntnisse auswählen kannst.',
  'marketplaceScreen.wiki.quickStart':
      'Schnellstart: Für ein lokales erstes Modell wähle HuggingFace → Chat → Q4_K_M. Öffne danach die Details und prüfe Speicher, Zielordner und Downloadgröße.',
  'marketplaceScreen.wiki.categoryTitle': 'Kategorie & Tags',
  'marketplaceScreen.wiki.categoryText':
      'Chat ist für Gespräche, Code für Programmierung, Reasoning für komplexes Denken, Vision für Bilder und Embedding für Suche.',
  'marketplaceScreen.wiki.providerTitle': 'Provider wählen',
  'marketplaceScreen.wiki.providerText':
      'HuggingFace liefert Dateien zum lokalen Download. OpenRouter und Featherless sind Cloud-Anbieter: Das Modell läuft dort und braucht einen hinterlegten API-Token.',
  'marketplaceScreen.wiki.quantizationTitle': 'Quantisierung',
  'marketplaceScreen.wiki.quantizationText':
      'Q4 ist meist der beste Kompromiss. Q8/FP16 brauchen mehr Speicher, liefern aber etwas mehr Qualität. Kleinere Q2/Q3 sparen Platz.',
  'marketplaceScreen.wiki.formatsTitle': 'Dateiformate',
  'marketplaceScreen.wiki.formatsText':
      'GGUF ist meist die passende Datei für lokale LLM-Programme. Safetensors kann aus mehreren Fragmenten bestehen – sie werden im Marketplace als eine Variante zusammengefasst und gemeinsam geladen.',
  'marketplaceScreen.wiki.vramTitle': 'VRAM & Kontext',
  'marketplaceScreen.wiki.vramText':
      'VRAM ist der Grafikspeicher. Ein leerer VRAM-Wert bedeutet: Die Dateigröße ist unbekannt, deshalb wird nichts geschätzt. CTX beschreibt die maximale Gesprächslänge.',
  'marketplaceScreen.wiki.downloadsTitle': 'Lokale Downloads',
  'marketplaceScreen.wiki.downloadsText':
      'Im Download-Slider siehst du Fortschritt, Geschwindigkeit, Zielordner und ob ein Provider-Token im Backend hinterlegt ist.',
  'marketplaceScreen.downloads.close': 'Downloads schließen',
  'marketplaceScreen.downloads.title': 'Downloads & Verlauf',
  'marketplaceScreen.filters.title': 'Filter',
  'marketplaceScreen.filters.activeTitle': 'Aktive Filter',
  'marketplaceScreen.filters.statusDefault':
      'Keine aktiven Filter (Standardansicht)',
  'marketplaceScreen.filters.provider': 'Provider',
  'marketplaceScreen.filters.category': 'Kategorie',
  'marketplaceScreen.filters.sort': 'Sortierung',
  'marketplaceScreen.filters.localOnly': 'Nur lokal',
  'marketplaceScreen.filters.gpuOnly': 'Auf deiner GPU',
  'marketplaceScreen.filters.quantization': 'Quant',
  'marketplaceScreen.filter.all': 'Alle',
  'marketplaceScreen.filter.chat': 'Chat',
  'marketplaceScreen.filter.code': 'Code',
  'marketplaceScreen.filter.reasoning': 'Reasoning',
  'marketplaceScreen.filter.vision': 'Vision',
  'marketplaceScreen.filter.embedding': 'Embedding',
  'marketplaceScreen.sort.popularity': 'Beliebtheit',
  'marketplaceScreen.sort.intelligence': 'Intelligence-Score',
  'marketplaceScreen.sort.context': 'Kontext',
  'marketplaceScreen.sort.newest': 'Neu zuerst',
  'marketplaceScreen.sort.priceLowHigh': 'Preis: Niedrig → Hoch',
  'marketplaceScreen.sort.priceHighLow': 'Preis: Hoch → Niedrig',
  'marketplaceScreen.error.network':
      'Netzwerkfehler – ist das Backend erreichbar?',
  'marketplaceScreen.error.timeout':
      'Zeitüberschreitung – bitte erneut versuchen.',
  'marketplaceScreen.error.huggingFaceToken':
      'Dieser HuggingFace-Download braucht einen gültigen API-Token. Bitte den Token unter Einstellungen → HuggingFace API-Token hinterlegen und den Zugriff auf das Modell bei HuggingFace bestätigen.',
  'marketplaceScreen.error.invalidInput': 'Ungültige Eingabe.',
  'marketplaceScreen.error.chooseProvider': 'Bitte Provider auswählen.',
  'marketplaceScreen.error.unknown': 'Unbekannter Fehler',
  'marketplaceScreen.error.modelIdMissing': 'Modell-ID fehlt',
  'marketplaceScreen.error.concreteProvider':
      'Bitte einen konkreten Provider auswählen',
  'marketplaceScreen.error.providerMissing': 'Provider fehlt',
  'marketplaceScreen.notification.jobDeleted': 'Eintrag gelöscht',
  'marketplaceScreen.notification.alreadyDownloading':
      'Modell wird bereits heruntergeladen (Job {jobId})',
  'marketplaceScreen.notification.downloadStarted':
      '{modelId}: Download gestartet',
  'marketplaceScreen.notification.downloadStartedOnNode':
      '{modelId}: Download auf {node} gestartet',
  'marketplaceScreen.downloads.onNode': 'Auf {node}',
  'marketplaceScreen.notification.chatStarted': '{name} im Chat gestartet',
  'marketplaceScreen.notification.actionTimedOut':
      'Aktion abgebrochen: Zeitüberschreitung',
  'marketplaceScreen.download.pickVariant': 'Variante für „{modelId}“ wählen',
  'marketplaceScreen.download.variantExplanation':
      'Modelle gibt es in verschiedenen Quantisierungen – das ist wie die Kompression bei Bildern (JPG vs. PNG). Kleinere Dateien brauchen weniger Speicher, haben aber leichte Qualitätsverluste. Größere Dateien liefern bessere Qualität, brauchen aber mehr RAM.',
  'marketplaceScreen.download.unknownSize': 'Unbekannte Größe',
  'marketplaceScreen.download.variant': 'Variante {number}',
  'marketplaceScreen.download.balanced': 'AUSGEWOGEN',
  'marketplaceScreen.download.maxQuality': 'MAX. QUALITÄT',
  'marketplaceScreen.download.compact': 'KOMPAKT',
  'marketplaceScreen.action.retrySearch': 'Erneut suchen',
  'marketplaceScreen.action.retry': 'Erneut versuchen',
  'marketplaceScreen.results.empty': 'Keine Modelle gefunden.',
  'marketplaceScreen.results.loadFailed': 'Nachladen fehlgeschlagen',
  'marketplaceScreen.results.loadingMore': 'Weitere Modelle werden geladen …',
  'marketplaceScreen.results.loadMore': 'Weitere Modelle laden',
  'marketplaceScreen.model.fallbackName': 'Modell',
  'marketplaceScreen.model.noDescription': 'Keine Beschreibung verfügbar.',
  'marketplaceScreen.model.score': '{score} IQ',
  'marketplaceScreen.model.vram': '{prefix}{value} GB VRAM',
  'marketplaceScreen.model.recommendation': '{score} Empfehlung',
  'marketplaceScreen.model.hits': '{count} Hits',
  'marketplaceScreen.model.add': 'Hinzufügen',
  'marketplaceScreen.model.download': 'Download',
  'marketplaceScreen.model.details': 'Details',
  'marketplaceScreen.hardware.title': 'Hardware-Profil',
  'marketplaceScreen.hardware.loadFailed': 'Profil konnte nicht geladen werden',
  'marketplaceScreen.hardware.gpuDetected': 'GPU erkannt',
  'marketplaceScreen.hardware.noGpuDetected': 'Keine GPU erkannt',
  'marketplaceScreen.downloads.jobsLoadFailed':
      'Jobs konnten nicht geladen werden',
  'marketplaceScreen.downloads.empty': 'Keine Downloads vorhanden.',
  'marketplaceScreen.backendAccess': 'Backend-Zugang',
  'marketplaceScreen.modelDirectoryInvalid': 'Modellordner ist ungültig',
  'marketplaceScreen.downloads.unknownModel': 'Unbekanntes Modell',
  'marketplaceScreen.downloads.queued': 'Warteschlange …',
  'marketplaceScreen.action.cancel': 'Abbrechen',
  'marketplaceScreen.downloads.target': 'Ziel: {target}',
  'marketplaceScreen.action.delete': 'Löschen',
  'marketplaceScreen.token.configured':
      '{provider}-Token ist im Backend gesetzt',
  'marketplaceScreen.token.missing': '{provider}-Token fehlt im Backend',
  'marketplaceScreen.token.badgeConfigured': '{provider} gesetzt',
  'marketplaceScreen.token.badgeMissing': '{provider} fehlt',
  'marketplaceScreen.price.in': 'IN {value}',
  'marketplaceScreen.price.out': 'OUT {value}',
  'marketplaceScreen.price.local': 'Lokal',
  'marketplaceScreen.price.free': 'Gratis',
  'marketplaceScreen.price.perMillion': '{price} / 1M Tokens',
  'marketplaceScreen.filterHelp.provider':
      'Quelle des Modells: lokale Dateien oder Cloud-Anbieter.',
  'marketplaceScreen.filterHelp.category':
      'Grenzt Modelle nach ihrem hauptsächlichen Einsatzgebiet ein. Die Tags auf den Karten verwenden dieselben Kategorien.',
  'marketplaceScreen.filterHelp.quantization':
      'Kleinere Quantisierungen sparen Speicher, größere erhalten mehr Qualität.',
  'marketplaceScreen.filterHelp.default': 'Filter für die Modellliste.',
};

const Map<String, String> marketplaceScreenStringsEn = {
  'marketplaceScreen.searchHint': 'Search models, providers, or tags...',
  'marketplaceScreen.search.submit': 'Run search',
  'marketplaceScreen.search.open': 'Search models',
  'marketplaceScreen.view.grid': 'Grid',
  'marketplaceScreen.view.list': 'List',
  'marketplaceScreen.wiki.title': 'Marketplace wiki',
  'marketplaceScreen.wiki.close': 'Close',
  'marketplaceScreen.wiki.intro':
      'A short explanation of the key terms, so you can choose a model even without prior knowledge.',
  'marketplaceScreen.wiki.quickStart':
      'Quick start: for a first local model, choose HuggingFace → Chat → Q4_K_M. Then open the details and check memory, target folder, and download size.',
  'marketplaceScreen.wiki.categoryTitle': 'Category & tags',
  'marketplaceScreen.wiki.categoryText':
      'Chat is for conversation, Code for programming, Reasoning for complex thinking, Vision for images, and Embedding for search.',
  'marketplaceScreen.wiki.providerTitle': 'Choose provider',
  'marketplaceScreen.wiki.providerText':
      'HuggingFace provides files for local download. OpenRouter and Featherless are cloud providers: the model runs there and needs a configured API token.',
  'marketplaceScreen.wiki.quantizationTitle': 'Quantization',
  'marketplaceScreen.wiki.quantizationText':
      'Q4 is usually the best compromise. Q8/FP16 need more memory but provide slightly higher quality. Smaller Q2/Q3 variants save space.',
  'marketplaceScreen.wiki.formatsTitle': 'File formats',
  'marketplaceScreen.wiki.formatsText':
      'GGUF is usually the right file for local LLM programs. Safetensors can consist of several fragments; the Marketplace groups and downloads them together as one variant.',
  'marketplaceScreen.wiki.vramTitle': 'VRAM & context',
  'marketplaceScreen.wiki.vramText':
      'VRAM is graphics memory. An empty VRAM value means the file size is unknown, so no estimate is made. CTX describes the maximum conversation length.',
  'marketplaceScreen.wiki.downloadsTitle': 'Local downloads',
  'marketplaceScreen.wiki.downloadsText':
      'The download drawer shows progress, speed, the target folder, and whether a provider token is configured in the backend.',
  'marketplaceScreen.downloads.close': 'Close downloads',
  'marketplaceScreen.downloads.title': 'Downloads & history',
  'marketplaceScreen.filters.title': 'Filters',
  'marketplaceScreen.filters.activeTitle': 'Active filters',
  'marketplaceScreen.filters.statusDefault': 'No active filters (default view)',
  'marketplaceScreen.filters.provider': 'Provider',
  'marketplaceScreen.filters.category': 'Category',
  'marketplaceScreen.filters.sort': 'Sort',
  'marketplaceScreen.filters.localOnly': 'Local only',
  'marketplaceScreen.filters.gpuOnly': 'On your GPU',
  'marketplaceScreen.filters.quantization': 'Quantization',
  'marketplaceScreen.filter.all': 'All',
  'marketplaceScreen.filter.chat': 'Chat',
  'marketplaceScreen.filter.code': 'Code',
  'marketplaceScreen.filter.reasoning': 'Reasoning',
  'marketplaceScreen.filter.vision': 'Vision',
  'marketplaceScreen.filter.embedding': 'Embedding',
  'marketplaceScreen.sort.popularity': 'Popularity',
  'marketplaceScreen.sort.intelligence': 'Intelligence score',
  'marketplaceScreen.sort.context': 'Context',
  'marketplaceScreen.sort.newest': 'Newest first',
  'marketplaceScreen.sort.priceLowHigh': 'Price: low → high',
  'marketplaceScreen.sort.priceHighLow': 'Price: high → low',
  'marketplaceScreen.error.network':
      'Network error – is the backend reachable?',
  'marketplaceScreen.error.timeout': 'Request timed out – please try again.',
  'marketplaceScreen.error.huggingFaceToken':
      'This HuggingFace download requires a valid API token. Add it under Settings → HuggingFace API token and confirm access to the model on HuggingFace.',
  'marketplaceScreen.error.invalidInput': 'Invalid input.',
  'marketplaceScreen.error.chooseProvider': 'Please select a provider.',
  'marketplaceScreen.error.unknown': 'Unknown error',
  'marketplaceScreen.error.modelIdMissing': 'Model ID is missing',
  'marketplaceScreen.error.concreteProvider':
      'Please select a specific provider',
  'marketplaceScreen.error.providerMissing': 'Provider is missing',
  'marketplaceScreen.notification.jobDeleted': 'Entry deleted',
  'marketplaceScreen.notification.alreadyDownloading':
      'The model is already downloading (job {jobId})',
  'marketplaceScreen.notification.downloadStarted':
      '{modelId}: download started',
  'marketplaceScreen.notification.downloadStartedOnNode':
      '{modelId}: download started on {node}',
  'marketplaceScreen.downloads.onNode': 'On {node}',
  'marketplaceScreen.notification.chatStarted': '{name} started in chat',
  'marketplaceScreen.notification.actionTimedOut':
      'Action cancelled: request timed out',
  'marketplaceScreen.download.pickVariant': 'Choose a variant for “{modelId}”',
  'marketplaceScreen.download.variantExplanation':
      'Models come in different quantizations – similar to image compression (JPG vs. PNG). Smaller files use less storage but lose a little quality. Larger files provide better quality but need more RAM.',
  'marketplaceScreen.download.unknownSize': 'Unknown size',
  'marketplaceScreen.download.variant': 'Variant {number}',
  'marketplaceScreen.download.balanced': 'BALANCED',
  'marketplaceScreen.download.maxQuality': 'MAX QUALITY',
  'marketplaceScreen.download.compact': 'COMPACT',
  'marketplaceScreen.action.retrySearch': 'Search again',
  'marketplaceScreen.action.retry': 'Try again',
  'marketplaceScreen.results.empty': 'No models found.',
  'marketplaceScreen.results.loadFailed': 'Could not load more models',
  'marketplaceScreen.results.loadingMore': 'Loading more models …',
  'marketplaceScreen.results.loadMore': 'Load more models',
  'marketplaceScreen.model.fallbackName': 'Model',
  'marketplaceScreen.model.noDescription': 'No description available.',
  'marketplaceScreen.model.score': '{score} IQ',
  'marketplaceScreen.model.vram': '{prefix}{value} GB VRAM',
  'marketplaceScreen.model.recommendation': '{score} recommendation',
  'marketplaceScreen.model.hits': '{count} hits',
  'marketplaceScreen.model.add': 'Add',
  'marketplaceScreen.model.download': 'Download',
  'marketplaceScreen.model.details': 'Details',
  'marketplaceScreen.hardware.title': 'Hardware profile',
  'marketplaceScreen.hardware.loadFailed': 'Could not load profile',
  'marketplaceScreen.hardware.gpuDetected': 'GPU detected',
  'marketplaceScreen.hardware.noGpuDetected': 'No GPU detected',
  'marketplaceScreen.downloads.jobsLoadFailed': 'Could not load jobs',
  'marketplaceScreen.downloads.empty': 'No downloads yet.',
  'marketplaceScreen.backendAccess': 'Backend access',
  'marketplaceScreen.modelDirectoryInvalid': 'Model folder is invalid',
  'marketplaceScreen.downloads.unknownModel': 'Unknown model',
  'marketplaceScreen.downloads.queued': 'Queued …',
  'marketplaceScreen.action.cancel': 'Cancel',
  'marketplaceScreen.downloads.target': 'Target: {target}',
  'marketplaceScreen.action.delete': 'Delete',
  'marketplaceScreen.token.configured':
      '{provider} token is configured in the backend',
  'marketplaceScreen.token.missing':
      '{provider} token is missing in the backend',
  'marketplaceScreen.token.badgeConfigured': '{provider} configured',
  'marketplaceScreen.token.badgeMissing': '{provider} missing',
  'marketplaceScreen.price.in': 'IN {value}',
  'marketplaceScreen.price.out': 'OUT {value}',
  'marketplaceScreen.price.local': 'Local',
  'marketplaceScreen.price.free': 'Free',
  'marketplaceScreen.price.perMillion': '{price} / 1M tokens',
  'marketplaceScreen.filterHelp.provider':
      'Source of the model: local files or cloud providers.',
  'marketplaceScreen.filterHelp.category':
      'Narrows models by their primary use case. Tags on the cards use the same categories.',
  'marketplaceScreen.filterHelp.quantization':
      'Smaller quantizations save storage, while larger ones preserve more quality.',
  'marketplaceScreen.filterHelp.default': 'Filters for the model list.',
};

String tr(String key, [Map<String, String>? params]) {
  final strings = base.appLanguage == 'en'
      ? marketplaceScreenStringsEn
      : marketplaceScreenStringsDe;
  var value = strings[key] ?? marketplaceScreenStringsDe[key] ?? key;
  params?.forEach((name, replacement) {
    value = value.replaceAll('{$name}', replacement);
  });
  return value;
}
