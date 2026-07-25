import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import 'models.dart';

const enginePanelColor = Color(0xFF16161D);
const engineInsetColor = Color(0xFF0F0F12);
const engineBlue = Color(0xFFC9A24A);
const engineAccent = Color(0xFFDFC077);

/// Shared accent gradient used for primary actions, icon badges and meters so
/// the whole engine surface reads as one cohesive, modern control panel.
const engineActionGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [engineBlue, engineAccent],
);

/// A compact, data-dense meter for the engine cockpit.  It deliberately
/// shows consumed capacity (rather than free capacity) so it can be read as
/// utilisation at a glance in the monitor rail.
class EngineUsageGauge extends StatelessWidget {
  const EngineUsageGauge({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.detail,
    required this.fraction,
    this.color = engineAccent,
  });

  final IconData icon;
  final String label;
  final String value;
  final String detail;
  final double fraction;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final usage = fraction.clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.065)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: usage,
              minHeight: 5,
              backgroundColor: Colors.white.withValues(alpha: 0.07),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            detail,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

@Preview(
  name: 'Hardware-Auslastung',
  group: 'Engine Cockpit',
  size: Size(340, 150),
)
Widget engineUsageGaugePreview() => MaterialApp(
  theme: ThemeData.dark(useMaterial3: true),
  home: const Scaffold(
    backgroundColor: engineInsetColor,
    body: Padding(
      padding: EdgeInsets.all(16),
      child: EngineUsageGauge(
        icon: Icons.memory_rounded,
        label: 'Arbeitsspeicher',
        value: '62 %',
        detail: '19,8 GB von 32 GB belegt',
        fraction: 0.62,
      ),
    ),
  ),
);

class EnginePanel extends StatelessWidget {
  const EnginePanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A1A23), Color(0xFF131318)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      padding: padding,
      child: child,
    );
  }
}

class EngineSectionTitle extends StatelessWidget {
  const EngineSectionTitle({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 21, color: engineAccent),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle!,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class EngineStatusBadge extends StatelessWidget {
  const EngineStatusBadge({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final presentation = _presentation(status);
    return Semantics(
      label: 'Status: ${presentation.label}',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: presentation.color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: presentation.color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(presentation.icon, size: 13, color: presentation.color),
            const SizedBox(width: 5),
            Text(
              presentation.label,
              style: TextStyle(
                color: presentation.color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  _StatusPresentation _presentation(String raw) {
    switch (raw.toLowerCase()) {
      case 'ready':
      case 'installed':
      case 'available':
      case 'complete':
      case 'completed':
        return const _StatusPresentation(
          'Bereit',
          Color(0xFF4CAF50),
          Icons.check_circle_outline,
        );
      case 'installing':
      case 'installing_packages':
        return const _StatusPresentation(
          'Wird installiert',
          Color(0xFFC9A24A),
          Icons.downloading,
        );
      case 'creating_environment':
        return const _StatusPresentation(
          'Wird eingerichtet',
          Color(0xFFDFC077),
          Icons.settings_suggest_outlined,
        );
      case 'probing':
        return const _StatusPresentation(
          'Wird geprüft',
          Color(0xFFDFC077),
          Icons.fact_check_outlined,
        );
      case 'running':
        return const _StatusPresentation(
          'Läuft',
          Color(0xFFDFC077),
          Icons.sync,
        );
      case 'queued':
        return const _StatusPresentation(
          'Warteschlange',
          Color(0xFFEBD9A8),
          Icons.schedule,
        );
      case 'starting':
        return const _StatusPresentation(
          'Startet',
          Color(0xFFDFC077),
          Icons.play_circle_outline,
        );
      case 'draining':
        return const _StatusPresentation(
          'Wird geleert',
          Color(0xFFDFC077),
          Icons.hourglass_bottom,
        );
      case 'restarting':
        return const _StatusPresentation(
          'Neustart',
          Color(0xFFBA68C8),
          Icons.restart_alt,
        );
      case 'failed':
      case 'failed_rollback':
      case 'error':
        return const _StatusPresentation(
          'Fehlgeschlagen',
          Color(0xFFEF5350),
          Icons.error_outline,
        );
      case 'incomplete':
      case 'invalid':
        return const _StatusPresentation(
          'Unvollständig',
          Color(0xFFFF7043),
          Icons.warning_amber_rounded,
        );
      case 'stopped':
        return const _StatusPresentation(
          'Gestoppt',
          Color(0xFFB0BEC5),
          Icons.stop_circle_outlined,
        );
      case 'missing':
        return const _StatusPresentation(
          'Nicht eingerichtet',
          Color(0xFFB0BEC5),
          Icons.download_for_offline_outlined,
        );
      case 'incompatible':
      case 'unsupported':
        return const _StatusPresentation(
          'Nicht benötigt',
          Color(0xFF90A4AE),
          Icons.do_not_disturb_alt_outlined,
        );
      case 'cancelled':
      case 'canceled':
        return const _StatusPresentation(
          'Abgebrochen',
          Color(0xFFB0BEC5),
          Icons.cancel_outlined,
        );
      default:
        return _StatusPresentation(
          raw.isEmpty ? 'Unbekannt' : raw,
          Colors.white54,
          Icons.help_outline,
        );
    }
  }
}

class EnginePlacementBadge extends StatelessWidget {
  const EnginePlacementBadge({
    super.key,
    required this.placement,
    this.planned = false,
  });

  final String placement;
  final bool planned;

  @override
  Widget build(BuildContext context) {
    final label = switch (placement) {
      'gpu' => 'GPU',
      'ram' => 'RAM',
      'hybrid' => 'GPU + RAM',
      _ => 'Nicht geplant',
    };
    return Tooltip(
      message: planned
          ? 'Aus dem Engine-Speicherplan'
          : 'Aktuelle Speicherplatzierung',
      child: Container(
        key: const Key('engine-placement-badge'),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: engineBlue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: engineBlue.withValues(alpha: 0.24)),
        ),
        child: Text(
          planned ? 'Geplant: $label' : label,
          style: const TextStyle(
            color: Color(0xFFEBD9A8),
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class EngineGuardBadge extends StatelessWidget {
  const EngineGuardBadge({super.key, required this.state});

  final String state;

  @override
  Widget build(BuildContext context) {
    if (state == 'normal' || state.isEmpty) return const SizedBox.shrink();
    final (label, color, icon) = switch (state) {
      'warning' => (
        'Speicherwarnung',
        const Color(0xFFDFC077),
        Icons.warning_amber,
      ),
      'critical' => (
        'Speicher kritisch',
        const Color(0xFFFF7043),
        Icons.memory,
      ),
      'emergency' => (
        'Notfallschutz aktiv',
        const Color(0xFFEF5350),
        Icons.health_and_safety_outlined,
      ),
      _ => ('Ressourcenschutz', Colors.white60, Icons.shield_outlined),
    };
    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.28)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPresentation {
  const _StatusPresentation(this.label, this.color, this.icon);

  final String label;
  final Color color;
  final IconData icon;
}

class EngineContextBar extends StatelessWidget {
  const EngineContextBar({super.key, required this.plan, this.compact = false});

  final ContextPlan plan;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ramAddsContext =
        plan.hybridMaxContextTokens > plan.gpuOnlyMaxContextTokens;
    final gpuReachesModelLimit =
        plan.modelContextLimitTokens > 0 &&
        plan.gpuOnlyMaxContextTokens >= plan.modelContextLimitTokens;
    final hardLimit = math.max(
      1,
      math.max(plan.modelContextLimitTokens, plan.hybridMaxContextTokens),
    );
    final gpuFraction = (plan.gpuOnlyMaxContextTokens / hardLimit).clamp(
      0.0,
      1.0,
    );
    final hybridFraction = (plan.hybridMaxContextTokens / hardLimit).clamp(
      0.0,
      1.0,
    );
    final effectiveFraction = (plan.effectiveContextTokens / hardLimit).clamp(
      0.0,
      1.0,
    );
    final effectiveLabel = compact ? 'Aktiv & geprüft' : 'Geplant';

    return Semantics(
      label: ramAddsContext
          ? 'Kontextplan: ohne zusätzlichen RAM geschätzt ${plan.gpuOnlyMaxContextTokens}, $effectiveLabel ${plan.effectiveContextTokens}, GPU und RAM geschätzt ${plan.hybridMaxContextTokens}, Modellgrenze ${plan.modelContextLimitTokens} Token'
          : gpuReachesModelLimit
          ? 'Kontextplan: ohne zusätzlichen RAM geschätzt ${plan.gpuOnlyMaxContextTokens}, $effectiveLabel ${plan.effectiveContextTokens}; die Modellgrenze von ${plan.modelContextLimitTokens} Token ist bereits erreicht'
          : 'Kontextplan: ohne zusätzlichen RAM geschätzt ${plan.gpuOnlyMaxContextTokens}, $effectiveLabel ${plan.effectiveContextTokens}; RAM bringt aktuell keinen zusätzlichen Kontext, Modellgrenze ${plan.modelContextLimitTokens} Token',
      child: Column(
        key: const Key('context-plan-bar'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              return SizedBox(
                height: 18,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                    ),
                    if (ramAddsContext)
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        width: width * hybridFraction,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFC9A24A,
                            ).withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(9),
                          ),
                        ),
                      ),
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: width * gpuFraction,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: engineBlue.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                    ),
                    Positioned(
                      left: (width * effectiveFraction - 1).clamp(0, width - 2),
                      top: -3,
                      bottom: -3,
                      child: Container(width: 2, color: Colors.white),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: compact ? 10 : 16,
            runSpacing: 7,
            children: [
              _Legend(
                color: engineBlue,
                label:
                    'Ohne extra RAM (Schätzung): ${formatTokenCount(plan.gpuOnlyMaxContextTokens)}',
              ),
              _Legend(
                color: Colors.white,
                label:
                    '$effectiveLabel: ${formatTokenCount(plan.effectiveContextTokens)}',
              ),
              if (ramAddsContext)
                _Legend(
                  key: const Key('context-plan-ram-extension'),
                  color: const Color(0xFFC9A24A),
                  label:
                      'GPU + RAM (Schätzung): ${formatTokenCount(plan.hybridMaxContextTokens)}',
                )
              else
                _Legend(
                  key: const Key('context-plan-no-ram-gain'),
                  color: gpuReachesModelLimit ? engineAccent : Colors.white38,
                  label: gpuReachesModelLimit
                      ? 'Modelllimit bereits vollständig auf GPU'
                      : 'RAM bringt aktuell keinen zusätzlichen Kontext',
                ),
              _Legend(
                color: Colors.white38,
                label:
                    'Modellgrenze: ${formatTokenCount(plan.modelContextLimitTokens)}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Explains the plan in user terms and keeps the technical evidence behind an
/// ordinary dropdown. This makes the distinction between a hard model limit,
/// GPU capacity and optional RAM explicit before any system change happens.
class EnginePreflightCard extends StatelessWidget {
  const EnginePreflightCard({super.key, required this.plan});

  final ContextPlan plan;

  @override
  Widget build(BuildContext context) {
    final ramAddsContext =
        plan.hybridMaxContextTokens > plan.gpuOnlyMaxContextTokens;
    final gpuAtHardLimit =
        plan.modelContextLimitTokens > 0 &&
        plan.gpuOnlyMaxContextTokens >= plan.modelContextLimitTokens;
    final cpuOnly = plan.memory.gpuBytes <= 0 && plan.memory.ramBytes > 0;
    final headline = cpuOnly
        ? 'Der Plan benötigt System-RAM; die GPU wird dafür nicht verwendet.'
        : ramAddsContext
        ? 'Rechnerisch kann System-RAM den Kontext von ${formatTokenCount(plan.gpuOnlyMaxContextTokens)} auf bis zu ${formatTokenCount(plan.hybridMaxContextTokens)} erweitern. Der echte Start prüft diesen Schätzwert.'
        : gpuAtHardLimit
        ? 'Die GPU erreicht bereits das feste Modelllimit von ${formatTokenCount(plan.modelContextLimitTokens)}.'
        : 'System-RAM bringt für diesen Plan keinen zusätzlichen Kontext.';
    final speedHint = cpuOnly
        ? 'CPU/RAM ist nutzbar, aber meist deutlich langsamer als GPU-Ausführung.'
        : plan.usesRam
        ? 'Der RAM-Anteil spart VRAM, kann Antworten aber langsamer machen.'
        : 'GPU-only ist die schnellste Speicheraufteilung für diesen Plan.';
    final metadataEstimated = plan.preflight.metadataConfidence == 'estimated';

    return Container(
      key: const Key('engine-preflight-card'),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.fact_check_outlined,
                  color: engineAccent,
                  size: 18,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Start-Check',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _PreflightPill(
                  label: metadataEstimated
                      ? 'Metadaten geschätzt'
                      : 'Metadaten geprüft',
                  color: metadataEstimated
                      ? engineAccent
                      : const Color(0xFF76C893),
                ),
              ],
            ),
            const SizedBox(height: 9),
            Text(
              headline,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              speedHint,
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
            ExpansionTile(
              key: const Key('engine-preflight-details'),
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(bottom: 4),
              iconColor: engineAccent,
              collapsedIconColor: Colors.white54,
              title: const Text(
                'Warum dieser Plan sicher ist',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              children: [
                _preflightLine(
                  'Gewichte',
                  formatBytes(plan.memory.weightsBytes),
                ),
                _preflightLine(
                  'Kontextspeicher',
                  formatBytes(plan.memory.kvCacheBytes),
                ),
                _preflightLine(
                  'Runtime-Reserve',
                  formatBytes(plan.memory.runtimeBytes),
                ),
                if (plan.preflight.hardwareSnapshotId.isNotEmpty)
                  _preflightLine(
                    'Hardware-Snapshot',
                    plan.preflight.hardwareSnapshotId,
                  ),
                if (plan.preflight.checks.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  for (final check in plan.preflight.checks)
                    _PreflightCheckLine(check: check),
                ] else
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      'Vor dem Workerstart werden Hardware, Cache-Modus und eine lokale Modellantwort nochmals geprüft.',
                      style: TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _preflightLine(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ),
        Text(
          value,
          style: const TextStyle(color: Colors.white60, fontSize: 11),
        ),
      ],
    ),
  );
}

class _PreflightPill extends StatelessWidget {
  const _PreflightPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.13),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700),
    ),
  );
}

class _PreflightCheckLine extends StatelessWidget {
  const _PreflightCheckLine({required this.check});

  final PreflightCheck check;

  @override
  Widget build(BuildContext context) {
    final passed = check.state == 'passed';
    final color = passed ? const Color(0xFF76C893) : engineAccent;
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            passed ? Icons.check_circle_outline : Icons.schedule_outlined,
            color: color,
            size: 14,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              check.detail.isEmpty
                  ? check.label
                  : '${check.label}: ${check.detail}',
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({super.key, required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 10),
        ),
      ],
    );
  }
}

String formatBytes(int bytes) {
  if (bytes <= 0) return '0 B';
  const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
  var value = bytes.toDouble();
  var index = 0;
  while (value >= 1024 && index < suffixes.length - 1) {
    value /= 1024;
    index++;
  }
  return '${value.toStringAsFixed(index == 0 ? 0 : 1)} ${suffixes[index]}';
}

String formatTokenCount(int tokens) {
  if (tokens >= 1000000) {
    return '${(tokens / 1000000).toStringAsFixed(tokens % 1000000 == 0 ? 0 : 1)}M';
  }
  if (tokens >= 1000) {
    return '${(tokens / 1000).toStringAsFixed(tokens % 1000 == 0 ? 0 : 1)}k';
  }
  return tokens.toString();
}
