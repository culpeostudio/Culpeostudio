import 'package:flutter/material.dart';

import '../../engine/models.dart';
import '../../engine/widgets.dart';
import '../../l10n/app_strings.dart';

Widget wizardStepNav(
  int step,
  String label, {
  required bool enabled,
  bool done = false,
  required int currentStep,
  required void Function(int step) onSelect,
}) {
  final active = currentStep == step;
  final color = done
      ? const Color(0xFF81C784)
      : active
      ? const Color(0xFFEBD9A8)
      : Colors.white38;
  return Expanded(
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        key: Key('engine-wizard-step-${step + 1}'),
        onTap: enabled ? () => onSelect(step) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '0${step + 1}',
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: active ? Colors.white : Colors.white54,
                  fontSize: 11,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget wizardStepDivider() => Container(
  width: 1,
  height: 34,
  color: Colors.white.withValues(alpha: 0.12),
);

Widget gpuRepairProgress(EngineOperation? operation) {
  final detail = operation?.detailMessage.isNotEmpty == true
      ? operation!.detailMessage
      : operation?.message?.isNotEmpty == true
      ? operation!.message!
      : tr('engineWidget.wizard.awaitingAdminConsent');
  final progress = operation?.progress ?? 0;
  return Container(
    key: const Key('engine-gpu-repair-progress'),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: engineBlue.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: engineBlue.withValues(alpha: 0.22)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(
              Icons.build_circle_outlined,
              color: engineAccent,
              size: 18,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                tr('engineWidget.wizard.gpuRepairTitle'),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        LinearProgressIndicator(
          value: progress > 0 ? progress.clamp(0, 1) : null,
          minHeight: 4,
        ),
        const SizedBox(height: 8),
        Text(
          detail,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ],
    ),
  );
}
