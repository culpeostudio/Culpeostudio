/// Deutsche UI-Texte. Schluessel-Schema: `screen.context.key`.
/// Platzhalter werden als `{name}` geschrieben und ueber `tr(key, {...})`
/// ersetzt.
const Map<String, String> appStringsDe = {
  // Allgemein
  'common.ok': 'OK',
  'common.cancel': 'Abbrechen',
  'common.save': 'Speichern',
  'common.delete': 'Löschen',
  'common.close': 'Schließen',
  'common.confirm': 'Bestätigen',
  'common.loading': 'Lädt…',
  'common.error': 'Fehler',
  'common.retry': 'Erneut versuchen',

  // Onboarding
  'onboarding.title': 'Willkommen!',
  'onboarding.subtitle':
      'Richte deine persönlichen Einstellungen ein. Du kannst sie später jederzeit in den Einstellungen ändern.',
  'onboarding.languageTitle': 'Sprache',
  'onboarding.languageGerman': 'Deutsch',
  'onboarding.languageEnglish': 'English',
  'onboarding.versionTitle': 'Frontend-Version',
  'onboarding.versionClassic': 'Classic',
  'onboarding.versionClassicDesc': 'Alle Module werden angezeigt.',
  'onboarding.versionLite': 'Lite',
  'onboarding.versionLiteDesc':
      'Nur Chat, Engine, Marktplatz, News und Benchmark werden angezeigt.',
  'onboarding.start': 'Los geht\'s',

  // Sidebar / Module
  'sidebar.chat': 'Chat',
  'sidebar.engine': 'Engine',
  'sidebar.marketplace': 'Marktplatz',
  'sidebar.training': 'Training',
  'sidebar.quantization': 'Quantisierung',
  'sidebar.generative': 'Gen Studio',
  'sidebar.news': 'News',
  'sidebar.benchmark': 'Benchmark',

  // Settings: Darstellung
  'settings.appearance': 'Darstellung',
  'settings.language': 'Sprache',
  'settings.frontendVersion': 'Frontend-Version',
  'settings.frontendVersionClassic': 'Classic (alle Module)',
  'settings.frontendVersionLite':
      'Lite (Chat, Engine, Marktplatz, News, Benchmark)',

  // Dashboard
  'dashboard.logoutTitle': 'Abmelden',
  'dashboard.logoutConfirm': 'Möchtest du dich wirklich ausloggen?',
  'dashboard.logoutYes': 'Ja, abmelden',
  'dashboard.benchmarkTitle': 'Externe Website öffnen',
  'dashboard.benchmarkBody':
      'Du bist dabei, artificialanalysis.ai im Browser zu öffnen. Möchtest du wirklich auf diese Seite wechseln?',
  'dashboard.benchmarkContinue': 'Weiter',
  'dashboard.benchmarkOpenFailed':
      'Die externe Benchmark-Seite konnte nicht geöffnet werden.',
  'dashboard.benchmarkOpenError':
      'Fehler beim Öffnen der Benchmark-Seite: {error}',
  'dashboard.tooltipLightTheme': 'Helles Design',
  'dashboard.tooltipDarkTheme': 'Dunkles Design',
  'dashboard.tooltipSettings': 'Einstellungen',
  'dashboard.tooltipLogout': 'Abmelden',
  'dashboard.tooltipNewChat': 'Neuer Chat erstellen',
  'dashboard.tooltipRemove': 'Entfernen',
  'dashboard.deletedModules': 'Gelöschte Module',
  'dashboard.deletedModulesEmpty':
      'Keine gelöschten Module.\nNutze das "-" Symbol an Modulen,\num sie zu entfernen.',
  'dashboard.codeBlockSwitch': 'Codeblock wechseln',
  'dashboard.codeBlockN': 'Codeblock {n}',
  'dashboard.codeClose': 'Code-Ansicht schließen',
  'dashboard.codeCopied': 'Code kopiert',
  'dashboard.copy': 'Kopieren',

  // Fehler
  'login.error.invalidCredentials': 'Anmeldedaten ungueltig',
  'login.error.invalidCode': 'Code ist ungueltig',

  // Validierung
  'login.validation.required': 'Pflichtfeld',
  'login.validation.codeInvalid': '6-stelligen Code eingeben',

  // Authenticator-Setup
  'login.setup.title': 'Authenticator einrichten',
  'login.setup.scanHint2fas':
      '2FAS öffnen, „+“ wählen und den QR-Code scannen.',
  'login.setup.scanHintGoogle':
      'Google Authenticator öffnen, „+“ wählen und den QR-Code scannen.',
  'login.setup.codeHint': 'Code aus der App',
  'login.setup.confirm': 'Einrichtung bestätigen',
  'login.setup.loadError': 'Setup konnte nicht geladen werden.',

  // Begruessung
  'login.welcome.title': 'Willkommen zurück',
  'login.welcome.subtitle': 'Melde dich an, um dein Studio zu öffnen.',

  // Formularfelder
  'login.field.usernameLabel': 'BENUTZERNAME',
  'login.field.usernameHint': 'Benutzername eingeben',
  'login.field.passwordLabel': 'PASSWORT',
  'login.field.passwordHint': 'Passwort eingeben',
  'login.field.showPassword': 'Passwort anzeigen',
  'login.field.hidePassword': 'Passwort verbergen',

  // Sitzung
  'login.remember.label': 'Angemeldet bleiben',
  'login.remember.duration': 'Sitzungsdauer',
  'login.duration.8h': '8 Std.',
  'login.duration.24h': '24 Std.',
  'login.duration.48h': '48 Std.',
  'login.duration.permanent': 'Dauerhaft',

  // Aktionen
  'login.action.login': 'Anmelden',
  'login.action.createAccount': 'Account erstellen',
  'login.action.forgotPassword': 'Passwort vergessen',

  // Fusszeile
  'login.footer.copyright': '© 2026 fillystudio. Alle Rechte vorbehalten.',
  'login.footer.credits':
      'Powered by PhiloEngine • Design & Development by fillystudio',

  // Account-Dialog
  'login.dialog.passwordUpdated': 'Passwort wurde aktualisiert.',
  'login.dialog.accountCreated': 'Account wurde erstellt.',
  'login.dialog.actionFailed': 'Aktion fehlgeschlagen.',
  'login.dialog.usernameHint': 'Benutzername',
  'login.dialog.newPasswordHint': 'Neues Passwort',
  'login.dialog.passwordHint': 'Passwort',
  'login.dialog.confirmPasswordHint': 'Passwort bestaetigen',
  'login.dialog.passwordsMismatch': 'Passwoerter stimmen nicht ueberein',
  'login.dialog.codeFromApp': 'Code aus {app}',
  'login.dialog.create': 'Erstellen',

  // Navigation
  'settings.nav.title': 'EINSTELLUNGEN',
  'settings.nav.general': 'Allgemein',
  'settings.nav.serverApi': 'Server / API',
  'settings.nav.shortcuts': 'Shortkarts',
  'settings.nav.botManagement': 'Bot-Verwaltung',
  'settings.nav.chatBot': 'Chat-Bot',
  'settings.nav.skills': 'Skills',

  // Allgemein
  'settings.general.title': 'Allgemeine Studio-Konfiguration',
  'settings.general.modelDirLabel': 'MODELL DOWNLOAD PFAD',
  'settings.general.modelDirDescription':
      'Ordner auf deiner Festplatte, in den heruntergeladene Modelle aus dem '
      'Marktplatz gespeichert werden. Du kannst einen eigenen Ordner waehlen '
      '(z.B. auf einer grossen Festplatte) – der Standard ist data/models.',
  'settings.general.modelDirHint': 'z.B. ~/models oder D:\\models',
  'settings.general.modelDirPickerTitle': 'Modell-Ordner waehlen',
  'settings.general.browse': 'Durchsuchen',
  'settings.general.browseTooltip': 'Ordner auf der Festplatte auswaehlen',
  'settings.general.apiUrlLabel': 'API HOST URL',
  'settings.general.apiUrlDescription':
      'Die Adresse des Backend-Servers (Standard: http://localhost:8080/api). '
      'Die App sendet alle Anfragen an diesen Server, um Modelle zu laden und Chats auszuführen.',
  'settings.general.saveButton': 'Einstellungen speichern',
  'settings.save.success': 'Einstellungen erfolgreich gespeichert',

  // Provider-Health
  'settings.health.reachable': 'Erreichbar',
  'settings.health.unreachable': 'Nicht erreichbar',
  'settings.health.httpResponse': 'Antwortet mit HTTP {code}',
  'settings.health.error': 'Fehler',

  // Server & API
  'settings.serverApi.title': 'Server & API-Schnittstellen',
  'settings.serverApi.subtitle':
      'Verbindung zu lokalen Servern und Cloud-Modell-Anbietern verwalten',
  'settings.serverApi.recheckTooltip': 'Verbindungen neu prüfen',
  'settings.serverApi.addNode': 'Node hinzufügen',
  'settings.serverApi.localServer': 'Lokaler Server',

  // Custom Node Dialoge
  'settings.customNode.fallbackName': 'Custom Node',
  'settings.customNode.addTitle': 'Custom Node hinzufügen',
  'settings.customNode.addDescription':
      'Richte eine eigene API-Verbindung zu einem benutzerdefinierten Server '
      'ein (z.B. Ollama oder ein lokaler OpenAI-kompatibler Endpunkt).',
  'settings.customNode.editTitle': 'Custom Node bearbeiten',
  'settings.customNode.editDescription':
      'Passe die Verbindungsinformationen für dieses Node an.',
  'settings.customNode.nameLabel': 'NODE NAME',
  'settings.customNode.nameHint': 'z.B. Lokaler Ollama Server',
  'settings.customNode.urlLabel': 'API BASE URL',
  'settings.customNode.urlHint': 'z.B. http://localhost:11434',
  'settings.customNode.keyLabel': 'API KEY (OPTIONAL)',
  'settings.customNode.keyHint': 'Token eingeben...',
  'settings.customNode.add': 'Hinzufügen',
  'settings.customNode.delete': 'Node löschen',
  'settings.customNode.save': 'Speichern',

  // Custom Nodes - Phase-2-Hinweis
  'settings.serverApi.phaseNote.title': 'Kommt in Phase 2',
  'settings.serverApi.phaseNote.body':
      'Eigene API-Nodes lassen sich bereits anlegen und auf Erreichbarkeit prüfen, sind aber noch nicht als aktive Verbindung in den Chat/Engine nutzbar. Die volle Funktion folgt mit Phase 2.',
  'settings.customNode.phaseBadge': 'Phase 2',

  // Token-Dialog
  'settings.token.setupTitle': '{title} einrichten',
  'settings.token.replaceDescription':
      'Es ist bereits ein Token konfiguriert. Du kannst ihn überschreiben, '
      'indem du unten einen neuen eingibst, oder ihn löschen.',
  'settings.token.enterDescription':
      'Gib deinen API-Token für {title} ein, um den Dienst zu aktivieren.',
  'settings.token.hfLink': '🤗 Token auf huggingface.co erstellen',
  'settings.token.orLink': '🤖 API-Keys auf openrouter.ai verwalten',
  'settings.token.flLink': '☁️ API-Schnittstelle auf featherless.ai abrufen',
  'settings.token.delete': 'Token löschen',
  'settings.token.updated': 'Token erfolgreich aktualisiert',

  // Provider-Karte
  'settings.provider.enabled': 'Aktiviert',
  'settings.provider.keySet': 'Key eingerichtet',
  'settings.provider.keyMissing': 'Key fehlt',
  'settings.provider.checking': 'Prüfe...',

  // Chat-Bot
  'settings.chatBot.title': 'Chat-Bot',
  'settings.chatBot.description':
      'Lege fest, ob neue Chats einen bestimmten Bot verwenden oder den '
      'passenden Bot automatisch auswählen.',
  'settings.chatBot.defaultLabel': 'STANDARD FÜR NEUE CHATS',
  'settings.chatBot.note':
      'Laufende Chats behalten ihren bisher verwendeten Bot.',

  // Skills
  'settings.skills.title': 'Agent Skills',
  'settings.skills.description':
      'Importierte Skills werden strikt gegen den Agent-Skills-Standard geprüft '
      'und nach data/skills kopiert. Sie werden in dieser Version noch nicht in Chats geladen.',
  'settings.skills.rescanTooltip': 'Neu scannen',
  'settings.skills.importFolder': 'Skill-Ordner einbinden',
  'settings.skills.imported': 'Skill eingebunden',
  'settings.skills.rescanned': 'Skills neu gescannt',
  'settings.skills.removed': 'Skill entfernt',
  'settings.skills.empty': 'Noch keine Skills eingebunden.',
  'settings.skills.unknown': 'Unbekannter Skill',
  'settings.skills.noDescription': 'Keine Beschreibung verfügbar',
  'settings.skills.removeTooltip': 'Entfernen',
  'settings.skills.valid': 'gültig',
  'settings.skills.invalid': 'ungültig',
  'settings.skills.fileCount': '{count} Dateien',

  // Shortcuts
  'settings.shortcuts.title': 'Tastenkombinationen (Shortkarts)',
  'settings.shortcuts.description':
      'Klicken Sie auf ein Tastenkürzel, um es neu aufzunehmen. Drücken Sie '
      'anschließend die gewünschte Tastenkombination.',
  'settings.shortcuts.pressKeys': 'Drücke Tasten...',
  'settings.shortcuts.action.switchToChat': 'Chat öffnen',
  'settings.shortcuts.action.switchToPhilox': 'Philox Agent öffnen',
  'settings.shortcuts.action.switchToEngine': 'Engine öffnen',
  'settings.shortcuts.action.switchToMarketplace': 'Marktplatz öffnen',
  'settings.shortcuts.action.switchToTraining': 'Training öffnen',
  'settings.shortcuts.action.switchToQuantization': 'Quantisierung öffnen',
  'settings.shortcuts.action.switchToGenerative': 'Gen Studio öffnen',
  'settings.shortcuts.action.switchToNews': 'News öffnen',
  'settings.shortcuts.action.switchToSettings': 'Einstellungen öffnen',
  'settings.shortcuts.action.toggleSidebar': 'Seitenleiste umschalten',
  'settings.shortcuts.action.focusChatInput': 'Chat-Eingabe fokussieren',
  'settings.shortcuts.action.newChatSession': 'Neuen Chat starten',
  'settings.shortcuts.action.toggleChatTab': 'Zwischen Chat-Tabs wechseln',
  'settings.shortcuts.action.toggleEngine': 'Engine starten/stoppen',
  'settings.shortcuts.action.loadModel': 'Modell laden',
  'settings.shortcuts.action.focusSearch': 'Suche fokussieren',
  'settings.shortcuts.action.showHelp': 'Tastenkürzel-Hilfe anzeigen',
  'settings.shortcuts.action.toggleTheme': 'Theme umschalten',

  // Systeminformationen & Hilfe
  'settings.systemInfo.title': 'Systeminformationen',
  'settings.systemInfo.noGpu': 'Keine GPU erkannt',
  'settings.systemInfo.cpuDetecting': 'CPU wird erkannt …',
  'settings.systemInfo.diskFree': 'DISK FREE',
  'settings.systemInfo.detection': 'ERKENNUNG',
  'settings.systemInfo.source.philoengineHardware':
      'PhiloEngine-Systemerkennung',
  'settings.systemInfo.source.philoengineHardwareLive':
      'PhiloEngine-Systemerkennung + Live-Daten',
  'settings.systemInfo.source.nativeLive': 'Lokale Live-Erkennung',
  'settings.systemInfo.source.localFallback': 'Lokale Basiserkennung',
  'settings.help.title': 'Hilfe & Dokumentation',
  'settings.help.body':
      'Stellen Sie sicher, dass das myphiloengine Backend läuft, bevor Sie '
      'Operationen aufrufen. Standardmäßig lauscht es auf Port 8080.',

  // Plus-Menue (Datei/Aktion)
  'chat.plusMenu.webSearch': 'Websuche',
  'chat.plusMenu.webSearchDesc': 'Echtzeit-Informationen',
  'chat.plusMenu.restart': 'Neustart',
  'chat.plusMenu.restartDesc': 'Unterhaltung zurücksetzen',
  'chat.plusMenu.uploadFile': 'Datei hochladen',
  'chat.plusMenu.uploadFileDesc': 'Lokale Datei auswählen',

  // Modell-Wahl / Arbeitsanzeige
  'chat.modelChoice.localReady': 'Lokal • Bereit',
  'chat.working.modelLoading': 'Modell wird geladen',
  'chat.working.thinking': 'PhiloBot denkt nach',
  'chat.noActiveChat': 'Kein aktiver Chat',
  'chat.header.showFileTree': 'Dateibaum anzeigen',

  // Benachrichtigungen
  'chat.notification.modelSwitched': 'Modell gewechselt: {label}',
  'chat.notification.startModelFirst':
      'Bitte zuerst ein lokales Engine- oder API-Modell starten',
  'chat.notification.chatStarted': 'Neuer Chat mit {label} gestartet',
  'chat.notification.chooseAnotherModel':
      'Bitte jetzt ein anderes Modell auswählen',
  'chat.notification.botSaved':
      '{name} wurde in der Bot-Verwaltung gespeichert',
  'chat.notification.memoryCompressed': 'Memory wurde komprimiert',
  'chat.notification.replyCopied': 'Antwort kopiert',

  // Fehler
  'chat.error.modelSwitchFailed': 'Modellwechsel fehlgeschlagen',
  'chat.error.sessionStartFailed': 'Konnte Chat-Sitzung nicht starten',
  'chat.error.settingsAction': 'Einstellungen',
  'chat.error.responseFailed': 'Antwort konnte nicht erzeugt werden',

  // Modell-Warmup
  'chat.warmup.modelUnavailable': 'Das lokale Modell ist nicht mehr verfügbar.',
  'chat.warmup.modelReady': 'Modell ist bereit',
  'chat.warmup.queueTimeout': 'Der Modellstart hat zu lange gewartet.',
  'chat.warmup.startFailed':
      'Das lokale Modell konnte nicht gestartet werden: {error}',
  'chat.warmup.localModelFallback': 'Lokales Modell',

  // Bot-Test
  'chat.botTest.newBotFallback': 'der neue Bot',
  'chat.botTest.prompt':
      '{keyword}: Teste {name} mit einer kurzen Beispielantwort.',

  // Lade-/Leerzustaende
  'chat.loading.preparing': 'Chat wird vorbereitet …',
  'chat.loading.initNewChat': 'Initialisiere neuen Chat...',
  'chat.empty.noModelReady': 'Noch kein Modell bereit',
  'chat.empty.startModelHint':
      'Starte ein lokales Engine- oder API-Modell, um loszulegen.',
  'chat.empty.startLocalModel': 'Lokales Modell starten',
  'chat.empty.chooseApiModel': 'API-Modell wählen',

  // Agentische Ereignisse
  'chat.events.toolStartedGeneric': 'Tool gestartet',
  'chat.events.toolStarted': '{tool} gestartet',
  'chat.events.toolFinishedGeneric': 'Tool beendet',
  'chat.events.toolFinished': '{tool} beendet',
  'chat.events.planningQuestions': 'Planungsfragen',
  'chat.events.planReady': 'Plan bereit',
  'chat.events.approvalNeeded': 'Freigabe erforderlich',
  'chat.events.permissionRequested': 'Zugriff außerhalb angefragt',
  'chat.events.permissionOnce': 'Zugriff erlaubt (einmalig)',
  'chat.events.permissionSession': 'Zugriff erlaubt (Sitzung)',
  'chat.events.permissionDenied': 'Zugriff abgelehnt',
  'chat.events.fileCreated': 'Datei erstellt',
  'chat.events.fileDeleted': 'Datei gelöscht',
  'chat.events.fileMoved': 'Datei verschoben',
  'chat.events.fileModified': 'Datei geändert',
  'chat.events.memoryCompressed': 'Memory komprimiert',

  // Dateibaum
  'chat.fileTree.title': 'Dateien',
  'chat.fileTree.refresh': 'Aktualisieren',

  // Datei-Aenderungen
  'chat.fileChange.new': 'Neu',
  'chat.fileChange.deleted': 'Gelöscht',
  'chat.fileChange.moved': 'Verschoben',
  'chat.fileChange.modified': 'Geändert',

  // Planfreigabe
  'chat.planApproval.title': 'Planfreigabe',
  'chat.planApproval.reject': 'Ablehnen',
  'chat.planApproval.approve': 'Genehmigen',
  'chat.planApproval.approvedMessage': 'Plan genehmigt',

  // Zugriffsanfrage
  'chat.permission.requestClosed': 'Zugriffsanfrage war nicht mehr offen',

  // Erstellter Bot
  'chat.createdBot.nameFallback': 'Neuer Bot',
  'chat.createdBot.saved': '{name} gespeichert',
  'chat.createdBot.test': 'Testen',
  'chat.createdBot.edit': 'Bearbeiten',

  // Inline-Editor
  'chat.editor.hint': 'Nachricht bearbeiten …',
  'chat.editor.cancel': 'Abbrechen',
  'chat.editor.resend': 'Neu senden',

  // Nachrichten-Navigator
  'chat.navigator.jumpToMessage': 'Zu deiner Nachricht',

  // Nachrichten-Aktionen
  'chat.messageActions.edit': 'Bearbeiten',
  'chat.messageActions.copy': 'Text kopieren',
  'chat.messageActions.actions': 'Aktionen',

  // Schnell-Prompts
  'chat.quickPrompt.shorter': 'Formuliere die letzte Antwort deutlich kuerzer.',
  'chat.quickPrompt.critical':
      'Pruefe die letzte Antwort kritischer und nenne Schwachstellen.',
  'chat.quickPrompt.structure':
      'Strukturiere die letzte Antwort klarer mit Abschnitten und naechsten Schritten.',
  'chat.quickPrompt.tune':
      'Botbuilder: Verfeinere den gerade erstellten Bot anhand meiner bisherigen Antworten.',
  'chat.quickPrompt.thisBotFallback': 'diesen Bot',
  'chat.quickPrompt.rule':
      'Botbuilder: Ueberarbeite {bot} so, dass diese Antwortqualitaet dauerhaft als Bot-Regel uebernommen wird.',

  // Nachrichten-Menue
  'chat.menu.shorter': 'Kuerzer',
  'chat.menu.critical': 'Kritischer',
  'chat.menu.moreStructure': 'Mehr Struktur',
  'chat.menu.tune': 'Feintunen',
  'chat.menu.asRule': 'Als Regel',

  // Eingabeleiste
  'chat.input.hint': 'Nachricht...',
  'chat.input.addTooltip': 'Datei oder Chat-Aktion',
  'chat.input.modelBoundToBot':
      'Das Modell ist fest mit dem ausgewählten Bot verbunden',
  'chat.input.modelWarmingUp': 'Das Modell läuft gerade warm',
  'chat.input.voiceMessage': 'Sprachnachricht',

  // Senden-Button
  'chat.send.selectModelFirst': 'Bitte zuerst ein Modell auswählen',
  'chat.send.botWorking': 'PhiloBot arbeitet noch …',
  'chat.send.waitForModel': 'Warten, bis das Modell bereit ist',
  'chat.send.sendMessage': 'Nachricht senden',

  // Thinking-Slider
  'chat.thinkingSlider.faster': 'Schneller',
  'chat.thinkingSlider.smarter': 'Intelligenter',
  'chat.thinkingSlider.inDevelopment': 'In Entwicklung',

  // Chat-Verlauf: Umbenennen / Loeschen
  'chatHistory.rename.title': 'Chat umbenennen',
  'chatHistory.rename.hint': 'Titel',
  'chatHistory.rename.cancel': 'Abbrechen',
  'chatHistory.rename.save': 'Speichern',
  'chatHistory.delete.title': 'Chat löschen?',
  'chatHistory.delete.body': '„{title}" wird dauerhaft gelöscht.',
  'chatHistory.delete.cancel': 'Abbrechen',
  'chatHistory.delete.confirm': 'Löschen',
  'chatHistory.deleteProject.title': 'Ordner löschen?',
  'chatHistory.deleteProject.body':
      '„{name}" wird gelöscht. Die enthaltenen Chats bleiben erhalten und wandern zurück in die allgemeine Liste.',
  'chatHistory.deleteProject.cancel': 'Abbrechen',
  'chatHistory.deleteProject.confirm': 'Löschen',

  // Chat-Verlauf: Panel
  'chatHistory.newFolder': 'Neuer Ordner',
  'chatHistory.sectionProjects': 'Projekte',
  'chatHistory.sectionHistory': 'Verlauf',
  'chatHistory.sectionChats': 'Chats',
  'chatHistory.empty':
      'Noch keine Chats — starte eine neue Unterhaltung oder lege einen Ordner an.',

  // Chat-Verlauf: Projekt-Dialog
  'chatHistory.projectDialog.titleEdit': 'Ordner bearbeiten',
  'chatHistory.projectDialog.titleNew': 'Neuer Ordner',
  'chatHistory.projectDialog.nameHint': 'Projektname',
  'chatHistory.projectDialog.nameError': 'Bitte einen Namen eingeben',
  'chatHistory.projectDialog.pathError': 'Bitte Pfad angeben oder deaktivieren',
  'chatHistory.projectDialog.colorLabel': 'FARBE',
  'chatHistory.projectDialog.iconLabel': 'ICON',
  'chatHistory.projectDialog.pathToggle':
      'Projektpfad festlegen (Dateizugriff im Chat)',
  'chatHistory.projectDialog.pathHint': '/pfad/zum/projekt',
  'chatHistory.projectDialog.browse': 'Durchsuchen',
  'chatHistory.projectDialog.browseTitle': 'Projektpfad wählen',
  'chatHistory.projectDialog.cancel': 'Abbrechen',
  'chatHistory.projectDialog.save': 'Speichern',
  'chatHistory.projectDialog.create': 'Erstellen',

  // Chat-Verlauf: Zeilen-Aktionen
  'chatHistory.projectRow.newChat': 'Neuer Chat im Ordner',
  'chatHistory.projectRow.edit': 'Ordner bearbeiten',
  'chatHistory.projectRow.delete': 'Ordner löschen',
  'chatHistory.chatRow.move': 'In Ordner verschieben',
  'chatHistory.chatRow.removeFromFolder': 'Aus Ordner entfernen',
  'chatHistory.chatRow.noFolders': 'Keine Ordner vorhanden',
  'chatHistory.chatRow.rename': 'Umbenennen',
  'chatHistory.chatRow.delete': 'Löschen',

  // Philox-Tab
  'philox.header.agentSession': 'Agent Session: {id}',
  'philox.header.sessionConfig': 'Sitzungskonfiguration',
  'philox.header.toggleParams': 'Parameter einblenden/ausblenden',
  'philox.loading.initAgent': 'Initialisiere Agenten...',
  'philox.empty.noSession': 'Keine aktive Sitzung',
  'philox.planApproval.title': 'Planfreigabe erforderlich',
  'philox.planApproval.body':
      'Der Philox Agent hat einen Ausführungsplan entworfen und wartet auf Ihre Genehmigung.',
  'philox.planApproval.reject': 'Ablehnen',
  'philox.planApproval.approve': 'Plan genehmigen',
  'philox.params.title': 'Agenten Parameter',
  'philox.params.thinkingLevel': 'THINKING LEVEL',
  'philox.params.executionMode': 'AUSFÜHRUNGSMODUS',
  'philox.params.allowedRoots': 'ERLAUBTE PFADE (ROOTS)',
  'philox.params.endSession': 'Session beenden',
  'philox.input.hint': 'Agenten instruieren...',
  'philox.input.voiceControl': 'Sprachsteuerung',

  // News
  'news.title': 'AI & Tech Feed',
  'news.subtitle':
      'Live-Nachrichten aggregiert aus führenden Hardware- und KI-Quellen.',
  'news.refresh': 'Aktualisieren',
  'news.searchHint': 'Suche nach Schlagworten, Inhalten oder Tags...',
  'news.categoryLabel': 'KATEGORIE:',
  'news.categoryAll': 'Alle',
  'news.categoryReleases': 'KI-Releases',
  'news.categoryHardware': 'Hardware',
  'news.categoryOpenSource': 'Open Source',
  'news.categoryResearch': 'Research',
  'news.noResults': 'Keine passenden Artikel gefunden.',
  'news.empty': 'Momentan sind keine Artikel verfügbar.',
  'news.resetFilters': 'Filter zurücksetzen',
  'news.loadError': 'Fehler beim Laden der Neuigkeiten: {error}',
  'news.readMore': 'Weiterlesen',

  // Bots Management
  'bots.title': 'Bot-Verwaltung',
  'bots.subtitle':
      'Erstelle und verwalte spezialisierte KI-Assistenten und Bots.',
  'bots.newBot': 'Neuer Bot',
  'bots.createTitle': 'Neuen Bot erstellen',
  'bots.editTitle': 'Bot bearbeiten: {name}',
  'bots.nameLabel': 'BOT NAME',
  'bots.nameHint': 'z.B. Code Assistent',
  'bots.promptLabel': 'SYSTEM PROMPT / INSTRUKTIONEN',
  'bots.promptHint': 'Gib dem Bot Regeln und Fachwissen mit...',
  'bots.keywordsLabel': 'SCHLÜSSELWÖRTER (AUTOROUTING)',
  'bots.keywordsHint': 'z.B. python, refactor, code',
  'bots.rootsLabel': 'ERLAUBTE PFADE (ROOTS)',
  'bots.rootsHint': '/pfad/zum/projekt',
  'bots.defaultLabel': 'Als Standard-Bot setzen',
  'bots.agenticLabel': 'Agentische Tools aktivieren (Dateien, Suche)',
  'bots.styleLabel': 'ANTWORT-STIL',
  'bots.styleBalanced': 'Ausgewogen',
  'bots.stylePrecise': 'Präzise / Logisch',
  'bots.styleCreative': 'Kreativ',
  'bots.modelBindingLabel': 'MODELL-BINDUNG',
  'bots.modelBindingAuto': 'Automatisch (Aktives Modell verwenden)',
  'bots.save': 'Bot speichern',
  'bots.delete': 'Bot löschen',
  'bots.deleteConfirm': 'Möchtest du "{name}" wirklich löschen?',
  'bots.saved': 'Bot "{name}" erfolgreich gespeichert',
  'bots.deleted': 'Bot "{name}" gelöscht',
  'bots.lockedBotHint':
      'System-Bot (kann nicht bearbeitet oder gelöscht werden)',

  // Training
  'training.title': 'Feintuning starten (Axolotl / Unsloth)',
  'training.subtitle':
      'Passe bestehende Sprachmodelle auf eigene Datensätze an.',
  'training.baseModelId': 'BASIS MODELL ID',
  'training.datasetPath': 'DATENSET PFAD',
  'training.hyperparams': 'HYPERPARAMETER (JSON)',
  'training.start': 'Training starten',
  'training.queueTitle': 'Trainings-Queue & Jobs',
  'training.emptyJobs': 'Keine aktiven Trainings-Jobs.',

  // Quantisierung
  'quantization.title': 'Modell quantisieren (llama.cpp)',
  'quantization.subtitle':
      'Komprimiere GGUF/Safetensors Modelle für mehr Geschwindigkeit.',
  'quantization.sourcePath': 'QUELL MODELL PFAD',
  'quantization.outputPath': 'ZIEL PFAD',
  'quantization.targetType': 'ZIEL-QUANTISIERUNG (TYPE)',
  'quantization.start': 'Quantisierung starten',
  'quantization.queueTitle': 'Quantisierungs-Queue & Jobs',
  'quantization.emptyJobs': 'Keine aktiven Quantisierungs-Jobs.',

  // GenStudio
  'genstudio.imageGenTab': 'Bildgenerierung',
  'genstudio.videoGenTab': 'Videogenerierung',
  'genstudio.imageTitle': 'Bild generieren',
  'genstudio.videoTitle': 'Video generieren',
  'genstudio.promptLabel': 'PROMPT / INHALT',
  'genstudio.promptPlaceholderImage':
      'Ein Ölgemälde eines Philosophen im antiken Griechenland...',
  'genstudio.promptPlaceholderVideo':
      'Ein Zoom in die Augen einer antiken Eule...',
  'genstudio.modelLabel': 'MODELL',
  'genstudio.submitImage': 'Bild generieren',
  'genstudio.submitVideo': 'Video generieren',

  // Marketplace
  'marketplace.title': 'Modell-Marktplatz',
  'marketplace.searchHint': 'Suche nach Modellen, Anbietern oder Tags...',
  'marketplace.providerAll': 'Alle Provider',
  'marketplace.categoryAll': 'Alle Kategorien',
  'marketplace.sortPopularity': 'Beliebtheit',
  'marketplace.sortIntelligence': 'Intelligence-Score',
  'marketplace.sortContext': 'Kontextfenster',
  'marketplace.sortNewest': 'Neu zuerst',
  'marketplace.gpuFit': 'Nur GPU-passende Modelle',
  'marketplace.localOnly': 'Nur lokale Modelle (HuggingFace)',
  'marketplace.download': 'Herunterladen',
  'marketplace.downloading': 'Lade herunter... {progress}%',
  'marketplace.startModel': 'Modell starten',
  'marketplace.starting': 'Startet...',
  'marketplace.stopModel': 'Stoppen',
  'marketplace.details': 'Details anzeigen',
  'marketplace.noResults': 'Keine passenden Modelle gefunden.',

  // Engine
  'engine.title': 'Engine & Instanzen',
  'engine.subtitle': 'Verwalte lokale Modell-Instanzen und Server-Auslastung.',
  'engine.syncStatus': 'SYSTEMDATEN WERDEN AUTOMATISCH SYNCHRONISIERT',
  'engine.removeInstance': 'Modellinstanz entfernen',
  'engine.stopInstance': 'Stoppen',
  'engine.startInstance': 'Starten',
  'engine.restartInstance': 'Neu starten',
  'engine.responseBehavior': 'Antwortverhalten',
  'engine.context': 'Kontext',
  'engine.detailsMore': 'Details',
  'engine.detailsLess': 'Weniger',
  'engine.samplingDefaults': 'Sampling-Defaults',
  'engine.liveApply': 'Live anwenden',
  'engine.runCodeConfirm': 'Modellcode ausführen?',
  'engine.agreeAndStart': 'Zustimmen & starten',
  'engine.recalcRam': 'Mit RAM neu berechnen',
  'engine.confirmDelete': 'Entgültig löschen',
};
