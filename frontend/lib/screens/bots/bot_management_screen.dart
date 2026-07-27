import 'package:flutter/material.dart';

import '../../engine/models.dart';
import '../../l10n/bot_management_strings.dart';
import '../../state/app_state.dart';
import '../../widgets/top_notification.dart';
import '../chat/chat_model_picker.dart';

class BotManagementScreen extends StatefulWidget {
  final Color themeColor;
  final bool loadRemoteData;
  final List<Map<String, dynamic>> initialBots;
  final List<ChatModelChoice> initialModelChoices;

  const BotManagementScreen({
    super.key,
    this.themeColor = const Color(0xFFC9A24A),
    this.loadRemoteData = true,
    this.initialBots = const [],
    this.initialModelChoices = const [],
  });

  @override
  State<BotManagementScreen> createState() => _BotManagementScreenState();
}

class _BotManagementScreenState extends State<BotManagementScreen> {
  final AppState _appState = AppState();
  Map<String, dynamic>? _selectedBot;
  bool _isNewBot = false;
  bool _isLoading = false;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _promptController = TextEditingController();
  final _keywordsController = TextEditingController();
  final _allowedRootsController = TextEditingController();
  bool _isDefault = false;
  bool _agenticEnabled = false;
  String _responseStyle = 'balanced';
  List<ChatModelChoice> _modelChoices = const [];
  String? _selectedModelBindingKey;

  bool get _isLockedBot =>
      !_isNewBot && (_selectedBot?['id']?.toString() == 'botbuilder');

  @override
  void initState() {
    super.initState();
    if (widget.loadRemoteData) {
      _loadBots();
    } else {
      _appState.philoBots
        ..clear()
        ..addAll(widget.initialBots);
      _modelChoices = widget.initialModelChoices;
      if (widget.initialBots.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final defaultBot = widget.initialBots.firstWhere(
            (bot) => bot['is_default'] == true,
            orElse: () => widget.initialBots.first,
          );
          _selectBot(Map<String, dynamic>.from(defaultBot));
        });
      }
    }
  }

  Future<void> _loadBots() async {
    setState(() => _isLoading = true);
    List<EngineInstance> instances = const [];
    await Future.wait<void>([
      _appState.refreshPhiloBots(),
      _appState.refreshActiveApiModels(),
      _appState.api
          .getEngineInstances()
          .then<void>((value) => instances = value)
          .catchError((Object _) {}),
    ]);
    final choices = buildChatModelChoices(
      cloudModels: _appState.activeApiModels,
      engineInstances: instances,
    );
    for (final instance in instances) {
      if (instance.id.isNotEmpty &&
          !choices.any((choice) => choice.instanceId == instance.id)) {
        choices.add(ChatModelChoice.local(instance));
      }
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
        _modelChoices = choices;
        // Select the default bot by default if available
        if (_appState.philoBots.isNotEmpty) {
          final defaultBot = _appState.philoBots.firstWhere(
            (b) => b['is_default'] == true,
            orElse: () => _appState.philoBots.first,
          );
          _selectBot(Map<String, dynamic>.from(defaultBot));
        }
      });
    }
  }

  void _selectBot(Map<String, dynamic> bot) {
    setState(() {
      _selectedBot = bot;
      _isNewBot = false;
      _nameController.text = bot['name']?.toString() ?? '';
      _promptController.text = bot['system_prompt']?.toString() ?? '';
      _isDefault = bot['is_default'] == true;
      _responseStyle = _normalizeResponseStyle(
        bot['response_style']?.toString(),
      );
      _agenticEnabled = bot['agentic_enabled'] == true;
      final rawBinding = bot['model_binding'];
      _selectedModelBindingKey = null;
      if (rawBinding is Map) {
        final binding = BotModelBinding.fromJson(
          Map<String, dynamic>.from(rawBinding),
        );
        final key = binding.isLocal
            ? 'local:${binding.instanceId ?? binding.modelId}'
            : 'cloud:${binding.modelRef}';
        if (!_modelChoices.any((choice) => choice.stableKey == key)) {
          _modelChoices = [..._modelChoices, ChatModelChoice.binding(binding)];
        }
        _selectedModelBindingKey = key;
      }
      final roots = bot['allowed_roots'];
      _allowedRootsController.text = roots is List
          ? roots.map((root) => root.toString()).join(', ')
          : '/pfad/zum/projekt, /pfad/zu/weiterem/ordner';
      final kws = bot['keywords'];
      if (kws is List) {
        _keywordsController.text = kws.join(', ');
      } else {
        _keywordsController.text = '';
      }
    });
  }

  void _prepareNewBot() {
    setState(() {
      _selectedBot = null;
      _isNewBot = true;
      _isDefault = false;
      _nameController.clear();
      _promptController.clear();
      _keywordsController.clear();
      _allowedRootsController.text =
          '/pfad/zum/projekt, /pfad/zu/weiterem/ordner';
      _agenticEnabled = false;
      _responseStyle = 'balanced';
      _selectedModelBindingKey = null;
    });
  }

  Future<void> _saveBot() async {
    if (_isLockedBot) {
      showTopNotification(
        context,
        tr('botManagement.notification.lockedSave'),
        color: Colors.redAccent,
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final systemPrompt = _promptController.text.trim();
    final keywordsStr = _keywordsController.text.trim();
    final keywords = keywordsStr
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final allowedRoots = _allowedRootsController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final botData = <String, dynamic>{
      'name': name,
      'system_prompt': systemPrompt,
      'keywords': keywords,
      'response_style': _responseStyle,
      'agentic_enabled': _agenticEnabled,
      'allowed_roots': allowedRoots,
      'is_default': _isDefault,
      'model_binding': _selectedBindingJson(),
    };

    if (!_isNewBot && _selectedBot != null) {
      botData['id'] = _selectedBot!['id'];
    }

    setState(() => _isLoading = true);
    final success = await _appState.savePhiloBot(botData);
    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        showTopNotification(
          context,
          tr('bots.saved', {'name': name}),
          color: Colors.green,
        );
        // Reselect the saved bot
        final saved = _appState.philoBots.firstWhere(
          (b) => b['name'] == name,
          orElse: () => _appState.philoBots.first,
        );
        _selectBot(Map<String, dynamic>.from(saved));
      } else {
        showTopNotification(
          context,
          _appState.lastChatError ?? tr('botManagement.notification.saveError'),
          color: Colors.redAccent,
        );
      }
    }
  }

  String _normalizeResponseStyle(String? value) {
    switch ((value ?? '').trim()) {
      case 'short':
      case 'explain':
      case 'steps':
      case 'critical':
      case 'brainstorm':
      case 'balanced':
        return value!.trim();
      default:
        return 'balanced';
    }
  }

  String _responseStyleLabel(String value) {
    switch (value) {
      case 'short':
        return tr('botManagement.style.short');
      case 'explain':
        return tr('botManagement.style.explain');
      case 'steps':
        return tr('botManagement.style.steps');
      case 'critical':
        return tr('botManagement.style.critical');
      case 'brainstorm':
        return tr('botManagement.style.brainstorm');
      case 'balanced':
      default:
        return tr('botManagement.style.balanced');
    }
  }

  Map<String, dynamic>? _selectedBindingJson() {
    final key = _selectedModelBindingKey;
    if (key == null) return null;
    for (final choice in _modelChoices) {
      if (choice.stableKey != key) continue;
      return {
        'kind': choice.isLocal ? 'local' : 'api',
        'model_ref': choice.modelRef,
        'provider': choice.provider,
        'model_id': choice.modelId,
        if (choice.instanceId?.isNotEmpty == true)
          'instance_id': choice.instanceId,
        'display_name': choice.label,
      };
    }
    return null;
  }

  Future<void> _deleteBot() async {
    if (_selectedBot == null || _selectedBot!['is_default'] == true) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF07070A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        title: Text(
          tr('botManagement.delete.title'),
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          tr('bots.deleteConfirm', {
            'name': _selectedBot!['name']?.toString() ?? '',
          }),
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              tr('common.cancel'),
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              tr('common.delete'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      final success = await _appState.deletePhiloBot(_selectedBot!['id']);
      if (mounted) {
        setState(() => _isLoading = false);
        if (success) {
          showTopNotification(
            context,
            tr('bots.deleted', {
              'name': _selectedBot!['name']?.toString() ?? '',
            }),
            color: Colors.green,
          );
          _loadBots();
        } else {
          showTopNotification(
            context,
            _appState.lastChatError ??
                tr('botManagement.notification.deleteError'),
            color: Colors.redAccent,
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _promptController.dispose();
    _keywordsController.dispose();
    _allowedRootsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 760;
          final margin = constraints.maxWidth < 600
              ? const EdgeInsets.all(8)
              : const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
          return Container(
            margin: margin,
            decoration: BoxDecoration(
              color: const Color(0xFF16161D).withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: wide
                ? Row(
                    key: const Key('bot-management-wide-layout'),
                    children: [
                      _buildSidebar(),
                      Expanded(child: _buildEditor(useBottomSheetMenus: false)),
                    ],
                  )
                : Column(
                    key: const Key('bot-management-stacked-layout'),
                    children: [
                      SizedBox(
                        height: constraints.maxHeight < 620 ? 170 : 220,
                        child: _buildSidebar(stacked: true),
                      ),
                      Expanded(
                        child: _buildEditor(
                          compact: true,
                          useBottomSheetMenus: constraints.maxWidth < 600,
                        ),
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }

  Widget _buildSidebar({bool stacked = false}) {
    return Container(
      width: stacked ? double.infinity : 280,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.15),
        border: Border(
          right: stacked
              ? BorderSide.none
              : BorderSide(color: Colors.white.withValues(alpha: 0.06)),
          bottom: stacked
              ? BorderSide(color: Colors.white.withValues(alpha: 0.06))
              : BorderSide.none,
        ),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.smart_toy_outlined,
                        color: Colors.white70,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          tr('bots.title'),
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.white70, size: 20),
                  onPressed: _prepareNewBot,
                  tooltip: tr('bots.createTitle'),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white10),
          // List
          Expanded(
            child: _isLoading && _appState.philoBots.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white30),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _appState.philoBots.length,
                    itemBuilder: (context, index) {
                      final bot = Map<String, dynamic>.from(
                        _appState.philoBots[index],
                      );
                      final isSelected =
                          !_isNewBot &&
                          _selectedBot != null &&
                          _selectedBot!['id'] == bot['id'];
                      final isDefault = bot['is_default'] == true;
                      final isLockedBot = bot['id'] == 'botbuilder';

                      return InkWell(
                        onTap: () => _selectBot(bot),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          color: isSelected
                              ? widget.themeColor.withValues(alpha: 0.08)
                              : Colors.transparent,
                          child: Row(
                            children: [
                              Icon(
                                isLockedBot
                                    ? Icons.lock_outline
                                    : isDefault
                                    ? Icons.security_outlined
                                    : Icons.smart_toy_outlined,
                                size: 18,
                                color: isSelected
                                    ? widget.themeColor
                                    : Colors.white54,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            bot['name']?.toString() ??
                                                tr(
                                                  'botManagement.list.unnamed',
                                                ),
                                            style: TextStyle(
                                              color: isSelected
                                                  ? Colors.white
                                                  : Colors.white70,
                                              fontSize: 13,
                                              fontWeight: isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (isDefault)
                                          Container(
                                            margin: const EdgeInsets.only(
                                              left: 6,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: widget.themeColor
                                                  .withValues(alpha: 0.15),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              tr('botManagement.list.default'),
                                              style: TextStyle(
                                                color: widget.themeColor,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        if (isLockedBot)
                                          Container(
                                            margin: const EdgeInsets.only(
                                              left: 6,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.redAccent
                                                  .withValues(alpha: 0.12),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              tr('botManagement.list.locked'),
                                              style: const TextStyle(
                                                color: Colors.redAccent,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      bot['keywords'] != null &&
                                              (bot['keywords'] as List)
                                                  .isNotEmpty
                                          ? tr('botManagement.list.triggers', {
                                              'keywords':
                                                  (bot['keywords'] as List)
                                                      .join(', '),
                                            })
                                          : (isDefault
                                                ? tr(
                                                    'botManagement.list.defaultWithoutKeywords',
                                                  )
                                                : tr(
                                                    'botManagement.list.noTriggers',
                                                  )),
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white38
                                            : Colors.white24,
                                        fontSize: 12,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildModelBindingField(bool locked, {required bool useBottomSheet}) {
    const automatic = '__chat_model__';
    final current = _selectedModelBindingKey ?? automatic;
    ChatModelChoice? selected;
    for (final choice in _modelChoices) {
      if (choice.stableKey == _selectedModelBindingKey) selected = choice;
    }
    final title =
        selected?.label ?? tr('botManagement.binding.normalSelection');
    final subtitle = selected == null
        ? tr('botManagement.binding.usesChatModel')
        : tr('botManagement.binding.modelSubtitle', {
            'provider': selected.isLocal
                ? tr('botManagement.binding.local')
                : selected.provider,
            'model': selected.modelId,
          });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          tr('botManagement.binding.title'),
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            if (useBottomSheet) {
              return Semantics(
                button: true,
                enabled: !locked,
                label: tr('botManagement.binding.selectionLabel', {
                  'title': title,
                }),
                child: InkWell(
                  key: const Key('bot-model-binding-sheet-trigger'),
                  onTap: locked ? null : () => _showBindingSheet(automatic),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 54),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.025),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          selected?.isLocal == true
                              ? Icons.memory_outlined
                              : selected == null
                              ? Icons.chat_bubble_outline
                              : Icons.cloud_outlined,
                          color: const Color(0xFFEBD9A8),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                subtitle,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.white54,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            return DropdownButtonFormField<String>(
              key: const Key('bot-model-binding-dropdown'),
              initialValue: current,
              isExpanded: true,
              dropdownColor: const Color(0xFF0F0F14),
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.025),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              items: [
                DropdownMenuItem(
                  value: automatic,
                  child: Text(tr('botManagement.binding.normalSelection')),
                ),
                ..._modelChoices.map(
                  (choice) => DropdownMenuItem(
                    value: choice.stableKey,
                    child: Text(
                      tr('botManagement.binding.choiceLabel', {
                        'provider': choice.isLocal
                            ? tr('botManagement.binding.local')
                            : choice.provider,
                        'model': choice.label,
                      }),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
              onChanged: locked
                  ? null
                  : (value) => setState(() {
                      _selectedModelBindingKey = value == automatic
                          ? null
                          : value;
                    }),
            );
          },
        ),
        const SizedBox(height: 5),
        Text(
          tr('botManagement.binding.overridesSelection'),
          style: const TextStyle(color: Colors.white38, fontSize: 12),
        ),
      ],
    );
  }

  Future<void> _showBindingSheet(String automatic) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F0F14),
      constraints: const BoxConstraints(maxWidth: 640),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.72,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text(
                tr('botManagement.binding.sheetTitle'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Flexible(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 20),
                children: [
                  ListTile(
                    key: const Key('bot-binding-choice-automatic'),
                    minTileHeight: 52,
                    leading: const Icon(Icons.chat_bubble_outline),
                    title: Text(tr('botManagement.binding.normalSelection')),
                    subtitle: Text(tr('botManagement.binding.none')),
                    onTap: () => Navigator.pop(context, automatic),
                  ),
                  ..._modelChoices.map(
                    (choice) => ListTile(
                      key: Key('bot-binding-choice-${choice.stableKey}'),
                      minTileHeight: 52,
                      leading: Icon(
                        choice.isLocal
                            ? Icons.memory_outlined
                            : Icons.cloud_outlined,
                      ),
                      title: Text(choice.label),
                      subtitle: Text(choice.subtitle),
                      trailing: choice.placementLabel.isEmpty
                          ? null
                          : Text(choice.placementLabel),
                      onTap: () => Navigator.pop(context, choice.stableKey),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    if (!mounted || selected == null) return;
    setState(() {
      _selectedModelBindingKey = selected == automatic ? null : selected;
    });
  }

  Widget _buildEditor({
    bool compact = false,
    required bool useBottomSheetMenus,
  }) {
    if (_selectedBot == null && !_isNewBot) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.smart_toy_outlined,
              size: 56,
              color: Colors.white.withValues(alpha: 0.1),
            ),
            const SizedBox(height: 16),
            Text(
              tr('botManagement.editor.empty'),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    final isDefault = !_isNewBot && _selectedBot?['is_default'] == true;
    final isLockedBot = _isLockedBot;
    const responseStyles = <String>[
      'balanced',
      'short',
      'explain',
      'steps',
      'critical',
      'brainstorm',
    ];

    return Padding(
      padding: EdgeInsets.all(compact ? 16 : 32),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _isNewBot
                        ? tr('bots.createTitle')
                        : tr('botManagement.editor.configureTitle', {
                            'name': _selectedBot!['name']?.toString() ?? '',
                          }),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (isLockedBot)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.redAccent.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      tr('botManagement.editor.lockedTitle'),
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else if (!isDefault &&
                    !_isNewBot &&
                    _selectedBot!['id'] != 'philobot' &&
                    _selectedBot!['id'] != 'botbuilder')
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent.withValues(alpha: 0.15),
                      foregroundColor: Colors.redAccent,
                      elevation: 0,
                      side: const BorderSide(
                        color: Colors.redAccent,
                        width: 0.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: Text(
                      tr('common.delete'),
                      style: const TextStyle(fontSize: 12),
                    ),
                    onPressed: _deleteBot,
                  ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(height: 1, color: Colors.white10),
            const SizedBox(height: 24),

            if (isLockedBot) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.redAccent.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  tr('botManagement.editor.lockedBody'),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(height: 18),
            ],

            // Fields
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Bot Name
                    Row(
                      children: [
                        Text(
                          tr('botManagement.name.label'),
                          style: const TextStyle(
                            color: Colors.white30,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Tooltip(
                          message: tr('botManagement.name.tooltip'),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F0F14),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          textStyle: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                          padding: const EdgeInsets.all(10),
                          child: const Icon(
                            Icons.help_outline,
                            size: 12,
                            color: Colors.white30,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      enabled: !isLockedBot,
                      readOnly: isLockedBot,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: tr('botManagement.name.hint'),
                        hintStyle: const TextStyle(
                          color: Colors.white24,
                          fontSize: 14,
                        ),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.02),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: widget.themeColor.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return tr('botManagement.name.required');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Default Bot Toggle
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            tr('botManagement.default.label'),
                            maxLines: 2,
                            style: TextStyle(
                              color: Colors.white30,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Tooltip(
                          message: tr('botManagement.default.tooltip'),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F0F14),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          textStyle: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                          padding: const EdgeInsets.all(10),
                          child: const Icon(
                            Icons.help_outline,
                            size: 12,
                            color: Colors.white30,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Switch(
                          value: _isDefault,
                          onChanged: isLockedBot || isDefault
                              ? null // Disable turning off directly, must make another bot default instead.
                              : (val) {
                                  setState(() {
                                    _isDefault = val;
                                  });
                                },
                          activeThumbColor: widget.themeColor,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            isDefault
                                ? tr('botManagement.default.active')
                                : (_isDefault
                                      ? tr('botManagement.default.enable')
                                      : tr('botManagement.default.inactive')),
                            style: TextStyle(
                              color: _isDefault
                                  ? Colors.white70
                                  : Colors.white30,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    _buildModelBindingField(
                      isLockedBot,
                      useBottomSheet: useBottomSheetMenus,
                    ),
                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Text(
                          tr('botManagement.style.label'),
                          style: const TextStyle(
                            color: Colors.white30,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Tooltip(
                          message: tr('botManagement.style.tooltip'),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F0F14),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          textStyle: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                          padding: const EdgeInsets.all(10),
                          child: const Icon(
                            Icons.help_outline,
                            size: 12,
                            color: Colors.white30,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _responseStyle,
                      dropdownColor: const Color(0xFF0F0F14),
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.02),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: widget.themeColor.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                      items: responseStyles
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(_responseStyleLabel(value)),
                            ),
                          )
                          .toList(),
                      selectedItemBuilder: (context) => responseStyles
                          .map(
                            (value) => DefaultTextStyle(
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                              child: Text(_responseStyleLabel(value)),
                            ),
                          )
                          .toList(),
                      onChanged: isLockedBot
                          ? null
                          : (value) {
                              if (value == null) return;
                              setState(() => _responseStyle = value);
                            },
                    ),
                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Text(
                          tr('botManagement.agentic.label'),
                          style: const TextStyle(
                            color: Colors.white30,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Tooltip(
                          message: tr('botManagement.agentic.tooltip'),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F0F14),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          textStyle: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                          padding: const EdgeInsets.all(10),
                          child: const Icon(
                            Icons.help_outline,
                            size: 12,
                            color: Colors.white30,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Switch(
                          value: _agenticEnabled,
                          onChanged: isLockedBot
                              ? null
                              : (value) {
                                  setState(() => _agenticEnabled = value);
                                },
                          activeThumbColor: widget.themeColor,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _agenticEnabled
                                ? tr('botManagement.agentic.enabled')
                                : tr('botManagement.agentic.disabled'),
                            style: TextStyle(
                              color: _agenticEnabled
                                  ? Colors.white70
                                  : Colors.white30,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _allowedRootsController,
                      enabled: !isLockedBot,
                      readOnly: isLockedBot,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: tr('botManagement.agentic.rootsHint'),
                        hintStyle: const TextStyle(
                          color: Colors.white24,
                          fontSize: 13,
                        ),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.02),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: widget.themeColor.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Trigger Keywords (Skip if default and isDefault toggle is on, but let's always show it)
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            tr('botManagement.keywords.label'),
                            style: const TextStyle(
                              color: Colors.white30,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Tooltip(
                          message: tr('botManagement.keywords.tooltip'),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F0F14),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          textStyle: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                          padding: const EdgeInsets.all(10),
                          child: const Icon(
                            Icons.help_outline,
                            size: 12,
                            color: Colors.white30,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _keywordsController,
                      enabled: !isLockedBot,
                      readOnly: isLockedBot,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: _isDefault
                            ? tr('botManagement.keywords.defaultHint')
                            : tr('botManagement.keywords.hint'),
                        hintStyle: const TextStyle(
                          color: Colors.white24,
                          fontSize: 14,
                        ),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.02),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: widget.themeColor.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                      validator: (val) {
                        // If it's default bot, keywords are optional. If not, they are required.
                        if (!_isDefault &&
                            (val == null || val.trim().isEmpty)) {
                          return tr('botManagement.keywords.required');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // System Prompt
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            tr('botManagement.prompt.label'),
                            maxLines: 2,
                            style: const TextStyle(
                              color: Colors.white30,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Tooltip(
                          message: tr('botManagement.prompt.tooltip'),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F0F14),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          textStyle: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                          padding: const EdgeInsets.all(10),
                          child: const Icon(
                            Icons.help_outline,
                            size: 12,
                            color: Colors.white30,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _promptController,
                      enabled: !isLockedBot,
                      readOnly: isLockedBot,
                      maxLines: 8,
                      minLines: 4,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.4,
                      ),
                      decoration: InputDecoration(
                        hintText: tr('botManagement.prompt.hint'),
                        hintStyle: const TextStyle(
                          color: Colors.white24,
                          fontSize: 14,
                        ),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.02),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: widget.themeColor.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return tr('botManagement.prompt.required');
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: Colors.white10),
            const SizedBox(height: 20),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_isNewBot)
                  TextButton(
                    onPressed: () {
                      if (_appState.philoBots.isNotEmpty) {
                        _selectBot(
                          Map<String, dynamic>.from(_appState.philoBots.first),
                        );
                      } else {
                        setState(() => _isNewBot = false);
                      }
                    },
                    child: Text(
                      tr('common.cancel'),
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.themeColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 14,
                    ),
                  ),
                  onPressed: (_isLoading || isLockedBot) ? null : _saveBot,
                  child: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          isLockedBot
                              ? tr('botManagement.list.locked')
                              : tr('common.save'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
