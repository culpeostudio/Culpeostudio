import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_strings.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_background.dart';
import '../../widgets/top_notification.dart';
import '../onboarding/onboarding_dialog.dart';
import '../chat/chat_history_panel.dart';
import '../chat/philobot_tab.dart';
import '../engine/engine_screen.dart';
import '../genstudio/genstudio_screen.dart';
import '../marketplace/marketplace_screen.dart';
import '../news/news_screen.dart';
import '../quantization/quantization_screen.dart';
import '../settings/settings_screen.dart';
import '../training/training_screen.dart';
import '../bots/bot_management_screen.dart';
import '../chat/model_management_dialog.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  static final Uri _benchmarkUri = Uri.parse(
    'https://artificialanalysis.ai/models',
  );

  final AppState _appState = AppState();
  bool _showSidebar = true;
  final Set<String> _expandedHistoryProjects = {};
  bool _isReorderingModules = false;
  bool _isSettingsHovered = false;
  bool _isLogoutHovered = false;
  bool _isHeaderHovered = false;
  bool _isThemeToggleHovered = false;
  bool _handleHovered = false;
  late AnimationController _settingsRotationController;
  late AnimationController _railController;
  late Animation<double> _railAnimation;

  final List<Map<String, dynamic>> _sidebarModules = [
    {'icon': Icons.forum_outlined, 'key': 'chat'},
    {'icon': Icons.memory_outlined, 'key': 'engine'},
    {'icon': Icons.storefront_outlined, 'key': 'marketplace'},
    {'icon': Icons.model_training_outlined, 'key': 'training'},
    {'icon': Icons.compress_outlined, 'key': 'quantization'},
    {'icon': Icons.movie_creation_outlined, 'key': 'generative'},
    {'icon': Icons.newspaper_outlined, 'key': 'news'},
    {'icon': Icons.speed_outlined, 'key': 'benchmark'},
  ];
  final List<Map<String, dynamic>> _deletedModules = [];

  /// Module, die in der Lite-Version sichtbar sind. Classic zeigt alle.
  static const Set<String> _liteModuleKeys = {
    'chat',
    'engine',
    'marketplace',
    'news',
    'benchmark',
  };

  /// Screens, die zwar nicht in der Sidebar stehen, aber in beiden Versionen
  /// erreichbar bleiben muessen (z. B. Settings ueber das Zahnrad).
  static const Set<String> _nonSidebarScreens = {
    'settings',
    'bot_management',
    'philox',
  };

  List<Map<String, dynamic>> get _visibleModules {
    if (_appState.frontendVersion != 'lite') return _sidebarModules;
    return _sidebarModules
        .where((m) => _liteModuleKeys.contains(m['key']))
        .toList();
  }

  /// Anzeigename eines Moduls ueber seinen Key (lokalisiert).
  static String _moduleLabel(String key) => tr('sidebar.$key');

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 320,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF0F0F14).withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.logout,
                      color: Colors.redAccent,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    tr('dashboard.logoutTitle'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tr('dashboard.logoutConfirm'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white60,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(tr('common.cancel')),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _appState.logout();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(tr('dashboard.logoutYes')),
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
    );
  }

  void _deleteModule(Map<String, dynamic> module) {
    setState(() {
      _sidebarModules.remove(module);
      _deletedModules.add(module);

      if (_appState.currentScreen == module['key']) {
        if (_sidebarModules.isNotEmpty) {
          _appState.setScreen(_sidebarModules.first['key'] as String);
        } else {
          _appState.setScreen('chat');
        }
      }
    });
  }

  void _restoreModule(Map<String, dynamic> module) {
    setState(() {
      _deletedModules.remove(module);
      _sidebarModules.add(module);
    });
  }

  // newIndex kommt bereits korrigiert vom ReorderableListView.onReorderItem-
  // Callback; die frühere manuelle `if (oldIndex < newIndex) newIndex -= 1`
  // Anpassung entfällt dadurch. Die Indizes beziehen sich auf die sichtbaren
  // Module; in der Lite-Version wird die neue Reihenfolge in die Gesamtliste
  // uebertragen, versteckte Module behalten ihre Position.
  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      final visible = List<Map<String, dynamic>>.of(_visibleModules);
      final moved = visible.removeAt(oldIndex);
      visible.insert(newIndex, moved);
      if (_appState.frontendVersion == 'lite') {
        final queue = List<Map<String, dynamic>>.of(visible);
        for (var i = 0; i < _sidebarModules.length && queue.isNotEmpty; i++) {
          if (_liteModuleKeys.contains(_sidebarModules[i]['key'])) {
            _sidebarModules[i] = queue.removeAt(0);
          }
        }
      } else {
        _sidebarModules
          ..clear()
          ..addAll(visible);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _appState.loadShortcuts();
    // Erster Login dieses Users: Sprache und Frontend-Version abfragen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _appState.needsOnboarding) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const OnboardingDialog(),
        );
      }
    });
    _settingsRotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _railController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 460),
      value: _showSidebar ? 1.0 : 0.0,
    );
    _railAnimation = CurvedAnimation(
      parent: _railController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void dispose() {
    _settingsRotationController.dispose();
    _railController.dispose();
    super.dispose();
  }

  void _toggleSidebar() {
    setState(() => _showSidebar = !_showSidebar);
    if (_showSidebar) {
      _railController.forward();
    } else {
      _railController.reverse();
    }
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.escape && !_showSidebar) {
      _toggleSidebar();
    }
  }

  Future<void> _handleBenchmarkTap() async {
    final shouldOpen = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF16161D),
          title: Text(
            tr('dashboard.benchmarkTitle'),
            style: const TextStyle(color: Colors.white),
          ),
          content: Text(
            tr('dashboard.benchmarkBody'),
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(tr('common.cancel')),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(tr('dashboard.benchmarkContinue')),
            ),
          ],
        );
      },
    );

    if (shouldOpen != true) {
      return;
    }

    try {
      final launched = await launchUrl(
        _benchmarkUri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        showTopNotification(
          context,
          tr('dashboard.benchmarkOpenFailed'),
          color: Colors.redAccent,
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      showTopNotification(
        context,
        tr('dashboard.benchmarkOpenError', {'error': '$error'}),
        color: Colors.redAccent,
      );
    }
  }

  /// Leitet eine Chat-Aktion (neuer Chat / Verlauf ein-/ausklappen) an den
  /// aktiven PhiloBotTab weiter. Ist der Chat-Screen noch nicht sichtbar,
  /// wird erst dorthin gewechselt und die Aktion nach dem Aufbau des Tabs
  /// nachgereicht, da PhiloBotTab seinen actionStream-Listener erst in
  /// initState registriert.
  void _triggerChatAction(String action) {
    if (_appState.currentScreen != 'chat') {
      _appState.setScreen('chat');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _appState.triggerAction(action);
      });
    } else {
      _appState.triggerAction(action);
    }
  }

  Widget _buildBody(String screen) {
    switch (screen) {
      case 'chat':
        return const PhiloBotTab();
      case 'philox':
        return const PhiloBotTab();
      case 'engine':
        return const EngineScreen();
      case 'marketplace':
        return const MarketplaceScreen();
      case 'training':
        return const TrainingScreen();
      case 'quantization':
        return const QuantizationScreen();
      case 'generative':
        return const GenStudioScreen();
      case 'news':
        return const NewsScreen();
      case 'settings':
        return const SettingsScreen();
      case 'bot_management':
        return const BotManagementScreen();
      default:
        return const PhiloBotTab();
    }
  }

  String get _apiHost {
    final uri = Uri.tryParse(_appState.api.baseUrl);
    return (uri?.host.isNotEmpty ?? false) ? uri!.host : 'local';
  }

  Widget _buildSidebar(bool isDesktop) {
    final showExpanded = !isDesktop || _showSidebar;
    if (!showExpanded && _isReorderingModules) {
      _isReorderingModules = false;
    }
    final brightness = Theme.of(context).brightness;
    final textPrimary = AppColors.textPrimary(brightness);
    final textSecondary = AppColors.textSecondary(brightness);

    final content = ExcludeSemantics(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 150;
          return ClipRect(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 38,
                        height: 38,
                        child: Image.asset(
                          'assets/logo.png',
                          width: 36,
                          height: 36,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stack) => Text(
                            'φ',
                            textAlign: TextAlign.center,
                            style: AppFonts.serifItalic(
                              fontSize: 23,
                              color: AppColors.gold,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: AnimatedOpacity(
                          opacity: showExpanded ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          child: ClipRect(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: const NeverScrollableScrollPhysics(),
                              child: SizedBox(
                                width: 190,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(width: 10),
                                    MouseRegion(
                                      onEnter: (_) => setState(
                                        () => _isHeaderHovered = true,
                                      ),
                                      onExit: (_) => setState(
                                        () => _isHeaderHovered = false,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                'MYPHILO',
                                                maxLines: 1,
                                                overflow: TextOverflow.clip,
                                                style: TextStyle(
                                                  color: textPrimary,
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 1.0,
                                                ),
                                              ),
                                              Text(
                                                'ENGINE',
                                                maxLines: 1,
                                                overflow: TextOverflow.clip,
                                                style: AppFonts.mono(
                                                  fontSize: 9,
                                                  color: textSecondary,
                                                  letterSpacing: 2.0,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(width: 8),
                                          AnimatedOpacity(
                                            opacity:
                                                _isHeaderHovered ||
                                                    _isReorderingModules
                                                ? 1.0
                                                : 0.0,
                                            duration: const Duration(
                                              milliseconds: 200,
                                            ),
                                            child: GestureDetector(
                                              onTap:
                                                  (_isHeaderHovered ||
                                                      _isReorderingModules)
                                                  ? () => setState(
                                                      () => _isReorderingModules =
                                                          !_isReorderingModules,
                                                    )
                                                  : null,
                                              child: MouseRegion(
                                                cursor:
                                                    (_isHeaderHovered ||
                                                        _isReorderingModules)
                                                    ? SystemMouseCursors.click
                                                    : SystemMouseCursors.basic,
                                                child: Icon(
                                                  _isReorderingModules
                                                      ? Icons.check
                                                      : Icons.edit_outlined,
                                                  color: _isReorderingModules
                                                      ? AppColors.gold
                                                      : textSecondary
                                                            .withValues(
                                                              alpha: 0.5,
                                                            ),
                                                  size: 14,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: _isReorderingModules && isWide
                        ? ReorderableListView(
                            padding: EdgeInsets.zero,
                            onReorderItem: _onReorder,
                            children: _visibleModules.map((item) {
                              return _SidebarNavItem(
                                key: ValueKey(item['key']),
                                label: _moduleLabel(item['key'] as String),
                                icon: item['icon'] as IconData,
                                selected:
                                    _appState.currentScreen == item['key'],
                                showSidebar: showExpanded,
                                showExternalIndicator:
                                    item['key'] == 'benchmark',
                                isReorderMode: true,
                                onDelete: () => _deleteModule(item),
                                onTap: () {},
                              );
                            }).toList(),
                          )
                        : ListView(
                            padding: EdgeInsets.zero,
                            children: [
                              for (final item in _visibleModules) ...[
                                _SidebarNavItem(
                                  key: ValueKey(item['key']),
                                  label: _moduleLabel(item['key'] as String),
                                  icon: item['icon'] as IconData,
                                  selected:
                                      _appState.currentScreen == item['key'],
                                  showSidebar: showExpanded,
                                  showExternalIndicator:
                                      item['key'] == 'benchmark',
                                  trailingActionIcon: item['key'] == 'chat'
                                      ? Icons.add_comment_outlined
                                      : null,
                                  trailingActionTooltip: tr(
                                    'dashboard.tooltipNewChat',
                                  ),
                                  onTrailingAction: item['key'] == 'chat'
                                      ? () => _triggerChatAction(
                                          'new_chat_session',
                                        )
                                      : null,
                                  onTap: () {
                                    if (item['key'] == 'benchmark') {
                                      _handleBenchmarkTap();
                                      return;
                                    }
                                    _appState.setScreen(item['key'] as String);
                                  },
                                ),
                                // Der Verlauf erscheint automatisch, sobald
                                // der Chat-Screen aktiv ist, und verschwindet
                                // wieder, sobald man zu einem anderen Reiter
                                // wechselt - kein manuelles Auf-/Zuklappen.
                                if (item['key'] == 'chat' &&
                                    showExpanded &&
                                    _appState.currentScreen == 'chat')
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left: 12,
                                      right: 4,
                                      bottom: 6,
                                    ),
                                    child: ChatHistoryPanel(
                                      key: const Key('chat-history-panel'),
                                      appState: _appState,
                                      currentChatId:
                                          _appState.currentChatSessionId,
                                      expandedProjects:
                                          _expandedHistoryProjects,
                                      onNewChatInProject: (projectId) =>
                                          _triggerChatAction(
                                            'new_chat_session:$projectId',
                                          ),
                                      onSelectChat: (sessionId) {
                                        _appState.selectChatSession(sessionId);
                                        if (_appState.currentScreen != 'chat') {
                                          _appState.setScreen('chat');
                                        }
                                      },
                                      onRenameChat: (sessionId) =>
                                          promptRenameChatSession(
                                            context,
                                            _appState,
                                            sessionId,
                                          ),
                                      onDeleteChat: (sessionId) =>
                                          confirmDeleteChatSession(
                                            context,
                                            _appState,
                                            sessionId,
                                            onNeedNewSession: () =>
                                                _triggerChatAction(
                                                  'new_chat_session',
                                                ),
                                          ),
                                    ),
                                  ),
                              ],
                            ],
                          ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 18),
                  child: Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        height: 1,
                        color: AppColors.divider(brightness),
                      ),
                      isWide
                          ? Row(
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: AppColors.gold.withValues(
                                    alpha: 0.18,
                                  ),
                                  child: Text(
                                    (_appState.username ?? 'D')[0]
                                        .toUpperCase(),
                                    style: const TextStyle(
                                      color: AppColors.gold,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _appState.username ?? 'User',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: textPrimary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        _apiHost,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppFonts.mono(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w400,
                                          letterSpacing: 0.4,
                                          color: textSecondary.withValues(
                                            alpha: 0.6,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                MouseRegion(
                                  onEnter: (_) => setState(
                                    () => _isThemeToggleHovered = true,
                                  ),
                                  onExit: (_) => setState(
                                    () => _isThemeToggleHovered = false,
                                  ),
                                  child: IconButton(
                                    tooltip: brightness == Brightness.dark
                                        ? tr('dashboard.tooltipLightTheme')
                                        : tr('dashboard.tooltipDarkTheme'),
                                    constraints: const BoxConstraints.tightFor(
                                      width: 32,
                                      height: 32,
                                    ),
                                    padding: EdgeInsets.zero,
                                    icon: AnimatedSwitcher(
                                      duration: const Duration(
                                        milliseconds: 260,
                                      ),
                                      transitionBuilder: (child, animation) =>
                                          RotationTransition(
                                            turns: Tween<double>(
                                              begin: 0.72,
                                              end: 1,
                                            ).animate(animation),
                                            child: ScaleTransition(
                                              scale: animation,
                                              child: child,
                                            ),
                                          ),
                                      child: Icon(
                                        brightness == Brightness.dark
                                            ? Icons.light_mode_outlined
                                            : Icons.dark_mode_outlined,
                                        key: ValueKey(brightness),
                                        color: _isThemeToggleHovered
                                            ? AppColors.gold
                                            : textSecondary,
                                        size: 19,
                                      ),
                                    ),
                                    onPressed: () => _appState.toggleTheme(),
                                  ),
                                ),
                                MouseRegion(
                                  onEnter: (_) {
                                    setState(() => _isSettingsHovered = true);
                                    _settingsRotationController.repeat();
                                  },
                                  onExit: (_) {
                                    setState(() => _isSettingsHovered = false);
                                    _settingsRotationController.stop();
                                    _settingsRotationController.animateTo(
                                      0.0,
                                      duration: const Duration(
                                        milliseconds: 250,
                                      ),
                                      curve: Curves.easeOut,
                                    );
                                  },
                                  child: RotationTransition(
                                    turns: _settingsRotationController,
                                    child: IconButton(
                                      tooltip: tr('dashboard.tooltipSettings'),
                                      constraints:
                                          const BoxConstraints.tightFor(
                                            width: 32,
                                            height: 32,
                                          ),
                                      padding: EdgeInsets.zero,
                                      icon: Icon(
                                        Icons.settings_outlined,
                                        color: _isSettingsHovered
                                            ? AppColors.gold
                                            : textSecondary,
                                        size: 18,
                                      ),
                                      onPressed: () =>
                                          _appState.setScreen('settings'),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                MouseRegion(
                                  onEnter: (_) =>
                                      setState(() => _isLogoutHovered = true),
                                  onExit: (_) =>
                                      setState(() => _isLogoutHovered = false),
                                  child: IconButton(
                                    tooltip: tr('dashboard.tooltipLogout'),
                                    constraints: const BoxConstraints.tightFor(
                                      width: 32,
                                      height: 32,
                                    ),
                                    padding: EdgeInsets.zero,
                                    icon: Icon(
                                      Icons.logout,
                                      color: _isLogoutHovered
                                          ? Colors.redAccent
                                          : textSecondary,
                                      size: 18,
                                    ),
                                    onPressed: _confirmLogout,
                                  ),
                                ),
                              ],
                            )
                          : SizedBox(
                              width: 40,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: AppColors.gold.withValues(
                                      alpha: 0.18,
                                    ),
                                    child: Text(
                                      (_appState.username ?? 'D')[0]
                                          .toUpperCase(),
                                      style: const TextStyle(
                                        color: AppColors.gold,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  MouseRegion(
                                    onEnter: (_) => setState(
                                      () => _isThemeToggleHovered = true,
                                    ),
                                    onExit: (_) => setState(
                                      () => _isThemeToggleHovered = false,
                                    ),
                                    child: IconButton(
                                      tooltip: brightness == Brightness.dark
                                          ? tr('dashboard.tooltipLightTheme')
                                          : tr('dashboard.tooltipDarkTheme'),
                                      constraints:
                                          const BoxConstraints.tightFor(
                                            width: 40,
                                            height: 40,
                                          ),
                                      padding: EdgeInsets.zero,
                                      icon: AnimatedSwitcher(
                                        duration: const Duration(
                                          milliseconds: 260,
                                        ),
                                        transitionBuilder: (child, animation) =>
                                            RotationTransition(
                                              turns: Tween<double>(
                                                begin: 0.72,
                                                end: 1,
                                              ).animate(animation),
                                              child: ScaleTransition(
                                                scale: animation,
                                                child: child,
                                              ),
                                            ),
                                        child: Icon(
                                          brightness == Brightness.dark
                                              ? Icons.light_mode_outlined
                                              : Icons.dark_mode_outlined,
                                          key: ValueKey(brightness),
                                          color: _isThemeToggleHovered
                                              ? AppColors.gold
                                              : textSecondary,
                                          size: 20,
                                        ),
                                      ),
                                      onPressed: () => _appState.toggleTheme(),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  MouseRegion(
                                    onEnter: (_) {
                                      setState(() => _isSettingsHovered = true);
                                      _settingsRotationController.repeat();
                                    },
                                    onExit: (_) {
                                      setState(
                                        () => _isSettingsHovered = false,
                                      );
                                      _settingsRotationController.stop();
                                      _settingsRotationController.animateTo(
                                        0.0,
                                        duration: const Duration(
                                          milliseconds: 250,
                                        ),
                                        curve: Curves.easeOut,
                                      );
                                    },
                                    child: RotationTransition(
                                      turns: _settingsRotationController,
                                      child: IconButton(
                                        tooltip: tr(
                                          'dashboard.tooltipSettings',
                                        ),
                                        constraints:
                                            const BoxConstraints.tightFor(
                                              width: 40,
                                              height: 40,
                                            ),
                                        padding: EdgeInsets.zero,
                                        icon: Icon(
                                          Icons.settings_outlined,
                                          color: _isSettingsHovered
                                              ? AppColors.gold
                                              : textSecondary,
                                        ),
                                        onPressed: () =>
                                            _appState.setScreen('settings'),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  MouseRegion(
                                    onEnter: (_) =>
                                        setState(() => _isLogoutHovered = true),
                                    onExit: (_) => setState(
                                      () => _isLogoutHovered = false,
                                    ),
                                    child: IconButton(
                                      tooltip: tr('dashboard.tooltipLogout'),
                                      constraints:
                                          const BoxConstraints.tightFor(
                                            width: 40,
                                            height: 40,
                                          ),
                                      padding: EdgeInsets.zero,
                                      icon: Icon(
                                        Icons.logout,
                                        color: _isLogoutHovered
                                            ? Colors.redAccent
                                            : textSecondary,
                                      ),
                                      onPressed: _confirmLogout,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    if (!isDesktop) {
      return SizedBox(
        width: 248,
        child: DecoratedBox(
          decoration: BoxDecoration(color: AppColors.rail(brightness)),
          child: content,
        ),
      );
    }

    return AnimatedBuilder(
      animation: _railAnimation,
      builder: (context, _) {
        final t = _railAnimation.value;
        const collapsed = 72.0;
        const expanded = 248.0;
        // The handle is deliberately generous: it is easier to spot and click,
        // while still reading as part of the rail divider rather than a button
        // floating beside it.
        const bump = 22.0;
        final railWidth = collapsed + (expanded - collapsed) * t;
        return SizedBox(
          width: railWidth + bump,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: railWidth,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.rail(brightness),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppColors.divider(brightness)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: content,
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _RailBumpPainter(
                      railWidth: railWidth,
                      bumpDepth: bump,
                      fill: AppColors.rail(brightness),
                      border: AppColors.divider(brightness),
                      accent: AppColors.gold,
                      accentStrength: _handleHovered ? 0.18 : 0.09,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: railWidth - 12,
                top: 0,
                bottom: 0,
                width: bump + 34,
                child: Center(
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    onEnter: (_) => setState(() => _handleHovered = true),
                    onExit: (_) => setState(() => _handleHovered = false),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _toggleSidebar,
                      child: SizedBox(
                        height: 128,
                        child: Center(
                          child: AnimatedScale(
                            duration: const Duration(milliseconds: 180),
                            scale: _handleHovered ? 1.12 : 1,
                            child: Icon(
                              _showSidebar
                                  ? Icons.chevron_left_rounded
                                  : Icons.chevron_right_rounded,
                              size: 23,
                              color: _handleHovered
                                  ? AppColors.gold
                                  : AppColors.textSecondary(brightness),
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 900;

    return AnimatedBuilder(
      animation: _appState,
      builder: (context, _) {
        final currentScreen = _appState.currentScreen;

        // Wird auf Lite gewechselt, waehrend ein Lite-fremdes Modul offen
        // ist, zurueck auf den Chat. Settings & Co. bleiben erreichbar.
        if (_appState.frontendVersion == 'lite' &&
            !_liteModuleKeys.contains(currentScreen) &&
            !_nonSidebarScreens.contains(currentScreen)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _appState.setScreen('chat');
          });
        }

        return KeyboardListener(
          focusNode: FocusNode(),
          autofocus: true,
          onKeyEvent: _handleKeyEvent,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: isDesktop
                ? null
                : AppBar(
                    backgroundColor: AppColors.rail(
                      Theme.of(context).brightness,
                    ),
                    elevation: 0,
                    title: Text(
                      _moduleLabel(
                        [
                              ..._sidebarModules,
                              ..._deletedModules,
                            ].any((item) => item['key'] == currentScreen)
                            ? currentScreen
                            : 'chat',
                      ),
                      style: TextStyle(
                        color: AppColors.textPrimary(
                          Theme.of(context).brightness,
                        ),
                      ),
                    ),
                    iconTheme: IconThemeData(
                      color: AppColors.textPrimary(
                        Theme.of(context).brightness,
                      ),
                    ),
                    actions: [
                      IconButton(
                        icon: Icon(
                          Icons.logout,
                          color: AppColors.textSecondary(
                            Theme.of(context).brightness,
                          ),
                        ),
                        onPressed: _confirmLogout,
                      ),
                    ],
                  ),
            drawer: isDesktop ? null : Drawer(child: _buildSidebar(false)),
            body: Stack(
              children: [
                const Positioned.fill(child: AppBackground()),
                Padding(
                  padding: EdgeInsets.all(isDesktop ? 10 : 0),
                  child: Row(
                    children: [
                      if (isDesktop) _buildSidebar(true),
                      if (isDesktop) const SizedBox(width: 14),
                      Expanded(
                        child: Stack(
                          children: [
                            _buildContentPanel(currentScreen, isDesktop),
                            if (_appState.selectedCode != null)
                              Positioned(
                                top: 20,
                                right: 20,
                                bottom: 20,
                                width: _appState.codeDrawerWidth
                                    .clamp(340.0, 620.0)
                                    .toDouble(),
                                child: _CodeAssistantDrawer(
                                  appState: _appState,
                                ),
                              ),
                            if (_isReorderingModules)
                              Center(
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // 1. Gelöschte Module Popup
                                      Container(
                                        width: 320,
                                        height: 520,
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFF0B0B0F,
                                          ).withValues(alpha: 0.95),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border: Border.all(
                                            color: Colors.white.withValues(
                                              alpha: 0.08,
                                            ),
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.5,
                                              ),
                                              blurRadius: 20,
                                              offset: const Offset(0, 10),
                                            ),
                                            BoxShadow(
                                              color: const Color(
                                                0xFFC9A24A,
                                              ).withValues(alpha: 0.1),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.widgets_outlined,
                                                      color: Color(0xFFC9A24A),
                                                      size: 18,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      tr(
                                                        'dashboard.deletedModules',
                                                      ),
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 15,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.close,
                                                    color: Colors.white30,
                                                    size: 16,
                                                  ),
                                                  onPressed: () => setState(
                                                    () => _isReorderingModules =
                                                        false,
                                                  ),
                                                  padding: EdgeInsets.zero,
                                                  constraints:
                                                      const BoxConstraints(),
                                                  splashRadius: 16,
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 16),
                                            Expanded(
                                              child: _deletedModules.isEmpty
                                                  ? Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Icon(
                                                          Icons.info_outline,
                                                          color: Colors.white
                                                              .withValues(
                                                                alpha: 0.15,
                                                              ),
                                                          size: 32,
                                                        ),
                                                        const SizedBox(
                                                          height: 12,
                                                        ),
                                                        Text(
                                                          tr(
                                                            'dashboard.deletedModulesEmpty',
                                                          ),
                                                          textAlign:
                                                              TextAlign.center,
                                                          style: TextStyle(
                                                            color: Colors.white
                                                                .withValues(
                                                                  alpha: 0.4,
                                                                ),
                                                            fontSize: 12,
                                                            height: 1.4,
                                                          ),
                                                        ),
                                                      ],
                                                    )
                                                  : SingleChildScrollView(
                                                      child: Column(
                                                        children: _deletedModules.map((
                                                          m,
                                                        ) {
                                                          return Padding(
                                                            padding:
                                                                const EdgeInsets.only(
                                                                  bottom: 8,
                                                                ),
                                                            child: Container(
                                                              padding:
                                                                  const EdgeInsets.symmetric(
                                                                    horizontal:
                                                                        12,
                                                                    vertical: 8,
                                                                  ),
                                                              decoration: BoxDecoration(
                                                                color: Colors
                                                                    .white
                                                                    .withValues(
                                                                      alpha:
                                                                          0.02,
                                                                    ),
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      8,
                                                                    ),
                                                                border: Border.all(
                                                                  color: Colors
                                                                      .white
                                                                      .withValues(
                                                                        alpha:
                                                                            0.04,
                                                                      ),
                                                                ),
                                                              ),
                                                              child: Row(
                                                                children: [
                                                                  Icon(
                                                                    m['icon']
                                                                        as IconData,
                                                                    color: Colors
                                                                        .white60,
                                                                    size: 16,
                                                                  ),
                                                                  const SizedBox(
                                                                    width: 10,
                                                                  ),
                                                                  Expanded(
                                                                    child: Text(
                                                                      _moduleLabel(
                                                                        m['key']
                                                                            as String,
                                                                      ),
                                                                      style: const TextStyle(
                                                                        color: Colors
                                                                            .white70,
                                                                        fontSize:
                                                                            13,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  IconButton(
                                                                    icon: const Icon(
                                                                      Icons
                                                                          .add_circle_outline,
                                                                      color: Color(
                                                                        0xFFC9A24A,
                                                                      ),
                                                                      size: 18,
                                                                    ),
                                                                    onPressed: () =>
                                                                        _restoreModule(
                                                                          m,
                                                                        ),
                                                                    padding:
                                                                        EdgeInsets
                                                                            .zero,
                                                                    constraints:
                                                                        const BoxConstraints(),
                                                                    splashRadius:
                                                                        16,
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          );
                                                        }).toList(),
                                                      ),
                                                    ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 24),
                                      // 2. Model Catalog Popup (ModelManagementDialog content!)
                                      Container(
                                        width: 680,
                                        height: 520,
                                        decoration: BoxDecoration(
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.5,
                                              ),
                                              blurRadius: 20,
                                              offset: const Offset(0, 10),
                                            ),
                                          ],
                                        ),
                                        child: ModelManagementDialog(
                                          appState: _appState,
                                          themeColor: const Color(0xFFC9A24A),
                                          isInline: true,
                                          onClose: () => setState(
                                            () => _isReorderingModules = false,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContentPanel(String currentScreen, bool isDesktop) {
    final brightness = Theme.of(context).brightness;
    // Most module screens are const widgets so they retain their state while
    // unrelated AppState notifications arrive. A language change is the one
    // exception: keying the active module by locale recreates it exactly then,
    // ensuring all handwritten `tr(...)` calls are rendered in the newly
    // selected language instead of waiting for an unrelated interaction.
    final panel = KeyedSubtree(
      key: ValueKey<String>('locale-${_appState.language}'),
      child: _buildBody(currentScreen),
    );

    if (!isDesktop) return panel;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.bg(brightness),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.divider(brightness)),
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(22), child: panel),
    );
  }
}

class _CodeAssistantDrawer extends StatelessWidget {
  const _CodeAssistantDrawer({required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    final code = appState.selectedCode ?? '';
    final language = appState.selectedCodeLanguage?.trim();
    final languageLabel = language?.isNotEmpty == true
        ? language!.toUpperCase()
        : 'CODE';
    final blocks = appState.allCodeBlocks;

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF101014),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.42),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 10),
              child: Row(
                children: [
                  const Icon(
                    Icons.code_rounded,
                    color: Color(0xFFEBD9A8),
                    size: 17,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      languageLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  if (blocks.length > 1)
                    PopupMenuButton<int>(
                      tooltip: tr('dashboard.codeBlockSwitch'),
                      color: const Color(0xFF18181D),
                      onSelected: (index) {
                        final block = blocks[index];
                        appState.showCodeAssistant(
                          block['code'] ?? '',
                          block['lang'],
                          blocks,
                        );
                      },
                      itemBuilder: (context) => List.generate(
                        blocks.length,
                        (index) => PopupMenuItem(
                          value: index,
                          child: Text(
                            tr('dashboard.codeBlockN', {'n': '${index + 1}'}),
                          ),
                        ),
                      ),
                      icon: const Icon(
                        Icons.format_list_bulleted,
                        size: 18,
                        color: Colors.white54,
                      ),
                    ),
                  IconButton(
                    tooltip: tr('dashboard.codeClose'),
                    onPressed: appState.closeCodeAssistant,
                    icon: const Icon(
                      Icons.close,
                      size: 18,
                      color: Colors.white60,
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: Colors.white.withValues(alpha: 0.08)),
            Expanded(
              child: Scrollbar(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: SelectableText(
                    code,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.5,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
            ),
            Divider(height: 1, color: Colors.white.withValues(alpha: 0.08)),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: code));
                  showTopNotification(context, tr('dashboard.codeCopied'));
                },
                icon: const Icon(Icons.copy_outlined, size: 16),
                label: Text(tr('dashboard.copy')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarNavItem extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final bool showSidebar;
  final VoidCallback onTap;
  final bool isReorderMode;
  final bool showExternalIndicator;
  final VoidCallback? onDelete;
  final IconData? trailingActionIcon;
  final String? trailingActionTooltip;
  final VoidCallback? onTrailingAction;

  const _SidebarNavItem({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.showSidebar,
    required this.onTap,
    this.isReorderMode = false,
    this.showExternalIndicator = false,
    this.onDelete,
    this.trailingActionIcon,
    this.trailingActionTooltip,
    this.onTrailingAction,
  });

  @override
  State<_SidebarNavItem> createState() => _SidebarNavItemState();
}

class _SidebarNavItemState extends State<_SidebarNavItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final textPrimary = AppColors.textPrimary(brightness);
    final textSecondary = AppColors.textSecondary(brightness);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: widget.isReorderMode
              ? null
              : widget.onTap, // Disable navigation in reorder mode
          onHover: widget.isReorderMode
              ? null
              : (hovered) {
                  setState(() {
                    _isHovered = hovered;
                  });
                },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            padding: EdgeInsets.symmetric(
              horizontal: widget.showSidebar ? 14 : 10,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: !widget.isReorderMode && widget.selected
                  ? AppColors.gold.withValues(alpha: 0.10)
                  : (!widget.isReorderMode && _isHovered
                        ? AppColors.gold.withValues(alpha: 0.08)
                        : Colors.transparent),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: !widget.isReorderMode && widget.selected
                    ? AppColors.gold.withValues(alpha: 0.24)
                    : (!widget.isReorderMode && _isHovered
                          ? AppColors.gold.withValues(alpha: 0.22)
                          : Colors.transparent),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Icon(
                  widget.icon,
                  size: 20,
                  color: !widget.isReorderMode && widget.selected
                      ? AppColors.gold
                      : ((!widget.isReorderMode && _isHovered)
                            ? AppColors.gold
                            : textSecondary),
                ),
                Expanded(
                  child: AnimatedOpacity(
                    opacity: widget.showSidebar ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    child: ClipRect(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const NeverScrollableScrollPhysics(),
                        child: SizedBox(
                          width: 180,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(width: 12),
                              Expanded(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        widget.label,
                                        maxLines: 1,
                                        overflow: TextOverflow.clip,
                                        style: AppFonts.navigation(
                                          color:
                                              !widget.isReorderMode &&
                                                  widget.selected
                                              ? textPrimary
                                              : ((!widget.isReorderMode &&
                                                        _isHovered)
                                                    ? AppColors.gold
                                                    : textSecondary),
                                          fontWeight:
                                              !widget.isReorderMode &&
                                                  widget.selected
                                              ? FontWeight.bold
                                              : FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    if (!widget.isReorderMode &&
                                        widget.showSidebar &&
                                        widget.showExternalIndicator &&
                                        _isHovered)
                                      Padding(
                                        padding: const EdgeInsets.only(left: 6),
                                        child: Icon(
                                          Icons.open_in_new,
                                          size: 15,
                                          color: textSecondary,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (!widget.isReorderMode &&
                                  widget.showSidebar &&
                                  widget.trailingActionIcon != null)
                                Padding(
                                  padding: const EdgeInsets.only(left: 2),
                                  child: MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: Tooltip(
                                      message:
                                          widget.trailingActionTooltip ?? '',
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(6),
                                        onTap: widget.onTrailingAction,
                                        child: Padding(
                                          padding: const EdgeInsets.all(4),
                                          child: Icon(
                                            widget.trailingActionIcon,
                                            size: 16,
                                            color: widget.selected
                                                ? AppColors.gold
                                                : textSecondary,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              if (widget.isReorderMode) ...[
                                if (widget.onDelete != null) ...[
                                  IconButton(
                                    icon: Icon(
                                      Icons.remove_circle_outline,
                                      color: Colors.redAccent.withValues(
                                        alpha: 0.7,
                                      ),
                                      size: 16,
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints.tightFor(
                                      width: 24,
                                      height: 24,
                                    ),
                                    onPressed: widget.onDelete,
                                    tooltip: tr('dashboard.tooltipRemove'),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Icon(
                                  Icons.drag_handle,
                                  color: textSecondary.withValues(alpha: 0.4),
                                  size: 18,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
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

/// Draws the elongated collapse handle as a continuation of the rail border.
/// The right edge of the rail is covered beneath the handle so the divider
/// bends around it as one continuous line.
class _RailBumpPainter extends CustomPainter {
  final double railWidth;
  final double bumpDepth;
  final Color fill;
  final Color border;
  final Color accent;
  final double accentStrength;

  _RailBumpPainter({
    required this.railWidth,
    required this.bumpDepth,
    required this.fill,
    required this.border,
    required this.accent,
    required this.accentStrength,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final mid = size.height / 2;
    const innerHalf = 64.0; // tall base against the rail (elongated)
    const outerHalf = 38.0; // slightly broader outer edge
    final w = railWidth;
    final d = bumpDepth;

    final path = Path()
      ..moveTo(w, mid - innerHalf)
      ..lineTo(w + d, mid - outerHalf)
      ..lineTo(w + d, mid + outerHalf)
      ..lineTo(w, mid + innerHalf)
      ..close();

    final fillPaint = Paint()
      ..color = fill
      ..isAntiAlias = true;

    // Mask the existing straight rail border where the handle joins it.
    canvas.drawRect(
      Rect.fromLTRB(w - 2, mid - innerHalf, w + 1, mid + innerHalf),
      fillPaint,
    );
    canvas.drawPath(path, fillPaint);
    canvas.drawPath(
      path,
      Paint()
        ..color = accent.withValues(alpha: accentStrength)
        ..isAntiAlias = true,
    );

    // Only trace the outer three edges. Leaving the base open lets the rail's
    // divider flow into the handle instead of producing a doubled line.
    canvas.drawPath(
      Path()
        ..moveTo(w, mid - innerHalf)
        ..lineTo(w + d, mid - outerHalf)
        ..lineTo(w + d, mid + outerHalf)
        ..lineTo(w, mid + innerHalf),
      Paint()
        ..color = Color.lerp(border, accent, accentStrength * 1.8)!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(covariant _RailBumpPainter old) =>
      old.railWidth != railWidth ||
      old.fill != fill ||
      old.bumpDepth != bumpDepth ||
      old.border != border ||
      old.accent != accent ||
      old.accentStrength != accentStrength;
}
