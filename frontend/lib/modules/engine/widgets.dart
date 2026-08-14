import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../../core/app_strings.dart';
import '../../core/design_tokens.dart';
import './models.dart';

// The engine module's names for the shared tokens. Rust acts, gold measures:
// engineAction marks what the user can do, engineMetric what the engine
// measured. Keeping the two apart is why a context length never looks like a
// button.
const enginePanelColor = CulpeoColors.panel;
const engineInsetColor = CulpeoColors.inset;
const engineAction = CulpeoColors.action;
const engineMetric = CulpeoColors.metric;
const engineAccent = CulpeoColors.metricBright;

/// Kept under the old name because several call sites read it as "the metric
/// tone"; it is the same gold, now sourced from the tokens.
const engineBlue = CulpeoColors.metric;

const engineActionGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [CulpeoColors.action, CulpeoColors.actionHover],
);

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
  home: Scaffold(
    backgroundColor: engineInsetColor,
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: EngineUsageGauge(
        icon: Icons.memory_rounded,
        label: tr('engineWidget.preview.memoryLabel'),
        value: '62 %',
        detail: tr('engineWidget.preview.memoryDetail'),
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

/// Marks a model or an instance as belonging to another machine.
///
/// It is rust rather than gold: which machine runs a model is something the
/// user chose, not something the engine measured.
class EngineNodeBadge extends StatelessWidget {
  const EngineNodeBadge({super.key, required this.nodeName});

  final String nodeName;

  @override
  Widget build(BuildContext context) {
    final label = nodeName.trim().isEmpty ? 'Node' : nodeName.trim();
    return Semantics(
      label: tr('engineWidget.node.badge', {'name': label}),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: CulpeoColors.actionMuted,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: CulpeoColors.actionBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.hub_outlined,
              size: 11,
              color: CulpeoColors.action,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                color: CulpeoColors.action,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
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
      label: tr('engineWidget.status', {'label': presentation.label}),
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
        return _StatusPresentation(
          tr('engineWidget.status.ready'),
          Color(0xFF4CAF50),
          Icons.check_circle_outline,
        );
      case 'installing':
      case 'installing_packages':
        return _StatusPresentation(
          tr('engineWidget.status.installing'),
          CulpeoColors.metric,
          Icons.downloading,
        );
      case 'creating_environment':
        return _StatusPresentation(
          tr('engineWidget.status.creatingEnvironment'),
          CulpeoColors.metricBright,
          Icons.settings_suggest_outlined,
        );
      case 'probing':
        return _StatusPresentation(
          tr('engineWidget.status.probing'),
          CulpeoColors.metricBright,
          Icons.fact_check_outlined,
        );
      case 'running':
        return _StatusPresentation(
          tr('engineWidget.status.running'),
          CulpeoColors.metricBright,
          Icons.sync,
        );
      case 'queued':
        return _StatusPresentation(
          tr('engineWidget.status.queued'),
          Color(0xFFEBD9A8),
          Icons.schedule,
        );
      case 'starting':
        return _StatusPresentation(
          tr('engineWidget.status.starting'),
          CulpeoColors.metricBright,
          Icons.play_circle_outline,
        );
      case 'draining':
        return _StatusPresentation(
          tr('engineWidget.status.draining'),
          CulpeoColors.metricBright,
          Icons.hourglass_bottom,
        );
      case 'restarting':
        return _StatusPresentation(
          tr('engineWidget.status.restarting'),
          Color(0xFFBA68C8),
          Icons.restart_alt,
        );
      case 'failed':
      case 'failed_rollback':
      case 'error':
        return _StatusPresentation(
          tr('engineWidget.status.failed'),
          Color(0xFFEF5350),
          Icons.error_outline,
        );
      case 'incomplete':
      case 'invalid':
        return _StatusPresentation(
          tr('engineWidget.status.incomplete'),
          Color(0xFFFF7043),
          Icons.warning_amber_rounded,
        );
      case 'stopped':
        return _StatusPresentation(
          tr('engineWidget.status.stopped'),
          Color(0xFFB0BEC5),
          Icons.stop_circle_outlined,
        );
      case 'missing':
        return _StatusPresentation(
          tr('engineWidget.status.missing'),
          Color(0xFFB0BEC5),
          Icons.download_for_offline_outlined,
        );
      case 'incompatible':
      case 'unsupported':
        return _StatusPresentation(
          tr('engineWidget.status.notNeeded'),
          Color(0xFF90A4AE),
          Icons.do_not_disturb_alt_outlined,
        );
      case 'cancelled':
      case 'canceled':
        return _StatusPresentation(
          tr('engineWidget.status.cancelled'),
          Color(0xFFB0BEC5),
          Icons.cancel_outlined,
        );
      default:
        return _StatusPresentation(
          raw.isEmpty ? tr('engineWidget.status.unknown') : raw,
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
      _ => tr('engineWidget.placement.notPlanned'),
    };
    return Tooltip(
      message: planned
          ? tr('engineWidget.placement.planTooltip')
          : tr('engineWidget.placement.currentTooltip'),
      child: Container(
        key: const Key('engine-placement-badge'),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: engineBlue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: engineBlue.withValues(alpha: 0.24)),
        ),
        child: Text(
          planned
              ? tr('engineWidget.placement.planned', {'label': label})
              : label,
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
        tr('engineWidget.guard.warning'),
        CulpeoColors.metricBright,
        Icons.warning_amber,
      ),
      'critical' => (
        tr('engineWidget.guard.critical'),
        const Color(0xFFFF7043),
        Icons.memory,
      ),
      'emergency' => (
        tr('engineWidget.guard.emergency'),
        const Color(0xFFEF5350),
        Icons.health_and_safety_outlined,
      ),
      _ => (
        tr('engineWidget.guard.protection'),
        Colors.white60,
        Icons.shield_outlined,
      ),
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
    final effectiveLabel = compact
        ? tr('engineWidget.context.activeChecked')
        : tr('engineWidget.context.planned');

    return Semantics(
      label: ramAddsContext
          ? tr('engineWidget.context.semanticWithRam', {
              'gpu': '${plan.gpuOnlyMaxContextTokens}',
              'effectiveLabel': effectiveLabel,
              'effective': '${plan.effectiveContextTokens}',
              'hybrid': '${plan.hybridMaxContextTokens}',
              'limit': '${plan.modelContextLimitTokens}',
            })
          : gpuReachesModelLimit
          ? tr('engineWidget.context.semanticAtLimit', {
              'gpu': '${plan.gpuOnlyMaxContextTokens}',
              'effectiveLabel': effectiveLabel,
              'effective': '${plan.effectiveContextTokens}',
              'limit': '${plan.modelContextLimitTokens}',
            })
          : tr('engineWidget.context.semanticNoRamGain', {
              'gpu': '${plan.gpuOnlyMaxContextTokens}',
              'effectiveLabel': effectiveLabel,
              'effective': '${plan.effectiveContextTokens}',
              'limit': '${plan.modelContextLimitTokens}',
            }),
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
                            color: CulpeoColors.metric.withValues(alpha: 0.35),
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
                label: tr('engineWidget.context.gpuEstimate', {
                  'tokens': formatTokenCount(plan.gpuOnlyMaxContextTokens),
                }),
              ),
              _Legend(
                color: Colors.white,
                label: tr('engineWidget.context.effective', {
                  'label': effectiveLabel,
                  'tokens': formatTokenCount(plan.effectiveContextTokens),
                }),
              ),
              if (ramAddsContext)
                _Legend(
                  key: const Key('context-plan-ram-extension'),
                  color: CulpeoColors.metric,
                  label: tr('engineWidget.context.hybridEstimate', {
                    'tokens': formatTokenCount(plan.hybridMaxContextTokens),
                  }),
                )
              else
                _Legend(
                  key: const Key('context-plan-no-ram-gain'),
                  color: gpuReachesModelLimit ? engineAccent : Colors.white38,
                  label: gpuReachesModelLimit
                      ? tr('engineWidget.context.modelLimitOnGpu')
                      : tr('engineWidget.context.noRamGain'),
                ),
              _Legend(
                color: Colors.white38,
                label: tr('engineWidget.context.modelLimit', {
                  'tokens': formatTokenCount(plan.modelContextLimitTokens),
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

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
        ? tr('engineWidget.preflight.cpuOnly')
        : ramAddsContext
        ? tr('engineWidget.preflight.ramExpands', {
            'gpu': formatTokenCount(plan.gpuOnlyMaxContextTokens),
            'hybrid': formatTokenCount(plan.hybridMaxContextTokens),
          })
        : gpuAtHardLimit
        ? tr('engineWidget.preflight.gpuAtLimit', {
            'limit': formatTokenCount(plan.modelContextLimitTokens),
          })
        : tr('engineWidget.preflight.noRamGain');
    final speedHint = cpuOnly
        ? tr('engineWidget.preflight.cpuSpeed')
        : plan.usesRam
        ? tr('engineWidget.preflight.ramSpeed')
        : tr('engineWidget.preflight.gpuSpeed');
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
                Expanded(
                  child: Text(
                    tr('engineWidget.preflight.title'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _PreflightPill(
                  label: metadataEstimated
                      ? tr('engineWidget.preflight.metadataEstimated')
                      : tr('engineWidget.preflight.metadataVerified'),
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
              title: Text(
                tr('engineWidget.preflight.whySafe'),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              children: [
                _preflightLine(
                  tr('engineWidget.preflight.weights'),
                  formatBytes(plan.memory.weightsBytes),
                ),
                _preflightLine(
                  tr('engineWidget.preflight.contextMemory'),
                  formatBytes(plan.memory.kvCacheBytes),
                ),
                _preflightLine(
                  tr('engineWidget.preflight.runtimeReserve'),
                  formatBytes(plan.memory.runtimeBytes),
                ),
                if (plan.preflight.hardwareSnapshotId.isNotEmpty)
                  _preflightLine(
                    tr('engineWidget.preflight.hardwareSnapshot'),
                    plan.preflight.hardwareSnapshotId,
                  ),
                if (plan.preflight.checks.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  for (final check in plan.preflight.checks)
                    _PreflightCheckLine(check: check),
                ] else
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      tr('engineWidget.preflight.noChecks'),
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
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
