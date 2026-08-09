import '../../core/app_strings.dart' show appLanguage;

const Map<String, String> engineScreenStringsDe = {
  'engineScreen.notification.modelsStarted':
      '{count} Modelle wurden gestartet und sind bereit.',
  'engineScreen.default.model': 'Das Modell',
  'engineScreen.notification.modelStarted':
      '„{name}“ wurde gestartet und ist bereit.',
  'engineScreen.error.calculationFailed':
      'Die automatische Berechnung konnte für dieses Modell nicht abgeschlossen werden.',
  'engineScreen.error.modelDoesNotFit':
      'Das Modell passt aktuell weder vollständig in den Grafikspeicher noch gemeinsam in GPU und freien System-RAM.',
  'engineScreen.memory.gpuNotReady': 'GPU-Unterstützung noch nicht bereit',
  'engineScreen.memory.addSystemRam': 'System-RAM dazunehmen?',
  'engineScreen.memory.ramPlan': '({ram} RAM im Plan) ',
  'engineScreen.memory.gpuNotReadyContent':
      '„{model}“ wurde nicht wegen seiner Größe abgelehnt. Die Grafikkarte wurde erkannt, aber die passende GPU-Runtime ist noch nicht einsatzbereit.\n\n{issue}\n\nEin Start über CPU + System-RAM {ramPlan}ist möglich. Möchtest du diesen Fallback verwenden?',
  'engineScreen.memory.addSystemRamContent':
      '„{model}“ passt nicht allein in den freien Grafikspeicher. Die Berechnung zeigt, dass ein Start mit GPU + System-RAM {ramPlan}möglich ist.\n\nMöchtest du diesen Hybridbetrieb verwenden?',
  'engineScreen.memory.chooseOtherModel': 'Nein, anderes Modell wählen',
  'engineScreen.memory.rebuildGpuRuntime': 'GPU-Runtime neu bauen',
  'engineScreen.memory.useCpuRam': 'CPU/RAM verwenden',
  'engineScreen.memory.useRam': 'RAM verwenden',
  'engineScreen.error.gpuRuntimeRebuildFailed':
      'Die Vulkan-GPU-Runtime konnte nicht neu gebaut werden.',
  'engineScreen.action.cancel': 'Abbrechen',
  'engineScreen.model.deleteTitle': 'Modell löschen?',
  'engineScreen.model.deleteContent':
      '„{model}“ wird aus der Liste und vom Speicher entfernt. Bei einem eigenen Modellpaket wird der vollständige zugehörige Ordner einschließlich Manifesten und Zusatzdateien gelöscht. Andere Modelle bleiben erhalten.',
  'engineScreen.model.deleteConfirm': 'Endgültig löschen',
  'engineScreen.notification.modelDeleted':
      'Modell und lokale Dateien wurden gelöscht.',
  'engineScreen.notification.chooseStartableModel':
      'Bitte zuerst ein startbares Modell auswählen.',
  'engineScreen.notification.instanceScheduled':
      'Instanz wurde eingeplant. Fehlende Runtime-Komponenten werden automatisch installiert.',
  'engineScreen.notification.refreshed':
      'Meine Modelle, Speicher und lokale Modelle sind aktuell.',
  'engineScreen.notification.instanceActionScheduled':
      'Instanzaktion „{action}“ wurde eingeplant.',
  'engineScreen.notification.autoFixStarted':
      'Die automatische Korrektur wurde gestartet.',
  'engineScreen.memory.retryRamContent':
      'Der freie Grafikspeicher hat sich während der Vorbereitung geändert. Die Engine kann den Plan erneut mit dem aktuell freien System-RAM berechnen.',
  'engineScreen.memory.recalculateWithRam': 'Mit RAM neu berechnen',
  'engineScreen.notification.gpuRamRecalculated':
      'GPU und System-RAM werden neu berechnet.',
  'engineScreen.notification.runtimePreparing':
      'Die Runtime wird neu vorbereitet.',
  'engineScreen.instance.removeTitle': 'Instanz entfernen?',
  'engineScreen.instance.removeContent':
      '„{instance}“ wird gestoppt und aus der Engine entfernt.',
  'engineScreen.action.remove': 'Entfernen',
  'engineScreen.notification.instanceRemoved': 'Instanz wurde entfernt.',
  'engineScreen.context.title': 'Kontext festlegen',
  'engineScreen.context.summary':
      '{current} Token sind aktiv und durch einen echten Modellstart geprüft. {maximum} sind das rechnerische GPU+RAM-Maximum, aber noch keine Stabilitätsgarantie.',
  'engineScreen.context.help':
      'Ein höherer Wert startet das Modell neu. Falls er nicht stabil ist, sucht die Engine automatisch zwischen dem letzten bestätigten Wert und der fehlgeschlagenen Obergrenze weiter. Das kann mehrere Modellstarts dauern.',
  'engineScreen.context.checked': 'Geprüft {tokens}',
  'engineScreen.context.testEstimate': 'Schätzung {tokens} testen',
  'engineScreen.context.tokensLabel': 'Kontext-Token',
  'engineScreen.context.rangeHelper': 'Wählbar: {minimum} bis {maximum} Token',
  'engineScreen.context.invalidValue':
      'Bitte einen Wert zwischen {minimum} und {maximum} eingeben.',
  'engineScreen.context.restartAndCheck': 'Neu starten & prüfen',
  'engineScreen.notification.contextUnchanged':
      'Der bereits geprüfte Kontext bleibt unverändert.',
  'engineScreen.notification.contextIncrease':
      'Der höhere Kontext wird jetzt gestartet und auf Stabilität geprüft.',
  'engineScreen.notification.contextRestart':
      'Der Kontext wird mit einem sicheren Neustart geändert.',
  'engineScreen.sampling.title': 'Sampling-Defaults',
  'engineScreen.sampling.temperature': 'Temperatur',
  'engineScreen.sampling.topP': 'Top P',
  'engineScreen.sampling.maxOutputTokens': 'Maximale Ausgabe-Token',
  'engineScreen.sampling.applyLive': 'Live anwenden',
  'engineScreen.notification.samplingUpdated':
      'Sampling-Defaults aktualisiert.',
  'engineScreen.error.resourceConflict':
      'Dieses Modell passt mit dem aktuell freien RAM- und Grafikspeicher nicht in den Speicher. Wähle ein kleineres oder quantisiertes Modell – oder stoppe zuerst andere lokale Modelle.',
  'engineScreen.system.tab': 'SYSTEM',
  'engineScreen.system.openMonitor': 'Systemmonitor öffnen',
  'engineScreen.system.monitor': 'SYSTEMMONITOR',
  'engineScreen.telemetry.title': 'Systemmonitor',
  'engineScreen.telemetry.subtitle': 'Live-Daten der lokalen Engine',
  'engineScreen.telemetry.closeMonitor': 'Systemmonitor schließen',
  'engineScreen.telemetry.hardwareUtilization': 'HARDWARE-AUSLASTUNG',
  'engineScreen.telemetry.hardwareLoading': 'Hardwaredaten werden geladen …',
  'engineScreen.telemetry.memory': 'Arbeitsspeicher',
  'engineScreen.telemetry.memoryUsed': '{used} von {total} belegt',
  'engineScreen.telemetry.currentModelStart': 'LAUFENDER MODELLSTART',
  'engineScreen.telemetry.quiet': 'RUHIG',
  'engineScreen.telemetry.active': 'AKTIV',
  'engineScreen.telemetry.noStartActive':
      'Kein Startvorgang aktiv. Die Engine ist bereit.',
  'engineScreen.telemetry.liveModels': 'LIVE-MODELLE',
  'engineScreen.telemetry.online': '{count} ONLINE',
  'engineScreen.telemetry.noModelRunning': 'Zurzeit läuft kein Modell.',
  'engineScreen.telemetry.technicalComponents': 'TECHNISCHE KOMPONENTEN',
  'engineScreen.telemetry.componentsTooltip': 'Technische Komponenten',
  'engineScreen.operation.defaultName': 'Engine-Vorgang',
  'engineScreen.progress.complete': '{percent} % abgeschlossen',
  'engineScreen.progress.waiting': 'Wartet auf Fortschrittsdaten …',
  'engineScreen.instance.label': 'Instanz {id}',
  'engineScreen.context.auto': 'Auto-Kontext',
  'engineScreen.context.tokenCount': '{tokens} Token',
  'engineScreen.runtime.backgroundPreparing':
      'Eine Laufzeitumgebung wird im Hintergrund vorbereitet.',
  'engineScreen.progress.preparing': 'Vorbereitung läuft …',
  'engineScreen.runtime.retrySetup': 'Einrichtung erneut versuchen',
  'engineScreen.workspace.startModel': 'Modell starten',
  'engineScreen.workspace.myModels': 'Meine Modelle · {count}',
  'engineScreen.wizard.selectModel': 'Modell auswählen',
  'engineScreen.wizard.configureStart': 'Start konfigurieren',
  'engineScreen.wizard.startModel': 'Modell starten',
  'engineScreen.wizard.selectModelSubtitle':
      'Wähle ein lokales Modell für deine nächste Instanz.',
  'engineScreen.wizard.expertSubtitle':
      'Prüfe die Experteneinstellungen für dieses Modell.',
  'engineScreen.wizard.autoSubtitle':
      'Die Engine plant Speicher und Kontext automatisch.',
  'engineScreen.wizard.startSubtitle':
      'Die Engine richtet benötigte Komponenten selbstständig ein.',
  'engineScreen.wizard.model': 'Modell',
  'engineScreen.wizard.configure': 'Konfigurieren',
  'engineScreen.wizard.start': 'Starten',
  'engineScreen.wizard.step': 'SCHRITT {step} / 3',
  'engineScreen.wizard.noLocalModels':
      'Keine lokalen Modelle gefunden.\nLade ein Modell im Marktplatz herunter und aktualisiere oben rechts.',
  'engineScreen.wizard.calculating':
      'Freien Grafikspeicher und Modellbedarf werden berechnet …',
  'engineScreen.wizard.cpuMode':
      'CPU-Modus aktiv: Die Engine verwendet den ausdrücklich bestätigten System-RAM.',
  'engineScreen.wizard.hybridMode':
      'Hybridmodus aktiv: Die Engine verwendet GPU und den bestätigten System-RAM-Anteil.',
  'engineScreen.expert.title': 'Expertenmodus',
  'engineScreen.expert.subtitle':
      'Kontext, Runtime, Geräte und Speicher manuell steuern',
  'engineScreen.expert.recalculatePlan': 'Plan neu berechnen',
  'engineScreen.wizard.calculateContinue': 'Automatisch berechnen und weiter',
  'engineScreen.wizard.autoMode':
      'Auto-Modus aktiv: Die Engine berechnet den Kontext passend zum Speicher, bereitet alle Komponenten vor und behebt Startprobleme selbstständig.',
  'engineScreen.action.retry': 'Erneut versuchen',
  'engineScreen.header.title': 'Modell-Studio',
  'engineScreen.header.variantTooltip':
      'Der llama-server-Build, den diese Maschine gewählt hat',
  'engineScreen.header.subtitle':
      'Lokale Modelle einrichten, starten und verwalten.',
  'engineScreen.error.dismiss': 'Meldung schließen',
  'engineScreen.preset.title': 'Gespeicherte Konfigurationen',
  'engineScreen.preset.open': 'Presets',
  'engineScreen.preset.apply': 'Übernehmen',
  'engineScreen.preset.applied': '„{name}“ wurde übernommen.',
  'engineScreen.preset.delete': 'Preset löschen',
  'engineScreen.preset.builtIn': 'mitgeliefert',
  'engineScreen.preset.saveCurrent': 'Aktuelle Einstellungen speichern',
  'engineScreen.preset.namePlaceholder': 'Name des Presets',
  'engineScreen.preset.nameRequired': 'Bitte einen Namen eingeben.',
  'engineScreen.preset.save': 'Speichern',
  'engineScreen.preset.export': 'Exportieren',
  'engineScreen.preset.exported':
      'Die Presets liegen als JSON in der Zwischenablage.',
  'engineScreen.preset.import': 'Importieren',
  'engineScreen.preset.importEmpty':
      'In der Zwischenablage steht keine Preset-Datei.',
  'engineScreen.model.quantizeTooltip': 'Modell quantisieren',
  'engineScreen.model.quantizeStarted':
      '„{model}“ wird quantisiert. Der Fortschritt steht bei den Vorgängen.',
  'engineScreen.model.deleteTooltip': 'Modell und lokale Dateien löschen',
  'engineScreen.model.quantizationTooltip':
      'Quantisierung der Modellgewichte. Sie bestimmt den vorgeschlagenen KV-Cache-Typ.',
  'engineScreen.model.contextTooltip': 'Maximale Kontextlänge des Modells',
  'engineScreen.model.notStartable': 'Nicht startbar',
  'engineScreen.model.selected': 'Ausgewählt',
  'engineScreen.field.contextPlanning': 'Kontextplanung',
  'engineScreen.field.restartRequired': 'Neustart erforderlich',
  'engineScreen.field.autoMaximum': 'Automatisch maximal',
  'engineScreen.field.fixedContext': 'Fester Kontext',
  'engineScreen.context.budgetTitle': 'Kontextbudget',
  'engineScreen.context.gpuOnly': 'Nur GPU: {tokens}',
  'engineScreen.context.gpuOnlyTooltip':
      'So viel Kontext passt allein in den VRAM.',
  'engineScreen.context.withRam': 'Mit RAM: {tokens}',
  'engineScreen.context.withRamTooltip':
      'Erreichbar, wenn System-RAM mitgenutzt werden darf. Langsamer als reiner VRAM.',
  'engineScreen.context.perToken': '{size} pro Token',
  'engineScreen.context.perTokenTooltip':
      'Speicherbedarf des KV-Caches je Token, aus Layern, KV-Heads und Cache-Typ.',
  'engineScreen.context.cacheTypeTooltip':
      'Gewählter KV-Cache-Typ. Er folgt der Quantisierung des Modells.',
  'engineScreen.context.ramWouldExtend':
      'Ohne System-RAM endet der Kontext bei {tokens} Token. Mehr geht nur, wenn du RAM unten freigibst.',
  'engineScreen.field.maximumContext': 'Maximaler Kontext',
  'engineScreen.field.token': 'Token',
  'engineScreen.field.autoCalculated': 'Wird automatisch berechnet',
  'engineScreen.field.runtime': 'Runtime',
  'engineScreen.field.autoSelectsAdapter': 'Auto wählt den besten Adapter',
  'engineScreen.field.automatic': 'Automatisch',
  'engineScreen.field.priority': 'Priorität',
  'engineScreen.field.pinnedHelp': 'Pinned wird nie automatisch verkleinert',
  'engineScreen.field.low': 'Niedrig',
  'engineScreen.field.normal': 'Normal',
  'engineScreen.field.high': 'Hoch',
  'engineScreen.field.pinned': 'Pinned',
  'engineScreen.field.gpuLayers': 'GPU-Layer',
  'engineScreen.field.emptyAuto': 'Leer = Auto',
  'engineScreen.field.cpuThreads': 'CPU-Threads',
  'engineScreen.field.tensorParallelism': 'Tensor Parallelism',
  'engineScreen.field.gpuCount': 'Anzahl GPUs',
  'engineScreen.field.parallelSequences': 'Parallele Sequenzen',
  'engineScreen.field.minimumOne': 'Mindestens 1',
  'engineScreen.field.gpuIds': 'GPU-IDs',
  'engineScreen.field.gpuIdsHelp':
      'Kommagetrennt; leer = Scheduler entscheidet',
  'engineScreen.field.offload': 'Offload',
  'engineScreen.field.preferGpu': 'GPU bevorzugen',
  'engineScreen.field.preferRamCpu': 'RAM/CPU bevorzugen',
  'engineScreen.field.flashAttention': 'Flash Attention',
  'engineScreen.field.flashAttentionHelp':
      'Für quantisierte KV-Caches erforderlich und dort automatisch aktiv.',
  'engineScreen.field.flashAttentionAuto': 'Automatisch',
  'engineScreen.field.flashAttentionOn': 'Immer an',
  'engineScreen.field.flashAttentionOff': 'Aus',
  'engineScreen.field.kvCacheDtype': 'KV-Cache-Dtype',
  'engineScreen.field.weightsUnchanged': 'Gewichte bleiben unverändert',
  'engineScreen.field.policyDecides': 'Policy entscheidet',
  'engineScreen.field.kvCachePolicy': 'KV-Cache-Policy',
  'engineScreen.field.kvCachePolicyHelp':
      '4-Bit kann Qualität und Durchsatz beeinflussen',
  'engineScreen.field.prefer4Bit': '4-Bit bevorzugen, sicher zurückfallen',
  'engineScreen.field.nativeCacheOnly': 'Nur nativer Cache',
  'engineScreen.field.autoModeRecommended': 'Auto-Modus (empfohlen)',
  'engineScreen.field.autoModeHelp':
      'Die Engine berechnet den Kontext passend zum Speicher und passt Cache, Kontext und Gerät automatisch an, bis das Modell läuft.',
  'engineScreen.field.allowRamOffload': 'System-RAM beim Offload zulassen',
  'engineScreen.field.allowRamOffloadHelp':
      'Nur aktivieren, wenn das Modell nicht vollständig in den Grafikspeicher passt.',
  'engineScreen.field.autostart': 'Autostart',
  'engineScreen.field.autostartHelp':
      'Diese Instanz beim nächsten Backend-Start wiederherstellen',
  'engineScreen.field.gatewayAutostart': 'Bei Anfrage automatisch laden',
  'engineScreen.field.gatewayAutostartHelp':
      'Das lokale OpenAI-Gateway lädt dieses Modell, wenn eine Anfrage dafür eintrifft, statt „nicht bereit“ zu antworten.',
  'engineScreen.field.restartOnCrash': 'Nach Absturz neu starten',
  'engineScreen.field.restartOnCrashHelp':
      'Beendet sich der Modellprozess von selbst, wird er automatisch neu gestartet – mit wachsendem Abstand, damit ein Modell, das nicht laden kann, nicht endlos neu startet.',
  'engineScreen.field.idleTimeout': 'Entladen nach Leerlauf',
  'engineScreen.field.idleTimeoutHelp':
      'Wie lange die Instanz ungenutzt geladen bleibt, bevor sie den Speicher freigibt.',
  'engineScreen.field.idleTimeoutDefault': 'Standard der Engine (15 Minuten)',
  'engineScreen.field.idleTimeout5Minutes': 'Nach 5 Minuten',
  'engineScreen.field.idleTimeout30Minutes': 'Nach 30 Minuten',
  'engineScreen.field.idleTimeout2Hours': 'Nach 2 Stunden',
  'engineScreen.field.idleTimeoutNever': 'Geladen lassen, bis ich stoppe',
  'engineScreen.memory.weights': 'Gewichte {size}',
  'engineScreen.memory.kvCache': 'KV {size}',
  'engineScreen.memory.runtime': 'Runtime {size}',
  'engineScreen.memory.noRamOffload': '{confidence} · kein RAM-Offload geplant',
  'engineScreen.memory.ramAfter': '{confidence} · RAM ab {tokens} Token',
  'engineScreen.instances.title': 'Bereits eingerichtete Modelle',
  'engineScreen.instances.subtitle':
      '{count} {modelLabel} eingerichtet · Start, Stopp und Verhalten direkt hier steuern',
  'engineScreen.instances.modelSingular': 'Modell',
  'engineScreen.instances.modelPlural': 'Modelle',
  'engineScreen.instances.empty':
      'Noch keine Engine-Instanz.\nWähle ein Modell und starte es mit der empfohlenen Konfiguration.',
  'engineScreen.diagnostics.technicalComponents': 'Technische Komponenten',
  'engineScreen.diagnostics.noComponents':
      'Noch keine Komponenteninformationen verfügbar.',
  'engineScreen.diagnostics.technicalDiagnosis': 'Technische Diagnose',
  'engineScreen.operations.current': 'Aktuelle Vorgänge',
  'engineScreen.operations.cancel': 'Vorgang abbrechen',
  'engineScreen.operation.defaultPreparing':
      'Die lokale Ausführung wird vorbereitet.',
  'engineScreen.operation.installingComponents':
      'Die benötigten Komponenten werden eingerichtet.',
  'engineScreen.operation.loadingModel': 'Das Modell wird geladen und geprüft.',
  'engineScreen.operation.runtimeLlamaCpp': 'GGUF-Ausführung',
  'engineScreen.operation.runtimeLlamaCppSource': 'Runtime llama_cpp',
  'engineScreen.operation.isWarmingUp': 'wird vorbereitet',

  'engineScreen.operation.warmingUpSource': 'wird vorgewärmt',
  'engineScreen.runtimeError.compilerMissing':
      'Für den nativen Runtime-Build fehlen Compiler oder CMake. Bitte die Build-Werkzeuge installieren und erneut versuchen.',
  'engineScreen.runtimeError.diskFull':
      'Auf dem Datenträger ist nicht genug freier Speicher. Bitte schaffe etwas Platz und versuche es erneut.',
  'engineScreen.runtimeError.networkUnavailable':
      'Die benötigten Komponenten konnten wegen einer Netzwerkstörung nicht geladen werden. Bitte prüfe die Verbindung und versuche es erneut.',
  'engineScreen.runtimeError.packageUnavailable':
      'Für dieses System ist das benötigte Paket nicht verfügbar. Culpeo Studio versucht, eine kompatible Alternative zu verwenden.',
  'engineScreen.runtimeError.nativeBuildFailed':
      'Die GPU-Ausführung konnte nicht eingerichtet werden. Beim nächsten Versuch wird eine kompatible Alternative verwendet.',
  'engineScreen.runtimeError.pythonEnvironmentFailed':
      'Die geschützte Laufzeitumgebung konnte nicht angelegt werden. Bitte versuche es erneut.',
  'engineScreen.runtimeError.probeFailed':
      'Die Komponenten wurden installiert, konnten auf diesem Gerät aber nicht erfolgreich geprüft werden.',
  'engineScreen.runtimeError.generic':
      'Eine benötigte Komponente konnte nicht eingerichtet werden. Bitte versuche es erneut.',
};

const Map<String, String> engineScreenStringsEn = {
  'engineScreen.notification.modelsStarted':
      '{count} models were started and are ready.',
  'engineScreen.default.model': 'The model',
  'engineScreen.notification.modelStarted':
      '“{name}” was started and is ready.',
  'engineScreen.error.calculationFailed':
      'The automatic calculation could not be completed for this model.',
  'engineScreen.error.modelDoesNotFit':
      'The model currently fits neither entirely in GPU memory nor jointly in GPU and available system RAM.',
  'engineScreen.memory.gpuNotReady': 'GPU support is not ready yet',
  'engineScreen.memory.addSystemRam': 'Add system RAM?',
  'engineScreen.memory.ramPlan': '({ram} RAM in the plan) ',
  'engineScreen.memory.gpuNotReadyContent':
      '“{model}” was not rejected because of its size. The graphics card was detected, but the matching GPU runtime is not ready yet.\n\n{issue}\n\nStarting with CPU + system RAM {ramPlan}is possible. Would you like to use this fallback?',
  'engineScreen.memory.addSystemRamContent':
      '“{model}” does not fit in the available GPU memory alone. The calculation shows that starting with GPU + system RAM {ramPlan}is possible.\n\nWould you like to use this hybrid mode?',
  'engineScreen.memory.chooseOtherModel': 'No, choose another model',
  'engineScreen.memory.rebuildGpuRuntime': 'Rebuild GPU runtime',
  'engineScreen.memory.useCpuRam': 'Use CPU/RAM',
  'engineScreen.memory.useRam': 'Use RAM',
  'engineScreen.error.gpuRuntimeRebuildFailed':
      'The Vulkan GPU runtime could not be rebuilt.',
  'engineScreen.action.cancel': 'Cancel',
  'engineScreen.model.deleteTitle': 'Delete model?',
  'engineScreen.model.deleteContent':
      '“{model}” will be removed from the list and from storage. For a custom model package, its complete directory, including manifests and additional files, will be deleted. Other models are kept.',
  'engineScreen.model.deleteConfirm': 'Delete permanently',
  'engineScreen.notification.modelDeleted':
      'The model and its local files were deleted.',
  'engineScreen.notification.chooseStartableModel':
      'Please select a startable model first.',
  'engineScreen.notification.instanceScheduled':
      'The instance was scheduled. Missing runtime components will be installed automatically.',
  'engineScreen.notification.refreshed':
      'My models, memory, and local models are up to date.',
  'engineScreen.notification.instanceActionScheduled':
      'Instance action “{action}” was scheduled.',
  'engineScreen.notification.autoFixStarted': 'Automatic correction started.',
  'engineScreen.memory.retryRamContent':
      'Available GPU memory changed during preparation. The Engine can recalculate the plan with the currently available system RAM.',
  'engineScreen.memory.recalculateWithRam': 'Recalculate with RAM',
  'engineScreen.notification.gpuRamRecalculated':
      'GPU and system RAM are being recalculated.',
  'engineScreen.notification.runtimePreparing':
      'The runtime is being prepared again.',
  'engineScreen.instance.removeTitle': 'Remove instance?',
  'engineScreen.instance.removeContent':
      '“{instance}” will be stopped and removed from the Engine.',
  'engineScreen.action.remove': 'Remove',
  'engineScreen.notification.instanceRemoved': 'The instance was removed.',
  'engineScreen.context.title': 'Set context',
  'engineScreen.context.summary':
      '{current} tokens are active and verified by a real model start. {maximum} is the calculated GPU+RAM maximum, but is not yet a stability guarantee.',
  'engineScreen.context.help':
      'A higher value restarts the model. If it is not stable, the Engine automatically continues searching between the last confirmed value and the failed upper bound. This can take several model starts.',
  'engineScreen.context.checked': 'Checked {tokens}',
  'engineScreen.context.testEstimate': 'Test estimate {tokens}',
  'engineScreen.context.tokensLabel': 'Context tokens',
  'engineScreen.context.rangeHelper':
      'Selectable: {minimum} to {maximum} tokens',
  'engineScreen.context.invalidValue':
      'Please enter a value between {minimum} and {maximum}.',
  'engineScreen.context.restartAndCheck': 'Restart & check',
  'engineScreen.notification.contextUnchanged':
      'The already checked context remains unchanged.',
  'engineScreen.notification.contextIncrease':
      'The larger context is now being started and checked for stability.',
  'engineScreen.notification.contextRestart':
      'The context is being changed with a safe restart.',
  'engineScreen.sampling.title': 'Sampling defaults',
  'engineScreen.sampling.temperature': 'Temperature',
  'engineScreen.sampling.topP': 'Top P',
  'engineScreen.sampling.maxOutputTokens': 'Maximum output tokens',
  'engineScreen.sampling.applyLive': 'Apply live',
  'engineScreen.notification.samplingUpdated': 'Sampling defaults updated.',
  'engineScreen.error.resourceConflict':
      'This model does not fit in currently available RAM and GPU memory. Choose a smaller or quantized model, or stop other local models first.',
  'engineScreen.system.tab': 'SYSTEM',
  'engineScreen.system.openMonitor': 'Open system monitor',
  'engineScreen.system.monitor': 'SYSTEM MONITOR',
  'engineScreen.telemetry.title': 'System monitor',
  'engineScreen.telemetry.subtitle': 'Live data from the local Engine',
  'engineScreen.telemetry.closeMonitor': 'Close system monitor',
  'engineScreen.telemetry.hardwareUtilization': 'HARDWARE UTILIZATION',
  'engineScreen.telemetry.hardwareLoading': 'Loading hardware data …',
  'engineScreen.telemetry.memory': 'Memory',
  'engineScreen.telemetry.memoryUsed': '{used} of {total} used',
  'engineScreen.telemetry.currentModelStart': 'CURRENT MODEL START',
  'engineScreen.telemetry.quiet': 'IDLE',
  'engineScreen.telemetry.active': 'ACTIVE',
  'engineScreen.telemetry.noStartActive':
      'No start operation is active. The Engine is ready.',
  'engineScreen.telemetry.liveModels': 'LIVE MODELS',
  'engineScreen.telemetry.online': '{count} ONLINE',
  'engineScreen.telemetry.noModelRunning': 'No model is currently running.',
  'engineScreen.telemetry.technicalComponents': 'TECHNICAL COMPONENTS',
  'engineScreen.telemetry.componentsTooltip': 'Technical components',
  'engineScreen.operation.defaultName': 'Engine operation',
  'engineScreen.progress.complete': '{percent}% complete',
  'engineScreen.progress.waiting': 'Waiting for progress data …',
  'engineScreen.instance.label': 'Instance {id}',
  'engineScreen.context.auto': 'Automatic context',
  'engineScreen.context.tokenCount': '{tokens} tokens',
  'engineScreen.runtime.backgroundPreparing':
      'A runtime environment is being prepared in the background.',
  'engineScreen.progress.preparing': 'Preparation in progress …',
  'engineScreen.runtime.retrySetup': 'Try setup again',
  'engineScreen.workspace.startModel': 'Start model',
  'engineScreen.workspace.myModels': 'My models · {count}',
  'engineScreen.wizard.selectModel': 'Select model',
  'engineScreen.wizard.configureStart': 'Configure start',
  'engineScreen.wizard.startModel': 'Start model',
  'engineScreen.wizard.selectModelSubtitle':
      'Choose a local model for your next instance.',
  'engineScreen.wizard.expertSubtitle':
      'Review the expert settings for this model.',
  'engineScreen.wizard.autoSubtitle':
      'The Engine plans memory and context automatically.',
  'engineScreen.wizard.startSubtitle':
      'The Engine sets up required components automatically.',
  'engineScreen.wizard.model': 'Model',
  'engineScreen.wizard.configure': 'Configure',
  'engineScreen.wizard.start': 'Start',
  'engineScreen.wizard.step': 'STEP {step} / 3',
  'engineScreen.wizard.noLocalModels':
      'No local models found.\nDownload a model from the Marketplace and refresh in the top right.',
  'engineScreen.wizard.calculating':
      'Calculating available GPU memory and model requirements …',
  'engineScreen.wizard.cpuMode':
      'CPU mode active: The Engine uses the explicitly confirmed system RAM.',
  'engineScreen.wizard.hybridMode':
      'Hybrid mode active: The Engine uses GPU and the confirmed system RAM share.',
  'engineScreen.expert.title': 'Expert mode',
  'engineScreen.expert.subtitle':
      'Manually control context, runtime, devices, and memory',
  'engineScreen.expert.recalculatePlan': 'Recalculate plan',
  'engineScreen.wizard.calculateContinue':
      'Calculate automatically and continue',
  'engineScreen.wizard.autoMode':
      'Auto mode active: The Engine calculates context for available memory, prepares all components, and resolves start problems automatically.',
  'engineScreen.action.retry': 'Try again',
  'engineScreen.header.title': 'Model studio',
  'engineScreen.header.variantTooltip':
      'The llama-server build this machine resolved to',
  'engineScreen.header.subtitle': 'Set up, start, and manage local models.',
  'engineScreen.error.dismiss': 'Dismiss message',
  'engineScreen.preset.title': 'Saved configurations',
  'engineScreen.preset.open': 'Presets',
  'engineScreen.preset.apply': 'Apply',
  'engineScreen.preset.applied': '"{name}" was applied.',
  'engineScreen.preset.delete': 'Delete preset',
  'engineScreen.preset.builtIn': 'built in',
  'engineScreen.preset.saveCurrent': 'Save the current settings',
  'engineScreen.preset.namePlaceholder': 'Preset name',
  'engineScreen.preset.nameRequired': 'Please enter a name.',
  'engineScreen.preset.save': 'Save',
  'engineScreen.preset.export': 'Export',
  'engineScreen.preset.exported': 'The presets are on the clipboard as JSON.',
  'engineScreen.preset.import': 'Import',
  'engineScreen.preset.importEmpty':
      'There is no preset file on the clipboard.',
  'engineScreen.model.quantizeTooltip': 'Quantize model',
  'engineScreen.model.quantizeStarted':
      '"{model}" is being quantized. Progress is shown with the operations.',
  'engineScreen.model.deleteTooltip': 'Delete model and local files',
  'engineScreen.model.quantizationTooltip':
      'Weight quantisation. It decides the suggested KV cache type.',
  'engineScreen.model.contextTooltip': 'Maximum context length of the model',
  'engineScreen.model.notStartable': 'Not startable',
  'engineScreen.model.selected': 'Selected',
  'engineScreen.field.contextPlanning': 'Context planning',
  'engineScreen.field.restartRequired': 'Restart required',
  'engineScreen.field.autoMaximum': 'Automatic maximum',
  'engineScreen.field.fixedContext': 'Fixed context',
  'engineScreen.context.budgetTitle': 'Context budget',
  'engineScreen.context.gpuOnly': 'GPU only: {tokens}',
  'engineScreen.context.gpuOnlyTooltip': 'How much context fits in VRAM alone.',
  'engineScreen.context.withRam': 'With RAM: {tokens}',
  'engineScreen.context.withRamTooltip':
      'Reachable when system RAM may be used too. Slower than VRAM alone.',
  'engineScreen.context.perToken': '{size} per token',
  'engineScreen.context.perTokenTooltip':
      'KV cache cost per token, from layers, KV heads and cache type.',
  'engineScreen.context.cacheTypeTooltip':
      'The chosen KV cache type. It follows the model\'s quantisation.',
  'engineScreen.context.ramWouldExtend':
      'Without system RAM the context stops at {tokens} tokens. Going further needs the RAM switch below.',
  'engineScreen.field.maximumContext': 'Maximum context',
  'engineScreen.field.token': 'Tokens',
  'engineScreen.field.autoCalculated': 'Calculated automatically',
  'engineScreen.field.runtime': 'Runtime',
  'engineScreen.field.autoSelectsAdapter': 'Auto selects the best adapter',
  'engineScreen.field.automatic': 'Automatic',
  'engineScreen.field.priority': 'Priority',
  'engineScreen.field.pinnedHelp': 'Pinned is never reduced automatically',
  'engineScreen.field.low': 'Low',
  'engineScreen.field.normal': 'Normal',
  'engineScreen.field.high': 'High',
  'engineScreen.field.pinned': 'Pinned',
  'engineScreen.field.gpuLayers': 'GPU layers',
  'engineScreen.field.emptyAuto': 'Empty = auto',
  'engineScreen.field.cpuThreads': 'CPU threads',
  'engineScreen.field.tensorParallelism': 'Tensor parallelism',
  'engineScreen.field.gpuCount': 'Number of GPUs',
  'engineScreen.field.parallelSequences': 'Parallel sequences',
  'engineScreen.field.minimumOne': 'At least 1',
  'engineScreen.field.gpuIds': 'GPU IDs',
  'engineScreen.field.gpuIdsHelp':
      'Comma-separated; leave empty for scheduler selection',
  'engineScreen.field.offload': 'Offload',
  'engineScreen.field.preferGpu': 'Prefer GPU',
  'engineScreen.field.preferRamCpu': 'Prefer RAM/CPU',
  'engineScreen.field.flashAttention': 'Flash attention',
  'engineScreen.field.flashAttentionHelp':
      'Required for quantised KV caches, where it is enabled automatically.',
  'engineScreen.field.flashAttentionAuto': 'Automatic',
  'engineScreen.field.flashAttentionOn': 'Always on',
  'engineScreen.field.flashAttentionOff': 'Off',
  'engineScreen.field.kvCacheDtype': 'KV cache dtype',
  'engineScreen.field.weightsUnchanged': 'Weights remain unchanged',
  'engineScreen.field.policyDecides': 'Policy decides',
  'engineScreen.field.kvCachePolicy': 'KV cache policy',
  'engineScreen.field.kvCachePolicyHelp':
      '4-bit can affect quality and throughput',
  'engineScreen.field.prefer4Bit': 'Prefer 4-bit, fall back safely',
  'engineScreen.field.nativeCacheOnly': 'Native cache only',
  'engineScreen.field.autoModeRecommended': 'Auto mode (recommended)',
  'engineScreen.field.autoModeHelp':
      'The Engine calculates context for available memory and automatically adjusts cache, context, and device until the model runs.',
  'engineScreen.field.allowRamOffload': 'Allow system RAM for offload',
  'engineScreen.field.allowRamOffloadHelp':
      'Enable only when the model does not fit fully in GPU memory.',
  'engineScreen.field.autostart': 'Autostart',
  'engineScreen.field.autostartHelp':
      'Restore this instance on the next backend start',
  'engineScreen.field.gatewayAutostart': 'Load on request',
  'engineScreen.field.gatewayAutostartHelp':
      'The local OpenAI gateway loads this model when a request arrives for it, instead of answering "not ready".',
  'engineScreen.field.restartOnCrash': 'Restart after a crash',
  'engineScreen.field.restartOnCrashHelp':
      'If the model process exits on its own it is started again, with a growing delay so a model that cannot load does not restart forever.',
  'engineScreen.field.idleTimeout': 'Unload when idle',
  'engineScreen.field.idleTimeoutHelp':
      'How long the instance stays loaded while unused before it releases its memory.',
  'engineScreen.field.idleTimeoutDefault': 'Engine default (15 minutes)',
  'engineScreen.field.idleTimeout5Minutes': 'After 5 minutes',
  'engineScreen.field.idleTimeout30Minutes': 'After 30 minutes',
  'engineScreen.field.idleTimeout2Hours': 'After 2 hours',
  'engineScreen.field.idleTimeoutNever': 'Keep loaded until I stop it',
  'engineScreen.memory.weights': 'Weights {size}',
  'engineScreen.memory.kvCache': 'KV {size}',
  'engineScreen.memory.runtime': 'Runtime {size}',
  'engineScreen.memory.noRamOffload': '{confidence} · no RAM offload planned',
  'engineScreen.memory.ramAfter': '{confidence} · RAM after {tokens} tokens',
  'engineScreen.instances.title': 'Configured models',
  'engineScreen.instances.subtitle':
      '{count} {modelLabel} configured · control start, stop, and behavior right here',
  'engineScreen.instances.modelSingular': 'model',
  'engineScreen.instances.modelPlural': 'models',
  'engineScreen.instances.empty':
      'No Engine instance yet.\nChoose a model and start it with the recommended configuration.',
  'engineScreen.diagnostics.technicalComponents': 'Technical components',
  'engineScreen.diagnostics.noComponents':
      'No component information available yet.',
  'engineScreen.diagnostics.technicalDiagnosis': 'Technical diagnosis',
  'engineScreen.operations.current': 'Current operations',
  'engineScreen.operations.cancel': 'Cancel operation',
  'engineScreen.operation.defaultPreparing':
      'The local execution is being prepared.',
  'engineScreen.operation.installingComponents':
      'The required components are being set up.',
  'engineScreen.operation.loadingModel':
      'The model is loading and being checked.',
  'engineScreen.operation.runtimeLlamaCpp': 'GGUF execution',
  'engineScreen.operation.runtimeLlamaCppSource': 'Runtime llama_cpp',
  'engineScreen.operation.isWarmingUp': 'is being prepared',

  'engineScreen.operation.warmingUpSource': 'wird vorgewärmt',
  'engineScreen.runtimeError.compilerMissing':
      'Compilers or CMake are missing for the native runtime build. Install the build tools and try again.',
  'engineScreen.runtimeError.diskFull':
      'There is not enough free disk space. Free up some space and try again.',
  'engineScreen.runtimeError.networkUnavailable':
      'The required components could not be loaded because of a network problem. Check the connection and try again.',
  'engineScreen.runtimeError.packageUnavailable':
      'The required package is not available for this system. Culpeo Studio will try to use a compatible alternative.',
  'engineScreen.runtimeError.nativeBuildFailed':
      'GPU execution could not be set up. A compatible alternative will be used on the next attempt.',
  'engineScreen.runtimeError.pythonEnvironmentFailed':
      'The isolated runtime environment could not be created. Please try again.',
  'engineScreen.runtimeError.probeFailed':
      'The components were installed but could not be checked successfully on this device.',
  'engineScreen.runtimeError.generic':
      'A required component could not be set up. Please try again.',
};

String tr(String key, [Map<String, String>? params]) {
  final strings = appLanguage == 'en'
      ? engineScreenStringsEn
      : engineScreenStringsDe;
  var value = strings[key] ?? engineScreenStringsDe[key] ?? key;
  params?.forEach((name, replacement) {
    value = value.replaceAll('{$name}', replacement);
  });
  return value;
}

String sourceText(String key) => engineScreenStringsDe[key] ?? key;
