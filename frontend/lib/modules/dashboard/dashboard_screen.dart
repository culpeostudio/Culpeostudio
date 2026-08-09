import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_strings.dart';
import '../../core/app_state.dart';
import '../../core/app_theme.dart';
import '../../core/startup_warmup.dart';
import '../../core/app_background.dart';
import '../../core/top_notification.dart';
import '../onboarding/onboarding_dialog.dart';
import '../benchmark/benchmark_screen.dart';
import '../scout/chat_history_panel.dart';
import '../scout/scout_tab.dart';
import '../scout/sidebar_model_panel.dart';
import '../engine/engine_screen.dart';
import '../marketplace/marketplace_screen.dart';
import '../news/news_screen.dart';
import '../settings/settings_screen.dart';
import '../bots/bot_management_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  final AppState _appState = AppState();
  final Set<String> _expandedHistoryProjects = {};
  final Set<String> _expandedHistorySubfolders = {};
  final Set<String> _collapsedModelFolders = {};

  /// Reihenfolge der drei Sidebar-Ansichten: Module, Chat-Verlauf, Modell.
  static const List<String> _sidebarViews = ['modules', 'history', 'models'];

  /// Seit die Modell-Auswahl mit in die Sidebar gehört, braucht die Spalte
  /// etwas mehr Platz für Modellname und Provider-Zeile - rund 15% breiter
  /// als die vorherigen 260/248px.
  static const double _sidebarWidthDesktop = 300;
  static const double _sidebarWidthDrawer = 285;
  int _sidebarView = 0;
  bool _isSettingsHovered = false;
  bool _isLogoutHovered = false;
  late AnimationController _settingsRotationController;

  /// Bewegt die Sidebar-Ansichten wie ein horizontaler Pager: der Wert läuft
  /// stetig von 0 bis [_sidebarViews.length] - 1, jede Ansicht liegt an ihrem
  /// Index und wird um (index - wert) verschoben angezeigt.
  late AnimationController _sidebarPanelController;

  /// Die Reihenfolge der Module bestimmt der Nutzer, die Symbole gehören zum
  /// Modul und bleiben deshalb hier.
  static const Map<String, IconData> _moduleIcons = {
    'marketplace': Icons.storefront_outlined,
    'engine': Icons.memory_outlined,
    'news': Icons.newspaper_outlined,
    'benchmark': Icons.speed_outlined,
  };

  static const Set<String> _nonSidebarScreens = {
    'chat',
    'settings',
    'bot_management',
    'spark',
  };

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

  @override
  void initState() {
    super.initState();
    StartupWarmup.instance.start();
    _appState.loadShortcuts();
    _appState.loadModuleOrder();
    _appState.loadChatSubfolders();

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
    _sidebarPanelController = AnimationController(
      vsync: this,
      lowerBound: 0,
      upperBound: (_sidebarViews.length - 1).toDouble(),
      value: _sidebarView.toDouble(),
    );
  }

  @override
  void dispose() {
    _settingsRotationController.dispose();
    _sidebarPanelController.dispose();
    super.dispose();
  }

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
        return const ScoutTab();
      case 'spark':
        return const ScoutTab();
      case 'engine':
        return const EngineScreen();
      case 'marketplace':
        return const MarketplaceScreen();
      case 'news':
        return const NewsScreen();
      case 'benchmark':
        return const BenchmarkScreen();
      case 'settings':
        return const SettingsScreen();
      case 'bot_management':
        return const BotManagementScreen();
      default:
        return const ScoutTab();
    }
  }

  String get _apiHost {
    final uri = Uri.tryParse(_appState.api.baseUrl);
    return (uri?.host.isNotEmpty ?? false) ? uri!.host : 'local';
  }

  Widget _buildSidebar(bool isDesktop) {
    final textPrimary = AppColors.textPrimary;
    final textSecondary = AppColors.textSecondary;

    final content = ExcludeSemantics(
      child: LayoutBuilder(
        builder: (context, _) {
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
                            'C',
                            textAlign: TextAlign.center,
                            style: AppFonts.serifItalic(
                              fontSize: 23,
                              color: AppColors.gold,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'CULPEO',
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
                            'STUDIO',
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
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: _SidebarViewSwitcher(
                    currentView: _sidebarView,
                    onChanged: _showSidebarView,
                  ),
                ),
                Expanded(child: _buildSidebarPanels()),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 18),
                  child: Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        height: 1,
                        color: AppColors.divider,
                      ),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: AppColors.gold.withValues(
                              alpha: 0.18,
                            ),
                            child: Text(
                              (_appState.username ?? 'D')[0].toUpperCase(),
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
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                                    color: textSecondary.withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
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
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOut,
                              );
                            },
                            child: RotationTransition(
                              turns: _settingsRotationController,
                              child: IconButton(
                                tooltip: tr('dashboard.tooltipSettings'),
                                constraints: const BoxConstraints.tightFor(
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
        width: _sidebarWidthDrawer,
        child: DecoratedBox(
          decoration: BoxDecoration(color: AppColors.rail),
          child: content,
        ),
      );
    }

    return SizedBox(
      width: _sidebarWidthDesktop,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.rail,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.divider),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: content,
        ),
      ),
    );
  }

  void _showSidebarView(int view) {
    setState(() {
      _sidebarView = view;
      // Chat-Verlauf und Modell-Auswahl gehören zur laufenden Chat-Sitzung -
      // beide brauchen den Chat-Bildschirm, sonst ist nichts da, das sie
      // anzeigen könnten.
      if (view != 0 && _appState.currentScreen != 'chat') {
        _appState.setScreen('chat');
      }
    });
    _sidebarPanelController.animateTo(
      view.toDouble(),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  /// Die drei Sidebar-Ansichten liegen wie bei einem horizontalen Pager
  /// nebeneinander; welche gerade sichtbar ist, bestimmt allein die Position
  /// des Controllers.
  Widget _buildSidebarPanels() {
    final panels = [
      DecoratedBox(
        decoration: BoxDecoration(color: AppColors.rail),
        child: _buildModuleList(),
      ),
      _buildHistoryView(),
      DecoratedBox(
        decoration: BoxDecoration(color: AppColors.rail),
        child: SidebarModelPanel(
          appState: _appState,
          collapsedFolders: _collapsedModelFolders,
        ),
      ),
    ];

    return ClipRect(
      child: AnimatedBuilder(
        animation: _sidebarPanelController,
        builder: (context, _) {
          final position = _sidebarPanelController.value;
          return Stack(
            children: [
              for (var i = 0; i < panels.length; i++)
                Positioned.fill(
                  child: IgnorePointer(
                    ignoring: (position - i).abs() > 0.5,
                    child: FractionalTranslation(
                      translation: Offset(i - position, 0),
                      child: panels[i],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildModuleList() {
    final modules = _appState.moduleOrder;
    return Padding(
      key: const ValueKey('sidebar-modules'),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ReorderableListView.builder(
        key: const Key('sidebar-module-list'),
        padding: const EdgeInsets.only(top: 19),
        buildDefaultDragHandles: false,
        itemCount: modules.length,
        onReorderItem: _appState.reorderModules,
        // Die aufgenommene Zeile hebt leicht ab, damit klar ist, was am
        // Mauszeiger hängt.
        proxyDecorator: (child, index, animation) => AnimatedBuilder(
          animation: animation,
          builder: (context, _) => Material(
            color: Colors.transparent,
            child: Transform.scale(
              scale: 1 + 0.03 * Curves.easeOut.transform(animation.value),
              child: child,
            ),
          ),
        ),
        itemBuilder: (context, index) {
          final key = modules[index];
          return _ModuleDragArea(
            key: ValueKey('sidebar-module-$key'),
            index: index,
            child: _SidebarNavItem(
              label: _moduleLabel(key),
              icon: _moduleIcons[key] ?? Icons.widgets_outlined,
              selected: _appState.currentScreen == key,
              showSidebar: true,
              onTap: () => _appState.setScreen(key),
            ),
          );
        },
      ),
    );
  }

  /// Erstellt einen neuen Chat. Befindet sich der aktuelle Chat in einem
  /// Projekt, wird der neue Chat diesem Projekt zugeordnet, sonst landet er
  /// im normalen Verlauf.
  void _createNewChat() {
    final sessionId = _appState.currentChatSessionId;
    final projectId = sessionId == null
        ? null
        : _appState.projectIdForSession(sessionId);
    _triggerChatAction(
      projectId != null ? 'new_chat_session:$projectId' : 'new_chat_session',
    );
  }

  Widget _buildHistoryView() {
    return Padding(
      key: const ValueKey('sidebar-history'),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        children: [
          const SizedBox(height: 19),
          _NewChatButton(
            label: tr('dashboard.tooltipNewChat'),
            onTap: _createNewChat,
          ),
          const SizedBox(height: 6),
          Expanded(
            child: ChatHistoryPanel(
              key: const Key('chat-history-panel'),
              appState: _appState,
              currentChatId: _appState.currentChatSessionId,
              expandedProjects: _expandedHistoryProjects,
              expandedSubfolders: _expandedHistorySubfolders,
              listMaxHeight: null,
              onNewChatInProject: (projectId) =>
                  _triggerChatAction('new_chat_session:$projectId'),
              onSelectChat: (sessionId) {
                _appState.selectChatSession(sessionId);
                if (_appState.currentScreen != 'chat') {
                  _appState.setScreen('chat');
                }
              },
              onRenameChat: (sessionId) =>
                  promptRenameChatSession(context, _appState, sessionId),
              onDeleteChat: (sessionId) => confirmDeleteChatSession(
                context,
                _appState,
                sessionId,
                onNeedNewSession: () => _triggerChatAction('new_chat_session'),
              ),
            ),
          ),
        ],
      ),
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

        if (_appState.frontendVersion == 'lite' &&
            !_moduleIcons.containsKey(currentScreen) &&
            !_nonSidebarScreens.contains(currentScreen)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _appState.setScreen('chat');
          });
        }

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: isDesktop
              ? null
              : AppBar(
                  backgroundColor: AppColors.rail,
                  elevation: 0,
                  title: Text(
                    _moduleLabel(
                      _moduleIcons.containsKey(currentScreen)
                          ? currentScreen
                          : 'chat',
                    ),
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                  iconTheme: IconThemeData(color: AppColors.textPrimary),
                  actions: [
                    IconButton(
                      icon: Icon(Icons.logout, color: AppColors.textSecondary),
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
                    if (isDesktop) ...[
                      _buildSidebar(true),
                      const SizedBox(width: 14),
                    ],
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
                              child: _CodeAssistantDrawer(appState: _appState),
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
    );
  }

  Widget _buildContentPanel(String currentScreen, bool isDesktop) {
    final panel = KeyedSubtree(
      key: ValueKey<String>('locale-${_appState.language}'),
      child: _buildBody(currentScreen),
    );

    if (!isDesktop) return panel;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.divider),
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

/// Macht eine Modulzeile verschiebbar: am Schreibtisch zieht die Maus sofort,
/// auf Touchgeräten erst nach kurzem Halten, damit Wischen weiter scrollt.
/// Ein einfacher Tipp bleibt in beiden Fällen ein Tipp.
class _ModuleDragArea extends StatelessWidget {
  const _ModuleDragArea({super.key, required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    switch (Theme.of(context).platform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.fuchsia:
        return ReorderableDelayedDragStartListener(index: index, child: child);
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        return ReorderableDragStartListener(index: index, child: child);
    }
  }
}

class _SidebarNavItem extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final bool showSidebar;
  final VoidCallback onTap;

  const _SidebarNavItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.showSidebar,
    required this.onTap,
  });

  @override
  State<_SidebarNavItem> createState() => _SidebarNavItemState();
}

class _SidebarNavItemState extends State<_SidebarNavItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppColors.textPrimary;
    final textSecondary = AppColors.textSecondary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: widget.onTap,
          onHover: (hovered) {
            setState(() {
              _isHovered = hovered;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            // Right inset is deliberately smaller than the left one: the
            // drag grip sits there and needs to read as pinned to the row's
            // true edge (~2mm), not just inside the same rhythm as the icon.
            padding: EdgeInsets.only(
              left: widget.showSidebar ? 14 : 10,
              right: widget.showSidebar ? 6 : 10,
              top: 12,
              bottom: 12,
            ),
            decoration: BoxDecoration(
              color: widget.selected
                  ? AppColors.gold.withValues(alpha: 0.10)
                  : (_isHovered
                        ? AppColors.gold.withValues(alpha: 0.08)
                        : Colors.transparent),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: widget.selected
                    ? AppColors.gold.withValues(alpha: 0.24)
                    : (_isHovered
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
                  color: widget.selected
                      ? AppColors.gold
                      : (_isHovered ? AppColors.gold : textSecondary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AnimatedOpacity(
                    opacity: widget.showSidebar ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    child: ClipRect(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const NeverScrollableScrollPhysics(),
                        child: Text(
                          widget.label,
                          maxLines: 1,
                          overflow: TextOverflow.clip,
                          style: AppFonts.navigation(
                            color: widget.selected
                                ? textPrimary
                                : (_isHovered ? AppColors.gold : textSecondary),
                            fontWeight: widget.selected
                                ? FontWeight.bold
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Verrät beim Überfahren, dass sich die Module umsortieren
                // lassen - sitzt am echten rechten Rand der Zeile, nicht
                // irgendwo hinter dem Text.
                if (widget.showSidebar)
                  Padding(
                    padding: const EdgeInsets.only(left: 6, right: 2),
                    child: AnimatedOpacity(
                      opacity: _isHovered ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 160),
                      child: _NineDotGrip(
                        color: textSecondary.withValues(alpha: 0.55),
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

/// A 3x3 grid of dots - the explicit "grip" affordance for a draggable row.
/// Deliberately not Flutter's built-in [Icons.drag_indicator], which is only
/// six dots (2x3).
class _NineDotGrip extends StatelessWidget {
  const _NineDotGrip({required this.color});

  final Color color;

  static const double _dotSize = 2.6;
  static const double _dotMargin = 1.4;

  @override
  Widget build(BuildContext context) {
    Widget dot() => Container(
      width: _dotSize,
      height: _dotSize,
      margin: const EdgeInsets.all(_dotMargin),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
    Widget row() =>
        Row(mainAxisSize: MainAxisSize.min, children: [dot(), dot(), dot()]);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [row(), row(), row()],
    );
  }
}

class _SidebarViewSwitcher extends StatelessWidget {
  const _SidebarViewSwitcher({
    required this.currentView,
    required this.onChanged,
  });

  final int currentView;
  final ValueChanged<int> onChanged;

  static const List<(IconData, String)> _segments = [
    (Icons.apps_outlined, 'sidebar.modules'),
    (Icons.forum_outlined, 'sidebar.history'),
    (Icons.smart_toy_outlined, 'sidebar.models'),
  ];

  @override
  Widget build(BuildContext context) {
    final last = _segments.length - 1;
    return Container(
      height: 40,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          for (var i = 0; i < _segments.length; i++)
            Expanded(
              child: _SwitcherSegment(
                icon: _segments[i].$1,
                label: tr(_segments[i].$2),
                selected: currentView == i,
                poke: i == 0
                    ? _SegmentPoke.left
                    : i == last
                    ? _SegmentPoke.right
                    : _SegmentPoke.none,
                borderRadius: i == 0
                    ? const BorderRadius.only(
                        topLeft: Radius.circular(13),
                        bottomLeft: Radius.circular(13),
                      )
                    : i == last
                    ? const BorderRadius.only(
                        topRight: Radius.circular(13),
                        bottomRight: Radius.circular(13),
                      )
                    : BorderRadius.zero,
                onTap: () => onChanged(i),
              ),
            ),
        ],
      ),
    );
  }
}

/// Which side (if any) of the switcher's rounded outer edge a segment sits
/// against. Only the outer segments poke past the rail's own rounded corner
/// when active; a middle segment (e.g. "Chat" once "Modell" joined it) has
/// no outer edge to poke past.
enum _SegmentPoke { left, right, none }

class _SwitcherSegment extends StatefulWidget {
  const _SwitcherSegment({
    required this.icon,
    required this.label,
    required this.selected,
    required this.poke,
    required this.borderRadius,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final _SegmentPoke poke;
  final BorderRadius borderRadius;
  final VoidCallback onTap;

  @override
  State<_SwitcherSegment> createState() => _SwitcherSegmentState();
}

class _SwitcherSegmentState extends State<_SwitcherSegment> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.selected;
    final color = active
        ? AppColors.gold
        : (_hovered ? AppColors.textPrimary : AppColors.textSecondary);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        // Aktive Bubble ragt ~20% über die Leisten-Höhe (32 -> 38.5) hinaus.
        // Nur an den äußeren Segmenten wird sie zur abgerundeten Außenseite
        // hin auch etwas breiter (6 px), damit klar sichtbar ist, wo sich
        // der Nutzer befindet; ein mittleres Segment hat keine Außenkante,
        // zu der es ausweichen könnte, und wächst nur in der Höhe.
        child: LayoutBuilder(
          builder: (context, constraints) {
            final cellWidth = constraints.maxWidth;
            final growsWidth = widget.poke != _SegmentPoke.none;
            return OverflowBox(
              minWidth: cellWidth,
              maxWidth: growsWidth ? cellWidth + 6 : cellWidth,
              minHeight: 32,
              maxHeight: 38.5,
              alignment: widget.poke == _SegmentPoke.left
                  ? Alignment.centerRight
                  : widget.poke == _SegmentPoke.right
                  ? Alignment.centerLeft
                  : Alignment.center,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                width: active && growsWidth ? cellWidth + 6 : cellWidth,
                height: active ? 38.5 : 32,
                decoration: BoxDecoration(
                  color: active
                      ? AppColors.gold.withValues(alpha: 0.12)
                      : (_hovered
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.transparent),
                  borderRadius: widget.borderRadius,
                  border: Border.all(
                    color: active
                        ? AppColors.gold.withValues(alpha: 0.24)
                        : Colors.transparent,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(widget.icon, size: 15, color: color),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        widget.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: active
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _NewChatButton extends StatefulWidget {
  const _NewChatButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  State<_NewChatButton> createState() => _NewChatButtonState();
}

class _NewChatButtonState extends State<_NewChatButton> {
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
              Icon(
                Icons.create_new_folder_outlined,
                size: 15,
                color: Colors.white70,
              ),
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
