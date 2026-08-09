import 'package:flutter/material.dart';

import '../../core/design_tokens.dart';

import './marketplace_detail_strings.dart';

void showFitDetailsDialog(
  BuildContext context, {
  required String modelName,
  required Map<String, dynamic> model,
  required Map<String, dynamic> hardwareProfile,
}) {
  double asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  final estimatedVram = asDouble(model['estimated_vram_gb']);
  final vramEstimated = model['vram_estimated'] == true;
  final fit = model['runtime_fit']?.toString() ?? '';
  final ramOffloadGb = asDouble(model['runtime_ram_offload_gb']);
  final warnings =
      (model['runtime_warnings'] as List?)
          ?.map((w) => w?.toString() ?? '')
          .where((w) => w.isNotEmpty)
          .toList() ??
      const <String>[];

  final hasGpu = hardwareProfile['has_gpu'] == true;
  final gpuName = (hardwareProfile['gpu_name'] ?? hardwareProfile['gpu'] ?? '')
      .toString();
  final gpuVram = asDouble(hardwareProfile['vram_gb']);
  final totalRam = asDouble(hardwareProfile['ram_gb']);
  final gpuPortionGb = (estimatedVram - ramOffloadGb).clamp(0, estimatedVram);

  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: CulpeoColors.panel,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(
        modelName,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(runtimeFitIcon(fit), color: runtimeFitColor(fit), size: 16),
              const SizedBox(width: 6),
              Text(
                runtimeFitLabel(fit),
                style: TextStyle(
                  color: runtimeFitColor(fit),
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (estimatedVram > 0)
            Text(
              tr(
                vramEstimated
                    ? 'marketplaceDetail.fit.memoryEstimated'
                    : 'marketplaceDetail.fit.memoryMeasured',
                {'value': estimatedVram.toStringAsFixed(1)},
              ),
              style: const TextStyle(color: Colors.white70, fontSize: 12.5),
            ),
          if (fit == 'partial_offload') ...[
            const SizedBox(height: 6),
            Text(
              tr('marketplaceDetail.fit.gpuPortion', {
                'value': gpuPortionGb.toStringAsFixed(1),
              }),
              style: const TextStyle(color: Colors.white70, fontSize: 12.5),
            ),
            Text(
              tr('marketplaceDetail.fit.ramPortion', {
                'value': ramOffloadGb.toStringAsFixed(1),
              }),
              style: const TextStyle(color: Colors.white70, fontSize: 12.5),
            ),
          ] else if (fit == 'cpu_only' && estimatedVram > 0) ...[
            const SizedBox(height: 6),
            Text(
              tr('marketplaceDetail.fit.cpuOnly'),
              style: const TextStyle(color: Colors.white70, fontSize: 12.5),
            ),
          ] else if (fit == 'unknown') ...[
            const SizedBox(height: 6),
            Text(
              tr('marketplaceDetail.fit.unknownRequirement'),
              style: const TextStyle(color: Colors.white70, fontSize: 12.5),
            ),
          ],
          const Divider(color: Colors.white24, height: 22),
          Text(
            tr('marketplaceDetail.fit.hardwareTitle'),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            hasGpu
                ? tr('marketplaceDetail.fit.gpuSummary', {
                    'gpu': gpuName.isEmpty
                        ? tr('marketplaceDetail.fit.gpuDetected')
                        : gpuName,
                    'vram': gpuVram.toStringAsFixed(0),
                  })
                : tr('marketplaceDetail.fit.noGpu'),
            style: const TextStyle(color: Colors.white70, fontSize: 12.5),
          ),
          Text(
            tr('marketplaceDetail.fit.ramSummary', {
              'ram': totalRam.toStringAsFixed(0),
            }),
            style: const TextStyle(color: Colors.white70, fontSize: 12.5),
          ),
          if (warnings.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...warnings.map(
              (w) => Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '⚠ $w',
                  style: const TextStyle(
                    color: Colors.orangeAccent,
                    fontSize: 11.5,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(tr('common.close')),
        ),
      ],
    ),
  );
}

String runtimeFitLabel(String fit) {
  switch (fit) {
    case 'full_gpu':
      return tr('marketplaceDetail.fit.fullGpu');
    case 'partial_offload':
      return tr('marketplaceDetail.fit.partialOffload');
    case 'cpu_only':
      return tr('marketplaceDetail.fit.cpuOnlyLabel');
    case 'unsupported':
      return tr('marketplaceDetail.fit.unsupported');
    case 'unknown':
      return tr('marketplaceDetail.fit.unknown');
    default:
      return tr('marketplaceDetail.fit.unknown');
  }
}

IconData runtimeFitIcon(String fit) {
  switch (fit) {
    case 'full_gpu':
      return Icons.verified_rounded;
    case 'partial_offload':
      return Icons.memory_rounded;
    case 'cpu_only':
      return Icons.speed_rounded;
    case 'unsupported':
      return Icons.block_rounded;
    case 'unknown':
      return Icons.help_outline_rounded;
    default:
      return Icons.help_outline_rounded;
  }
}

Color runtimeFitColor(String fit) {
  switch (fit) {
    case 'full_gpu':
      return Colors.greenAccent;
    case 'partial_offload':
      return Colors.lightBlueAccent;
    case 'cpu_only':
      return Colors.amberAccent;
    case 'unsupported':
      return Colors.redAccent;
    case 'unknown':
      return Colors.white60;
    default:
      return Colors.white60;
  }
}
