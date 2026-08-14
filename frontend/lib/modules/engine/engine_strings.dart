const Map<String, String> engineStringsDe = {
  'engineWidget.node.badge': 'Laeuft auf Node {name}',
  'engineWidget.status': 'Status: {label}',
  'engineWidget.status.ready': 'Bereit',
  'engineWidget.status.installing': 'Wird installiert',
  'engineWidget.status.creatingEnvironment': 'Wird eingerichtet',
  'engineWidget.status.probing': 'Wird geprüft',
  'engineWidget.status.running': 'Läuft',
  'engineWidget.status.queued': 'Warteschlange',
  'engineWidget.status.starting': 'Startet',
  'engineWidget.status.draining': 'Wird geleert',
  'engineWidget.status.restarting': 'Neustart',
  'engineWidget.status.failed': 'Fehlgeschlagen',
  'engineWidget.status.incomplete': 'Unvollständig',
  'engineWidget.status.stopped': 'Gestoppt',
  'engineWidget.status.missing': 'Nicht eingerichtet',
  'engineWidget.status.notNeeded': 'Nicht benötigt',
  'engineWidget.status.cancelled': 'Abgebrochen',
  'engineWidget.status.unknown': 'Unbekannt',
  'engineWidget.placement.notPlanned': 'Nicht geplant',
  'engineWidget.placement.planTooltip': 'Aus dem Engine-Speicherplan',
  'engineWidget.placement.currentTooltip': 'Aktuelle Speicherplatzierung',
  'engineWidget.placement.planned': 'Geplant: {label}',
  'engineWidget.guard.warning': 'Speicherwarnung',
  'engineWidget.guard.critical': 'Speicher kritisch',
  'engineWidget.guard.emergency': 'Notfallschutz aktiv',
  'engineWidget.guard.protection': 'Ressourcenschutz',
  'engineWidget.context.activeChecked': 'Aktiv & geprüft',
  'engineWidget.context.planned': 'Geplant',
  'engineWidget.context.semanticWithRam':
      'Kontextplan: ohne zusätzlichen RAM geschätzt {gpu}, {effectiveLabel} {effective}, GPU und RAM geschätzt {hybrid}, Modellgrenze {limit} Token',
  'engineWidget.context.semanticAtLimit':
      'Kontextplan: ohne zusätzlichen RAM geschätzt {gpu}, {effectiveLabel} {effective}; die Modellgrenze von {limit} Token ist bereits erreicht',
  'engineWidget.context.semanticNoRamGain':
      'Kontextplan: ohne zusätzlichen RAM geschätzt {gpu}, {effectiveLabel} {effective}; RAM bringt aktuell keinen zusätzlichen Kontext, Modellgrenze {limit} Token',
  'engineWidget.context.gpuEstimate': 'Ohne extra RAM (Schätzung): {tokens}',
  'engineWidget.context.effective': '{label}: {tokens}',
  'engineWidget.context.hybridEstimate': 'GPU + RAM (Schätzung): {tokens}',
  'engineWidget.context.modelLimitOnGpu':
      'Modelllimit bereits vollständig auf GPU',
  'engineWidget.context.noRamGain':
      'RAM bringt aktuell keinen zusätzlichen Kontext',
  'engineWidget.context.modelLimit': 'Modellgrenze: {tokens}',
  'engineWidget.preflight.cpuOnly':
      'Der Plan benötigt System-RAM; die GPU wird dafür nicht verwendet.',
  'engineWidget.preflight.ramExpands':
      'Rechnerisch kann System-RAM den Kontext von {gpu} auf bis zu {hybrid} erweitern. Der echte Start prüft diesen Schätzwert.',
  'engineWidget.preflight.gpuAtLimit':
      'Die GPU erreicht bereits das feste Modelllimit von {limit}.',
  'engineWidget.preflight.noRamGain':
      'System-RAM bringt für diesen Plan keinen zusätzlichen Kontext.',
  'engineWidget.preflight.cpuSpeed':
      'CPU/RAM ist nutzbar, aber meist deutlich langsamer als GPU-Ausführung.',
  'engineWidget.preflight.ramSpeed':
      'Der RAM-Anteil spart VRAM, kann Antworten aber langsamer machen.',
  'engineWidget.preflight.gpuSpeed':
      'GPU-only ist die schnellste Speicheraufteilung für diesen Plan.',
  'engineWidget.preflight.title': 'Start-Check',
  'engineWidget.preflight.metadataEstimated': 'Metadaten geschätzt',
  'engineWidget.preflight.metadataVerified': 'Metadaten geprüft',
  'engineWidget.preflight.whySafe': 'Warum dieser Plan sicher ist',
  'engineWidget.preflight.weights': 'Gewichte',
  'engineWidget.preflight.contextMemory': 'Kontextspeicher',
  'engineWidget.preflight.runtimeReserve': 'Runtime-Reserve',
  'engineWidget.preflight.hardwareSnapshot': 'Hardware-Snapshot',
  'engineWidget.preflight.noChecks':
      'Vor dem Workerstart werden Hardware, Cache-Modus und eine lokale Modellantwort nochmals geprüft.',
  'engineWidget.instance.moreActions': 'Weitere Aktionen',
  'engineWidget.instance.remove': 'Modellinstanz entfernen',
  'engineWidget.instance.activeRequest': '{count} aktive Anfrage',
  'engineWidget.instance.activeRequests': '{count} aktive Anfragen',
  'engineWidget.preview.memoryLabel': 'Arbeitsspeicher',
  'engineWidget.preview.memoryDetail': '19,8 GB von 32 GB belegt',
  'engineWidget.wizard.awaitingAdminConsent':
      'Das Betriebssystem wartet auf die Administratorfreigabe.',
  'engineWidget.wizard.gpuRepairTitle': 'GPU-Unterstützung wird eingerichtet',
  'engineWidget.instance.progressComplete': '{percent} % abgeschlossen',
  'engineWidget.instance.preparing': 'Wird vorbereitet …',
  'engineWidget.instance.memoryPlacement': 'Speicherverteilung',
  'engineWidget.instance.hybrid': 'Hybrid',
  'engineWidget.instance.hybridTooltip':
      'Ein Teil liegt im System-RAM. Das ist langsamer als reiner VRAM.',
  'engineWidget.instance.vramShare': '{size} im VRAM',
  'engineWidget.instance.ramShare': '{size} im RAM',
  'engineWidget.instance.plannedContext':
      '{tokens} Token Kontext sind eingeplant.',
  'engineWidget.instance.showInChatTitle':
      'Auch ausgeschaltet im Chat anzeigen',
  'engineWidget.instance.showInChatSubtitle':
      'Die Auswahl startet das Modell bei Bedarf automatisch.',
  'engineWidget.instance.fallback.unstableContext':
      'Der höhere Kontext von {failed} war nicht stabil. Aktiv und erfolgreich geprüft: {active} Token. Das rechnerische Maximum bleibt über „Kontext“ testbar.',
  'engineWidget.instance.fallback.compatibleRuntime':
      'Die Engine hat automatisch eine kompatible Ausführung gewählt. Das Modell bleibt nutzbar.',
  'engineWidget.instance.stage.installing': 'Einmalige Einrichtung läuft',
  'engineWidget.instance.stage.queued': 'Start wird vorbereitet',
  'engineWidget.instance.stage.starting': 'Modell wird gestartet',
  'engineWidget.instance.stage.draining':
      'Laufende Anfragen werden abgeschlossen',
  'engineWidget.instance.stage.restarting':
      'Neue Einstellungen werden angewendet',
  'engineWidget.instance.stage.ready': 'Bereit für lokale Anfragen',
  'engineWidget.instance.stage.failed':
      'Start konnte nicht abgeschlossen werden',
  'engineWidget.instance.stage.stopped': 'Derzeit ausgeschaltet',
  'engineWidget.instance.stage.default': 'Lokales Modell',
  'engineWidget.instance.description.installing':
      'Culpeo Studio richtet die benötigten Komponenten im Hintergrund ein. Danach startet das Modell automatisch.',
  'engineWidget.instance.description.queued':
      'Die sichere Speicheraufteilung ist berechnet. Der Start beginnt automatisch, sobald die Ressourcen bereit sind.',
  'engineWidget.instance.description.starting':
      'Das Modell wird geladen und kurz geprüft. Du musst nichts weiter tun.',
  'engineWidget.instance.description.draining':
      'Vor dem Wechsel werden laufende Antworten bis zu 30 Sekunden sauber beendet.',
  'engineWidget.instance.description.restarting':
      'Die Engine startet das Modell mit dem neuen Plan und prüft es anschließend automatisch.',
  'engineWidget.instance.description.failed':
      'Die automatische Einrichtung ist fehlgeschlagen. Du kannst es erneut versuchen; technische Details sind optional verfügbar.',
  'engineWidget.instance.description.default':
      'Die Engine arbeitet im Hintergrund.',
  'engineWidget.error.setupFailed':
      'Eine benötigte Komponente konnte nicht eingerichtet werden. Bitte versuche es erneut.',
  'engineWidget.error.memoryInsufficient':
      'Der verfügbare Speicher reicht für diesen Plan nicht aus. Die Engine kann beim nächsten Versuch einen kleineren Kontext wählen.',
  'engineWidget.error.gpuUnavailable':
      'Die gewünschte GPU-Ausführung ist nicht verfügbar. Eine kompatible Alternative kann automatisch gewählt werden.',
  'engineWidget.error.generic':
      'Das Modell konnte noch nicht gestartet werden. Bitte versuche es erneut oder öffne die technischen Details.',
  'engineWidget.error.planChanged':
      'Das Speicherbudget hat sich während der Vorbereitung geändert. GPU und System-RAM werden beim nächsten Versuch neu berechnet.',
  'engineWidget.details.title': 'Technische Details',
  'engineWidget.details.modelName': 'Lokaler Modellname',
  'engineWidget.details.runtime': 'Ausführung',
  'engineWidget.details.context': 'Kontext',
  'engineWidget.details.contextTokens': '{tokens} Token',
  'engineWidget.details.internalPhase': 'Interne Phase',
  'engineWidget.details.priority': 'Priorität',
  'engineWidget.details.placement': 'Platzierung',
  'engineWidget.details.activeRequests': 'Aktive Anfragen',
  'engineWidget.details.resourceProtection': 'Ressourcenschutz',
  'engineWidget.details.lastUsed': 'Zuletzt verwendet',
  'engineWidget.details.automaticStop': 'Automatisches Stoppen',
  'engineWidget.details.automaticAdjustment': 'Automatische Anpassung',
  'engineWidget.details.restartRequired': 'Bei Änderung mit Neustart',
  'engineWidget.details.errorLog': 'Fehlerprotokoll',
  'engineWidget.runtime.auto': 'Automatisch',
  'engineWidget.priority.low': 'Niedrig',
  'engineWidget.priority.high': 'Hoch',
  'engineWidget.priority.pinned': 'Fest reserviert',
  'engineWidget.priority.normal': 'Normal',
  'engineWidget.placement.unknown': 'Noch nicht bekannt',
  'engineWidget.instance.guard.warning': 'Warnung – neue Starts pausiert',
  'engineWidget.instance.guard.critical':
      'Kritisch – Speicher wird freigegeben',
  'engineWidget.instance.guard.emergency': 'Notfall – Hostschutz aktiv',
  'engineWidget.instance.guard.normal': 'Normal',
  'engineWidget.time.short': '{day}.{month}.{year} {hour}:{minute}',
  'engineWidget.restartField.runtime': 'Ausführung',
  'engineWidget.restartField.contextTokens': 'Kontextgröße',
  'engineWidget.restartField.gpuLayers': 'GPU-Layer',
  'engineWidget.restartField.threads': 'CPU-Threads',
  'engineWidget.restartField.tensorParallelSize': 'GPU-Parallelität',
  'engineWidget.restartField.gpuIds': 'GPU-Auswahl',
  'engineWidget.restartField.offload': 'Speicheraufteilung',
  'engineWidget.restartField.kvCacheDtype': 'Kontextspeicherformat',
  'engineWidget.restartField.maxSequences': 'parallele Anfragen',
  'engineQuantize.title': 'Modell quantisieren',
  'engineQuantize.cancel': 'Abbrechen',
  'engineQuantize.start': 'Quantisierung starten',
  'engineQuantize.starting': 'Wird gestartet …',
  'engineQuantize.checking': 'Ergebnisgröße wird berechnet …',
  'engineQuantize.unavailable':
      'Die Quantisierung steht erst zur Verfügung, wenn eine lokale Runtime installiert ist.',
  'engineQuantize.targetFormat': 'Zielformat',
  'engineQuantize.targetName': 'Dateiname',
  'engineQuantize.targetNameHelp':
      'Leer lassen, um den Namen aus Quelle und Zielformat abzuleiten. Die Datei entsteht neben der Quelle.',
  'engineQuantize.currentSize': 'Jetzt',
  'engineQuantize.resultSize': 'Danach',
  'engineQuantize.saves': 'Spart {percent} % · {size}',
  'engineQuantize.diskFree': '{free} frei, {needed} benötigt',
  'engineQuantize.pplDelta': 'Perplexität {delta}',
  'engineQuantize.bpw': '{bits} Bit pro Gewicht',
  'engineQuantize.allowRequantize': 'Erneute Quantisierung erlauben',
  'engineQuantize.allowRequantizeHelp':
      'Die Quelle ist bereits quantisiert. Das Ergebnis verliert Qualität ein zweites Mal und wird schlechter als dasselbe Format direkt aus einer F16-Quelle.',
  'engineQuantize.advanced': 'Erweitert',
  'engineQuantize.leaveOutputTensor': 'Ausgabe-Tensor unangetastet lassen',
  'engineQuantize.leaveOutputTensorHelp':
      'Etwas größer, dafür spürbar besser bei niedrigen Bitraten.',
};

const Map<String, String> engineStringsEn = {
  'engineWidget.node.badge': 'Runs on node {name}',
  'engineWidget.status': 'Status: {label}',
  'engineWidget.status.ready': 'Ready',
  'engineWidget.status.installing': 'Installing',
  'engineWidget.status.creatingEnvironment': 'Setting up',
  'engineWidget.status.probing': 'Checking',
  'engineWidget.status.running': 'Running',
  'engineWidget.status.queued': 'Queued',
  'engineWidget.status.starting': 'Starting',
  'engineWidget.status.draining': 'Draining',
  'engineWidget.status.restarting': 'Restarting',
  'engineWidget.status.failed': 'Failed',
  'engineWidget.status.incomplete': 'Incomplete',
  'engineWidget.status.stopped': 'Stopped',
  'engineWidget.status.missing': 'Not set up',
  'engineWidget.status.notNeeded': 'Not required',
  'engineWidget.status.cancelled': 'Cancelled',
  'engineWidget.status.unknown': 'Unknown',
  'engineWidget.placement.notPlanned': 'Not planned',
  'engineWidget.placement.planTooltip': 'From the Engine memory plan',
  'engineWidget.placement.currentTooltip': 'Current memory placement',
  'engineWidget.placement.planned': 'Planned: {label}',
  'engineWidget.guard.warning': 'Memory warning',
  'engineWidget.guard.critical': 'Memory critical',
  'engineWidget.guard.emergency': 'Emergency protection active',
  'engineWidget.guard.protection': 'Resource protection',
  'engineWidget.context.activeChecked': 'Active & checked',
  'engineWidget.context.planned': 'Planned',
  'engineWidget.context.semanticWithRam':
      'Context plan: estimated without additional RAM {gpu}, {effectiveLabel} {effective}, estimated with GPU and RAM {hybrid}, model limit {limit} tokens',
  'engineWidget.context.semanticAtLimit':
      'Context plan: estimated without additional RAM {gpu}, {effectiveLabel} {effective}; the model limit of {limit} tokens has already been reached',
  'engineWidget.context.semanticNoRamGain':
      'Context plan: estimated without additional RAM {gpu}, {effectiveLabel} {effective}; RAM currently adds no context, model limit {limit} tokens',
  'engineWidget.context.gpuEstimate': 'Without extra RAM (estimate): {tokens}',
  'engineWidget.context.effective': '{label}: {tokens}',
  'engineWidget.context.hybridEstimate': 'GPU + RAM (estimate): {tokens}',
  'engineWidget.context.modelLimitOnGpu': 'Model limit already fully on GPU',
  'engineWidget.context.noRamGain': 'RAM currently adds no context',
  'engineWidget.context.modelLimit': 'Model limit: {tokens}',
  'engineWidget.preflight.cpuOnly':
      'The plan requires system RAM; the GPU is not used for it.',
  'engineWidget.preflight.ramExpands':
      'System RAM can theoretically expand the context from {gpu} to up to {hybrid}. The actual start verifies this estimate.',
  'engineWidget.preflight.gpuAtLimit':
      'The GPU already reaches the fixed model limit of {limit}.',
  'engineWidget.preflight.noRamGain':
      'System RAM adds no additional context for this plan.',
  'engineWidget.preflight.cpuSpeed':
      'CPU/RAM is usable but usually much slower than GPU execution.',
  'engineWidget.preflight.ramSpeed':
      'The RAM portion saves VRAM, but can make responses slower.',
  'engineWidget.preflight.gpuSpeed':
      'GPU-only is the fastest memory layout for this plan.',
  'engineWidget.preflight.title': 'Start check',
  'engineWidget.preflight.metadataEstimated': 'Metadata estimated',
  'engineWidget.preflight.metadataVerified': 'Metadata verified',
  'engineWidget.preflight.whySafe': 'Why this plan is safe',
  'engineWidget.preflight.weights': 'Weights',
  'engineWidget.preflight.contextMemory': 'Context memory',
  'engineWidget.preflight.runtimeReserve': 'Runtime reserve',
  'engineWidget.preflight.hardwareSnapshot': 'Hardware snapshot',
  'engineWidget.preflight.noChecks':
      'Hardware, cache mode, and a local model response are checked again before the worker starts.',
  'engineWidget.instance.moreActions': 'More actions',
  'engineWidget.instance.remove': 'Remove model instance',
  'engineWidget.instance.activeRequest': '{count} active request',
  'engineWidget.instance.activeRequests': '{count} active requests',
  'engineWidget.preview.memoryLabel': 'Memory',
  'engineWidget.preview.memoryDetail': '19.8 GB of 32 GB in use',
  'engineWidget.wizard.awaitingAdminConsent':
      'The operating system is waiting for administrator approval.',
  'engineWidget.wizard.gpuRepairTitle': 'Setting up GPU support',
  'engineWidget.instance.progressComplete': '{percent}% complete',
  'engineWidget.instance.preparing': 'Preparing …',
  'engineWidget.instance.memoryPlacement': 'Memory placement',
  'engineWidget.instance.hybrid': 'Hybrid',
  'engineWidget.instance.hybridTooltip':
      'Part of this runs from system RAM, which is slower than VRAM alone.',
  'engineWidget.instance.vramShare': '{size} in VRAM',
  'engineWidget.instance.ramShare': '{size} in RAM',
  'engineWidget.instance.plannedContext':
      '{tokens} tokens of context are planned.',
  'engineWidget.instance.showInChatTitle': 'Show in chat while stopped',
  'engineWidget.instance.showInChatSubtitle':
      'Selecting it starts the model automatically when needed.',
  'engineWidget.instance.fallback.unstableContext':
      'The higher context of {failed} tokens was not stable. {active} tokens are active and successfully verified. You can still test the calculated maximum through “Context”.',
  'engineWidget.instance.fallback.compatibleRuntime':
      'The Engine automatically selected a compatible runtime. The model remains usable.',
  'engineWidget.instance.stage.installing': 'One-time setup in progress',
  'engineWidget.instance.stage.queued': 'Preparing to start',
  'engineWidget.instance.stage.starting': 'Starting model',
  'engineWidget.instance.stage.draining': 'Finishing active requests',
  'engineWidget.instance.stage.restarting': 'Applying new settings',
  'engineWidget.instance.stage.ready': 'Ready for local requests',
  'engineWidget.instance.stage.failed': 'Could not complete start',
  'engineWidget.instance.stage.stopped': 'Currently switched off',
  'engineWidget.instance.stage.default': 'Local model',
  'engineWidget.instance.description.installing':
      'Culpeo Studio is setting up the required components in the background. The model will start automatically afterwards.',
  'engineWidget.instance.description.queued':
      'The safe memory layout is calculated. Startup begins automatically when the resources are ready.',
  'engineWidget.instance.description.starting':
      'The model is loading and being checked briefly. You do not need to do anything else.',
  'engineWidget.instance.description.draining':
      'Before switching, active responses are completed cleanly for up to 30 seconds.',
  'engineWidget.instance.description.restarting':
      'The Engine starts the model with the new plan and then checks it automatically.',
  'engineWidget.instance.description.failed':
      'Automatic setup failed. You can try again; technical details remain optional.',
  'engineWidget.instance.description.default':
      'The Engine is working in the background.',
  'engineWidget.error.setupFailed':
      'A required component could not be set up. Please try again.',
  'engineWidget.error.memoryInsufficient':
      'The available memory is not enough for this plan. On the next attempt, the Engine can choose a smaller context.',
  'engineWidget.error.gpuUnavailable':
      'The requested GPU runtime is unavailable. A compatible alternative can be selected automatically.',
  'engineWidget.error.generic':
      'The model could not be started yet. Please try again or open the technical details.',
  'engineWidget.error.planChanged':
      'The memory budget changed during preparation. GPU and system RAM will be recalculated on the next attempt.',
  'engineWidget.details.title': 'Technical details',
  'engineWidget.details.modelName': 'Local model name',
  'engineWidget.details.runtime': 'Runtime',
  'engineWidget.details.context': 'Context',
  'engineWidget.details.contextTokens': '{tokens} tokens',
  'engineWidget.details.internalPhase': 'Internal phase',
  'engineWidget.details.priority': 'Priority',
  'engineWidget.details.placement': 'Placement',
  'engineWidget.details.activeRequests': 'Active requests',
  'engineWidget.details.resourceProtection': 'Resource protection',
  'engineWidget.details.lastUsed': 'Last used',
  'engineWidget.details.automaticStop': 'Automatic stop',
  'engineWidget.details.automaticAdjustment': 'Automatic adjustment',
  'engineWidget.details.restartRequired': 'Restart required after changes',
  'engineWidget.details.errorLog': 'Error log',
  'engineWidget.runtime.auto': 'Automatic',
  'engineWidget.priority.low': 'Low',
  'engineWidget.priority.high': 'High',
  'engineWidget.priority.pinned': 'Reserved',
  'engineWidget.priority.normal': 'Normal',
  'engineWidget.placement.unknown': 'Not known yet',
  'engineWidget.instance.guard.warning': 'Warning – new starts paused',
  'engineWidget.instance.guard.critical': 'Critical – freeing memory',
  'engineWidget.instance.guard.emergency': 'Emergency – host protection active',
  'engineWidget.instance.guard.normal': 'Normal',
  'engineWidget.time.short': '{month}/{day}/{year} {hour}:{minute}',
  'engineWidget.restartField.runtime': 'Runtime',
  'engineWidget.restartField.contextTokens': 'Context size',
  'engineWidget.restartField.gpuLayers': 'GPU layers',
  'engineWidget.restartField.threads': 'CPU threads',
  'engineWidget.restartField.tensorParallelSize': 'GPU parallelism',
  'engineWidget.restartField.gpuIds': 'GPU selection',
  'engineWidget.restartField.offload': 'Memory layout',
  'engineWidget.restartField.kvCacheDtype': 'Context memory format',
  'engineWidget.restartField.maxSequences': 'Concurrent requests',
  'engineQuantize.title': 'Quantize model',
  'engineQuantize.cancel': 'Cancel',
  'engineQuantize.start': 'Start quantization',
  'engineQuantize.starting': 'Starting …',
  'engineQuantize.checking': 'Calculating the result size …',
  'engineQuantize.unavailable':
      'Quantization becomes available once a local runtime is installed.',
  'engineQuantize.targetFormat': 'Target format',
  'engineQuantize.targetName': 'File name',
  'engineQuantize.targetNameHelp':
      'Leave empty to derive the name from the source and the target format. The file is written beside its source.',
  'engineQuantize.currentSize': 'Now',
  'engineQuantize.resultSize': 'After',
  'engineQuantize.saves': 'Saves {percent}% · {size}',
  'engineQuantize.diskFree': '{free} free, {needed} needed',
  'engineQuantize.pplDelta': 'perplexity {delta}',
  'engineQuantize.bpw': '{bits} bits per weight',
  'engineQuantize.allowRequantize': 'Allow re-quantization',
  'engineQuantize.allowRequantizeHelp':
      'The source is already quantized. The result loses quality a second time and will be worse than the same format taken straight from an F16 source.',
  'engineQuantize.advanced': 'Advanced',
  'engineQuantize.leaveOutputTensor': 'Leave the output tensor untouched',
  'engineQuantize.leaveOutputTensorHelp':
      'A little larger, noticeably better at low bit rates.',
};
