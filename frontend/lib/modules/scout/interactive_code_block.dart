import 'package:flutter/material.dart';

import '../../core/design_tokens.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;

import './chat_aux_strings.dart';
import './chat_markdown_helpers.dart';
import './chat_visual_block.dart';

class InteractiveCodeElementBuilder extends MarkdownElementBuilder {
  final void Function(String code, String? language) onCodeTap;

  final double fontSize;

  final Color accentColor;

  InteractiveCodeElementBuilder({
    required this.onCodeTap,
    this.fontSize = 12,
    this.accentColor = CulpeoColors.metric,
  });

  @override
  bool isBlockElement() => false;

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final hasClass = element.attributes.containsKey('class');
    final hasNewline = element.textContent.contains('\n');
    final isBlock = hasClass || hasNewline;

    if (!isBlock) {
      return null;
    }

    String? language;
    if (hasClass) {
      final className = element.attributes['class']!;
      if (className.startsWith('language-')) {
        language = className.substring('language-'.length);
      }
    }

    final code = element.textContent;
    if (language == 'visual' ||
        language == 'chart' ||
        language == 'culpeo-visual') {
      return ChatVisualBlock(source: code);
    }
    if (isMarkdownSourceLanguage(language)) {
      return MarkdownSourceBlock(
        source: code,
        language: language,
        accentColor: CulpeoColors.metricBright,
      );
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onCodeTap(code, language),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.02),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.white.withValues(alpha: 0.04),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        language?.toUpperCase() ??
                            tr('chatAux.code.defaultLanguage'),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: fontSize,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.open_in_new,
                      size: 12,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        tr('chatAux.code.view'),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.3),
                          fontSize: fontSize,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.01),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.terminal_outlined,
                      size: 16,
                      color: accentColor.withValues(alpha: 0.8),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        buildCodePreviewLabel(code),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: fontSize,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
