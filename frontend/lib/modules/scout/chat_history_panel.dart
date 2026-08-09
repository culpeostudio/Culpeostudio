import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/design_tokens.dart';

import './chat_aux_strings.dart';
import '../../core/app_state.dart';
import '../../core/app_theme.dart';

/// Auswählen und Anlegen sind Handlungen, also Rost. Gold bleibt den
/// Messwerten der Engine vorbehalten — siehe [CulpeoColors].
const Color kChatAccent = CulpeoColors.action;

const List<Color> kProjectColorChoices = [
  CulpeoColors.action,
  Color(0xFF6E8FE0),
  Color(0xFF7BAE7F),
  Color(0xFFA98BD4),
  Color(0xFFD97B7B),
  Color(0xFF62B5AB),
];

Color chatProjectColor(ChatProject? project) {
  final raw = project?.color;
  if (raw != null) {
    final hex = raw.replaceAll('#', '').trim();
    final value = int.tryParse(hex, radix: 16);
    if (value != null) {
      return Color(hex.length == 6 ? (0xFF000000 | value) : value);
    }
  }
  return kChatAccent;
}

Color chatSubfolderColor(ChatSubfolder? subfolder) {
  final raw = subfolder?.color;
  if (raw != null) {
    final hex = raw.replaceAll('#', '').trim();
    final value = int.tryParse(hex, radix: 16);
    if (value != null) {
      return Color(hex.length == 6 ? (0xFF000000 | value) : value);
    }
  }
  return kChatAccent;
}

const Map<String, IconData> kChatProjectIcons = {
  'folder': Icons.folder_outlined,
  'code': Icons.code_rounded,
  'work': Icons.work_outline_rounded,
  'school': Icons.school_outlined,
  'science': Icons.science_outlined,
  'book': Icons.menu_book_outlined,
  'brush': Icons.brush_outlined,
  'music': Icons.music_note_outlined,
  'star': Icons.star_outline_rounded,
  'bug': Icons.bug_report_outlined,
  'shopping': Icons.shopping_bag_outlined,
  'travel': Icons.flight_outlined,
  'home': Icons.home_outlined,
  'person': Icons.person_outline_rounded,
  'settings': Icons.settings_outlined,
  'cloud': Icons.cloud_outlined,
  'database': Icons.storage_outlined,
  'security': Icons.security_outlined,
  'analytics': Icons.analytics_outlined,
  'design': Icons.palette_outlined,
  'video': Icons.videocam_outlined,
  'audio': Icons.audiotrack_outlined,
  'image': Icons.image_outlined,
  'link': Icons.link_outlined,
  'lock': Icons.lock_outline_rounded,
  'key': Icons.vpn_key_outlined,
  'terminal': Icons.terminal_outlined,
  'server': Icons.dns_outlined,
  'api': Icons.api_outlined,
  'web': Icons.web_outlined,
  'mobile': Icons.phone_android_outlined,
  'desktop': Icons.desktop_mac_outlined,
  'game': Icons.sports_esports_outlined,
  'ai': Icons.psychology_outlined,
  'robot': Icons.smart_toy_outlined,
  'lightbulb': Icons.lightbulb_outlined,
  'target': Icons.flag_outlined,
  'calendar': Icons.calendar_today_outlined,
  'email': Icons.email_outlined,
  'chat': Icons.chat_bubble_outline_rounded,
  'phone': Icons.phone_outlined,
  'map': Icons.map_outlined,
  'location': Icons.location_on_outlined,
  'heart': Icons.favorite_outline_rounded,
  'medical': Icons.medical_services_outlined,
  'fitness': Icons.fitness_center_outlined,
  'food': Icons.restaurant_outlined,
  'coffee': Icons.coffee_outlined,
  'car': Icons.directions_car_outlined,
  'bike': Icons.directions_bike_outlined,
};

/// Alle Fenster dieses Panels tragen denselben Rahmen wie die Karten der
/// übrigen Module.
final RoundedRectangleBorder _dialogShape = RoundedRectangleBorder(
  borderRadius: BorderRadius.circular(CulpeoLayout.cardRadius),
  side: BorderSide(color: CulpeoColors.hairlineStrong),
);

IconData chatProjectIcon(ChatProject? project) {
  final key = project?.icon;
  if (key != null && kChatProjectIcons.containsKey(key)) {
    return kChatProjectIcons[key]!;
  }
  return Icons.folder_outlined;
}

Future<void> promptRenameChatSession(
  BuildContext context,
  AppState appState,
  String sessionId,
) async {
  final controller = TextEditingController(
    text: appState.getSessionTitle(sessionId),
  );
  final newTitle = await showDialog<String>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: CulpeoColors.panel,
        shape: _dialogShape,
        title: Text(
          tr('chatHistory.rename.title'),
          style: TextStyle(
            color: CulpeoColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: CulpeoColors.textPrimary),
          cursorColor: CulpeoColors.action,
          decoration: InputDecoration(
            hintText: tr('chatHistory.rename.hint'),
            hintStyle: TextStyle(color: CulpeoColors.textFaint),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: CulpeoColors.hairlineStrong),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: CulpeoColors.action),
            ),
          ),
          onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            style: TextButton.styleFrom(
              foregroundColor: CulpeoColors.textMuted,
            ),
            child: Text(tr('chatHistory.rename.cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            style: TextButton.styleFrom(foregroundColor: CulpeoColors.action),
            child: Text(tr('chatHistory.rename.save')),
          ),
        ],
      );
    },
  );
  controller.dispose();
  if (newTitle != null && newTitle.trim().isNotEmpty) {
    appState.renameSession(sessionId, newTitle.trim());
  }
}

Future<void> confirmDeleteChatSession(
  BuildContext context,
  AppState appState,
  String sessionId, {
  required VoidCallback onNeedNewSession,
}) async {
  final title = appState.getSessionTitle(sessionId);
  final wasCurrent = appState.currentChatSessionId == sessionId;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: CulpeoColors.panel,
      shape: _dialogShape,
      title: Text(
        tr('chatHistory.delete.title'),
        style: TextStyle(
          color: CulpeoColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: Text(
        tr('chatHistory.delete.body', {'title': title}),
        style: TextStyle(color: CulpeoColors.textSecondary, fontSize: 13),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          style: TextButton.styleFrom(foregroundColor: CulpeoColors.textMuted),
          child: Text(tr('chatHistory.delete.cancel')),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: TextButton.styleFrom(foregroundColor: CulpeoColors.danger),
          child: Text(tr('chatHistory.delete.confirm')),
        ),
      ],
    ),
  );
  if (confirmed != true) return;
  appState.deleteSession(sessionId);
  if (wasCurrent && appState.currentChatSessionId == null) {
    onNeedNewSession();
  }
}

class ChatProjectBadge extends StatelessWidget {
  const ChatProjectBadge({super.key, required this.project});

  final ChatProject project;

  @override
  Widget build(BuildContext context) {
    final color = chatProjectColor(project);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: culpeoPillDecoration(color),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(chatProjectIcon(project), size: 11, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              project.name,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ChatHistoryPanel extends StatefulWidget {
  final AppState appState;
  final String? currentChatId;

  final Set<String> expandedProjects;

  /// Expanded subfolder ids, project-agnostic (ids are unique across the
  /// whole app) - same externally-owned-Set pattern as [expandedProjects],
  /// so it survives this widget being torn down and rebuilt.
  final Set<String> expandedSubfolders;

  final ValueChanged<String> onNewChatInProject;
  final ValueChanged<String> onSelectChat;
  final ValueChanged<String> onRenameChat;
  final ValueChanged<String> onDeleteChat;

  /// Max height of the inner list. When null the list fills the available
  /// space (used when the panel is rendered as a full-height sidebar column).
  final double? listMaxHeight;

  const ChatHistoryPanel({
    super.key,
    required this.appState,
    required this.currentChatId,
    required this.expandedProjects,
    required this.expandedSubfolders,
    required this.onNewChatInProject,
    required this.onSelectChat,
    required this.onRenameChat,
    required this.onDeleteChat,
    this.listMaxHeight = 340,
  });

  @override
  State<ChatHistoryPanel> createState() => _ChatHistoryPanelState();
}

class _ChatHistoryPanelState extends State<ChatHistoryPanel> {
  AppState get _appState => widget.appState;

  Future<void> _promptProjectDialog({ChatProject? existing}) async {
    final result = await showDialog<_ProjectEditorResult>(
      context: context,
      builder: (_) => _ProjectEditorDialog(existing: existing),
    );
    if (result == null) return;
    final hex =
        '#${result.color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
    if (existing == null) {
      final project = await _appState.createChatProject(
        result.name,
        color: hex,
        path: result.path,
        icon: result.icon,
      );
      if (project != null) {
        setState(() => widget.expandedProjects.add(project.id));
      }
    } else {
      await _appState.renameChatProject(
        existing.id,
        result.name,
        color: hex,
        path: result.path,
        icon: result.icon ?? '',
      );
    }
  }

  Future<void> _confirmDeleteProject(ChatProject project) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: CulpeoColors.panel,
        shape: _dialogShape,
        title: Text(
          tr('chatHistory.deleteProject.title'),
          style: TextStyle(
            color: CulpeoColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          tr('chatHistory.deleteProject.body', {'name': project.name}),
          style: TextStyle(color: CulpeoColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: CulpeoColors.textMuted,
            ),
            child: Text(tr('chatHistory.deleteProject.cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: CulpeoColors.danger),
            child: Text(tr('chatHistory.deleteProject.confirm')),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _appState.deleteChatProject(project.id);
    }
  }

  void _toggleProject(String projectId) {
    setState(() {
      if (!widget.expandedProjects.remove(projectId)) {
        widget.expandedProjects.add(projectId);
      }
    });
  }

  void _toggleSubfolder(String subfolderId) {
    setState(() {
      if (!widget.expandedSubfolders.remove(subfolderId)) {
        widget.expandedSubfolders.add(subfolderId);
      }
    });
  }

  Future<void> _promptSubfolderDialog(
    String projectId, {
    ChatSubfolder? existing,
  }) async {
    final result = await showDialog<_SubfolderEditorResult>(
      context: context,
      builder: (_) => _SubfolderEditorDialog(existing: existing),
    );
    if (result == null) return;
    final hex =
        '#${result.color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
    if (existing == null) {
      final folder = await _appState.createChatSubfolder(
        projectId,
        result.name,
        color: hex,
      );
      setState(() => widget.expandedSubfolders.add(folder.id));
    } else {
      await _appState.renameChatSubfolder(existing.id, result.name, color: hex);
    }
  }

  Future<void> _confirmDeleteSubfolder(ChatSubfolder subfolder) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: CulpeoColors.panel,
        shape: _dialogShape,
        title: Text(
          tr('chatHistory.deleteSubfolder.title'),
          style: TextStyle(
            color: CulpeoColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          tr('chatHistory.deleteSubfolder.body', {'name': subfolder.name}),
          style: TextStyle(color: CulpeoColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: CulpeoColors.textMuted,
            ),
            child: Text(tr('chatHistory.deleteProject.cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: CulpeoColors.danger),
            child: Text(tr('chatHistory.deleteProject.confirm')),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _appState.deleteChatSubfolder(subfolder.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _appState,
      builder: (context, _) {
        final projects = _appState.chatProjects;
        final projectIds = projects.map((p) => p.id).toSet();
        final unassigned = _appState.chatSessions.reversed.where((id) {
          final pid = _appState.projectIdForSession(id);
          return pid == null || !projectIds.contains(pid);
        }).toList();

        final panelList = ListView(
          key: const Key('chat-history-panel-list'),
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          children: [
            _PanelActionRow(
              key: const Key('chat-history-panel-new-project'),
              icon: Icons.create_new_folder_outlined,
              label: tr('chatHistory.newFolder'),
              onTap: () => _promptProjectDialog(),
            ),
            const SizedBox(height: 6),
            Divider(height: 1, color: CulpeoColors.hairline),
            const SizedBox(height: 6),
            if (projects.isNotEmpty) ...[
              _PanelSectionHeader(label: tr('chatHistory.sectionProjects')),
              for (final project in projects) ...[
                _ProjectRow(
                  key: Key('chat-history-project-${project.id}'),
                  project: project,
                  expanded: widget.expandedProjects.contains(project.id),
                  chatCount: _appState.sessionsInProject(project.id).length,
                  onToggle: () => _toggleProject(project.id),
                  onNewChat: () => widget.onNewChatInProject(project.id),
                  onRename: () => _promptProjectDialog(existing: project),
                  onDelete: () => _confirmDeleteProject(project),
                ),
                if (widget.expandedProjects.contains(project.id)) ...[
                  () {
                    final subfolders = _appState.subfoldersInProject(
                      project.id,
                    );
                    return Column(
                      children: [
                        _PanelActionRow(
                          key: Key(
                            'chat-history-project-new-subfolder-${project.id}',
                          ),
                          icon: Icons.create_new_folder_outlined,
                          label: tr('chatHistory.newSubfolder'),
                          indent: 20,
                          onTap: () => _promptSubfolderDialog(project.id),
                        ),
                        for (final subfolder in subfolders) ...[
                          _SubfolderRow(
                            key: Key('chat-history-subfolder-${subfolder.id}'),
                            subfolder: subfolder,
                            expanded: widget.expandedSubfolders.contains(
                              subfolder.id,
                            ),
                            chatCount: _appState
                                .sessionsInSubfolder(subfolder.id)
                                .length,
                            onToggle: () => _toggleSubfolder(subfolder.id),
                            onNewChat: () =>
                                widget.onNewChatInProject(project.id),
                            onRename: () => _promptSubfolderDialog(
                              project.id,
                              existing: subfolder,
                            ),
                            onDelete: () => _confirmDeleteSubfolder(subfolder),
                          ),
                          if (widget.expandedSubfolders.contains(subfolder.id))
                            for (final sessionId
                                in _appState
                                    .sessionsInSubfolder(subfolder.id)
                                    .reversed)
                              _ChatRow(
                                key: Key('chat-history-chat-$sessionId'),
                                sessionId: sessionId,
                                title: _appState.getSessionTitle(sessionId),
                                selected: sessionId == widget.currentChatId,
                                indent: 45,
                                projects: projects,
                                currentProjectId: project.id,
                                subfolders: subfolders,
                                currentSubfolderId: subfolder.id,
                                onSelect: () => widget.onSelectChat(sessionId),
                                onRename: () => widget.onRenameChat(sessionId),
                                onDelete: () => widget.onDeleteChat(sessionId),
                                onMove: (projectId) =>
                                    _appState.assignSessionToProject(
                                      sessionId,
                                      projectId,
                                    ),
                                onMoveToSubfolder: (subfolderId) =>
                                    _appState.assignSessionToSubfolder(
                                      sessionId,
                                      subfolderId,
                                    ),
                              ),
                        ],
                        for (final sessionId
                            in _appState
                                .sessionsDirectlyInProject(project.id)
                                .reversed)
                          _ChatRow(
                            key: Key('chat-history-chat-$sessionId'),
                            sessionId: sessionId,
                            title: _appState.getSessionTitle(sessionId),
                            selected: sessionId == widget.currentChatId,
                            indent: 30,
                            projects: projects,
                            currentProjectId: project.id,
                            subfolders: subfolders,
                            onSelect: () => widget.onSelectChat(sessionId),
                            onRename: () => widget.onRenameChat(sessionId),
                            onDelete: () => widget.onDeleteChat(sessionId),
                            onMove: (projectId) => _appState
                                .assignSessionToProject(sessionId, projectId),
                            onMoveToSubfolder: (subfolderId) =>
                                _appState.assignSessionToSubfolder(
                                  sessionId,
                                  subfolderId,
                                ),
                          ),
                      ],
                    );
                  }(),
                ],
              ],
            ],
            if (unassigned.isNotEmpty) ...[
              _PanelSectionHeader(
                label: tr(
                  projects.isEmpty
                      ? 'chatHistory.sectionHistory'
                      : 'chatHistory.sectionChats',
                ),
              ),
              for (final sessionId in unassigned)
                _ChatRow(
                  key: Key('chat-history-chat-$sessionId'),
                  sessionId: sessionId,
                  title: _appState.getSessionTitle(sessionId),
                  selected: sessionId == widget.currentChatId,
                  indent: 0,
                  projects: projects,
                  currentProjectId: null,
                  onSelect: () => widget.onSelectChat(sessionId),
                  onRename: () => widget.onRenameChat(sessionId),
                  onDelete: () => widget.onDeleteChat(sessionId),
                  onMove: (projectId) =>
                      _appState.assignSessionToProject(sessionId, projectId),
                ),
            ],
            if (projects.isEmpty && unassigned.isEmpty)
              Padding(
                padding: EdgeInsets.fromLTRB(14, 10, 14, 12),
                child: Text(
                  tr('chatHistory.empty'),
                  style: TextStyle(color: CulpeoColors.textFaint, fontSize: 12),
                ),
              ),
          ],
        );

        final maxHeight = widget.listMaxHeight;
        if (maxHeight == null) return panelList;
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: panelList,
        );
      },
    );
  }
}

class _ProjectEditorResult {
  const _ProjectEditorResult(this.name, this.color, this.path, this.icon);

  final String name;
  final Color color;
  final String? path;
  final String? icon;
}

class _ProjectEditorDialog extends StatefulWidget {
  const _ProjectEditorDialog({this.existing});

  final ChatProject? existing;

  @override
  State<_ProjectEditorDialog> createState() => _ProjectEditorDialogState();
}

class _ProjectEditorDialogState extends State<_ProjectEditorDialog> {
  late final TextEditingController _controller;
  late final TextEditingController _pathController;
  late Color _selectedColor;
  late String? _selectedIcon;
  late bool _hasPath;

  String? _nameError;
  String? _pathError;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.existing?.name ?? '');
    _pathController = TextEditingController(text: widget.existing?.path ?? '');
    _selectedColor = widget.existing != null
        ? chatProjectColor(widget.existing)
        : kProjectColorChoices.first;
    final existingIcon = widget.existing?.icon;
    _selectedIcon =
        existingIcon != null && kChatProjectIcons.containsKey(existingIcon)
        ? existingIcon
        : null;
    _hasPath = (widget.existing?.path ?? '').isNotEmpty;
  }

  @override
  void dispose() {
    _controller.dispose();
    _pathController.dispose();
    super.dispose();
  }

  Future<void> _browseProjectPath() async {
    try {
      final selected = await FilePicker.getDirectoryPath(
        dialogTitle: tr('chatHistory.projectDialog.browseTitle'),
      );
      if (selected != null && selected.trim().isNotEmpty && mounted) {
        setState(() {
          _pathController.text = selected;
          _pathError = null;
        });
      }
    } catch (_) {}
  }

  void _submit() {
    final name = _controller.text.trim();
    final path = _hasPath ? _pathController.text.trim() : '';
    final nameError = name.isEmpty
        ? tr('chatHistory.projectDialog.nameError')
        : null;
    final pathError = _hasPath && path.isEmpty
        ? tr('chatHistory.projectDialog.pathError')
        : null;
    if (nameError != null || pathError != null) {
      setState(() {
        _nameError = nameError;
        _pathError = pathError;
      });
      return;
    }
    Navigator.of(context).pop(
      _ProjectEditorResult(
        name,
        _selectedColor,
        path.isEmpty ? null : path,
        _selectedIcon,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: CulpeoColors.panel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CulpeoLayout.cardRadius),
        side: BorderSide(color: CulpeoColors.hairlineStrong),
      ),
      titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      actionsPadding: const EdgeInsets.fromLTRB(20, 12, 16, 14),
      title: _title(),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _nameField(),
              const SizedBox(height: 18),
              _sectionLabel(tr('chatHistory.projectDialog.colorLabel')),
              const SizedBox(height: 10),
              _colorChoices(),
              const SizedBox(height: 18),
              _sectionLabel(tr('chatHistory.projectDialog.iconLabel')),
              const SizedBox(height: 10),
              _iconChoices(),
              const SizedBox(height: 14),
              _pathToggle(),
              if (_hasPath) ...[const SizedBox(height: 4), _pathField()],
            ],
          ),
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

  /// Zeigt neben dem Titel, wie der Ordner in der Liste aussehen wird. Farbe
  /// und Symbol lassen sich sonst nur erahnen, bis das Fenster zu ist.
  Widget _title() {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: _selectedColor.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(CulpeoLayout.pillRadius),
            border: Border.all(color: _selectedColor.withValues(alpha: 0.34)),
          ),
          child: Icon(
            _selectedIcon == null
                ? Icons.folder_outlined
                : kChatProjectIcons[_selectedIcon]!,
            size: 17,
            color: _selectedColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            tr(
              _isEdit
                  ? 'chatHistory.projectDialog.titleEdit'
                  : 'chatHistory.projectDialog.titleNew',
            ),
            style: TextStyle(
              color: CulpeoColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: AppFonts.mono(
        fontSize: 9,
        color: CulpeoColors.textFaint,
        letterSpacing: 1.6,
      ),
    );
  }

  Widget _nameField() {
    return TextField(
      key: const Key('project-name-field'),
      controller: _controller,
      autofocus: true,
      style: TextStyle(color: CulpeoColors.textPrimary, fontSize: 14),
      cursorColor: CulpeoColors.action,
      decoration: InputDecoration(
        hintText: tr('chatHistory.projectDialog.nameHint'),
        hintStyle: TextStyle(color: CulpeoColors.textFaint, fontSize: 14),
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
    );
  }

  Widget _colorChoices() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final color in kProjectColorChoices)
          _ChoiceTile(
            selected: _selectedColor == color,
            onTap: () => setState(() => _selectedColor = color),
            size: 26,
            circle: true,
            fill: color,
            child: _selectedColor == color
                ? Icon(Icons.check, size: 15, color: CulpeoColors.textPrimary)
                : null,
          ),
      ],
    );
  }

  /// Die Symbolliste ist lang. Sie bekommt eine feste Höhe und scrollt in sich,
  /// damit das Formular nicht auf drei Bildschirmhöhen wächst.
  Widget _iconChoices() {
    return Container(
      height: 132,
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: CulpeoColors.inset,
        borderRadius: BorderRadius.circular(CulpeoLayout.pillRadius),
        border: Border.all(color: CulpeoColors.hairline),
      ),
      child: Scrollbar(
        child: SingleChildScrollView(
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final entry in kChatProjectIcons.entries)
                _ChoiceTile(
                  selected: _selectedIcon == entry.key,
                  onTap: () => setState(
                    () => _selectedIcon = _selectedIcon == entry.key
                        ? null
                        : entry.key,
                  ),
                  size: 34,
                  fill: _selectedIcon == entry.key
                      ? _selectedColor.withValues(alpha: 0.16)
                      : Colors.transparent,
                  border: _selectedIcon == entry.key
                      ? _selectedColor.withValues(alpha: 0.5)
                      : CulpeoColors.hairline,
                  child: Icon(
                    entry.value,
                    size: 17,
                    color: _selectedIcon == entry.key
                        ? _selectedColor
                        : CulpeoColors.textMuted,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pathToggle() {
    return InkWell(
      key: const Key('project-path-toggle'),
      onTap: () => setState(() => _hasPath = !_hasPath),
      borderRadius: BorderRadius.circular(CulpeoLayout.pillRadius),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: Checkbox(
                value: _hasPath,
                onChanged: (value) => setState(() => _hasPath = value ?? false),
                activeColor: CulpeoColors.action,
                checkColor: CulpeoColors.textPrimary,
                visualDensity: VisualDensity.compact,
                side: BorderSide(
                  color: CulpeoColors.hairlineStrong,
                  width: 1.5,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                tr('chatHistory.projectDialog.pathToggle'),
                style: TextStyle(
                  color: CulpeoColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pathField() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: TextField(
            key: const Key('project-path-field'),
            controller: _pathController,
            autofocus: true,
            style: TextStyle(color: CulpeoColors.textPrimary, fontSize: 13),
            cursorColor: CulpeoColors.action,
            decoration: InputDecoration(
              hintText: tr('chatHistory.projectDialog.pathHint'),
              hintStyle: TextStyle(color: CulpeoColors.textFaint, fontSize: 13),
              errorText: _pathError,
              errorStyle: TextStyle(color: CulpeoColors.danger, fontSize: 11),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: CulpeoColors.hairlineStrong),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: CulpeoColors.action),
              ),
            ),
            onChanged: (_) {
              if (_pathError != null) {
                setState(() => _pathError = null);
              }
            },
            onSubmitted: (_) => _submit(),
          ),
        ),
        const SizedBox(width: 10),
        OutlinedButton.icon(
          key: const Key('project-path-browse'),
          onPressed: _browseProjectPath,
          icon: const Icon(Icons.folder_open_rounded, size: 16),
          label: Text(tr('chatHistory.projectDialog.browse')),
          style: OutlinedButton.styleFrom(
            foregroundColor: CulpeoColors.action,
            side: BorderSide(color: CulpeoColors.hairlineStrong),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(CulpeoLayout.pillRadius),
            ),
          ),
        ),
      ],
    );
  }
}

/// Ein anklickbares Kästchen für Farbe oder Symbol. Beide Reihen im Dialog
/// verhalten sich gleich, also gibt es sie nur einmal.
class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.selected,
    required this.onTap,
    required this.size,
    required this.fill,
    this.border,
    this.circle = false,
    this.child,
  });

  final bool selected;
  final VoidCallback onTap;
  final double size;
  final Color fill;
  final Color? border;
  final bool circle;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: fill,
            shape: circle ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: circle
                ? null
                : BorderRadius.circular(CulpeoLayout.pillRadius),
            border: Border.all(
              color:
                  border ??
                  (selected ? CulpeoColors.textPrimary : Colors.transparent),
              width: circle && selected ? 2 : 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _PanelSectionHeader extends StatelessWidget {
  const _PanelSectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 2),
      child: Text(
        label.toUpperCase(),
        style: AppFonts.mono(
          fontSize: 9,
          color: CulpeoColors.textFaint,
          letterSpacing: 1.6,
        ),
      ),
    );
  }
}

class _PanelActionRow extends StatefulWidget {
  const _PanelActionRow({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.indent = 0,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final double indent;

  @override
  State<_PanelActionRow> createState() => _PanelActionRowState();
}

class _PanelActionRowState extends State<_PanelActionRow> {
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
          height: 34,
          margin: EdgeInsets.only(left: 6 + widget.indent, right: 6),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: _hovered ? CulpeoColors.hairline : Colors.transparent,
            borderRadius: BorderRadius.circular(CulpeoLayout.pillRadius),
          ),
          child: Row(
            children: [
              Icon(widget.icon, size: 15, color: CulpeoColors.textSecondary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: CulpeoColors.textSecondary,
                    fontSize: 13,
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

class _ProjectRow extends StatefulWidget {
  const _ProjectRow({
    super.key,
    required this.project,
    required this.expanded,
    required this.chatCount,
    required this.onToggle,
    required this.onNewChat,
    required this.onRename,
    required this.onDelete,
  });

  final ChatProject project;
  final bool expanded;
  final int chatCount;
  final VoidCallback onToggle;
  final VoidCallback onNewChat;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  State<_ProjectRow> createState() => _ProjectRowState();
}

class _ProjectRowState extends State<_ProjectRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color = chatProjectColor(widget.project);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        height: 36,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: _hovered ? CulpeoColors.hairline : Colors.transparent,
          borderRadius: BorderRadius.circular(CulpeoLayout.pillRadius),
          // Derselbe Rahmen wie an der Chatzeile, sonst sitzt der Inhalt
          // beider Zeilen um die Rahmenbreite versetzt.
          border: Border.all(
            color: _hovered ? CulpeoColors.hairlineStrong : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            // Das Ordnersymbol steht auf derselben Linie wie die Chatsymbole
            // darunter, der Aufklapp-Pfeil sitzt am rechten Rand.
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onToggle,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(
                    widget.project.icon != null
                        ? chatProjectIcon(widget.project)
                        : (widget.expanded
                              ? Icons.folder_open
                              : Icons.folder_outlined),
                    size: 14,
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
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Text(
                    widget.project.name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: CulpeoColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            if (widget.chatCount > 0)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  '${widget.chatCount}',
                  style: TextStyle(color: CulpeoColors.textFaint, fontSize: 11),
                ),
              ),
            AnimatedOpacity(
              opacity: _hovered ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 120),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _RowIconButton(
                    tooltip: tr('chatHistory.projectRow.newChat'),
                    icon: Icons.add,
                    onPressed: widget.onNewChat,
                  ),
                  _RowIconButton(
                    tooltip: tr('chatHistory.projectRow.edit'),
                    icon: Icons.edit_outlined,
                    onPressed: widget.onRename,
                  ),
                  _RowIconButton(
                    tooltip: tr('chatHistory.projectRow.delete'),
                    icon: Icons.delete_outline,
                    onPressed: widget.onDelete,
                  ),
                ],
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onToggle,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: SizedBox(
                  width: 26,
                  height: 36,
                  child: Center(
                    child: AnimatedRotation(
                      turns: widget.expanded ? 0.25 : 0,
                      duration: const Duration(milliseconds: 180),
                      child: Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: CulpeoColors.textFaint,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A subfolder header, indented one step further right than its parent
/// [_ProjectRow] - otherwise the same row shape (colour dot instead of a
/// custom icon, since [ChatSubfolder] doesn't carry one; toggle, count,
/// hover actions, chevron).
class _SubfolderRow extends StatefulWidget {
  const _SubfolderRow({
    super.key,
    required this.subfolder,
    required this.expanded,
    required this.chatCount,
    required this.onToggle,
    required this.onNewChat,
    required this.onRename,
    required this.onDelete,
  });

  final ChatSubfolder subfolder;
  final bool expanded;
  final int chatCount;
  final VoidCallback onToggle;
  final VoidCallback onNewChat;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  State<_SubfolderRow> createState() => _SubfolderRowState();
}

class _SubfolderRowState extends State<_SubfolderRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color = chatSubfolderColor(widget.subfolder);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        height: 34,
        margin: const EdgeInsets.only(left: 20, right: 6),
        decoration: BoxDecoration(
          color: _hovered ? CulpeoColors.hairline : Colors.transparent,
          borderRadius: BorderRadius.circular(CulpeoLayout.pillRadius),
          border: Border.all(
            color: _hovered ? CulpeoColors.hairlineStrong : Colors.transparent,
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
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(
                    widget.expanded ? Icons.folder_open : Icons.folder_outlined,
                    size: 13,
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
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Text(
                    widget.subfolder.name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: CulpeoColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            if (widget.chatCount > 0)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  '${widget.chatCount}',
                  style: TextStyle(color: CulpeoColors.textFaint, fontSize: 11),
                ),
              ),
            AnimatedOpacity(
              opacity: _hovered ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 120),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _RowIconButton(
                    tooltip: tr('chatHistory.subfolderRow.newChat'),
                    icon: Icons.add,
                    onPressed: widget.onNewChat,
                  ),
                  _RowIconButton(
                    tooltip: tr('chatHistory.subfolderRow.edit'),
                    icon: Icons.edit_outlined,
                    onPressed: widget.onRename,
                  ),
                  _RowIconButton(
                    tooltip: tr('chatHistory.subfolderRow.delete'),
                    icon: Icons.delete_outline,
                    onPressed: widget.onDelete,
                  ),
                ],
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onToggle,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: SizedBox(
                  width: 26,
                  height: 34,
                  child: Center(
                    child: AnimatedRotation(
                      turns: widget.expanded ? 0.25 : 0,
                      duration: const Duration(milliseconds: 180),
                      child: Icon(
                        Icons.chevron_right,
                        size: 15,
                        color: CulpeoColors.textFaint,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubfolderEditorResult {
  const _SubfolderEditorResult(this.name, this.color);

  final String name;
  final Color color;
}

/// Same shape as [_ProjectEditorDialog] minus the icon grid and path field -
/// [ChatSubfolder] only has a name and a colour.
class _SubfolderEditorDialog extends StatefulWidget {
  const _SubfolderEditorDialog({this.existing});

  final ChatSubfolder? existing;

  @override
  State<_SubfolderEditorDialog> createState() => _SubfolderEditorDialogState();
}

class _SubfolderEditorDialogState extends State<_SubfolderEditorDialog> {
  late final TextEditingController _controller;
  late Color _selectedColor;
  String? _nameError;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.existing?.name ?? '');
    _selectedColor = widget.existing != null
        ? chatSubfolderColor(widget.existing)
        : kProjectColorChoices.first;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = tr('chatHistory.subfolderDialog.nameError'));
      return;
    }
    Navigator.of(context).pop(_SubfolderEditorResult(name, _selectedColor));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: CulpeoColors.panel,
      shape: _dialogShape,
      title: Text(
        tr(
          _isEdit
              ? 'chatHistory.subfolderDialog.titleEdit'
              : 'chatHistory.subfolderDialog.titleNew',
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
              key: const Key('chat-subfolder-name-field'),
              controller: _controller,
              autofocus: true,
              style: TextStyle(color: CulpeoColors.textPrimary, fontSize: 14),
              cursorColor: CulpeoColors.action,
              decoration: InputDecoration(
                hintText: tr('chatHistory.subfolderDialog.nameHint'),
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
              tr('chatHistory.subfolderDialog.colorLabel'),
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
                    key: Key('chat-subfolder-color-${color.toARGB32()}'),
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

class _ChatRow extends StatefulWidget {
  const _ChatRow({
    super.key,
    required this.sessionId,
    required this.title,
    required this.selected,
    required this.indent,
    required this.projects,
    required this.currentProjectId,
    required this.onSelect,
    required this.onRename,
    required this.onDelete,
    required this.onMove,
    this.subfolders = const [],
    this.currentSubfolderId,
    this.onMoveToSubfolder,
  });

  final String sessionId;
  final String title;
  final bool selected;
  final double indent;
  final List<ChatProject> projects;

  final String? currentProjectId;
  final VoidCallback onSelect;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final ValueChanged<String?> onMove;

  /// The current project's own subfolders, so the same move menu can also
  /// sort the chat inside its project instead of just between projects.
  /// Empty when the chat isn't in a project or that project has none yet.
  final List<ChatSubfolder> subfolders;
  final String? currentSubfolderId;
  final ValueChanged<String?>? onMoveToSubfolder;

  @override
  State<_ChatRow> createState() => _ChatRowState();
}

class _ChatRowState extends State<_ChatRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        height: 34,
        margin: EdgeInsets.only(left: 6 + widget.indent, right: 6),
        decoration: BoxDecoration(
          color: selected
              ? CulpeoColors.actionMuted
              : _hovered
              ? CulpeoColors.hairline
              : Colors.transparent,
          borderRadius: BorderRadius.circular(CulpeoLayout.pillRadius),
          border: Border.all(
            color: selected ? CulpeoColors.actionBorder : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onSelect,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(
                    selected ? Icons.chat : Icons.chat_bubble_outline,
                    size: 14,
                    color: selected
                        ? CulpeoColors.action
                        : CulpeoColors.textFaint,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onSelect,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Text(
                    widget.title,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected
                          ? CulpeoColors.textPrimary
                          : CulpeoColors.textSecondary,
                      fontSize: 13,
                      fontWeight: selected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
            AnimatedOpacity(
              opacity: _hovered ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 120),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PopupMenuButton<String>(
                    key: Key('chat-history-move-${widget.sessionId}'),
                    tooltip: tr('chatHistory.chatRow.move'),
                    color: CulpeoColors.panel,
                    shape: _dialogShape,
                    iconSize: 15,
                    splashRadius: 16,
                    constraints: const BoxConstraints(
                      minWidth: 180,
                      maxWidth: 240,
                    ),
                    icon: Icon(
                      Icons.drive_file_move_outlined,
                      size: 15,
                      color: CulpeoColors.textFaint,
                    ),
                    onSelected: (value) {
                      if (value == '__none__') {
                        widget.onMove(null);
                      } else if (value == '__direct__') {
                        widget.onMoveToSubfolder?.call(null);
                      } else if (value.startsWith('subfolder:')) {
                        widget.onMoveToSubfolder?.call(
                          value.substring('subfolder:'.length),
                        );
                      } else {
                        widget.onMove(value);
                      }
                    },
                    itemBuilder: (context) => [
                      if (widget.currentProjectId != null)
                        PopupMenuItem<String>(
                          value: '__none__',
                          height: 36,
                          child: _MoveMenuEntry(
                            icon: Icons.folder_off_outlined,
                            label: tr('chatHistory.chatRow.removeFromFolder'),
                          ),
                        ),
                      if (widget.currentSubfolderId != null)
                        PopupMenuItem<String>(
                          value: '__direct__',
                          height: 36,
                          child: _MoveMenuEntry(
                            icon: Icons.subdirectory_arrow_left,
                            label: tr(
                              'chatHistory.chatRow.removeFromSubfolder',
                            ),
                          ),
                        ),
                      for (final project in widget.projects)
                        if (project.id != widget.currentProjectId)
                          PopupMenuItem<String>(
                            value: project.id,
                            height: 36,
                            child: _MoveMenuEntry(
                              icon: chatProjectIcon(project),
                              label: project.name,
                              iconColor: chatProjectColor(project),
                            ),
                          ),
                      if (widget.currentProjectId == null &&
                          widget.projects.isEmpty)
                        PopupMenuItem<String>(
                          enabled: false,
                          height: 36,
                          child: _MoveMenuEntry(
                            icon: Icons.folder_off_outlined,
                            label: tr('chatHistory.chatRow.noFolders'),
                          ),
                        ),
                      for (final subfolder in widget.subfolders)
                        if (subfolder.id != widget.currentSubfolderId)
                          PopupMenuItem<String>(
                            value: 'subfolder:${subfolder.id}',
                            height: 36,
                            child: _MoveMenuEntry(
                              icon: Icons.folder_outlined,
                              label: subfolder.name,
                              iconColor: chatSubfolderColor(subfolder),
                            ),
                          ),
                    ],
                  ),
                  _RowIconButton(
                    tooltip: tr('chatHistory.chatRow.rename'),
                    icon: Icons.edit_outlined,
                    onPressed: widget.onRename,
                  ),
                  _RowIconButton(
                    tooltip: tr('chatHistory.chatRow.delete'),
                    icon: Icons.delete_outline,
                    onPressed: widget.onDelete,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoveMenuEntry extends StatelessWidget {
  const _MoveMenuEntry({
    required this.icon,
    required this.label,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: iconColor ?? CulpeoColors.textMuted),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: CulpeoColors.textSecondary, fontSize: 13),
          ),
        ),
      ],
    );
  }
}

class _RowIconButton extends StatelessWidget {
  const _RowIconButton({
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
      icon: Icon(icon, size: 15),
      color: CulpeoColors.textFaint,
      splashRadius: 16,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      onPressed: onPressed,
    );
  }
}
