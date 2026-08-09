import 'package:flutter/material.dart';

import '../../core/design_tokens.dart';

import '../scout/chat_aux_strings.dart';

class FileChangeCard extends StatefulWidget {
  const FileChangeCard({
    super.key,
    required this.path,
    required this.actionLabel,
    required this.actionColor,
    this.destination,
    required this.diff,
    required this.diffSkipped,
  });

  final String path;
  final String actionLabel;
  final Color actionColor;
  final String? destination;
  final String diff;
  final bool diffSkipped;

  @override
  State<FileChangeCard> createState() => _FileChangeCardState();
}

class _FileChangeCardState extends State<FileChangeCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final fileName = widget.path.split('/').last;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              child: Row(
                children: [
                  Icon(
                    _expanded ? Icons.expand_more : Icons.chevron_right_rounded,
                    size: 15,
                    color: Colors.white38,
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.edit_note,
                    size: 15,
                    color: CulpeoColors.metricBright,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      fileName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: widget.actionColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      widget.actionLabel,
                      style: TextStyle(
                        color: widget.actionColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1, color: Colors.white10),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.destination != null
                        ? '${widget.path} → ${widget.destination}'
                        : widget.path,
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                  if (widget.diff.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final line in widget.diff.split('\n'))
                              if (line.isNotEmpty) _buildDiffLine(line),
                          ],
                        ),
                      ),
                    ),
                  ] else if (widget.diffSkipped) ...[
                    const SizedBox(height: 8),
                    Text(
                      tr('chatAux.fileChange.diffSkipped'),
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDiffLine(String line) {
    Color color = Colors.white54;
    Color? background;
    if (line.startsWith('+') && !line.startsWith('+++')) {
      color = const Color(0xFF7BAE7F);
      background = const Color(0xFF7BAE7F).withValues(alpha: 0.06);
    } else if (line.startsWith('-') && !line.startsWith('---')) {
      color = const Color(0xFFD97B7B);
      background = const Color(0xFFD97B7B).withValues(alpha: 0.06);
    } else if (line.startsWith('@@')) {
      color = CulpeoColors.metricBright;
    } else if (line.startsWith('+++') || line.startsWith('---')) {
      color = Colors.white38;
    }
    return Container(
      color: background,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        line,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontFamily: 'monospace',
          height: 1.35,
        ),
      ),
    );
  }
}
