import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/design_tokens.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_markdown_latex/flutter_markdown_latex.dart';
import 'package:markdown/markdown.dart' as md;
import '../../core/api_service.dart';
import '../../core/app_state.dart';
import '../engine/models.dart';
import './chat_tabs_strings.dart';
import './chat_aux_strings.dart' show tr;
import '../../core/app_theme.dart';
import '../../core/top_notification.dart';
import './chat_history_panel.dart';
import './chat_markdown_helpers.dart';
import './chat_model_picker.dart';
import './context_meter.dart';
import './output_levels.dart';
import '../spark/file_change_card.dart';
import './interactive_code_block.dart';
import './reasoning_dropdown.dart';
import './chat_widgets.dart';
import './model_management_dialog.dart';
import './model_warmup.dart';
import './chat_action_widgets.dart';
import './thinking_levels.dart';
import '../spark/permission_panel.dart';
import '../spark/plan_checklist.dart';

class ScoutTab extends StatefulWidget {
  const ScoutTab({
    super.key,
    this.api,
    this.appState,
    this.sessionId,
    this.isActivePane = true,
    this.onPaneFocused,
    this.onSessionCreated,
    this.onClosePane,
    this.headerAction,
  });

  final ApiService? api;
  final AppState? appState;

  /// Pins this instance to one session when it is rendered inside the
  /// multi-chat workspace. Leaving it null preserves the historic
  /// single-chat behaviour, which follows [AppState.currentChatSessionId].
  final String? sessionId;

  /// Only the focused pane may handle global chat actions or publish the
  /// sidebar model picker, which is intentionally a single shared control.
  final bool isActivePane;
  final VoidCallback? onPaneFocused;
  final ValueChanged<String>? onSessionCreated;
  final VoidCallback? onClosePane;

  /// Optional workspace control rendered in the existing chat title bar.
  /// This keeps the classic single-chat surface free of an extra header.
  final Widget? headerAction;

  @override
  State<ScoutTab> createState() => _ScoutTabState();
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

class _ScoutTabState extends State<ScoutTab> {
  late final ApiService _api;
  late final AppState _appState;

  final FocusNode _inputFocusNode = FocusNode();
  StreamSubscription<String>? _actionSubscription;
  StreamIterator<ScoutStreamEvent>? _activeMessageStream;
  int _chatRequestGeneration = 0;

  String? _sessionId;
  final List<Map<String, dynamic>> _messages = [];
  final _msgController = TextEditingController();
  final _editMessageController = TextEditingController();
  final _editMessageFocusNode = FocusNode();

  final _allowedRootsController = TextEditingController();
  final _scrollController = ScrollController();
  final StringBuffer _pendingAssistantDelta = StringBuffer();
  Timer? _streamRenderTimer;
  bool _scrollFrameScheduled = false;
  bool _isLoading = false;

  DateTime? _pendingSince;
  Timer? _pendingTicker;
  bool _isInitializingChat = true;
  String _thinkingLevel = 'medium';
  // Spark is a mode, not a level: it decides that the agent loop answers,
  // while [_thinkingLevel] still decides how hard it thinks. It holds its own
  // flag instead of occupying a slot in the level that every model-change
  // check then had to step around.
  // How long an answer may get. Persists across turns in this pane, because it
  // is a preference about the model, not a decision about one message.
  String _outputLevel = OutputLevels.normal;
  bool _sparkEnabled = false;
  bool _webSearchEnabled = false;

  bool _planningEnabled = false;
  final String _agenticMode = 'execute';
  bool _showPlanningApproval = false;
  Map<String, dynamic>? _pendingPlanningData;
  // The approved plan while it is being worked off: every step with its own
  // status, filled from plan_started and ticked over by the per-step events.
  List<Map<String, dynamic>> _planSteps = const [];
  String _planSummary = '';
  bool _planRunning = false;
  String? _pendingAgenticMessage;

  Map<String, dynamic>? _pendingPermission;

  bool _showFileTree = false;
  Map<String, dynamic>? _fileTree;
  bool _fileTreeLoading = false;
  Timer? _fileTreeRefreshTimer;
  final Set<String> _expandedTreePaths = {'.'};
  List<ChatModelChoice> _chatModelChoices = const [];
  ChatModelChoice? _selectedChatModel;
  List<EngineInstance> _engineInstances = const [];
  List<ScoutChoice> _botChoices = const [];
  List<ReasoningProfile> _reasoningProfiles = [];
  // How full this chat's context window is. The backend measures it, both when
  // the history is loaded and again around every turn, so the ring on the
  // composer never has to guess from what this pane happens to hold.
  ContextUsage _contextUsage = ContextUsage.unknown;
  String? _selectedBotId;
  String? _responseBotId;
  final ModelWarmupProgress _warmup = ModelWarmupProgress();
  StreamSubscription<EngineStreamEvent>? _engineWarmupSubscription;
  ChatModelChoice? _pendingWarmupChoice;
  String? _pendingWarmupMessage;
  bool _warmupCancelled = false;
  bool _warmupFailureAnnounced = false;
  bool _isLoadingLocalModels = true;
  String? _localModelsError;
  bool _isDragging = false;
  int? _hoveredMessageIndex;
  int? _hoveredNavigatorMessageIndex;
  int? _editingMessageIndex;
  final Map<int, GlobalKey> _messageKeys = {};
  final List<Map<String, String>> _uploadedFiles = [];

  bool get _hasPinnedSession => widget.sessionId != null;

  Key _paneKey(String base) =>
      _hasPinnedSession ? Key('$base-${widget.sessionId}') : Key(base);

  ScoutChoice? get _selectedBot {
    for (final bot in _botChoices) {
      if (bot.id == _selectedBotId) return bot;
    }
    return null;
  }

  ScoutChoice? get _warmupBot {
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
            connectionId: choice.connectionId,
            instanceId: choice.instanceId,
            label: choice.label,
            subtitle: chatTabsText('scout.localReady'),
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
    final themeColor = CulpeoColors.metric;
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

    _pendingTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  void _endPending() {
    _pendingTicker?.cancel();
    _pendingTicker = null;
    _pendingSince = null;
  }

  /// The gap between sending and the first word of the answer.
  ///
  /// The phase reads as a shimmer rather than as a spinner with counting dots:
  /// the light crossing the words is the same signal the composer's outline is
  /// showing at that moment, so the two say one thing. The spinner stays for a
  /// warm-up, because that one has a real reading behind it - a percentage that
  /// climbs - and a shimmer would hide that something is being measured.
  Widget _buildWorkingIndicator() {
    final elapsed = _pendingSince == null
        ? 0
        : DateTime.now().difference(_pendingSince!).inSeconds;
    String phase;
    if (_warmup.isActive) {
      final pct = (_warmup.displayProgress * 100).clamp(0, 100).round();
      final base = _warmup.message.isNotEmpty
          ? _warmup.message
          : chatTabsText('scout.loadingModel');
      phase = pct > 0 ? '$base · $pct %' : base;
    } else {
      phase = chatTabsText('scout.thinking');
    }
    final elapsedLabel = elapsed >= 2 ? '  ·  ${elapsed}s' : '';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_warmup.isActive) ...[
          const SizedBox(
            width: 13,
            height: 13,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: CulpeoColors.metric,
            ),
          ),
          const SizedBox(width: 10),
        ],
        Flexible(
          child: ShimmerLabel(
            text: '$phase$elapsedLabel',
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

  Widget _buildStreamingText(String text) {
    return Text(
      text,
      style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
    );
  }

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
              color: CulpeoColors.metricBright,
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

  Widget _buildChatHistoryBar() {
    final currentId = _sessionId ?? _appState.currentChatSessionId;
    final currentTitle = currentId == null
        ? chatTabsText('scout.noActiveChat')
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
              key: _paneKey('file-tree-toggle'),
              tooltip: chatTabsText('scout.showFileTree'),
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
                color: _showFileTree ? CulpeoColors.metric : Colors.white38,
              ),
            ),
          if (widget.headerAction != null) widget.headerAction!,
          if (widget.onClosePane != null)
            IconButton(
              key: _paneKey('chat-pane-close'),
              tooltip: chatTabsText('scout.multiChat.close'),
              splashRadius: 16,
              onPressed: widget.onClosePane,
              icon: const Icon(
                Icons.close_rounded,
                size: 17,
                color: Colors.white54,
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          chatTabsText('common.webSearch'),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 1),
                        Text(
                          chatTabsText('common.realtimeInformation'),
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

          // Spark always plans, so with Spark on the row reports that instead
          // of offering a choice: turning planning off here would not turn it
          // off for the agent.
          InkWell(
            key: _paneKey('chat-planning-toggle'),
            onTap: _sparkEnabled
                ? null
                : () {
                    setState(() {
                      _planningEnabled = !_planningEnabled;
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
                    Icons.fact_check_outlined,
                    color: _planningEnabled || _sparkEnabled
                        ? themeColor
                        : Colors.white70,
                    size: 14,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          chatTabsText('common.planningMode'),
                          style: TextStyle(
                            color: _sparkEnabled
                                ? Colors.white70
                                : Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          _sparkEnabled
                              ? chatTabsText('common.planningModeWithSpark')
                              : chatTabsText('common.planningModeHint'),
                          style: const TextStyle(
                            color: Colors.white30,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _sparkEnabled
                        ? Icons.lock_outline
                        : _planningEnabled
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: _planningEnabled || _sparkEnabled
                        ? themeColor
                        : Colors.white24,
                    size: 14,
                  ),
                ],
              ),
            ),
          ),

          // How long the answer may get. Not a toggle like the two above, so it
          // carries the same segmented pill the thinking modes use rather than
          // a checkmark - and it lives here instead of on the composer row,
          // which has no width left and is for per-turn decisions anyway.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                Icon(
                  OutputLevels.iconDataFor(_outputLevel),
                  color: Colors.white70,
                  size: 14,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('chatAux.output.title'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        OutputLevels.hintFor(_outputLevel),
                        style: const TextStyle(
                          color: Colors.white30,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                ThinkingModeSliderButton(
                  key: _paneKey('chat-output-level'),
                  value: _outputLevel,
                  options: [
                    for (final level in OutputLevels.all)
                      ThinkingModeOption(
                        value: level,
                        label: OutputLevels.labelFor(level),
                        icon: OutputLevels.iconDataFor(level),
                      ),
                  ],
                  themeColor: CulpeoColors.action,
                  onChanged: (level) {
                    setState(() => _outputLevel = level);
                    _plusMenuEntry?.markNeedsBuild();
                  },
                ),
              ],
            ),
          ),

          InkWell(
            onTap: _pickFile,
            borderRadius: BorderRadius.circular(8),
            hoverColor: themeColor.withValues(alpha: 0.09),
            splashColor: themeColor.withValues(alpha: 0.12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  Icon(Icons.attach_file, color: Colors.white70, size: 14),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          chatTabsText('common.uploadFile'),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 1),
                        Text(
                          chatTabsText('common.chooseLocalFile'),
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
    // The progress bar ticks on its own timer, outside any setState here,
    // so the sidebar mirror needs its own listener to stay live.
    _warmup.addListener(_syncModelPickerToAppState);
    _warmup.addListener(_announceWarmupFailure);
    _actionSubscription = _appState.actionStream.listen((action) {
      if (!mounted) return;
      if (action == 'focus_chat_input' && widget.isActivePane) {
        _inputFocusNode.requestFocus();
      } else if (action.startsWith('new_chat_session') && widget.isActivePane) {
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
        final pinnedSessionId = widget.sessionId;
        if (pinnedSessionId != null) {
          _sessionId = pinnedSessionId;
          await _fetchHistory();
        } else if (_appState.currentChatSessionId == null) {
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

  @override
  void didUpdateWidget(covariant ScoutTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActivePane && !oldWidget.isActivePane) {
      // Equality for the sidebar snapshot deliberately excludes its callback
      // fields, so two panes using the same visible model could otherwise
      // look equal here. Force a fresh publication when focus changes: the
      // callback must always control the newly focused session, not the pane
      // that happened to publish an identical snapshot before it.
      _lastPublishedModelPicker = null;
      // AppState notifies its listeners. During didUpdateWidget the
      // workspace is still building, so publishing synchronously would ask
      // ancestors to rebuild mid-frame. The active pane has settled by the
      // next frame and its callback can then be safely mirrored.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !widget.isActivePane) return;
        _lastPublishedModelPicker = null;
        _syncModelPickerToAppState();
      });
    }
    if (widget.sessionId == oldWidget.sessionId) return;

    final nextSessionId = widget.sessionId;
    _invalidateActiveMessageStream();
    setState(() {
      _sessionId = nextSessionId;
      _messages.clear();
      _contextUsage = ContextUsage.unknown;
      _isLoading = false;
    });
    if (nextSessionId != null) unawaited(_fetchHistory());
  }

  ChatModelPickerState? _lastPublishedModelPicker;

  /// Mirrors the fields the sidebar's model panel needs into [AppState].
  /// Runs after every [setState] (see the override below) and whenever
  /// [_warmup] ticks on its own timer. [ChatModelPickerState]'s equality
  /// only covers what the sidebar actually renders, so a keystroke in the
  /// composer computes an equal snapshot and never reaches
  /// [AppState.notifyListeners] - only a real change to the model list,
  /// selection, or warmup does.
  void _syncModelPickerToAppState() {
    if (!mounted || !widget.isActivePane) return;
    final next = ChatModelPickerState(
      entries: [
        for (final choice in _chatModelChoices)
          ChatModelPickerEntry(
            stableKey: choice.stableKey,
            label: choice.label,
            subtitle: choice.subtitle,
            isLocal: choice.isLocal,
            selectable: choice.selectable,
            ready: choice.isReady,
            placementLabel: choice.placementLabel,
          ),
      ],
      selectedKey: _selectedChatModel?.stableKey,
      loading: _isLoadingLocalModels,
      error: _localModelsError,
      locked: _modelPickerLocked,
      lockedReason: _modelPickerLocked
          ? chatTabsText('scout.modelBoundToBot')
          : null,
      warmupActive: _warmup.isActive,
      warmupProgress: _warmup.displayProgress,
      warmupMessage: _warmup.isActive ? _warmup.message : '',
      onSelect: _selectChatModelByKey,
      onRefresh: _refreshChatModels,
      onOpenEngine: () => _appState.setScreen('engine'),
      onManageCloudModels: _showModelManagementDialog,
      onCancelWarmup: _cancelModelWarmup,
    );
    if (next == _lastPublishedModelPicker) return;
    _lastPublishedModelPicker = next;
    _appState.publishChatModelPicker(next);
  }

  Future<void> _selectChatModelByKey(String stableKey) async {
    for (final choice in _chatModelChoices) {
      if (choice.stableKey == stableKey) {
        await _selectChatModel(choice);
        return;
      }
    }
  }

  @override
  void setState(VoidCallback fn) {
    super.setState(fn);
    if (widget.isActivePane) _syncModelPickerToAppState();
  }

  void _onAppStateChanged() {
    if (!mounted) return;
    if (_hasPinnedSession) {
      // This pane has its own immutable session binding. AppState still
      // supplies titles, projects and model metadata, but its global focused
      // session must not replace this pane or cancel its stream.
      setState(() {});
      return;
    }
    final nextSessionId = _appState.currentChatSessionId;
    if (nextSessionId != _sessionId) {
      _invalidateActiveMessageStream();
      setState(() {
        _sessionId = nextSessionId;
        _messages.clear();
        _contextUsage = ContextUsage.unknown;
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
    StreamIterator<ScoutStreamEvent> stream,
  ) async {
    try {
      await stream.cancel();
    } catch (_) {}
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
      _appState.refreshScouts(),
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
    final bots = _appState.scouts
        .whereType<Map>()
        .map((bot) => ScoutChoice.fromJson(Map<String, dynamic>.from(bot)))
        .where((bot) => bot.id.isNotEmpty)
        .toList();

    List<ReasoningProfile> profiles = [];
    try {
      final res = await _api.scout.listReasoningProfiles();
      if (res['profiles'] != null) {
        profiles = (res['profiles'] as List)
            .map((p) => ReasoningProfile.fromMap(Map<String, dynamic>.from(p)))
            .toList();
      }
    } catch (_) {}

    if (!mounted) return;
    final previousKey = _selectedChatModel?.stableKey;
    ChatModelChoice? nextSelection;
    for (final choice in choices) {
      if (choice.stableKey == previousKey) {
        nextSelection = choice;
        break;
      }
    }
    // The model the user picked stays picked even once it drops out of the
    // list - a local model whose node went offline, an engine that is not
    // ready yet. Falling through to [choices.first] instead would silently
    // move the chat onto a paid cloud provider, and the next failure would
    // then name that provider rather than the model the user actually chose.
    if (nextSelection == null && _selectedChatModel != null) {
      final previous = _selectedChatModel!;
      nextSelection = previous.isLocal
          ? ChatModelChoice.unavailableSession(
              modelRef: previous.modelRef,
              provider: previous.provider,
              modelId: previous.modelId,
              instanceId: previous.instanceId,
              connectionId: previous.connectionId,
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
      _engineInstances = instances;
      _botChoices = bots;
      _selectedBotId = selectedBot?.id;
      _reasoningProfiles = profiles;
      _isLoadingLocalModels = false;
      _localModelsError = engineError;
      if (nextSelection != null) {
        _selectedChatModel = nextSelection;
        final validOptions = ThinkingLevels.optionsFor(
          profiles,
          nextSelection.modelId,
        );
        if (!validOptions.contains(_thinkingLevel) &&
            _thinkingLevel != 'dual') {
          _thinkingLevel = ThinkingLevels.defaultLevelFor(
            profiles,
            nextSelection.modelId,
          );
        }
      }
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

    if (_sessionId != null) {
      final switched = await _switchSessionModel(target);
      if (switched && mounted) {
        setState(() {
          _selectedChatModel = target;
          final validOptions = ThinkingLevels.optionsFor(
            _reasoningProfiles,
            target.modelId,
          );
          if (!validOptions.contains(_thinkingLevel) &&
              _thinkingLevel != 'dual') {
            _thinkingLevel = ThinkingLevels.defaultLevelFor(
              _reasoningProfiles,
              target.modelId,
            );
          }
        });
        if (!target.isLocal) {
          _appState.setSelectedModelId(target.modelRef);
        }
        showTopNotification(
          context,
          chatTabsText('scout.modelSwitched', {'model': target.label}),
        );
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

  Future<bool> _switchSessionModel(ChatModelChoice target) async {
    final sessionId = _sessionId;
    if (sessionId == null) return false;
    final result = await _api.scout.setSessionModel(
      sessionId,
      provider: target.provider,
      modelId: target.isLocal
          ? (target.instanceId ?? target.modelId)
          : target.modelId,
      modelRef: target.modelRef,
      displayName: target.label,
      connectionId: target.connectionId,
    );
    if (result['status'] == 'ok') return true;
    if (mounted) {
      _showChatError(
        result['error']?.toString() ?? chatTabsText('scout.modelSwitchFailed'),
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
          chatTabsText('scout.startModelFirst'),
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
      connectionId: target.connectionId,
    );
    if (mounted) {
      setState(() {
        // A pane inside [ChatWorkspace] remains bound to its existing
        // session. Starting a new chat from the focused pane hands the new
        // session to the workspace instead of silently replacing this pane's
        // transcript and stream state.
        if (sId != null && !_hasPinnedSession) {
          _sessionId = sId;
          _selectedChatModel = target;
          final validOptions = ThinkingLevels.optionsFor(
            _reasoningProfiles,
            target.modelId,
          );
          if (!validOptions.contains(_thinkingLevel) &&
              _thinkingLevel != 'dual') {
            _thinkingLevel = ThinkingLevels.defaultLevelFor(
              _reasoningProfiles,
              target.modelId,
            );
          }
          _messages.clear();
          _contextUsage = ContextUsage.unknown;
        } else if (sId != null) {
          _selectedChatModel = target;
          final validOptions = ThinkingLevels.optionsFor(
            _reasoningProfiles,
            target.modelId,
          );
          if (!validOptions.contains(_thinkingLevel) &&
              _thinkingLevel != 'dual') {
            _thinkingLevel = ThinkingLevels.defaultLevelFor(
              _reasoningProfiles,
              target.modelId,
            );
          }
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
        _appState.lastChatError ?? chatTabsText('scout.startSessionFailed'),
      );
      return false;
    }
    if (sId != null) widget.onSessionCreated?.call(sId);
    if (announce && mounted) {
      showTopNotification(
        context,
        chatTabsText('scout.newChatStarted', {'model': target.label}),
      );
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
        message: chatTabsText('scout.localModelUnavailable'),
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
          } catch (_) {}
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
        _warmup.complete(message: chatTabsText('scout.modelReady'));
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
          } catch (_) {}
        }
        try {
          final instance = await _api.getEngineInstance(instanceId);
          _applyWarmupInstance(instance);
        } catch (_) {}
        lastRelevantEvent = DateTime.now();
        if (mounted) setState(() {});
      }
      _warmup.fail(
        message: chatTabsText('scout.modelStartTimedOut'),
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
        message: chatTabsText('scout.localModelStartFailed', {
          'error': error.toString(),
        }),
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
      _sessionId = _hasPinnedSession ? widget.sessionId : null;
      _selectedBotId = null;
      _responseBotId = null;
      _selectedChatModel = null;
      _pendingWarmupChoice = null;
      _pendingWarmupMessage = null;
      _warmup.reset();
    });
    if (_hasPinnedSession) {
      _appState.selectChatSession(widget.sessionId!);
    } else {
      _appState.clearCurrentChatSessionSelection();
    }
    showTopNotification(context, chatTabsText('scout.chooseAnotherModel'));
  }

  /// Announces a failed model start where every other message appears.
  ///
  /// Listening on [_warmup] rather than announcing at each `fail()` call site
  /// keeps the one notification per failure no matter which of them - warm-up,
  /// send, retry - reported it. The flag resets as soon as the warm-up leaves
  /// the failed state, so the next attempt is announced again.
  void _announceWarmupFailure() {
    if (!_warmup.hasFailed) {
      _warmupFailureAnnounced = false;
      return;
    }
    if (_warmupFailureAnnounced) return;
    _warmupFailureAnnounced = true;

    final message = _warmup.message.trim().isEmpty
        ? tr('chatAux.warmup.startFailed')
        : _warmup.message.trim();
    final canChangeBinding = _warmupBot?.modelBinding != null;

    // fail() can land inside a build or a stream callback, and an overlay
    // cannot be inserted while a frame is being built.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_warmup.hasFailed) return;
      showTopNotification(
        context,
        message,
        color: Colors.redAccent,
        duration: const Duration(seconds: 9),
        actions: [
          TopNotificationAction(
            label: tr('common.retry'),
            onPressed: _retryModelWarmup,
            primary: true,
          ),
          TopNotificationAction(
            label: tr('chatAux.warmup.chooseAnother'),
            onPressed: _chooseAnotherModel,
          ),
          if (canChangeBinding)
            TopNotificationAction(
              label: tr('chatAux.warmup.changeBinding'),
              onPressed: () => _appState.setScreen('bot_management'),
            ),
        ],
      );
    });
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
      actionLabel: needsSettingsShortcut
          ? chatTabsText('scout.settings')
          : null,
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
    final res = await _api.scout.getHistory(requestedSessionId);
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
      final rawUsage = res['context_usage'];
      setState(() {
        _contextUsage = rawUsage is Map
            ? ContextUsage.fromMap(Map<String, dynamic>.from(rawUsage))
            : ContextUsage.unknown;
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
    setState(() {});

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
      // An approval keeps the list it just approved on screen until
      // plan_started replaces it; a fresh message ends the old run.
      if (approvePlan == null) {
        _planSteps = const [];
        _planSummary = '';
        _planRunning = false;
      }
    });
    _beginPending();
    _scrollToBottom();

    final streamIterator = StreamIterator<ScoutStreamEvent>(
      _api.scout.streamMessage(
        requestSessionId,
        text,
        thinkingLevel: _sparkEnabled
            ? 'spark'
            : _thinkingLevel == 'dual'
            ? 'dual'
            : ThinkingLevels.legacyTierFor(_thinkingLevel),
        // Spark no longer swallows the level: the backend hands the effort
        // to every provider turn the agent loop takes, so a Spark run thinks
        // as hard as the bar says.
        reasoningEffort: _thinkingLevel == 'dual' ? null : _thinkingLevel,
        outputLevel: _outputLevel,
        editMessageIndex: editIndex,
        mode: _sparkEnabled ? _agenticMode : null,
        allowedRoots: _sparkEnabled ? _allowedRoots() : null,
        approvePlan: approvePlan,

        // Spark plans by default: an agent that may touch files should say
        // what it intends to do before it does it, so the toggle only decides
        // planning for plain chat turns.
        planning: approvePlan == true
            ? null
            : ((_planningEnabled || _sparkEnabled) ? true : null),
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
              modelName: label ?? chatTabsText('scout.localModel'),
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
          ScoutChoice? eventBot;
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
          await _appState.refreshScouts();
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
              chatTabsText('scout.botSavedInManagement', {'name': botName}),
              color: Colors.green,
            );
          }
        } else if (event.type == 'context_compacted') {
          // Spark shortened its own tool results to stay inside the window.
          // A different thing from folding the chat history, so it says so.
          if (mounted) {
            showTopNotification(
              context,
              chatTabsText('scout.toolResultsShortened'),
            );
          }
        } else if (event.type == 'context_usage') {
          final usage = ContextUsage.fromMap(event.data);
          if (usage != _contextUsage) {
            setState(() => _contextUsage = usage);
          }
          if (usage.compacted && mounted) {
            showTopNotification(
              context,
              chatTabsText('scout.contextCompacted'),
            );
          }
        } else if (event.type == 'session_title') {
          // The backend names a fresh chat from its first exchange, after the
          // answer. It arrives once per session, so the sidebar entry renames
          // itself instead of carrying the opening message until a restart.
          final title = event.data['title']?.toString() ?? '';
          final titledSession =
              event.data['session_id']?.toString() ?? requestSessionId;
          if (title.isNotEmpty) {
            _appState.applyGeneratedSessionTitle(titledSession, title);
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
            event.type == 'plan_started' ||
            event.type == 'plan_step_start' ||
            event.type == 'plan_step_result' ||
            event.type == 'plan_finished' ||
            event.type == 'plan_skipped' ||
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
              chatTabsText('scout.responseFailed');
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
                modelName:
                    _selectedChatModel?.label ??
                    chatTabsText('scout.localModel'),
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
            // The list stays up so the user can see how far the run got, but
            // nothing is running any more.
            _planRunning = false;
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
          setState(() {
            _isLoading = false;
            _planRunning = false;
          });
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
        _planRunning = false;
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

  void _handleAgenticSSEEvent(ScoutStreamEvent event) {
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
      if (event.type == 'plan_started') {
        // The approval is spent the moment the run starts; from here the list
        // itself is the status display.
        _showPlanningApproval = false;
        _planSummary = _planningSummaryOf(event.data);
        _planSteps = _planStepsOf(event.data);
        _planRunning = _planSteps.isNotEmpty;
      } else if (event.type == 'plan_step_start' ||
          event.type == 'plan_step_result') {
        _applyPlanStepEvent(event);
      } else if (event.type == 'plan_finished') {
        final steps = _planStepsOf(event.data);
        if (steps.isNotEmpty) _planSteps = steps;
        _planRunning = false;
        // A worklist with every point green has nothing left to report: it
        // makes room for the answer instead of parking on the composer. Only a
        // run with something still open stays, because that one can be picked
        // up again.
        if (_planSteps.every((step) => step['status'] == 'done')) {
          _planSteps = const [];
          _planSummary = '';
        }
      } else if (event.type == 'plan_skipped') {
        _planSteps = const [];
        _planSummary = '';
        _planRunning = false;
      }
      if (event.type == 'permission_request') {
        _pendingPermission = Map<String, dynamic>.from(event.data);
      } else if (event.type == 'permission_result') {
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
      showTopNotification(context, chatTabsText('scout.memoryCompressed'));
    }
    _scrollToBottom();
  }

  Map<String, dynamic> _planningPayloadOf(Map<String, dynamic> data) {
    final planning = data['planning'];
    return planning is Map
        ? Map<String, dynamic>.from(planning)
        : <String, dynamic>{};
  }

  String _planningSummaryOf(Map<String, dynamic> data) {
    return _planningPayloadOf(data)['plan_summary']?.toString() ?? '';
  }

  List<Map<String, dynamic>> _planStepsOf(Map<String, dynamic> data) {
    final raw = _planningPayloadOf(data)['plan_steps'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((step) => Map<String, dynamic>.from(step))
        .toList();
  }

  /// Moves one row of the worklist. The step events carry their own number
  /// rather than an index, and a run that somehow started without its list
  /// still gets one built here - the checklist is worth more than the
  /// guarantee that it was announced first.
  void _applyPlanStepEvent(ScoutStreamEvent event) {
    final number = (event.data['step'] as num?)?.toInt() ?? 0;
    if (number <= 0) return;
    final total = (event.data['total'] as num?)?.toInt() ?? 0;
    final title = event.data['title']?.toString() ?? '';
    final result = event.data['result']?.toString() ?? '';
    final status =
        event.data['status']?.toString() ??
        (event.type == 'plan_step_start' ? 'running' : 'done');

    final steps = List<Map<String, dynamic>>.from(_planSteps);
    while (steps.length < (total > number ? total : number)) {
      steps.add({'number': steps.length + 1, 'title': '', 'status': 'pending'});
    }

    final index = steps.indexWhere(
      (step) => (step['number'] as num?)?.toInt() == number,
    );
    if (index < 0) return;

    final step = Map<String, dynamic>.from(steps[index]);
    step['status'] = status;
    if (title.isNotEmpty) step['title'] = title;
    if (result.isNotEmpty) step['result'] = result;
    steps[index] = step;

    _planSteps = steps;
    _planRunning = true;
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
    showTopNotification(context, chatTabsText('scout.responseCopied'));
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
        themeColor: CulpeoColors.metric,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializingChat) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: CulpeoColors.metric,
              ),
            ),
            SizedBox(height: 14),
            Text(
              chatTabsText('scout.chatPreparing'),
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
            valueColor: AlwaysStoppedAnimation<Color>(CulpeoColors.metric),
          ),

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
                                  ? chatTabsText('scout.initializingNewChat')
                                  : _chatModelChoices.isEmpty
                                  ? chatTabsText('scout.noModelReady')
                                  : chatTabsText('scout.noActiveChat'),
                              style: const TextStyle(
                                color: Colors.white30,
                                fontSize: 13,
                              ),
                            ),
                            if (!_isLoading && _chatModelChoices.isEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                chatTabsText('scout.startModelToBegin'),
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
                                    label: Text(
                                      chatTabsText('scout.startLocalModel'),
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: _showModelManagementDialog,
                                    icon: const Icon(
                                      Icons.cloud_outlined,
                                      size: 15,
                                    ),
                                    label: Text(
                                      chatTabsText('scout.selectApiModel'),
                                    ),
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
                                                  ? CulpeoColors.metric
                                                        .withValues(alpha: 0.08)
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
                                                    ? CulpeoColors.metric
                                                          .withValues(
                                                            alpha: 0.2,
                                                          )
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
                                                        m['bot_id'] == 'scout'
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
                                                          color: CulpeoColors
                                                              .metricBright,
                                                        ),
                                                    builders: {
                                                      if (shouldUseInputCheckboxBuilder(
                                                        markdownContent,
                                                      ))
                                                        'input':
                                                            TaskCheckboxElementBuilder(
                                                              accentColor:
                                                                  CulpeoColors
                                                                      .metricBright,
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
                                                        color: CulpeoColors
                                                            .metricBright,
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
        ModelWarmupPanel(progress: _warmup, onCancel: _cancelModelWarmup),

        _buildFloatingInputBar(),
        const SizedBox(height: 10),
      ],
    );
  }

  /// Counters arrive as JSON numbers, so they reach here as doubles and would
  /// otherwise read "3.0 Schritte".
  String _countOf(dynamic value) {
    return ((value as num?)?.toInt() ?? 0).toString();
  }

  Widget _buildAgenticEvents(List<dynamic> events) {
    // The last eight, not the first: a planned run reports a step at a time,
    // and what happened most recently is what tells the user where it stands.
    final visible = events.length > 8
        ? events.sublist(events.length - 8)
        : events.toList();
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
            toolName.isEmpty
                ? chatTabsText('scout.agentEvent.toolStartedDefault')
                : chatTabsText('scout.agentEvent.toolStarted', {
                    'tool': toolName,
                  }),
          'tool_result' =>
            toolName.isEmpty
                ? chatTabsText('scout.agentEvent.toolFinishedDefault')
                : chatTabsText('scout.agentEvent.toolFinished', {
                    'tool': toolName,
                  }),
          'planning_questions' => chatTabsText(
            'scout.agentEvent.planningQuestions',
          ),
          'plan_ready' =>
            summary.isEmpty
                ? chatTabsText('scout.agentEvent.planReady')
                : summary,
          'plan_started' => chatTabsText('scout.agentEvent.planStarted', {
            'total': _countOf(data['total']),
          }),
          'plan_step_start' => chatTabsText('scout.agentEvent.planStep', {
            'step': _countOf(data['step']),
            'total': _countOf(data['total']),
            'title': data['title']?.toString() ?? '',
          }),
          'plan_step_result' => chatTabsText(
            data['status']?.toString() == 'failed'
                ? 'scout.agentEvent.planStepFailed'
                : 'scout.agentEvent.planStepDone',
            {'step': _countOf(data['step']), 'total': _countOf(data['total'])},
          ),
          'plan_finished' => chatTabsText('scout.agentEvent.planFinished', {
            'done': _countOf(data['done']),
            'total': _countOf(data['total']),
          }),
          'plan_skipped' => chatTabsText('scout.agentEvent.planSkipped'),
          'approval_needed' =>
            summary.isEmpty
                ? chatTabsText('scout.agentEvent.approvalRequired')
                : summary,
          'permission_request' => chatTabsText(
            'scout.agentEvent.permissionRequested',
          ),
          'permission_result' => switch (data['decision']?.toString()) {
            'once' => chatTabsText('scout.agentEvent.permissionAllowedOnce'),
            'session' => chatTabsText(
              'scout.agentEvent.permissionAllowedSession',
            ),
            _ => chatTabsText('scout.agentEvent.permissionDenied'),
          },
          'file_changed' => switch (data['action']?.toString()) {
            'created' => chatTabsText('scout.agentEvent.fileCreated'),
            'deleted' => chatTabsText('scout.agentEvent.fileDeleted'),
            'moved' => chatTabsText('scout.agentEvent.fileMoved'),
            _ => chatTabsText('scout.agentEvent.fileModified'),
          },
          'compression' => chatTabsText('scout.agentEvent.memoryCompressed'),
          _ => type,
        };
        final icon = switch (type) {
          'tool_start' => Icons.play_arrow_outlined,
          'tool_result' => Icons.check_circle_outline,
          'planning_questions' => Icons.help_outline,
          'plan_ready' => Icons.fact_check_outlined,
          'plan_started' => Icons.playlist_add_check,
          'plan_step_start' => Icons.radio_button_checked,
          'plan_step_result' =>
            data['status']?.toString() == 'failed'
                ? Icons.error_outline
                : Icons.check_circle_outline,
          'plan_finished' => Icons.checklist_rtl,
          'plan_skipped' => Icons.fast_forward,
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
              Icon(icon, size: 13, color: CulpeoColors.metricBright),
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
                Expanded(
                  child: Text(
                    chatTabsText('scout.files'),
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  key: const Key('file-tree-refresh'),
                  tooltip: chatTabsText('scout.refresh'),
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
                        color: CulpeoColors.metric,
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
                  color: isDir ? CulpeoColors.metric : Colors.white38,
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

  (String, Color) _fileChangeActionStyle(String action) {
    switch (action) {
      case 'created':
        return (chatTabsText('scout.fileAction.new'), const Color(0xFF7BAE7F));
      case 'deleted':
        return (
          chatTabsText('scout.fileAction.deleted'),
          const Color(0xFFD97B7B),
        );
      case 'moved':
        return (
          chatTabsText('scout.fileAction.moved'),
          const Color(0xFF6E8FE0),
        );
      default:
        return (chatTabsText('scout.fileAction.modified'), CulpeoColors.metric);
    }
  }

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

        for (final (index, change) in changes.indexed)
          _buildFileChangeCard(change, index),
      ],
    );
  }

  Widget _buildFileChangeCard(Map<String, dynamic> change, int index) {
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
      key: ValueKey('file-change-$index-$path-$action-$destination'),
      path: path,
      actionLabel: label,
      actionColor: color,
      destination: destination,
      diff: diffSkipped ? '' : diff,
      diffSkipped: diffSkipped,
    );
  }

  /// True while something sits on the composer's top edge. The input drops its
  /// upper corners then, so the two read as one block.
  bool get _hasComposerHat => _showPlanningApproval || _planSteps.isNotEmpty;

  /// Drops the worklist. The backend keeps its copy until the next approved
  /// plan replaces it, so nothing resumes behind the user's back once the list
  /// is gone from the composer.
  void _discardPlan() {
    setState(() {
      _planSteps = const [];
      _planSummary = '';
      _planRunning = false;
    });
  }

  Widget _buildPlanningApprovalPanel() {
    final planning = _pendingPlanningData ?? {};
    final summary =
        planning['plan_summary']?.toString() ??
        chatTabsText('scout.agentEvent.planReady');
    final steps = planning['steps'] is List
        ? List<dynamic>.from(planning['steps'])
        : <dynamic>[];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      decoration: BoxDecoration(
        color: CulpeoColors.metric.withValues(alpha: 0.08),
        // Same radius as the composer it sits on, so the two read as one shape
        // rather than as a lid that does not fit the box.
        borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
        border: Border(
          top: BorderSide(color: CulpeoColors.metric.withValues(alpha: 0.35)),
          left: BorderSide(color: CulpeoColors.metric.withValues(alpha: 0.35)),
          right: BorderSide(color: CulpeoColors.metric.withValues(alpha: 0.35)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.fact_check_outlined,
                color: CulpeoColors.metricBright,
                size: 16,
              ),
              SizedBox(width: 8),
              Text(
                chatTabsText('scout.planApproval'),
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
                child: Text(chatTabsText('common.reject')),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () => _sendMessage(approvePlan: true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CulpeoColors.metric,
                ),
                child: Text(chatTabsText('common.approve')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _respondPermission(String decision) async {
    final pending = _pendingPermission;
    if (pending == null) return;
    final requestId = pending['request_id']?.toString() ?? '';
    final sessionId = pending['session_id']?.toString() ?? (_sessionId ?? '');
    setState(() => _pendingPermission = null);
    final ok = await _api.spark.respondPermission(
      sessionId: sessionId,
      requestId: requestId,
      decision: decision,
    );
    if (!ok && mounted) {
      showTopNotification(
        context,
        chatTabsText('scout.permissionNoLongerOpen'),
        color: const Color(0xFFE06C75),
      );
    }
  }

  Future<void> _loadFileTree() async {
    final sessionId = _sessionId;
    if (sessionId == null || _fileTreeLoading) return;
    _fileTreeLoading = true;
    try {
      final result = await _api.scout.getSessionTree(sessionId);
      if (!mounted || sessionId != _sessionId) return;
      final tree = result['tree'];
      setState(() {
        _fileTree = tree is Map ? Map<String, dynamic>.from(tree) : null;
      });
    } finally {
      _fileTreeLoading = false;
    }
  }

  void _scheduleFileTreeRefresh() {
    if (!_showFileTree) return;
    _fileTreeRefreshTimer?.cancel();
    _fileTreeRefreshTimer = Timer(
      const Duration(milliseconds: 500),
      _loadFileTree,
    );
  }

  Widget _buildCreatedBotCard(Map<String, dynamic> bot) {
    final name = bot['name']?.toString() ?? chatTabsText('scout.newBot');
    final keywords = bot['keywords'];
    final keywordText = keywords is List
        ? keywords
              .map((e) => e.toString())
              .where((e) => e.isNotEmpty)
              .join(', ')
        : '';
    final themeColor = CulpeoColors.metric;

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
                  chatTabsText('scout.botSaved', {'name': name}),
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
                label: chatTabsText('scout.test'),
                onTap: () => _testCreatedBot(bot),
              ),
              chatActionChip(
                enabled: !_isLoading,
                icon: Icons.tune,
                label: chatTabsText('common.edit'),
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
            hintText: chatTabsText('scout.editMessageHint'),
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
              child: Text(chatTabsText('common.cancel')),
            ),
            const SizedBox(width: 4),
            TextButton(
              onPressed: () => _submitEditedUserMessage(index, currentContent),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFEBD9A8),
                minimumSize: const Size(0, 30),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: Text(chatTabsText('scout.resend')),
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
              message: chatTabsText('scout.jumpToYourMessage'),
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
                          color: CulpeoColors.metric.withValues(
                            alpha: isHighlighted ? 1 : 0.7,
                          ),
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
            tooltip: chatTabsText('common.edit'),
            icon: Icons.edit_outlined,
            onTap: () => _startEditingUserMessage(index, content),
          ),
          const SizedBox(width: 4),
          messageActionButton(
            enabled: !_isLoading,
            tooltip: chatTabsText('common.copyText'),
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
          tooltip: chatTabsText('common.copyText'),
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
      tooltip: chatTabsText('common.actions'),
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
          messageMenuItem(
            'shorter',
            Icons.compress,
            chatTabsText('scout.shorter'),
          ),
          messageMenuItem(
            'critical',
            Icons.gavel,
            chatTabsText('scout.moreCritical'),
          ),
          messageMenuItem(
            'structure',
            Icons.format_list_bulleted,
            chatTabsText('scout.moreStructure'),
          ),
          if (message['bot_id'] == 'botbuilder')
            messageMenuItem(
              'tune',
              Icons.auto_fix_high,
              chatTabsText('scout.fineTune'),
            )
          else
            messageMenuItem(
              'rule',
              Icons.smart_toy_outlined,
              chatTabsText('scout.useAsRule'),
            ),
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
        final themeColor = CulpeoColors.metric;
        final composerBorder = AppColors.divider;
        final composerText = AppColors.textPrimary;
        final composerHint = AppColors.textSecondary;
        // The input is the one surface in the chat the user works in, so it is
        // the one that gets a fill: a panel raised off the page background,
        // like every other card in the app. The transcript above it stays flat
        // on the background, which is what keeps the two apart now that the
        // composer no longer relies on an outline alone to be found.
        final composerSurface = CulpeoColors.panel;
        final composerRadius = _hasComposerHat
            ? const BorderRadius.vertical(bottom: Radius.circular(17))
            : BorderRadius.circular(17);

        final String modelId = _selectedChatModel?.modelId ?? '';
        final efforts = ThinkingLevels.optionsFor(_reasoningProfiles, modelId);

        final List<ThinkingModeOption> thinkingOptions = efforts.map((e) {
          final String key = e == 'xhigh'
              ? 'XHigh'
              : e[0].toUpperCase() + e.substring(1);
          return ThinkingModeOption(
            value: e,
            label: chatTabsText('common.thinking$key'),
            icon: ThinkingLevels.iconDataFor(e),
          );
        }).toList();

        thinkingOptions.add(
          ThinkingModeOption(
            value: 'dual',
            label: chatTabsText('common.thinkingDual'),
            icon: ThinkingLevels.iconDataFor('dual'),
            enabled: false,
          ),
        );

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
                // Composer footprint is a quarter larger than the previous
                // 483/357 (width), 14/15 (padding) and 13 (text) baseline,
                // which was itself 15% over the original. It's bottom-anchored
                // (Align+fixed bottom padding above), so the extra height only
                // pushes the top edge up - the composer never grows toward the
                // screen edge.
                constraints: BoxConstraints(
                  // A pane in the multi-chat workspace can be dragged narrower
                  // than the composer wants to be, so the floor follows the
                  // room that is actually there rather than overflowing it.
                  minWidth: math.min(
                    isDesktop ? 604 : 446,
                    math.max(width - 48, 0),
                  ),
                  maxWidth: isDesktop
                      ? math.max(width * 0.359, 604)
                      : math.min(math.max(width * 0.95, 446), 719),
                ),
                // What belongs to the next message sits on the composer like a
                // hat: the plan waiting for approval, and the worklist it turns
                // into. Both share the input's width and its top edge, so they
                // read as part of the same thing instead of floating cards.
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_showPlanningApproval)
                      _buildPlanningApprovalPanel()
                    else if (_planSteps.isNotEmpty)
                      PlanChecklist(
                        summary: _planSummary,
                        steps: _planSteps,
                        running: _planRunning,
                        onResume: _interactionLocked
                            ? null
                            : () => _sendMessage(approvePlan: true),
                        onDiscard: _interactionLocked ? null : _discardPlan,
                      ),
                    ComposerActivityGlow(
                      active: _interactionLocked,
                      borderRadius: composerRadius,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 19,
                        ),
                        decoration: BoxDecoration(
                          color: composerSurface,
                          borderRadius: composerRadius,
                          border: Border.all(
                            color: _isDragging ? themeColor : composerBorder,
                            width: _isDragging ? 1.5 : 1.0,
                          ),
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
                              key: _paneKey('chat-composer'),
                              focusNode: _inputFocusNode,
                              controller: _msgController,
                              enabled: !_interactionLocked,
                              onTap: widget.onPaneFocused,
                              style: TextStyle(
                                color: composerText,
                                fontSize: 16,
                              ),
                              maxLines: 4,
                              minLines: 1,
                              decoration: InputDecoration(
                                hintText: chatTabsText('scout.messageHint'),
                                hintStyle: TextStyle(
                                  color: composerHint,
                                  fontSize: 16,
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
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CompositedTransformTarget(
                                  link: _plusMenuLink,
                                  child: IconButton(
                                    key: _paneKey('chat-add-button'),
                                    tooltip: chatTabsText('scout.addAction'),
                                    onPressed: _interactionLocked
                                        ? null
                                        : _togglePlusMenu,
                                    constraints: const BoxConstraints(
                                      minWidth: 52,
                                      minHeight: 52,
                                    ),
                                    icon: Icon(
                                      Icons.add,
                                      color: composerHint,
                                      size: 24,
                                    ),
                                  ),
                                ),
                                if (_webSearchEnabled) ...[
                                  const SizedBox(width: 6),
                                  ChatBadge(
                                    icon: Icons.language,
                                    label: chatTabsText('common.web'),
                                    themeColor: CulpeoColors.metric,
                                    onTap: () => setState(
                                      () => _webSearchEnabled = false,
                                    ),
                                  ),
                                ],
                                // The trailing controls are all fixed width and a
                                // pane can be dragged narrower than they add up to,
                                // so the cluster shrinks to fit instead of
                                // overflowing the row.
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerRight,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // A reading, so it stands ahead of the
                                          // controls rather than among them.
                                          if (_contextUsage.isKnown) ...[
                                            ContextMeter(usage: _contextUsage),
                                            const SizedBox(width: 10),
                                          ],
                                          SparkModeButton(
                                            active: _sparkEnabled,
                                            label: chatTabsText(
                                              'common.modeSpark',
                                            ),
                                            tooltip: chatTabsText(
                                              'common.modeSparkHint',
                                            ),
                                            themeColor: CulpeoColors.action,
                                            compact: !isDesktop,
                                            onChanged: (spark) {
                                              setState(() {
                                                _sparkEnabled = spark;
                                              });
                                            },
                                          ),
                                          const SizedBox(width: 8),
                                          ThinkingModeSliderButton(
                                            value: _thinkingLevel,
                                            options: thinkingOptions,
                                            // Not the composer's gold: the ring
                                            // marks which mode is selected, and
                                            // selection is rust
                                            // (design_tokens.dart) - gold is for
                                            // what the engine reported, not for a
                                            // control.
                                            themeColor: CulpeoColors.action,
                                            onChanged: (val) {
                                              setState(() {
                                                _thinkingLevel = val;
                                              });
                                            },
                                          ),
                                          const SizedBox(width: 8),
                                          HoverIconButton(
                                            icon: Icons.mic_none,
                                            tooltip: chatTabsText(
                                              'scout.voiceMessage',
                                            ),
                                            onPressed: () {},
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            key: _paneKey('chat-send-button'),
                                            tooltip: _sessionId == null
                                                ? chatTabsText(
                                                    'scout.selectModelFirst',
                                                  )
                                                : _isLoading
                                                ? chatTabsText(
                                                    'scout.botWorking',
                                                  )
                                                : _warmup.isActive
                                                ? chatTabsText(
                                                    'scout.waitForModel',
                                                  )
                                                : chatTabsText(
                                                    'scout.sendMessage',
                                                  ),
                                            onPressed:
                                                _interactionLocked ||
                                                    _sessionId == null ||
                                                    !hasText
                                                ? null
                                                : () => _sendMessage(),
                                            constraints: const BoxConstraints(
                                              minWidth: 52,
                                              minHeight: 52,
                                            ),
                                            style: IconButton.styleFrom(
                                              backgroundColor: hasText
                                                  ? themeColor
                                                  : composerHint.withValues(
                                                      alpha: 0.15,
                                                    ),
                                              disabledBackgroundColor:
                                                  composerHint.withValues(
                                                    alpha: 0.15,
                                                  ),
                                            ),

                                            icon: _interactionLocked
                                                ? const SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child:
                                                        CircularProgressIndicator(
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
                                                      size: 22,
                                                    ),
                                                  ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
