import 'package:flutter/material.dart';

// Dialog mit der Detail-Aufschluesselung, ob ein Modell auf die Hardware passt.

// Gemeinsamer Tap-Dialog fuer die GPU/RAM-Aufschluesselung eines Modells.
// Wird sowohl von der Karten-Ansicht (_MarketplaceScreenState) als auch vom
// ModelDetailDialog aufgerufen, damit "auf das Fit-Badge tippen" ueberall
// dieselbe Erweiterung mit RAM-Info zeigt.
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
      backgroundColor: const Color(0xFF16161D),
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
              '${vramEstimated ? "Geschätzter" : "Ermittelter"} Speicherbedarf: '
              '~${estimatedVram.toStringAsFixed(1)} GB',
              style: const TextStyle(color: Colors.white70, fontSize: 12.5),
            ),
          if (fit == 'partial_offload') ...[
            const SizedBox(height: 6),
            Text(
              '• ${gpuPortionGb.toStringAsFixed(1)} GB auf der GPU',
              style: const TextStyle(color: Colors.white70, fontSize: 12.5),
            ),
            Text(
              '• ${ramOffloadGb.toStringAsFixed(1)} GB im Arbeitsspeicher (RAM)',
              style: const TextStyle(color: Colors.white70, fontSize: 12.5),
            ),
          ] else if (fit == 'cpu_only' && estimatedVram > 0) ...[
            const SizedBox(height: 6),
            Text(
              '• Läuft komplett über den Arbeitsspeicher (RAM), ohne GPU-Beschleunigung',
              style: const TextStyle(color: Colors.white70, fontSize: 12.5),
            ),
          ] else if (fit == 'unknown') ...[
            const SizedBox(height: 6),
            Text(
              'Für dieses Modell liegen keine Größen- oder Quantisierungs-'
              'daten vor, aus denen sich der Bedarf schätzen lässt.',
              style: const TextStyle(color: Colors.white70, fontSize: 12.5),
            ),
          ],
          const Divider(color: Colors.white24, height: 22),
          Text(
            'DEINE HARDWARE',
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
                ? '${gpuName.isEmpty ? "GPU erkannt" : gpuName} · ${gpuVram.toStringAsFixed(0)} GB VRAM'
                : 'Keine GPU erkannt',
            style: const TextStyle(color: Colors.white70, fontSize: 12.5),
          ),
          Text(
            '${totalRam.toStringAsFixed(0)} GB Arbeitsspeicher (RAM)',
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
          child: const Text('Schließen'),
        ),
      ],
    ),
  );
}

// runtimeFitLabel/Icon/Color sind bewusst top-level statt Methoden auf
// _MarketplaceScreenState: sowohl die Karten-Ansicht als auch der separate
// ModelDetailDialog (StatelessWidget ohne Zugriff auf den State) brauchen
// dieselbe Zuordnung von runtime_fit -> Text/Icon/Farbe, u.a. fuer den
// Tap-Dialog mit der GPU/RAM-Aufschluesselung.
String runtimeFitLabel(String fit) {
  switch (fit) {
    case 'full_gpu':
      return 'Passt komplett auf GPU';
    case 'partial_offload':
      return 'GPU + Arbeitsspeicher';
    case 'cpu_only':
      return 'Nur CPU (langsamer)';
    case 'unsupported':
      return 'Passt auf diesem Gerät nicht';
    case 'unknown':
      return 'Kompatibilität unbekannt';
    default:
      return 'Kompatibilität unbekannt';
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

// partial_offload (GPU+RAM) ist ein bewusst waermerer, aber nicht
// warnungsfarbener Ton: es ist eine funktionierende Konfiguration, kein
// Problemzustand -- vorher teilte es sich orangeAccent mit "passt nicht
// vollstaendig", was wie ein Fehler statt einer echten Option aussah.
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
