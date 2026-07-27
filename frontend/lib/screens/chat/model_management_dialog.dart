import 'dart:ui';
import 'package:flutter/material.dart';

import '../../l10n/chat_aux_strings.dart';
import '../../state/app_state.dart';

class ModelManagementDialog extends StatefulWidget {
  final AppState appState;
  final Color themeColor;
  final bool isInline;
  final VoidCallback? onClose;

  const ModelManagementDialog({
    super.key,
    required this.appState,
    required this.themeColor,
    this.isInline = false,
    this.onClose,
  });

  @override
  State<ModelManagementDialog> createState() => _ModelManagementDialogState();
}

class _ModelManagementDialogState extends State<ModelManagementDialog> {
  String? _selectedFolderId;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedFolderId = null;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  final List<Color> _folderColors = [
    const Color(0xFFC9A24A), // Blue
    const Color(0xFFC9A24A), // Orange
    const Color(0xFF4CAF50), // Green
    const Color(0xFFF44336), // Red
    const Color(0xFF9C27B0), // Purple
    const Color(0xFFE91E63), // Pink
    const Color(0xFF009688), // Teal
    const Color(0xFFFFC107), // Amber
    const Color(0xFF00BCD4), // Cyan
    const Color(0xFF9E9E9E), // Grey
  ];

  void _showFolderFormDialog({ModelFolder? existingFolder}) {
    final isEdit = existingFolder != null;
    final nameController = TextEditingController(
      text: existingFolder?.name ?? '',
    );
    Color selectedColor = existingFolder?.color ?? _folderColors.first;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF141419),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 1.0,
                ),
              ),
              title: Text(
                tr(
                  isEdit
                      ? 'chatHistory.projectDialog.titleEdit'
                      : 'chatHistory.projectDialog.titleNew',
                ),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: tr('chatAux.modelManagement.folderNameHint'),
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 14,
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: widget.themeColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    tr('chatAux.modelManagement.chooseColor'),
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _folderColors.map((color) {
                      final isSelected =
                          color.toARGB32() == selectedColor.toARGB32();
                      return GestureDetector(
                        onTap: () {
                          setDialogState(() {
                            selectedColor = color;
                          });
                        },
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(color: Colors.white, width: 2.0)
                                : Border.all(color: Colors.transparent),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: color.withValues(alpha: 0.5),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    tr('common.cancel'),
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.themeColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isNotEmpty) {
                      if (isEdit) {
                        widget.appState.renameAndRecolorFolder(
                          existingFolder.id,
                          name,
                          selectedColor,
                        );
                      } else {
                        widget.appState.createModelFolder(name, selectedColor);
                      }
                      Navigator.pop(context);
                      setState(() {});
                    }
                  },
                  child: Text(
                    tr(
                      isEdit
                          ? 'chatHistory.projectDialog.save'
                          : 'chatHistory.projectDialog.create',
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final folders = widget.appState.modelFolders;
    final allModels = widget.appState.availableModelIds;

    List<String> displayedModels = [];
    if (_searchQuery.isNotEmpty) {
      displayedModels = allModels.where((modelId) {
        final haystack = [
          modelId,
          widget.appState.modelDisplayName(modelId),
          widget.appState.modelSubtitle(modelId),
        ].join(' ').toLowerCase();
        return haystack.contains(_searchQuery.toLowerCase());
      }).toList();
    } else if (_selectedFolderId == null) {
      displayedModels = allModels;
    } else {
      final folder = folders.firstWhere(
        (f) => f.id == _selectedFolderId,
        orElse: () => folders.first,
      );
      displayedModels = folder.modelIds;
    }

    final mainContent = ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: widget.isInline ? 680 : 800,
          height: widget.isInline ? 520 : 550,
          decoration: BoxDecoration(
            color: const Color(0xFF0F0F14).withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 240,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.02),
                  border: Border(
                    right: BorderSide(
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          Icon(Icons.folder, color: Colors.white70, size: 18),
                          SizedBox(width: 8),
                          Text(
                            tr('chatAux.modelManagement.catalogTitle'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Colors.white10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildSidebarTab(
                            id: null,
                            name: tr('chatAux.modelManagement.allModels'),
                            color: Colors.white70,
                            modelCount: allModels.length,
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Text(
                              tr('chatAux.modelManagement.categories'),
                              style: const TextStyle(
                                color: Colors.white30,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            child: ReorderableListView.builder(
                              padding: const EdgeInsets.only(bottom: 8),
                              itemCount: folders.length,
                              onReorderItem: (oldIndex, newIndex) {
                                widget.appState.reorderModelFolders(
                                  oldIndex,
                                  newIndex,
                                );
                                setState(() {});
                              },
                              itemBuilder: (context, index) {
                                final folder = folders[index];
                                return _buildSidebarTab(
                                  key: ValueKey(folder.id),
                                  id: folder.id,
                                  name: folder.name,
                                  color: folder.color,
                                  modelCount: folder.modelIds.length,
                                  onEdit: () => _showFolderFormDialog(
                                    existingFolder: folder,
                                  ),
                                  onDelete: folder.id == 'general'
                                      ? null
                                      : () {
                                          widget.appState.deleteModelFolder(
                                            folder.id,
                                          );
                                          if (_selectedFolderId == folder.id) {
                                            setState(() {
                                              _selectedFolderId = null;
                                            });
                                          } else {
                                            setState(() {});
                                          }
                                        },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Colors.white10),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: InkWell(
                        onTap: () => _showFolderFormDialog(),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: widget.themeColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: widget.themeColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add,
                                color: widget.themeColor,
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                tr('chatHistory.newFolder'),
                                style: TextStyle(
                                  color: widget.themeColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            tr('chatAux.modelManagement.inputFade'),
                            style: const TextStyle(
                              color: Colors.white30,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.03),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: widget.appState.modelThreshold,
                                dropdownColor: const Color(0xFF0F0F14),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                ),
                                icon: const Icon(
                                  Icons.arrow_drop_down,
                                  color: Colors.white54,
                                  size: 14,
                                ),
                                isExpanded: true,
                                isDense: true,
                                items: [
                                  DropdownMenuItem(
                                    value: 'small',
                                    child: Text(
                                      tr(
                                        'chatAux.modelManagement.thresholdSmall',
                                      ),
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'medium',
                                    child: Text(
                                      tr(
                                        'chatAux.modelManagement.thresholdMedium',
                                      ),
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'large',
                                    child: Text(
                                      tr(
                                        'chatAux.modelManagement.thresholdLarge',
                                      ),
                                    ),
                                  ),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    widget.appState.setModelThreshold(val);
                                    setState(() {});
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 38,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.08),
                                ),
                              ),
                              child: TextField(
                                controller: _searchController,
                                onChanged: (val) {
                                  setState(() {
                                    _searchQuery = val;
                                  });
                                },
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(
                                    Icons.search,
                                    size: 16,
                                    color: Colors.white38,
                                  ),
                                  hintText: tr(
                                    'chatAux.modelManagement.searchHint',
                                  ),
                                  hintStyle: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    fontSize: 13,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            onPressed: () {
                              if (widget.isInline) {
                                widget.onClose?.call();
                              } else {
                                Navigator.pop(context);
                              }
                            },
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white60,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Colors.white10),
                    Expanded(
                      child: displayedModels.isEmpty
                          ? Center(
                              child: Text(
                                tr('chatAux.modelManagement.noModels'),
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  fontSize: 13,
                                ),
                              ),
                            )
                          : _selectedFolderId == null || _searchQuery.isNotEmpty
                          ? ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: displayedModels.length,
                              itemBuilder: (context, index) {
                                return _buildModelItem(
                                  displayedModels[index],
                                  false,
                                );
                              },
                            )
                          : ReorderableListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: displayedModels.length,
                              onReorderItem: (oldIndex, newIndex) {
                                widget.appState.reorderModelInFolder(
                                  _selectedFolderId!,
                                  oldIndex,
                                  newIndex,
                                );
                                setState(() {});
                              },
                              itemBuilder: (context, index) {
                                return _buildModelItem(
                                  displayedModels[index],
                                  true,
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (widget.isInline) {
      return mainContent;
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
      child: mainContent,
    );
  }

  Widget _buildModelItem(String modelId, bool isReorderable) {
    final folders = widget.appState.modelFolders;
    final isActive = widget.appState.selectedModelId == modelId;
    final displayName = widget.appState.modelDisplayName(modelId);
    final subtitle = widget.appState.modelSubtitle(modelId);

    final currentFolder = folders.firstWhere(
      (f) => f.modelIds.contains(modelId),
      orElse: () => folders.first,
    );

    return Container(
      key: ValueKey(modelId),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isActive
            ? widget.themeColor.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? widget.themeColor.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.06),
          width: isActive ? 1.5 : 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          onTap: () {
            widget.appState.setSelectedModelId(modelId);
            if (widget.isInline) {
              widget.onClose?.call();
            } else {
              Navigator.pop(context);
            }
          },
          leading: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: currentFolder.color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.android, color: currentFolder.color, size: 16),
          ),
          title: Text(
            displayName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            '${currentFolder.name} • $subtitle',
            style: TextStyle(
              color: currentFolder.color.withValues(alpha: 0.8),
              fontSize: 10,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PopupMenuButton<String>(
                tooltip: tr('chatAux.modelManagement.moveToFolder'),
                icon: const Icon(
                  Icons.folder_open,
                  size: 16,
                  color: Colors.white54,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                color: const Color(0xFF141419),
                onSelected: (targetFolderId) {
                  widget.appState.moveModelToFolder(modelId, targetFolderId);
                  setState(() {});
                },
                itemBuilder: (context) {
                  return folders.map((f) {
                    return PopupMenuItem<String>(
                      value: f.id,
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: f.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            f.name,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList();
                },
              ),
              const SizedBox(width: 8),
              if (isActive)
                Icon(Icons.check_circle, color: widget.themeColor, size: 18)
              else
                const Icon(
                  Icons.radio_button_off,
                  color: Colors.white30,
                  size: 16,
                ),
              if (isReorderable) ...[
                const SizedBox(width: 12),
                const Icon(Icons.drag_handle, color: Colors.white30, size: 18),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarTab({
    Key? key,
    required String? id,
    required String name,
    required Color color,
    required int modelCount,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
  }) {
    final isSelected = _selectedFolderId == id;
    return Container(
      key: key,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? color.withValues(alpha: 0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedFolderId = id;
            });
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 12,
                    ),
                  ),
                ),
                if (id != null && isSelected && onEdit != null) ...[
                  IconButton(
                    icon: const Icon(
                      Icons.edit,
                      size: 12,
                      color: Colors.white38,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: onEdit,
                  ),
                  const SizedBox(width: 6),
                ],
                if (id != null && isSelected && onDelete != null) ...[
                  IconButton(
                    icon: const Icon(
                      Icons.delete,
                      size: 12,
                      color: Colors.white38,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: onDelete,
                  ),
                  const SizedBox(width: 6),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$modelCount',
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
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
