import 'package:flutter/material.dart';

import '../../core/app_strings.dart';
import './settings_widgets.dart';

String? settingsHardwareDetectionSourceLabel(String? source) {
  final normalized = source?.trim();
  if (normalized == null || normalized.isEmpty) return null;

  switch (normalized.toLowerCase()) {
    case 'culpeostudio_hardware':
    case 'whichllm':
      return tr('settings.systemInfo.source.culpeostudioHardware');
    case 'culpeostudio_hardware+native_live':
    case 'whichllm+native_live':
      return tr('settings.systemInfo.source.culpeostudioHardwareLive');
    case 'native_live':
      return tr('settings.systemInfo.source.nativeLive');
    case 'go_fallback':
      return tr('settings.systemInfo.source.localFallback');
    default:
      return normalized;
  }
}

Widget settingsSystemInfoCard(Map<String, dynamic> systemInfo) {
  final gpu =
      systemInfo['gpu_name'] ??
      systemInfo['gpu'] ??
      tr('settings.systemInfo.noGpu');
  final cpu = systemInfo['cpu_name'] ?? tr('settings.systemInfo.cpuDetecting');
  final ram = systemInfo['ram_gb'] ?? systemInfo['ram_mb'] ?? 0;
  final vram = systemInfo['vram_gb'] ?? systemInfo['vram_mb'] ?? 0;
  final disk = systemInfo['disk_free'] ?? 'N/A';
  final source = settingsHardwareDetectionSourceLabel(
    systemInfo['detection_source']?.toString(),
  );

  return Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: SettingsPalette.surfaceRaised,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: SettingsPalette.hairlineSoft),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          tr('settings.systemInfo.title'),
          style: const TextStyle(
            color: SettingsPalette.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        settingsSpecRow('GPU', gpu.toString()),
        const Divider(color: Colors.white10),
        settingsSpecRow('CPU', cpu.toString()),
        const Divider(color: Colors.white10),
        settingsSpecRow('RAM', '${ram.toString()} GB'),
        const Divider(color: Colors.white10),
        settingsSpecRow('VRAM', '${vram.toString()} GB'),
        const Divider(color: Colors.white10),
        settingsSpecRow(tr('settings.systemInfo.diskFree'), disk.toString()),
        if (source != null && source.isNotEmpty) ...[
          const Divider(color: Colors.white10),
          settingsSpecRow(tr('settings.systemInfo.detection'), source),
        ],
      ],
    ),
  );
}

Widget settingsHelpCard() {
  return Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: SettingsPalette.surfaceRaised,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: SettingsPalette.hairlineSoft),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr('settings.help.title'),
          style: const TextStyle(
            color: SettingsPalette.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          tr('settings.help.body'),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.65),
            fontSize: 12,
            height: 1.4,
          ),
        ),
      ],
    ),
  );
}

Widget settingsSkillTile(
  Map<String, dynamic> skill, {
  required void Function(String name, bool enabled) onToggle,
  required void Function(String name) onDelete,
}) {
  final name = (skill['name'] ?? '').toString();
  final description = (skill['description'] ?? '').toString();
  final path = (skill['path'] ?? '').toString();
  final enabled = skill['enabled'] == true;
  final valid = skill['valid'] != false;
  final errors = skill['errors'] is List
      ? List<dynamic>.from(skill['errors']).map((e) => e.toString()).toList()
      : <String>[];
  final summary = skill['file_summary'] is Map
      ? Map<String, dynamic>.from(skill['file_summary'])
      : <String, dynamic>{};
  final chips = <String>[
    tr('settings.skills.fileCount', {'count': '${summary['file_count'] ?? 0}'}),
    if (summary['has_scripts'] == true) 'scripts',
    if (summary['has_references'] == true) 'references',
    if (summary['has_assets'] == true) 'assets',
  ];

  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: SettingsPalette.surfaceInput,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: valid
            ? SettingsPalette.dividerLine
            : SettingsPalette.danger.withValues(alpha: 0.45),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              valid ? Icons.extension_outlined : Icons.error_outline,
              color: valid ? SettingsPalette.accent : SettingsPalette.danger,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.isEmpty ? tr('settings.skills.unknown') : name,
                    style: const TextStyle(
                      color: SettingsPalette.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description.isEmpty
                        ? tr('settings.skills.noDescription')
                        : description,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: enabled,
              activeThumbColor: SettingsPalette.accent,
              onChanged: valid && name.isNotEmpty
                  ? (value) => onToggle(name, value)
                  : null,
            ),
            IconButton(
              onPressed: name.isNotEmpty ? () => onDelete(name) : null,
              icon: const Icon(Icons.delete_outline, size: 18),
              color: SettingsPalette.danger,
              tooltip: tr('settings.skills.removeTooltip'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            settingsSkillChip(
              valid
                  ? tr('settings.skills.valid')
                  : tr('settings.skills.invalid'),
              valid,
            ),
            ...chips.map((chip) => settingsSkillChip(chip, true)),
          ],
        ),
        if (path.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            path,
            style: const TextStyle(
              color: SettingsPalette.textVeryFaint,
              fontSize: 11,
              fontFamily: 'monospace',
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
        if (errors.isNotEmpty) ...[
          const SizedBox(height: 12),
          ...errors.map(
            (error) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                error,
                style: const TextStyle(
                  color: SettingsPalette.danger,
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
            ),
          ),
        ],
      ],
    ),
  );
}
