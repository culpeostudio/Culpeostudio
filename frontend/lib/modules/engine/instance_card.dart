import 'dart:math' as math;

import 'package:flutter/material.dart';

import './models.dart';
import './widgets.dart';
import '../../core/app_strings.dart';
import '../../core/culpeo_grid.dart';
import '../../core/design_tokens.dart';

class InstanceCard extends StatelessWidget {
  const InstanceCard({
    super.key,
    required this.instance,
    required this.models,
    required this.busy,
    required this.expanded,
    required this.onToggleExpanded,
    required this.onAction,
    required this.onDelete,
    required this.onEditContext,
    required this.onEditSampling,
    required this.onApplySuggestedFix,
    required this.onUpdateInstance,
  });

  final EngineInstance instance;

  final List<ModelRecord> models;

  final bool busy;

  final bool expanded;

  final VoidCallback onToggleExpanded;

  final void Function(String action) onAction;

  final VoidCallback onDelete;
  final VoidCallback onEditContext;
  final VoidCallback onEditSampling;
  final VoidCallback onApplySuggestedFix;

  final void Function(Map<String, dynamic> patch) onUpdateInstance;

  @override
  Widget build(BuildContext context) {
    final instance = this.instance;
    final model = models
        .where((model) => model.id == instance.modelId)
        .firstOrNull;
    final busy = this.busy;
    final displayName = instance.servedModelName.isNotEmpty
        ? instance.servedModelName
        : (model?.name ?? instance.id);
    final detailsExpanded = expanded;
    final transitional = const {
      'installing',
      'queued',
      'starting',
      'draining',
      'restarting',
    }.contains(instance.state);
    return Container(
      key: Key('engine-instance-${instance.id}'),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: engineInsetColor,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: instance.isReady
              ? const Color(0xFF4CAF50).withValues(alpha: 0.22)
              : Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _instanceStageTitle(instance),
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              EngineStatusBadge(status: instance.state),
              PopupMenuButton<String>(
                tooltip: tr('engineWidget.instance.moreActions'),
                enabled: !busy,
                icon: const Icon(Icons.more_vert, color: Colors.white54),
                onSelected: (value) {
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.delete_outline),
                      title: Text(tr('engineWidget.instance.remove')),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 9),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              EnginePlacementBadge(
                placement: instance.placement,
                planned: !instance.isReady,
              ),
              EngineGuardBadge(state: instance.guardState),
              if (instance.activeRequests > 0)
                Text(
                  instance.activeRequests == 1
                      ? tr('engineWidget.instance.activeRequest', {
                          'count': '${instance.activeRequests}',
                        })
                      : tr('engineWidget.instance.activeRequests', {
                          'count': '${instance.activeRequests}',
                        }),
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
            ],
          ),
          if (transitional || instance.state == 'failed') ...[
            const SizedBox(height: 12),
            Container(
              key: Key('engine-instance-guide-${instance.id}'),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    (instance.state == 'failed'
                            ? const Color(0xFFF44336)
                            : engineBlue)
                        .withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    instance.state == 'failed'
                        ? Icons.info_outline
                        : Icons.auto_awesome_outlined,
                    color: instance.state == 'failed'
                        ? const Color(0xFFEF9A9A)
                        : const Color(0xFFEBD9A8),
                    size: 19,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      instanceStageDescription(instance),
                      style: TextStyle(
                        color: instance.state == 'failed'
                            ? const Color(0xFFFFCDD2)
                            : Colors.white70,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (instance.state != 'failed') ...[
              const SizedBox(height: 9),
              LinearProgressIndicator(
                value: instance.progress > 0 ? instance.progress : null,
                minHeight: 4,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 5),
              Text(
                instance.progress > 0
                    ? tr('engineWidget.instance.progressComplete', {
                        'percent': '${(instance.progress * 100).round()}',
                      })
                    : tr('engineWidget.instance.preparing'),
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ],
          if (instance.plan != null && instance.isReady) ...[
            const SizedBox(height: 13),
            EngineContextBar(plan: instance.plan!, compact: true),
            const SizedBox(height: 13),
            _memoryPlacement(instance.plan!),
          ],
          if (instance.plan != null && transitional) ...[
            const SizedBox(height: 9),
            Text(
              tr('engineWidget.instance.plannedContext', {
                'tokens': formatTokenCount(
                  instance.plan!.effectiveContextTokens,
                ),
              }),
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
          if (instance.fallbacks.isNotEmpty) ...[
            const SizedBox(height: 9),
            engineWarningBox(_instanceFallbackMessage(instance)),
          ],
          if (instance.errorSummary.isNotEmpty ||
              (instance.error != null && instance.error!.isNotEmpty)) ...[
            const SizedBox(height: 9),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF44336).withValues(alpha: 0.11),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                instanceErrorMessage(instance),
                style: const TextStyle(color: Color(0xFFFFCDD2), fontSize: 12),
              ),
            ),
            if (instance.suggestedFix != null && !instance.isActive) ...[
              const SizedBox(height: 9),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  key: Key('engine-suggested-fix-${instance.id}'),
                  onPressed: busy ? null : () => onApplySuggestedFix(),
                  icon: const Icon(Icons.auto_fix_high, size: 17),
                  label: Text(instance.suggestedFix!.label),
                ),
              ),
            ],
          ],
          if (detailsExpanded) ...[
            const SizedBox(height: 12),
            _instanceTechnicalDetails(instance),
          ],
          const SizedBox(height: 6),
          Material(
            color: Colors.transparent,
            child: CheckboxListTile(
              key: Key('engine-show-in-chat-${instance.id}'),
              contentPadding: EdgeInsets.zero,
              dense: false,
              controlAffinity: ListTileControlAffinity.leading,
              value: instance.showInChatPicker,
              onChanged: busy
                  ? null
                  : (value) => onUpdateInstance({
                      'show_in_chat_picker': value == true,
                    }),
              title: Text(
                tr('engineWidget.instance.showInChatTitle'),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              subtitle: Text(
                tr('engineWidget.instance.showInChatSubtitle'),
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ),
          ),
          const SizedBox(height: 13),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (instance.isReady)
                OutlinedButton.icon(
                  onPressed: busy ? null : () => onAction('stop'),
                  icon: const Icon(Icons.stop, size: 17),
                  label: Text(tr('engine.stopInstance')),
                )
              else if (!instance.isActive)
                FilledButton.tonalIcon(
                  onPressed: busy ? null : () => onAction('start'),
                  icon: Icon(
                    instance.state == 'failed'
                        ? Icons.refresh
                        : Icons.play_arrow,
                    size: 17,
                  ),
                  label: Text(
                    instance.state == 'failed'
                        ? tr('common.retry')
                        : tr('engine.startInstance'),
                  ),
                ),
              if (instance.isReady)
                OutlinedButton.icon(
                  onPressed: busy ? null : () => onEditSampling(),
                  icon: const Icon(Icons.graphic_eq, size: 17),
                  label: Text(tr('engine.responseBehavior')),
                ),
              if (instance.isReady && instance.plan != null)
                OutlinedButton.icon(
                  key: Key('engine-context-edit-${instance.id}'),
                  onPressed: busy ? null : () => onEditContext(),
                  icon: const Icon(Icons.memory_outlined, size: 17),
                  label: Text(tr('engine.context')),
                ),
              TextButton.icon(
                key: Key('engine-instance-details-toggle-${instance.id}'),
                onPressed: onToggleExpanded,
                icon: Icon(
                  detailsExpanded ? Icons.expand_less : Icons.expand_more,
                  size: 17,
                ),
                label: Text(
                  detailsExpanded
                      ? tr('engine.detailsLess')
                      : tr('engine.detailsMore'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Where this instance's memory actually sits.
  ///
  /// Whether a model runs from VRAM or spills into system RAM is the difference
  /// between fast and slow, and the engine asks the user to decide it rather
  /// than deciding for them. A proportional bar makes that trade visible at a
  /// glance, which a row of byte figures does not.
  Widget _memoryPlacement(ContextPlan plan) {
    final gpu = plan.memory.gpuBytes;
    final ram = plan.memory.ramBytes;
    if (gpu <= 0 && ram <= 0) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              tr('engineWidget.instance.memoryPlacement'),
              style: TextStyle(
                color: CulpeoColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
            const Spacer(),
            if (ram > 0)
              CulpeoBadge(
                label: tr('engineWidget.instance.hybrid'),
                color: CulpeoColors.ram,
                tooltip: tr('engineWidget.instance.hybridTooltip'),
              ),
          ],
        ),
        const SizedBox(height: 7),
        CulpeoSplitBar(
          segments: [
            CulpeoSplitSegment(
              bytes: gpu,
              color: CulpeoColors.vram,
              label: tr('engineWidget.instance.vramShare', {
                'size': formatBytes(gpu),
              }),
            ),
            CulpeoSplitSegment(
              bytes: ram,
              color: CulpeoColors.ram,
              label: tr('engineWidget.instance.ramShare', {
                'size': formatBytes(ram),
              }),
            ),
          ],
        ),
      ],
    );
  }
}

Widget engineWarningBox(String text) {
  return Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: CulpeoColors.metric.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.warning_amber,
          color: CulpeoColors.metricBright,
          size: 17,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Color(0xFFEBD9A8), fontSize: 12),
          ),
        ),
      ],
    ),
  );
}

String _instanceFallbackMessage(EngineInstance instance) {
  var failedContext = 0;
  for (final fallback in instance.fallbacks) {
    final from = int.tryParse(fallback.from.trim());
    final isContextFallback =
        fallback.setting == 'context_tokens' ||
        (from != null && fallback.reason.toLowerCase().contains('kontext'));
    if (isContextFallback && from != null) {
      failedContext = math.max(failedContext, from);
    }
  }
  final activeContext =
      instance.plan?.effectiveContextTokens ??
      instance.effectiveConfig.contextTokens ??
      0;
  if (failedContext > activeContext && activeContext > 0) {
    return tr('engineWidget.instance.fallback.unstableContext', {
      'failed': formatTokenCount(failedContext),
      'active': formatTokenCount(activeContext),
    });
  }
  return tr('engineWidget.instance.fallback.compatibleRuntime');
}

String _instanceStageTitle(EngineInstance instance) {
  switch (instance.state) {
    case 'installing':
      return tr('engineWidget.instance.stage.installing');
    case 'queued':
      return tr('engineWidget.instance.stage.queued');
    case 'starting':
      return tr('engineWidget.instance.stage.starting');
    case 'draining':
      return tr('engineWidget.instance.stage.draining');
    case 'restarting':
      return tr('engineWidget.instance.stage.restarting');
    case 'ready':
      return tr('engineWidget.instance.stage.ready');
    case 'failed':
    case 'failed_rollback':
      return tr('engineWidget.instance.stage.failed');
    case 'stopped':
      return tr('engineWidget.instance.stage.stopped');
    default:
      return tr('engineWidget.instance.stage.default');
  }
}

String instanceStageDescription(EngineInstance instance) {
  if (instance.detailMessage.trim().isNotEmpty) {
    return instance.detailMessage.trim();
  }
  switch (instance.state) {
    case 'installing':
      return tr('engineWidget.instance.description.installing');
    case 'queued':
      return tr('engineWidget.instance.description.queued');
    case 'starting':
      return tr('engineWidget.instance.description.starting');
    case 'draining':
      return tr('engineWidget.instance.description.draining');
    case 'restarting':
      return tr('engineWidget.instance.description.restarting');
    case 'failed':
    case 'failed_rollback':
      return tr('engineWidget.instance.description.failed');
    default:
      return tr('engineWidget.instance.description.default');
  }
}

String friendlyEngineError(String raw) {
  final value = raw.toLowerCase();
  if (value.contains('exit status') || value.contains('exit code')) {
    return tr('engineWidget.error.setupFailed');
  }
  if (value.contains('out of memory') || value.contains('oom')) {
    return tr('engineWidget.error.memoryInsufficient');
  }
  if (value.contains('cuda') ||
      value.contains('rocm') ||
      value.contains('vulkan')) {
    return tr('engineWidget.error.gpuUnavailable');
  }
  return tr('engineWidget.error.generic');
}

String instanceErrorMessage(EngineInstance instance) {
  final raw = instance.errorSummary.isNotEmpty
      ? instance.errorSummary
      : (instance.error ?? '');
  final value = raw.toLowerCase();

  if (value.contains('engine plan conflict') ||
      (value.contains('minimum context') && value.contains('maximum is'))) {
    return tr('engineWidget.error.planChanged');
  }
  return instance.errorSummary.isNotEmpty ? raw : friendlyEngineError(raw);
}

Widget _instanceTechnicalDetails(EngineInstance instance) {
  final context =
      instance.plan?.effectiveContextTokens ??
      instance.effectiveConfig.contextTokens ??
      0;
  return Container(
    key: Key('engine-instance-details-${instance.id}'),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.035),
      borderRadius: BorderRadius.circular(9),
      border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          tr('engineWidget.details.title'),
          style: const TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        _detailLine(tr('engineWidget.details.modelName'), instance.id),
        _detailLine(
          tr('engineWidget.details.runtime'),
          runtimeLabel(instance.effectiveConfig.runtime),
        ),
        _detailLine(
          tr('engineWidget.details.context'),
          tr('engineWidget.details.contextTokens', {
            'tokens': formatTokenCount(context),
          }),
        ),
        if (instance.phase.isNotEmpty)
          _detailLine(tr('engineWidget.details.internalPhase'), instance.phase),
        _detailLine(
          tr('engineWidget.details.priority'),
          _priorityLabel(instance.requestedConfig.priority),
        ),
        _detailLine(
          tr('engineWidget.details.placement'),
          _placementLabel(instance.placement),
        ),
        _detailLine(
          tr('engineWidget.details.activeRequests'),
          instance.activeRequests.toString(),
        ),
        _detailLine(
          tr('engineWidget.details.resourceProtection'),
          _guardLabel(instance.guardState),
        ),
        if (instance.lastUsedAt != null)
          _detailLine(
            tr('engineWidget.details.lastUsed'),
            _formatEngineTime(instance.lastUsedAt!),
          ),
        if (instance.idleExpiresAt != null)
          _detailLine(
            tr('engineWidget.details.automaticStop'),
            _formatEngineTime(instance.idleExpiresAt!),
          ),
        if (instance.fallbacks.isNotEmpty)
          _detailLine(
            tr('engineWidget.details.automaticAdjustment'),
            instance.fallbacks.map((item) => item.label).join(' · '),
          ),
        if (instance.restartRequiredFields.isNotEmpty)
          _detailLine(
            tr('engineWidget.details.restartRequired'),
            instance.restartRequiredFields
                .map(_restartFieldLabel)
                .toSet()
                .join(', '),
          ),
        if (instance.error != null && instance.error!.isNotEmpty)
          _detailLine(tr('engineWidget.details.errorLog'), instance.error!),
      ],
    ),
  );
}

Widget _detailLine(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final labelWidget = Text(
          label,
          style: const TextStyle(color: Colors.white38, fontSize: 12),
        );
        final valueWidget = SelectableText(
          value,
          style: const TextStyle(color: Colors.white60, fontSize: 12),
        );
        if (constraints.maxWidth < 430) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [labelWidget, const SizedBox(height: 2), valueWidget],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 150, child: labelWidget),
            Expanded(child: valueWidget),
          ],
        );
      },
    ),
  );
}

String runtimeLabel(String runtime) {
  switch (runtime.toLowerCase()) {
    case 'llama_cpp':
    case 'llama-cpp-python':
      return 'llama.cpp';
    case 'auto':
    case '':
      return tr('engineWidget.runtime.auto');
    default:
      return runtime;
  }
}

String _priorityLabel(String priority) {
  switch (priority) {
    case 'low':
      return tr('engineWidget.priority.low');
    case 'high':
      return tr('engineWidget.priority.high');
    case 'pinned':
      return tr('engineWidget.priority.pinned');
    default:
      return tr('engineWidget.priority.normal');
  }
}

String _placementLabel(String placement) => switch (placement) {
  'gpu' => 'GPU',
  'ram' => 'RAM',
  'hybrid' => 'GPU + RAM',
  _ => tr('engineWidget.placement.unknown'),
};

String _guardLabel(String guard) => switch (guard) {
  'warning' => tr('engineWidget.instance.guard.warning'),
  'critical' => tr('engineWidget.instance.guard.critical'),
  'emergency' => tr('engineWidget.instance.guard.emergency'),
  _ => tr('engineWidget.instance.guard.normal'),
};

String _formatEngineTime(DateTime value) {
  final local = value.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return tr('engineWidget.time.short', {
    'day': local.day.toString().padLeft(2, '0'),
    'month': local.month.toString().padLeft(2, '0'),
    'year': '${local.year}',
    'hour': hour,
    'minute': minute,
  });
}

String _restartFieldLabel(String field) => switch (field) {
  'runtime' => tr('engineWidget.restartField.runtime'),
  'context_tokens' => tr('engineWidget.restartField.contextTokens'),
  'gpu_layers' => tr('engineWidget.restartField.gpuLayers'),
  'threads' => tr('engineWidget.restartField.threads'),
  'tensor_parallel_size' => tr('engineWidget.restartField.tensorParallelSize'),
  'gpu_ids' => tr('engineWidget.restartField.gpuIds'),
  'offload' => tr('engineWidget.restartField.offload'),
  'kv_cache_dtype' => tr('engineWidget.restartField.kvCacheDtype'),
  'max_sequences' => tr('engineWidget.restartField.maxSequences'),
  _ => field,
};
