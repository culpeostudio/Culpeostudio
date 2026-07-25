import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../engine/models.dart';
import '../../engine/widgets.dart';

/// Karte einer Engine-Instanz in der Instanzliste: Status, Fortschritt,
/// Fehlermeldung samt Sofort-Fix und die Aktionsleiste (Start/Stopp, Kontext,
/// Antwortverhalten, Details).
///
/// Zustandslos — der Screen haelt weiterhin Controller und Aufklapp-Zustand und
/// reicht nur das Noetige herein. Die Formatierungs-Helfer darunter sind reine
/// Funktionen; die oeffentlichen werden auch vom Screen selbst genutzt.
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

  /// Modellkatalog fuer den Titel-Lookup ueber [EngineInstance.modelId].
  final List<ModelRecord> models;

  /// True, solange fuer diese Instanz eine Operation laeuft (sperrt Aktionen).
  final bool busy;

  /// True, wenn der technische Detailblock aufgeklappt ist.
  final bool expanded;

  final VoidCallback onToggleExpanded;

  /// Startet/stoppt die Instanz; das Argument ist die Aktion ('start'/'stop').
  final void Function(String action) onAction;

  final VoidCallback onDelete;
  final VoidCallback onEditContext;
  final VoidCallback onEditSampling;
  final VoidCallback onApplySuggestedFix;

  /// Schreibt eine Teilaenderung an der Instanz zurueck (z. B. Chat-Sichtbarkeit).
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
                tooltip: 'Weitere Aktionen',
                enabled: !busy,
                icon: const Icon(Icons.more_vert, color: Colors.white54),
                onSelected: (value) {
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.delete_outline),
                      title: Text('Modellinstanz entfernen'),
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
                  '${instance.activeRequests} aktive ${instance.activeRequests == 1 ? 'Anfrage' : 'Anfragen'}',
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
                    ? '${(instance.progress * 100).round()} % abgeschlossen'
                    : 'Wird vorbereitet …',
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ],
          if (instance.plan != null && instance.isReady) ...[
            const SizedBox(height: 13),
            EngineContextBar(plan: instance.plan!, compact: true),
          ],
          if (instance.plan != null && transitional) ...[
            const SizedBox(height: 9),
            Text(
              '${formatTokenCount(instance.plan!.effectiveContextTokens)} Token Kontext sind eingeplant.',
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
              title: const Text(
                'Auch ausgeschaltet im Chat anzeigen',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
              subtitle: const Text(
                'Die Auswahl startet das Modell bei Bedarf automatisch.',
                style: TextStyle(color: Colors.white38, fontSize: 12),
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
                  label: const Text('Stoppen'),
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
                    instance.state == 'failed' ? 'Erneut versuchen' : 'Starten',
                  ),
                ),
              if (instance.isReady)
                OutlinedButton.icon(
                  onPressed: busy ? null : () => onEditSampling(),
                  icon: const Icon(Icons.graphic_eq, size: 17),
                  label: const Text('Antwortverhalten'),
                ),
              if (instance.isReady && instance.plan != null)
                OutlinedButton.icon(
                  key: Key('engine-context-edit-${instance.id}'),
                  onPressed: busy ? null : () => onEditContext(),
                  icon: const Icon(Icons.memory_outlined, size: 17),
                  label: const Text('Kontext'),
                ),
              TextButton.icon(
                key: Key('engine-instance-details-toggle-${instance.id}'),
                onPressed: onToggleExpanded,
                icon: Icon(
                  detailsExpanded ? Icons.expand_less : Icons.expand_more,
                  size: 17,
                ),
                label: Text(detailsExpanded ? 'Weniger' : 'Details'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Widget engineWarningBox(String text) {
  return Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: const Color(0xFFC9A24A).withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.warning_amber, color: Color(0xFFDFC077), size: 17),
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
    return 'Der höhere Kontext von ${formatTokenCount(failedContext)} war nicht stabil. '
        'Aktiv und erfolgreich geprüft: ${formatTokenCount(activeContext)} Token. '
        'Das rechnerische Maximum bleibt über „Kontext“ testbar.';
  }
  return 'Die Engine hat automatisch eine kompatible Ausführung gewählt. Das Modell bleibt nutzbar.';
}

String _instanceStageTitle(EngineInstance instance) {
  switch (instance.state) {
    case 'installing':
      return 'Einmalige Einrichtung läuft';
    case 'queued':
      return 'Start wird vorbereitet';
    case 'starting':
      return 'Modell wird gestartet';
    case 'draining':
      return 'Laufende Anfragen werden abgeschlossen';
    case 'restarting':
      return 'Neue Einstellungen werden angewendet';
    case 'ready':
      return 'Bereit für lokale Anfragen';
    case 'failed':
    case 'failed_rollback':
      return 'Start konnte nicht abgeschlossen werden';
    case 'stopped':
      return 'Derzeit ausgeschaltet';
    default:
      return 'Lokales Modell';
  }
}

String instanceStageDescription(EngineInstance instance) {
  if (instance.detailMessage.trim().isNotEmpty) {
    return instance.detailMessage.trim();
  }
  switch (instance.state) {
    case 'installing':
      return 'PhiloEngine richtet die benötigten Komponenten im Hintergrund ein. Danach startet das Modell automatisch.';
    case 'queued':
      return 'Die sichere Speicheraufteilung ist berechnet. Der Start beginnt automatisch, sobald die Ressourcen bereit sind.';
    case 'starting':
      return 'Das Modell wird geladen und kurz geprüft. Du musst nichts weiter tun.';
    case 'draining':
      return 'Vor dem Wechsel werden laufende Antworten bis zu 30 Sekunden sauber beendet.';
    case 'restarting':
      return 'Die Engine startet das Modell mit dem neuen Plan und prüft es anschließend automatisch.';
    case 'failed':
    case 'failed_rollback':
      return 'Die automatische Einrichtung ist fehlgeschlagen. Du kannst es erneut versuchen; technische Details sind optional verfügbar.';
    default:
      return 'Die Engine arbeitet im Hintergrund.';
  }
}

String friendlyEngineError(String raw) {
  final value = raw.toLowerCase();
  if (value.contains('exit status') || value.contains('exit code')) {
    return 'Eine benötigte Komponente konnte nicht eingerichtet werden. Bitte versuche es erneut.';
  }
  if (value.contains('out of memory') || value.contains('oom')) {
    return 'Der verfügbare Speicher reicht für diesen Plan nicht aus. Die Engine kann beim nächsten Versuch einen kleineren Kontext wählen.';
  }
  if (value.contains('cuda') ||
      value.contains('rocm') ||
      value.contains('vulkan')) {
    return 'Die gewünschte GPU-Ausführung ist nicht verfügbar. Eine kompatible Alternative kann automatisch gewählt werden.';
  }
  return 'Das Modell konnte noch nicht gestartet werden. Bitte versuche es erneut oder öffne die technischen Details.';
}

String instanceErrorMessage(EngineInstance instance) {
  final raw = instance.errorSummary.isNotEmpty
      ? instance.errorSummary
      : (instance.error ?? '');
  final value = raw.toLowerCase();
  // Older persisted failures can still contain the internal planner text.
  // Keep it available in the optional technical details, but never expose it
  // as the user-facing status message.
  if (value.contains('engine plan conflict') ||
      (value.contains('minimum context') && value.contains('maximum is'))) {
    return 'Das Speicherbudget hat sich während der Vorbereitung geändert. GPU und System-RAM werden beim nächsten Versuch neu berechnet.';
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
        const Text(
          'Technische Details',
          style: TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        _detailLine('Lokaler Modellname', instance.id),
        _detailLine(
          'Ausführung',
          runtimeLabel(instance.effectiveConfig.runtime),
        ),
        _detailLine('Kontext', '${formatTokenCount(context)} Token'),
        if (instance.phase.isNotEmpty)
          _detailLine('Interne Phase', instance.phase),
        _detailLine(
          'Priorität',
          _priorityLabel(instance.requestedConfig.priority),
        ),
        _detailLine('Platzierung', _placementLabel(instance.placement)),
        _detailLine('Aktive Anfragen', instance.activeRequests.toString()),
        _detailLine('Ressourcenschutz', _guardLabel(instance.guardState)),
        if (instance.lastUsedAt != null)
          _detailLine(
            'Zuletzt verwendet',
            _formatEngineTime(instance.lastUsedAt!),
          ),
        if (instance.idleExpiresAt != null)
          _detailLine(
            'Automatisches Stoppen',
            _formatEngineTime(instance.idleExpiresAt!),
          ),
        if (instance.fallbacks.isNotEmpty)
          _detailLine(
            'Automatische Anpassung',
            instance.fallbacks.map((item) => item.label).join(' · '),
          ),
        if (instance.restartRequiredFields.isNotEmpty)
          _detailLine(
            'Bei Änderung mit Neustart',
            instance.restartRequiredFields
                .map(_restartFieldLabel)
                .toSet()
                .join(', '),
          ),
        if (instance.error != null && instance.error!.isNotEmpty)
          _detailLine('Fehlerprotokoll', instance.error!),
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
    case 'vllm':
      return 'vLLM';
    case 'transformers':
      return 'Transformers';
    case 'auto':
    case '':
      return 'Automatisch';
    default:
      return runtime;
  }
}

String _priorityLabel(String priority) {
  switch (priority) {
    case 'low':
      return 'Niedrig';
    case 'high':
      return 'Hoch';
    case 'pinned':
      return 'Fest reserviert';
    default:
      return 'Normal';
  }
}

String _placementLabel(String placement) => switch (placement) {
  'gpu' => 'GPU',
  'ram' => 'RAM',
  'hybrid' => 'GPU + RAM',
  _ => 'Noch nicht bekannt',
};

String _guardLabel(String guard) => switch (guard) {
  'warning' => 'Warnung – neue Starts pausiert',
  'critical' => 'Kritisch – Speicher wird freigegeben',
  'emergency' => 'Notfall – Hostschutz aktiv',
  _ => 'Normal',
};

String _formatEngineTime(DateTime value) {
  final local = value.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '${local.day.toString().padLeft(2, '0')}.${local.month.toString().padLeft(2, '0')}.${local.year} $hour:$minute';
}

String _restartFieldLabel(String field) {
  const labels = <String, String>{
    'runtime': 'Ausführung',
    'context_tokens': 'Kontextgröße',
    'gpu_layers': 'GPU-Layer',
    'threads': 'CPU-Threads',
    'tensor_parallel_size': 'GPU-Parallelität',
    'gpu_ids': 'GPU-Auswahl',
    'offload': 'Speicheraufteilung',
    'kv_cache_dtype': 'Kontextspeicherformat',
    'max_sequences': 'parallele Anfragen',
    'trust_remote_code': 'Modellcode-Freigabe',
  };
  return labels[field] ?? field;
}
