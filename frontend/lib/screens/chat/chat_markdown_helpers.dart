import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_markdown_latex/flutter_markdown_latex.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/chat_aux_strings.dart';
import '../../widgets/top_notification.dart';

String normalizeChatMarkdown(String input) {
  if (input.isEmpty) {
    return input;
  }

  return input.replaceAllMapped(
    RegExp(
      r'(^|\n)[ \t]*\\\[[ \t]*\r?\n([\s\S]*?)\r?\n[ \t]*\\\][ \t]*(?=\n|$)',
      multiLine: true,
    ),
    (match) {
      final leadingBreak = match.group(1) ?? '';
      final body = (match.group(2) ?? '').trim();
      if (body.isEmpty) {
        return '$leadingBreak\$\$\n\$\$';
      }
      return '$leadingBreak\$\$\n$body\n\$\$';
    },
  );
}

String buildCodePreviewLabel(String code) {
  final lineCount = code.trim().isEmpty ? 0 : code.trim().split('\n').length;
  final displayCount = lineCount == 0 ? 1 : lineCount;
  return tr('chatAux.markdown.codePreview', {'count': displayCount.toString()});
}

bool isMarkdownSourceLanguage(String? language) {
  final normalized = (language ?? '').trim().toLowerCase();
  return normalized == 'markdown' ||
      normalized == 'md' ||
      normalized == 'text' ||
      normalized == 'txt' ||
      normalized == 'plain' ||
      normalized == 'plaintext';
}

bool shouldUseInputCheckboxBuilder(String markdown) {
  final hasRawCheckboxInput = RegExp(
    "<input\\b[^>]*\\btype\\s*=\\s*['\"]?checkbox",
    caseSensitive: false,
  ).hasMatch(markdown);
  if (!hasRawCheckboxInput) {
    return false;
  }
  final hasGfmTaskList = RegExp(
    r'(^|\n)\s*(?:[-+*]|\d+[.)])\s+\[[ xX]\]\s+',
    multiLine: true,
  ).hasMatch(markdown);
  return !hasGfmTaskList;
}

Widget buildMarkdownCheckbox(bool checked, {Color? color}) {
  return Semantics(
    checked: checked,
    child: Padding(
      padding: const EdgeInsets.only(right: 8, top: 2),
      child: Icon(
        checked ? Icons.check_box : Icons.check_box_outline_blank,
        size: 18,
        color: color ?? Colors.white70,
      ),
    ),
  );
}

class TaskCheckboxElementBuilder extends MarkdownElementBuilder {
  TaskCheckboxElementBuilder({this.accentColor});

  final Color? accentColor;

  @override
  bool isBlockElement() => false;

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final type = element.attributes['type']?.trim().toLowerCase();
    if (type != 'checkbox') {
      return null;
    }
    final checkedValue = element.attributes['checked']?.trim().toLowerCase();
    final checked = checkedValue != null && checkedValue != 'false';
    return buildMarkdownCheckbox(checked, color: accentColor);
  }
}

Future<void> openMarkdownLink(BuildContext context, String? href) async {
  if (href == null || href.trim().isEmpty) {
    return;
  }

  final uri = Uri.tryParse(href.trim());
  if (uri == null) {
    if (context.mounted) {
      showTopNotification(
        context,
        tr('chatAux.markdown.linkOpenFailed'),
        color: Colors.redAccent,
      );
    }
    return;
  }

  try {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      showTopNotification(
        context,
        tr('chatAux.markdown.linkOpenFailedWithUrl', {'url': href}),
        color: Colors.redAccent,
      );
    }
  } catch (_) {
    if (context.mounted) {
      showTopNotification(
        context,
        tr('chatAux.markdown.linkOpenFailedWithUrl', {'url': href}),
        color: Colors.redAccent,
      );
    }
  }
}

class MarkdownSourceBlock extends StatefulWidget {
  const MarkdownSourceBlock({
    super.key,
    required this.source,
    required this.accentColor,
    this.language,
  });

  final String source;
  final String? language;
  final Color accentColor;

  @override
  State<MarkdownSourceBlock> createState() => _MarkdownSourceBlockState();
}

class _MarkdownSourceBlockState extends State<MarkdownSourceBlock> {
  bool _showSource = false;

  Future<void> _copySource() async {
    await Clipboard.setData(ClipboardData(text: widget.source));
    if (!mounted) {
      return;
    }
    showTopNotification(context, tr('chatAux.markdown.sourceCopied'));
  }

  @override
  Widget build(BuildContext context) {
    final languageLabel = (widget.language?.trim().isNotEmpty ?? false)
        ? widget.language!.trim().toUpperCase()
        : tr('chatAux.markdown.plainText');
    final borderColor = Colors.white.withValues(alpha: 0.08);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              children: [
                Text(
                  languageLabel,
                  style: TextStyle(
                    color: widget.accentColor.withValues(alpha: 0.85),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                ToggleButtons(
                  constraints: const BoxConstraints(
                    minHeight: 28,
                    minWidth: 76,
                  ),
                  borderRadius: BorderRadius.circular(6),
                  borderColor: borderColor,
                  selectedBorderColor: widget.accentColor.withValues(
                    alpha: 0.55,
                  ),
                  fillColor: widget.accentColor.withValues(alpha: 0.14),
                  color: Colors.white60,
                  selectedColor: Colors.white,
                  textStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  isSelected: [!_showSource, _showSource],
                  onPressed: (index) {
                    setState(() => _showSource = index == 1);
                  },
                  children: [
                    Text(tr('chatAux.markdown.preview')),
                    Text(tr('chatAux.markdown.source')),
                  ],
                ),
                const SizedBox(width: 6),
                IconButton(
                  tooltip: tr('chatAux.markdown.copySource'),
                  visualDensity: VisualDensity.compact,
                  iconSize: 18,
                  color: Colors.white70,
                  onPressed: _copySource,
                  icon: const Icon(Icons.copy_rounded),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: borderColor),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 140),
            child: _showSource ? _buildSourceView() : _buildPreview(context),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview(BuildContext context) {
    final previewSource = normalizeChatMarkdown(widget.source);
    return Padding(
      key: const ValueKey('preview'),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: MarkdownBody(
        data: previewSource,
        selectable: true,
        onTapLink: (text, href, title) {
          openMarkdownLink(context, href);
        },
        checkboxBuilder: (checked) =>
            buildMarkdownCheckbox(checked, color: widget.accentColor),
        blockSyntaxes: [LatexBlockSyntax()],
        inlineSyntaxes: [LatexInlineSyntax()],
        extensionSet: md.ExtensionSet.gitHubFlavored,
        builders: {
          if (shouldUseInputCheckboxBuilder(previewSource))
            'input': TaskCheckboxElementBuilder(
              accentColor: widget.accentColor,
            ),
          'latex': LatexElementBuilder(
            textStyle: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        },
        styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
          codeblockDecoration: const BoxDecoration(color: Colors.transparent),
          codeblockPadding: EdgeInsets.zero,
          p: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
          pPadding: const EdgeInsets.only(bottom: 12),
          checkbox: TextStyle(color: widget.accentColor, fontSize: 18),
          tableBody: const TextStyle(color: Colors.white70, fontSize: 13),
          tableHead: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSourceView() {
    return Container(
      key: const ValueKey('source'),
      padding: const EdgeInsets.all(12),
      color: Colors.black.withValues(alpha: 0.12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SelectableText(
          widget.source,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            height: 1.45,
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }
}
