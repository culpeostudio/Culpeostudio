const Map<String, String> appStringsEn = {
  'common.cancel': 'Cancel',
  'common.save': 'Save',
  'common.delete': 'Delete',
  'common.close': 'Close',
  'common.retry': 'Retry',

  'onboarding.title': 'Welcome!',
  'onboarding.subtitle':
      'Set up your personal preferences. You can change them anytime in the settings.',
  'onboarding.languageTitle': 'Language',
  'onboarding.languageGerman': 'Deutsch',
  'onboarding.languageEnglish': 'English',
  'onboarding.versionTitle': 'Frontend version',
  'onboarding.versionClassic': 'Classic',
  'onboarding.versionClassicDesc': 'All modules are shown.',
  'onboarding.versionLite': 'Lite',
  'onboarding.versionLiteDesc':
      'Only Chat, Engine, Marketplace, News and Benchmark are shown.',
  'onboarding.start': 'Get started',

  'sidebar.chat': 'Chat',
  'sidebar.engine': 'Engine',
  'sidebar.marketplace': 'Marketplace',
  'sidebar.news': 'News',
  'sidebar.benchmark': 'Benchmark',
  'sidebar.modules': 'Modules',
  'sidebar.history': 'Chat',
  'sidebar.models': 'Model',

  'settings.appearance': 'Appearance',
  'settings.language': 'Language',
  'settings.frontendVersion': 'Frontend version',
  'settings.frontendVersionClassic': 'Classic (all modules)',
  'settings.frontendVersionLite':
      'Lite (Chat, Engine, Marketplace, News, Benchmark)',

  'dashboard.logoutTitle': 'Log out',
  'dashboard.logoutConfirm': 'Do you really want to log out?',
  'dashboard.logoutYes': 'Yes, log out',
  'dashboard.tooltipSettings': 'Settings',
  'dashboard.tooltipLogout': 'Log out',
  'dashboard.tooltipNewChat': 'New chat',
  'dashboard.codeBlockSwitch': 'Switch code block',
  'dashboard.codeBlockN': 'Code block {n}',
  'dashboard.codeClose': 'Close code view',
  'dashboard.codeCopied': 'Code copied',
  'dashboard.copy': 'Copy',

  'login.error.invalidCredentials': 'Invalid credentials',
  'login.error.invalidCode': 'Invalid code',

  'login.validation.required': 'Required field',
  'login.validation.codeInvalid': 'Enter the 6-digit code',

  'login.setup.title': 'Set up authenticator',
  'login.setup.scanHint2fas': 'Open 2FAS, tap "+" and scan the QR code.',
  'login.setup.scanHintGoogle':
      'Open Google Authenticator, tap "+" and scan the QR code.',
  'login.setup.codeHint': 'Code from the app',
  'login.setup.confirm': 'Confirm setup',
  'login.setup.loadError': 'Setup could not be loaded.',

  'login.welcome.title': 'Welcome back',
  'login.welcome.subtitle': 'Sign in to open your studio.',

  'login.field.usernameLabel': 'USERNAME',
  'login.field.usernameHint': 'Enter username',
  'login.field.passwordLabel': 'PASSWORD',
  'login.field.passwordHint': 'Enter password',
  'login.field.showPassword': 'Show password',
  'login.field.hidePassword': 'Hide password',

  'login.remember.label': 'Stay signed in',
  'login.remember.duration': 'Session duration',
  'login.duration.8h': '8 hrs.',
  'login.duration.24h': '24 hrs.',
  'login.duration.48h': '48 hrs.',
  'login.duration.permanent': 'Permanent',

  'login.action.login': 'Sign in',
  'login.action.createAccount': 'Create account',
  'login.action.forgotPassword': 'Forgot password',

  'login.footer.copyright': '© 2026 culpeohq. All rights reserved.',
  'login.footer.credits':
      'Powered by Culpeo Studio • Design & Development by culpeohq',

  'login.dialog.passwordUpdated': 'Password has been updated.',
  'login.dialog.accountCreated': 'Account has been created.',
  'login.dialog.actionFailed': 'Action failed.',
  'login.dialog.usernameHint': 'Username',
  'login.dialog.newPasswordHint': 'New password',
  'login.dialog.passwordHint': 'Password',
  'login.dialog.confirmPasswordHint': 'Confirm password',
  'login.dialog.passwordsMismatch': 'Passwords do not match',
  'login.dialog.codeFromApp': 'Code from {app}',
  'login.dialog.create': 'Create',

  'settings.nav.title': 'SETTINGS',
  'settings.nav.general': 'General',
  'settings.nav.serverApi': 'Server / API',
  'settings.nav.shortcuts': 'Shortcuts',
  'settings.nav.botManagement': 'Bot Management',
  'settings.nav.chatBot': 'Chat Bot',
  'settings.nav.skills': 'Skills',

  'settings.general.title': 'General Studio Configuration',
  'settings.general.modelDirLabel': 'MODEL DOWNLOAD PATH',
  'settings.general.modelDirDescription':
      'Folder on your hard drive where models downloaded from the marketplace '
      'are stored. You can choose your own folder (e.g. on a large drive) – '
      'the default is data/models.',
  'settings.general.modelDirHint': 'e.g. ~/models or D:\\models',
  'settings.general.modelDirPickerTitle': 'Choose model folder',
  'settings.general.browse': 'Browse',
  'settings.general.browseTooltip': 'Choose folder on hard drive',
  'settings.general.apiUrlLabel': 'API HOST URL',
  'settings.general.apiUrlDescription':
      'The address of the backend server (default: http://localhost:8080/api). '
      'The app sends all requests to this server to load models and run chats.',
  'settings.general.saveButton': 'Save settings',
  'settings.save.success': 'Settings saved successfully',

  'settings.health.reachable': 'Reachable',
  'settings.health.unreachable': 'Not reachable',
  'settings.health.httpResponse': 'Responds with HTTP {code}',
  'settings.health.error': 'Error',

  'settings.serverApi.title': 'Server & API Interfaces',
  'settings.serverApi.subtitle':
      'Manage connections to local servers and cloud model providers',
  'settings.serverApi.recheckTooltip': 'Re-check connections',
  'settings.serverApi.addNode': 'Add node',
  'settings.serverApi.localServer': 'Local Server',

  'settings.customNode.fallbackName': 'Custom Node',
  'settings.customNode.addTitle': 'Add custom node',
  'settings.customNode.addDescription':
      'Set up your own API connection to a custom server (e.g. Ollama or a '
      'local OpenAI-compatible endpoint).',
  'settings.customNode.editTitle': 'Edit custom node',
  'settings.customNode.editDescription':
      'Adjust the connection information for this node.',
  'settings.customNode.nameLabel': 'NODE NAME',
  'settings.customNode.nameHint': 'e.g. Local Ollama server',
  'settings.customNode.urlLabel': 'API BASE URL',
  'settings.customNode.urlHint': 'e.g. http://localhost:11434',
  'settings.customNode.keyLabel': 'API KEY (OPTIONAL)',
  'settings.customNode.keyHint': 'Enter token...',
  'settings.customNode.add': 'Add',
  'settings.customNode.delete': 'Delete node',
  'settings.customNode.save': 'Save',

  'settings.serverApi.phaseNote.title': 'Coming in Phase 2',
  'settings.serverApi.phaseNote.body':
      'Custom API nodes can already be added and checked for reachability, but are not yet usable as an active connection in chat/engine. Full functionality arrives with Phase 2.',

  'settings.token.setupTitle': 'Set up {title}',
  'settings.token.replaceDescription':
      'A token is already configured. You can overwrite it by entering a new '
      'one below, or delete it.',
  'settings.token.enterDescription':
      'Enter your API token for {title} to activate the service.',
  'settings.token.hfLink': '🤗 Create token on huggingface.co',
  'settings.token.orLink': '🤖 Manage API keys on openrouter.ai',
  'settings.token.flLink': '☁️ Get API access on featherless.ai',
  'settings.token.delete': 'Delete token',
  'settings.token.updated': 'Token updated successfully',

  'settings.provider.enabled': 'Enabled',
  'settings.provider.keySet': 'Key configured',
  'settings.provider.keyMissing': 'Key missing',
  'settings.provider.checking': 'Checking...',

  'settings.chatBot.title': 'Chat Bot',
  'settings.chatBot.description':
      'Decide whether new chats use a specific bot or automatically select '
      'the appropriate bot.',
  'settings.chatBot.defaultLabel': 'DEFAULT FOR NEW CHATS',
  'settings.chatBot.note': 'Running chats keep their previously used bot.',

  'settings.skills.title': 'Agent Skills',
  'settings.skills.description':
      'Imported skills are strictly validated against the Agent Skills '
      'standard and copied to data/skills. They are not loaded into chats in this version yet.',
  'settings.skills.rescanTooltip': 'Rescan',
  'settings.skills.importFolder': 'Import skill folder',
  'settings.skills.imported': 'Skill imported',
  'settings.skills.rescanned': 'Skills rescanned',
  'settings.skills.removed': 'Skill removed',
  'settings.skills.empty': 'No skills imported yet.',
  'settings.skills.unknown': 'Unknown skill',
  'settings.skills.noDescription': 'No description available',
  'settings.skills.removeTooltip': 'Remove',
  'settings.skills.valid': 'valid',
  'settings.skills.invalid': 'invalid',
  'settings.skills.fileCount': '{count} files',

  'settings.shortcuts.title': 'Keyboard Shortcuts',
  'settings.shortcuts.description':
      'Click a shortcut to re-record it. Then press the desired key combination.',
  'settings.shortcuts.pressKeys': 'Press keys...',
  'settings.shortcuts.action.switchToChat': 'Open chat',
  'settings.shortcuts.action.switchToSpark': 'Open Spark Agent',
  'settings.shortcuts.action.switchToEngine': 'Open Engine',
  'settings.shortcuts.action.switchToMarketplace': 'Open Marketplace',
  'settings.shortcuts.action.switchToNews': 'Open News',
  'settings.shortcuts.action.switchToSettings': 'Open Settings',
  'settings.shortcuts.action.toggleSidebar': 'Toggle sidebar',
  'settings.shortcuts.action.focusChatInput': 'Focus chat input',
  'settings.shortcuts.action.newChatSession': 'Start new chat',
  'settings.shortcuts.action.toggleChatTab': 'Switch between chat tabs',
  'settings.shortcuts.action.toggleEngine': 'Start/stop engine',
  'settings.shortcuts.action.loadModel': 'Load model',
  'settings.shortcuts.action.focusSearch': 'Focus search',
  'settings.shortcuts.action.showHelp': 'Show shortcut help',

  'settings.systemInfo.title': 'System Information',
  'settings.systemInfo.noGpu': 'No GPU detected',
  'settings.systemInfo.cpuDetecting': 'Detecting CPU …',
  'settings.systemInfo.diskFree': 'DISK FREE',
  'settings.systemInfo.detection': 'DETECTION',
  'settings.systemInfo.source.culpeostudioHardware':
      'Culpeo Studio Hardware Detection',
  'settings.systemInfo.source.culpeostudioHardwareLive':
      'Culpeo Studio Hardware Detection + live data',
  'settings.systemInfo.source.nativeLive': 'Local live detection',
  'settings.systemInfo.source.localFallback': 'Local fallback detection',
  'settings.help.title': 'Help & Documentation',
  'settings.help.body':
      'Make sure the culpeostudio backend is running before performing '
      'operations. By default it listens on port 8080.',

  'chat.modelChoice.localReady': 'Local • Ready',

  'chat.warmup.modelReady': 'Model is ready',

  'chat.planApproval.reject': 'Reject',

  'chat.thinkingSlider.faster': 'Faster',
  'chat.thinkingSlider.smarter': 'Smarter',
  'chat.thinkingSlider.inDevelopment': 'In development',

  'chatHistory.rename.title': 'Rename chat',
  'chatHistory.rename.hint': 'Title',
  'chatHistory.rename.cancel': 'Cancel',
  'chatHistory.rename.save': 'Save',
  'chatHistory.delete.title': 'Delete chat?',
  'chatHistory.delete.body': '"{title}" will be permanently deleted.',
  'chatHistory.delete.cancel': 'Cancel',
  'chatHistory.delete.confirm': 'Delete',
  'chatHistory.deleteProject.title': 'Delete folder?',
  'chatHistory.deleteProject.body':
      '"{name}" will be deleted. The chats it contains are kept and move back to the general list.',
  'chatHistory.deleteProject.cancel': 'Cancel',
  'chatHistory.deleteProject.confirm': 'Delete',

  'chatHistory.newFolder': 'New folder',
  'chatHistory.sectionProjects': 'Projects',
  'chatHistory.sectionHistory': 'History',
  'chatHistory.sectionChats': 'Chats',
  'chatHistory.empty':
      'No chats yet — start a new conversation or create a folder.',

  'chatHistory.projectDialog.titleEdit': 'Edit folder',
  'chatHistory.projectDialog.titleNew': 'New folder',
  'chatHistory.projectDialog.nameHint': 'Project name',
  'chatHistory.projectDialog.nameError': 'Please enter a name',
  'chatHistory.projectDialog.pathError': 'Please provide a path or disable it',
  'chatHistory.projectDialog.colorLabel': 'COLOR',
  'chatHistory.projectDialog.iconLabel': 'ICON',
  'chatHistory.projectDialog.pathToggle':
      'Set project path (file access in chat)',
  'chatHistory.projectDialog.pathHint': '/path/to/project',
  'chatHistory.projectDialog.browse': 'Browse',
  'chatHistory.projectDialog.browseTitle': 'Choose project path',
  'chatHistory.projectDialog.cancel': 'Cancel',
  'chatHistory.projectDialog.save': 'Save',
  'chatHistory.projectDialog.create': 'Create',

  'chatHistory.projectRow.newChat': 'New chat in folder',
  'chatHistory.projectRow.edit': 'Edit folder',
  'chatHistory.projectRow.delete': 'Delete folder',
  'chatHistory.chatRow.move': 'Move to folder',
  'chatHistory.chatRow.removeFromFolder': 'Remove from folder',
  'chatHistory.chatRow.removeFromSubfolder': 'Remove from subfolder',
  'chatHistory.chatRow.noFolders': 'No folders available',
  'chatHistory.chatRow.rename': 'Rename',
  'chatHistory.chatRow.delete': 'Delete',

  'chatHistory.newSubfolder': 'New subfolder',
  'chatHistory.deleteSubfolder.title': 'Delete subfolder?',
  'chatHistory.deleteSubfolder.body':
      '"{name}" will be deleted. Its chats are kept and move back to the '
      'project.',
  'chatHistory.subfolderDialog.titleEdit': 'Edit subfolder',
  'chatHistory.subfolderDialog.titleNew': 'New subfolder',
  'chatHistory.subfolderDialog.nameHint': 'Folder name',
  'chatHistory.subfolderDialog.nameError': 'Please enter a name',
  'chatHistory.subfolderDialog.colorLabel': 'COLOR',
  'chatHistory.subfolderRow.newChat': 'New chat in subfolder',
  'chatHistory.subfolderRow.edit': 'Edit subfolder',
  'chatHistory.subfolderRow.delete': 'Delete subfolder',

  'news.title': 'AI & Tech Feed',
  'news.refresh': 'Refresh',
  'news.searchHint': 'Search keywords, content or tags...',
  'news.categoryLabel': 'CATEGORY:',
  'news.categoryAll': 'All',
  'news.categoryReleases': 'AI Releases',
  'news.categoryHardware': 'Hardware',
  'news.categorySoftware': 'Software & Dev',
  'news.categorySecurity': 'Security',
  'news.categoryOpenSource': 'Open Source',
  'news.categoryResearch': 'Research',
  'news.noResults': 'No matching articles found.',
  'news.empty': 'No articles available at the moment.',
  'news.resetFilters': 'Reset filters',
  'news.sourceLabel': 'PROVIDER:',
  'news.sourceAll': 'All providers',
  'news.savedFilter': 'Saved',
  'news.save': 'Save article',
  'news.unsave': 'Remove from saved',
  'news.savedEmpty': 'You have not saved any articles yet.',
  'news.savedLoadError': 'Could not load saved articles: {error}',
  'news.loadError': 'Error loading news: {error}',

  'benchmark.title': 'Benchmark',
  'benchmark.subtitle':
      'Daily ratings from LMArena: real people compare two answers and vote.',
  'benchmark.tabLeaderboard': 'Leaderboard',
  'benchmark.tabCompare': 'Compare',

  'benchmark.board.arena_text': 'LMArena · Text',

  'benchmark.sourceLive': 'Updated daily',
  'benchmark.sourceAsOf': 'As of',
  'benchmark.refreshAction': 'Refresh',
  'benchmark.refreshStarted': 'Sync running — this takes a moment.',
  'benchmark.loadingTitle': 'Loading the leaderboard',
  'benchmark.loadingProgress': '{loaded} of {total} runs',
  'benchmark.loadingHint':
      'The first sync pulls the whole dataset and stores it locally.',
  'benchmark.loadFailed': 'Benchmark data could not be loaded.',

  'benchmark.metricEvaluated': '{count} rated',
  'benchmark.metricFieldMedian': 'Field median',
  'benchmark.metricFieldBest': 'Best',
  'benchmark.metricSpanLabel': '{metric}: field median {median}, best {max}.',
  'benchmark.metricLeader': 'Category leader',

  'benchmark.wikiOpen': 'Open the benchmark wiki',
  'benchmark.wikiTitle': 'Benchmark wiki',
  'benchmark.wikiIntro':
      'This leaderboard is built from duels: people put the same question to two models, see both answers without names and pick the better one. Winning more often moves a model up. Tap a point below to see what it means.',
  'benchmark.wikiReading': 'How to read the leaderboard',
  'benchmark.wikiCategories': 'What each category measures',
  'benchmark.wikiCategoriesHint':
      'Every category tests a different skill. Tap one to see what is checked there and how far the models are apart.',
  'benchmark.wikiExplain': 'What does this category measure?',
  'benchmark.wikiExplainColumn':
      'Click to sort · right-click explains the category',
  'benchmark.wikiScoreTitle': 'The headline score ({label})',
  'benchmark.wikiScoreElo':
      'The headline score is a comparison number, not a percentage. It rises when a model wins often and falls when it loses. A gap of about 100 points means the stronger model wins roughly two out of three duels. So one value alone says little — only the gap between two models tells you which one is really better.',
  'benchmark.wikiScorePercent':
      'The headline score folds all categories into one number, at most {max}. It is great for comparing two models. But a high total does not automatically mean the model leads every category — check the individual bars for that.',
  'benchmark.wikiRankTitle': 'Rank and the pale line in the bar',
  'benchmark.wikiRankText':
      'A rank is just a snapshot: when two models are a few points apart, their order is almost chance — only a clear gap really means better. The pale line inside a bar marks the middle of the field: half of all models score below it. A bar reaching past it is above average.',
  'benchmark.wikiTypeTitle': '{open} or {api}',
  'benchmark.wikiTypeText':
      '“{open}” means the model is free: you can download it and try it yourself. “{api}” means the model only runs at the provider and you pay per request. The “Type” filter hides either group.',
  'benchmark.wikiCompareTitle': 'Putting models side by side',
  'benchmark.wikiCompareText':
      'Use the arrow at the end of a row to move a model into the comparison. Up to twelve models line up there: the first column is the reference, every other column shows the distance from it.',
  'benchmark.wikiSourceTitle': 'Where the data comes from',
  'benchmark.wikiSourceText':
      'The leaderboard data is downloaded once and stored locally. “Refresh” pulls the newest state — the date of the last fetch is shown top right. Downloads and likes in the detail view come live from the Hugging Face hub; facts that only appear in the model description are not checked.',
  'benchmark.wikiNoDescription': 'There is no description for this category.',

  'benchmark.metric.hard_prompts.desc':
      'The toughest and trickiest prompts in the arena — this is where the top models show themselves.',
  'benchmark.metric.coding.desc':
      'Who writes the Code people prefer? People judge the answers to programming tasks.',
  'benchmark.metric.math.desc':
      'Arithmetic and math tasks: how well the model handles numbers and proofs.',
  'benchmark.metric.creative_writing.desc':
      'Free writing — stories, copy, style. People compare the answers directly and pick the better one.',
  'benchmark.metric.instruction_following.desc':
      'How precisely does the model do what was actually asked — even for unusual instructions?',
  'benchmark.metric.multi_turn.desc':
      'Conversations across several messages: does the model stay on track and remember what was said earlier?',
  'benchmark.metric.longer_query.desc':
      'Long, detailed questions instead of short one-liners — so the model keeps up even with complicated texts.',
  'benchmark.metric.non_english.desc':
      'Questions in languages other than English — many models are mainly strong in English.',

  'benchmark.family.instruction': 'Instructions',
  'benchmark.family.reasoning': 'Reasoning',
  'benchmark.family.math': 'Mathematics',
  'benchmark.family.coding': 'Coding',
  'benchmark.family.creative': 'Creative',
  'benchmark.family.conversation': 'Conversation',
  'benchmark.family.language': 'Languages',

  'benchmark.metricNoData':
      'The current snapshot holds no values for this category.',

  'benchmark.searchHint': 'Search model, provider or architecture…',
  'benchmark.filterType': 'Type',
  'benchmark.filterOrg': 'Provider',
  'benchmark.filterAll': 'All',
  'benchmark.filterReset': 'Reset filters',
  'benchmark.sortLabel': 'Sort by',
  'benchmark.sortAverage': 'Headline score',
  'benchmark.sortName': 'Name',
  'benchmark.resultCount': '{count} models',
  'benchmark.empty': 'No models match these filters.',
  'benchmark.loadMore': 'Load more',

  'benchmark.columnRank': 'Rank',
  'benchmark.columnModel': 'Model',
  'benchmark.columnOrg': 'Provider',
  'benchmark.columnType': 'Type',
  'benchmark.metricWindowRange': '{from}–{to} of {total}',

  'benchmark.type.open_weights': 'Open Source',
  'benchmark.type.proprietary': 'API',

  'benchmark.detailRank': 'Rank {rank} of {total}',
  'benchmark.detailPercentile': 'Stronger than {value} % of all runs',
  'benchmark.detailScores': 'Individual scores',
  'benchmark.detailVsMedianUp': '{diff} above the median',
  'benchmark.detailVsMedianDown': '{diff} below the median',
  'benchmark.detailRankShort': 'Rank {rank}',
  'benchmark.detailRuns': 'Evaluated runs',
  'benchmark.detailFacts': 'Key facts',
  'benchmark.factLicense': 'License',
  'benchmark.factType': 'Type',
  'benchmark.factOrg': 'Provider',
  'benchmark.factSubmitted': 'Evaluated',

  'benchmark.detail.votes': 'Votes',
  'benchmark.detail.confidence': 'Confidence interval',
  'benchmark.detail.variance': 'Rating spread',
  'benchmark.detail.arena_rank': 'Rank per arena',

  'benchmark.hubTitle': 'Live from the Hugging Face hub',
  'benchmark.hubDownloads': 'Downloads (30 days)',
  'benchmark.hubDownloadsTotal': 'Downloads all time',
  'benchmark.hubLikes': 'Likes',
  'benchmark.hubTrending': 'Trending score',
  'benchmark.hubUpdated': 'Last modified',
  'benchmark.hubGated': 'Gated access',
  'benchmark.hubParams': 'Parameters from the weights',
  'benchmark.hubMissing':
      'This repository is no longer on the hub — deleted or renamed.',
  'benchmark.cardResults': 'Vendor numbers from the model card',
  'benchmark.cardResultsNote': 'Self-reported, not independently verified.',
  'benchmark.openOnHub': 'Open the model source',
  'benchmark.openLinkFailed': 'The link could not be opened: {url}',
  'benchmark.addToCompare': 'Add to comparison',
  'benchmark.noLeaderboardEntry':
      'The arena has no entry for this model — it has not been rated there yet. The live hub numbers are below.',

  'benchmark.compareEmpty':
      'Pick up to four models from the leaderboard for a head-to-head view.',
  'benchmark.compareRemove': 'Remove from comparison',
  'benchmark.compareCount': '{count} models compared',
  'benchmark.compareClear': 'Clear comparison',
  'benchmark.compareLimit': 'Twelve models is the maximum for a comparison.',
  'benchmark.compareAdded': '{model} is now in the comparison.',
  'benchmark.compareAlready': '{model} is already in the comparison.',
  'benchmark.compareScores': 'Scores side by side',
  'benchmark.compareBest': 'Best of the selection',
  'benchmark.compareNoData': 'No scores available for this model.',

  'bots.title': 'Bot Management',
  'bots.createTitle': 'Create new Bot',
  'bots.deleteConfirm': 'Do you really want to delete "{name}"?',
  'bots.saved': 'Bot "{name}" successfully saved',
  'bots.deleted': 'Bot "{name}" deleted',

  'engine.syncStatus': 'SYSTEM DATA IS AUTOMATICALLY SYNCHRONIZED',
  'engine.stopInstance': 'Stop',
  'engine.startInstance': 'Start',
  'engine.responseBehavior': 'Response Behavior',
  'engine.context': 'Context',
  'engine.detailsMore': 'Details',
  'engine.detailsLess': 'Less',
};
