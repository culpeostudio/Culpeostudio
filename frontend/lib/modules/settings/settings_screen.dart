import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/app_strings.dart';
import '../../core/design_tokens.dart';
import '../../core/user_preferences_strings.dart';
import '../../core/api_service.dart';
import '../../core/app_state.dart';
import '../../core/top_notification.dart';
import '../bots/bot_management_screen.dart';
import '../nodes/nodes_screen.dart';
import '../scout/bot_picker.dart';
import './anbieter/anbieter_section.dart';
import './settings_cards.dart';
import './settings_widgets.dart';
import './shortcut_recorder.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback? onClose;

  /// Which nav section to land on. Used to jump straight to a section (e.g.
  /// Server API) instead of always opening on General.
  final int? initialSectionIndex;
  const SettingsScreen({super.key, this.onClose, this.initialSectionIndex});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ApiService _api = ApiService();
  final AppState _appState = AppState();
  Map<String, String> _shortcuts = {};
  late int _selectedSectionIndex = widget.initialSectionIndex ?? 0;

  final _modelDirController = TextEditingController();
  final _apiUrlController = TextEditingController();

  bool _isLoading = false;
  bool _isSaving = false;

  bool _modelDirValid = true;
  String _modelDirError = '';
  bool _isSkillsLoading = false;
  List<Map<String, dynamic>> _skills = [];
  bool _botsLoaded = false;

  Map<String, dynamic> _systemInfo = {};

  void _closeSettings() {
    if (widget.onClose != null) {
      widget.onClose!();
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      _appState.setScreen('chat');
    }
  }

  @override
  void initState() {
    super.initState();
    _apiUrlController.text = _api.baseUrl;
    _fetchSettings();
    _fetchSystemInfo();
    _fetchSkills();
    _fetchBots();
  }

  Future<void> _fetchBots() async {
    await _appState.refreshScouts();
    if (mounted) setState(() => _botsLoaded = true);
  }

  @override
  void dispose() {
    _modelDirController.dispose();
    _apiUrlController.dispose();
    super.dispose();
  }

  Future<void> _fetchSettings() async {
    setState(() => _isLoading = true);
    final res = await _api.settings.getSettings();
    if (!mounted) return;
    setState(() {
      _modelDirController.text = res['model_dir'] ?? '';
      _modelDirValid = res['model_dir_valid'] ?? true;
      _modelDirError = res['model_dir_error']?.toString() ?? '';
      if (res.containsKey('shortcuts')) {
        _shortcuts = Map<String, String>.from(res['shortcuts']);
        _shortcuts.remove('toggle_theme');
      } else {
        _shortcuts = {};
      }
      _isLoading = false;
    });
  }

  Future<void> _fetchSystemInfo() async {
    final res = await _api.settings.getSystemInfo();
    if (!mounted) return;
    setState(() {
      _systemInfo = res;
    });
  }

  Future<void> _fetchSkills() async {
    if (mounted) {
      setState(() => _isSkillsLoading = true);
    }
    final res = await _api.settings.listSkills();
    if (!mounted) return;
    setState(() {
      if (res.containsKey('skills') && res['skills'] is List) {
        _skills = List<Map<String, dynamic>>.from(
          (res['skills'] as List).map(
            (item) => Map<String, dynamic>.from(item),
          ),
        );
      }
      _isSkillsLoading = false;
    });
    if (res.containsKey('error') && mounted) {
      _showSettingsMessage(res['error'].toString(), isError: true);
    }
  }

  Future<void> _importSkill() async {
    final selectedPath = await FilePicker.getDirectoryPath(
      dialogTitle: tr('settings.skills.importFolder'),
    );
    if (selectedPath == null || selectedPath.trim().isEmpty) return;

    setState(() => _isSkillsLoading = true);
    final res = await _api.settings.importSkill(
      selectedPath.trim(),
      enabled: true,
    );
    if (!mounted) return;
    setState(() => _isSkillsLoading = false);
    if (res.containsKey('error')) {
      _showSettingsMessage(res['error'].toString(), isError: true);
      return;
    }
    _showSettingsMessage(tr('settings.skills.imported'));
    await _fetchSkills();
  }

  Future<void> _rescanSkills() async {
    setState(() => _isSkillsLoading = true);
    final res = await _api.settings.rescanSkills();
    if (!mounted) return;
    setState(() {
      if (res.containsKey('skills') && res['skills'] is List) {
        _skills = List<Map<String, dynamic>>.from(
          (res['skills'] as List).map(
            (item) => Map<String, dynamic>.from(item),
          ),
        );
      }
      _isSkillsLoading = false;
    });
    if (res.containsKey('error')) {
      _showSettingsMessage(res['error'].toString(), isError: true);
    } else {
      _showSettingsMessage(tr('settings.skills.rescanned'));
    }
  }

  Future<void> _toggleSkill(String name, bool enabled) async {
    final res = await _api.settings.updateSkill(name, enabled: enabled);
    if (!mounted) return;
    if (res.containsKey('error')) {
      _showSettingsMessage(res['error'].toString(), isError: true);
      await _fetchSkills();
      return;
    }
    setState(() {
      _skills = _skills.map((skill) {
        if (skill['name'] == name) {
          return {...skill, 'enabled': enabled};
        }
        return skill;
      }).toList();
    });
  }

  Future<void> _deleteSkill(String name) async {
    final res = await _api.settings.deleteSkill(name);
    if (!mounted) return;
    if (res.containsKey('error')) {
      _showSettingsMessage(res['error'].toString(), isError: true);
      return;
    }
    _showSettingsMessage(tr('settings.skills.removed'));
    await _fetchSkills();
  }

  void _showSettingsMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    showTopNotification(
      context,
      message,
      color: isError ? Colors.redAccent : Colors.green,
    );
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);

    _api.baseUrl = _apiUrlController.text.trim();

    final res = await _api.settings.updateSettings(
      modelDir: _modelDirController.text.trim().isNotEmpty
          ? _modelDirController.text.trim()
          : null,
      shortcuts: _shortcuts.isNotEmpty ? _shortcuts : null,
    );

    setState(() => _isSaving = false);

    if (mounted) {
      if (res.containsKey('error')) {
        showTopNotification(context, res['error'], color: Colors.redAccent);
      } else {
        showTopNotification(
          context,
          tr('settings.save.success'),
          color: Colors.green,
        );
        final appState = AppState();
        appState.updateShortcutsMap(_shortcuts);

        _fetchSettings();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeSection = _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _buildActiveSection();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _closeSettings,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 2.5, sigmaY: 2.5),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.1),
                ),
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 20.0,
              ),
              child: GestureDetector(
                onTap: () {},
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 1380,
                    maxHeight: 900,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: SettingsPalette.glassBg,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: SettingsPalette.hairlineStrong,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.50),
                              blurRadius: 36,
                              offset: const Offset(0, 14),
                            ),
                          ],
                        ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Column(
                        children: [
                          _buildWindowHeader(),
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final isCompact = constraints.maxWidth < 700;

                                if (isCompact) {
                                  return Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        _buildCompactTopBar(),
                                        const SizedBox(height: 16),
                                        Expanded(
                                          child: _buildSectionViewport(
                                            activeSection,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }

                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLeftNavigationMenu(),
                                    Container(
                                      width: 1,
                                      color: Colors.white.withValues(
                                        alpha: 0.06,
                                      ),
                                    ),
                                    Expanded(
                                      child: _buildSectionViewport(
                                        activeSection,
                                        padding: const EdgeInsets.all(22.0),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWindowHeader() {
    final navItems = _navigationItems();
    final activeItem = _selectedSectionIndex < navItems.length
        ? navItems[_selectedSectionIndex]
        : null;
    final activeLabel = activeItem?['label'] as String? ?? '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
      decoration: BoxDecoration(
        color: SettingsPalette.surfaceNavStart.withValues(alpha: 0.35),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            tr('settings.nav.title').toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.6,
            ),
          ),
          if (activeLabel.isNotEmpty) ...[
            const SizedBox(width: 12),
            Text(
              '|',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.25),
                fontSize: 14,
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              activeLabel,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const Spacer(),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _closeSettings,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 20,
                  color: Colors.white70,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Whether the active section needs the full bounded viewport height
  /// (its own internal scrolling) instead of the outer scroll view.
  bool get _activeSectionFillsViewport => _selectedSectionIndex == 3;

  Widget _buildSectionViewport(
    Widget child, {
    EdgeInsetsGeometry padding = EdgeInsets.zero,
  }) {
    final Widget body = _activeSectionFillsViewport
        ? Padding(padding: padding, child: child)
        : SingleChildScrollView(padding: padding, child: child);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: KeyedSubtree(
        key: ValueKey<int>(_selectedSectionIndex),
        child: body,
      ),
    );
  }

  Widget _buildActiveSection() {
    switch (_selectedSectionIndex) {
      case 0:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: _buildGeneralSettingsCard()),
            const SizedBox(width: 20),
            Expanded(
              flex: 2,
              child: settingsSystemInfoCard(_systemInfo),
            ),
          ],
        );
      case 1:
        return _buildServerApiSettingsCard();
      case 2:
        return _buildShortcutsCard();
      case 3:
        return const BotManagementScreen();
      case 4:
        return _buildChatBotSettingsCard();
      case 5:
        return _buildSkillsCard();
      case 6:
        return const NodesScreen();
      default:
        return _buildGeneralSettingsCard();
    }
  }

  List<Map<String, dynamic>> _navigationItems() {
    return [
      {
        'label': tr('settings.nav.general'),
        'icon': Icons.tune_rounded,
        'color': const Color(0xFF00E5FF),
      },
      {
        'label': tr('settings.nav.serverApi'),
        'icon': Icons.dns_rounded,
        'color': const Color(0xFFBAA6FF),
      },
      {
        'label': tr('settings.nav.shortcuts'),
        'icon': Icons.keyboard_rounded,
        'color': const Color(0xFFFFC107),
      },
      {
        'label': tr('settings.nav.botManagement'),
        'icon': Icons.smart_toy_rounded,
        'color': const Color(0xFF4CAF50),
      },
      {
        'label': tr('settings.nav.chatBot'),
        'icon': Icons.auto_awesome_rounded,
        'color': const Color(0xFFFF5252),
      },
      {
        'label': tr('settings.nav.skills'),
        'icon': Icons.extension_rounded,
        'color': const Color(0xFF448AFF),
      },
      {
        'label': tr('settings.nav.nodes'),
        'icon': Icons.hub_rounded,
        'color': const Color(0xFFE040FB),
      },
    ];
  }

  Widget _buildLeftNavigationMenu() {
    final menuItems = _navigationItems();

    return Container(
      width: 230,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: SettingsPalette.surfaceNavStart.withValues(alpha: 0.25),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              key: const PageStorageKey('settings-left-navigation'),
              child: Column(
                children: menuItems.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final item = entry.value;
                  final isSelected = _selectedSectionIndex == idx;
                  final itemColor = (item['color'] as Color?) ?? SettingsPalette.accent;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () =>
                            setState(() => _selectedSectionIndex = idx),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 11,
                          ),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [
                                      itemColor.withValues(
                                        alpha: 0.28,
                                      ),
                                      itemColor.withValues(
                                        alpha: 0.08,
                                      ),
                                    ],
                                  )
                                : null,
                            color: isSelected
                                ? null
                                : Colors.white.withValues(alpha: 0.025),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? itemColor.withValues(
                                      alpha: 0.55,
                                    )
                                  : Colors.white.withValues(alpha: 0.04),
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: itemColor
                                          .withValues(alpha: 0.20),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? itemColor.withValues(
                                          alpha: 0.25,
                                        )
                                      : itemColor.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  item['icon'] as IconData,
                                  size: 18,
                                  color: isSelected
                                      ? itemColor
                                      : itemColor.withValues(alpha: 0.7),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  item['label'] as String,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.white.withValues(alpha: 0.75),
                                    fontSize: 13,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                  ),
                                ),
                              ),
                              AnimatedOpacity(
                                duration: const Duration(milliseconds: 200),
                                opacity: isSelected ? 1.0 : 0.0,
                                child: Icon(
                                  Icons.chevron_right_rounded,
                                  size: 18,
                                  color: itemColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactTopBar() {
    final menuItems = _navigationItems();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: SettingsPalette.surfaceNavStart.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: SingleChildScrollView(
        key: const PageStorageKey('settings-compact-top-navigation'),
        scrollDirection: Axis.horizontal,
        child: Row(
          children: menuItems.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            final isSelected = _selectedSectionIndex == idx;

            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _selectedSectionIndex = idx),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? SettingsPalette.accent.withValues(alpha: 0.20)
                          : Colors.white.withValues(alpha: 0.035),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? SettingsPalette.accent.withValues(alpha: 0.45)
                            : Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item['icon'] as IconData,
                          size: 17,
                          color: isSelected
                              ? SettingsPalette.accent
                              : SettingsPalette.textMuted,
                        ),
                        const SizedBox(width: 7),
                        Text(
                          item['label'] as String,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white60,
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                          ),
                        ),
                      ],
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

  Widget _buildGeneralSettingsCard() {
    return settingsGlassCard(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              tr('settings.general.title'),
              style: const TextStyle(
                color: SettingsPalette.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.02),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4DD0E1).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.folder_outlined, color: Color(0xFF4DD0E1), size: 22),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tr('settings.general.modelDirLabel'),
                                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      tr('settings.general.modelDirDescription'),
                                      style: const TextStyle(color: SettingsPalette.textMuted, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _modelDirController,
                                  onChanged: (_) {
                                    if (!_modelDirValid) {
                                      setState(() {
                                        _modelDirValid = true;
                                        _modelDirError = '';
                                      });
                                    }
                                  },
                                  style: const TextStyle(
                                    color: SettingsPalette.textPrimary,
                                    fontSize: 14,
                                  ),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: SettingsPalette.surfaceInput,
                                    hintText: tr('settings.general.modelDirHint'),
                                    hintStyle: const TextStyle(
                                      color: SettingsPalette.textHint,
                                      fontSize: 13,
                                    ),
                                    errorText: _modelDirValid ? null : _modelDirError,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Tooltip(
                                message: tr('settings.general.browseTooltip'),
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    final selected =
                                        await FilePicker.getDirectoryPath(
                                          dialogTitle: tr(
                                            'settings.general.modelDirPickerTitle',
                                          ),
                                        );
                                    if (selected != null &&
                                        selected.trim().isNotEmpty &&
                                        mounted) {
                                      setState(() {
                                        _modelDirController.text = selected;
                                      });
                                    }
                                  },
                                  icon: const Icon(
                                    Icons.folder_open_rounded,
                                    size: 18,
                                    color: CulpeoColors.actionHover,
                                  ),
                                  label: const Text(
                                    'Durchsuchen',
                                    style: TextStyle(
                                      color: CulpeoColors.actionHover,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: CulpeoColors.actionHover,
                                    backgroundColor: CulpeoColors.action.withValues(alpha: 0.10),
                                    side: BorderSide(
                                      color: CulpeoColors.actionHover.withValues(alpha: 0.45),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 18,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.02),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFBAA6FF).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.link_rounded, color: Color(0xFFBAA6FF), size: 22),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tr('settings.general.apiUrlLabel'),
                                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      tr('settings.general.apiUrlDescription'),
                                      style: const TextStyle(color: SettingsPalette.textMuted, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _apiUrlController,
                            style: const TextStyle(
                              color: SettingsPalette.textPrimary,
                              fontSize: 14,
                            ),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: SettingsPalette.surfaceInput,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      tr('settings.appearance').toUpperCase(),
                      style: const TextStyle(
                        color: SettingsPalette.textMuted,
                        fontSize: 10,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildAppearanceSettings(),
                    if (_appState.guestModeActive) ...[
                      const SizedBox(height: 24),
                      Text(
                        'ACCOUNT & SICHERHEIT',
                        style: const TextStyle(
                          color: SettingsPalette.textMuted,
                          fontSize: 10,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _appState.isLoading
                            ? null
                            : () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Multi-Account aktivieren'),
                                    content: const Text(
                                      'Dadurch wirst du abgemeldet und musst einen sicheren Account mit Passwort und Authenticator-App (TOTP) erstellen. Fortfahren?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(false),
                                        child: const Text('Abbrechen'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(true),
                                        child: const Text('Fortfahren'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await _appState.disableGuestMode();
                                  _appState.logout();
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent.withValues(alpha: 0.2),
                          foregroundColor: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Multi-Account (Registrierung) aktivieren'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [CulpeoColors.action, CulpeoColors.actionHover],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: CulpeoColors.actionHover.withValues(alpha: 0.38),
                    blurRadius: 18,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(
                            Colors.white,
                          ),
                        ),
                      )
                    // The label is a full sentence in some languages and the
                  // button is as narrow as the column it sits in, so it
                  // shrinks to fit rather than overflowing - truncating the
                  // primary action would be worse than a slightly smaller
                  // label.
                  : FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              tr('settings.general.saveButton'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _changeLanguage(String language) async {
    final saved = await _appState.setLanguage(language);
    if (!saved && mounted) {
      _showSettingsMessage(userPreferencesText('saveFailed'), isError: true);
    }
  }

  Future<void> _retryUserPreferencesSave() async {
    final saved = await _appState.retryUserPreferencesSave();
    if (!saved && mounted) {
      _showSettingsMessage(userPreferencesText('saveFailed'), isError: true);
    }
  }

  Widget _buildAppearanceSettings() {
    InputDecoration dropdownDecoration() => InputDecoration(
      filled: true,
      fillColor: SettingsPalette.surfaceInput,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
    );

    const labelStyle = TextStyle(
      color: SettingsPalette.textSecondary,
      fontSize: 12,
    );

    return AnimatedBuilder(
      animation: _appState,
      builder: (context, _) {
        final isSaving = _appState.isSavingUserPreferences;
        final saveFailed = _appState.userPreferencesError != null;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(tr('settings.language'), style: labelStyle),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              key: ValueKey('settings-language-${_appState.language}'),
              initialValue: _appState.language,
              isExpanded: true,
              dropdownColor: SettingsPalette.surfaceNavStart,
              style: const TextStyle(
                color: SettingsPalette.textPrimary,
                fontSize: 14,
              ),
              decoration: dropdownDecoration(),
              items: [
                DropdownMenuItem(
                  value: 'de',
                  child: Text(
                    tr('onboarding.languageGerman'),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                DropdownMenuItem(
                  value: 'en',
                  child: Text(
                    tr('onboarding.languageEnglish'),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              onChanged: isSaving
                  ? null
                  : (value) {
                      if (value != null) {
                        _changeLanguage(value);
                      }
                    },
            ),
            if (isSaving) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Text(userPreferencesText('saving'), style: labelStyle),
                ],
              ),
            ],
            if (saveFailed) ...[
              const SizedBox(height: 12),
              Text(
                userPreferencesText('saveFailed'),
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
              if (_appState.canRetryUserPreferencesSave)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: isSaving ? null : _retryUserPreferencesSave,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: Text(userPreferencesText('retry')),
                  ),
                ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildServerApiSettingsCard() {
    return AnbieterSection(
      onActiveModelsChanged: _appState.refreshActiveApiModels,
    );
  }

  Widget _buildChatBotSettingsCard() {
    final bots = _appState.scouts
        .whereType<Map>()
        .map((bot) => ScoutChoice.fromJson(Map<String, dynamic>.from(bot)))
        .where((bot) => bot.id.isNotEmpty)
        .toList();

    return settingsGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            tr('settings.chatBot.title'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            tr('settings.chatBot.description'),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.52),
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            tr('settings.chatBot.defaultLabel'),
            style: const TextStyle(
              color: SettingsPalette.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          if (!_botsLoaded)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            )
          else if (bots.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: SettingsPalette.surfaceInput,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.smart_toy_outlined,
                        color: SettingsPalette.textHintFaint,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          tr('settings.chatBot.empty'),
                          style: const TextStyle(
                            color: SettingsPalette.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () =>
                          setState(() => _selectedSectionIndex = 3),
                      icon: const Icon(
                        Icons.settings_suggest_outlined,
                        size: 16,
                      ),
                      label: Text(tr('settings.chatBot.openManagement')),
                      style: TextButton.styleFrom(
                        foregroundColor: SettingsPalette.accent,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            BotPicker(
              bots: bots,
              selectedBotId: _appState.preferredBotId,
              useBottomSheet: false,
              onSelected: (botId) {
                setState(() => _appState.setPreferredBotId(botId));
              },
            ),
          const SizedBox(height: 14),
          Text(
            tr('settings.chatBot.note'),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.34),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsCard() {
    return settingsGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  tr('settings.skills.title'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: _isSkillsLoading ? null : _rescanSkills,
                icon: const Icon(Icons.refresh, size: 18),
                color: SettingsPalette.textSecondary,
                tooltip: tr('settings.skills.rescanTooltip'),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _isSkillsLoading ? null : _importSkill,
                icon: const Icon(Icons.create_new_folder_outlined, size: 16),
                label: Text(
                  tr('settings.skills.importFolder'),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: SettingsPalette.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            tr('settings.skills.description'),
            style: const TextStyle(
              color: SettingsPalette.textFaint,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_isSkillsLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        SettingsPalette.accent,
                      ),
                    ),
                  ),
                )
              else if (_skills.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: SettingsPalette.surfaceInput,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.extension_outlined,
                        color: SettingsPalette.textHintFaint,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          tr('settings.skills.empty'),
                          style: const TextStyle(
                            color: SettingsPalette.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ..._skills.map(
                  (s) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: settingsSkillTile(
                      s,
                      onToggle: _toggleSkill,
                      onDelete: _deleteSkill,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShortcutsCard() {
    final actionLabels = {
      'switch_to_chat': tr('settings.shortcuts.action.switchToChat'),
      'switch_to_spark': tr('settings.shortcuts.action.switchToSpark'),
      'switch_to_engine': tr('settings.shortcuts.action.switchToEngine'),
      'switch_to_marketplace': tr(
        'settings.shortcuts.action.switchToMarketplace',
      ),
      'switch_to_news': tr('settings.shortcuts.action.switchToNews'),
      'switch_to_settings': tr('settings.shortcuts.action.switchToSettings'),
      'toggle_sidebar': tr('settings.shortcuts.action.toggleSidebar'),
      'focus_chat_input': tr('settings.shortcuts.action.focusChatInput'),
      'new_chat_session': tr('settings.shortcuts.action.newChatSession'),
      'toggle_chat_tab': tr('settings.shortcuts.action.toggleChatTab'),
      'toggle_engine': tr('settings.shortcuts.action.toggleEngine'),
      'load_model': tr('settings.shortcuts.action.loadModel'),
      'focus_search': tr('settings.shortcuts.action.focusSearch'),
      'show_help': tr('settings.shortcuts.action.showHelp'),
    };

    return settingsGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            tr('settings.shortcuts.title'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            tr('settings.shortcuts.description'),
            style: const TextStyle(
              color: SettingsPalette.textFaint,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: actionLabels.entries.map((entry) {
              final action = entry.key;
              final label = entry.value;
              final shortcut = _shortcuts[action] ?? '';
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: SettingsPalette.surfaceInput,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: SettingsPalette.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    ShortcutRecorder(
                      shortcut: shortcut,
                      onChanged: (newShortcut) {
                        setState(() {
                          _shortcuts[action] = newShortcut;
                        });
                      },
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isSaving ? null : _saveSettings,
            style: ElevatedButton.styleFrom(
              backgroundColor: SettingsPalette.accent,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : Text(
                    tr('settings.general.saveButton'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
