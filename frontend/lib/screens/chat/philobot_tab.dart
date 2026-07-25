import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_markdown_latex/flutter_markdown_latex.dart';
import 'package:markdown/markdown.dart' as md;
import '../../services/api_service.dart';
import '../../state/app_state.dart';
import '../../engine/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/top_notification.dart';
import 'chat_history_panel.dart';
import 'chat_markdown_helpers.dart';
import 'chat_model_picker.dart';
import 'file_change_card.dart';
import 'interactive_code_block.dart';
import 'reasoning_dropdown.dart';
import 'chat_widgets.dart';
import 'model_management_dialog.dart';
import 'model_warmup.dart';
import 'chat_action_widgets.dart';
import 'permission_panel.dart';

class PhiloBotTab extends StatefulWidget {
  const PhiloBotTab({super.key, this.api, this.appState});

  final ApiService? api;
  final AppState? appState;

  @override
  State<PhiloBotTab> createState() => _PhiloBotTabState();
}

class _TwoDotMenuIcon extends StatelessWidget {
  const _TwoDotMenuIcon();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [_MenuDot(), SizedBox(width: 4), _MenuDot()],
    );
  }
}

class _MenuDot extends StatelessWidget {
  const _MenuDot();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white70,
        shape: BoxShape.circle,
      ),
      child: const SizedBox(width: 3, height: 3),
    );
  }
}

class _PhiloBotTabState extends State<PhiloBotTab> {
  late final ApiService _api;
  late final AppState _appState;

  final FocusNode _inputFocusNode = FocusNode();
  StreamSubscription<String>? _actionSubscription;
  StreamIterator<PhiloBotStreamEvent>? _activeMessageStream;
  int _chatRequestGeneration = 0;

  String? _sessionId;
  final List<Map<String, dynamic>> _messages = [];
  final _msgController = TextEditingController();
  final _editMessageController = TextEditingController();
  final _editMessageFocusNode = FocusNode();
  // Leer voreingestellt: welche Ordner freigegeben sind, ergibt sich aus dem
  // gewaehlten Projekt. Ein fest eingetragener Pfad waere auf einem anderen
  // Rechner ohnehin ungueltig.
  final _allowedRootsController = TextEditingController();
  final _scrollController = ScrollController();
  final StringBuffer _pendingAssistantDelta = StringBuffer();
  Timer? _streamRenderTimer;
  bool _scrollFrameScheduled = false;
  bool _isLoading = false;
  // Treibt die "PhiloBot arbeitet …"-Anzeige samt Sekundenzähler, solange auf
  // das erste Token gewartet wird (Modell-Warmup + Prompt-Verarbeitung).
  DateTime? _pendingSince;
  Timer? _pendingTicker;
  bool _isInitializingChat = true;
  String _thinkingLevel = 'medium';
  bool _webSearchEnabled = false;
  final String _agenticMode = 'execute';
  bool _showPlanningApproval = false;
  Map<String, dynamic>? _pendingPlanningData;
  String? _pendingAgenticMessage;
  // Offene Permission-Anfrage des Agenten (Zugriff ausserhalb des
  // Projektpfads): request_id/tool/path/session_id. Der Stream wartet
  // blockierend, bis der Nutzer im Panel darunter entscheidet.
  Map<String, dynamic>? _pendingPermission;
  // Dateibaum des aktiven Projekts (rechte Seitenleiste). Wird lazy geladen
  // und nach file_changed-Events debounced aktualisiert.
  bool _showFileTree = false;
  Map<String, dynamic>? _fileTree;
  bool _fileTreeLoading = false;
  Timer? _fileTreeRefreshTimer;
  final Set<String> _expandedTreePaths = {'.'};
  List<ChatModelChoice> _chatModelChoices = const [];
  ChatModelChoice? _selectedChatModel;
  List<EngineInstance> _engineInstances = const [];
  List<PhiloBotChoice> _botChoices = const [];
  String? _selectedBotId;
  String? _responseBotId;
  final ModelWarmupProgress _warmup = ModelWarmupProgress();
  StreamSubscription<EngineStreamEvent>? _engineWarmupSubscription;
  ChatModelChoice? _pendingWarmupChoice;
  String? _pendingWarmupMessage;
  bool _warmupCancelled = false;
  bool _isLoadingLocalModels = true;
  String? _localModelsError;
  bool _isDragging = false;
  int? _hoveredMessageIndex;
  int? _hoveredNavigatorMessageIndex;
  int? _editingMessageIndex;
  final Map<int, GlobalKey> _messageKeys = {};
  final List<Map<String, String>> _uploadedFiles = [];

  PhiloBotChoice? get _selectedBot {
    for (final bot in _botChoices) {
      if (bot.id == _selectedBotId) return bot;
    }
    return null;
  }

  PhiloBotChoice? get _warmupBot {
    final selected = _selectedBot;
    if (selected?.modelBinding != null) return selected;
    for (final bot in _botChoices) {
      if (bot.id == _responseBotId && bot.modelBinding != null) return bot;
    }
    return null;
  }

  ChatModelChoice _choiceForBinding(BotModelBinding binding) {
    final key = binding.isLocal
        ? 'local:${binding.instanceId ?? binding.modelId}'
        : 'cloud:${binding.modelRef}';
    for (final choice in _chatModelChoices) {
      if (choice.stableKey == key) return choice;
    }
    if (binding.isLocal) {
      final instanceId = binding.instanceId ?? binding.modelId;
      for (final instance in _engineInstances) {
        if (instance.id == instanceId) return ChatModelChoice.local(instance);
      }
    }
    return ChatModelChoice.binding(binding);
  }

  ChatModelChoice _latestChoice(ChatModelChoice choice) {
    for (final candidate in _chatModelChoices) {
      if (candidate.stableKey == choice.stableKey) return candidate;
    }
    return choice;
  }

  void _replaceChatModelChoice(ChatModelChoice replacement) {
    final index = _chatModelChoices.indexWhere(
      (choice) => choice.stableKey == replacement.stableKey,
    );
    final updated = [..._chatModelChoices];
    if (index >= 0) {
      updated[index] = replacement;
    } else {
      updated.add(replacement);
    }
    _chatModelChoices = updated;
    if (_selectedChatModel?.stableKey == replacement.stableKey) {
      _selectedChatModel = replacement;
    }
    if (_pendingWarmupChoice?.stableKey == replacement.stableKey) {
      _pendingWarmupChoice = replacement;
    }
  }

  void _markChoiceReady(ChatModelChoice choice, {EngineInstance? instance}) {
    final concrete = instance?.isReady == true
        ? ChatModelChoice.local(instance!)
        : ChatModelChoice(
            source: choice.source,
            stableKey: choice.stableKey,
            modelRef: choice.modelRef,
            provider: choice.provider,
            modelId: choice.modelId,
            instanceId: choice.instanceId,
            label: choice.label,
            subtitle: 'Lokal • Bereit',
            selectable: true,
            state: 'ready',
            placement: choice.placement,
          );
    _replaceChatModelChoice(concrete);
  }

  bool get _modelPickerLocked => _selectedBot?.modelBinding != null;
  bool get _interactionLocked => _isLoading || _warmup.isActive;

  final LayerLink _plusMenuLink = LayerLink();
  OverlayEntry? _plusMenuEntry;

  Future<void> _pickFile() async {
    _hidePlusMenu();
    try {
      final result = await FilePicker.pickFiles(allowMultiple: true);
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          for (var file in result.files) {
            if (file.path != null) {
              _uploadedFiles.add({'name': file.name, 'path': file.path!});
            }
          }
        });
      }
    } catch (e) {
      debugPrint("Error picking file: $e");
    }
  }

  void _openFile(String path) {
    _appState.showFilePreview(path);
  }

  void _showPlusMenu() {
    final themeColor = const Color(0xFFC9A24A);
    _plusMenuEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _hidePlusMenu,
              child: Container(color: Colors.transparent),
            ),
          ),
          Positioned(
            width: 280,
            child: CompositedTransformFollower(
              link: _plusMenuLink,
              showWhenUnlinked: false,
              targetAnchor: Alignment.topLeft,
              followerAnchor: Alignment.bottomLeft,
              offset: const Offset(0, -12),
              child: Material(
                color: Colors.transparent,
                child: _buildPlusMenuContent(themeColor),
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_plusMenuEntry!);
  }

  void _hidePlusMenu() {
    _plusMenuEntry?.remove();
    _plusMenuEntry = null;
  }

  void _togglePlusMenu() {
    if (_plusMenuEntry == null) {
      _showPlusMenu();
    } else {
      _hidePlusMenu();
    }
  }

  void _beginPending() {
    _pendingSince = DateTime.now();
    _pendingTicker?.cancel();
    // 1s-Ticker aktualisiert Sekundenzähler und Punkte auch dann, wenn gerade
    // keine Stream-Events kommen (stille Wartephase auf das erste Token).
    _pendingTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  void _endPending() {
    _pendingTicker?.cancel();
    _pendingTicker = null;
    _pendingSince = null;
  }

  // Anzeige, solange auf das erste Token gewartet wird: macht sichtbar, DASS
  // die KI arbeitet, WAS gerade passiert (Modell lädt vs. denkt nach) und WIE
  // LANGE es schon dauert – damit klar wird, dass die Zeit im Modell liegt.
  Widget _buildWorkingIndicator() {
    final elapsed = _pendingSince == null
        ? 0
        : DateTime.now().difference(_pendingSince!).inSeconds;
    final dotCount = 1 + (elapsed % 3);
    String phase;
    if (_warmup.isActive) {
      final pct = (_warmup.displayProgress * 100).clamp(0, 100).round();
      final base = _warmup.message.isNotEmpty
          ? _warmup.message
          : 'Modell wird geladen';
      phase = pct > 0 ? '$base · $pct %' : base;
    } else {
      phase = 'PhiloBot denkt nach';
    }
    final elapsedLabel = elapsed >= 2 ? '  ·  ${elapsed}s' : '';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 13,
          height: 13,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFFC9A24A),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            '$phase${'.' * dotCount}$elapsedLabel',
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 13,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  // Waehrend eine Antwort noch streamt, zeigen wir ihren Text als reinen
  // (nicht gerenderten) Markdown-Quelltext. flutter_markdown parst bei jedem
  // Token via didUpdateWidget neu und wirft bei unvollstaendigem Markdown
  // (z. B. halb empfangene Tabelle, offener Code-/Latex-Block) die Assertion
  // '_inlines.isEmpty'. Erst nach Abschluss rendern wir volles Markdown.
  Widget _buildStreamingText(String text) {
    return Text(
      text,
      style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
    );
  }

  // Waehrend ein <think>...</think> Block laeuft, treffen die Roh-Denk-Tokens
  // live hier ein (reasoning_delta), bevor die finale Antwort beginnt. Sobald
  // Content ankommt, klappt dieselbe Information zu ReasoningDropdown
  // zusammen, damit sie den Chatverlauf danach nicht vermuellt.
  Widget _buildLiveReasoningPreview(String reasoning) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(
              Icons.psychology_outlined,
              size: 14,
              color: Color(0xFFDFC077),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              reasoning.trim(),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 12,
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Chat-Kopfzeile: zeigt nur noch den Titel des aktiven Chats. Verlauf und
  // Projekte leben als Dropdown unter "Chat-Verlauf" im Sidebar-Untermenue
  // (siehe dashboard_screen.dart), nicht mehr hier.
  Widget _buildChatHistoryBar() {
    final currentId = _sessionId ?? _appState.currentChatSessionId;
    final currentTitle = currentId == null
        ? 'Kein aktiver Chat'
        : _appState.getSessionTitle(currentId);
    final currentProjectId = currentId == null
        ? null
        : _appState.projectIdForSession(currentId);
    final currentProject = currentProjectId == null
        ? null
        : _appState.projectById(currentProjectId);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          const Icon(Icons.forum_outlined, size: 15, color: Colors.white54),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    currentTitle,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (currentProject != null) ...[
                  const SizedBox(width: 8),
                  ChatProjectBadge(project: currentProject),
                ],
              ],
            ),
          ),
          if ((currentProject?.path ?? '').isNotEmpty)
            IconButton(
              key: const Key('file-tree-toggle'),
              tooltip: 'Dateibaum anzeigen',
              splashRadius: 16,
              onPressed: () {
                setState(() => _showFileTree = !_showFileTree);
                if (_showFileTree && _fileTree == null) {
                  _loadFileTree();
                }
              },
              icon: Icon(
                Icons.account_tree_outlined,
                size: 16,
                color: _showFileTree ? const Color(0xFFC9A24A) : Colors.white38,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlusMenuContent(Color themeColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF161617),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 18,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Web Search Option
          InkWell(
            onTap: () {
              setState(() {
                _webSearchEnabled = !_webSearchEnabled;
              });
              _plusMenuEntry?.markNeedsBuild();
            },
            borderRadius: BorderRadius.circular(8),
            hoverColor: themeColor.withValues(alpha: 0.09),
            splashColor: themeColor.withValues(alpha: 0.12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  Icon(
                    Icons.language,
                    color: _webSearchEnabled ? themeColor : Colors.white70,
                    size: 14,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Websuche',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 1),
                        Text(
                          'Echtzeit-Informationen',
                          style: TextStyle(color: Colors.white30, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _webSearchEnabled
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: _webSearchEnabled ? themeColor : Colors.white24,
                    size: 14,
                  ),
                ],
              ),
            ),
          ),
          // New Chat Option
          InkWell(
            key: const Key('chat-new-session-action'),
            onTap: _interactionLocked
                ? null
                : () {
                    _hidePlusMenu();
                    _startSession();
                  },
            borderRadius: BorderRadius.circular(8),
            hoverColor: themeColor.withValues(alpha: 0.09),
            splashColor: themeColor.withValues(alpha: 0.12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: const Row(
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    color: Colors.white70,
                    size: 14,
                  ),
                  SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Neustart',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 1),
                      Text(
                        'Unterhaltung zurücksetzen',
                        style: TextStyle(color: Colors.white30, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Datei hochladen Option
          InkWell(
            onTap: _pickFile,
            borderRadius: BorderRadius.circular(8),
            hoverColor: themeColor.withValues(alpha: 0.09),
            splashColor: themeColor.withValues(alpha: 0.12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: const Row(
                children: [
                  Icon(Icons.attach_file, color: Colors.white70, size: 14),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Datei hochladen',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 1),
                        Text(
                          'Lokale Datei auswählen',
                          style: TextStyle(color: Colors.white30, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _api = widget.api ?? ApiService();
    _appState = widget.appState ?? AppState();
    _appState.addListener(_onAppStateChanged);
    _actionSubscription = _appState.actionStream.listen((action) {
      if (!mounted) return;
      if (action == 'focus_chat_input') {
        _inputFocusNode.requestFocus();
      } else if (action.startsWith('new_chat_session')) {
        if (!_interactionLocked) {
          final parts = action.split(':');
          final projectId = parts.length > 1 && parts[1].isNotEmpty
              ? parts[1]
              : null;
          _startSession(projectId: projectId);
        }
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await _refreshChatModels();
        if (_appState.currentChatSessionId == null) {
          await _startSession(choice: _selectedChatModel);
        } else {
          _sessionId = _appState.currentChatSessionId;
          await _fetchHistory();
        }
      } finally {
        if (mounted) setState(() => _isInitializingChat = false);
      }
    });
  }

  @override
  void dispose() {
    _hidePlusMenu();
    _appState.removeListener(_onAppStateChanged);
    _actionSubscription?.cancel();
    _invalidateActiveMessageStream();
    _streamRenderTimer?.cancel();
    _fileTreeRefreshTimer?.cancel();
    _pendingTicker?.cancel();
    _engineWarmupSubscription?.cancel();
    _warmup.dispose();
    _inputFocusNode.dispose();
    _msgController.dispose();
    _editMessageController.dispose();
    _editMessageFocusNode.dispose();
    _allowedRootsController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onAppStateChanged() {
    if (!mounted) return;
    final nextSessionId = _appState.currentChatSessionId;
    if (nextSessionId != _sessionId) {
      _invalidateActiveMessageStream();
      setState(() {
        _sessionId = nextSessionId;
        _messages.clear();
        _isLoading = false;
      });
      if (nextSessionId != null) unawaited(_fetchHistory());
      return;
    }
    setState(() {});
  }

  void _invalidateActiveMessageStream() {
    _chatRequestGeneration++;
    final active = _activeMessageStream;
    _activeMessageStream = null;
    if (active != null) unawaited(_cancelMessageStream(active));
    _streamRenderTimer?.cancel();
    _streamRenderTimer = null;
    _pendingAssistantDelta.clear();
  }

  Future<void> _cancelMessageStream(
    StreamIterator<PhiloBotStreamEvent> stream,
  ) async {
    try {
      await stream.cancel();
    } catch (_) {
      // Disconnect errors belong to the invalidated request generation.
    }
  }

  bool _isCurrentChatRequest(int generation, String sessionId) {
    return generation == _chatRequestGeneration && _sessionId == sessionId;
  }

  Future<void> _refreshChatModels() async {
    if (mounted) {
      setState(() {
        _isLoadingLocalModels = true;
        _localModelsError = null;
      });
    }
    await Future.wait<void>([
      _appState.refreshActiveApiModels(),
      _appState.refreshPhiloBots(),
    ]);
    var instances = <EngineInstance>[];
    String? engineError;
    try {
      instances = await _api.getEngineInstances();
    } catch (error) {
      engineError = error.toString();
    }
    final choices = buildChatModelChoices(
      cloudModels: _appState.activeApiModels,
      engineInstances: instances,
    );
    final bots = _appState.philoBots
        .whereType<Map>()
        .map((bot) => PhiloBotChoice.fromJson(Map<String, dynamic>.from(bot)))
        .where((bot) => bot.id.isNotEmpty)
        .toList();
    if (!mounted) return;
    final previousKey = _selectedChatModel?.stableKey;
    ChatModelChoice? nextSelection;
    for (final choice in choices) {
      if (choice.stableKey == previousKey) {
        nextSelection = choice;
        break;
      }
    }
    final hasActiveSession =
        _sessionId != null || _appState.currentChatSessionId != null;
    if (nextSelection == null &&
        hasActiveSession &&
        _selectedChatModel != null) {
      final previous = _selectedChatModel!;
      nextSelection = previous.isLocal
          ? ChatModelChoice.unavailableSession(
              modelRef: previous.modelRef,
              provider: previous.provider,
              modelId: previous.modelId,
              instanceId: previous.instanceId,
              displayName: previous.label,
            )
          : previous;
      choices.add(nextSelection);
    }
    if (nextSelection == null && _appState.selectedModelId != null) {
      final cloudKey = 'cloud:${_appState.selectedModelId}';
      for (final choice in choices) {
        if (choice.stableKey == cloudKey) {
          nextSelection = choice;
          break;
        }
      }
    }
    nextSelection ??= choices.isEmpty ? null : choices.first;
    final selectedBotId = _selectedBotId ?? _appState.preferredBotId;
    final selectedBot = bots
        .where((bot) => bot.id == selectedBotId)
        .firstOrNull;
    final binding = selectedBot?.modelBinding;
    if (binding != null) {
      final key = binding.isLocal
          ? 'local:${binding.instanceId ?? binding.modelId}'
          : 'cloud:${binding.modelRef}';
      var boundChoice = choices
          .where((choice) => choice.stableKey == key)
          .firstOrNull;
      if (boundChoice == null && binding.isLocal) {
        final boundInstanceId = binding.instanceId ?? binding.modelId;
        final instance = instances
            .where((item) => item.id == boundInstanceId)
            .firstOrNull;
        if (instance != null) {
          boundChoice = ChatModelChoice.local(instance);
          choices.add(boundChoice);
        }
      }
      if (boundChoice != null) {
        nextSelection = boundChoice;
      } else {
        final unavailable = ChatModelChoice.binding(binding);
        choices.add(unavailable);
        nextSelection = unavailable;
      }
    }
    setState(() {
      _chatModelChoices = choices;
      _selectedChatModel = nextSelection;
      _engineInstances = instances;
      _botChoices = bots;
      _selectedBotId = selectedBot?.id;
      _isLoadingLocalModels = false;
      _localModelsError = engineError;
    });
  }

  Future<void> _selectChatModel(ChatModelChoice choice) async {
    if (_interactionLocked || _modelPickerLocked) return;
    if (_selectedChatModel?.stableKey == choice.stableKey &&
        _sessionId != null) {
      return;
    }
    _pendingWarmupMessage = null;
    _responseBotId = null;
    final previousSession = _sessionId;
    final previousSelection = _selectedChatModel;
    var target = choice;
    if (target.requiresWarmup && !await _ensureLocalModelReady(target)) {
      return;
    }
    target = _latestChoice(target);
    // Laeuft bereits ein Chat, wird das Modell in-place gewechselt — der
    // Verlauf bleibt erhalten und es entsteht keine neue (leere) Session.
    if (_sessionId != null) {
      final switched = await _switchSessionModel(target);
      if (switched && mounted) {
        setState(() => _selectedChatModel = target);
        if (!target.isLocal) {
          _appState.setSelectedModelId(target.modelRef);
        }
        showTopNotification(context, 'Modell gewechselt: ${target.label}');
      }
      return;
    }
    final started = await _startSession(choice: target, announce: true);
    if (!started && mounted) {
      setState(() {
        _sessionId = previousSession;
        _selectedChatModel = previousSelection;
      });
    }
  }

  /// Wechselt das Modell der aktiven Session ueber das Backend, ohne einen
  /// neuen Chat anzulegen.
  Future<bool> _switchSessionModel(ChatModelChoice target) async {
    final sessionId = _sessionId;
    if (sessionId == null) return false;
    final result = await _api.setPhiloBotSessionModel(
      sessionId,
      provider: target.provider,
      modelId: target.isLocal
          ? (target.instanceId ?? target.modelId)
          : target.modelId,
      modelRef: target.modelRef,
      displayName: target.label,
    );
    if (result['status'] == 'ok') return true;
    if (mounted) {
      _showChatError(
        result['error']?.toString() ?? 'Modellwechsel fehlgeschlagen',
      );
    }
    return false;
  }

  Future<bool> _startSession({
    ChatModelChoice? choice,
    bool announce = false,
    String? botId,
    String? projectId,
  }) async {
    if (_interactionLocked) return false;
    _invalidateActiveMessageStream();
    final target = choice ?? _selectedChatModel;
    if (mounted) setState(() => _isLoading = true);
    if (target == null) {
      if (mounted) {
        setState(() => _isLoading = false);
        showTopNotification(
          context,
          'Bitte zuerst ein lokales Engine- oder API-Modell starten',
          color: Colors.orange,
        );
      }
      return false;
    }
    final sId = await _appState.createNewChatSession(
      target.modelRef,
      provider: target.provider,
      modelId: target.modelId,
      instanceId: target.instanceId,
      botId: botId ?? _selectedBotId,
      projectId: projectId,
    );
    if (mounted) {
      setState(() {
        if (sId != null) {
          _sessionId = sId;
          _selectedChatModel = target;
          _messages.clear();
        }
        _isLoading = false;
      });
      if (sId != null && !target.isLocal) {
        _appState.setSelectedModelId(target.modelRef);
      }
    }
    if (_warmup.isReady) {
      _warmup.reset();
    }
    if (sId == null && mounted) {
      _showChatError(
        _appState.lastChatError ?? 'Konnte Chat-Sitzung nicht starten',
      );
      return false;
    }
    if (announce && mounted) {
      showTopNotification(context, 'Neuer Chat mit ${target.label} gestartet');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _inputFocusNode.requestFocus();
      });
    }
    return sId != null;
  }

  Future<bool> _ensureLocalModelReady(ChatModelChoice choice) async {
    final instanceId = choice.instanceId;
    if (!choice.isLocal || choice.isReady) return true;
    if (instanceId == null || instanceId.isEmpty || !choice.selectable) {
      _warmup.begin(
        instanceId: instanceId ?? '',
        modelName: choice.label,
        placement: choice.placement,
      );
      _warmup.fail(
        message: 'Das lokale Modell ist nicht mehr verfügbar.',
        code: 'local_model_not_found',
      );
      if (mounted) setState(() {});
      return false;
    }

    _pendingWarmupChoice = choice;
    _warmupCancelled = false;
    _warmup.begin(
      instanceId: instanceId,
      modelName: choice.label,
      placement: choice.placement,
    );
    if (mounted) setState(() {});

    var lastRelevantEvent = DateTime.now();
    var streamFailed = false;
    await _engineWarmupSubscription?.cancel();
    _engineWarmupSubscription = _api.streamEngineEvents().listen(
      (event) {
        var relevant = false;
        if (event.type == 'snapshot') {
          final rawInstances = event.data['instances'];
          if (rawInstances is List) {
            for (final raw in rawInstances) {
              final instance = EngineInstance.fromJson(raw);
              if (instance.id == instanceId) {
                _applyWarmupInstance(instance);
                relevant = true;
                break;
              }
            }
          }
        } else if (event.type == 'instance_changed' ||
            event.type == 'instance_created') {
          final instance = EngineInstance.fromJson(event.data);
          if (instance.id == instanceId) {
            _applyWarmupInstance(instance);
            relevant = true;
          }
        } else if (event.type == 'operation') {
          final operation = EngineOperation.fromJson(event.data);
          if (operation.instanceId == instanceId ||
              (_warmup.operationId.isNotEmpty &&
                  operation.id == _warmup.operationId)) {
            _applyWarmupOperation(operation);
            relevant = true;
          }
        }
        if (relevant) {
          lastRelevantEvent = DateTime.now();
          if (mounted) setState(() {});
        }
      },
      onError: (Object _) => streamFailed = true,
      cancelOnError: false,
    );

    try {
      final result = await _api.ensureEngineInstanceReady(instanceId);
      if (_warmupCancelled) {
        final lateOperationId = result.operationId?.trim() ?? '';
        if (lateOperationId.isNotEmpty) {
          try {
            await _api.cancelEngineOperation(lateOperationId);
          } catch (_) {
            // The UI remains cancelled even if the operation already finished.
          }
        }
        return false;
      }
      if (result.instance != null) _applyWarmupInstance(result.instance!);
      _warmup.updateFromJson({
        'instance_id': instanceId,
        if (result.operationId != null) 'operation_id': result.operationId,
        'status': result.isReady ? 'ready' : result.status,
        if (result.queuePosition != null)
          'queue_position': result.queuePosition,
      });
      if (result.isReady) {
        _markChoiceReady(choice, instance: result.instance);
        _warmup.complete(message: 'Modell ist bereit');
        return true;
      }

      final deadline = DateTime.now().add(const Duration(minutes: 10));
      while (DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 500));
        if (_warmupCancelled) return false;
        if (_warmup.isReady) {
          _markChoiceReady(choice);
          return true;
        }
        if (_warmup.hasFailed) return false;

        final silentFor = DateTime.now().difference(lastRelevantEvent);
        if (!streamFailed && silentFor < const Duration(seconds: 2)) continue;

        final operationId = _warmup.operationId;
        if (operationId.isNotEmpty) {
          try {
            _applyWarmupOperation(await _api.getEngineOperation(operationId));
          } catch (_) {
            // The instance snapshot below remains the final source of truth.
          }
        }
        try {
          final instance = await _api.getEngineInstance(instanceId);
          _applyWarmupInstance(instance);
        } catch (_) {
          // A later SSE event or poll can still recover the warmup.
        }
        lastRelevantEvent = DateTime.now();
        if (mounted) setState(() {});
      }
      _warmup.fail(
        message: 'Der Modellstart hat zu lange gewartet.',
        code: 'model_queue_timeout',
      );
      return false;
    } on ApiException catch (error) {
      _warmup.fail(
        message: error.message,
        code: error.code ?? 'local_model_unavailable',
      );
      return false;
    } catch (error) {
      _warmup.fail(
        message: 'Das lokale Modell konnte nicht gestartet werden: $error',
        code: 'local_model_unavailable',
      );
      return false;
    } finally {
      await _engineWarmupSubscription?.cancel();
      _engineWarmupSubscription = null;
      if (mounted) setState(() {});
    }
  }

  void _applyWarmupInstance(EngineInstance instance) {
    if (instance.id != _warmup.instanceId) return;
    final status = switch (instance.state) {
      'ready' => 'ready',
      'failed' || 'failed_rollback' => 'failed',
      'queued' => 'queued',
      _ => 'running',
    };
    _warmup.updateFromJson({
      'instance_id': instance.id,
      'status': status,
      'phase': instance.phase.isEmpty ? instance.state : instance.phase,
      'progress': instance.progress,
      'placement': instance.placement,
      if (instance.detailMessage.isNotEmpty) 'message': instance.detailMessage,
      if (instance.errorCode.isNotEmpty) 'code': instance.errorCode,
    });
    final index = _engineInstances.indexWhere((item) => item.id == instance.id);
    if (index >= 0) {
      final updated = [..._engineInstances];
      updated[index] = instance;
      _engineInstances = updated;
    }
    if (instance.isReady) {
      ChatModelChoice? matching;
      for (final choice in _chatModelChoices) {
        if (choice.instanceId == instance.id) {
          matching = choice;
          break;
        }
      }
      matching ??= _pendingWarmupChoice;
      if (matching != null && matching.instanceId == instance.id) {
        _markChoiceReady(matching, instance: instance);
      }
    }
  }

  void _applyWarmupOperation(EngineOperation operation) {
    final status = operation.isTerminal
        ? const {'completed', 'complete'}.contains(operation.state)
              ? 'ready'
              : operation.state == 'failed'
              ? 'failed'
              : operation.state == 'cancelled'
              ? 'cancelled'
              : 'running'
        : operation.state == 'queued'
        ? 'queued'
        : 'running';
    _warmup.updateFromJson({
      'operation_id': operation.id,
      if (operation.instanceId != null) 'instance_id': operation.instanceId,
      'status': status,
      'phase': operation.phase.isEmpty ? operation.state : operation.phase,
      'progress': operation.progress,
      if (operation.queuePosition != null)
        'queue_position': operation.queuePosition,
      if (operation.detailMessage.isNotEmpty)
        'message': operation.detailMessage,
      if (operation.errorCode.isNotEmpty) 'code': operation.errorCode,
    });
  }

  Future<void> _cancelModelWarmup() async {
    _warmupCancelled = true;
    final operationId = _warmup.operationId;
    final subscription = _engineWarmupSubscription;
    _engineWarmupSubscription = null;
    _warmup.cancel();
    if (mounted) setState(() {});

    await subscription?.cancel();
    if (operationId.isNotEmpty) {
      try {
        await _api.cancelEngineOperation(operationId);
      } catch (_) {}
    }
  }

  Future<void> _retryModelWarmup() async {
    if (_pendingWarmupMessage?.trim().isNotEmpty == true &&
        _sessionId != null) {
      await _sendMessage(reusePendingMessage: true);
      return;
    }
    final choice = _pendingWarmupChoice;
    if (choice == null) return;
    final ready = await _ensureLocalModelReady(choice);
    if (!ready || !mounted) return;
    await _startSession(
      choice: _latestChoice(choice),
      botId: _selectedBotId,
      announce: true,
    );
  }

  void _chooseAnotherModel() {
    _invalidateActiveMessageStream();
    setState(() {
      _sessionId = null;
      _selectedBotId = null;
      _responseBotId = null;
      _selectedChatModel = null;
      _pendingWarmupChoice = null;
      _pendingWarmupMessage = null;
      _warmup.reset();
    });
    _appState.clearCurrentChatSessionSelection();
    showTopNotification(context, 'Bitte jetzt ein anderes Modell auswählen');
  }

  void _showChatError(String message) {
    final normalized = message.toLowerCase();
    final needsSettingsShortcut =
        normalized.contains('openrouter api-key') ||
        normalized.contains('openrouter api key');
    showTopNotification(
      context,
      message,
      color: Colors.redAccent,
      actionLabel: needsSettingsShortcut ? 'Einstellungen' : null,
      onAction: needsSettingsShortcut
          ? () => _appState.setScreen('settings')
          : null,
      duration: needsSettingsShortcut
          ? const Duration(seconds: 7)
          : const Duration(seconds: 4),
    );
  }

  Future<void> _fetchHistory() async {
    final requestedSessionId = _sessionId;
    if (requestedSessionId == null) return;
    final res = await _api.getPhiloBotHistory(requestedSessionId);
    if (res.containsKey('messages') &&
        mounted &&
        _sessionId == requestedSessionId) {
      final sessionChoice = chatModelChoiceFromSessionMetadata(
        res,
        _chatModelChoices,
      );
      final rawSession = res['session'];
      final sessionMetadata = rawSession is Map
          ? Map<String, dynamic>.from(rawSession)
          : res;
      final lockedBotId = sessionMetadata['locked_bot_id']?.toString().trim();
      setState(() {
        _messages.clear();
        for (var m in res['messages']) {
          _messages.add({
            'role': m['role'],
            'content': m['content'],
            'bot_id': m['bot_id'],
            'bot_name': m['bot_name'],
          });
        }
        if (sessionChoice != null) {
          _selectedChatModel = sessionChoice;
          if (!_chatModelChoices.any(
            (choice) => choice.stableKey == sessionChoice.stableKey,
          )) {
            _chatModelChoices = [..._chatModelChoices, sessionChoice];
          }
        }
        _selectedBotId = lockedBotId?.isNotEmpty == true ? lockedBotId : null;
      });
      _scrollToBottom();
    }
  }

  Future<void> _sendMessage({
    bool? approvePlan,
    bool reusePendingMessage = false,
  }) async {
    if (_interactionLocked) return;
    final requestSessionId = _sessionId;
    final text = reusePendingMessage
        ? (_pendingWarmupMessage ?? '').trim()
        : approvePlan == null
        ? _msgController.text.trim()
        : (_pendingAgenticMessage ?? 'Plan genehmigt').trim();
    if ((text.isEmpty && approvePlan == null) || requestSessionId == null) {
      return;
    }
    _invalidateActiveMessageStream();
    final requestGeneration = _chatRequestGeneration;
    _hidePlusMenu();
    final editIndex = reusePendingMessage ? null : _editingMessageIndex;
    if (approvePlan == null && !reusePendingMessage) {
      if (_warmup.hasFailed) _warmup.reset();
      _pendingWarmupChoice = null;
      _responseBotId = null;
      _msgController.clear();
      _pendingAgenticMessage = text;
      _pendingWarmupMessage = text;
    }
    setState(() {}); // Reset send button state

    setState(() {
      if (!reusePendingMessage &&
          approvePlan == null &&
          editIndex != null &&
          editIndex >= 0 &&
          editIndex < _messages.length) {
        _messages.removeRange(editIndex, _messages.length);
      }
      if (reusePendingMessage) {
        prepareWarmupRetryMessages(_messages, text);
      } else if (approvePlan == null) {
        _messages.add({'role': 'user', 'content': text});
        _messages.add({'role': 'assistant', 'content': ''});
      } else if (_messages.isEmpty || _messages.last['role'] != 'assistant') {
        _messages.add({'role': 'assistant', 'content': ''});
      }
      _isLoading = true;
      _showPlanningApproval = false;
      _pendingPermission = null;
      _editingMessageIndex = null;
      _hoveredMessageIndex = null;
    });
    _beginPending();
    _scrollToBottom();

    final streamIterator = StreamIterator<PhiloBotStreamEvent>(
      _api.streamPhiloBotMessage(
        requestSessionId,
        text,
        thinkingLevel: _thinkingLevel,
        editMessageIndex: editIndex,
        mode: _thinkingLevel == 'agent' ? _agenticMode : null,
        allowedRoots: _thinkingLevel == 'agent' ? _allowedRoots() : null,
        approvePlan: approvePlan,
      ),
    );
    _activeMessageStream = streamIterator;
    try {
      while (await streamIterator.moveNext()) {
        if (!mounted ||
            !_isCurrentChatRequest(requestGeneration, requestSessionId)) {
          return;
        }
        final event = streamIterator.current;
        if (event.type == 'model_warmup') {
          final instanceId = event.data['instance_id']?.toString() ?? '';
          if (!_warmup.isActive && !_warmup.isReady) {
            final label = _chatModelChoices
                .where((choice) => choice.instanceId == instanceId)
                .map((choice) => choice.label)
                .firstOrNull;
            _warmup.begin(
              instanceId: instanceId,
              modelName: label ?? 'Lokales Modell',
              placement: event.data['placement']?.toString() ?? 'unknown',
            );
          }
          _warmup.updateFromJson(event.data);
          if (_warmup.isReady) {
            ChatModelChoice? warmedChoice;
            for (final choice in _chatModelChoices) {
              if (choice.instanceId == instanceId) {
                warmedChoice = choice;
                break;
              }
            }
            warmedChoice ??= _pendingWarmupChoice;
            if (warmedChoice != null && warmedChoice.instanceId == instanceId) {
              _markChoiceReady(warmedChoice);
              _selectedChatModel = _latestChoice(warmedChoice);
            }
          }
          setState(() {});
        } else if (event.type == 'bot_selected') {
          final botId = event.data['id']?.toString() ?? '';
          final botName = event.data['name']?.toString() ?? '';
          PhiloBotChoice? eventBot;
          for (final bot in _botChoices) {
            if (bot.id == botId) {
              eventBot = bot;
              break;
            }
          }
          final binding = eventBot?.modelBinding;
          final boundChoice = binding == null
              ? null
              : _choiceForBinding(binding);
          setState(() {
            if (_messages.isNotEmpty) {
              _messages.last['bot_id'] = botId;
              _messages.last['bot_name'] = botName;
            }
            _responseBotId = botId;
            if (boundChoice != null) {
              _replaceChatModelChoice(boundChoice);
              _selectedChatModel = boundChoice;
              if (!boundChoice.isReady) {
                _pendingWarmupChoice = boundChoice;
              }
            }
          });
        } else if (event.type == 'bot_created') {
          await _appState.refreshPhiloBots();
          final bot = event.data['bot'];
          final botName = bot is Map ? bot['name']?.toString() : null;
          if (bot is Map && _messages.isNotEmpty) {
            setState(() {
              _messages.last['created_bot'] = Map<String, dynamic>.from(bot);
            });
          }
          if (mounted && botName != null && botName.isNotEmpty) {
            showTopNotification(
              context,
              '$botName wurde in der Bot-Verwaltung gespeichert',
              color: Colors.green,
            );
          }
        } else if (event.type == 'text_delta') {
          final chunk = event.data['chunk']?.toString() ?? '';
          if (chunk.isEmpty) continue;
          _queueAssistantDelta(chunk);
        } else if (event.type == 'reasoning_delta') {
          final chunk = event.data['chunk']?.toString() ?? '';
          if (chunk.isEmpty) continue;
          if (_messages.isNotEmpty && _messages.last['role'] == 'assistant') {
            setState(() {
              _messages.last['reasoning'] =
                  '${_messages.last['reasoning'] ?? ''}$chunk';
            });
            _scrollToBottom();
          }
        } else if (event.type == 'tool_start' ||
            event.type == 'tool_result' ||
            event.type == 'planning_questions' ||
            event.type == 'plan_ready' ||
            event.type == 'approval_needed' ||
            event.type == 'permission_request' ||
            event.type == 'permission_result' ||
            event.type == 'file_changed' ||
            event.type == 'compression') {
          _handleAgenticSSEEvent(event);
        } else if (event.type == 'error') {
          _flushPendingAssistantDelta();
          final message =
              event.data['message']?.toString() ??
              'Antwort konnte nicht erzeugt werden';
          final code = event.data['code']?.toString() ?? '';
          const warmupCodes = {
            'resource_guard_rejected',
            'model_queue_timeout',
            'model_warmup_canceled',
            'local_model_not_found',
            'local_model_not_ready',
            'local_model_unavailable',
            'model_binding_missing',
            'model_binding_invalid',
          };
          if (warmupCodes.contains(code)) {
            if (_warmup.status == 'idle') {
              _warmup.begin(
                instanceId: event.data['instance_id']?.toString() ?? '',
                modelName: _selectedChatModel?.label ?? 'Lokales Modell',
                placement: _selectedChatModel?.placement ?? 'unknown',
              );
            }
            _warmup.fail(message: message, code: code);
          }
          setState(() {
            if (_messages.isNotEmpty &&
                _messages.last['role'] == 'assistant' &&
                (_messages.last['content'] ?? '').toString().isEmpty) {
              _messages.removeLast();
            }
            _isLoading = false;
            _pendingPermission = null;
            if (!warmupCodes.contains(code)) {
              _pendingWarmupMessage = null;
              _pendingWarmupChoice = null;
              _responseBotId = null;
            }
          });
          if (!warmupCodes.contains(code)) _showChatError(message);
          return;
        } else if (event.type == 'done') {
          _flushPendingAssistantDelta();
          if (_warmup.isReady) _warmup.reset();
          _pendingWarmupMessage = null;
          _pendingWarmupChoice = null;
          _responseBotId = null;
          _pendingPermission = null;
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (!mounted ||
          !_isCurrentChatRequest(requestGeneration, requestSessionId)) {
        return;
      }
      _flushPendingAssistantDelta();
      setState(() {
        if (_messages.isNotEmpty &&
            _messages.last['role'] == 'assistant' &&
            (_messages.last['content'] ?? '').toString().isEmpty) {
          _messages.removeLast();
        }
        _isLoading = false;
        _pendingPermission = null;
        _pendingWarmupMessage = null;
        _pendingWarmupChoice = null;
        _responseBotId = null;
      });
      _showChatError(e.toString());
    } finally {
      try {
        await streamIterator.cancel();
      } catch (_) {}
      if (identical(_activeMessageStream, streamIterator)) {
        _activeMessageStream = null;
      }
      _endPending();
      if (mounted &&
          _isCurrentChatRequest(requestGeneration, requestSessionId)) {
        _flushPendingAssistantDelta();
        setState(() => _isLoading = false);
      }
    }
  }

  List<String> _allowedRoots() {
    return _allowedRootsController.text
        .split(',')
        .map((root) => root.trim())
        .where((root) => root.isNotEmpty)
        .toList();
  }

  void _handleAgenticSSEEvent(PhiloBotStreamEvent event) {
    final entry = <String, dynamic>{
      'type': event.type,
      'data': event.data,
      'timestamp': DateTime.now().toIso8601String(),
    };
    setState(() {
      if (_messages.isNotEmpty && _messages.last['role'] == 'assistant') {
        final existing = _messages.last['agentic_events'];
        final events = existing is List ? existing : <dynamic>[];
        events.add(entry);
        _messages.last['agentic_events'] = events;
      }
      if (event.type == 'planning_questions' ||
          event.type == 'plan_ready' ||
          event.type == 'approval_needed') {
        final planning = event.data['planning'];
        _pendingPlanningData = planning is Map
            ? Map<String, dynamic>.from(planning)
            : <String, dynamic>{};
        _showPlanningApproval =
            event.type == 'plan_ready' || event.type == 'approval_needed';
      }
      if (event.type == 'permission_request') {
        _pendingPermission = Map<String, dynamic>.from(event.data);
      } else if (event.type == 'permission_result') {
        // Sicherheitsnetz: Panel schliessen, sobald die Entscheidung
        // backend-seitig durch ist (auch wenn sie nicht von hier kam).
        final id = event.data['request_id']?.toString();
        if (id != null && id == _pendingPermission?['request_id']?.toString()) {
          _pendingPermission = null;
        }
      }
      if (event.type == 'file_changed') {
        _scheduleFileTreeRefresh();
      }
    });
    if (event.type == 'compression' && mounted) {
      showTopNotification(context, 'Memory wurde komprimiert');
    }
    _scrollToBottom();
  }

  void _queueAssistantDelta(String chunk) {
    _pendingAssistantDelta.write(chunk);
    _streamRenderTimer ??= Timer(const Duration(milliseconds: 33), () {
      _streamRenderTimer = null;
      _flushPendingAssistantDelta();
    });
  }

  void _flushPendingAssistantDelta() {
    _streamRenderTimer?.cancel();
    _streamRenderTimer = null;
    final chunk = _pendingAssistantDelta.toString();
    if (chunk.isEmpty) return;
    _pendingAssistantDelta.clear();
    if (!mounted ||
        _messages.isEmpty ||
        _messages.last['role'] != 'assistant') {
      return;
    }
    setState(() {
      _messages.last['content'] = '${_messages.last['content'] ?? ''}$chunk';
    });
    _scrollToBottom();
  }

  Future<void> _sendQuickPrompt(String text) async {
    if (_isLoading || text.trim().isEmpty) return;
    _msgController.text = text.trim();
    await _sendMessage();
  }

  Future<void> _testCreatedBot(Map<String, dynamic> bot) async {
    final name = bot['name']?.toString() ?? 'der neue Bot';
    final keywords = bot['keywords'];
    final keyword = keywords is List && keywords.isNotEmpty
        ? keywords.first.toString()
        : name;
    await _sendQuickPrompt(
      '$keyword: Teste $name mit einer kurzen Beispielantwort.',
    );
  }

  Future<void> _copyAssistantMessage(String content) async {
    if (content.trim().isEmpty) return;
    await Clipboard.setData(ClipboardData(text: content));
    if (!mounted) return;
    showTopNotification(context, 'Antwort kopiert');
  }

  void _startEditingUserMessage(int index, String currentContent) {
    if (_isLoading) return;
    setState(() {
      _editingMessageIndex = index;
      _editMessageController.text = currentContent;
      _editMessageController.selection = TextSelection.collapsed(
        offset: _editMessageController.text.length,
      );
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _editMessageFocusNode.requestFocus();
    });
  }

  void _cancelEditingUserMessage() {
    setState(() {
      _editingMessageIndex = null;
      _editMessageController.clear();
    });
  }

  Future<void> _submitEditedUserMessage(
    int index,
    String currentContent,
  ) async {
    final text = _editMessageController.text.trim();
    if (text.isEmpty) {
      _cancelEditingUserMessage();
      return;
    }
    // Auch bei unveraendertem Text absenden: "Neu senden" ohne Textaenderung
    // ist der uebliche Weg, eine Antwort mit einem zwischenzeitlich anders
    // gewaehlten Modell neu zu generieren (Regenerate). Vorher wurde das
    // still abgebrochen, wenn der Text identisch blieb — dann passierte
    // sichtbar nichts.
    _msgController.text = text;
    await _sendMessage();
    _editMessageController.clear();
  }

  Future<void> _jumpToUserMessage(int index) async {
    if (!_scrollController.hasClients || _messages.length < 2) return;
    final targetContext = _messageKeys[index]?.currentContext;
    if (targetContext != null) {
      await Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        alignment: 0.18,
      );
      return;
    }
    final position = _scrollController.position;
    final estimatedOffset =
        position.maxScrollExtent * (index / (_messages.length - 1));
    await _scrollController.animateTo(
      estimatedOffset,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
    await Future<void>.delayed(const Duration(milliseconds: 16));
    if (!mounted) return;
    final renderedContext = _messageKeys[index]?.currentContext;
    if (renderedContext != null && renderedContext.mounted) {
      await Scrollable.ensureVisible(
        renderedContext,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        alignment: 0.18,
      );
    }
  }

  void _scrollToBottom({bool forceSmooth = false}) {
    if (_scrollFrameScheduled) return;
    _scrollFrameScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollFrameScheduled = false;
      if (mounted && _scrollController.hasClients) {
        if (_isLoading && !forceSmooth) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        } else {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      }
    });
  }

  List<Map<String, String>> _extractCodeBlocks() {
    final List<Map<String, String>> blocks = [];
    final regExp = RegExp(r'```([a-zA-Z0-9_\-\+]*)\n([\s\S]*?)```');
    for (final msg in _messages) {
      final content = msg['content'] ?? '';
      final matches = regExp.allMatches(content);
      for (final match in matches) {
        final lang = match.group(1)?.trim() ?? '';
        final code = match.group(2) ?? '';
        if (code.trim().isNotEmpty && !isMarkdownSourceLanguage(lang)) {
          blocks.add({'lang': lang.isEmpty ? 'code' : lang, 'code': code});
        }
      }
    }
    return blocks;
  }

  void _showModelManagementDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => ModelManagementDialog(
        appState: _appState,
        themeColor: const Color(0xFFC9A24A),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializingChat) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Color(0xFFC9A24A),
              ),
            ),
            SizedBox(height: 14),
            Text(
              'Chat wird vorbereitet …',
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ],
        ),
      );
    }
    return Column(
      children: [
        _buildChatHistoryBar(),
        if (_isLoading && _sessionId == null)
          const LinearProgressIndicator(
            backgroundColor: Colors.transparent,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC9A24A)),
          ),
        // Messages List
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _sessionId == null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.forum_outlined,
                              size: 48,
                              color: Colors.white24,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _isLoading
                                  ? 'Initialisiere neuen Chat...'
                                  : _chatModelChoices.isEmpty
                                  ? 'Noch kein Modell bereit'
                                  : 'Kein aktiver Chat',
                              style: const TextStyle(
                                color: Colors.white30,
                                fontSize: 13,
                              ),
                            ),
                            if (!_isLoading && _chatModelChoices.isEmpty) ...[
                              const SizedBox(height: 8),
                              const Text(
                                'Starte ein lokales Engine- oder API-Modell, um loszulegen.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white24,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                alignment: WrapAlignment.center,
                                children: [
                                  OutlinedButton.icon(
                                    key: const Key('open-local-engine-button'),
                                    onPressed: () =>
                                        _appState.setScreen('engine'),
                                    icon: const Icon(Icons.memory, size: 15),
                                    label: const Text('Lokales Modell starten'),
                                  ),
                                  TextButton.icon(
                                    onPressed: _showModelManagementDialog,
                                    icon: const Icon(
                                      Icons.cloud_outlined,
                                      size: 15,
                                    ),
                                    label: const Text('API-Modell wählen'),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      )
                    : Stack(
                        children: [
                          ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 52,
                              vertical: 16,
                            ),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final m = _messages[index];
                              final isUser = m['role'] == 'user';
                              final content = (m['content'] ?? '').toString();
                              final isStreamingAssistant =
                                  !isUser &&
                                  _isLoading &&
                                  index == _messages.length - 1;
                              final displayContent = isStreamingAssistant
                                  ? (content.isEmpty ? '|' : '$content |')
                                  : content;
                              final markdownContent = normalizeChatMarkdown(
                                displayContent,
                              );
                              final reasoning = (m['reasoning'] ?? '')
                                  .toString();
                              final isReasoningLive =
                                  isStreamingAssistant && content.isEmpty;
                              return Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 920,
                                  ),
                                  child: Align(
                                    alignment: isUser
                                        ? Alignment.centerRight
                                        : Alignment.centerLeft,
                                    child: MouseRegion(
                                      key: _messageKeys.putIfAbsent(
                                        index,
                                        GlobalKey.new,
                                      ),
                                      onEnter: (_) => setState(
                                        () => _hoveredMessageIndex = index,
                                      ),
                                      onExit: (_) {
                                        if (_hoveredMessageIndex == index) {
                                          setState(
                                            () => _hoveredMessageIndex = null,
                                          );
                                        }
                                      },
                                      child: Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          Container(
                                            margin: const EdgeInsets.only(
                                              bottom: 42,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 12,
                                            ),
                                            constraints: const BoxConstraints(
                                              maxWidth: 640,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isUser
                                                  ? const Color(
                                                      0xFFC9A24A,
                                                    ).withValues(alpha: 0.08)
                                                  : Colors.white.withValues(
                                                      alpha: 0.03,
                                                    ),
                                              borderRadius: BorderRadius.only(
                                                topLeft: const Radius.circular(
                                                  16,
                                                ),
                                                topRight: const Radius.circular(
                                                  16,
                                                ),
                                                bottomLeft: isUser
                                                    ? const Radius.circular(16)
                                                    : const Radius.circular(4),
                                                bottomRight: isUser
                                                    ? const Radius.circular(4)
                                                    : const Radius.circular(16),
                                              ),
                                              border: Border.all(
                                                color: isUser
                                                    ? const Color(
                                                        0xFFC9A24A,
                                                      ).withValues(alpha: 0.2)
                                                    : Colors.white.withValues(
                                                        alpha: 0.06,
                                                      ),
                                                width: 1.0,
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                if (!isUser &&
                                                    m['bot_name'] != null &&
                                                    m['bot_name']
                                                        .toString()
                                                        .isNotEmpty) ...[
                                                  Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        m['bot_id'] ==
                                                                'philobot'
                                                            ? Icons
                                                                  .security_outlined
                                                            : Icons
                                                                  .smart_toy_outlined,
                                                        size: 10,
                                                        color: Colors.white30,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        m['bot_name']
                                                            .toString()
                                                            .toUpperCase(),
                                                        style: const TextStyle(
                                                          color: Colors.white30,
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          letterSpacing: 0.5,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 6),
                                                ],
                                                if (!isUser &&
                                                    reasoning.isNotEmpty)
                                                  isReasoningLive
                                                      ? _buildLiveReasoningPreview(
                                                          reasoning,
                                                        )
                                                      : ReasoningDropdown(
                                                          reasoning: reasoning,
                                                        ),
                                                if (isUser &&
                                                    _editingMessageIndex ==
                                                        index)
                                                  _buildInlineMessageEditor(
                                                    index,
                                                    content,
                                                  )
                                                else if (isStreamingAssistant &&
                                                    content.isEmpty)
                                                  // Immer der tickende Spinner (nicht
                                                  // nur wenn reasoning leer ist):
                                                  // sobald ein Denkblock einmal Text
                                                  // geliefert hat, blieb der Screen
                                                  // zwischen Tool-Runden sonst
                                                  // eingefroren (nur die alte
                                                  // reasoning-Vorschau + ein
                                                  // reglungsloser Cursor) — sah wie
                                                  // abgestuerzt aus, obwohl das
                                                  // Modell noch an der naechsten
                                                  // Runde arbeitete.
                                                  _buildWorkingIndicator()
                                                else if (isStreamingAssistant)
                                                  _buildStreamingText(
                                                    displayContent,
                                                  )
                                                else
                                                  MarkdownBody(
                                                    data: markdownContent,
                                                    selectable: true,
                                                    onTapLink:
                                                        (text, href, title) {
                                                          openMarkdownLink(
                                                            context,
                                                            href,
                                                          );
                                                        },
                                                    checkboxBuilder: (checked) =>
                                                        buildMarkdownCheckbox(
                                                          checked,
                                                          color: const Color(
                                                            0xFFDFC077,
                                                          ),
                                                        ),
                                                    builders: {
                                                      if (shouldUseInputCheckboxBuilder(
                                                        markdownContent,
                                                      ))
                                                        'input':
                                                            TaskCheckboxElementBuilder(
                                                              accentColor:
                                                                  const Color(
                                                                    0xFFDFC077,
                                                                  ),
                                                            ),
                                                      'code': InteractiveCodeElementBuilder(
                                                        onCodeTap: (code, lang) {
                                                          final allBlocks =
                                                              _extractCodeBlocks();
                                                          _appState
                                                              .showCodeAssistant(
                                                                code,
                                                                lang,
                                                                allBlocks,
                                                              );
                                                        },
                                                      ),
                                                      'latex':
                                                          LatexElementBuilder(
                                                            textStyle:
                                                                const TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontSize: 14,
                                                                ),
                                                          ),
                                                    },
                                                    blockSyntaxes: [
                                                      LatexBlockSyntax(),
                                                    ],
                                                    inlineSyntaxes: [
                                                      LatexInlineSyntax(),
                                                    ],
                                                    extensionSet: md
                                                        .ExtensionSet
                                                        .gitHubFlavored,
                                                    styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                                                      codeblockDecoration:
                                                          const BoxDecoration(
                                                            color: Colors
                                                                .transparent,
                                                          ),
                                                      codeblockPadding:
                                                          EdgeInsets.zero,
                                                      p: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 14,
                                                        height: 1.4,
                                                      ),
                                                      pPadding:
                                                          const EdgeInsets.only(
                                                            bottom: 12.0,
                                                          ),
                                                      blockquotePadding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 16,
                                                            vertical: 8,
                                                          ),
                                                      blockquoteDecoration:
                                                          BoxDecoration(
                                                            color: Colors.white
                                                                .withValues(
                                                                  alpha: 0.05,
                                                                ),
                                                            border: const Border(
                                                              left: BorderSide(
                                                                color: Color(
                                                                  0xFF232a37,
                                                                ),
                                                                width: 4,
                                                              ),
                                                            ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  4,
                                                                ),
                                                          ),
                                                      blockquote:
                                                          const TextStyle(
                                                            color:
                                                                Colors.white70,
                                                            fontSize: 14,
                                                            fontStyle: FontStyle
                                                                .italic,
                                                          ),
                                                      checkbox: const TextStyle(
                                                        color: Color(
                                                          0xFFDFC077,
                                                        ),
                                                        fontSize: 18,
                                                      ),
                                                      horizontalRuleDecoration:
                                                          BoxDecoration(
                                                            border: Border(
                                                              top: BorderSide(
                                                                color: Colors
                                                                    .white
                                                                    .withValues(
                                                                      alpha:
                                                                          0.15,
                                                                    ),
                                                                width: 1.0,
                                                              ),
                                                            ),
                                                          ),
                                                      strong: const TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 14,
                                                      ),
                                                      em: const TextStyle(
                                                        color: Colors.white,
                                                        fontStyle:
                                                            FontStyle.italic,
                                                        fontSize: 14,
                                                      ),
                                                      code: TextStyle(
                                                        color: const Color(
                                                          0xFFEBD9A8,
                                                        ),
                                                        backgroundColor: Colors
                                                            .white
                                                            .withValues(
                                                              alpha: 0.15,
                                                            ),
                                                        fontSize: 13,
                                                        fontFamily: 'monospace',
                                                      ),
                                                      tableBody:
                                                          const TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 13,
                                                          ),
                                                      tableHead:
                                                          const TextStyle(
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 13,
                                                          ),
                                                      tableBorder:
                                                          TableBorder.all(
                                                            color: Colors.white
                                                                .withValues(
                                                                  alpha: 0.15,
                                                                ),
                                                            width: 1.0,
                                                          ),
                                                      listBullet:
                                                          const TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 14,
                                                          ),
                                                    ),
                                                  ),
                                                if (!isUser &&
                                                    m['created_bot']
                                                        is Map) ...[
                                                  const SizedBox(height: 12),
                                                  _buildCreatedBotCard(
                                                    Map<String, dynamic>.from(
                                                      m['created_bot'],
                                                    ),
                                                  ),
                                                ],
                                                if (!isUser &&
                                                    m['agentic_events']
                                                        is List) ...[
                                                  const SizedBox(height: 12),
                                                  _buildAgenticEvents(
                                                    List<dynamic>.from(
                                                      m['agentic_events'],
                                                    ),
                                                  ),
                                                  _buildFileChanges(
                                                    List<dynamic>.from(
                                                      m['agentic_events'],
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          if (_hoveredMessageIndex == index &&
                                              !isStreamingAssistant)
                                            Positioned(
                                              bottom: 8,
                                              right: isUser ? 6 : null,
                                              left: isUser ? null : 6,
                                              child: _buildMessageActions(
                                                message: m,
                                                index: index,
                                                isUser: isUser,
                                                content: content,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          if (_messages.any(
                            (message) => message['role'] == 'user',
                          ))
                            Positioned(
                              top: 0,
                              right: 0,
                              bottom: 0,
                              child: _buildUserMessageNavigator(),
                            ),
                        ],
                      ),
              ),
              if (_showFileTree && _sessionId != null) _buildFileTreePanel(),
            ],
          ),
        ),
        if (_pendingPermission != null)
          PermissionPanel(
            pending: _pendingPermission!,
            onRespond: _respondPermission,
          ),
        if (_showPlanningApproval) _buildPlanningApprovalPanel(),
        ModelWarmupPanel(
          progress: _warmup,
          onCancel: _cancelModelWarmup,
          onRetry: _retryModelWarmup,
          onChooseAnother: _chooseAnotherModel,
          onChangeBinding: _warmupBot?.modelBinding == null
              ? null
              : () => _appState.setScreen('bot_management'),
        ),
        // Redesigned Floating Input Bar
        _buildFloatingInputBar(),
        const SizedBox(height: 6),
        Text(
          'Powered by PhiloEngine • Created by fillystudio',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.18),
            fontSize: 12,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildAgenticEvents(List<dynamic> events) {
    final visible = events.take(8).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: visible.map((raw) {
        final event = raw is Map
            ? Map<String, dynamic>.from(raw)
            : <String, dynamic>{};
        final type = event['type']?.toString() ?? '';
        final data = event['data'] is Map
            ? Map<String, dynamic>.from(event['data'] as Map)
            : <String, dynamic>{};
        final toolName =
            data['name']?.toString() ?? (data['tool_name']?.toString() ?? '');
        final planning = data['planning'] is Map
            ? Map<String, dynamic>.from(data['planning'] as Map)
            : data;
        final summary = planning['plan_summary']?.toString() ?? '';
        final label = switch (type) {
          'tool_start' =>
            toolName.isEmpty ? 'Tool gestartet' : '$toolName gestartet',
          'tool_result' =>
            toolName.isEmpty ? 'Tool beendet' : '$toolName beendet',
          'planning_questions' => 'Planungsfragen',
          'plan_ready' => summary.isEmpty ? 'Plan bereit' : summary,
          'approval_needed' =>
            summary.isEmpty ? 'Freigabe erforderlich' : summary,
          'permission_request' => 'Zugriff außerhalb angefragt',
          'permission_result' => switch (data['decision']?.toString()) {
            'once' => 'Zugriff erlaubt (einmalig)',
            'session' => 'Zugriff erlaubt (Sitzung)',
            _ => 'Zugriff abgelehnt',
          },
          'file_changed' => switch (data['action']?.toString()) {
            'created' => 'Datei erstellt',
            'deleted' => 'Datei gelöscht',
            'moved' => 'Datei verschoben',
            _ => 'Datei geändert',
          },
          'compression' => 'Memory komprimiert',
          _ => type,
        };
        final icon = switch (type) {
          'tool_start' => Icons.play_arrow_outlined,
          'tool_result' => Icons.check_circle_outline,
          'planning_questions' => Icons.help_outline,
          'plan_ready' => Icons.fact_check_outlined,
          'approval_needed' => Icons.verified_outlined,
          'permission_request' => Icons.privacy_tip_outlined,
          'permission_result' =>
            data['decision']?.toString() == 'deny'
                ? Icons.block
                : Icons.verified_user_outlined,
          'file_changed' => Icons.edit_note,
          'compression' => Icons.compress,
          _ => Icons.info_outline,
        };
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: const Color(0xFFDFC077)),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// Icon fuer einen Dateinamen im Dateibaum, grob nach Endung.
  IconData _fileTreeIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.dart') ||
        lower.endsWith('.go') ||
        lower.endsWith('.py') ||
        lower.endsWith('.js') ||
        lower.endsWith('.ts')) {
      return Icons.code_rounded;
    }
    if (lower.endsWith('.md') || lower.endsWith('.txt')) {
      return Icons.article_outlined;
    }
    if (lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.svg') ||
        lower.endsWith('.gif')) {
      return Icons.image_outlined;
    }
    if (lower.endsWith('.json') ||
        lower.endsWith('.yaml') ||
        lower.endsWith('.yml') ||
        lower.endsWith('.toml')) {
      return Icons.settings_outlined;
    }
    return Icons.insert_drive_file_outlined;
  }

  /// Rechte Seitenleiste mit dem Dateibaum des aktiven Projekts.
  Widget _buildFileTreePanel() {
    final tree = _fileTree;
    return Container(
      width: 260,
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: Colors.white10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 4, 6),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Dateien',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  key: const Key('file-tree-refresh'),
                  tooltip: 'Aktualisieren',
                  splashRadius: 14,
                  onPressed: _loadFileTree,
                  icon: const Icon(
                    Icons.refresh,
                    size: 14,
                    color: Colors.white38,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white10),
          Expanded(
            child: tree == null
                ? const Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFFC9A24A),
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    children: _buildTreeNodes(tree, 0),
                  ),
          ),
        ],
      ),
    );
  }

  /// Baut die Zeilen des Dateibaums rekursiv; Ordner zuerst, dann Dateien.
  List<Widget> _buildTreeNodes(Map<String, dynamic> node, int depth) {
    final children = node['children'];
    if (children is! List) return const [];
    final nodes = children
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    nodes.sort((a, b) {
      final aDir = a['is_dir'] == true;
      final bDir = b['is_dir'] == true;
      if (aDir != bDir) return aDir ? -1 : 1;
      return (a['name']?.toString() ?? '').compareTo(
        b['name']?.toString() ?? '',
      );
    });
    final widgets = <Widget>[];
    for (final child in nodes) {
      final name = child['name']?.toString() ?? '';
      final path = child['path']?.toString() ?? name;
      final isDir = child['is_dir'] == true;
      final expanded = _expandedTreePaths.contains(path);
      widgets.add(
        InkWell(
          onTap: isDir
              ? () => setState(() {
                  expanded
                      ? _expandedTreePaths.remove(path)
                      : _expandedTreePaths.add(path);
                })
              : null,
          child: Padding(
            padding: EdgeInsets.only(
              left: 10.0 + depth * 14.0,
              top: 3,
              bottom: 3,
              right: 8,
            ),
            child: Row(
              children: [
                Icon(
                  isDir
                      ? (expanded ? Icons.folder_open : Icons.folder_outlined)
                      : _fileTreeIcon(name),
                  size: 14,
                  color: isDir ? const Color(0xFFC9A24A) : Colors.white38,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isDir ? Colors.white70 : Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      if (isDir && expanded) {
        widgets.addAll(_buildTreeNodes(child, depth + 1));
      }
    }
    return widgets;
  }

  /// Aktions-Badge-Texte und Farben fuer file_changed-Karten.
  (String, Color) _fileChangeActionStyle(String action) {
    switch (action) {
      case 'created':
        return ('Neu', const Color(0xFF7BAE7F));
      case 'deleted':
        return ('Gelöscht', const Color(0xFFD97B7B));
      case 'moved':
        return ('Verschoben', const Color(0xFF6E8FE0));
      default:
        return ('Geändert', const Color(0xFFC9A24A));
    }
  }

  /// Rendert die Datei-Aenderungen einer Assistant-Nachricht als aufklappbare
  /// Diff-Karten (Live-Diff).
  Widget _buildFileChanges(List<dynamic> events) {
    final changes = events
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .where((e) => e['type'] == 'file_changed')
        .toList();
    if (changes.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        for (final change in changes) _buildFileChangeCard(change),
      ],
    );
  }

  Widget _buildFileChangeCard(Map<String, dynamic> change) {
    final data = change['data'] is Map
        ? Map<String, dynamic>.from(change['data'] as Map)
        : <String, dynamic>{};
    final path = data['path']?.toString() ?? '';
    final action = data['action']?.toString() ?? 'modified';
    final destination = data['destination']?.toString();
    final diff = data['diff']?.toString() ?? '';
    final diffSkipped = data['diff_skipped'] == true;
    final (label, color) = _fileChangeActionStyle(action);
    return FileChangeCard(
      key: ValueKey('file-change-$path-$action-$destination'),
      path: path,
      actionLabel: label,
      actionColor: color,
      destination: destination,
      diff: diffSkipped ? '' : diff,
      diffSkipped: diffSkipped,
    );
  }

  Widget _buildPlanningApprovalPanel() {
    final planning = _pendingPlanningData ?? {};
    final summary = planning['plan_summary']?.toString() ?? 'Plan bereit';
    final steps = planning['steps'] is List
        ? List<dynamic>.from(planning['steps'])
        : <dynamic>[];
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFC9A24A).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFC9A24A).withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.fact_check_outlined,
                color: Color(0xFFDFC077),
                size: 16,
              ),
              SizedBox(width: 8),
              Text(
                'Planfreigabe',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            summary,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          if (steps.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...steps
                .take(4)
                .map(
                  (step) => Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      '- ${step.toString()}',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
          ],
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _isLoading
                    ? null
                    : () => setState(() => _showPlanningApproval = false),
                child: const Text('Ablehnen'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () => _sendMessage(approvePlan: true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC9A24A),
                ),
                child: const Text('Genehmigen'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Deutsche Kurzlabels fuer die Datei-Tools im Permission-Panel.
  Future<void> _respondPermission(String decision) async {
    final pending = _pendingPermission;
    if (pending == null) return;
    final requestId = pending['request_id']?.toString() ?? '';
    final sessionId = pending['session_id']?.toString() ?? (_sessionId ?? '');
    setState(() => _pendingPermission = null);
    final ok = await _api.respondPhiloBotPermission(
      sessionId: sessionId,
      requestId: requestId,
      decision: decision,
    );
    if (!ok && mounted) {
      // Dann hat das Backend die Anfrage bereits verworfen (Timeout/Ende)
      // und faehrt mit "abgelehnt" fort — nur als Hinweis zeigen.
      showTopNotification(
        context,
        'Zugriffsanfrage war nicht mehr offen',
        color: const Color(0xFFE06C75),
      );
    }
  }

  /// Laedt den Dateibaum des aktiven Projekts vom Backend.
  Future<void> _loadFileTree() async {
    final sessionId = _sessionId;
    if (sessionId == null || _fileTreeLoading) return;
    _fileTreeLoading = true;
    try {
      final result = await _api.getPhiloBotSessionTree(sessionId);
      if (!mounted || sessionId != _sessionId) return;
      final tree = result['tree'];
      setState(() {
        _fileTree = tree is Map ? Map<String, dynamic>.from(tree) : null;
      });
    } finally {
      _fileTreeLoading = false;
    }
  }

  /// Aktualisiert den Baum nach file_changed-Events, gebuendelt, damit eine
  /// Folge schneller Aenderungen nur einen Reload ausloest.
  void _scheduleFileTreeRefresh() {
    if (!_showFileTree) return;
    _fileTreeRefreshTimer?.cancel();
    _fileTreeRefreshTimer = Timer(
      const Duration(milliseconds: 500),
      _loadFileTree,
    );
  }

  /// Panel fuer die live-Zugriffsanfrage: der Agent will ausserhalb des
  /// Projektpfads arbeiten und wartet blockierend auf die Entscheidung.
  Widget _buildCreatedBotCard(Map<String, dynamic> bot) {
    final name = bot['name']?.toString() ?? 'Neuer Bot';
    final keywords = bot['keywords'];
    final keywordText = keywords is List
        ? keywords
              .map((e) => e.toString())
              .where((e) => e.isNotEmpty)
              .join(', ')
        : '';
    final themeColor = const Color(0xFFC9A24A);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: themeColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: themeColor.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle_outline, size: 14, color: themeColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '$name gespeichert',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (keywordText.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              keywordText,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              chatActionChip(
                enabled: !_isLoading,
                icon: Icons.play_arrow,
                label: 'Testen',
                onTap: () => _testCreatedBot(bot),
              ),
              chatActionChip(
                enabled: !_isLoading,
                icon: Icons.tune,
                label: 'Bearbeiten',
                onTap: () => _appState.setScreen('settings'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInlineMessageEditor(int index, String currentContent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _editMessageController,
          focusNode: _editMessageFocusNode,
          minLines: 1,
          maxLines: 8,
          textInputAction: TextInputAction.newline,
          onSubmitted: (_) => _submitEditedUserMessage(index, currentContent),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            height: 1.4,
          ),
          decoration: InputDecoration(
            isDense: true,
            hintText: 'Nachricht bearbeiten …',
            hintStyle: const TextStyle(color: Colors.white38),
            border: InputBorder.none,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: _cancelEditingUserMessage,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white54,
                minimumSize: const Size(0, 30),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: const Text('Abbrechen'),
            ),
            const SizedBox(width: 4),
            TextButton(
              onPressed: () => _submitEditedUserMessage(index, currentContent),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFEBD9A8),
                minimumSize: const Size(0, 30),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: const Text('Neu senden'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUserMessageNavigator() {
    final userIndexes = <int>[];
    for (var index = 0; index < _messages.length; index++) {
      if (_messages[index]['role'] == 'user') userIndexes.add(index);
    }
    return SizedBox(
      width: 34,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: userIndexes.map((index) {
            final isHighlighted =
                _editingMessageIndex == index ||
                _hoveredNavigatorMessageIndex == index;
            return Tooltip(
              message: 'Zu deiner Nachricht',
              child: MouseRegion(
                onEnter: (_) =>
                    setState(() => _hoveredNavigatorMessageIndex = index),
                onExit: (_) {
                  if (_hoveredNavigatorMessageIndex == index) {
                    setState(() => _hoveredNavigatorMessageIndex = null);
                  }
                },
                child: InkWell(
                  onTap: () => _jumpToUserMessage(index),
                  borderRadius: BorderRadius.circular(3),
                  child: SizedBox(
                    width: 26,
                    height: 10,
                    child: Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        curve: Curves.easeOut,
                        width: isHighlighted ? 22 : 15,
                        height: isHighlighted ? 3 : 2,
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFC9A24A,
                          ).withValues(alpha: isHighlighted ? 1 : 0.7),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMessageActions({
    required Map<String, dynamic> message,
    required int index,
    required bool isUser,
    required String content,
  }) {
    if (isUser) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          messageActionButton(
            enabled: !_isLoading,
            tooltip: 'Bearbeiten',
            icon: Icons.edit_outlined,
            onTap: () => _startEditingUserMessage(index, content),
          ),
          const SizedBox(width: 4),
          messageActionButton(
            enabled: !_isLoading,
            tooltip: 'Text kopieren',
            icon: Icons.copy_outlined,
            onTap: () => _copyAssistantMessage(content),
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        messageActionButton(
          enabled: !_isLoading,
          tooltip: 'Text kopieren',
          icon: Icons.copy_outlined,
          onTap: () => _copyAssistantMessage(content),
        ),
        const SizedBox(width: 4),
        _buildAssistantMessageMenu(message: message),
      ],
    );
  }

  Widget _buildAssistantMessageMenu({required Map<String, dynamic> message}) {
    return PopupMenuButton<String>(
      tooltip: 'Aktionen',
      enabled: !_isLoading,
      color: const Color(0xFF0F0F14),
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      onSelected: (value) {
        switch (value) {
          case 'shorter':
            _sendQuickPrompt('Formuliere die letzte Antwort deutlich kuerzer.');
            break;
          case 'critical':
            _sendQuickPrompt(
              'Pruefe die letzte Antwort kritischer und nenne Schwachstellen.',
            );
            break;
          case 'structure':
            _sendQuickPrompt(
              'Strukturiere die letzte Antwort klarer mit Abschnitten und naechsten Schritten.',
            );
            break;
          case 'tune':
            _sendQuickPrompt(
              'Botbuilder: Verfeinere den gerade erstellten Bot anhand meiner bisherigen Antworten.',
            );
            break;
          case 'rule':
            final botName = message['bot_name']?.toString() ?? 'diesen Bot';
            _sendQuickPrompt(
              'Botbuilder: Ueberarbeite $botName so, dass diese Antwortqualitaet dauerhaft als Bot-Regel uebernommen wird.',
            );
            break;
        }
      },
      itemBuilder: (context) {
        return [
          messageMenuItem('shorter', Icons.compress, 'Kuerzer'),
          messageMenuItem('critical', Icons.gavel, 'Kritischer'),
          messageMenuItem(
            'structure',
            Icons.format_list_bulleted,
            'Mehr Struktur',
          ),
          if (message['bot_id'] == 'botbuilder')
            messageMenuItem('tune', Icons.auto_fix_high, 'Feintunen')
          else
            messageMenuItem('rule', Icons.smart_toy_outlined, 'Als Regel'),
        ];
      },
      child: Container(
        width: 28,
        height: 24,
        decoration: BoxDecoration(
          color: const Color(0xFF0F0F14).withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: const _TwoDotMenuIcon(),
      ),
    );
  }

  Widget _buildFloatingInputBar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final hasText = _msgController.text.trim().isNotEmpty;
        final width = constraints.maxWidth;
        final isDesktop = width >= 900;
        final useBottomSheets = width < 600;
        final themeColor = const Color(0xFFC9A24A);
        final brightness = Theme.of(context).brightness;
        final composerBg = AppColors.surface(
          brightness,
        ).withValues(alpha: brightness == Brightness.dark ? 0.92 : 0.96);
        final composerBorder = AppColors.divider(brightness);
        final composerText = AppColors.textPrimary(brightness);
        final composerHint = AppColors.textSecondary(brightness);

        final thinkingOptions = [
          const ThinkingModeOption(
            value: 'none',
            label: 'Fast',
            icon: Icons.speed,
          ),
          const ThinkingModeOption(
            value: 'medium',
            label: 'Fast Thinking',
            icon: Icons.bolt,
          ),
          const ThinkingModeOption(
            value: 'max',
            label: 'Extra',
            icon: Icons.auto_awesome,
          ),
          const ThinkingModeOption(
            value: 'dual',
            label: 'Dual',
            icon: Icons.psychology,
            enabled: false,
          ),
          const ThinkingModeOption(
            value: 'agent',
            label: 'Agent',
            icon: Icons.smart_toy_outlined,
            enabled: false,
          ),
        ];

        return Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(
              left: 24,
              right: 24,
              bottom: 24,
              top: 8,
            ),
            child: DropTarget(
              onDragDone: (details) {
                if (details.files.isNotEmpty) {
                  setState(() {
                    for (var file in details.files) {
                      _uploadedFiles.add({
                        'name': file.name,
                        'path': file.path,
                      });
                    }
                  });
                }
              },
              onDragEntered: (details) {
                setState(() {
                  _isDragging = true;
                });
              },
              onDragExited: (details) {
                setState(() {
                  _isDragging = false;
                });
              },
              child: Container(
                constraints: BoxConstraints(
                  minWidth: isDesktop ? 420 : 310,
                  maxWidth: isDesktop
                      ? (width * 0.25 > 420 ? width * 0.25 : 420)
                      : (width * 0.95 > 500
                            ? 500
                            : (width * 0.95 > 310 ? width * 0.95 : 310)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: composerBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _isDragging ? themeColor : composerBorder,
                          width: _isDragging ? 1.5 : 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_uploadedFiles.isNotEmpty) ...[
                            Align(
                              alignment: Alignment.centerLeft,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: _uploadedFiles.map((file) {
                                    return FileChip(
                                      file: file,
                                      themeColor: themeColor,
                                      onDelete: () {
                                        setState(() {
                                          _uploadedFiles.remove(file);
                                        });
                                      },
                                      onOpen: (path) => _openFile(path),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ],
                          TextField(
                            focusNode: _inputFocusNode,
                            controller: _msgController,
                            enabled: !_interactionLocked,
                            style: TextStyle(color: composerText, fontSize: 13),
                            maxLines: 4,
                            minLines: 1,
                            decoration: InputDecoration(
                              hintText: 'Nachricht...',
                              hintStyle: TextStyle(
                                color: composerHint,
                                fontSize: 13,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                              contentPadding: EdgeInsets.zero,
                            ),
                            onChanged: (text) {
                              setState(() {});
                            },
                            onSubmitted: (_) => _sendMessage(),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CompositedTransformTarget(
                                      link: _plusMenuLink,
                                      child: IconButton(
                                        key: const Key('chat-add-button'),
                                        tooltip: 'Datei oder Chat-Aktion',
                                        onPressed: _interactionLocked
                                            ? null
                                            : _togglePlusMenu,
                                        constraints: const BoxConstraints(
                                          minWidth: 44,
                                          minHeight: 44,
                                        ),
                                        icon: Icon(
                                          Icons.add,
                                          color: composerHint,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: ChatModelPicker(
                                        selected: _selectedChatModel,
                                        choices: _chatModelChoices,
                                        loadingLocalModels:
                                            _isLoadingLocalModels,
                                        localModelsError: _localModelsError,
                                        enabled:
                                            !_interactionLocked &&
                                            !_modelPickerLocked,
                                        disabledReason: _modelPickerLocked
                                            ? 'Das Modell ist fest mit dem ausgewählten Bot verbunden'
                                            : _warmup.isActive
                                            ? 'Das Modell läuft gerade warm'
                                            : null,
                                        useBottomSheet: useBottomSheets,
                                        onSelected: _selectChatModel,
                                        onRefreshLocalModels:
                                            _refreshChatModels,
                                        onOpenEngine: () =>
                                            _appState.setScreen('engine'),
                                        onManageCloudModels:
                                            _showModelManagementDialog,
                                      ),
                                    ),
                                    if (_webSearchEnabled) ...[
                                      const SizedBox(width: 6),
                                      ChatBadge(
                                        icon: Icons.language,
                                        label: 'Web',
                                        themeColor: const Color(0xFFC9A24A),
                                        onTap: () => setState(
                                          () => _webSearchEnabled = false,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              ThinkingModeSliderButton(
                                value: _thinkingLevel,
                                options: thinkingOptions,
                                themeColor: themeColor,
                                onChanged: (val) {
                                  setState(() {
                                    _thinkingLevel = val;
                                  });
                                },
                              ),
                              const SizedBox(width: 8),
                              HoverIconButton(
                                icon: Icons.mic_none,
                                tooltip: 'Sprachnachricht',
                                onPressed: () {},
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                key: const Key('chat-send-button'),
                                tooltip: _sessionId == null
                                    ? 'Bitte zuerst ein Modell auswählen'
                                    : _isLoading
                                    ? 'PhiloBot arbeitet noch …'
                                    : _warmup.isActive
                                    ? 'Warten, bis das Modell bereit ist'
                                    : 'Nachricht senden',
                                onPressed:
                                    _interactionLocked ||
                                        _sessionId == null ||
                                        !hasText
                                    ? null
                                    : () => _sendMessage(),
                                constraints: const BoxConstraints(
                                  minWidth: 44,
                                  minHeight: 44,
                                ),
                                style: IconButton.styleFrom(
                                  backgroundColor: hasText
                                      ? themeColor
                                      : composerHint.withValues(alpha: 0.15),
                                  disabledBackgroundColor: composerHint
                                      .withValues(alpha: 0.15),
                                ),
                                // Waehrend eine Antwort noch laeuft (oder das
                                // Modell warmup macht), ersetzt ein Loading-
                                // Kreis den Pfeil: der gesperrte Button allein
                                // (gleiches Grau wie bei leerem Textfeld) war
                                // nicht eindeutig genug als "KI arbeitet noch"
                                // zu erkennen — sah wie ein normaler inaktiver
                                // Button aus, nicht wie eine laufende Anfrage.
                                icon: _interactionLocked
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white70,
                                        ),
                                      )
                                    : AnimatedRotation(
                                        turns: hasText ? 0.25 : 0.0,
                                        duration: const Duration(
                                          milliseconds: 220,
                                        ),
                                        curve: Curves.easeOut,
                                        child: Icon(
                                          Icons.arrow_upward,
                                          color: hasText
                                              ? Colors.white
                                              : composerHint,
                                          size: 18,
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
