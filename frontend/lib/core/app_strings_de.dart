const Map<String, String> appStringsDe = {
  'common.cancel': 'Abbrechen',
  'common.save': 'Speichern',
  'common.delete': 'Löschen',
  'common.close': 'Schließen',
  'common.retry': 'Erneut versuchen',

  'onboarding.title': 'Willkommen!',
  'onboarding.subtitle':
      'Richte deine persönlichen Einstellungen ein. Du kannst sie später jederzeit in den Einstellungen ändern.',
  'onboarding.languageTitle': 'Sprache',
  'onboarding.languageGerman': 'Deutsch',
  'onboarding.languageEnglish': 'English',
  'onboarding.providerTitle': 'Anbieter verbinden',
  'onboarding.providerDescription':
      'Zum Chatten braucht es einen verbundenen KI-Anbieter. Jetzt verbinden oder später unter Einstellungen › Server / API nachholen.',
  'onboarding.providerButton': 'Anbieter-Einstellungen öffnen',
  'onboarding.start': 'Los geht\'s',

  'sidebar.chat': 'Chat',
  'sidebar.engine': 'Engine',
  'sidebar.marketplace': 'Marktplatz',
  'sidebar.news': 'News',
  'sidebar.benchmark': 'Benchmark',
  'sidebar.modules': 'Module',
  'sidebar.history': 'Chat',
  'sidebar.models': 'Modell',

  'settings.appearance': 'Darstellung',
  'settings.language': 'Sprache',

  'dashboard.logoutTitle': 'Abmelden',
  'dashboard.logoutConfirm': 'Möchtest du dich wirklich ausloggen?',
  'dashboard.logoutYes': 'Ja, abmelden',
  'dashboard.tooltipSettings': 'Einstellungen',
  'dashboard.tooltipLogout': 'Abmelden',
  'dashboard.tooltipNewChat': 'Neuer Chat',
  'dashboard.codeBlockSwitch': 'Codeblock wechseln',
  'dashboard.codeBlockN': 'Codeblock {n}',
  'dashboard.codeClose': 'Code-Ansicht schließen',
  'dashboard.codeCopied': 'Code kopiert',
  'dashboard.copy': 'Kopieren',

  'login.error.invalidCredentials': 'Anmeldedaten ungueltig',
  'login.error.invalidCode': 'Code ist ungueltig',

  'login.validation.required': 'Pflichtfeld',
  'login.validation.codeInvalid': '6-stelligen Code eingeben',

  'login.setup.title': 'Authenticator einrichten',
  'login.setup.scanHint2fas':
      '2FAS öffnen, „+“ wählen und den QR-Code scannen.',
  'login.setup.scanHintGoogle':
      'Google Authenticator öffnen, „+“ wählen und den QR-Code scannen.',
  'login.setup.codeHint': 'Code aus der App',
  'login.setup.confirm': 'Einrichtung bestätigen',
  'login.setup.loadError': 'Setup konnte nicht geladen werden.',

  'login.welcome.title': 'Willkommen zurück',
  'login.welcome.subtitle': 'Melde dich an, um dein Studio zu öffnen.',

  'login.field.usernameLabel': 'BENUTZERNAME',
  'login.field.usernameHint': 'Benutzername eingeben',
  'login.field.passwordLabel': 'PASSWORT',
  'login.field.passwordHint': 'Passwort eingeben',
  'login.field.showPassword': 'Passwort anzeigen',
  'login.field.hidePassword': 'Passwort verbergen',

  'login.remember.label': 'Angemeldet bleiben',
  'login.remember.duration': 'Sitzungsdauer',
  'login.duration.8h': '8 Std.',
  'login.duration.24h': '24 Std.',
  'login.duration.48h': '48 Std.',
  'login.duration.permanent': 'Dauerhaft',

  'login.action.login': 'Anmelden',
  'login.action.createAccount': 'Account erstellen',
  'login.action.forgotPassword': 'Passwort vergessen',

  'login.footer.copyright': '© 2026 culpeohq. Alle Rechte vorbehalten.',
  'login.footer.credits':
      'Powered by Culpeo Studio • Design & Development by culpeohq',

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

  'settings.nav.title': 'EINSTELLUNGEN',
  'settings.nav.general': 'Allgemein',
  'settings.nav.serverApi': 'Server / API',
  'settings.nav.shortcuts': 'Shortkarts',
  'settings.nav.botManagement': 'Bot-Verwaltung',
  'settings.nav.chatBot': 'Chat-Bot',
  'settings.nav.skills': 'Skills',

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

  'settings.health.reachable': 'Erreichbar',
  'settings.health.unreachable': 'Nicht erreichbar',
  'settings.health.httpResponse': 'Antwortet mit HTTP {code}',
  'settings.health.error': 'Fehler',

  'settings.serverApi.title': 'Server & API-Schnittstellen',
  'settings.serverApi.subtitle':
      'Verbindung zu lokalen Servern und Cloud-Modell-Anbietern verwalten',
  'settings.serverApi.recheckTooltip': 'Verbindungen neu prüfen',
  'settings.serverApi.addNode': 'Node hinzufügen',
  'settings.serverApi.localServer': 'Lokaler Server',

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

  'settings.serverApi.phaseNote.title': 'Kommt in Phase 2',
  'settings.serverApi.phaseNote.body':
      'Eigene API-Nodes lassen sich bereits anlegen und auf Erreichbarkeit prüfen, sind aber noch nicht als aktive Verbindung in den Chat/Engine nutzbar. Die volle Funktion folgt mit Phase 2.',

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

  'settings.provider.enabled': 'Aktiviert',
  'settings.provider.keySet': 'Key eingerichtet',
  'settings.provider.keyMissing': 'Key fehlt',
  'settings.provider.checking': 'Prüfe...',

  'settings.chatBot.title': 'Chat-Bot',
  'settings.chatBot.description':
      'Lege fest, ob neue Chats einen bestimmten Bot verwenden oder den '
      'passenden Bot automatisch auswählen.',
  'settings.chatBot.defaultLabel': 'STANDARD FÜR NEUE CHATS',
  'settings.chatBot.note':
      'Laufende Chats behalten ihren bisher verwendeten Bot.',
  'settings.chatBot.empty':
      'Keine Bots verfügbar. Erstelle zuerst einen Bot in der Bot-Verwaltung.',
  'settings.chatBot.openManagement': 'Bot-Verwaltung öffnen',

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

  'settings.shortcuts.title': 'Tastenkombinationen (Shortkarts)',
  'settings.shortcuts.description':
      'Klicken Sie auf ein Tastenkürzel, um es neu aufzunehmen. Drücken Sie '
      'anschließend die gewünschte Tastenkombination.',
  'settings.shortcuts.pressKeys': 'Drücke Tasten...',
  'settings.shortcuts.action.switchToChat': 'Chat öffnen',
  'settings.shortcuts.action.switchToSpark': 'Spark Agent öffnen',
  'settings.shortcuts.action.switchToEngine': 'Engine öffnen',
  'settings.shortcuts.action.switchToMarketplace': 'Marktplatz öffnen',
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

  'settings.systemInfo.title': 'Systeminformationen',
  'settings.systemInfo.noGpu': 'Keine GPU erkannt',
  'settings.systemInfo.cpuDetecting': 'CPU wird erkannt …',
  'settings.systemInfo.diskFree': 'DISK FREE',
  'settings.systemInfo.detection': 'ERKENNUNG',
  'settings.systemInfo.source.culpeostudioHardware':
      'Culpeo-Studio-Systemerkennung',
  'settings.systemInfo.source.culpeostudioHardwareLive':
      'Culpeo-Studio-Systemerkennung + Live-Daten',
  'settings.systemInfo.source.nativeLive': 'Lokale Live-Erkennung',
  'settings.systemInfo.source.localFallback': 'Lokale Basiserkennung',
  'settings.help.title': 'Hilfe & Dokumentation',
  'settings.help.body':
      'Stellen Sie sicher, dass das culpeostudio Backend läuft, bevor Sie '
      'Operationen aufrufen. Standardmäßig lauscht es auf Port 8080.',

  'chat.modelChoice.localReady': 'Lokal • Bereit',

  'chat.warmup.modelReady': 'Modell ist bereit',

  'chat.planApproval.reject': 'Ablehnen',

  'chat.thinkingSlider.faster': 'Schneller',
  'chat.thinkingSlider.smarter': 'Intelligenter',
  'chat.thinkingSlider.inDevelopment': 'In Entwicklung',

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
  'chatHistory.deleteProject.withChats':
      'Die {count} enthaltenen Chats mitlöschen',
  'chatHistory.deleteProject.confirm': 'Löschen',

  'chatHistory.newFolder': 'Neuer Ordner',
  'chatHistory.sectionProjects': 'Projekte',
  'chatHistory.sectionHistory': 'Verlauf',
  'chatHistory.sectionChats': 'Chats',
  'chatHistory.empty':
      'Noch keine Chats — starte eine neue Unterhaltung oder lege einen Ordner an.',

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

  'chatHistory.projectRow.newChat': 'Neuer Chat im Ordner',
  'chatHistory.projectRow.edit': 'Ordner bearbeiten',
  'chatHistory.projectRow.delete': 'Ordner löschen',
  'chatHistory.chatRow.move': 'In Ordner verschieben',
  'chatHistory.chatRow.removeFromFolder': 'Aus Ordner entfernen',
  'chatHistory.chatRow.removeFromSubfolder': 'Aus Unterordner entfernen',
  'chatHistory.chatRow.noFolders': 'Keine Ordner vorhanden',
  'chatHistory.chatRow.rename': 'Umbenennen',
  'chatHistory.chatRow.delete': 'Löschen',

  'chatHistory.newSubfolder': 'Neuer Unterordner',
  'chatHistory.deleteSubfolder.title': 'Unterordner löschen?',
  'chatHistory.deleteSubfolder.body':
      '„{name}" wird gelöscht. Die enthaltenen Chats bleiben erhalten und wandern zurück ins Projekt.',
  'chatHistory.subfolderDialog.titleEdit': 'Unterordner bearbeiten',
  'chatHistory.subfolderDialog.titleNew': 'Neuer Unterordner',
  'chatHistory.subfolderDialog.nameHint': 'Ordnername',
  'chatHistory.subfolderDialog.nameError': 'Bitte einen Namen eingeben',
  'chatHistory.subfolderDialog.colorLabel': 'FARBE',
  'chatHistory.subfolderRow.newChat': 'Neuer Chat im Unterordner',
  'chatHistory.subfolderRow.edit': 'Unterordner bearbeiten',
  'chatHistory.subfolderRow.delete': 'Unterordner löschen',

  'news.title': 'AI & Tech Feed',
  'news.refresh': 'Aktualisieren',
  'news.searchHint': 'Suche nach Schlagworten, Inhalten oder Tags...',
  'news.categoryLabel': 'KATEGORIE:',
  'news.categoryAll': 'Alle',
  'news.categoryReleases': 'KI-Releases',
  'news.categoryHardware': 'Hardware',
  'news.categorySoftware': 'Software & Entwicklung',
  'news.categorySecurity': 'Security',
  'news.categoryOpenSource': 'Open Source',
  'news.categoryResearch': 'Research',
  'news.noResults': 'Keine passenden Artikel gefunden.',
  'news.empty': 'Momentan sind keine Artikel verfügbar.',
  'news.resetFilters': 'Filter zurücksetzen',
  'news.sourceLabel': 'ANBIETER:',
  'news.sourceAll': 'Alle Anbieter',
  'news.savedFilter': 'Gespeichert',
  'news.save': 'Bericht speichern',
  'news.unsave': 'Aus Merkliste entfernen',
  'news.savedEmpty': 'Du hast noch keine Berichte gespeichert.',
  'news.savedLoadError':
      'Gespeicherte Berichte konnten nicht geladen werden: {error}',
  'news.loadError': 'Fehler beim Laden der Neuigkeiten: {error}',

  'benchmark.title': 'Benchmark',
  'benchmark.subtitle':
      'Tagesaktuelle Wertungen aus der LMArena: echte Menschen vergleichen zwei Antworten und stimmen ab.',
  'benchmark.tabLeaderboard': 'Rangliste',
  'benchmark.tabCompare': 'Vergleich',

  'benchmark.board.arena_text': 'LMArena · Text',

  'benchmark.sourceLive': 'Tagesaktuell',
  'benchmark.sourceAsOf': 'Stand',
  'benchmark.refreshAction': 'Aktualisieren',
  'benchmark.refreshStarted': 'Abgleich läuft – das dauert einen Moment.',
  'benchmark.loadingTitle': 'Rangliste wird geladen',
  'benchmark.loadingProgress': '{loaded} von {total} Läufen',
  'benchmark.loadingHint':
      'Der erste Abgleich holt den kompletten Datensatz und legt ihn lokal ab.',
  'benchmark.loadFailed': 'Benchmark-Daten konnten nicht geladen werden.',

  'benchmark.metricEvaluated': '{count} bewertet',
  'benchmark.metricFieldMedian': 'Median des Feldes',
  'benchmark.metricFieldBest': 'Bestwert',
  'benchmark.metricSpanLabel':
      '{metric}: Median des Feldes {median}, Bestwert {max}.',
  'benchmark.metricLeader': 'Kategoriesieger',

  'benchmark.wikiOpen': 'Benchmark-Wiki öffnen',
  'benchmark.wikiTitle': 'Benchmark-Wiki',
  'benchmark.wikiIntro':
      'Diese Rangliste entsteht aus Duellen: Menschen stellen zwei Modellen dieselbe Frage, sehen beide Antworten ohne Namen und wählen die bessere. Je öfter ein Modell gewinnt, desto weiter oben steht es. Tippe unten auf einen Punkt, um zu sehen, was er bedeutet.',
  'benchmark.wikiReading': 'So liest du die Rangliste',
  'benchmark.wikiCategories': 'Was die einzelnen Kategorien messen',
  'benchmark.wikiCategoriesHint':
      'Jede Kategorie prüft eine andere Fähigkeit. Tippe eine an, um zu sehen, was dort getestet wird und wie groß der Abstand zwischen den Modellen ist.',
  'benchmark.wikiExplain': 'Was misst diese Kategorie?',
  'benchmark.wikiExplainColumn':
      'Klicken sortiert · Rechtsklick erklärt die Kategorie',
  'benchmark.wikiScoreTitle': 'Die Gesamtwertung ({label})',
  'benchmark.wikiScoreElo':
      'Die Gesamtwertung ist eine Vergleichszahl, keine Prozentzahl. Sie steigt, wenn ein Modell häufig gewinnt, und sinkt bei Niederlagen. Ein Abstand von rund 100 Punkten heißt: das stärkere Modell gewinnt etwa zwei von drei Duellen. Ein einzelner Wert sagt darum wenig – erst der Abstand zwischen zwei Modellen sagt, welches wirklich besser ist.',
  'benchmark.wikiScorePercent':
      'Die Gesamtwertung fasst alle Kategorien zu einer einzigen Zahl zusammen – höchstens {max}. Sie eignet sich gut zum Vergleich zweier Modelle. Nur zur Vorsicht: Eine hohe Gesamtzahl heißt nicht automatisch, dass das Modell in jeder Kategorie vorn liegt – dafür schau in die einzelnen Balken.',
  'benchmark.wikiRankTitle': 'Platz und der helle Strich im Balken',
  'benchmark.wikiRankText':
      'Der Platz ist eine Momentaufnahme: Liegen zwei Modelle nur wenige Punkte auseinander, ist die Reihenfolge fast Zufall – erst ein deutlicher Abstand bedeutet wirklich besser. Der helle Strich im Balken markiert die Mitte des Feldes: die Hälfte aller Modelle liegt darunter. Ein Balken, der darüber hinausragt, ist überdurchschnittlich.',
  'benchmark.wikiTypeTitle': '{open} oder {api}',
  'benchmark.wikiTypeText':
      '»{open}« heißt: Das Modell ist frei – du kannst es selbst herunterladen und ausprobieren. »{api}« heißt: Das Modell läuft nur beim Anbieter und du bezahlst pro Anfrage. Mit dem Filter »Typ« blendest du eine der beiden Gruppen aus.',
  'benchmark.wikiCompareTitle': 'Modelle nebeneinanderlegen',
  'benchmark.wikiCompareText':
      'Mit dem Pfeilsymbol am Ende einer Zeile legst du ein Modell in den Vergleich. Dort stehen bis zu zwölf Modelle nebeneinander: Die erste Spalte ist der Bezugspunkt, alle weiteren zeigen den Abstand dazu.',
  'benchmark.wikiSourceTitle': 'Woher die Daten kommen',
  'benchmark.wikiSourceText':
      'Die Daten der Rangliste werden einmal heruntergeladen und lokal abgelegt. Mit »Aktualisieren« holst du den aktuellen Stand – oben rechts steht das Datum der letzten Abfrage. Downloads und Hersteller im Detailfenster kommen live vom Hugging-Face-Hub; Angaben, die nur in der Modellbeschreibung stehen, sind nicht geprüft.',
  'benchmark.wikiNoDescription':
      'Zu dieser Kategorie gibt es keine Beschreibung.',

  'benchmark.metric.hard_prompts.desc':
      'Die härtesten und kniffligsten Anfragen der Arena – hier zeigen sich die Spitzenmodelle.',
  'benchmark.metric.coding.desc':
      'Wer schreibt den Code, den Menschen besser finden? Menschen bewerten die Antworten zu Programmieraufgaben.',
  'benchmark.metric.math.desc':
      'Rechen- und Mathematikaufgaben: So gut kann das Modell mit Zahlen und Beweisen umgehen.',
  'benchmark.metric.creative_writing.desc':
      'Freies Schreiben – Geschichten, Texte, Stil. Menschen vergleichen die Antworten direkt und wählen die bessere.',
  'benchmark.metric.instruction_following.desc':
      'Wie genau macht das Modell das, was tatsächlich gefragt war – auch bei ungewöhnlichen Anweisungen?',
  'benchmark.metric.multi_turn.desc':
      'Gespräche über mehrere Runden: Behält das Modell den Faden und erinnert sich, was vorher gesagt wurde?',
  'benchmark.metric.longer_query.desc':
      'Lange, ausführliche Fragen statt kurzer Einzeiler – wichtig, damit das Modell auch bei komplizierten Texten nicht aufgibt.',
  'benchmark.metric.non_english.desc':
      'Fragen in anderen Sprachen als Englisch – viele Modelle sind vor allem auf Englisch stark.',

  'benchmark.family.instruction': 'Anweisungen',
  'benchmark.family.reasoning': 'Schlussfolgern',
  'benchmark.family.math': 'Mathematik',
  'benchmark.family.coding': 'Programmieren',
  'benchmark.family.creative': 'Kreatives',
  'benchmark.family.conversation': 'Gespräch',
  'benchmark.family.language': 'Sprachen',

  'benchmark.metricNoData':
      'Für diese Wertung liegen im aktuellen Abzug keine Werte vor.',

  'benchmark.searchHint': 'Modell, Anbieter oder Architektur suchen…',
  'benchmark.filterType': 'Typ',
  'benchmark.filterOrg': 'Anbieter',
  'benchmark.filterAll': 'Alle',
  'benchmark.filterReset': 'Filter zurücksetzen',
  'benchmark.sortLabel': 'Sortierung',
  'benchmark.sortAverage': 'Gesamtwertung',
  'benchmark.sortName': 'Name',
  'benchmark.resultCount': '{count} Modelle',
  'benchmark.empty': 'Keine Modelle passen zu diesen Filtern.',
  'benchmark.loadMore': 'Weitere laden',

  'benchmark.columnRank': 'Platz',
  'benchmark.columnModel': 'Modell',
  'benchmark.columnOrg': 'Anbieter',
  'benchmark.columnType': 'Typ',
  'benchmark.metricWindowRange': '{from}–{to} von {total}',

  'benchmark.type.open_weights': 'Open Source',
  'benchmark.type.proprietary': 'API',

  'benchmark.detailRank': 'Platz {rank} von {total}',
  'benchmark.detailPercentile': 'Stärker als {value} % aller Läufe',
  'benchmark.detailScores': 'Teilwertungen',
  'benchmark.detailVsMedianUp': '{diff} über dem Median',
  'benchmark.detailVsMedianDown': '{diff} unter dem Median',
  'benchmark.detailRankShort': 'Platz {rank}',
  'benchmark.detailRuns': 'Ausgewertete Läufe',
  'benchmark.detailFacts': 'Eckdaten',
  'benchmark.factLicense': 'Lizenz',
  'benchmark.factType': 'Typ',
  'benchmark.factOrg': 'Anbieter',
  'benchmark.factSubmitted': 'Stand der Auswertung',

  'benchmark.detail.votes': 'Abstimmungen',
  'benchmark.detail.confidence': 'Vertrauensbereich',
  'benchmark.detail.variance': 'Streuung der Wertung',
  'benchmark.detail.arena_rank': 'Platz laut Arena',

  'benchmark.hubTitle': 'Live vom Hugging-Face-Hub',
  'benchmark.hubDownloads': 'Downloads (30 Tage)',
  'benchmark.hubDownloadsTotal': 'Downloads gesamt',
  'benchmark.hubLikes': 'Likes',
  'benchmark.hubTrending': 'Trend-Punkte',
  'benchmark.hubUpdated': 'Zuletzt geändert',
  'benchmark.hubGated': 'Zugang beschränkt',
  'benchmark.hubParams': 'Parameter laut Gewichten',
  'benchmark.hubMissing':
      'Dieses Repository liegt nicht mehr auf dem Hub – gelöscht oder umbenannt.',
  'benchmark.cardResults': 'Herstellerangaben aus der Model-Card',
  'benchmark.cardResultsNote': 'Selbst gemeldet, nicht unabhängig geprüft.',
  'benchmark.openOnHub': 'Quelle des Modells öffnen',
  'benchmark.openLinkFailed': 'Link konnte nicht geöffnet werden: {url}',
  'benchmark.addToCompare': 'Zum Vergleich',
  'benchmark.noLeaderboardEntry':
      'Zu diesem Modell gibt es keinen Arena-Eintrag – es wurde dort noch nicht bewertet. Unten stehen die Live-Zahlen des Hubs.',

  'benchmark.compareEmpty':
      'Wähle in der Rangliste bis zu vier Modelle für den direkten Vergleich.',
  'benchmark.compareRemove': 'Aus Vergleich entfernen',
  'benchmark.compareCount': '{count} Modelle im Vergleich',
  'benchmark.compareClear': 'Vergleich leeren',
  'benchmark.compareLimit':
      'Mehr als zwölf Modelle lassen sich nicht vergleichen.',
  'benchmark.compareAdded': '{model} steht jetzt im Vergleich.',
  'benchmark.compareAlready': '{model} steht bereits im Vergleich.',
  'benchmark.compareScores': 'Wertungen im Vergleich',
  'benchmark.compareBest': 'Bester Wert der Auswahl',
  'benchmark.compareNoData': 'Für dieses Modell liegen keine Wertungen vor.',

  'bots.title': 'Bot-Verwaltung',
  'bots.createTitle': 'Neuen Bot erstellen',
  'bots.deleteConfirm': 'Möchtest du "{name}" wirklich löschen?',
  'bots.saved': 'Bot "{name}" erfolgreich gespeichert',
  'bots.deleted': 'Bot "{name}" gelöscht',

  'engine.syncStatus': 'SYSTEMDATEN WERDEN AUTOMATISCH SYNCHRONISIERT',
  'engine.stopInstance': 'Stoppen',
  'engine.startInstance': 'Starten',
  'engine.responseBehavior': 'Antwortverhalten',
  'engine.context': 'Kontext',
  'engine.detailsMore': 'Details',
  'engine.detailsLess': 'Weniger',
};
