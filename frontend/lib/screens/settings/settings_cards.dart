import 'package:flutter/material.dart';

import 'settings_widgets.dart';

// Groessere, aber zustandslose Karten der Einstellungen: System-Infos,
// Hilfe-Hinweis und die Kachel eines einzelnen Skills. Daten und Aktionen
// kommen vom Screen herein.

Widget settingsSystemInfoCard(Map<String, dynamic> systemInfo) {
  final gpu =
      systemInfo['gpu_name'] ?? systemInfo['gpu'] ?? 'Keine GPU erkannt';
  final cpu = systemInfo['cpu_name'] ?? 'CPU wird erkannt …';
  final ram = systemInfo['ram_gb'] ?? systemInfo['ram_mb'] ?? 0;
  final vram = systemInfo['vram_gb'] ?? systemInfo['vram_mb'] ?? 0;
  final disk = systemInfo['disk_free'] ?? 'N/A';
  final source = systemInfo['detection_source']?.toString();

  return Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: const Color(0xFF16161D),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Systeminformationen',
          style: TextStyle(
            color: Colors.white,
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
        settingsSpecRow('DISK FREE', disk.toString()),
        if (source != null && source.isNotEmpty) ...[
          const Divider(color: Colors.white10),
          settingsSpecRow('ERKENNUNG', source),
        ],
      ],
    ),
  );
}

Widget settingsHelpCard() {
  return Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: const Color(0xFF16161D),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hilfe & Dokumentation',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Stellen Sie sicher, dass das myphiloengine Backend läuft, bevor Sie Operationen aufrufen. Standardmäßig lauscht es auf Port 8080.',
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
    '${summary['file_count'] ?? 0} Dateien',
    if (summary['has_scripts'] == true) 'scripts',
    if (summary['has_references'] == true) 'references',
    if (summary['has_assets'] == true) 'assets',
  ];

  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF0F0F12),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: valid
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.redAccent.withValues(alpha: 0.45),
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
              color: valid ? const Color(0xFFC9A24A) : Colors.redAccent,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.isEmpty ? 'Unbekannter Skill' : name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description.isEmpty
                        ? 'Keine Beschreibung verfügbar'
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
              activeThumbColor: const Color(0xFFC9A24A),
              onChanged: valid && name.isNotEmpty
                  ? (value) => onToggle(name, value)
                  : null,
            ),
            IconButton(
              onPressed: name.isNotEmpty ? () => onDelete(name) : null,
              icon: const Icon(Icons.delete_outline, size: 18),
              color: Colors.redAccent,
              tooltip: 'Entfernen',
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            settingsSkillChip(valid ? 'gültig' : 'ungültig', valid),
            ...chips.map((chip) => settingsSkillChip(chip, true)),
          ],
        ),
        if (path.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            path,
            style: const TextStyle(
              color: Colors.white30,
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
                  color: Colors.redAccent,
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
