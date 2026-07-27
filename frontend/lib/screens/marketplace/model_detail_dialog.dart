import 'package:flutter/material.dart';

import '../../l10n/marketplace_detail_strings.dart';
import 'fit_details_dialog.dart';
import 'marketplace_format.dart';

// Vollstaendiger Detail-Dialog zu einem Modell.

class ModelDetailDialog extends StatelessWidget {
  final Map<String, dynamic> summary;
  final Map<String, dynamic>? detail;
  final Map<String, dynamic> hardwareProfile;
  final ValueChanged<Map<String, dynamic>>? onDownload;

  const ModelDetailDialog({
    super.key,
    required this.summary,
    this.detail,
    this.hardwareProfile = const {},
    this.onDownload,
  });

  String _firstText(List<String> keys, String fallback) {
    for (final key in keys) {
      final value = (summary[key] ?? (detail?[key]))?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return fallback;
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  List<String> _stringList(String key) {
    final raw = summary[key] ?? (detail?[key]);
    if (raw is! List) return const [];
    return raw
        .whereType<Object?>()
        .map((item) => item?.toString() ?? '')
        .where((item) => item.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final name = _firstText([
      'display_name',
      'name',
      'model_id',
    ], tr('marketplaceDetail.model.fallbackName'));
    final modelId = _firstText(['model_id', 'id'], '');
    final provider = (summary['provider'] ?? '').toString();
    final providerBadge =
        (summary['provider_badge'] ?? (detail?['provider_badge']) ?? provider)
            .toString();
    final desc = _firstText([
      'description',
    ], tr('marketplaceDetail.model.noDescription'));
    final tags = _stringList('capability_tags');
    final quantizations = _stringList('quantizations');
    final formats = _stringList('formats');
    final category = (summary['category'] ?? (detail?['category']) ?? '')
        .toString();
    final contextLength = _asInt(
      summary['context_length'] ?? (detail?['context_length']),
    );
    final score = _asInt(
      summary['intelligence_score'] ?? (detail?['intelligence_score']),
    );
    final downloads = _asInt(summary['downloads'] ?? (detail?['downloads']));
    final price = (summary['price_per_1m'] ?? (detail?['price_per_1m']) ?? '-')
        .toString();
    final parameterBadge =
        (summary['parameter_badge'] ?? (detail?['parameter_badge']) ?? '')
            .toString();
    final estimatedVram =
        (summary['estimated_vram_gb'] ?? (detail?['estimated_vram_gb']) ?? 0)
            .toDouble();
    final vramEstimated =
        summary['vram_estimated'] == true || detail?['vram_estimated'] == true;
    final fitsGpu = summary['fits_detected_gpu'] == true;
    final runtimeFit = (summary['runtime_fit'] ?? detail?['runtime_fit'] ?? '')
        .toString();
    final mergedModel = <String, dynamic>{...summary, ...?detail};

    final options =
        summary['download_options'] ?? (detail?['download_options']);
    final optionList = options is List
        ? options
              .whereType<Map>()
              .map((m) => Map<String, dynamic>.from(m))
              .toList()
        : <Map<String, dynamic>>[];

    return Dialog(
      backgroundColor: const Color(0xFF16161D),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 600),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: Colors.white.withValues(alpha: 0.55),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  if (parameterBadge.isNotEmpty) ...[
                    _pill(parameterBadge, Colors.white70),
                    const SizedBox(width: 6),
                  ],
                  _pill(providerBadge, const Color(0xFFC9A24A)),
                  const SizedBox(width: 6),
                  if (category.isNotEmpty) _pill(category, Colors.amberAccent),
                  const SizedBox(width: 6),
                  if (contextLength > 0)
                    _pill(
                      tr('marketplaceDetail.model.contextBadge', {
                        'count': (contextLength / 1000).round().toString(),
                      }),
                      Colors.tealAccent,
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                modelId,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.38),
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                desc,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _metricRow(
                    Icons.payments_outlined,
                    tr('marketplaceDetail.model.price', {'price': price}),
                  ),
                  _metricRow(
                    Icons.psychology_alt_outlined,
                    tr('marketplaceDetail.model.intelligence', {
                      'score': score.toString(),
                    }),
                  ),
                  _metricRow(
                    Icons.trending_up_rounded,
                    tr('marketplaceDetail.model.downloads', {
                      'count': downloads.toString(),
                    }),
                  ),
                  if (estimatedVram > 0)
                    _metricRow(
                      fitsGpu
                          ? Icons.check_circle_outline
                          : runtimeFitIcon(runtimeFit),
                      tr('marketplaceDetail.model.vram', {
                        'prefix': vramEstimated ? '~' : '',
                        'value': estimatedVram.toStringAsFixed(1),
                        'suffix': vramEstimated
                            ? tr('marketplaceDetail.model.vramEstimatedSuffix')
                            : '',
                      }),
                      color: fitsGpu
                          ? Colors.greenAccent
                          : runtimeFitColor(runtimeFit),
                      onTap: () => showFitDetailsDialog(
                        context,
                        modelName: name,
                        model: mergedModel,
                        hardwareProfile: hardwareProfile,
                      ),
                    ),
                  if (runtimeFit.isNotEmpty)
                    _metricRow(
                      runtimeFitIcon(runtimeFit),
                      runtimeFitLabel(runtimeFit),
                      color: runtimeFitColor(runtimeFit),
                      onTap: () => showFitDetailsDialog(
                        context,
                        modelName: name,
                        model: mergedModel,
                        hardwareProfile: hardwareProfile,
                      ),
                    ),
                ],
              ),
              if (tags.isNotEmpty ||
                  quantizations.isNotEmpty ||
                  formats.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  tr('marketplaceDetail.model.tags'),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ...tags.map(_tag),
                    ...quantizations.map(_tag),
                    ...formats.map(_tag),
                  ],
                ),
              ],
              if (optionList.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  tr('marketplaceDetail.model.availableVariants'),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                ...optionList.map((option) {
                  final assetIDs = option['asset_ids'];
                  final shardCount = assetIDs is List ? assetIDs.length : 0;
                  final size = _asInt(option['size_bytes']);
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    onTap: onDownload == null
                        ? null
                        : () => onDownload!(option),
                    leading: const Icon(
                      Icons.file_download_outlined,
                      size: 18,
                      color: Color(0xFFC9A24A),
                    ),
                    title: Text(
                      option['label']?.toString() ??
                          option['format']?.toString() ??
                          tr('marketplaceDetail.model.variantFallback'),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    subtitle: Text(
                      [
                        if (size > 0) formatBytes(size),
                        if (shardCount > 1)
                          tr('marketplaceDetail.model.shardCount', {
                            'count': shardCount.toString(),
                          }),
                        if (size == 0 && shardCount == 0)
                          option['format']?.toString() ?? '',
                      ].where((part) => part.isNotEmpty).join(' · '),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 10,
                      ),
                    ),
                    trailing: onDownload == null
                        ? null
                        : const Icon(
                            Icons.download_rounded,
                            color: Color(0xFFC9A24A),
                            size: 18,
                          ),
                  );
                }),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _pill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _tag(String text) {
    final color = marketplaceTagColor(text);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 10)),
    );
  }

  Widget _metricRow(
    IconData icon,
    String text, {
    Color? color,
    VoidCallback? onTap,
  }) {
    final metricColor = color ?? Colors.white.withValues(alpha: 0.62);
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: color ?? Colors.white.withValues(alpha: 0.55),
          size: 15,
        ),
        const SizedBox(width: 5),
        Text(text, style: TextStyle(color: metricColor, fontSize: 11)),
        if (onTap != null) ...[
          const SizedBox(width: 3),
          Icon(
            Icons.info_outline_rounded,
            color: metricColor.withValues(alpha: 0.55),
            size: 11,
          ),
        ],
      ],
    );
    if (onTap == null) return row;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: row,
    );
  }
}
