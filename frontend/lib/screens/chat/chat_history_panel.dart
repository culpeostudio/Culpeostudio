import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../l10n/chat_aux_strings.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';

/// Gold-Akzent des Chat-Bereichs.
const Color kChatAccent = Color(0xFFC9A24A);

/// Zur Auswahl stehende Ordnerfarben im Projekt-Dialog.
const List<Color> kProjectColorChoices = [
  Color(0xFFC9A24A), // Gold
  Color(0xFF6E8FE0), // Blau
  Color(0xFF7BAE7F), // Gruen
  Color(0xFFA98BD4), // Lila
  Color(0xFFD97B7B), // Rot
  Color(0xFF62B5AB), // Petrol
];

/// Farbe eines Projektordners; faellt auf Gold zurueck, wenn keine oder eine
/// ungueltige Farbe hinterlegt ist.
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

/// Zur Auswahl stehende Icons im Projekt-Dialog; Schluessel sind die
/// String-Ids, die backend-seitig am Projekt gespeichert werden.
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
};

/// Icon eines Projektordners; faellt auf den Ordner zurueck, wenn kein oder
/// ein unbekannter Icon-Schluessel hinterlegt ist.
IconData chatProjectIcon(ChatProject? project) {
  final key = project?.icon;
  if (key != null && kChatProjectIcons.containsKey(key)) {
    return kChatProjectIcons[key]!;
  }
  return Icons.folder_outlined;
}

/// Dialog zum Umbenennen eines Chats; wird sowohl vom Verlaufs-Dropdown in
/// der Sidebar als auch (frueher) direkt vom Chat-Tab genutzt.
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
        backgroundColor: const Color(0xFF1C1C22),
        title: Text(
          tr('chatHistory.rename.title'),
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          cursorColor: kChatAccent,
          decoration: InputDecoration(
            hintText: tr('chatHistory.rename.hint'),
            hintStyle: const TextStyle(color: Colors.white38),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: kChatAccent),
            ),
          ),
          onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              tr('chatHistory.rename.cancel'),
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: Text(
              tr('chatHistory.rename.save'),
              style: TextStyle(color: kChatAccent),
            ),
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

/// Bestaetigungsdialog zum Loeschen eines Chats. War die geloeschte Sitzung
/// die aktive und bleibt keine mehr uebrig, ruft [onNeedNewSession] den
/// Aufrufer auf, damit dieser (z. B. im Chat-Tab) eine neue Sitzung startet.
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
      backgroundColor: const Color(0xFF1C1C22),
      title: Text(
        tr('chatHistory.delete.title'),
        style: TextStyle(color: Colors.white, fontSize: 16),
      ),
      content: Text(
        tr('chatHistory.delete.body', {'title': title}),
        style: const TextStyle(color: Colors.white70, fontSize: 13),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(
            tr('chatHistory.delete.cancel'),
            style: TextStyle(color: Colors.white54),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(
            tr('chatHistory.delete.confirm'),
            style: TextStyle(color: Color(0xFFE06C75)),
          ),
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

/// Kleine Pill in der Chat-Leiste, die den Ordner des aktiven Chats zeigt.
class ChatProjectBadge extends StatelessWidget {
  const ChatProjectBadge({super.key, required this.project});

  final ChatProject project;

  @override
  Widget build(BuildContext context) {
    final color = chatProjectColor(project);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
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

/// Verlaufs-Dropdown unter dem "Chat"-Reiter der Sidebar. Zeigt die
/// Projektordner und die freien Chats an und bietet alle Verlaufs-Aktionen
/// (neu, umbenennen, loeschen, in Ordner verschieben) direkt inline an. Ein
/// neuer (nicht zugeordneter) Chat wird ueber das Icon am "Chat"-Reiter
/// selbst gestartet, nicht mehr hier im Panel.
class ChatHistoryPanel extends StatefulWidget {
  const ChatHistoryPanel({
    super.key,
    required this.appState,
    required this.currentChatId,
    required this.expandedProjects,
    required this.onNewChatInProject,
    required this.onSelectChat,
    required this.onRenameChat,
    required this.onDeleteChat,
  });

  final AppState appState;
  final String? currentChatId;

  /// Gemerkte Aufklapp-Zustaende der Ordner; gehoert dem aufrufenden Tab,
  /// damit sie ein Schliessen des Panels ueberleben.
  final Set<String> expandedProjects;

  final ValueChanged<String> onNewChatInProject;
  final ValueChanged<String> onSelectChat;
  final ValueChanged<String> onRenameChat;
  final ValueChanged<String> onDeleteChat;

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
        backgroundColor: const Color(0xFF1C1C22),
        title: Text(
          tr('chatHistory.deleteProject.title'),
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        content: Text(
          tr('chatHistory.deleteProject.body', {'name': project.name}),
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              tr('chatHistory.deleteProject.cancel'),
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              tr('chatHistory.deleteProject.confirm'),
              style: TextStyle(color: Color(0xFFE06C75)),
            ),
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

        // Auf ca. 8 sichtbare Chat-Zeilen begrenzt (34px je Zeile) plus
        // Platz fuer "Neuer Ordner" und eine Sektions-Ueberschrift; darueber
        // hinaus scrollt die Liste innerhalb dieser Hoehe statt die restliche
        // Sidebar zu verdraengen.
        return ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 340),
          child: ListView(
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
                  if (widget.expandedProjects.contains(project.id))
                    for (final sessionId
                        in _appState.sessionsInProject(project.id).reversed)
                      _ChatRow(
                        key: Key('chat-history-chat-$sessionId'),
                        sessionId: sessionId,
                        title: _appState.getSessionTitle(sessionId),
                        selected: sessionId == widget.currentChatId,
                        indent: 30,
                        projects: projects,
                        currentProjectId: project.id,
                        onSelect: () => widget.onSelectChat(sessionId),
                        onRename: () => widget.onRenameChat(sessionId),
                        onDelete: () => widget.onDeleteChat(sessionId),
                        onMove: (projectId) => _appState.assignSessionToProject(
                          sessionId,
                          projectId,
                        ),
                      ),
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
                    style: const TextStyle(color: Colors.white30, fontSize: 12),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Ergebnis des Ordner-Dialogs (Name, gewaehlte Farbe, optionaler Projektpfad).
class _ProjectEditorResult {
  const _ProjectEditorResult(this.name, this.color, this.path, this.icon);

  final String name;
  final Color color;
  final String? path;
  final String? icon;
}

/// Dialog zum Anlegen/Bearbeiten eines Projektordners. Als eigenes
/// StatefulWidget, damit der TextEditingController erst bei Route-Dispose
/// (nach der Schluss-Animation) entsorgt wird.
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

  // Validierungsfehler, die unter den Feldern angezeigt werden, statt den
  // Dialog bei unvollstaendigen Angaben still offen zu lassen.
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
    } catch (_) {
      // Abbruch oder Fehler im Datei-Dialog ignorieren.
    }
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
      backgroundColor: const Color(0xFF1C1C22),
      title: Text(
        tr(
          _isEdit
              ? 'chatHistory.projectDialog.titleEdit'
              : 'chatHistory.projectDialog.titleNew',
        ),
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            key: const Key('project-name-field'),
            controller: _controller,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            cursorColor: kChatAccent,
            decoration: InputDecoration(
              hintText: tr('chatHistory.projectDialog.nameHint'),
              hintStyle: const TextStyle(color: Colors.white38),
              errorText: _nameError,
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: kChatAccent),
              ),
            ),
            onChanged: (_) {
              if (_nameError != null) setState(() => _nameError = null);
            },
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 18),
          Text(
            tr('chatHistory.projectDialog.colorLabel'),
            style: AppFonts.mono(
              fontSize: 9,
              color: Colors.white38,
              letterSpacing: 1.6,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            children: [
              for (final color in kProjectColorChoices)
                GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _selectedColor == color
                            ? Colors.white
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: _selectedColor == color
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : null,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            tr('chatHistory.projectDialog.iconLabel'),
            style: AppFonts.mono(
              fontSize: 9,
              color: Colors.white38,
              letterSpacing: 1.6,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final entry in kChatProjectIcons.entries)
                GestureDetector(
                  onTap: () => setState(
                    () => _selectedIcon = _selectedIcon == entry.key
                        ? null
                        : entry.key,
                  ),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _selectedIcon == entry.key
                          ? kChatAccent.withValues(alpha: 0.15)
                          : Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _selectedIcon == entry.key
                            ? kChatAccent
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      entry.value,
                      size: 19,
                      color: _selectedIcon == entry.key
                          ? kChatAccent
                          : Colors.white54,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          InkWell(
            key: const Key('project-path-toggle'),
            onTap: () => setState(() => _hasPath = !_hasPath),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Checkbox(
                    value: _hasPath,
                    onChanged: (value) =>
                        setState(() => _hasPath = value ?? false),
                    activeColor: kChatAccent,
                  ),
                  Expanded(
                    child: Text(
                      tr('chatHistory.projectDialog.pathToggle'),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_hasPath) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('project-path-field'),
                    controller: _pathController,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    cursorColor: kChatAccent,
                    decoration: InputDecoration(
                      hintText: tr('chatHistory.projectDialog.pathHint'),
                      hintStyle: const TextStyle(color: Colors.white38),
                      errorText: _pathError,
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: kChatAccent),
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
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  key: const Key('project-path-browse'),
                  onPressed: _browseProjectPath,
                  icon: const Icon(Icons.folder_open_rounded, size: 18),
                  label: Text(tr('chatHistory.projectDialog.browse')),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kChatAccent,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            tr('chatHistory.projectDialog.cancel'),
            style: TextStyle(color: Colors.white54),
          ),
        ),
        TextButton(
          onPressed: _submit,
          child: Text(
            tr(
              _isEdit
                  ? 'chatHistory.projectDialog.save'
                  : 'chatHistory.projectDialog.create',
            ),
            style: const TextStyle(color: kChatAccent),
          ),
        ),
      ],
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
          color: Colors.white38,
          letterSpacing: 1.6,
        ),
      ),
    );
  }
}

/// Einfache Aktionszeile (z. B. "Neuer Chat") im Panel.
class _PanelActionRow extends StatefulWidget {
  const _PanelActionRow({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

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
          margin: const EdgeInsets.symmetric(horizontal: 6),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: _hovered
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(widget.icon, size: 15, color: Colors.white70),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ordner-Zeile eines Projekts mit Aufklapp-Chevron und Hover-Aktionen.
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
          color: _hovered
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onToggle,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: SizedBox(
                  width: 34,
                  height: 36,
                  child: Center(
                    child: AnimatedRotation(
                      turns: widget.expanded ? 0.25 : 0,
                      duration: const Duration(milliseconds: 180),
                      child: const Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: Colors.white38,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Icon(
              // Eigenes Icon gewinnt; sonst der klassische Ordner, der sich
              // beim Auf-/Zuklappen oeffnet und schliesst.
              widget.project.icon != null
                  ? chatProjectIcon(widget.project)
                  : (widget.expanded
                        ? Icons.folder_open
                        : Icons.folder_outlined),
              size: 16,
              color: color,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onToggle,
                child: Text(
                  widget.project.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            if (widget.chatCount > 0)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  '${widget.chatCount}',
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
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
          ],
        ),
      ),
    );
  }
}

/// Chat-Zeile im Panel; bei Hover erscheinen Verschieben-, Umbenennen- und
/// Loesch-Aktionen.
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
  });

  final String sessionId;
  final String title;
  final bool selected;
  final double indent;
  final List<ChatProject> projects;

  /// Projekt, in dem die Zeile gerade gerendert wird (null = freie Liste).
  final String? currentProjectId;
  final VoidCallback onSelect;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final ValueChanged<String?> onMove;

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
              ? kChatAccent.withValues(alpha: 0.12)
              : _hovered
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
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
                    color: selected ? kChatAccent : Colors.white38,
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
                      color: selected ? Colors.white : Colors.white70,
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
                    color: const Color(0xFF24242C),
                    iconSize: 15,
                    splashRadius: 16,
                    constraints: const BoxConstraints(
                      minWidth: 180,
                      maxWidth: 240,
                    ),
                    icon: const Icon(
                      Icons.drive_file_move_outlined,
                      size: 15,
                      color: Colors.white38,
                    ),
                    onSelected: (value) =>
                        widget.onMove(value == '__none__' ? null : value),
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
        Icon(icon, size: 15, color: iconColor ?? Colors.white54),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
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
      color: Colors.white38,
      splashRadius: 16,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      onPressed: onPressed,
    );
  }
}
