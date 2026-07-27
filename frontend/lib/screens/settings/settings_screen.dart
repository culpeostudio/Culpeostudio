import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:ui';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_strings.dart';
import '../../l10n/user_preferences_strings.dart';
import '../../services/api_service.dart';
import '../../state/app_state.dart';
import '../../widgets/top_notification.dart';
import '../bots/bot_management_screen.dart';
import '../chat/bot_picker.dart';
import 'provider_card.dart';
import 'settings_cards.dart';
import 'settings_widgets.dart';
import 'shortcut_recorder.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ApiService _api = ApiService();
  final AppState _appState = AppState();
  Map<String, String> _shortcuts = {};
  int _selectedSectionIndex = 0;

  // Settings Controllers
  final _modelDirController = TextEditingController();
  final _hfTokenController = TextEditingController();
  final _openRouterTokenController = TextEditingController();
  final _featherlessTokenController = TextEditingController();

  // API Url Config
  final _apiUrlController = TextEditingController();

  bool _isLoading = false;
  bool _isSaving = false;

  bool _hfTokenSet = false;
  bool _openRouterTokenSet = false;
  bool _featherlessTokenSet = false;
  bool _modelDirValid = true;
  String _modelDirError = '';
  bool _isSkillsLoading = false;
  List<Map<String, dynamic>> _skills = [];

  // System Info
  Map<String, dynamic> _systemInfo = {};

  // Provider health check states
  final Map<String, String> _providerHealthStatus = {
    'huggingface': 'checking',
    'openrouter': 'checking',
    'featherless': 'checking',
    'backend': 'checking',
  };
  final Map<String, String> _providerHealthMessage = {
    'huggingface': '',
    'openrouter': '',
    'featherless': '',
    'backend': '',
  };

  // Custom user API nodes
  List<Map<String, dynamic>> _customNodes = [];

  Future<void> _loadCustomNodes() async {
    try {
      final file = File('data/custom_nodes.json');
      if (await file.exists()) {
        final content = await file.readAsString();
        final list = jsonDecode(content);
        if (list is List) {
          setState(() {
            _customNodes = List<Map<String, dynamic>>.from(
              list.map((item) => Map<String, dynamic>.from(item)),
            );
          });
        }
      }
    } catch (_) {
      // ignore
    }
  }

  Future<void> _saveCustomNodes() async {
    try {
      final file = File('data/custom_nodes.json');
      if (!await file.parent.exists()) {
        await file.parent.create(recursive: true);
      }
      await file.writeAsString(jsonEncode(_customNodes));
    } catch (_) {
      // ignore
    }
  }

  Future<void> _checkAllProviders() async {
    _checkProviderHealth('backend');
    _checkProviderHealth('huggingface');
    _checkProviderHealth('openrouter');
    _checkProviderHealth('featherless');
    for (final node in _customNodes) {
      _checkCustomNodeHealth(node);
    }
  }

  Future<void> _checkCustomNodeHealth(Map<String, dynamic> node) async {
    final id = node['id'].toString();
    final urlStr = node['url'].toString();

    if (!mounted) return;
    setState(() {
      _providerHealthStatus[id] = 'checking';
      _providerHealthMessage[id] = '';
    });

    try {
      final uri = Uri.parse(urlStr);
      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      if (!mounted) return;
      setState(() {
        final reachable =
            response.statusCode >= 200 && response.statusCode < 400;
        _providerHealthStatus[id] = reachable ? 'ok' : 'error';
        _providerHealthMessage[id] = reachable
            ? tr('settings.health.reachable')
            : tr('settings.health.httpResponse', {
                'code': '${response.statusCode}',
              });
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _providerHealthStatus[id] = 'error';
        _providerHealthMessage[id] = tr('settings.health.unreachable');
      });
    }
  }

  Future<void> _checkProviderHealth(String provider) async {
    if (!mounted) return;
    setState(() {
      _providerHealthStatus[provider] = 'checking';
      _providerHealthMessage[provider] = '';
    });

    if (provider == 'backend') {
      try {
        final res = await _api.getSystemInfo();
        if (!mounted) return;
        if (res.containsKey('error')) {
          setState(() {
            _providerHealthStatus['backend'] = 'error';
            _providerHealthMessage['backend'] = tr(
              'settings.health.unreachable',
            );
          });
        } else {
          setState(() {
            _providerHealthStatus['backend'] = 'ok';
            _providerHealthMessage['backend'] = tr('settings.health.reachable');
          });
        }
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _providerHealthStatus['backend'] = 'error';
          _providerHealthMessage['backend'] = tr('settings.health.unreachable');
        });
      }
      return;
    }

    try {
      final res = await _api.testProviderConnection(provider);
      if (!mounted) return;
      if (res.containsKey('error')) {
        setState(() {
          _providerHealthStatus[provider] = 'error';
          _providerHealthMessage[provider] = res['error'].toString();
        });
      } else {
        final reachable = res['reachable'] == true;
        setState(() {
          _providerHealthStatus[provider] = reachable ? 'ok' : 'error';
          _providerHealthMessage[provider] =
              res['message']?.toString() ??
              (reachable
                  ? tr('settings.health.reachable')
                  : tr('settings.health.error'));
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _providerHealthStatus[provider] = 'error';
        _providerHealthMessage[provider] = e.toString();
      });
    }
  }

  Future<void> _launchUrl(String urlString) async {
    try {
      final uri = Uri.parse(urlString);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      // ignore
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
    _loadCustomNodes().then((_) => _checkAllProviders());
  }

  Future<void> _fetchBots() async {
    await _appState.refreshPhiloBots();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _modelDirController.dispose();
    _hfTokenController.dispose();
    _openRouterTokenController.dispose();
    _featherlessTokenController.dispose();
    _apiUrlController.dispose();
    super.dispose();
  }

  Future<void> _fetchSettings() async {
    setState(() => _isLoading = true);
    final res = await _api.getSettings();
    setState(() {
      _modelDirController.text = res['model_dir'] ?? '';
      _modelDirValid = res['model_dir_valid'] ?? true;
      _modelDirError = res['model_dir_error']?.toString() ?? '';
      _hfTokenSet = res['huggingface_token_set'] ?? false;
      _openRouterTokenSet = res['openrouter_token_set'] ?? false;
      _featherlessTokenSet = res['featherless_token_set'] ?? false;
      if (res.containsKey('shortcuts')) {
        _shortcuts = Map<String, String>.from(res['shortcuts']);
      } else {
        _shortcuts = {};
      }
      _isLoading = false;
    });
  }

  Future<void> _fetchSystemInfo() async {
    final res = await _api.getSystemInfo();
    setState(() {
      _systemInfo = res;
    });
  }

  Future<void> _fetchSkills() async {
    if (mounted) {
      setState(() => _isSkillsLoading = true);
    }
    final res = await _api.listSkills();
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
    final res = await _api.importSkill(selectedPath.trim(), enabled: true);
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
    final res = await _api.rescanSkills();
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
    final res = await _api.updateSkill(name, enabled: enabled);
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
    final res = await _api.deleteSkill(name);
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

    // Update API Endpoint URL
    _api.baseUrl = _apiUrlController.text.trim();

    // Update settings in database
    final res = await _api.updateSettings(
      modelDir: _modelDirController.text.trim().isNotEmpty
          ? _modelDirController.text.trim()
          : null,
      huggingfaceToken: _hfTokenController.text.trim().isNotEmpty
          ? _hfTokenController.text.trim()
          : null,
      openrouterToken: _openRouterTokenController.text.trim().isNotEmpty
          ? _openRouterTokenController.text.trim()
          : null,
      featherlessToken: _featherlessTokenController.text.trim().isNotEmpty
          ? _featherlessTokenController.text.trim()
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
        _hfTokenController.clear();
        _openRouterTokenController.clear();
        _featherlessTokenController.clear();

        // Sync to AppState
        final appState = AppState();
        appState.updateShortcutsMap(_shortcuts);

        _fetchSettings();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left side: Active Settings Section
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildActiveSection(),
          ),
          const SizedBox(width: 24),
          // Right side: Vertical selection menu
          _buildRightNavigationMenu(),
        ],
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
            const SizedBox(width: 24),
            Expanded(
              flex: 2,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  settingsSystemInfoCard(_systemInfo),
                  const SizedBox(height: 20),
                  settingsHelpCard(),
                ],
              ),
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
      default:
        return _buildGeneralSettingsCard();
    }
  }

  static const double _navItemHeight = 54.0;
  static const double _navItemSpacing = 10.0;

  Widget _buildRightNavigationMenu() {
    final menuItems = [
      {'label': tr('settings.nav.general'), 'icon': Icons.settings_outlined},
      {'label': tr('settings.nav.serverApi'), 'icon': Icons.dns_outlined},
      {'label': tr('settings.nav.shortcuts'), 'icon': Icons.keyboard_outlined},
      {
        'label': tr('settings.nav.botManagement'),
        'icon': Icons.smart_toy_outlined,
      },
      {
        'label': tr('settings.nav.chatBot'),
        'icon': Icons.auto_awesome_outlined,
      },
      {'label': tr('settings.nav.skills'), 'icon': Icons.extension_outlined},
    ];

    return Container(
      width: 236,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            SettingsPalette.surfaceNavStart,
            SettingsPalette.surfaceNavEnd,
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 14,
                decoration: BoxDecoration(
                  color: SettingsPalette.accent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                tr('settings.nav.title'),
                style: const TextStyle(
                  color: SettingsPalette.textFaint,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                top: _selectedSectionIndex * (_navItemHeight + _navItemSpacing),
                left: 0,
                right: 0,
                height: _navItemHeight,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        SettingsPalette.accent.withValues(alpha: 0.24),
                        SettingsPalette.accent.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: SettingsPalette.accent.withValues(alpha: 0.45),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: SettingsPalette.accent.withValues(alpha: 0.18),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                ),
              ),
              Column(
                children: menuItems.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final item = entry.value;
                  final isSelected = _selectedSectionIndex == idx;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: _navItemSpacing),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(13),
                        onTap: () =>
                            setState(() => _selectedSectionIndex = idx),
                        child: SizedBox(
                          height: _navItemHeight,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 220),
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? SettingsPalette.accent.withValues(
                                            alpha: 0.20,
                                          )
                                        : Colors.white.withValues(alpha: 0.04),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    item['icon'] as IconData,
                                    size: 17,
                                    color: isSelected
                                        ? SettingsPalette.accent
                                        : SettingsPalette.textMuted,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    item['label'] as String,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.white60,
                                      fontSize: 13,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                    ),
                                  ),
                                ),
                                AnimatedOpacity(
                                  duration: const Duration(milliseconds: 200),
                                  opacity: isSelected ? 1 : 0,
                                  child: const Icon(
                                    Icons.chevron_right_rounded,
                                    size: 18,
                                    color: SettingsPalette.accent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ],
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
                    Text(
                      tr('settings.general.modelDirLabel'),
                      style: const TextStyle(
                        color: SettingsPalette.textMuted,
                        fontSize: 10,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tr('settings.general.modelDirDescription'),
                      style: const TextStyle(
                        color: SettingsPalette.textFaint,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
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
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
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
                            ),
                            label: Text(tr('settings.general.browse')),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: SettingsPalette.accent,
                              side: BorderSide(
                                color: SettingsPalette.hairlineStrong,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      tr('settings.general.apiUrlLabel'),
                      style: const TextStyle(
                        color: SettingsPalette.textMuted,
                        fontSize: 10,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tr('settings.general.apiUrlDescription'),
                      style: const TextStyle(
                        color: SettingsPalette.textFaint,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
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
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
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
                  ],
                ),
              ),
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
                        valueColor: AlwaysStoppedAnimation(
                          SettingsPalette.textPrimary,
                        ),
                      ),
                    )
                  : Text(
                      tr('settings.general.saveButton'),
                      style: const TextStyle(
                        color: SettingsPalette.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
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

  Future<void> _changeFrontendVersion(String frontendVersion) async {
    final saved = await _appState.setFrontendVersion(frontendVersion);
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

  /// Sprach- und Frontend-Versionswahl. The authenticated profile is the
  /// source of truth; AppState updates the controls only after a successful
  /// server response and exposes a retry path on failure.
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
            const SizedBox(height: 16),
            Text(tr('settings.frontendVersion'), style: labelStyle),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              key: ValueKey(
                'settings-frontend-version-${_appState.frontendVersion}',
              ),
              initialValue: _appState.frontendVersion,
              isExpanded: true,
              dropdownColor: SettingsPalette.surfaceNavStart,
              style: const TextStyle(
                color: SettingsPalette.textPrimary,
                fontSize: 14,
              ),
              decoration: dropdownDecoration(),
              items: [
                DropdownMenuItem(
                  value: 'classic',
                  child: Text(
                    tr('settings.frontendVersionClassic'),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                DropdownMenuItem(
                  value: 'lite',
                  child: Text(
                    tr('settings.frontendVersionLite'),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              onChanged: isSaving
                  ? null
                  : (value) {
                      if (value != null) {
                        _changeFrontendVersion(value);
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
    return settingsGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Expanded/Flexible, damit die Ueberschrift bei schmalem Fenster
              // schrumpfen kann, statt die Zeile ueber den Rand zu schieben.
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 24,
                      decoration: BoxDecoration(
                        color: SettingsPalette.accent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr('settings.serverApi.title'),
                            style: const TextStyle(
                              color: SettingsPalette.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tr('settings.serverApi.subtitle'),
                            style: const TextStyle(
                              color: SettingsPalette.textFaint,
                              fontSize: 12,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: _checkAllProviders,
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    color: SettingsPalette.textSecondary,
                    tooltip: tr('settings.serverApi.recheckTooltip'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _showAddCustomNodeDialog,
                    icon: const Icon(
                      Icons.add_circle_outline_rounded,
                      size: 15,
                      color: SettingsPalette.textPrimary,
                    ),
                    label: Text(
                      tr('settings.serverApi.addNode'),
                      style: const TextStyle(
                        color: SettingsPalette.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SettingsPalette.accent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 4,
                      shadowColor: SettingsPalette.accent.withValues(
                        alpha: 0.4,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          settingsPhaseNoteBanner(
            title: tr('settings.serverApi.phaseNote.title'),
            body: tr('settings.serverApi.phaseNote.body'),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _buildProviderCard(
                    id: 'backend',
                    title: tr('settings.serverApi.localServer'),
                    subtitle: _apiUrlController.text,
                    icon: Icons.computer_rounded,
                    emoji: '',
                    isKeySet: true,
                    accentColor: const Color(0xFF4CAF50),
                    gradientColors: [
                      const Color(0xFF1D291F),
                      const Color(0xFF151C16),
                    ],
                    onTap: () {},
                  ),
                  _buildProviderCard(
                    id: 'huggingface',
                    title: 'Hugging Face',
                    subtitle: 'huggingface.co',
                    icon: Icons.face_rounded,
                    emoji: '🤗',
                    isKeySet: _hfTokenSet,
                    accentColor: const Color(0xFFFFD21E),
                    gradientColors: [
                      const Color(0xFF2E2A1F),
                      const Color(0xFF221F17),
                    ],
                    onTap: () => _showTokenEditDialog(
                      'huggingface',
                      'Hugging Face Token',
                      _hfTokenSet,
                    ),
                  ),
                  _buildProviderCard(
                    id: 'openrouter',
                    title: 'OpenRouter',
                    subtitle: 'openrouter.ai',
                    icon: Icons.route_rounded,
                    emoji: '🤖',
                    isKeySet: _openRouterTokenSet,
                    accentColor: const Color(0xFF00C6FF),
                    gradientColors: [
                      const Color(0xFF1D2635),
                      const Color(0xFF151B26),
                    ],
                    onTap: () => _showTokenEditDialog(
                      'openrouter',
                      'OpenRouter Token',
                      _openRouterTokenSet,
                    ),
                  ),
                  _buildProviderCard(
                    id: 'featherless',
                    title: 'Featherless',
                    subtitle: 'api.featherless.ai',
                    icon: Icons.cloud_queue_rounded,
                    emoji: '☁️',
                    isKeySet: _featherlessTokenSet,
                    accentColor: const Color(0xFFAB47BC),
                    gradientColors: [
                      const Color(0xFF2A1E31),
                      const Color(0xFF1E1523),
                    ],
                    onTap: () => _showTokenEditDialog(
                      'featherless',
                      'Featherless Token',
                      _featherlessTokenSet,
                    ),
                  ),
                  // Render Custom Nodes
                  ..._customNodes.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final node = entry.value;
                    final color = customNodeColor(idx);
                    final name =
                        node['name']?.toString() ??
                        tr('settings.customNode.fallbackName');
                    final url = node['url']?.toString() ?? '';
                    final isKeySet =
                        node['key']?.toString().isNotEmpty ?? false;
                    final id = node['id'].toString();

                    return _buildProviderCard(
                      id: id,
                      title: name,
                      subtitle: url,
                      icon: Icons.hub_outlined,
                      emoji: '',
                      isKeySet: isKeySet,
                      accentColor: color,
                      gradientColors: [
                        color.withValues(alpha: 0.08),
                        SettingsPalette.surfaceRaised,
                      ],
                      onTap: () => _showEditCustomNodeDialog(node),
                      isCustom: true,
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderCard({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
    required String emoji,
    required bool isKeySet,
    required Color accentColor,
    required List<Color> gradientColors,
    required VoidCallback onTap,
    bool isCustom = false,
  }) {
    final health = _providerHealthStatus[id] ?? 'checking';
    final healthMsg = _providerHealthMessage[id] ?? '';

    return ProviderCardWidget(
      id: id,
      title: title,
      subtitle: subtitle,
      icon: icon,
      emoji: emoji,
      isKeySet: isKeySet,
      accentColor: accentColor,
      gradientColors: gradientColors,
      onTap: onTap,
      logoBuilder: _buildProviderLogo,
      health: health,
      healthMsg: healthMsg,
      isCustom: isCustom,
    );
  }

  Widget _buildProviderLogo(
    String id,
    String title,
    Color accentColor,
    String emoji,
    IconData icon,
  ) {
    if (id == 'backend') {
      return Image.asset(
        'assets/logo.png',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) =>
            Icon(icon, color: accentColor, size: 20),
      );
    } else if (id == 'huggingface') {
      return Image.asset(
        'assets/huggingface.png',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) =>
            Text(emoji, style: const TextStyle(fontSize: 18)),
      );
    } else if (id == 'openrouter') {
      return Image.asset(
        'assets/openrouter.png',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) =>
            Text(emoji, style: const TextStyle(fontSize: 18)),
      );
    } else if (id == 'featherless') {
      return Image.asset(
        'assets/featherless.png',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) =>
            Text(emoji, style: const TextStyle(fontSize: 18)),
      );
    } else {
      // Custom Node logo: rounded block with the first character of the title
      return Container(
        alignment: Alignment.center,
        child: Text(
          title.isNotEmpty ? title.substring(0, 1).toUpperCase() : 'N',
          style: TextStyle(
            color: accentColor,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      );
    }
  }

  void _showAddCustomNodeDialog() {
    final nameController = TextEditingController();
    final urlController = TextEditingController();
    final keyController = TextEditingController();
    bool obscureText = true;

    showDialog(
      context: context,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              return Dialog(
                backgroundColor: SettingsPalette.dialogScrim,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 440),
                  padding: const EdgeInsets.all(24),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header
                        Row(
                          children: [
                            const Icon(
                              Icons.hub_outlined,
                              color: SettingsPalette.accent,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                tr('settings.customNode.addTitle'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: SettingsPalette.textFaint,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          tr('settings.customNode.addDescription'),
                          style: const TextStyle(
                            color: SettingsPalette.textMuted,
                            fontSize: 12,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          tr('settings.customNode.nameLabel'),
                          style: const TextStyle(
                            color: SettingsPalette.textFaint,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 6),
                        settingsDialogTextField(
                          controller: nameController,
                          hintText: tr('settings.customNode.nameHint'),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          tr('settings.customNode.urlLabel'),
                          style: const TextStyle(
                            color: SettingsPalette.textFaint,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 6),
                        settingsDialogTextField(
                          controller: urlController,
                          hintText: tr('settings.customNode.urlHint'),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          tr('settings.customNode.keyLabel'),
                          style: const TextStyle(
                            color: SettingsPalette.textFaint,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 6),
                        settingsDialogTextField(
                          controller: keyController,
                          hintText: tr('settings.customNode.keyHint'),
                          obscureText: obscureText,
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureText
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: SettingsPalette.textVeryFaint,
                              size: 18,
                            ),
                            onPressed: () {
                              setDialogState(() {
                                obscureText = !obscureText;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Actions row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                foregroundColor: SettingsPalette.textFaint,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                              ),
                              child: Text(tr('common.cancel')),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () async {
                                final name = nameController.text.trim();
                                final url = urlController.text.trim();
                                if (name.isNotEmpty && url.isNotEmpty) {
                                  Navigator.pop(context);
                                  final newNode = {
                                    'id':
                                        'custom_${DateTime.now().millisecondsSinceEpoch}',
                                    'name': name,
                                    'url': url,
                                    'key': keyController.text.trim(),
                                  };
                                  setState(() {
                                    _customNodes.add(newNode);
                                  });
                                  await _saveCustomNodes();
                                  _checkCustomNodeHealth(newNode);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: SettingsPalette.accent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              child: Text(
                                tr('settings.customNode.add'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    ).then((_) {
      nameController.dispose();
      urlController.dispose();
      keyController.dispose();
    });
  }

  void _showEditCustomNodeDialog(Map<String, dynamic> node) {
    final nameController = TextEditingController(text: node['name']);
    final urlController = TextEditingController(text: node['url']);
    final keyController = TextEditingController(text: node['key']);
    bool obscureText = true;

    showDialog(
      context: context,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              return Dialog(
                backgroundColor: SettingsPalette.dialogScrim,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 440),
                  padding: const EdgeInsets.all(24),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header
                        Row(
                          children: [
                            const Icon(
                              Icons.hub_outlined,
                              color: SettingsPalette.accent,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                tr('settings.customNode.editTitle'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: SettingsPalette.textFaint,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          tr('settings.customNode.editDescription'),
                          style: const TextStyle(
                            color: SettingsPalette.textMuted,
                            fontSize: 12,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          tr('settings.customNode.nameLabel'),
                          style: const TextStyle(
                            color: SettingsPalette.textFaint,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 6),
                        settingsDialogTextField(
                          controller: nameController,
                          hintText: tr('settings.customNode.nameHint'),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          tr('settings.customNode.urlLabel'),
                          style: const TextStyle(
                            color: SettingsPalette.textFaint,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 6),
                        settingsDialogTextField(
                          controller: urlController,
                          hintText: tr('settings.customNode.urlHint'),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          tr('settings.customNode.keyLabel'),
                          style: const TextStyle(
                            color: SettingsPalette.textFaint,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 6),
                        settingsDialogTextField(
                          controller: keyController,
                          hintText: tr('settings.customNode.keyHint'),
                          obscureText: obscureText,
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureText
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: SettingsPalette.textVeryFaint,
                              size: 18,
                            ),
                            onPressed: () {
                              setDialogState(() {
                                obscureText = !obscureText;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Actions row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                setState(() {
                                  _customNodes.removeWhere(
                                    (n) => n['id'] == node['id'],
                                  );
                                  _providerHealthStatus.remove(node['id']);
                                  _providerHealthMessage.remove(node['id']);
                                });
                                _saveCustomNodes();
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.redAccent,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                              ),
                              child: Text(
                                tr('settings.customNode.delete'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                foregroundColor: SettingsPalette.textFaint,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                              ),
                              child: Text(tr('common.cancel')),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () async {
                                final name = nameController.text.trim();
                                final url = urlController.text.trim();
                                if (name.isNotEmpty && url.isNotEmpty) {
                                  Navigator.pop(context);
                                  setState(() {
                                    node['name'] = name;
                                    node['url'] = url;
                                    node['key'] = keyController.text.trim();
                                  });
                                  await _saveCustomNodes();
                                  _checkCustomNodeHealth(node);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: SettingsPalette.accent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              child: Text(
                                tr('settings.customNode.save'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    ).then((_) {
      nameController.dispose();
      urlController.dispose();
      keyController.dispose();
    });
  }

  void _showTokenEditDialog(String provider, String title, bool isSet) {
    final controller = TextEditingController();
    bool obscureText = true;

    showDialog(
      context: context,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              return Dialog(
                backgroundColor: SettingsPalette.dialogScrim,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 440),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Row(
                        children: [
                          Icon(
                            provider == 'huggingface'
                                ? Icons.face_rounded
                                : (provider == 'openrouter'
                                      ? Icons.route_rounded
                                      : Icons.cloud_queue_rounded),
                            color: SettingsPalette.accent,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              tr('settings.token.setupTitle', {'title': title}),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: SettingsPalette.textFaint,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isSet
                            ? tr('settings.token.replaceDescription')
                            : tr('settings.token.enterDescription', {
                                'title': title,
                              }),
                        style: const TextStyle(
                          color: SettingsPalette.textMuted,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Link section to get keys (premium click tile)
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            if (provider == 'huggingface') {
                              _launchUrl(
                                'https://huggingface.co/settings/tokens',
                              );
                            } else if (provider == 'openrouter') {
                              _launchUrl('https://openrouter.ai/keys');
                            } else if (provider == 'featherless') {
                              _launchUrl('https://featherless.ai/');
                            }
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Ink(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: SettingsPalette.accent.withValues(
                                alpha: 0.06,
                              ),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: SettingsPalette.accent.withValues(
                                  alpha: 0.15,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.open_in_new_rounded,
                                  size: 14,
                                  color: SettingsPalette.accentSoft,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  provider == 'huggingface'
                                      ? tr('settings.token.hfLink')
                                      : provider == 'openrouter'
                                      ? tr('settings.token.orLink')
                                      : tr('settings.token.flLink'),
                                  style: const TextStyle(
                                    color: SettingsPalette.accentSoft,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      settingsDialogTextField(
                        controller: controller,
                        hintText: tr('settings.customNode.keyHint'),
                        obscureText: obscureText,
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureText
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: SettingsPalette.textVeryFaint,
                            size: 18,
                          ),
                          onPressed: () {
                            setDialogState(() {
                              obscureText = !obscureText;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Actions row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (isSet) ...[
                            TextButton(
                              onPressed: () async {
                                Navigator.pop(context);
                                await _updateSingleToken(provider, '');
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.redAccent,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                              ),
                              child: Text(
                                tr('settings.token.delete'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Spacer(),
                          ],
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              foregroundColor: SettingsPalette.textFaint,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                            ),
                            child: Text(tr('common.cancel')),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () async {
                              final val = controller.text.trim();
                              if (val.isNotEmpty) {
                                Navigator.pop(context);
                                await _updateSingleToken(provider, val);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: SettingsPalette.accent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              elevation: 2,
                            ),
                            child: Text(
                              tr('common.save'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    ).then((_) => controller.dispose());
  }

  Future<void> _updateSingleToken(String provider, String value) async {
    setState(() => _isLoading = true);
    final res = await _api.updateSettings(
      huggingfaceToken: provider == 'huggingface' ? value : null,
      openrouterToken: provider == 'openrouter' ? value : null,
      featherlessToken: provider == 'featherless' ? value : null,
    );

    setState(() => _isLoading = false);

    if (res.containsKey('error')) {
      _showSettingsMessage(res['error'].toString(), isError: true);
    } else {
      _showSettingsMessage(tr('settings.token.updated'));
      await _fetchSettings();
      _checkProviderHealth(provider);
    }
  }

  Widget _buildChatBotSettingsCard() {
    final bots = _appState.philoBots
        .whereType<Map>()
        .map((bot) => PhiloBotChoice.fromJson(Map<String, dynamic>.from(bot)))
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
          if (bots.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
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
          Expanded(
            child: SingleChildScrollView(
              child: Column(
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShortcutsCard() {
    final actionLabels = {
      'switch_to_chat': tr('settings.shortcuts.action.switchToChat'),
      'switch_to_philox': tr('settings.shortcuts.action.switchToPhilox'),
      'switch_to_engine': tr('settings.shortcuts.action.switchToEngine'),
      'switch_to_marketplace': tr(
        'settings.shortcuts.action.switchToMarketplace',
      ),
      'switch_to_training': tr('settings.shortcuts.action.switchToTraining'),
      'switch_to_quantization': tr(
        'settings.shortcuts.action.switchToQuantization',
      ),
      'switch_to_generative': tr(
        'settings.shortcuts.action.switchToGenerative',
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
      'toggle_theme': tr('settings.shortcuts.action.toggleTheme'),
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
          Expanded(
            child: SingleChildScrollView(
              child: Column(
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
            ),
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
