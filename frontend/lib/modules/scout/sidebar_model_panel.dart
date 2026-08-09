import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/app_theme.dart';
import '../../core/design_tokens.dart';
import './chat_aux_strings.dart';
import './chat_history_panel.dart' show kProjectColorChoices;

/// Shows and drives the active chat session's model choice from the sidebar,
/// grouped into the folders the user organised cloud models into.
///
/// The session (today: `ScoutTab`) is the only thing that knows the model
/// list, warmup progress and bot-binding lock, and it only exists while the
/// chat screen is mounted. This widget never talks to it directly - it only
/// reads the [ChatModelPickerState] snapshot the session publishes to
/// [AppState], so it renders the same "nothing mounted yet" empty state
/// whether that's because the user is on another module or because the chat
/// screen just started loading. Folders themselves ([AppState.modelFolders])
/// used to hold cloud models only; local (engine) entries can be filed the
/// same way now, and the flat section underneath is what's left unfiled.
class SidebarModelPanel extends StatefulWidget {
  const SidebarModelPanel({
    super.key,
    required this.appState,
    required this.collapsedFolders,
  });

  final AppState appState;

  /// Folder ids the user collapsed. Empty by default, i.e. every folder
  /// starts expanded - the point of the sidebar view is seeing your models,
  /// not clicking through empty groups first.
  final Set<String> collapsedFolders;

  @override
  State<SidebarModelPanel> createState() => _SidebarModelPanelState();
}

class _SidebarModelPanelState extends State<SidebarModelPanel> {
  AppState get _appState => widget.appState;

  void _toggleFolder(String folderId) {
    setState(() {
      if (!widget.collapsedFolders.remove(folderId)) {
        widget.collapsedFolders.add(folderId);
      }
    });
  }

  Future<void> _showFolderDialog({ModelFolder? existing}) async {
    final result = await showDialog<_FolderEditorResult>(
      context: context,
      builder: (_) => _FolderEditorDialog(existing: existing),
    );
    if (result == null) return;
    if (existing == null) {
      _appState.createModelFolder(result.name, result.color);
    } else {
      _appState.renameAndRecolorFolder(existing.id, result.name, result.color);
    }
  }

  Future<void> _confirmDeleteFolder(ModelFolder folder) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: CulpeoColors.panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CulpeoLayout.cardRadius),
          side: BorderSide(color: CulpeoColors.hairlineStrong),
        ),
        title: Text(
          tr('chatAux.modelFolder.deleteTitle'),
          style: TextStyle(
            color: CulpeoColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          tr('chatAux.modelFolder.deleteBody', {'name': folder.name}),
          style: TextStyle(color: CulpeoColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: CulpeoColors.textMuted,
            ),
            child: Text(tr('common.cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: CulpeoColors.danger),
            child: Text(tr('common.delete')),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      _appState.deleteModelFolder(folder.id);
      widget.collapsedFolders.remove(folder.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _appState,
      builder: (context, _) {
        final state = _appState.chatModelPicker;
        return Padding(
          key: const ValueKey('sidebar-models'),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 19),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  tr('sidebar.models').toUpperCase(),
                  style: AppFonts.mono(
                    fontSize: 9,
                    color: CulpeoColors.textFaint,
                    letterSpacing: 1.6,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(child: _body(state)),
              if (state != null) _actions(state),
              const SizedBox(height: 6),
            ],
          ),
        );
      },
    );
  }

  Widget _body(ChatModelPickerState? state) {
    if (state == null) {
      return _EmptyState(label: tr('chatAux.sidebarModel.notReady'));
    }
    if (state.locked) {
      return _LockedState(reason: state.lockedReason ?? '');
    }

    final folders = _appState.modelFolders;
    final byRef = {for (final entry in state.entries) _folderRef(entry): entry};
    final filed = {for (final folder in folders) ...folder.modelIds};
    // Local models start outside the folders and can be dragged in like any
    // other; this section is whatever is still loose.
    final local = state.entries
        .where((e) => e.isLocal && !filed.contains(_folderRef(e)))
        .toList();

    return ListView(
      key: const Key('sidebar-model-list'),
      padding: EdgeInsets.zero,
      children: [
        // The warmup row tracks a model that is starting up, independent of
        // whether the rest of the list is still loading, empty or errored.
        if (state.warmupActive) _WarmupRow(state: state),
        if (state.loading && state.entries.isEmpty)
          _EmptyState(label: tr('chatAux.modelPicker.searching'))
        else if (state.error != null)
          _EmptyState(label: state.error!, isError: true)
        else if (state.entries.isEmpty)
          _EmptyState(label: tr('chatAux.modelPicker.noneAvailable'))
        else ...[
          _ActionRow(
            key: const Key('sidebar-model-new-folder'),
            icon: Icons.create_new_folder_outlined,
            label: tr('chatHistory.newFolder'),
            onTap: () => _showFolderDialog(),
          ),
          const SizedBox(height: 4),
          Divider(height: 1, color: CulpeoColors.hairline),
          for (final folder in folders)
            _FolderSection(
              key: ValueKey('sidebar-model-folder-${folder.id}'),
              folder: folder,
              entries: [
                for (final modelId in folder.modelIds)
                  if (byRef[modelId] != null) byRef[modelId]!,
              ],
              collapsed: widget.collapsedFolders.contains(folder.id),
              selectedKey: state.selectedKey,
              folders: folders,
              onToggle: () => _toggleFolder(folder.id),
              onEdit: () => _showFolderDialog(existing: folder),
              onDelete: folder.id == 'general'
                  ? null
                  : () => _confirmDeleteFolder(folder),
              onSelect: state.onSelect,
              onMove: _appState.moveModelToFolder,
              onReorder: (oldIndex, newIndex) =>
                  _appState.reorderModelInFolder(folder.id, oldIndex, newIndex),
            ),
          if (local.isNotEmpty) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 4, 6, 2),
              child: Text(
                tr('chatAux.modelFolder.local'),
                style: AppFonts.mono(
                  fontSize: 9,
                  color: CulpeoColors.textFaint,
                  letterSpacing: 1.6,
                ),
              ),
            ),
            for (final entry in local)
              _ModelRow(
                key: ValueKey('sidebar-model-row-${entry.stableKey}'),
                entry: entry,
                selected: entry.stableKey == state.selectedKey,
                onTap: entry.selectable
                    ? () => state.onSelect(entry.stableKey)
                    : null,
                dragRef: _folderRef(entry),
                trailing: _MoveMenu(
                  entry: entry,
                  folders: folders,
                  currentFolderId: null,
                  onMove: _appState.moveModelToFolder,
                ),
              ),
          ],
        ],
      ],
    );
  }

  Widget _actions(ChatModelPickerState state) {
    return Column(
      children: [
        const SizedBox(height: 4),
        Divider(height: 1, color: CulpeoColors.hairline),
        const SizedBox(height: 4),
        _ActionRow(
          icon: Icons.refresh_rounded,
          label: tr('chatAux.sidebarModel.refresh'),
          onTap: state.onRefresh,
        ),
        _ActionRow(
          icon: Icons.memory_outlined,
          label: tr('chatAux.sidebarModel.openEngine'),
          onTap: state.onOpenEngine,
        ),
      ],
    );
  }
}

/// How a folder refers to a model. Cloud entries publish
/// `stableKey = 'cloud:$modelRef'` and folders (an older, AppState-level
/// feature this panel now surfaces inline) have always keyed those by the
/// bare modelRef, so that stays as it is. Local entries never had a place
/// in a folder before and keep their whole `local:$instanceId` key, which a
/// cloud modelRef can't collide with.
String _folderRef(ChatModelPickerEntry entry) => entry.isLocal
    ? entry.stableKey
    : entry.stableKey.substring('cloud:'.length);

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.label, this.isError = false});

  final String label;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
      child: Text(
        label,
        style: TextStyle(
          color: isError ? CulpeoColors.danger : CulpeoColors.textFaint,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _LockedState extends StatelessWidget {
  const _LockedState({required this.reason});

  final String reason;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(CulpeoLayout.cardPadding),
        decoration: BoxDecoration(
          color: CulpeoColors.inset,
          borderRadius: BorderRadius.circular(CulpeoLayout.pillRadius),
          border: Border.all(color: CulpeoColors.hairline),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.lock_outline_rounded,
              size: 15,
              color: CulpeoColors.textMuted,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                reason,
                style: TextStyle(color: CulpeoColors.textMuted, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WarmupRow extends StatelessWidget {
  const _WarmupRow({required this.state});

  final ChatModelPickerState state;

  @override
  Widget build(BuildContext context) {
    final percent = (state.warmupProgress * 100).clamp(0, 100).round();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(CulpeoLayout.cardPadding),
      decoration: BoxDecoration(
        color: CulpeoColors.actionMuted,
        borderRadius: BorderRadius.circular(CulpeoLayout.pillRadius),
        border: Border.all(color: CulpeoColors.actionBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 13,
                height: 13,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: CulpeoColors.action,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  state.warmupMessage.isEmpty
                      ? '$percent%'
                      : '${state.warmupMessage} · $percent%',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: CulpeoColors.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              GestureDetector(
                onTap: state.onCancelWarmup,
                child: Text(
                  tr('chatAux.sidebarModel.warmupCancel'),
                  style: TextStyle(
                    color: CulpeoColors.textMuted,
                    fontSize: 11,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: state.warmupProgress.clamp(0.0, 1.0),
              minHeight: 3,
              backgroundColor: CulpeoColors.hairlineStrong,
              valueColor: AlwaysStoppedAnimation(CulpeoColors.action),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModelRow extends StatefulWidget {
  const _ModelRow({
    super.key,
    required this.entry,
    required this.selected,
    this.onTap,
    this.dragRef,
    this.trailing,
  });

  final ChatModelPickerEntry entry;
  final bool selected;
  final VoidCallback? onTap;

  /// The model ref folders key by. Set on rows that live in a folder, which
  /// makes the row's label area draggable onto another folder; local models
  /// don't belong to folders and leave it null.
  final String? dragRef;

  /// Extra controls appended after the selected checkmark - the reorder
  /// handle and move-to-folder menu a row gets once it lives inside a
  /// folder.
  final Widget? trailing;

  @override
  State<_ModelRow> createState() => _ModelRowState();
}

class _ModelRowState extends State<_ModelRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final disabled = widget.onTap == null;
    final iconColor = widget.selected
        ? CulpeoColors.action
        : disabled
        ? CulpeoColors.textFaint
        : CulpeoColors.textMuted;

    return MouseRegion(
      cursor: disabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: widget.selected
                ? CulpeoColors.actionMuted
                : _hovered
                ? CulpeoColors.hairline
                : Colors.transparent,
            borderRadius: BorderRadius.circular(CulpeoLayout.pillRadius),
            border: Border.all(
              color: widget.selected
                  ? CulpeoColors.actionBorder
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              // The label area is what you pick up to file the model in
              // another folder; the controls after it keep their own
              // gestures, so the two never fight over a pointer.
              Expanded(
                child: _DragToFolder(
                  modelRef: widget.dragRef,
                  label: entry.label,
                  child: Row(
                    children: [
                      Icon(
                        entry.isLocal
                            ? Icons.memory_outlined
                            : Icons.cloud_outlined,
                        size: 15,
                        color: iconColor,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              entry.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: disabled
                                    ? CulpeoColors.textFaint
                                    : widget.selected
                                    ? CulpeoColors.textPrimary
                                    : CulpeoColors.textSecondary,
                                fontSize: 12,
                                fontWeight: widget.selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                            Text(
                              entry.placementLabel.isEmpty
                                  ? entry.subtitle
                                  : '${entry.subtitle} • '
                                        '${entry.placementLabel}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: CulpeoColors.textFaint,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (widget.selected)
                Icon(Icons.check, size: 15, color: CulpeoColors.action),
              if (widget.trailing != null) widget.trailing!,
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionRow extends StatefulWidget {
  const _ActionRow({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  State<_ActionRow> createState() => _ActionRowState();
}

class _ActionRowState extends State<_ActionRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: 32,
          margin: const EdgeInsets.symmetric(vertical: 1),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: _hovered ? CulpeoColors.hairline : Colors.transparent,
            borderRadius: BorderRadius.circular(CulpeoLayout.pillRadius),
          ),
          child: Row(
            children: [
              Icon(widget.icon, size: 14, color: CulpeoColors.textSecondary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: CulpeoColors.textSecondary,
                    fontSize: 12,
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

/// A folder header plus, when expanded, its models in a small reorderable
/// list of their own. The header never moves - only the panel's "+ Neuer
/// Ordner" action and [AppState.reorderModelFolders] (still available to
/// whatever else calls it) change folder order; this compact view only
/// exposes reordering *within* a folder, which is what "sortieren" is
/// actually about day to day.
class _FolderSection extends StatelessWidget {
  const _FolderSection({
    super.key,
    required this.folder,
    required this.entries,
    required this.collapsed,
    required this.selectedKey,
    required this.folders,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
    required this.onSelect,
    required this.onMove,
    required this.onReorder,
  });

  final ModelFolder folder;
  final List<ChatModelPickerEntry> entries;
  final bool collapsed;
  final String? selectedKey;
  final List<ModelFolder> folders;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;
  final ValueChanged<String> onSelect;

  /// `(modelRef, targetFolderId)` - AppState.moveModelToFolder itself.
  final void Function(String modelRef, String targetFolderId) onMove;
  final void Function(int oldIndex, int newIndex) onReorder;

  @override
  Widget build(BuildContext context) {
    // Anywhere on the section takes a drop - the header, the rows under it,
    // the "no models" line. Dropping a model back into the folder it's
    // already in is a no-op the target simply doesn't accept.
    return DragTarget<String>(
      onWillAcceptWithDetails: (details) =>
          !folder.modelIds.contains(details.data),
      onAcceptWithDetails: (details) => onMove(details.data, folder.id),
      builder: (context, candidateData, rejectedData) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FolderHeader(
            folder: folder,
            collapsed: collapsed,
            modelCount: entries.length,
            onToggle: onToggle,
            onEdit: onEdit,
            onDelete: onDelete,
            isDropTarget: candidateData.isNotEmpty,
          ),
          if (!collapsed)
            entries.isEmpty
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(30, 2, 10, 6),
                    child: Text(
                      tr('chatAux.modelManagement.noModels'),
                      style: TextStyle(
                        color: CulpeoColors.textFaint,
                        fontSize: 11,
                      ),
                    ),
                  )
                : ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(left: 20),
                    buildDefaultDragHandles: false,
                    itemCount: entries.length,
                    onReorderItem: onReorder,
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      return _ModelRow(
                        key: ValueKey('sidebar-model-row-${entry.stableKey}'),
                        entry: entry,
                        selected: entry.stableKey == selectedKey,
                        onTap: entry.selectable
                            ? () => onSelect(entry.stableKey)
                            : null,
                        dragRef: _folderRef(entry),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _ReorderHandle(
                              key: Key(
                                'sidebar-model-drag-handle-${entry.stableKey}',
                              ),
                              index: index,
                            ),
                            _MoveMenu(
                              entry: entry,
                              folders: folders,
                              currentFolderId: folder.id,
                              onMove: onMove,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
        ],
      ),
    );
  }
}

/// Picking a model up and dropping it on a folder is the obvious way to
/// file it, so the row's own label area is the drag - not a handle on it.
/// Sorting *within* a folder is the rarer move and gets the explicit
/// [_ReorderHandle] instead, which sits beside this widget rather than
/// inside it so the two drags never compete for the same pointer.
///
/// A null [modelRef] means the row isn't in a folder to begin with (local
/// models), and the child is passed through undragged.
class _DragToFolder extends StatelessWidget {
  const _DragToFolder({
    required this.modelRef,
    required this.label,
    required this.child,
  });

  final String? modelRef;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ref = modelRef;
    if (ref == null) return child;

    final feedback = Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: CulpeoColors.panel,
          borderRadius: BorderRadius.circular(CulpeoLayout.pillRadius),
          border: Border.all(color: CulpeoColors.actionBorder),
        ),
        child: Text(
          label,
          style: TextStyle(color: CulpeoColors.textPrimary, fontSize: 12),
        ),
      ),
    );
    final ghost = Opacity(opacity: 0.3, child: child);

    // Touch keeps its long-press delay so a scroll flick doesn't pick a row
    // up; on desktop the drag starts on the first movement.
    switch (Theme.of(context).platform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.fuchsia:
        return LongPressDraggable<String>(
          data: ref,
          feedback: feedback,
          childWhenDragging: ghost,
          child: child,
        );
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        return Draggable<String>(
          data: ref,
          feedback: feedback,
          childWhenDragging: ghost,
          child: MouseRegion(cursor: SystemMouseCursors.grab, child: child),
        );
    }
  }
}

/// Sorts a model inside its own folder. Same delayed-drag-on-touch,
/// immediate-drag-on-desktop split as the module list in the sidebar - see
/// dashboard_screen.dart's `_ModuleDragArea`.
class _ReorderHandle extends StatelessWidget {
  const _ReorderHandle({super.key, required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final grip = MouseRegion(
      cursor: SystemMouseCursors.grab,
      child: Tooltip(
        message: tr('chatAux.modelManagement.reorder'),
        // A tooltip that opens on long press would take the pointer away
        // from the delayed drag below on touch, and the grip would do
        // nothing. Hovering still shows it, which is the desktop case.
        triggerMode: TooltipTriggerMode.manual,
        child: Icon(
          Icons.drag_indicator,
          size: 14,
          color: CulpeoColors.textFaint,
        ),
      ),
    );

    switch (Theme.of(context).platform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.fuchsia:
        return ReorderableDelayedDragStartListener(index: index, child: grip);
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        return ReorderableDragStartListener(index: index, child: grip);
    }
  }
}

class _MoveMenu extends StatelessWidget {
  const _MoveMenu({
    required this.entry,
    required this.folders,
    required this.currentFolderId,
    required this.onMove,
  });

  final ChatModelPickerEntry entry;
  final List<ModelFolder> folders;

  /// Null for a model that isn't in any folder yet, i.e. every folder is
  /// offered as a target.
  final String? currentFolderId;
  final void Function(String modelRef, String targetFolderId) onMove;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      key: Key('sidebar-model-move-${entry.stableKey}'),
      tooltip: tr('chatAux.modelManagement.moveToFolder'),
      color: CulpeoColors.panel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CulpeoLayout.cardRadius),
        side: BorderSide(color: CulpeoColors.hairlineStrong),
      ),
      iconSize: 15,
      splashRadius: 16,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 180, maxWidth: 240),
      icon: Icon(
        Icons.drive_file_move_outlined,
        size: 15,
        color: CulpeoColors.textFaint,
      ),
      onSelected: (folderId) => onMove(_folderRef(entry), folderId),
      itemBuilder: (context) => [
        for (final target in folders)
          if (target.id != currentFolderId)
            PopupMenuItem<String>(
              value: target.id,
              height: 36,
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: target.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      target.name,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: CulpeoColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
      ],
    );
  }
}

class _FolderHeader extends StatefulWidget {
  const _FolderHeader({
    required this.folder,
    required this.collapsed,
    required this.modelCount,
    required this.onToggle,
    required this.onEdit,
    this.onDelete,
    this.isDropTarget = false,
  });

  final ModelFolder folder;
  final bool collapsed;
  final int modelCount;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  /// True while a compatible model is being dragged over this header.
  final bool isDropTarget;

  @override
  State<_FolderHeader> createState() => _FolderHeaderState();
}

class _FolderHeaderState extends State<_FolderHeader> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.folder.color;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        height: 34,
        margin: const EdgeInsets.symmetric(vertical: 1),
        decoration: BoxDecoration(
          color: widget.isDropTarget
              ? color.withValues(alpha: 0.16)
              : _hovered
              ? CulpeoColors.hairline
              : Colors.transparent,
          borderRadius: BorderRadius.circular(CulpeoLayout.pillRadius),
          border: Border.all(
            color: widget.isDropTarget ? color : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onToggle,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Icon(
                    widget.collapsed
                        ? Icons.folder_outlined
                        : Icons.folder_open,
                    size: 15,
                    color: color,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onToggle,
                child: Text(
                  widget.folder.name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: CulpeoColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            if (widget.modelCount > 0)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  '${widget.modelCount}',
                  style: TextStyle(color: CulpeoColors.textFaint, fontSize: 11),
                ),
              ),
            AnimatedOpacity(
              opacity: _hovered ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 120),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _HeaderIconButton(
                    tooltip: tr('chatAux.modelFolder.edit'),
                    icon: Icons.edit_outlined,
                    onPressed: widget.onEdit,
                  ),
                  if (widget.onDelete != null)
                    _HeaderIconButton(
                      tooltip: tr('common.delete'),
                      icon: Icons.delete_outline,
                      onPressed: widget.onDelete!,
                    ),
                ],
              ),
            ),
            AnimatedRotation(
              turns: widget.collapsed ? 0 : 0.25,
              duration: const Duration(milliseconds: 180),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: CulpeoColors.textFaint,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      icon: Icon(icon, size: 14),
      color: CulpeoColors.textFaint,
      splashRadius: 15,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      onPressed: onPressed,
    );
  }
}

class _FolderEditorResult {
  const _FolderEditorResult(this.name, this.color);

  final String name;
  final Color color;
}

class _FolderEditorDialog extends StatefulWidget {
  const _FolderEditorDialog({this.existing});

  final ModelFolder? existing;

  @override
  State<_FolderEditorDialog> createState() => _FolderEditorDialogState();
}

class _FolderEditorDialogState extends State<_FolderEditorDialog> {
  late final TextEditingController _controller;
  late Color _selectedColor;
  String? _nameError;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.existing?.name ?? '');
    _selectedColor = widget.existing?.color ?? kProjectColorChoices.first;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = tr('chatAux.modelFolder.nameError'));
      return;
    }
    Navigator.of(context).pop(_FolderEditorResult(name, _selectedColor));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: CulpeoColors.panel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CulpeoLayout.cardRadius),
        side: BorderSide(color: CulpeoColors.hairlineStrong),
      ),
      title: Text(
        tr(
          _isEdit
              ? 'chatAux.modelFolder.titleEdit'
              : 'chatAux.modelFolder.titleNew',
        ),
        style: TextStyle(
          color: CulpeoColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              key: const Key('model-folder-name-field'),
              controller: _controller,
              autofocus: true,
              style: TextStyle(color: CulpeoColors.textPrimary, fontSize: 14),
              cursorColor: CulpeoColors.action,
              decoration: InputDecoration(
                hintText: tr('chatAux.modelFolder.nameHint'),
                hintStyle: TextStyle(
                  color: CulpeoColors.textFaint,
                  fontSize: 14,
                ),
                errorText: _nameError,
                errorStyle: TextStyle(color: CulpeoColors.danger, fontSize: 11),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: CulpeoColors.hairlineStrong),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: CulpeoColors.action),
                ),
              ),
              onChanged: (_) {
                if (_nameError != null) setState(() => _nameError = null);
              },
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 18),
            Text(
              tr('chatAux.modelFolder.colorLabel'),
              style: AppFonts.mono(
                fontSize: 9,
                color: CulpeoColors.textFaint,
                letterSpacing: 1.6,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final color in kProjectColorChoices)
                  GestureDetector(
                    key: Key('model-folder-color-${color.toARGB32()}'),
                    onTap: () => setState(() => _selectedColor = color),
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _selectedColor == color
                              ? CulpeoColors.textPrimary
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: _selectedColor == color
                          ? Icon(
                              Icons.check,
                              size: 15,
                              color: CulpeoColors.textPrimary,
                            )
                          : null,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(foregroundColor: CulpeoColors.textMuted),
          child: Text(tr('chatHistory.projectDialog.cancel')),
        ),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(
            backgroundColor: CulpeoColors.action,
            foregroundColor: CulpeoColors.textPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(CulpeoLayout.pillRadius),
            ),
          ),
          child: Text(
            tr(
              _isEdit
                  ? 'chatHistory.projectDialog.save'
                  : 'chatHistory.projectDialog.create',
            ),
          ),
        ),
      ],
    );
  }
}
