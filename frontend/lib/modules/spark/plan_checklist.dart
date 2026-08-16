import 'package:flutter/material.dart';

import '../../core/design_tokens.dart';

import '../scout/chat_aux_strings.dart';

/// The approved plan as a worklist that ticks itself off. Spark splits a task
/// into steps, then works them one at a time with a fresh context per step -
/// this is where that run becomes visible.
///
/// It wears the composer like a hat and stays folded down to a single line:
/// during a long run the interesting part is which step is going, not the whole
/// list, and the list would otherwise push the input halfway up the screen. One
/// tap opens it.
///
/// Gold frames it, like the approval panel it takes over from: this reports
/// what the engine is doing, it is not a control. Only the row states carry
/// their own colour - green for a finished step, red for one that broke.
class PlanChecklist extends StatefulWidget {
  const PlanChecklist({
    super.key,
    required this.summary,
    required this.steps,
    required this.running,
    this.onResume,
    this.onDiscard,
  });

  final String summary;
  final List<Map<String, dynamic>> steps;

  /// True while the run is still going. Once it is false, a step left pending
  /// is one that never started, because an earlier step failed.
  final bool running;

  /// Picks the worklist up again where it stopped. Only offered once the run
  /// is standing still with points left open - which is the case the whole
  /// thing exists for: a crash must not cost the plan.
  final VoidCallback? onResume;

  /// Drops the worklist. The plan is only ever finished or dropped, never
  /// silently forgotten.
  final VoidCallback? onDiscard;

  @override
  State<PlanChecklist> createState() => _PlanChecklistState();
}

class _PlanChecklistState extends State<PlanChecklist> {
  bool _expanded = false;

  int get _open =>
      widget.steps.where((step) => step['status'] != 'done').length;

  int get _done =>
      widget.steps.where((step) => step['status'] == 'done').length;

  @override
  Widget build(BuildContext context) {
    final steps = widget.steps;
    final total = steps.length;
    final current = steps.indexWhere((step) => step['status'] == 'running');
    // Between one step reporting back and the next one starting, no row is
    // running. The counter names the step that is up next instead of dropping
    // to the finished-count for a frame.
    final active = current >= 0
        ? current + 1
        : (_done < total ? _done + 1 : total);
    // Folded down, this line has to carry the whole run: what it is at, and
    // what that step is called.
    final currentTitle = current >= 0
        ? (steps[current]['title']?.toString() ?? '')
        : '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      decoration: BoxDecoration(
        color: CulpeoColors.metric.withValues(alpha: 0.08),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
        border: Border(
          top: BorderSide(color: CulpeoColors.metric.withValues(alpha: 0.35)),
          left: BorderSide(color: CulpeoColors.metric.withValues(alpha: 0.35)),
          right: BorderSide(color: CulpeoColors.metric.withValues(alpha: 0.35)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            key: const Key('plan-checklist-header'),
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                Icon(
                  Icons.checklist_rtl,
                  color: CulpeoColors.metricBright,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  tr('chatAux.plan.title'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (!_expanded && currentTitle.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      currentTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  widget.running
                      ? tr('chatAux.plan.progress', {
                          'current': '$active',
                          'total': '$total',
                        })
                      : tr('chatAux.plan.doneCount', {
                          'done': '$_done',
                          'total': '$total',
                        }),
                  style: TextStyle(
                    color: CulpeoColors.metricSoft,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  color: CulpeoColors.metricSoft,
                  size: 18,
                ),
              ],
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: _expanded
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.summary.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          widget.summary,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 220),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (final step in steps)
                                _PlanStepRow(
                                  step: step,
                                  running: widget.running,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : const SizedBox(width: double.infinity),
          ),
          if (!widget.running &&
              _open > 0 &&
              (widget.onResume != null || widget.onDiscard != null))
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      tr('chatAux.plan.openLeft', {'open': '$_open'}),
                      style: TextStyle(
                        color: CulpeoColors.metricSoft,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  if (widget.onDiscard != null)
                    TextButton(
                      onPressed: widget.onDiscard,
                      child: Text(
                        tr('chatAux.plan.discard'),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  if (widget.onResume != null) ...[
                    const SizedBox(width: 6),
                    ElevatedButton(
                      onPressed: widget.onResume,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CulpeoColors.metric,
                        visualDensity: VisualDensity.compact,
                      ),
                      child: Text(
                        tr('chatAux.plan.resume'),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _PlanStepRow extends StatelessWidget {
  const _PlanStepRow({required this.step, required this.running});

  final Map<String, dynamic> step;
  final bool running;

  @override
  Widget build(BuildContext context) {
    final status = step['status']?.toString() ?? 'pending';
    final title = step['title']?.toString() ?? '';
    final result = step['result']?.toString() ?? '';
    // A step still pending after the run stopped never started at all - an
    // earlier one failed and took the rest of the list with it.
    final stranded = !running && status == 'pending';

    final titleColor = switch (status) {
      'done' => Colors.white70,
      'running' => Colors.white,
      'failed' => Colors.white,
      _ => stranded ? Colors.white24 : Colors.white38,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: Center(child: _marker(status, stranded)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 12,
                    fontWeight: status == 'running'
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
                if (stranded)
                  Text(
                    tr('chatAux.plan.notRun'),
                    style: const TextStyle(color: Colors.white24, fontSize: 11),
                  )
                else if (result.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      result,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: status == 'failed'
                            ? CulpeoColors.danger.withValues(alpha: 0.85)
                            : Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _marker(String status, bool stranded) {
    switch (status) {
      case 'done':
        return Icon(Icons.check_circle, size: 15, color: CulpeoColors.success);
      case 'failed':
        return Icon(Icons.error_outline, size: 15, color: CulpeoColors.danger);
      case 'running':
        return SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 1.6,
            color: CulpeoColors.metricBright,
          ),
        );
      default:
        return Icon(
          Icons.radio_button_unchecked,
          size: 13,
          color: stranded ? Colors.white12 : Colors.white24,
        );
    }
  }
}
