import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_strings.dart';
import '../l10n/remaining_ui_strings.dart';
import '../services/api_service.dart';

class ModelFolder {
  final String id;
  String name;
  Color color;
  final List<String> modelIds;

  ModelFolder({
    required this.id,
    required this.name,
    required this.color,
    required this.modelIds,
  });
}

class ActiveApiModel {
  final String provider;
  final String modelId;
  final String displayName;
  final String modelRef;

  ActiveApiModel({
    required this.provider,
    required this.modelId,
    required this.displayName,
    required this.modelRef,
  });

  factory ActiveApiModel.fromJson(Map<String, dynamic> json) {
    final provider = json['provider']?.toString() ?? '';
    final modelId = json['model_id']?.toString() ?? '';
    final displayName = json['display_name']?.toString() ?? modelId;
    final modelRef = json['model_ref']?.toString() ?? '';
    return ActiveApiModel(
      provider: provider,
      modelId: modelId,
      displayName: displayName.isEmpty ? modelId : displayName,
      modelRef: modelRef,
    );
  }
}

class BotModelBinding {
  final String kind;
  final String modelRef;
  final String provider;
  final String modelId;
  final String? instanceId;
  final String displayName;

  const BotModelBinding({
    required this.kind,
    required this.modelRef,
    required this.provider,
    required this.modelId,
    this.instanceId,
    required this.displayName,
  });

  bool get isLocal => kind == 'local' || provider == 'local';

  factory BotModelBinding.fromJson(Map<String, dynamic> json) {
    final kind = json['kind']?.toString().trim().toLowerCase() ?? '';
    final provider = json['provider']?.toString().trim() ?? '';
    final instanceId = json['instance_id']?.toString().trim() ?? '';
    final modelId = json['model_id']?.toString().trim() ?? '';
    var modelRef = json['model_ref']?.toString().trim() ?? '';
    final local = kind == 'local' || provider == 'local';
    if (modelRef.isEmpty && local && instanceId.isNotEmpty) {
      modelRef = 'local:$instanceId';
    }
    return BotModelBinding(
      kind: local ? 'local' : 'api',
      modelRef: modelRef,
      provider: local ? 'local' : provider,
      modelId: modelId.isNotEmpty ? modelId : instanceId,
      instanceId: instanceId.isEmpty ? null : instanceId,
      displayName: json['display_name']?.toString().trim() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'kind': isLocal ? 'local' : 'api',
    'model_ref': modelRef,
    'provider': provider,
    'model_id': modelId,
    if (instanceId?.isNotEmpty == true) 'instance_id': instanceId,
    'display_name': displayName,
  };
}

class PhiloBotChoice {
  final String id;
  final String name;
  final bool isDefault;
  final bool locked;
  final BotModelBinding? modelBinding;

  const PhiloBotChoice({
    required this.id,
    required this.name,
    this.isDefault = false,
    this.locked = false,
    this.modelBinding,
  });

  factory PhiloBotChoice.fromJson(Map<String, dynamic> json) {
    final rawBinding = json['model_binding'];
    return PhiloBotChoice(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString().trim().isNotEmpty == true
          ? json['name'].toString().trim()
          : 'Unbenannter Bot',
      isDefault: json['is_default'] == true,
      locked: json['locked'] == true || json['id']?.toString() == 'botbuilder',
      modelBinding: rawBinding is Map
          ? BotModelBinding.fromJson(Map<String, dynamic>.from(rawBinding))
          : null,
    );
  }
}

class ChatProject {
  ChatProject({
    required this.id,
    required this.name,
    this.color,
    this.path,
    this.icon,
  });

  final String id;
  String name;
  String? color;

  String? path;

  String? icon;

  factory ChatProject.fromJson(Map<String, dynamic> json) {
    final rawColor = json['color']?.toString();
    final rawPath = json['path']?.toString();
    final rawIcon = json['icon']?.toString();
    return ChatProject(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      color: (rawColor == null || rawColor.isEmpty) ? null : rawColor,
      path: (rawPath == null || rawPath.isEmpty) ? null : rawPath,
      icon: (rawIcon == null || rawIcon.isEmpty) ? null : rawIcon,
    );
  }
}

class UserPreferences {
  const UserPreferences({
    required this.configured,
    required this.language,
    required this.frontendVersion,
  });

  static const defaultLanguage = 'de';
  static const defaultFrontendVersion = 'classic';
  static const supportedLanguages = {'de', 'en'};
  static const supportedFrontendVersions = {'lite', 'classic'};

  final bool configured;
  final String language;
  final String frontendVersion;

  bool get hasSupportedValues =>
      supportedLanguages.contains(language) &&
      supportedFrontendVersions.contains(frontendVersion);

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      configured: json['configured'] == true,
      language: json['language']?.toString() ?? '',
      frontendVersion: json['frontend_version']?.toString() ?? '',
    );
  }
}

class AppState extends ChangeNotifier {
  static const _rememberedTokenKey = 'remembered_auth_token';
  static const _rememberedUsernameKey = 'remembered_auth_username';
  static const _lastChatSessionKey = 'last_chat_session_id';

  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;
  AppState._internal() : api = ApiService() {
    _wireSessionExpiry();
  }
  AppState.test(this.api) {
    _wireSessionExpiry();
  }

  final ApiService api;

  void _wireSessionExpiry() {
    api.onSessionExpired = () {
      if (_sessionExpiryHandled) return;
      _sessionExpiryHandled = true;
      logout();
      _lastChatError = remainingUiText('appState.sessionExpired');
      notifyListeners();
    };
  }

  bool _sessionExpiryHandled = false;

  String language = UserPreferences.defaultLanguage;
  String frontendVersion = UserPreferences.defaultFrontendVersion;

  bool _hasUserPrefs = true;
  bool _userPreferencesLoaded = false;
  bool _isSavingUserPreferences = false;
  String? _userPreferencesError;
  UserPreferences? _pendingUserPreferences;

  bool get userPreferencesLoaded => _userPreferencesLoaded;

  bool get isSavingUserPreferences => _isSavingUserPreferences;

  String? get userPreferencesError => _userPreferencesError;
  bool get canRetryUserPreferencesSave => _pendingUserPreferences != null;

  bool get needsOnboarding =>
      isLoggedIn && _userPreferencesLoaded && !_hasUserPrefs;

  Future<bool> setLanguage(String lang) {
    return saveUserPreferences(
      language: lang,
      frontendVersion: frontendVersion,
    );
  }

  Future<bool> setFrontendVersion(String version) {
    return saveUserPreferences(language: language, frontendVersion: version);
  }

  Future<bool> loadUserPrefs() async {
    _resetUserPreferencesForUnknownUser();
    if (!isLoggedIn) {
      notifyListeners();
      return false;
    }

    final result = await api.getUserPreferences();
    if (result.containsKey('error')) {
      _markUserPreferencesUnavailable(result['error']);
      notifyListeners();
      return false;
    }

    final preferences = UserPreferences.fromJson(result);
    if (!preferences.hasSupportedValues) {
      _markUserPreferencesUnavailable(
        remainingUiText('preferences.invalidReceived'),
      );
      notifyListeners();
      return false;
    }

    _applyUserPreferences(preferences);
    _userPreferencesLoaded = true;
    _hasUserPrefs = preferences.configured;
    _userPreferencesError = null;
    _pendingUserPreferences = null;
    notifyListeners();
    return true;
  }

  Future<bool> saveUserPreferences({
    required String language,
    required String frontendVersion,
  }) async {
    final requested = UserPreferences(
      configured: true,
      language: language,
      frontendVersion: frontendVersion,
    );
    if (!requested.hasSupportedValues) {
      _pendingUserPreferences = requested;
      _userPreferencesError = remainingUiText('preferences.invalidChoice');
      notifyListeners();
      return false;
    }
    if (!isLoggedIn) {
      _pendingUserPreferences = requested;
      _userPreferencesError = remainingUiText('preferences.notSignedIn');
      notifyListeners();
      return false;
    }
    if (_isSavingUserPreferences) return false;

    _isSavingUserPreferences = true;
    _userPreferencesError = null;
    notifyListeners();

    final result = await api.updateUserPreferences(
      language: requested.language,
      frontendVersion: requested.frontendVersion,
    );
    _isSavingUserPreferences = false;

    if (result.containsKey('error')) {
      _pendingUserPreferences = requested;
      _userPreferencesError = result['error']?.toString();
      notifyListeners();
      return false;
    }

    final persisted = UserPreferences.fromJson(result);
    if (!persisted.configured || !persisted.hasSupportedValues) {
      _pendingUserPreferences = requested;
      _userPreferencesError = remainingUiText('preferences.invalidSaved');
      notifyListeners();
      return false;
    }

    _applyUserPreferences(persisted);
    _userPreferencesLoaded = true;
    _hasUserPrefs = true;
    _userPreferencesError = null;
    _pendingUserPreferences = null;
    notifyListeners();
    return true;
  }

  Future<bool> retryUserPreferencesSave() async {
    final pending = _pendingUserPreferences;
    if (pending == null) return false;
    return saveUserPreferences(
      language: pending.language,
      frontendVersion: pending.frontendVersion,
    );
  }

  Future<bool> retryUserPreferencesLoad() => loadUserPrefs();

  void _applyUserPreferences(UserPreferences preferences) {
    language = preferences.language;
    frontendVersion = preferences.frontendVersion;
    appLanguage = language;
  }

  void _resetUserPreferencesForUnknownUser() {
    language = UserPreferences.defaultLanguage;
    frontendVersion = UserPreferences.defaultFrontendVersion;
    appLanguage = language;
    _hasUserPrefs = true;
    _userPreferencesLoaded = false;
    _isSavingUserPreferences = false;
    _userPreferencesError = null;
    _pendingUserPreferences = null;
  }

  void _markUserPreferencesUnavailable(dynamic error) {
    _hasUserPrefs = false;
    _userPreferencesLoaded = true;
    _userPreferencesError = error?.toString();
    _pendingUserPreferences = null;
  }

  final _actionStreamController = StreamController<String>.broadcast();
  Stream<String> get actionStream => _actionStreamController.stream;

  void triggerAction(String action) {
    _actionStreamController.add(action);
  }

  double chatTextScale = 1.0;

  void increaseChatScale() {
    if (chatTextScale < 2.0) {
      chatTextScale += 0.05;
      notifyListeners();
    }
  }

  void decreaseChatScale() {
    if (chatTextScale > 0.6) {
      chatTextScale -= 0.05;
      notifyListeners();
    }
  }

  Map<String, String> shortcuts = {};

  Future<void> loadShortcuts() async {
    try {
      final res = await api.getSettings();
      if (res.containsKey('shortcuts')) {
        final rawShortcuts = res['shortcuts'];
        if (rawShortcuts is Map) {
          shortcuts = Map<String, String>.from(rawShortcuts);
          shortcuts.remove('toggle_theme');
          notifyListeners();
        }
      }
    } catch (_) {
      return;
    }
  }

  void updateShortcutsMap(Map<String, String> newShortcuts) {
    shortcuts = newShortcuts;
    notifyListeners();
  }

  final List<ActiveApiModel> activeApiModels = [];
  final List<String> availableModelIds = [];

  final List<dynamic> philoBots = [];

  final List<ModelFolder> modelFolders = [
    ModelFolder(
      id: 'general',
      name: 'API-Modelle',
      color: const Color(0xFFC9A24A),
      modelIds: [],
    ),
  ];

  void createModelFolder(String name, Color color) {
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    modelFolders.add(
      ModelFolder(id: newId, name: name, color: color, modelIds: []),
    );
    notifyListeners();
  }

  void deleteModelFolder(String folderId) {
    final index = modelFolders.indexWhere((f) => f.id == folderId);
    if (index != -1) {
      final folder = modelFolders[index];
      final generalFolder = modelFolders.firstWhere(
        (f) => f.id == 'general',
        orElse: () {
          final f = ModelFolder(
            id: 'general',
            name: 'Sprachmodelle',
            color: const Color(0xFFC9A24A),
            modelIds: [],
          );
          modelFolders.insert(0, f);
          return f;
        },
      );
      if (generalFolder != folder) {
        generalFolder.modelIds.addAll(folder.modelIds);
      }
      modelFolders.removeAt(index);
      notifyListeners();
    }
  }

  void renameAndRecolorFolder(String folderId, String newName, Color newColor) {
    for (var folder in modelFolders) {
      if (folder.id == folderId) {
        folder.name = newName;
        folder.color = newColor;
        break;
      }
    }
    notifyListeners();
  }

  void moveModelToFolder(String modelId, String targetFolderId) {
    for (var folder in modelFolders) {
      folder.modelIds.remove(modelId);
    }
    final targetFolder = modelFolders.firstWhere(
      (f) => f.id == targetFolderId,
      orElse: () {
        final f = ModelFolder(
          id: 'general',
          name: 'Sprachmodelle',
          color: const Color(0xFFC9A24A),
          modelIds: [],
        );
        modelFolders.add(f);
        return f;
      },
    );
    if (!targetFolder.modelIds.contains(modelId)) {
      targetFolder.modelIds.add(modelId);
    }
    notifyListeners();
  }

  String _currentScreen = 'chat';
  String get currentScreen => _currentScreen;

  bool get isLoggedIn => api.token != null;
  String? get username => api.username;

  String? _selectedModelId;
  String? get selectedModelId => _selectedModelId;

  String? _preferredBotId;
  String? get preferredBotId => _preferredBotId;

  void setPreferredBotId(String? botId) {
    _preferredBotId = botId;
    notifyListeners();
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _authError;
  String? get authError => _authError;

  bool? _totpConfigured;
  bool? get totpConfigured => _totpConfigured;

  String? _setupSecret;
  String? get setupSecret => _setupSecret;

  String? _setupOtpauthUrl;
  String? get setupOtpauthUrl => _setupOtpauthUrl;

  String _authenticatorApp = 'google';
  String get authenticatorApp => _authenticatorApp;
  String get authenticatorAppLabel => _authenticatorApp == '2fas'
      ? '2FAS Authenticator'
      : 'Google Authenticator';

  final List<String> chatSessions = [];
  final Map<String, String> sessionTitles = {};

  final List<ChatProject> chatProjects = [];
  final Map<String, String> sessionProjects = {};
  String? currentChatSessionId;
  String? _lastChatError;
  String? get lastChatError => _lastChatError;

  Future<String?> createNewChatSession(
    String modelRef, {
    String? provider,
    String? modelId,
    String? instanceId,
    String? botId,
    String? projectId,
  }) async {
    _isLoading = true;
    _lastChatError = null;
    notifyListeners();
    final selected = activeModelForRef(modelRef);
    final result = await api.createPhiloBotSession(
      modelRef: modelRef,
      provider: provider ?? selected?.provider,
      modelId: modelId ?? selected?.modelId,
      instanceId: instanceId,
      botId: botId,
      projectId: projectId,
    );
    _isLoading = false;
    if (result.containsKey('session_id')) {
      final sId = result['session_id'] as String;
      chatSessions.add(sId);
      sessionTitles[sId] = 'Sitzung ${chatSessions.length}';
      if (projectId != null && projectId.isNotEmpty) {
        sessionProjects[sId] = projectId;
      }
      currentChatSessionId = sId;
      unawaited(_persistLastChatSession());
      notifyListeners();
      return sId;
    }
    _lastChatError =
        result['error']?.toString() ??
        remainingUiText('appState.sessionCreateFailed');
    notifyListeners();
    return null;
  }

  void renameSession(String sId, String newTitle) {
    if (chatSessions.contains(sId)) {
      final trimmed = newTitle.trim();
      sessionTitles[sId] = trimmed.isEmpty ? sId : trimmed;
      notifyListeners();

      unawaited(api.renamePhiloBotSession(sId, trimmed));
    }
  }

  void deleteSession(String sId) {
    if (chatSessions.contains(sId)) {
      chatSessions.remove(sId);
      sessionTitles.remove(sId);
      sessionProjects.remove(sId);
      if (currentChatSessionId == sId) {
        currentChatSessionId = chatSessions.isNotEmpty
            ? chatSessions.last
            : null;
        unawaited(_persistLastChatSession());
      }
      notifyListeners();

      unawaited(api.deletePhiloBotSession(sId));
    }
  }

  String? projectIdForSession(String sId) => sessionProjects[sId];

  ChatProject? projectById(String projectId) {
    for (final project in chatProjects) {
      if (project.id == projectId) return project;
    }
    return null;
  }

  List<String> sessionsInProject(String projectId) {
    return chatSessions
        .where((sId) => sessionProjects[sId] == projectId)
        .toList();
  }

  Future<ChatProject?> createChatProject(
    String name, {
    String? color,
    String? path,
    String? icon,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;
    final result = await api.createPhiloBotProject(
      trimmed,
      color: color,
      path: path,
      icon: icon,
    );
    final rawProject = result['project'];
    if (rawProject is Map) {
      final project = ChatProject.fromJson(
        Map<String, dynamic>.from(rawProject),
      );
      if (project.id.isNotEmpty) {
        chatProjects.insert(0, project);
        notifyListeners();
        return project;
      }
    }
    _lastChatError =
        result['error']?.toString() ??
        remainingUiText('appState.projectCreateFailed');
    notifyListeners();
    return null;
  }

  Future<void> renameChatProject(
    String projectId,
    String newName, {
    String? color,
    String? path,
    String? icon,
  }) async {
    final project = projectById(projectId);
    final trimmed = newName.trim();
    if (project == null || trimmed.isEmpty) return;
    project.name = trimmed;
    if (color != null && color.isNotEmpty) {
      project.color = color;
    }

    project.path = (path != null && path.isNotEmpty) ? path : null;

    project.icon = (icon != null && icon.isNotEmpty) ? icon : null;
    notifyListeners();
    unawaited(
      api.renamePhiloBotProject(
        projectId,
        trimmed,
        color: color,
        path: path,
        icon: icon,
      ),
    );
  }

  Future<void> deleteChatProject(String projectId) async {
    final index = chatProjects.indexWhere((p) => p.id == projectId);
    if (index == -1) return;
    chatProjects.removeAt(index);

    sessionProjects.removeWhere((_, pId) => pId == projectId);
    notifyListeners();
    unawaited(api.deletePhiloBotProject(projectId));
  }

  Future<void> assignSessionToProject(String sId, String? projectId) async {
    if (!chatSessions.contains(sId)) return;
    if (projectId == null || projectId.isEmpty) {
      sessionProjects.remove(sId);
    } else {
      sessionProjects[sId] = projectId;
    }
    notifyListeners();
    unawaited(api.setPhiloBotSessionProject(sId, projectId));
  }

  Future<void> restoreChatProjects() async {
    try {
      final result = await api.listPhiloBotProjects();
      final rawProjects = result['projects'];
      if (rawProjects is! List) return;
      final loaded = <ChatProject>[];
      for (final entry in rawProjects) {
        if (entry is! Map) continue;
        final project = ChatProject.fromJson(Map<String, dynamic>.from(entry));
        if (project.id.isNotEmpty) {
          loaded.add(project);
        }
      }
      chatProjects
        ..clear()
        ..addAll(loaded);
      notifyListeners();
    } catch (_) {}
  }

  String getSessionTitle(String sId) {
    return sessionTitles[sId] ?? sId;
  }

  void selectChatSession(String sessionId) {
    currentChatSessionId = sessionId;
    unawaited(_persistLastChatSession());
    notifyListeners();
  }

  void clearCurrentChatSessionSelection() {
    currentChatSessionId = null;
    notifyListeners();
  }

  Future<void> restoreChatSessions() async {
    await restoreChatProjects();
    try {
      final result = await api.listPhiloBotSessions();
      final rawSessions = result['sessions'];
      if (rawSessions is! List) return;

      final ordered = <String>[];
      final titles = <String, String>{};
      final projects = <String, String>{};
      for (final entry in rawSessions) {
        if (entry is! Map) continue;
        final sId = entry['session_id']?.toString();
        if (sId == null || sId.isEmpty) continue;
        ordered.add(sId);
        final title = entry['title']?.toString();
        titles[sId] = (title == null || title.isEmpty) ? sId : title;
        final projectId = entry['project_id']?.toString();
        if (projectId != null && projectId.isNotEmpty) {
          projects[sId] = projectId;
        }
      }

      chatSessions
        ..clear()
        ..addAll(ordered.reversed);
      sessionTitles
        ..clear()
        ..addAll(titles);
      sessionProjects
        ..clear()
        ..addAll(projects);

      if (chatSessions.isEmpty) {
        currentChatSessionId = null;
        notifyListeners();
        return;
      }

      var preferred = chatSessions.last;
      try {
        final preferences = await SharedPreferences.getInstance();
        final saved = preferences.getString(_lastChatSessionKey);
        if (saved != null && chatSessions.contains(saved)) {
          preferred = saved;
        }
      } catch (_) {}
      currentChatSessionId = preferred;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _persistLastChatSession() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final sId = currentChatSessionId;
      if (sId == null || sId.isEmpty) {
        await preferences.remove(_lastChatSessionKey);
      } else {
        await preferences.setString(_lastChatSessionKey, sId);
      }
    } catch (_) {}
  }

  void setScreen(String screen) {
    _currentScreen = screen;
    notifyListeners();
  }

  void setSelectedModelId(String modelId) {
    _selectedModelId = modelId;
    notifyListeners();
  }

  ActiveApiModel? activeModelForRef(String modelRef) {
    for (final model in activeApiModels) {
      if (model.modelRef == modelRef) {
        return model;
      }
    }
    return null;
  }

  String modelDisplayName(String modelRef) {
    final model = activeModelForRef(modelRef);
    return model?.displayName ?? modelRef;
  }

  String modelSubtitle(String modelRef) {
    final model = activeModelForRef(modelRef);
    if (model == null) {
      return modelRef;
    }
    return '${model.provider} • ${model.modelId}';
  }

  Future<bool> refreshActiveApiModels() async {
    final result = await api.listActiveAPIModels();
    if (result.containsKey('error')) {
      _lastChatError = result['error']?.toString();
      notifyListeners();
      return false;
    }

    final rawModels = result['models'];
    final loaded = <ActiveApiModel>[];
    if (rawModels is List) {
      for (final item in rawModels) {
        if (item is Map) {
          final model = ActiveApiModel.fromJson(
            Map<String, dynamic>.from(item),
          );
          if (model.modelRef.isNotEmpty) {
            loaded.add(model);
          }
        }
      }
    }

    activeApiModels
      ..clear()
      ..addAll(loaded);
    final activeRefList = loaded.map((m) => m.modelRef).toList();
    final activeRefs = activeRefList.toSet();
    availableModelIds
      ..clear()
      ..addAll(activeRefList);

    for (final folder in modelFolders) {
      folder.modelIds.removeWhere((id) => !activeRefs.contains(id));
    }
    final generalFolder = modelFolders.firstWhere((f) => f.id == 'general');
    for (final model in loaded) {
      final alreadyFoldered = modelFolders.any(
        (f) => f.modelIds.contains(model.modelRef),
      );
      if (!alreadyFoldered) {
        generalFolder.modelIds.add(model.modelRef);
      }
    }
    if (_selectedModelId == null || !activeRefs.contains(_selectedModelId)) {
      _selectedModelId = loaded.isNotEmpty ? loaded.first.modelRef : null;
    }

    notifyListeners();
    return true;
  }

  Future<bool> refreshPhiloBots() async {
    final result = await api.getPhiloBots();
    if (result.containsKey('error')) {
      _lastChatError = result['error']?.toString();
      notifyListeners();
      return false;
    }
    final list = result['bots'];
    philoBots.clear();
    if (list is List) {
      philoBots.addAll(list);
    }
    notifyListeners();
    return true;
  }

  Future<bool> savePhiloBot(Map<String, dynamic> bot) async {
    _isLoading = true;
    notifyListeners();
    final result = await api.savePhiloBot(bot);
    _isLoading = false;
    if (result.containsKey('error')) {
      _lastChatError = result['error']?.toString();
      notifyListeners();
      return false;
    }
    await refreshPhiloBots();
    return true;
  }

  Future<bool> deletePhiloBot(String id) async {
    _isLoading = true;
    notifyListeners();
    final result = await api.deletePhiloBot(id);
    _isLoading = false;
    if (result.containsKey('error')) {
      _lastChatError = result['error']?.toString();
      notifyListeners();
      return false;
    }
    await refreshPhiloBots();
    return true;
  }

  Future<bool> login(
    String user,
    String pass, {
    bool rememberSession = false,
    String sessionDuration = '24h',
  }) async {
    _isLoading = true;
    _authError = null;
    notifyListeners();

    final result = await api.login(
      user,
      pass,
      sessionDuration: sessionDuration,
    );
    _isLoading = false;

    if (result.containsKey('error')) {
      _authError = result['error'];
      notifyListeners();
      return false;
    } else if (api.token != null) {
      _sessionExpiryHandled = false;
      _lastChatError = null;
      if (rememberSession) {
        await _rememberSession();
      } else {
        await _clearRememberedSession();
      }
      await loadUserPrefs();
      await restoreChatSessions();
      notifyListeners();
      return true;
    } else {
      _authError = remainingUiText('appState.loginFailed');
      notifyListeners();
      return false;
    }
  }

  Future<bool> restoreRememberedSession() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final token = preferences.getString(_rememberedTokenKey);
      final user = preferences.getString(_rememberedUsernameKey);
      if (token == null || user == null || !_tokenCanBeRestored(token)) {
        await _clearRememberedSession();
        return false;
      }
      api.token = token;
      api.username = user;
      await loadUserPrefs();
      await restoreChatSessions();
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _rememberSession() async {
    try {
      final token = api.token;
      final user = api.username;
      if (token == null || user == null) return;
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_rememberedTokenKey, token);
      await preferences.setString(_rememberedUsernameKey, user);
    } catch (_) {}
  }

  Future<void> _clearRememberedSession() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.remove(_rememberedTokenKey);
      await preferences.remove(_rememberedUsernameKey);
    } catch (_) {}
  }

  bool _tokenCanBeRestored(String token) {
    try {
      final sections = token.split('.');
      if (sections.length != 3) return false;
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(sections[1]))),
      );
      if (payload is! Map<String, dynamic>) return false;
      if (payload['session_duration'] == 'permanent') return true;
      final exp = payload['exp'];
      final expirySeconds = exp is num ? exp.toInt() : int.tryParse('$exp');
      return expirySeconds != null &&
          DateTime.now().isBefore(
            DateTime.fromMillisecondsSinceEpoch(expirySeconds * 1000),
          );
    } catch (_) {
      return false;
    }
  }

  Future<bool> loadAuthStatus() async {
    _isLoading = true;
    _authError = null;
    notifyListeners();

    final result = await api.getAuthStatus();
    _isLoading = false;
    if (result.containsKey('error')) {
      _authError = result['error'];
      notifyListeners();
      return false;
    }
    _totpConfigured = result['totp_configured'] == true;
    _authenticatorApp = result['authenticator_app'] == '2fas'
        ? '2fas'
        : 'google';
    notifyListeners();
    return true;
  }

  Future<bool> startAuthenticatorSetup() async {
    _isLoading = true;
    _authError = null;
    notifyListeners();
    final result = await api.startAuthenticatorSetup();
    _isLoading = false;
    if (result.containsKey('error')) {
      _authError = result['error'];
      notifyListeners();
      return false;
    }
    _setupSecret = result['secret'];
    _setupOtpauthUrl = result['otpauth_url'];
    notifyListeners();
    return _setupSecret != null && _setupOtpauthUrl != null;
  }

  Future<bool> confirmAuthenticatorSetup(
    String code,
    String authenticatorApp,
  ) async {
    _isLoading = true;
    _authError = null;
    notifyListeners();
    final result = await api.confirmAuthenticatorSetup(code, authenticatorApp);
    _isLoading = false;
    if (result.containsKey('error')) {
      _authError = result['error'];
      notifyListeners();
      return false;
    }
    _totpConfigured = result['totp_configured'] == true;
    _authenticatorApp = authenticatorApp;
    if (_totpConfigured == true) {
      _setupSecret = null;
      _setupOtpauthUrl = null;
    }
    notifyListeners();
    return _totpConfigured == true;
  }

  Future<bool> createAccount(String user, String pass, String totpCode) async {
    _isLoading = true;
    _authError = null;
    notifyListeners();

    final result = await api.createAccount(user, pass, totpCode);
    _isLoading = false;

    if (result.containsKey('error')) {
      _authError = result['error'];
      notifyListeners();
      return false;
    }

    notifyListeners();
    return true;
  }

  Future<bool> resetPassword(
    String user,
    String newPassword,
    String totpCode,
  ) async {
    _isLoading = true;
    _authError = null;
    notifyListeners();

    final result = await api.resetPassword(user, newPassword, totpCode);
    _isLoading = false;

    if (result.containsKey('error')) {
      _authError = result['error'];
      notifyListeners();
      return false;
    }

    notifyListeners();
    return true;
  }

  String _modelThreshold = 'medium';
  String get modelThreshold => _modelThreshold;

  int get modelThresholdLimit {
    switch (_modelThreshold) {
      case 'small':
        return 3;
      case 'medium':
        return 6;
      case 'large':
        return 9;
      default:
        return 6;
    }
  }

  void setModelThreshold(String val) {
    _modelThreshold = val;
    notifyListeners();
  }

  String? selectedCode;
  String? selectedCodeLanguage;
  List<Map<String, String>> allCodeBlocks = [];
  double codeDrawerWidth = 450.0;

  String? selectedFilePath;
  String? selectedFileType;

  void showCodeAssistant(
    String code,
    String? language,
    List<Map<String, String>> allBlocks,
  ) {
    selectedCode = code;
    selectedCodeLanguage = language;
    allCodeBlocks = allBlocks;
    selectedFilePath = null;
    selectedFileType = null;
    notifyListeners();
  }

  void showFilePreview(String path) {
    selectedFilePath = path;
    allCodeBlocks = [];
    final file = File(path);
    if (!file.existsSync()) {
      selectedFileType = 'unknown';
      selectedCode = remainingUiText('appState.fileNotFound', {'path': path});
      selectedCodeLanguage = 'txt';
      notifyListeners();
      return;
    }

    final ext = path.split('.').last.toLowerCase();

    const textExtensions = {
      'txt',
      'html',
      'css',
      'js',
      'ts',
      'json',
      'dart',
      'yaml',
      'md',
      'py',
      'cpp',
      'h',
      'c',
      'sql',
      'sh',
      'bat',
      'ps1',
      'xml',
      'ini',
      'cfg',
      'log',
    };

    const imageExtensions = {'png', 'jpg', 'jpeg', 'gif', 'bmp', 'webp', 'ico'};

    if (textExtensions.contains(ext)) {
      try {
        final content = file.readAsStringSync();
        selectedFileType = 'text';
        selectedCode = content;
        selectedCodeLanguage = ext;

        if (ext == 'html') {
          try {
            if (Platform.isWindows) {
              Process.run('explorer.exe', [path]);
            }
          } catch (_) {}
        }
      } catch (e) {
        selectedFileType = 'unknown';
        selectedCode = remainingUiText('appState.fileReadFailed', {
          'error': '$e',
        });
        selectedCodeLanguage = 'txt';
      }
    } else if (imageExtensions.contains(ext)) {
      selectedFileType = 'image';
      selectedCode = path;
      selectedCodeLanguage = ext;
    } else if (ext == 'pdf') {
      selectedFileType = 'pdf';
      selectedCode = path;
      selectedCodeLanguage = 'pdf';

      try {
        if (Platform.isWindows) {
          Process.run('explorer.exe', [path]);
        }
      } catch (_) {}
    } else {
      selectedFileType = 'unknown';
      selectedCode = path;
      selectedCodeLanguage = ext;

      try {
        if (Platform.isWindows) {
          Process.run('explorer.exe', [path]);
        }
      } catch (_) {}
    }

    notifyListeners();
  }

  void closeCodeAssistant() {
    selectedCode = null;
    selectedCodeLanguage = null;
    allCodeBlocks = [];
    selectedFilePath = null;
    selectedFileType = null;
    notifyListeners();
  }

  void updateCodeAssistantWidth(double width) {
    codeDrawerWidth = width;
    notifyListeners();
  }

  void reorderModelFolders(int oldIndex, int newIndex) {
    final folder = modelFolders.removeAt(oldIndex);
    modelFolders.insert(newIndex, folder);
    notifyListeners();
  }

  void reorderModelInFolder(String folderId, int oldIndex, int newIndex) {
    final folderIndex = modelFolders.indexWhere((f) => f.id == folderId);
    if (folderIndex != -1) {
      final folder = modelFolders[folderIndex];
      final modelId = folder.modelIds.removeAt(oldIndex);
      folder.modelIds.insert(newIndex, modelId);
      notifyListeners();
    }
  }

  void logout() {
    api.logout();
    unawaited(_clearRememberedSession());
    _resetUserPreferencesForUnknownUser();
    _currentScreen = 'chat';
    _selectedModelId = null;
    _modelThreshold = 'medium';
    currentChatSessionId = null;
    chatSessions.clear();
    sessionTitles.clear();
    chatProjects.clear();
    sessionProjects.clear();

    unawaited(_persistLastChatSession());
    _lastChatError = null;

    selectedCode = null;
    selectedCodeLanguage = null;
    allCodeBlocks = [];
    selectedFilePath = null;
    selectedFileType = null;
    notifyListeners();
  }
}
