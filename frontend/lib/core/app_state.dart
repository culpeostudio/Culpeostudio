import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'design_tokens.dart';
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import './app_strings.dart';
import './remaining_ui_strings.dart';
import './api_service.dart';
import './startup_warmup.dart';
import '../modules/providers/provider_api.dart';

class ModelFolder {
  final String id;
  String name;
  Color color;
  final List<String> modelIds;
  String? parentId;
  bool isProviderFolder;

  ModelFolder({
    required this.id,
    required this.name,
    required this.color,
    required this.modelIds,
    this.parentId,
    this.isProviderFolder = false,
  });
}

class ActiveApiModel {
  final String provider;
  final String modelId;
  final String displayName;
  final String modelRef;

  /// Set for a model activated from the user-owned provider registry. It is
  /// carried into Scout so the backend can resolve the matching encrypted
  /// connection without treating a display label as an endpoint.
  final String? connectionId;

  ActiveApiModel({
    required this.provider,
    required this.modelId,
    required this.displayName,
    required this.modelRef,
    this.connectionId,
  });

  factory ActiveApiModel.fromJson(Map<String, dynamic> json) {
    final providerLabel = json['provider_label']?.toString().trim() ?? '';
    final provider = providerLabel.isNotEmpty
        ? providerLabel
        : (json['provider']?.toString() ?? '');
    final modelId = json['model_id']?.toString() ?? '';
    final displayName = json['display_name']?.toString() ?? modelId;
    final modelRef = json['model_ref']?.toString() ?? '';
    final connectionId = json['connection_id']?.toString().trim() ?? '';
    return ActiveApiModel(
      provider: provider,
      modelId: modelId,
      displayName: displayName.isEmpty ? modelId : displayName,
      modelRef: modelRef,
      connectionId: connectionId.isEmpty ? null : connectionId,
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
  final String? connectionId;

  const BotModelBinding({
    required this.kind,
    required this.modelRef,
    required this.provider,
    required this.modelId,
    this.instanceId,
    required this.displayName,
    this.connectionId,
  });

  bool get isLocal => kind == 'local' || provider == 'local';

  factory BotModelBinding.fromJson(Map<String, dynamic> json) {
    final kind = json['kind']?.toString().trim().toLowerCase() ?? '';
    final provider = json['provider']?.toString().trim() ?? '';
    final instanceId = json['instance_id']?.toString().trim() ?? '';
    final modelId = json['model_id']?.toString().trim() ?? '';
    final connectionId = json['connection_id']?.toString().trim() ?? '';
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
      connectionId: connectionId.isEmpty ? null : connectionId,
    );
  }

  Map<String, dynamic> toJson() => {
    'kind': isLocal ? 'local' : 'api',
    'model_ref': modelRef,
    'provider': provider,
    'model_id': modelId,
    if (instanceId?.isNotEmpty == true) 'instance_id': instanceId,
    if (connectionId?.isNotEmpty == true) 'connection_id': connectionId,
    'display_name': displayName,
  };
}

class ScoutChoice {
  final String id;
  final String name;
  final bool isDefault;
  final bool locked;
  final BotModelBinding? modelBinding;

  const ScoutChoice({
    required this.id,
    required this.name,
    this.isDefault = false,
    this.locked = false,
    this.modelBinding,
  });

  factory ScoutChoice.fromJson(Map<String, dynamic> json) {
    final rawBinding = json['model_binding'];
    return ScoutChoice(
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

/// A sub-folder inside a [ChatProject], for sorting a project's own chats
/// further. Unlike projects, this is a local-only, device-level grouping -
/// there is no backend endpoint for it - so it's persisted through
/// [SharedPreferences] instead of `api.spark`, the same way
/// [AppState.moduleOrder] is.
class ChatSubfolder {
  ChatSubfolder({
    required this.id,
    required this.projectId,
    required this.name,
    this.color,
  });

  final String id;
  final String projectId;
  String name;
  String? color;

  Map<String, dynamic> toJson() => {
    'id': id,
    'project_id': projectId,
    'name': name,
    if (color != null) 'color': color,
  };

  static ChatSubfolder? fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? '';
    final projectId = json['project_id']?.toString() ?? '';
    final name = json['name']?.toString() ?? '';
    if (id.isEmpty || projectId.isEmpty || name.isEmpty) return null;
    return ChatSubfolder(
      id: id,
      projectId: projectId,
      name: name,
      color: json['color']?.toString(),
    );
  }
}

class UserPreferences {
  const UserPreferences({required this.configured, required this.language});

  static const defaultLanguage = 'de';
  static const supportedLanguages = {'de', 'en'};

  final bool configured;
  final String language;

  bool get hasSupportedValues => supportedLanguages.contains(language);

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    final lang = json['language']?.toString() ?? '';
    return UserPreferences(
      configured: json['configured'] == true,
      language: lang.isEmpty ? UserPreferences.defaultLanguage : lang,
    );
  }
}

/// One entry in the model list the sidebar shows. A flattened, display-only
/// view of scout's `ChatModelChoice` so app_state stays free of a dependency
/// on the chat module.
class ChatModelPickerEntry {
  const ChatModelPickerEntry({
    required this.stableKey,
    required this.label,
    required this.subtitle,
    required this.isLocal,
    required this.selectable,
    required this.ready,
    required this.placementLabel,
  });

  final String stableKey;
  final String label;
  final String subtitle;
  final bool isLocal;
  final bool selectable;
  final bool ready;
  final String placementLabel;

  @override
  bool operator ==(Object other) =>
      other is ChatModelPickerEntry &&
      other.stableKey == stableKey &&
      other.label == label &&
      other.subtitle == subtitle &&
      other.isLocal == isLocal &&
      other.selectable == selectable &&
      other.ready == ready &&
      other.placementLabel == placementLabel;

  @override
  int get hashCode => Object.hash(
    stableKey,
    label,
    subtitle,
    isLocal,
    selectable,
    ready,
    placementLabel,
  );
}

/// Snapshot the active chat session publishes so the sidebar can show and
/// drive the same model choice without app_state depending on the chat
/// module. Whoever owns the running session (currently `ScoutTab`) calls
/// [AppState.publishChatModelPicker]; the callback fields stay out of
/// equality so a rebuild only ripples out when something the user would
/// actually see changed - the session setStates on every keystroke, and
/// that must not repaint the sidebar.
class ChatModelPickerState {
  const ChatModelPickerState({
    required this.entries,
    required this.selectedKey,
    required this.loading,
    required this.error,
    required this.locked,
    required this.lockedReason,
    required this.warmupActive,
    required this.warmupProgress,
    required this.warmupMessage,
    required this.onSelect,
    required this.onRefresh,
    required this.onOpenEngine,
    required this.onManageCloudModels,
    required this.onCancelWarmup,
  });

  final List<ChatModelPickerEntry> entries;
  final String? selectedKey;
  final bool loading;
  final String? error;
  final bool locked;
  final String? lockedReason;
  final bool warmupActive;
  final double warmupProgress;
  final String warmupMessage;

  final ValueChanged<String> onSelect;
  final VoidCallback onRefresh;
  final VoidCallback onOpenEngine;
  final VoidCallback onManageCloudModels;
  final VoidCallback onCancelWarmup;

  bool _sameData(ChatModelPickerState other) {
    if (entries.length != other.entries.length) return false;
    for (var i = 0; i < entries.length; i++) {
      if (entries[i] != other.entries[i]) return false;
    }
    return selectedKey == other.selectedKey &&
        loading == other.loading &&
        error == other.error &&
        locked == other.locked &&
        lockedReason == other.lockedReason &&
        warmupActive == other.warmupActive &&
        warmupProgress == other.warmupProgress &&
        warmupMessage == other.warmupMessage;
  }

  @override
  bool operator ==(Object other) =>
      other is ChatModelPickerState && _sameData(other);

  @override
  int get hashCode => Object.hash(
    Object.hashAll(entries),
    selectedKey,
    loading,
    error,
    locked,
    lockedReason,
    warmupActive,
    warmupProgress,
    warmupMessage,
  );
}

class AppState extends ChangeNotifier {
  static const _rememberedTokenKey = 'remembered_auth_token';
  static const _rememberedUsernameKey = 'remembered_auth_username';
  static const _lastChatSessionKey = 'last_chat_session_id';
  static const _moduleOrderKey = 'sidebar_module_order';
  static const _chatSubfoldersKey = 'chat_subfolders';
  static const _sessionSubfoldersKey = 'chat_session_subfolders';

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

  /// Section a navigation to the settings screen should land on, consumed
  /// (and cleared) the next time that screen is built. Null opens on General.
  int? pendingSettingsSection;

  String language = UserPreferences.defaultLanguage;

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
    return saveUserPreferences(language: lang);
  }

  Future<bool> loadUserPrefs() async {
    _resetUserPreferencesForUnknownUser();
    if (!isLoggedIn) {
      notifyListeners();
      return false;
    }

    final result = await api.login.getUserPreferences();
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

  Future<bool> saveUserPreferences({required String language}) async {
    final requested = UserPreferences(configured: true, language: language);
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

    final result = await api.login.updateUserPreferences(
      language: requested.language,
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
    return saveUserPreferences(language: pending.language);
  }

  Future<bool> retryUserPreferencesLoad() => loadUserPrefs();

  void _applyUserPreferences(UserPreferences preferences) {
    language = preferences.language;
    appLanguage = language;
  }

  void _resetUserPreferencesForUnknownUser() {
    language = UserPreferences.defaultLanguage;
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
      final res = await api.settings.getSettings();
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

  final List<dynamic> scouts = [];

  ChatModelPickerState? _chatModelPicker;
  ChatModelPickerState? get chatModelPicker => _chatModelPicker;

  /// Monotonically increasing UI request for choosing the chat whose model is
  /// about to be changed.  The workspace owns the actual pane list and
  /// consumes this signal only when it has more than one open pane.  Keeping
  /// the event in [AppState] lets the persistent sidebar ask the mounted chat
  /// workspace for a target without importing any scout widgets here.
  int _chatModelTargetSelectionRequest = 0;
  int get chatModelTargetSelectionRequest => _chatModelTargetSelectionRequest;

  /// Asks the active chat workspace to choose a target pane before the model
  /// sidebar is used.  A single-chat workspace deliberately ignores it, so
  /// the classic model-panel flow remains unchanged.
  void requestChatModelTargetSelection() {
    _chatModelTargetSelectionRequest++;
    notifyListeners();
  }

  /// The active chat session (today: `ScoutTab`) calls this whenever its
  /// model list, selection, or warmup state changes, so the sidebar can
  /// mirror it without app_state depending on the chat module directly.
  /// There is deliberately no call to clear this on dispose - a
  /// `ChangeNotifier` may not call `notifyListeners()` while Flutter is
  /// tearing the widget tree down, which is exactly when dispose runs. The
  /// stale snapshot left behind is harmless: the sidebar only shows it next
  /// to a screen that forces the chat session to remount and publish fresh
  /// state before the user can interact with it.
  void publishChatModelPicker(ChatModelPickerState? state) {
    _chatModelPicker = state;
    notifyListeners();
  }

  /// A folder's [ModelFolder.modelIds] hold cloud models by their bare
  /// `modelRef` and local (engine) models by the picker's whole
  /// `local:$instanceId` key. Nothing else in the app hands out a modelRef
  /// starting with `local:`, so the two can't be confused for one another.
  static bool isLocalModelFolderRef(String ref) => ref.startsWith('local:');

  final List<ModelFolder> modelFolders = [
    ModelFolder(
      id: 'general',
      name: 'API-Modelle',
      color: CulpeoColors.metric,
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
            color: CulpeoColors.metric,
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
          color: CulpeoColors.metric,
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

  /// Reihenfolge der Module in der Sidebar, wie sie ausgeliefert wird. Der
  /// Nutzer kann sie per Drag & Drop umsortieren; die Auswahl liegt lokal in
  /// den SharedPreferences und gilt damit pro Gerät.
  static const List<String> defaultModuleOrder = [
    'marketplace',
    'engine',
    'news',
    'benchmark',
  ];

  List<String> _moduleOrder = List<String>.of(defaultModuleOrder);
  List<String> get moduleOrder => List<String>.unmodifiable(_moduleOrder);

  Future<void> loadModuleOrder() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final saved = preferences.getStringList(_moduleOrderKey);
      if (saved == null) return;
      final sanitized = _sanitizedModuleOrder(saved);
      if (listEquals(sanitized, _moduleOrder)) return;
      _moduleOrder = sanitized;
      notifyListeners();
    } catch (_) {}
  }

  /// Verschiebt ein Modul an eine neue Stelle. [newIndex] zählt in der bereits
  /// um das Modul verkürzten Liste, so wie `onReorderItem` es meldet.
  Future<void> reorderModules(int oldIndex, int newIndex) async {
    if (oldIndex < 0 || oldIndex >= _moduleOrder.length) return;
    final target = newIndex.clamp(0, _moduleOrder.length - 1);
    if (target == oldIndex) return;
    final next = List<String>.of(_moduleOrder);
    next.insert(target, next.removeAt(oldIndex));
    _moduleOrder = next;
    notifyListeners();
    await _persistModuleOrder();
  }

  /// Behält nur bekannte Module, wirft Dubletten weg und hängt Module an, die
  /// es beim letzten Speichern noch nicht gab.
  static List<String> _sanitizedModuleOrder(List<String> raw) {
    final ordered = <String>[];
    for (final key in raw) {
      if (defaultModuleOrder.contains(key) && !ordered.contains(key)) {
        ordered.add(key);
      }
    }
    for (final key in defaultModuleOrder) {
      if (!ordered.contains(key)) ordered.add(key);
    }
    return ordered;
  }

  Future<void> _persistModuleOrder() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setStringList(_moduleOrderKey, _moduleOrder);
    } catch (_) {}
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
  bool _guestModeActive = false;
  bool get guestModeActive => _guestModeActive;

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
    String? connectionId,
  }) async {
    _isLoading = true;
    _lastChatError = null;
    notifyListeners();
    final selected = activeModelForRef(modelRef);
    final result = await api.scout.createSession(
      modelRef: modelRef,
      provider: provider ?? selected?.provider,
      modelId: modelId ?? selected?.modelId,
      instanceId: instanceId,
      botId: botId,
      projectId: projectId,
      connectionId: connectionId ?? selected?.connectionId,
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

      unawaited(api.scout.renameSession(sId, trimmed));
    }
  }

  void deleteSession(String sId) {
    if (chatSessions.contains(sId)) {
      chatSessions.remove(sId);
      sessionTitles.remove(sId);
      sessionProjects.remove(sId);
      if (sessionSubfolders.remove(sId) != null) {
        unawaited(_persistChatSubfolders());
      }
      if (currentChatSessionId == sId) {
        currentChatSessionId = chatSessions.isNotEmpty
            ? chatSessions.last
            : null;
        unawaited(_persistLastChatSession());
      }
      notifyListeners();

      unawaited(api.scout.deleteSession(sId));
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
    final result = await api.spark.createProject(
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
      api.spark.renameProject(
        projectId,
        trimmed,
        color: color,
        path: path,
        icon: icon,
      ),
    );
  }

  /// Deletes a folder. [withSessions] also deletes the chats filed in it -
  /// otherwise they stay and only lose their folder, which is what happened
  /// unconditionally before.
  Future<void> deleteChatProject(
    String projectId, {
    bool withSessions = false,
  }) async {
    final index = chatProjects.indexWhere((p) => p.id == projectId);
    if (index == -1) return;
    if (withSessions) {
      for (final sId in sessionsInProject(projectId)) {
        deleteSession(sId);
      }
    }
    chatProjects.removeAt(index);

    sessionProjects.removeWhere((_, pId) => pId == projectId);
    // Subfolders only exist inside their project, so they go with it.
    final removedFolderIds = chatSubfolders
        .where((f) => f.projectId == projectId)
        .map((f) => f.id)
        .toSet();
    chatSubfolders.removeWhere((f) => f.projectId == projectId);
    sessionSubfolders.removeWhere((_, fId) => removedFolderIds.contains(fId));
    notifyListeners();
    unawaited(api.spark.deleteProject(projectId));
    unawaited(_persistChatSubfolders());
  }

  Future<void> assignSessionToProject(String sId, String? projectId) async {
    if (!chatSessions.contains(sId)) return;
    if (projectId == null || projectId.isEmpty) {
      sessionProjects.remove(sId);
    } else {
      sessionProjects[sId] = projectId;
    }
    // A subfolder belongs to one project; leaving it behind here would
    // strand the session in a subfolder of a project it's no longer in.
    if (sessionSubfolders.remove(sId) != null) {
      unawaited(_persistChatSubfolders());
    }
    notifyListeners();
    unawaited(api.scout.setSessionProject(sId, projectId));
  }

  Future<void> restoreChatProjects() async {
    try {
      final result = await api.spark.listProjects();
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

  final List<ChatSubfolder> chatSubfolders = [];
  final Map<String, String> sessionSubfolders = {};

  List<ChatSubfolder> subfoldersInProject(String projectId) =>
      chatSubfolders.where((f) => f.projectId == projectId).toList();

  String? subfolderIdForSession(String sId) => sessionSubfolders[sId];

  List<String> sessionsInSubfolder(String subfolderId) => chatSessions
      .where((sId) => sessionSubfolders[sId] == subfolderId)
      .toList();

  /// Sessions in [projectId] that aren't sorted into one of its subfolders.
  List<String> sessionsDirectlyInProject(String projectId) {
    return sessionsInProject(
      projectId,
    ).where((sId) => sessionSubfolders[sId] == null).toList();
  }

  Future<ChatSubfolder> createChatSubfolder(
    String projectId,
    String name, {
    String? color,
  }) async {
    final trimmed = name.trim();
    final folder = ChatSubfolder(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      projectId: projectId,
      name: trimmed.isEmpty ? name : trimmed,
      color: color,
    );
    chatSubfolders.add(folder);
    notifyListeners();
    unawaited(_persistChatSubfolders());
    return folder;
  }

  Future<void> renameChatSubfolder(
    String subfolderId,
    String newName, {
    String? color,
  }) async {
    for (final folder in chatSubfolders) {
      if (folder.id != subfolderId) continue;
      final trimmed = newName.trim();
      if (trimmed.isNotEmpty) folder.name = trimmed;
      if (color != null) folder.color = color;
      break;
    }
    notifyListeners();
    unawaited(_persistChatSubfolders());
  }

  Future<void> deleteChatSubfolder(String subfolderId) async {
    if (!chatSubfolders.any((f) => f.id == subfolderId)) return;
    chatSubfolders.removeWhere((f) => f.id == subfolderId);
    sessionSubfolders.removeWhere((_, fId) => fId == subfolderId);
    notifyListeners();
    unawaited(_persistChatSubfolders());
  }

  /// A subfolder only makes sense inside its own project, so the UI is only
  /// meant to offer the session's *current* project's subfolders here -
  /// this does not itself change [sessionProjects].
  Future<void> assignSessionToSubfolder(String sId, String? subfolderId) async {
    if (!chatSessions.contains(sId)) return;
    if (subfolderId == null || subfolderId.isEmpty) {
      sessionSubfolders.remove(sId);
    } else {
      sessionSubfolders[sId] = subfolderId;
    }
    notifyListeners();
    unawaited(_persistChatSubfolders());
  }

  Future<void> loadChatSubfolders() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final rawFolders = preferences.getStringList(_chatSubfoldersKey);
      if (rawFolders != null) {
        final loaded = <ChatSubfolder>[];
        for (final raw in rawFolders) {
          try {
            final decoded = jsonDecode(raw);
            if (decoded is Map) {
              final folder = ChatSubfolder.fromJson(
                Map<String, dynamic>.from(decoded),
              );
              if (folder != null) loaded.add(folder);
            }
          } catch (_) {}
        }
        chatSubfolders
          ..clear()
          ..addAll(loaded);
      }
      final rawSessions = preferences.getString(_sessionSubfoldersKey);
      if (rawSessions != null) {
        try {
          final decoded = jsonDecode(rawSessions);
          if (decoded is Map) {
            sessionSubfolders
              ..clear()
              ..addAll(
                decoded.map(
                  (key, value) => MapEntry(key.toString(), value.toString()),
                ),
              );
          }
        } catch (_) {}
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _persistChatSubfolders() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setStringList(_chatSubfoldersKey, [
        for (final folder in chatSubfolders) jsonEncode(folder.toJson()),
      ]);
      await preferences.setString(
        _sessionSubfoldersKey,
        jsonEncode(sessionSubfolders),
      );
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
      final result = await api.scout.listSessions();
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
    String? providerError;
    Future<List<ActiveProviderModel>> loadProviderModels() async {
      try {
        return await api.providers.listActiveModels();
      } catch (error) {
        providerError = error.toString();
        return const [];
      }
    }

    final results = await Future.wait<Object>([
      api.marketplace.listActiveAPIModels(),
      loadProviderModels(),
    ]);
    final legacyResult = results[0] as Map<String, dynamic>;
    final providerModels = results[1] as List<ActiveProviderModel>;
    if (legacyResult.containsKey('error') && providerError != null) {
      _lastChatError = providerError;
      notifyListeners();
      return false;
    }

    final loaded = <ActiveApiModel>[];
    final loadedRefs = <String>{};
    final rawModels = legacyResult['models'];
    if (rawModels is List) {
      for (final item in rawModels) {
        if (item is Map) {
          final model = ActiveApiModel.fromJson(
            Map<String, dynamic>.from(item),
          );
          if (model.modelRef.isNotEmpty && loadedRefs.add(model.modelRef)) {
            loaded.add(model);
          }
        }
      }
    }
    for (final model in providerModels) {
      if (model.modelRef.isEmpty || !loadedRefs.add(model.modelRef)) continue;
      loaded.add(
        ActiveApiModel(
          provider: model.providerLabel,
          modelId: model.modelId,
          displayName: model.displayName,
          modelRef: model.modelRef,
          connectionId: model.connectionId,
        ),
      );
    }

    activeApiModels
      ..clear()
      ..addAll(loaded);
    final activeRefList = loaded.map((m) => m.modelRef).toList();
    final activeRefs = activeRefList.toSet();
    availableModelIds
      ..clear()
      ..addAll(activeRefList);

    // Drops cloud models the account no longer has. Local (engine) models
    // can be filed into folders too and are keyed by their own
    // `local:$instanceId`, which this list knows nothing about - they stay.
    for (final folder in modelFolders) {
      folder.modelIds.removeWhere(
        (id) => !isLocalModelFolderRef(id) && !activeRefs.contains(id),
      );
    }
    for (final model in loaded) {
      final alreadyFoldered = modelFolders.any(
        (f) => f.modelIds.contains(model.modelRef),
      );
      if (!alreadyFoldered) {
        final providerName = model.provider.trim().isNotEmpty
            ? model.provider.trim()
            : 'API';
        final folderId =
            'provider_${providerName.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_').toLowerCase()}';
        final providerFolder = modelFolders.firstWhere(
          (f) =>
              f.id == folderId ||
              f.name.toLowerCase() == providerName.toLowerCase(),
          orElse: () {
            final pf = ModelFolder(
              id: folderId,
              name: providerName,
              color: _colorForProviderName(providerName),
              modelIds: [],
              parentId: 'general',
              isProviderFolder: true,
            );
            modelFolders.add(pf);
            return pf;
          },
        );
        providerFolder.modelIds.add(model.modelRef);
      }
    }

    // Prune auto-generated provider folders that have no active models
    modelFolders.removeWhere((f) => f.isProviderFolder && f.modelIds.isEmpty);
    if (_selectedModelId == null || !activeRefs.contains(_selectedModelId)) {
      _selectedModelId = loaded.isNotEmpty ? loaded.first.modelRef : null;
    }

    notifyListeners();
    return true;
  }

  Future<bool> deleteActiveApiModel(String modelRef) async {
    try {
      await api.marketplace.deleteActiveAPIModel(modelRef);
    } catch (_) {}
    try {
      await api.providers.deleteActiveModel(modelRef);
    } catch (_) {}

    activeApiModels.removeWhere((m) => m.modelRef == modelRef);
    availableModelIds.remove(modelRef);
    for (final folder in modelFolders) {
      folder.modelIds.remove(modelRef);
    }
    modelFolders.removeWhere((f) => f.isProviderFolder && f.modelIds.isEmpty);
    if (_selectedModelId == modelRef) {
      _selectedModelId = activeApiModels.isNotEmpty
          ? activeApiModels.first.modelRef
          : null;
    }
    notifyListeners();
    return true;
  }

  Future<bool> refreshScouts() async {
    final result = await api.scout.getBots();
    if (result.containsKey('error')) {
      _lastChatError = result['error']?.toString();
      notifyListeners();
      return false;
    }
    final list = result['bots'];
    scouts.clear();
    if (list is List) {
      scouts.addAll(list);
    }
    notifyListeners();
    return true;
  }

  Future<bool> saveScout(Map<String, dynamic> bot) async {
    _isLoading = true;
    notifyListeners();
    final result = await api.scout.saveBot(bot);
    _isLoading = false;
    if (result.containsKey('error')) {
      _lastChatError = result['error']?.toString();
      notifyListeners();
      return false;
    }
    await refreshScouts();
    return true;
  }

  Future<bool> deleteScout(String id) async {
    _isLoading = true;
    notifyListeners();
    final result = await api.scout.deleteBot(id);
    _isLoading = false;
    if (result.containsKey('error')) {
      _lastChatError = result['error']?.toString();
      notifyListeners();
      return false;
    }
    await refreshScouts();
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

    final result = await api.login.login(
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
      StartupWarmup.instance.start();
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
      StartupWarmup.instance.start();
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

    final result = await api.login.getAuthStatus();
    _isLoading = false;
    if (result.containsKey('error')) {
      _authError = result['error'];
      notifyListeners();
      return false;
    }
    _totpConfigured = result['totp_configured'] == true;
    _guestModeActive = result['guest_mode_active'] == true;
    _authenticatorApp = result['authenticator_app'] == '2fas'
        ? '2fas'
        : 'google';
    notifyListeners();
    return true;
  }

  Future<bool> enableGuestMode() async {
    _isLoading = true;
    _authError = null;
    notifyListeners();
    final result = await api.login.enableGuestMode();
    _isLoading = false;
    if (result.containsKey('error')) {
      _authError = result['error'];
      notifyListeners();
      return false;
    }
    _guestModeActive = true;
    notifyListeners();
    return true;
  }

  Future<bool> disableGuestMode() async {
    _isLoading = true;
    _authError = null;
    notifyListeners();
    final result = await api.login.disableGuestMode();
    _isLoading = false;
    if (result.containsKey('error')) {
      _authError = result['error'];
      notifyListeners();
      return false;
    }
    _guestModeActive = false;
    notifyListeners();
    return true;
  }

  Future<bool> startAuthenticatorSetup() async {
    _isLoading = true;
    _authError = null;
    notifyListeners();
    final result = await api.login.startAuthenticatorSetup();
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
    final result = await api.login.confirmAuthenticatorSetup(
      code,
      authenticatorApp,
    );
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

    final result = await api.login.createAccount(user, pass, totpCode);
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

    final result = await api.login.resetPassword(user, newPassword, totpCode);
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
    api.login.logout();
    StartupWarmup.instance.clear();
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
    chatSubfolders.clear();
    sessionSubfolders.clear();

    unawaited(_persistLastChatSession());
    _lastChatError = null;

    selectedCode = null;
    selectedCodeLanguage = null;
    allCodeBlocks = [];
    selectedFilePath = null;
    selectedFileType = null;
  }
}

Color _colorForProviderName(String provider) {
  final lower = provider.toLowerCase();
  if (lower.contains('openai')) return const Color(0xFF10A37F);
  if (lower.contains('anthropic')) return const Color(0xFFD97706);
  if (lower.contains('gemini') || lower.contains('google')) {
    return const Color(0xFF4285F4);
  }
  if (lower.contains('mistral')) return const Color(0xFFFF7043);
  if (lower.contains('deepseek')) return const Color(0xFF009688);
  if (lower.contains('perplexity')) return const Color(0xFF22D3EE);
  if (lower.contains('together')) return const Color(0xFF8B5CF6);
  if (lower.contains('ollama')) return const Color(0xFFEAB308);
  return CulpeoColors.metric;
}
