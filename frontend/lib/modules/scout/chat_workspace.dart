import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/api_service.dart';
import '../../core/app_state.dart';
import '../../core/design_tokens.dart';
import '../../core/top_notification.dart';
import './chat_tabs_strings.dart';
import './scout_tab.dart';

/// The number of independently interactive chats the workspace keeps open.
/// A single [AppState.currentChatSessionId] still exists for compatibility
/// with the history and model sidebar; it represents the focused pane only.
enum ChatWorkspaceLayout { single, split, grid }

/// Hosts independently stateful [ScoutTab] instances in a responsive grid.
///
/// The workspace owns the open-pane and focused-pane state. Each [ScoutTab]
/// receives a fixed `sessionId`, so a selection in the history cannot replace
/// a different pane's messages or cancel its active stream.
class ChatWorkspace extends StatefulWidget {
  const ChatWorkspace({super.key, this.api, this.appState});

  final ApiService? api;
  final AppState? appState;

  @override
  State<ChatWorkspace> createState() => _ChatWorkspaceState();
}

class _ChatWorkspaceState extends State<ChatWorkspace> {
  static const int _maximumOpenPanes = 4;
  static const double _paneGap = CulpeoLayout.gridGap;
  static const double _minimumTwoPaneWidth = 960;
  static const double _minimumGridHeight = 660;
  static const String _newChatMenuValue = 'new-chat';

  late final ApiService _api;
  late final AppState _appState;
  final List<String> _openSessionIds = [];
  String? _focusedSessionId;
  ChatWorkspaceLayout _layout = ChatWorkspaceLayout.single;
  bool _inlineWorkspaceMenuOpen = false;
  bool _toolbarWorkspaceMenuOpen = false;
  int _lastHandledModelTargetSelectionRequest = 0;
  bool _modelTargetDialogOpen = false;

  @override
  void initState() {
    super.initState();
    _api = widget.api ?? ApiService();
    _appState = widget.appState ?? AppState();
    _appState.addListener(_onAppStateChanged);
    _lastHandledModelTargetSelectionRequest =
        _appState.chatModelTargetSelectionRequest;

    final initialSessionId = _appState.currentChatSessionId;
    if (initialSessionId != null) {
      _openSessionIds.add(initialSessionId);
      _focusedSessionId = initialSessionId;
    }
  }

  @override
  void dispose() {
    _appState.removeListener(_onAppStateChanged);
    super.dispose();
  }

  void _onAppStateChanged() {
    final modelTargetSelectionRequest =
        _appState.chatModelTargetSelectionRequest;
    final hasNewModelTargetSelectionRequest =
        modelTargetSelectionRequest != _lastHandledModelTargetSelectionRequest;
    // Remember the request before a focus change triggers another AppState
    // notification. Otherwise one sidebar tap could show the picker twice.
    if (hasNewModelTargetSelectionRequest) {
      _lastHandledModelTargetSelectionRequest = modelTargetSelectionRequest;
    }

    final availableIds = _appState.chatSessions.toSet();
    final nextOpenIds = [
      for (final sessionId in _openSessionIds)
        if (availableIds.contains(sessionId)) sessionId,
    ];
    final selectedSessionId = _appState.currentChatSessionId;
    if (selectedSessionId != null &&
        availableIds.contains(selectedSessionId) &&
        !nextOpenIds.contains(selectedSessionId)) {
      nextOpenIds.insert(0, selectedSessionId);
      if (nextOpenIds.length > _maximumOpenPanes) nextOpenIds.removeLast();
    }

    String? nextFocusedSessionId = _focusedSessionId;
    if (selectedSessionId != null && nextOpenIds.contains(selectedSessionId)) {
      nextFocusedSessionId = selectedSessionId;
    } else if (nextFocusedSessionId == null ||
        !nextOpenIds.contains(nextFocusedSessionId)) {
      nextFocusedSessionId = nextOpenIds.isEmpty ? null : nextOpenIds.first;
    }

    final openIdsChanged =
        nextOpenIds.length != _openSessionIds.length ||
        nextOpenIds.asMap().entries.any(
          (entry) => _openSessionIds[entry.key] != entry.value,
        );
    if (openIdsChanged || nextFocusedSessionId != _focusedSessionId) {
      setState(() {
        _openSessionIds
          ..clear()
          ..addAll(nextOpenIds);
        _focusedSessionId = nextFocusedSessionId;
      });
    }

    if (hasNewModelTargetSelectionRequest) {
      _requestModelTargetSelection();
    }
  }

  /// The sidebar stays the familiar place to choose a model. When there are
  /// multiple open chats, it first asks which pane the following sidebar
  /// choice should control. A single pane deliberately keeps the historic
  /// direct flow and never opens this dialog.
  void _requestModelTargetSelection() {
    if (!mounted || _openSessionIds.length <= 1 || _modelTargetDialogOpen) {
      return;
    }
    _modelTargetDialogOpen = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _openSessionIds.length <= 1) {
        _modelTargetDialogOpen = false;
        return;
      }
      unawaited(_showModelTargetSelectionDialog());
    });
  }

  Future<void> _showModelTargetSelectionDialog() async {
    try {
      final sessionIds = List<String>.unmodifiable(_openSessionIds);
      final selectedSessionId = await showDialog<String>(
        context: context,
        useRootNavigator: true,
        builder: (dialogContext) => _ChatModelTargetDialog(
          sessionIds: sessionIds,
          focusedSessionId: _focusedSessionId,
          titleForSession: _appState.getSessionTitle,
        ),
      );
      if (!mounted || selectedSessionId == null) return;
      // A chat may have been closed while the dialog was visible.
      if (_openSessionIds.contains(selectedSessionId)) {
        _openSession(selectedSessionId);
      }
    } finally {
      _modelTargetDialogOpen = false;
    }
  }

  void _openSession(String sessionId) {
    if (!_appState.chatSessions.contains(sessionId)) return;
    final wasAlreadyOpen = _openSessionIds.contains(sessionId);
    if (wasAlreadyOpen && _focusedSessionId == sessionId) return;
    final replacedSession =
        !wasAlreadyOpen && _openSessionIds.length >= _maximumOpenPanes;

    setState(() {
      // Pane order belongs to the workspace, not to focus. Keeping an open
      // chat in place is what makes a drag-and-drop swap remain visible after
      // the dragged pane becomes the focused chat.
      if (!wasAlreadyOpen) {
        _openSessionIds.insert(0, sessionId);
        if (_openSessionIds.length > _maximumOpenPanes) {
          _openSessionIds.removeLast();
        }
      }
      _focusedSessionId = sessionId;
    });
    _appState.selectChatSession(sessionId);

    if (replacedSession && mounted) {
      showTopNotification(
        context,
        chatTabsText('scout.multiChat.maximumReached'),
        color: CulpeoColors.warning,
      );
    }
  }

  /// Exchanges two occupied pane positions without recreating either
  /// [ScoutTab]. Their session keys therefore keep a running stream, draft and
  /// locally selected model attached to the chat the user picked up.
  void _swapSessionPanes(String draggedSessionId, String targetSessionId) {
    if (draggedSessionId == targetSessionId) return;
    final draggedIndex = _openSessionIds.indexOf(draggedSessionId);
    final targetIndex = _openSessionIds.indexOf(targetSessionId);
    if (draggedIndex < 0 || targetIndex < 0) return;

    setState(() {
      _openSessionIds[draggedIndex] = targetSessionId;
      _openSessionIds[targetIndex] = draggedSessionId;
      _focusedSessionId = draggedSessionId;
    });
    _appState.selectChatSession(draggedSessionId);
  }

  void _closeSession(String sessionId) {
    if (_openSessionIds.length <= 1) return;
    setState(() {
      _openSessionIds.remove(sessionId);
      if (_focusedSessionId == sessionId) {
        _focusedSessionId = _openSessionIds.firstOrNull;
      }
    });
    final focusedSessionId = _focusedSessionId;
    if (focusedSessionId != null) {
      _appState.selectChatSession(focusedSessionId);
    }
  }

  void _setLayout(ChatWorkspaceLayout layout) {
    setState(() => _layout = layout);
  }

  void _selectWorkspaceMenuItem(String value) {
    if (value == _newChatMenuValue) {
      // ScoutTab only handles this broadcast in the focused pane. Its pinned
      // session therefore supplies the correct per-chat model for the new
      // conversation instead of relying on a workspace-wide model choice.
      _appState.triggerAction('new_chat_session');
      return;
    }
    if (value.startsWith('layout:')) {
      final layout = switch (value.substring('layout:'.length)) {
        'single' => ChatWorkspaceLayout.single,
        'split' => ChatWorkspaceLayout.split,
        _ => ChatWorkspaceLayout.grid,
      };
      _setLayout(layout);
      return;
    }
    if (value.startsWith('session:')) {
      _openSession(value.substring('session:'.length));
    }
  }

  ChatWorkspaceLayout _effectiveLayout(BoxConstraints constraints) {
    if (constraints.maxWidth < _minimumTwoPaneWidth) {
      return ChatWorkspaceLayout.single;
    }
    if (_layout == ChatWorkspaceLayout.grid &&
        constraints.maxHeight < _minimumGridHeight) {
      return ChatWorkspaceLayout.split;
    }
    return _layout;
  }

  List<String> _visibleSessionIds(int paneCount) {
    final focusedSessionId = _focusedSessionId;
    // A single pane always follows focus. Multi-pane layouts instead follow
    // the explicit workspace order so users can actually see a dropped chat
    // exchange positions with its target.
    if (paneCount == 1 &&
        focusedSessionId != null &&
        _openSessionIds.contains(focusedSessionId)) {
      return [focusedSessionId];
    }
    return _openSessionIds.take(paneCount).toList();
  }

  String _layoutLabel(ChatWorkspaceLayout layout) => switch (layout) {
    ChatWorkspaceLayout.single => chatTabsText('scout.multiChat.layout.single'),
    ChatWorkspaceLayout.split => chatTabsText('scout.multiChat.layout.split'),
    ChatWorkspaceLayout.grid => chatTabsText('scout.multiChat.layout.grid'),
  };

  IconData _layoutIcon(ChatWorkspaceLayout layout) => switch (layout) {
    ChatWorkspaceLayout.single => Icons.crop_square_rounded,
    ChatWorkspaceLayout.split => Icons.view_week_outlined,
    ChatWorkspaceLayout.grid => Icons.grid_view_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, workspaceConstraints) {
        final showWorkspaceToolbar =
            _effectiveLayout(workspaceConstraints) !=
            ChatWorkspaceLayout.single;
        return Column(
          children: [
            if (showWorkspaceToolbar) _buildToolbar(context),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (_openSessionIds.isEmpty &&
                      _appState.chatSessions.isEmpty) {
                    return _buildNewChatPane();
                  }
                  return _buildWorkspaceGrid(context, constraints);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildToolbar(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 680;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.white10)),
          ),
          child: Row(
            children: [
              const Icon(Icons.forum_outlined, size: 17, color: Colors.white54),
              if (!compact) ...[
                const SizedBox(width: 8),
                Text(
                  chatTabsText('scout.multiChat.title'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const Spacer(),
              _LayoutButton(
                key: const Key('chat-workspace-layout-single'),
                icon: Icons.crop_square_rounded,
                label: _layoutLabel(ChatWorkspaceLayout.single),
                selected: _layout == ChatWorkspaceLayout.single,
                onPressed: () => _setLayout(ChatWorkspaceLayout.single),
              ),
              _LayoutButton(
                key: const Key('chat-workspace-layout-split'),
                icon: Icons.view_week_outlined,
                label: _layoutLabel(ChatWorkspaceLayout.split),
                selected: _layout == ChatWorkspaceLayout.split,
                onPressed: () => _setLayout(ChatWorkspaceLayout.split),
              ),
              _LayoutButton(
                key: const Key('chat-workspace-layout-grid'),
                icon: Icons.grid_view_rounded,
                label: _layoutLabel(ChatWorkspaceLayout.grid),
                selected: _layout == ChatWorkspaceLayout.grid,
                onPressed: () => _setLayout(ChatWorkspaceLayout.grid),
              ),
              const SizedBox(width: 4),
              _buildToolbarWorkspaceMenu(),
            ],
          ),
        );
      },
    );
  }

  /// The multi-pane toolbar keeps the same menu surface as the compact
  /// single-pane selector. It exposes a direct new-chat action as well as
  /// existing conversations, while the layout buttons remain visibly close.
  Widget _buildToolbarWorkspaceMenu() {
    return PopupMenuButton<String>(
      key: const Key('chat-workspace-add'),
      tooltip: chatTabsText('scout.multiChat.add'),
      padding: EdgeInsets.zero,
      position: PopupMenuPosition.under,
      offset: const Offset(0, 6),
      constraints: const BoxConstraints.tightFor(width: 280),
      menuPadding: const EdgeInsets.all(6),
      color: const Color(0xFF17171B),
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black.withValues(alpha: 0.55),
      elevation: 14,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
      ),
      onOpened: () => setState(() => _toolbarWorkspaceMenuOpen = true),
      onCanceled: () => setState(() => _toolbarWorkspaceMenuOpen = false),
      onSelected: (value) {
        setState(() => _toolbarWorkspaceMenuOpen = false);
        _selectWorkspaceMenuItem(value);
      },
      itemBuilder: (context) {
        final available = _appState.chatSessions
            .where((id) => !_openSessionIds.contains(id))
            .toList();
        return [
          PopupMenuItem<String>(
            key: const Key('chat-workspace-new'),
            value: _newChatMenuValue,
            height: 58,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: _WorkspaceMenuNewChatAction(
              title: chatTabsText('scout.multiChat.new'),
              subtitle: chatTabsText('scout.multiChat.newHint'),
            ),
          ),
          const PopupMenuDivider(height: 12),
          PopupMenuItem<String>(
            enabled: false,
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _WorkspaceMenuSectionLabel(
              chatTabsText('scout.multiChat.menuAvailable'),
            ),
          ),
          if (available.isEmpty)
            PopupMenuItem<String>(
              enabled: false,
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
              child: _WorkspaceMenuEmptyState(
                chatTabsText('scout.multiChat.noChatToAdd'),
              ),
            )
          else
            for (final sessionId in available)
              PopupMenuItem<String>(
                key: Key('chat-workspace-session-$sessionId'),
                value: 'session:$sessionId',
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                child: _WorkspaceMenuOption(
                  icon: Icons.forum_outlined,
                  label: _appState.getSessionTitle(sessionId),
                  trailing: Icons.open_in_new_rounded,
                ),
              ),
        ];
      },
      child: Semantics(
        button: true,
        label: chatTabsText('scout.multiChat.add'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          width: 32,
          height: 30,
          decoration: BoxDecoration(
            color: _toolbarWorkspaceMenuOpen
                ? CulpeoColors.action.withValues(alpha: 0.14)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _toolbarWorkspaceMenuOpen
                  ? CulpeoColors.action.withValues(alpha: 0.46)
                  : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Icon(
            Icons.add_comment_outlined,
            size: 17,
            color: _toolbarWorkspaceMenuOpen
                ? CulpeoColors.actionHover
                : Colors.white60,
          ),
        ),
      ),
    );
  }

  Widget _buildNewChatPane() {
    return _WorkspacePane(
      key: const Key('chat-pane-new'),
      semanticLabel: chatTabsText('scout.multiChat.pane', {'title': ''}),
      selected: true,
      framed: false,
      child: ScoutTab(
        api: _api,
        appState: _appState,
        headerAction: _buildInlineWorkspaceMenu(),
        onSessionCreated: _openSession,
      ),
    );
  }

  Widget _buildInlineWorkspaceMenu() {
    return PopupMenuButton<String>(
      key: const Key('chat-workspace-menu'),
      tooltip: chatTabsText('scout.multiChat.title'),
      padding: EdgeInsets.zero,
      position: PopupMenuPosition.under,
      offset: const Offset(0, 6),
      constraints: const BoxConstraints.tightFor(width: 280),
      menuPadding: const EdgeInsets.all(6),
      color: const Color(0xFF17171B),
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black.withValues(alpha: 0.55),
      elevation: 14,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
      ),
      onOpened: () => setState(() => _inlineWorkspaceMenuOpen = true),
      onCanceled: () => setState(() => _inlineWorkspaceMenuOpen = false),
      onSelected: (value) {
        setState(() => _inlineWorkspaceMenuOpen = false);
        _selectWorkspaceMenuItem(value);
      },
      itemBuilder: (context) {
        final available = _appState.chatSessions
            .where((id) => !_openSessionIds.contains(id))
            .toList();
        return [
          PopupMenuItem<String>(
            key: const Key('chat-workspace-new'),
            value: _newChatMenuValue,
            height: 58,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: _WorkspaceMenuNewChatAction(
              title: chatTabsText('scout.multiChat.new'),
              subtitle: chatTabsText('scout.multiChat.newHint'),
            ),
          ),
          const PopupMenuDivider(height: 12),
          PopupMenuItem<String>(
            enabled: false,
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _WorkspaceMenuSectionLabel(
              chatTabsText('scout.multiChat.menuLayout'),
            ),
          ),
          for (final layout in ChatWorkspaceLayout.values)
            PopupMenuItem<String>(
              key: Key('chat-workspace-layout-option-${layout.name}'),
              value: 'layout:${layout.name}',
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              child: _WorkspaceMenuOption(
                icon: _layoutIcon(layout),
                label: _layoutLabel(layout),
                selected: _layout == layout,
              ),
            ),
          const PopupMenuDivider(height: 12),
          PopupMenuItem<String>(
            enabled: false,
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _WorkspaceMenuSectionLabel(
              chatTabsText('scout.multiChat.menuAvailable'),
            ),
          ),
          if (available.isEmpty)
            PopupMenuItem<String>(
              enabled: false,
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
              child: _WorkspaceMenuEmptyState(
                chatTabsText('scout.multiChat.noChatToAdd'),
              ),
            )
          else
            for (final sessionId in available)
              PopupMenuItem<String>(
                key: Key('chat-workspace-session-$sessionId'),
                value: 'session:$sessionId',
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                child: _WorkspaceMenuOption(
                  icon: Icons.forum_outlined,
                  label: _appState.getSessionTitle(sessionId),
                  trailing: Icons.open_in_new_rounded,
                ),
              ),
        ];
      },
      child: Semantics(
        button: true,
        label: chatTabsText('scout.multiChat.title'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          width: 30,
          height: 28,
          decoration: BoxDecoration(
            color: _inlineWorkspaceMenuOpen
                ? CulpeoColors.action.withValues(alpha: 0.14)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _inlineWorkspaceMenuOpen
                  ? CulpeoColors.action.withValues(alpha: 0.46)
                  : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Icon(
            Icons.view_quilt_outlined,
            size: 17,
            color: _inlineWorkspaceMenuOpen
                ? CulpeoColors.actionHover
                : Colors.white60,
          ),
        ),
      ),
    );
  }

  Widget _buildWorkspaceGrid(BuildContext context, BoxConstraints constraints) {
    final effectiveLayout = _effectiveLayout(constraints);
    final paneCount = switch (effectiveLayout) {
      ChatWorkspaceLayout.single => 1,
      ChatWorkspaceLayout.split => 2,
      ChatWorkspaceLayout.grid => 4,
    };
    final rowCount = effectiveLayout == ChatWorkspaceLayout.grid ? 2 : 1;
    final mainExtent = rowCount == 1
        ? constraints.maxHeight
        : (constraints.maxHeight - _paneGap) / rowCount;
    final crossExtent = effectiveLayout == ChatWorkspaceLayout.single
        ? constraints.maxWidth
        : (constraints.maxWidth - _paneGap) / 2;
    final visibleSessionIds = _visibleSessionIds(paneCount);

    return GridView.builder(
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      // A GridView builder reuses children by index unless it can resolve a
      // child's new index. Pane positions are intentionally swapped at
      // runtime, so map the session key back to its current cell and keep each
      // ScoutTab's draft, transcript and stream state with its session.
      findChildIndexCallback: (key) {
        final value = key is ValueKey<String> ? key.value : null;
        const sessionKeyPrefix = 'chat-pane-';
        if (value == null || !value.startsWith(sessionKeyPrefix)) return null;
        const dropTargetKeyPrefix = 'chat-pane-drop-';
        final sessionId = value.startsWith(dropTargetKeyPrefix)
            ? value.substring(dropTargetKeyPrefix.length)
            : value.substring(sessionKeyPrefix.length);
        final index = visibleSessionIds.indexOf(sessionId);
        return index < 0 ? null : index;
      },
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        // Chat panes must have an independently scrollable transcript and
        // composer, so their height derives from the workspace rather than a
        // card aspect ratio. The max extent retains CulpeoGrid's responsive
        // two-column behaviour without hard-coding device types.
        maxCrossAxisExtent: crossExtent,
        mainAxisExtent: mainExtent,
        crossAxisSpacing: _paneGap,
        mainAxisSpacing: _paneGap,
      ),
      itemCount: paneCount,
      itemBuilder: (context, index) {
        if (index >= visibleSessionIds.length) {
          return _EmptyWorkspacePane(
            index: index,
            framed: effectiveLayout != ChatWorkspaceLayout.single,
          );
        }
        final sessionId = visibleSessionIds[index];
        final title = _appState.getSessionTitle(sessionId);
        final multiPane = effectiveLayout != ChatWorkspaceLayout.single;

        Widget buildPane(bool isDropTarget) {
          return _WorkspacePane(
            key: Key('chat-pane-$sessionId'),
            semanticLabel: chatTabsText('scout.multiChat.pane', {
              'title': title,
            }),
            selected: sessionId == _focusedSessionId,
            framed: multiPane,
            isDropTarget: isDropTarget,
            onFocus: () => _openSession(sessionId),
            child: ScoutTab(
              key: ValueKey('scout-pane-$sessionId'),
              api: _api,
              appState: _appState,
              sessionId: sessionId,
              isActivePane: sessionId == _focusedSessionId,
              onPaneFocused: () => _openSession(sessionId),
              headerAction: multiPane
                  ? _ChatPaneDragHandle(
                      key: Key('chat-pane-drag-$sessionId'),
                      sessionId: sessionId,
                      title: title,
                      onDragStarted: () => _openSession(sessionId),
                    )
                  : _buildInlineWorkspaceMenu(),
              onClosePane: _openSessionIds.length > 1
                  ? () => _closeSession(sessionId)
                  : null,
              onSessionCreated: _openSession,
            ),
          );
        }

        if (!multiPane) return buildPane(false);

        return _ChatPaneDropTarget(
          key: Key('chat-pane-drop-$sessionId'),
          sessionId: sessionId,
          onAccept: (draggedSessionId) =>
              _swapSessionPanes(draggedSessionId, sessionId),
          builder: buildPane,
        );
      },
    );
  }
}

/// A focused, compact target chooser rather than another model picker. The
/// actual model list remains in the left sidebar; choosing a row here simply
/// makes that chat the sidebar's active model context.
class _ChatModelTargetDialog extends StatelessWidget {
  const _ChatModelTargetDialog({
    required this.sessionIds,
    required this.focusedSessionId,
    required this.titleForSession,
  });

  final List<String> sessionIds;
  final String? focusedSessionId;
  final String Function(String sessionId) titleForSession;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      key: const Key('chat-model-target-dialog'),
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            decoration: BoxDecoration(
              color: CulpeoColors.panel,
              borderRadius: BorderRadius.circular(CulpeoLayout.cardRadius),
              border: Border.all(color: CulpeoColors.hairlineStrong),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.42),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: CulpeoColors.action.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: CulpeoColors.actionBorder),
                      ),
                      child: const Icon(
                        Icons.tune_rounded,
                        size: 18,
                        color: CulpeoColors.actionHover,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        chatTabsText('scout.multiChat.modelTarget.title'),
                        style: TextStyle(
                          color: CulpeoColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      key: const Key('chat-model-target-dismiss'),
                      tooltip: chatTabsText('common.cancel'),
                      splashRadius: 18,
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: CulpeoColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  chatTabsText('scout.multiChat.modelTarget.body'),
                  style: TextStyle(
                    color: CulpeoColors.textSecondary,
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 14),
                for (final sessionId in sessionIds) ...[
                  _ChatModelTargetOption(
                    key: Key('chat-model-target-$sessionId'),
                    title: titleForSession(sessionId),
                    selected: sessionId == focusedSessionId,
                    onTap: () => Navigator.of(context).pop(sessionId),
                  ),
                  if (sessionId != sessionIds.last) const SizedBox(height: 7),
                ],
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    key: const Key('chat-model-target-cancel'),
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: CulpeoColors.textMuted,
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: Text(chatTabsText('common.cancel')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatModelTargetOption extends StatelessWidget {
  const _ChatModelTargetOption({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected
        ? CulpeoColors.textPrimary
        : CulpeoColors.textSecondary;
    return Semantics(
      button: true,
      selected: selected,
      label: title,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(CulpeoLayout.pillRadius),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOut,
            constraints: const BoxConstraints(minHeight: 54),
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
            decoration: BoxDecoration(
              color: selected
                  ? CulpeoColors.action.withValues(alpha: 0.12)
                  : Colors.white.withValues(alpha: 0.025),
              borderRadius: BorderRadius.circular(CulpeoLayout.pillRadius),
              border: Border.all(
                color: selected
                    ? CulpeoColors.actionBorder
                    : CulpeoColors.hairline,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.forum_outlined,
                  size: 17,
                  color: selected ? CulpeoColors.actionHover : Colors.white54,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 12.5,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                ),
                if (selected) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: CulpeoColors.action.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      chatTabsText('scout.multiChat.modelTarget.current'),
                      style: const TextStyle(
                        color: CulpeoColors.actionHover,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ] else
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: Colors.white38,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WorkspaceMenuNewChatAction extends StatelessWidget {
  const _WorkspaceMenuNewChatAction({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: CulpeoColors.action.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CulpeoColors.action.withValues(alpha: 0.46)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: CulpeoColors.action.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Icon(
              Icons.add_comment_outlined,
              size: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.62),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_rounded,
            size: 16,
            color: CulpeoColors.actionHover,
          ),
        ],
      ),
    );
  }
}

class _WorkspaceMenuSectionLabel extends StatelessWidget {
  const _WorkspaceMenuSectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.44),
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.7,
        ),
      ),
    );
  }
}

class _WorkspaceMenuOption extends StatelessWidget {
  const _WorkspaceMenuOption({
    required this.icon,
    required this.label,
    this.selected = false,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final IconData? trailing;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? Colors.white : Colors.white70;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: selected
            ? CulpeoColors.action.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: selected
              ? CulpeoColors.action.withValues(alpha: 0.34)
              : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: selected ? CulpeoColors.actionHover : Colors.white54,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: foreground,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
          if (selected) ...[
            const SizedBox(width: 8),
            const Icon(
              Icons.check_rounded,
              size: 15,
              color: CulpeoColors.actionHover,
            ),
          ] else if (trailing != null) ...[
            const SizedBox(width: 8),
            Icon(trailing, size: 14, color: Colors.white38),
          ],
        ],
      ),
    );
  }
}

class _WorkspaceMenuEmptyState extends StatelessWidget {
  const _WorkspaceMenuEmptyState(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 15,
            color: Colors.white38,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

class _LayoutButton extends StatelessWidget {
  const _LayoutButton({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: IconButton(
        tooltip: label,
        onPressed: onPressed,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        style: IconButton.styleFrom(
          foregroundColor: selected ? CulpeoColors.action : Colors.white54,
          backgroundColor: selected
              ? CulpeoColors.action.withValues(alpha: 0.12)
              : Colors.transparent,
        ),
        icon: Icon(icon, size: 18),
      ),
    );
  }
}

class _WorkspacePane extends StatelessWidget {
  const _WorkspacePane({
    super.key,
    required this.semanticLabel,
    required this.selected,
    required this.child,
    required this.framed,
    this.isDropTarget = false,
    this.onFocus,
  });

  final String semanticLabel;
  final bool selected;
  final Widget child;
  final bool framed;
  final bool isDropTarget;
  final VoidCallback? onFocus;

  @override
  Widget build(BuildContext context) {
    Widget pane = child;
    if (framed) {
      // Keep the original chat surface visible. In multi-pane mode this is a
      // flat neutral divider, not a rounded/fill-coloured card.
      pane = Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isDropTarget
                ? CulpeoColors.actionBorder
                : selected
                ? CulpeoColors.hairlineStrong
                : CulpeoColors.hairline,
            width: isDropTarget ? 1.4 : 1,
          ),
        ),
        child: child,
      );
    }
    if (onFocus != null) {
      pane = Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => onFocus!(),
        child: pane,
      );
    }
    return Semantics(
      container: true,
      selected: selected,
      label: semanticLabel,
      child: pane,
    );
  }
}

/// Typed drag data keeps a chat drop target from reacting to the similarly
/// string-shaped model drags used elsewhere in the Scout UI.
class _WorkspaceChatDrag {
  const _WorkspaceChatDrag(this.sessionId);

  final String sessionId;
}

/// A drop target represents one occupied workspace position. Dropping a chat
/// onto it swaps the two positions, matching the mental model of grabbing one
/// window tab and placing it on another.
class _ChatPaneDropTarget extends StatelessWidget {
  const _ChatPaneDropTarget({
    super.key,
    required this.sessionId,
    required this.onAccept,
    required this.builder,
  });

  final String sessionId;
  final ValueChanged<String> onAccept;
  final Widget Function(bool isDropTarget) builder;

  @override
  Widget build(BuildContext context) {
    return DragTarget<_WorkspaceChatDrag>(
      onWillAcceptWithDetails: (details) => details.data.sessionId != sessionId,
      onAcceptWithDetails: (details) => onAccept(details.data.sessionId),
      builder: (context, candidateData, rejectedData) =>
          builder(candidateData.isNotEmpty),
    );
  }
}

/// The compact grip lives in ScoutTab's existing title bar, so desktop users
/// have an immediately draggable tab affordance without adding a second pane
/// header or changing the chat surface itself.
class _ChatPaneDragHandle extends StatelessWidget {
  const _ChatPaneDragHandle({
    super.key,
    required this.sessionId,
    required this.title,
    required this.onDragStarted,
  });

  final String sessionId;
  final String title;
  final VoidCallback onDragStarted;

  @override
  Widget build(BuildContext context) {
    final handle = MouseRegion(
      cursor: SystemMouseCursors.grab,
      child: Tooltip(
        message: chatTabsText('scout.multiChat.reorder'),
        child: Semantics(
          label: chatTabsText('scout.multiChat.reorder'),
          child: SizedBox(
            width: 28,
            height: 28,
            child: Center(
              child: Icon(
                Icons.drag_indicator_rounded,
                size: 17,
                color: Colors.white.withValues(alpha: 0.46),
              ),
            ),
          ),
        ),
      ),
    );

    return Draggable<_WorkspaceChatDrag>(
      data: _WorkspaceChatDrag(sessionId),
      feedback: _ChatPaneDragFeedback(title: title),
      childWhenDragging: Opacity(opacity: 0.34, child: handle),
      onDragStarted: onDragStarted,
      child: handle,
    );
  }
}

class _ChatPaneDragFeedback extends StatelessWidget {
  const _ChatPaneDragFeedback({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 240),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: CulpeoColors.panel.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(CulpeoLayout.pillRadius),
            border: Border.all(color: CulpeoColors.actionBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.38),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.forum_outlined,
                size: 16,
                color: CulpeoColors.actionHover,
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyWorkspacePane extends StatelessWidget {
  const _EmptyWorkspacePane({required this.index, required this.framed});

  final int index;
  final bool framed;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: Key('chat-pane-empty-$index'),
      decoration: framed
          ? BoxDecoration(border: Border.all(color: CulpeoColors.hairline))
          : null,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.add_comment_outlined,
                color: Colors.white24,
                size: 28,
              ),
              const SizedBox(height: 10),
              Text(
                chatTabsText('scout.multiChat.empty'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
