import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_markdown_latex/flutter_markdown_latex.dart';
import 'package:markdown/markdown.dart' as md;
import '../../services/api_service.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/top_notification.dart';
import 'chat_markdown_helpers.dart';
import 'interactive_code_block.dart';
import 'chat_widgets.dart';
import 'model_management_dialog.dart';

class PhiloxTab extends StatefulWidget {
  const PhiloxTab({super.key});

  @override
  State<PhiloxTab> createState() => _PhiloxTabState();
}

class _PhiloxTabState extends State<PhiloxTab> {
  final ApiService _api = ApiService();
  final AppState _appState = AppState();

  final FocusNode _inputFocusNode = FocusNode();
  StreamSubscription<String>? _actionSubscription;

  String? _sessionId;
  final List<Map<String, dynamic>> _messages = [];
  final _msgController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isLoading = false;

  // Agent Settings
  String _thinkingLevel = 'medium';
  String _mode = 'planning';
  final _allowedRootsController = TextEditingController(text: 'data/workspace');
  // Plan approval demo
  bool _showPlanApproval = false;
  String? _pendingPlanMessage;
  bool _showSettings = true;
  bool _plusHovered = false;
  bool _sendHovered = false;
  bool _webSearchEnabled = false;
  bool _modelHovered = false;
  bool _isDragging = false;
  final List<Map<String, String>> _uploadedFiles = [];

  final LayerLink _plusMenuLink = LayerLink();
  OverlayEntry? _plusMenuEntry;

  Future<void> _pickFile() async {
    _hidePlusMenu();
    try {
      final result = await FilePicker.pickFiles(allowMultiple: true);
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          for (var file in result.files) {
            if (file.path != null) {
              _uploadedFiles.add({'name': file.name, 'path': file.path!});
            }
          }
        });
      }
    } catch (e) {
      debugPrint("Error picking file: $e");
    }
  }

  void _openFile(String path) {
    _appState.showFilePreview(path);
  }

  void _showPlusMenu() {
    final themeColor = const Color(0xFFC9A24A);
    _plusMenuEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _hidePlusMenu,
              child: Container(color: Colors.transparent),
            ),
          ),
          Positioned(
            width: 280,
            child: CompositedTransformFollower(
              link: _plusMenuLink,
              showWhenUnlinked: false,
              targetAnchor: Alignment.topLeft,
              followerAnchor: Alignment.bottomLeft,
              offset: const Offset(0, -12),
              child: Material(
                color: Colors.transparent,
                child: _buildPlusMenuContent(themeColor),
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_plusMenuEntry!);
  }

  void _hidePlusMenu() {
    _plusMenuEntry?.remove();
    _plusMenuEntry = null;
  }

  void _togglePlusMenu() {
    if (_plusMenuEntry == null) {
      _showPlusMenu();
    } else {
      _hidePlusMenu();
    }
  }

  Widget _buildPlusMenuContent(Color themeColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF161617),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 18,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Web Search Option
          InkWell(
            onTap: () {
              setState(() {
                _webSearchEnabled = !_webSearchEnabled;
              });
              _plusMenuEntry?.markNeedsBuild();
            },
            borderRadius: BorderRadius.circular(8),
            hoverColor: themeColor.withValues(alpha: 0.09),
            splashColor: themeColor.withValues(alpha: 0.12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  Icon(
                    Icons.language,
                    color: _webSearchEnabled ? themeColor : Colors.white70,
                    size: 14,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Websuche',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 1),
                        Text(
                          'Echtzeit-Informationen',
                          style: TextStyle(color: Colors.white30, fontSize: 8),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _webSearchEnabled
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: _webSearchEnabled ? themeColor : Colors.white24,
                    size: 14,
                  ),
                ],
              ),
            ),
          ),
          // New Chat Option
          InkWell(
            onTap: () {
              _hidePlusMenu();
              _startSession();
            },
            borderRadius: BorderRadius.circular(8),
            hoverColor: themeColor.withValues(alpha: 0.09),
            splashColor: themeColor.withValues(alpha: 0.12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: const Row(
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    color: Colors.white70,
                    size: 14,
                  ),
                  SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Neustart',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 1),
                      Text(
                        'Unterhaltung zurücksetzen',
                        style: TextStyle(color: Colors.white30, fontSize: 8),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Datei hochladen Option
          InkWell(
            onTap: _pickFile,
            borderRadius: BorderRadius.circular(8),
            hoverColor: themeColor.withValues(alpha: 0.09),
            splashColor: themeColor.withValues(alpha: 0.12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: const Row(
                children: [
                  Icon(Icons.attach_file, color: Colors.white70, size: 14),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Datei hochladen',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 1),
                        Text(
                          'Lokale Datei auswählen',
                          style: TextStyle(color: Colors.white30, fontSize: 8),
                        ),
                      ],
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

  @override
  void initState() {
    super.initState();
    _appState.addListener(_onAppStateChanged);
    _actionSubscription = _appState.actionStream.listen((action) {
      if (!mounted) return;
      if (action == 'focus_chat_input') {
        _inputFocusNode.requestFocus();
      } else if (action == 'new_chat_session') {
        _startSession();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_sessionId == null) {
        _startSession();
      }
    });
  }

  void _onAppStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _startSession() async {
    setState(() => _isLoading = true);
    final modelId = _appState.selectedModelId ?? 'default-model';
    final allowedRoots = _allowedRootsController.text
        .trim()
        .split(',')
        .map((s) => s.trim())
        .toList();
    final res = await _api.createPhiloxSession(
      modelId,
      _thinkingLevel,
      _mode,
      allowedRoots,
    );
    if (mounted) {
      setState(() {
        _sessionId = res['session_id'];
        _messages.clear();
        _isLoading = false;
      });
    }
    if (res.containsKey('error') && mounted) {
      showTopNotification(context, res['error'], color: Colors.redAccent);
    } else {
      _fetchHistory();
    }
  }

  Future<void> _fetchHistory() async {
    if (_sessionId == null) return;
    final res = await _api.getPhiloxHistory(_sessionId!);
    if (res.containsKey('messages') && mounted) {
      setState(() {
        _messages.clear();
        for (var m in res['messages']) {
          _messages.add({'role': m['role'], 'content': m['content']});
        }
      });
      _scrollToBottom();
    }
  }

  Future<void> _sendMessage({bool? approvePlan}) async {
    final text = _msgController.text.trim();
    if (text.isEmpty && approvePlan == null) return;

    if (approvePlan == null) {
      _msgController.clear();
      setState(() {
        _messages.add({'role': 'user', 'content': text});
      });
      _scrollToBottom();
    }

    setState(() {
      _isLoading = true;
      _showPlanApproval = false;
    });

    final res = await _api.sendPhiloxMessage(
      _sessionId!,
      text.isNotEmpty ? text : (_pendingPlanMessage ?? ''),
      thinkingLevel: _thinkingLevel,
      mode: _mode,
      approvePlan: approvePlan,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }

    if (res.containsKey('reply') && mounted) {
      setState(() {
        _messages.add({'role': 'assistant', 'content': res['reply']});
      });
      _scrollToBottom();
    }

    // Simulate agent planning stage that requires user review
    if (_mode == 'planning' &&
        approvePlan == null &&
        res.containsKey('status') &&
        res['status'] == 'needs_approval' &&
        mounted) {
      setState(() {
        _showPlanApproval = true;
        _pendingPlanMessage = text;
      });
    }

    if (res.containsKey('error') && mounted) {
      showTopNotification(context, res['error'], color: Colors.redAccent);
    }
  }

  void _scrollToBottom({bool forceSmooth = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        if (_isLoading && !forceSmooth) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        } else {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      }
    });
  }

  List<Map<String, String>> _extractCodeBlocks() {
    final List<Map<String, String>> blocks = [];
    final regExp = RegExp(r'```([a-zA-Z0-9_\-\+]*)\n([\s\S]*?)```');
    for (final msg in _messages) {
      final content = msg['content'] ?? '';
      final matches = regExp.allMatches(content);
      for (final match in matches) {
        final lang = match.group(1)?.trim() ?? '';
        final code = match.group(2) ?? '';
        if (code.trim().isNotEmpty && !isMarkdownSourceLanguage(lang)) {
          blocks.add({'lang': lang.isEmpty ? 'code' : lang, 'code': code});
        }
      }
    }
    return blocks;
  }

  @override
  void dispose() {
    _actionSubscription?.cancel();
    _inputFocusNode.dispose();
    _appState.removeListener(_onAppStateChanged);
    _hidePlusMenu();
    _msgController.dispose();
    _allowedRootsController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showModelManagementDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => ModelManagementDialog(
        appState: _appState,
        themeColor: const Color(0xFFC9A24A),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Left Side Chat Area
        Expanded(
          flex: 3,
          child: Container(
            color: Colors.transparent,
            child: Column(
              children: [
                // Persistent Header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  color: Colors.transparent,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _sessionId != null
                            ? 'Agent Session: $_sessionId'
                            : 'Sitzungskonfiguration',
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                      ),
                      Row(
                        children: [
                          if (_sessionId != null) ...[
                            TextButton.icon(
                              onPressed: _startSession,
                              icon: const Icon(Icons.refresh, size: 14),
                              label: const Text(
                                'Neustart',
                                style: TextStyle(fontSize: 12),
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFFC9A24A),
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          IconButton(
                            icon: Icon(
                              _showSettings ? Icons.tune : Icons.tune_outlined,
                              color: const Color(0xFFC9A24A),
                              size: 18,
                            ),
                            onPressed: () {
                              setState(() {
                                _showSettings = !_showSettings;
                              });
                            },
                            tooltip: 'Parameter einblenden/ausblenden',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Main Area
                Expanded(
                  child: Column(
                    children: [
                      if (_isLoading && _sessionId == null)
                        const LinearProgressIndicator(
                          backgroundColor: Colors.transparent,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFFC9A24A),
                          ),
                        ),
                      Expanded(
                        child: _sessionId == null
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.smart_toy_outlined,
                                      size: 48,
                                      color: Colors.white24,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      _isLoading
                                          ? 'Initialisiere Agenten...'
                                          : 'Keine aktive Sitzung',
                                      style: const TextStyle(
                                        color: Colors.white30,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                ),
                                itemCount: _messages.length,
                                itemBuilder: (context, index) {
                                  final m = _messages[index];
                                  final isUser = m['role'] == 'user';
                                  final markdownContent = normalizeChatMarkdown(
                                    (m['content'] ?? '').toString(),
                                  );
                                  return Align(
                                    alignment: isUser
                                        ? Alignment.centerRight
                                        : Alignment.centerLeft,
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 16),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      constraints: BoxConstraints(
                                        maxWidth:
                                            MediaQuery.of(context).size.width *
                                            0.55,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isUser
                                            ? const Color(
                                                0xFFC9A24A,
                                              ).withValues(alpha: 0.08)
                                            : Colors.white.withValues(
                                                alpha: 0.03,
                                              ),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: isUser
                                              ? const Color(
                                                  0xFFC9A24A,
                                                ).withValues(alpha: 0.2)
                                              : Colors.white.withValues(
                                                  alpha: 0.06,
                                                ),
                                        ),
                                      ),
                                      child: MarkdownBody(
                                        data: markdownContent,
                                        selectable: true,
                                        onTapLink: (text, href, title) {
                                          openMarkdownLink(context, href);
                                        },
                                        checkboxBuilder: (checked) =>
                                            buildMarkdownCheckbox(
                                              checked,
                                              color: const Color(0xFFDFC077),
                                            ),
                                        builders: {
                                          if (shouldUseInputCheckboxBuilder(
                                            markdownContent,
                                          ))
                                            'input': TaskCheckboxElementBuilder(
                                              accentColor: const Color(
                                                0xFFDFC077,
                                              ),
                                            ),
                                          'code': InteractiveCodeElementBuilder(
                                            fontSize: 10,
                                            accentColor: const Color(
                                              0xFFDFC077,
                                            ),
                                            onCodeTap: (code, lang) {
                                              final allBlocks =
                                                  _extractCodeBlocks();
                                              _appState.showCodeAssistant(
                                                code,
                                                lang,
                                                allBlocks,
                                              );
                                            },
                                          ),
                                          'latex': LatexElementBuilder(
                                            textStyle: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                            ),
                                          ),
                                        },
                                        blockSyntaxes: [LatexBlockSyntax()],
                                        inlineSyntaxes: [LatexInlineSyntax()],
                                        extensionSet:
                                            md.ExtensionSet.gitHubFlavored,
                                        styleSheet:
                                            MarkdownStyleSheet.fromTheme(
                                              Theme.of(context),
                                            ).copyWith(
                                              codeblockDecoration:
                                                  const BoxDecoration(
                                                    color: Colors.transparent,
                                                  ),
                                              codeblockPadding: EdgeInsets.zero,
                                              p: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                                height: 1.4,
                                              ),
                                              pPadding: const EdgeInsets.only(
                                                bottom: 12.0,
                                              ),
                                              blockquotePadding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 8,
                                                  ),
                                              blockquoteDecoration:
                                                  BoxDecoration(
                                                    color: Colors.white
                                                        .withValues(
                                                          alpha: 0.05,
                                                        ),
                                                    border: const Border(
                                                      left: BorderSide(
                                                        color: Color(
                                                          0xFF232a37,
                                                        ),
                                                        width: 4,
                                                      ),
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
                                                  ),
                                              blockquote: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 14,
                                                fontStyle: FontStyle.italic,
                                              ),
                                              checkbox: const TextStyle(
                                                color: Color(0xFFDFC077),
                                                fontSize: 18,
                                              ),
                                              horizontalRuleDecoration:
                                                  BoxDecoration(
                                                    border: Border(
                                                      top: BorderSide(
                                                        color: Colors.white
                                                            .withValues(
                                                              alpha: 0.15,
                                                            ),
                                                        width: 1.0,
                                                      ),
                                                    ),
                                                  ),
                                              strong: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                              em: const TextStyle(
                                                color: Colors.white,
                                                fontStyle: FontStyle.italic,
                                                fontSize: 14,
                                              ),
                                              code: TextStyle(
                                                color: const Color(0xFFDFC077),
                                                backgroundColor: Colors.white
                                                    .withValues(alpha: 0.15),
                                                fontSize: 13,
                                                fontFamily: 'monospace',
                                              ),
                                              tableBody: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 13,
                                              ),
                                              tableHead: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                              tableBorder: TableBorder.all(
                                                color: Colors.white.withValues(
                                                  alpha: 0.15,
                                                ),
                                                width: 1.0,
                                              ),
                                              listBullet: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                              ),
                                            ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                      // Plan approval notice
                      if (_showPlanApproval)
                        Container(
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFC9A24A,
                            ).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(
                                0xFFC9A24A,
                              ).withValues(alpha: 0.25),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Planfreigabe erforderlich',
                                style: TextStyle(
                                  color: Color(0xFFC9A24A),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Der Philox Agent hat einen Ausführungsplan entworfen und wartet auf Ihre Genehmigung.',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () =>
                                        _sendMessage(approvePlan: false),
                                    child: const Text(
                                      'Ablehnen',
                                      style: TextStyle(color: Colors.redAccent),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: () =>
                                        _sendMessage(approvePlan: true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFC9A24A),
                                    ),
                                    child: const Text(
                                      'Plan genehmigen',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      // Redesigned Floating Input Bar
                      if (_sessionId != null) ...[
                        _buildFloatingInputBar(),
                        const SizedBox(height: 6),
                        Text(
                          'Powered by PhiloEngine • Created by fillystudio',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.18),
                            fontSize: 9,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Right Side Parameter Panel (Collapsible)
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          width: _showSettings ? 250 : 0,
          child: ClipRect(
            child: SizedBox(
              width: 250,
              child: Container(
                decoration: const BoxDecoration(color: Color(0xFF07070A)),
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Agenten Parameter',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'THINKING LEVEL',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 10,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildDropdown(
                        value: _thinkingLevel,
                        items: const ['none', 'medium', 'max'],
                        onChanged: (val) {
                          setState(() => _thinkingLevel = val!);
                        },
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'AUSFÜHRUNGSMODUS',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 10,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildDropdown(
                        value: _mode,
                        items: ['standard', 'planning', 'tool_use'],
                        onChanged: (val) {
                          setState(() => _mode = val!);
                        },
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'ERLAUBTE PFADE (ROOTS)',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 10,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _allowedRootsController,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFF121217),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      if (_sessionId != null)
                        OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              _sessionId = null;
                              _messages.clear();
                            });
                          },
                          icon: const Icon(Icons.delete_outline, size: 16),
                          label: const Text(
                            'Session beenden',
                            style: TextStyle(fontSize: 13),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                            side: const BorderSide(color: Colors.redAccent),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
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
    );
  }

  Widget _buildFloatingInputBar() {
    final hasText = _msgController.text.trim().isNotEmpty;
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 900;
    final themeColor = const Color(0xFFC9A24A);
    final brightness = Theme.of(context).brightness;
    final composerBg = AppColors.surface(
      brightness,
    ).withValues(alpha: brightness == Brightness.dark ? 0.92 : 0.96);
    final composerBorder = AppColors.divider(brightness);
    final composerText = AppColors.textPrimary(brightness);
    final composerHint = AppColors.textSecondary(brightness);

    final folders = _appState.modelFolders
        .where((f) => f.modelIds.isNotEmpty)
        .toList();
    final totalModelsCount = folders.fold<int>(
      0,
      (sum, f) => sum + f.modelIds.length,
    );
    final totalPossibleItems = folders.length + totalModelsCount;
    final limit = _appState.modelThresholdLimit;
    final double actualModelMenuHeight = (totalPossibleItems > limit)
        ? (limit * 40.0 + 16.0)
        : (totalPossibleItems * 40.0 + 16.0);

    List<PopupMenuEntry<String>> buildModelMenuItems() {
      final folders = _appState.modelFolders
          .where((f) => f.modelIds.isNotEmpty)
          .toList();
      final collapseByDefault = folders.length >= 2;

      // We will keep a local map of folderId -> isExpanded.
      // Since buildModelMenuItems is called once when opening, this map is initialized once per open.
      final Map<String, bool> folderExpanded = {};
      for (var f in folders) {
        folderExpanded[f.id] = !collapseByDefault;
      }

      return [
        PopupMenuItem<String>(
          enabled: false,
          padding: EdgeInsets.zero,
          child: StatefulBuilder(
            builder: (context, menuSetState) {
              final List<Widget> children = [];

              for (var folder in folders) {
                final isExpanded = folderExpanded[folder.id] ?? true;

                // Folder Header
                children.add(
                  InkWell(
                    onTap: () {
                      menuSetState(() {
                        folderExpanded[folder.id] = !isExpanded;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            folder.name.toUpperCase(),
                            style: TextStyle(
                              color: folder.color,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Icon(
                            isExpanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            size: 14,
                            color: folder.color,
                          ),
                        ],
                      ),
                    ),
                  ),
                );

                children.add(
                  Divider(
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.04),
                  ),
                );

                // Models under folder
                if (isExpanded) {
                  for (var modelId in folder.modelIds) {
                    final isSelected =
                        (_appState.selectedModelId ?? 'default-model') ==
                        modelId;
                    children.add(
                      InkWell(
                        onTap: () {
                          Navigator.pop(context, modelId);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          color: isSelected
                              ? themeColor.withValues(alpha: 0.06)
                              : Colors.transparent,
                          child: Row(
                            children: [
                              Icon(
                                Icons.psychology,
                                size: 14,
                                color: isSelected ? themeColor : Colors.white30,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  modelId,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.white70,
                                    fontSize: 11,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isSelected)
                                Icon(Icons.check, size: 12, color: themeColor),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                  children.add(
                    Divider(
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.04),
                    ),
                  );
                }
              }

              if (children.isNotEmpty && children.last is Divider) {
                children.removeLast();
              }

              return SizedBox(
                height: actualModelMenuHeight - 16.0,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: children,
                  ),
                ),
              );
            },
          ),
        ),
      ];
    }

    final modelItems = buildModelMenuItems();
    final thinkingOptions = [
      const ThinkingModeOption(value: 'none', label: 'Fast', icon: Icons.speed),
      const ThinkingModeOption(
        value: 'medium',
        label: 'Fast Thinking',
        icon: Icons.bolt,
      ),
      const ThinkingModeOption(
        value: 'max',
        label: 'Extra',
        icon: Icons.auto_awesome,
      ),
      const ThinkingModeOption(
        value: 'dual',
        label: 'Dual',
        icon: Icons.psychology,
        enabled: false,
      ),
      const ThinkingModeOption(
        value: 'agent',
        label: 'Agent',
        icon: Icons.smart_toy_outlined,
        enabled: false,
      ),
    ];

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24, top: 8),
        child: DropTarget(
          onDragDone: (details) {
            if (details.files.isNotEmpty) {
              setState(() {
                for (var file in details.files) {
                  _uploadedFiles.add({'name': file.name, 'path': file.path});
                }
              });
            }
          },
          onDragEntered: (details) {
            setState(() {
              _isDragging = true;
            });
          },
          onDragExited: (details) {
            setState(() {
              _isDragging = false;
            });
          },
          child: Container(
            constraints: BoxConstraints(
              minWidth: isDesktop ? 420 : 310,
              maxWidth: isDesktop
                  ? (width * 0.25 > 420 ? width * 0.25 : 420)
                  : (width * 0.95 > 500
                        ? 500
                        : (width * 0.95 > 310 ? width * 0.95 : 310)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: composerBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _isDragging ? themeColor : composerBorder,
                      width: _isDragging ? 1.5 : 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.38),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_uploadedFiles.isNotEmpty) ...[
                        Align(
                          alignment: Alignment.centerLeft,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: _uploadedFiles.map((file) {
                                return FileChip(
                                  file: file,
                                  themeColor: themeColor,
                                  onDelete: () {
                                    setState(() {
                                      _uploadedFiles.remove(file);
                                    });
                                  },
                                  onOpen: (path) => _openFile(path),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                      TextField(
                        focusNode: _inputFocusNode,
                        controller: _msgController,
                        style: TextStyle(color: composerText, fontSize: 13),
                        maxLines: 4,
                        minLines: 1,
                        decoration: InputDecoration(
                          hintText: 'Agenten instruieren...',
                          hintStyle: TextStyle(
                            color: composerHint.withValues(alpha: 0.56),
                            fontSize: 13,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (text) {
                          setState(() {});
                        },
                        onSubmitted: (_) => _sendMessage(),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CompositedTransformTarget(
                                  link: _plusMenuLink,
                                  child: GestureDetector(
                                    onTap: _togglePlusMenu,
                                    child: MouseRegion(
                                      onEnter: (_) =>
                                          setState(() => _plusHovered = true),
                                      onExit: (_) =>
                                          setState(() => _plusHovered = false),
                                      child: Padding(
                                        padding: const EdgeInsets.all(4.0),
                                        child: Icon(
                                          Icons.add,
                                          color: _plusHovered
                                              ? const Color(0xFFC9A24A)
                                              : Colors.white70,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: PopupMenuButton<String>(
                                    constraints: BoxConstraints(
                                      maxHeight: actualModelMenuHeight,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: BorderSide(
                                        color: Colors.white.withValues(
                                          alpha: 0.12,
                                        ),
                                        width: 1.0,
                                      ),
                                    ),
                                    color: const Color(0xFF0F0F14),
                                    offset: Offset(
                                      0,
                                      -actualModelMenuHeight - 12,
                                    ),
                                    tooltip: '',
                                    child: MouseRegion(
                                      onEnter: (_) =>
                                          setState(() => _modelHovered = true),
                                      onExit: (_) =>
                                          setState(() => _modelHovered = false),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Flexible(
                                              child: Text(
                                                _appState.selectedModelId ??
                                                    'default-model',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: _modelHovered
                                                      ? themeColor
                                                      : Colors.white70,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Icon(
                                              Icons.keyboard_arrow_down,
                                              size: 12,
                                              color: _modelHovered
                                                  ? themeColor
                                                  : Colors.white60,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    onSelected: (val) {
                                      if (val == '__open_catalog__') {
                                        _showModelManagementDialog();
                                      } else {
                                        _appState.setSelectedModelId(val);
                                      }
                                    },
                                    itemBuilder: (context) => modelItems,
                                  ),
                                ),
                                if (_webSearchEnabled) ...[
                                  const SizedBox(width: 6),
                                  ChatBadge(
                                    icon: Icons.language,
                                    label: 'Web',
                                    themeColor: const Color(0xFFC9A24A),
                                    onTap: () => setState(
                                      () => _webSearchEnabled = false,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          ThinkingModeSliderButton(
                            value: _thinkingLevel,
                            options: thinkingOptions,
                            themeColor: themeColor,
                            onChanged: (val) {
                              setState(() {
                                _thinkingLevel = val;
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          HoverIconButton(
                            icon: Icons.mic_none,
                            tooltip: 'Sprachsteuerung',
                            onPressed: () {},
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _sendMessage(),
                            child: MouseRegion(
                              onEnter: (_) =>
                                  setState(() => _sendHovered = true),
                              onExit: (_) =>
                                  setState(() => _sendHovered = false),
                              child: CircleAvatar(
                                radius: 14,
                                backgroundColor: hasText
                                    ? (_sendHovered
                                          ? themeColor
                                          : const Color(0xFFC9A24A))
                                    : Colors.white.withValues(alpha: 0.08),
                                child: AnimatedRotation(
                                  turns: hasText ? 0.25 : 0.0,
                                  duration: const Duration(milliseconds: 220),
                                  curve: Curves.easeOut,
                                  child: Icon(
                                    Icons.arrow_upward,
                                    color: hasText
                                        ? Colors.white
                                        : Colors.white60,
                                    size: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF121217),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: const Color(0xFF121217),
          style: const TextStyle(color: Colors.white, fontSize: 13),
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: Colors.white60,
            size: 18,
          ),
          isExpanded: true,
          items: items
              .map(
                (e) => DropdownMenuItem(value: e, child: Text(e.toUpperCase())),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
