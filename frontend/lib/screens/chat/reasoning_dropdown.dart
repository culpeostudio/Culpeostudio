import 'package:flutter/material.dart';

import '../../l10n/chat_aux_strings.dart';

/// Zusammengeklappter Gedankengang (`<think>...</think>` Inhalt) unter einer
/// fertigen Antwort. Waehrend des Streamings zeigt der Chat den Rohtext als
/// Live-Vorschau; sobald die finale Antwort steht, ersetzt dieses Dropdown sie
/// — standardmaessig zugeklappt, damit der Chatverlauf nicht mit Rohtext
/// vermuellt wird.
class ReasoningDropdown extends StatefulWidget {
  const ReasoningDropdown({super.key, required this.reasoning});

  final String reasoning;

  @override
  State<ReasoningDropdown> createState() => _ReasoningDropdownState();
}

class _ReasoningDropdownState extends State<ReasoningDropdown> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final trimmed = widget.reasoning.trim();
    final wordCount = trimmed.isEmpty
        ? 0
        : trimmed.split(RegExp(r'\s+')).length;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
                    Icons.psychology_outlined,
                    size: 15,
                    color: Color(0xFFDFC077),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      wordCount > 0
                          ? tr('chatAux.reasoning.titleWithWords', {
                              'count': wordCount.toString(),
                            })
                          : tr('chatAux.reasoning.title'),
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
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
              child: Text(
                trimmed,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12.5,
                  fontStyle: FontStyle.italic,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
