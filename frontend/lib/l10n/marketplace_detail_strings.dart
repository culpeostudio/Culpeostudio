import 'app_strings.dart' as base;

/// Isolated translations for Marketplace detail views and helper widgets.
///
/// Existing application-wide keys remain available through the fallback so the
/// Marketplace migration does not need to modify the established string maps.
const Map<String, String> marketplaceDetailStringsDe = {
  // Hardware fit details
  'marketplaceDetail.fit.memoryEstimated':
      'Geschätzter Speicherbedarf: ~{value} GB',
  'marketplaceDetail.fit.memoryMeasured':
      'Ermittelter Speicherbedarf: ~{value} GB',
  'marketplaceDetail.fit.gpuPortion': '• {value} GB auf der GPU',
  'marketplaceDetail.fit.ramPortion': '• {value} GB im Arbeitsspeicher (RAM)',
  'marketplaceDetail.fit.cpuOnly':
      '• Läuft komplett über den Arbeitsspeicher (RAM), ohne GPU-Beschleunigung',
  'marketplaceDetail.fit.unknownRequirement':
      'Für dieses Modell liegen keine Größen- oder Quantisierungsdaten vor, aus denen sich der Bedarf schätzen lässt.',
  'marketplaceDetail.fit.hardwareTitle': 'DEINE HARDWARE',
  'marketplaceDetail.fit.gpuDetected': 'GPU erkannt',
  'marketplaceDetail.fit.gpuSummary': '{gpu} · {vram} GB VRAM',
  'marketplaceDetail.fit.noGpu': 'Keine GPU erkannt',
  'marketplaceDetail.fit.ramSummary': '{ram} GB Arbeitsspeicher (RAM)',
  'marketplaceDetail.fit.fullGpu': 'Passt komplett auf GPU',
  'marketplaceDetail.fit.partialOffload': 'GPU + Arbeitsspeicher',
  'marketplaceDetail.fit.cpuOnlyLabel': 'Nur CPU (langsamer)',
  'marketplaceDetail.fit.unsupported': 'Passt auf diesem Gerät nicht',
  'marketplaceDetail.fit.unknown': 'Kompatibilität unbekannt',

  // Model detail dialog
  'marketplaceDetail.model.fallbackName': 'Modell',
  'marketplaceDetail.model.noDescription': 'Keine Beschreibung verfügbar.',
  'marketplaceDetail.model.contextBadge': '{count}K Kontext',
  'marketplaceDetail.model.price': 'Preis: {price}',
  'marketplaceDetail.model.intelligence': 'IQ {score}',
  'marketplaceDetail.model.downloads': '{count} Hits',
  'marketplaceDetail.model.vram': '{prefix}{value} GB VRAM{suffix}',
  'marketplaceDetail.model.vramEstimatedSuffix': ' (geschätzt)',
  'marketplaceDetail.model.tags': 'Tags',
  'marketplaceDetail.model.availableVariants': 'Verfügbare Varianten',
  'marketplaceDetail.model.variantFallback': 'Variante',
  'marketplaceDetail.model.shardCount': '{count} zusammengehörende Dateien',

  // Filter preview and recommendation explanations
  'marketplaceDetail.filter.category': 'Kategorie',
  'marketplaceDetail.filter.chat': 'Chat',
  'marketplaceDetail.filter.code': 'Code',
  'marketplaceDetail.filter.reasoning': 'Reasoning',
  'marketplaceDetail.filter.vision': 'Vision',
  'marketplaceDetail.filter.localOnly': 'Nur lokal',
  'marketplaceDetail.recommendation.balanced':
      'Q4_K_M / Q4_0 ist für die meisten Nutzer der beste Kompromiss: ca. 50 % der Originalgröße, aber fast volle Qualität. Läuft auf fast jeder Hardware.',
  'marketplaceDetail.recommendation.maxQuality':
      'FP16 / Q8 / Q5_0 behalten fast 100 % der Originalqualität, brauchen aber 2–3× mehr Speicher/RAM. Nur für starke GPUs (24 GB+ VRAM) sinnvoll.',
  'marketplaceDetail.recommendation.compact':
      'Q2 / Q3 / Q5_K_S sind sehr klein (30–40 % Größe), aber die Ausgabequalität leidet deutlich. Nur wenn Speicher ganz knapp ist.',
  'marketplaceDetail.recommendation.unavailable': 'Keine Empfehlung verfügbar.',
};

const Map<String, String> marketplaceDetailStringsEn = {
  // Hardware fit details
  'marketplaceDetail.fit.memoryEstimated':
      'Estimated memory requirement: ~{value} GB',
  'marketplaceDetail.fit.memoryMeasured':
      'Measured memory requirement: ~{value} GB',
  'marketplaceDetail.fit.gpuPortion': '• {value} GB on the GPU',
  'marketplaceDetail.fit.ramPortion': '• {value} GB in system memory (RAM)',
  'marketplaceDetail.fit.cpuOnly':
      '• Runs entirely in system memory (RAM), without GPU acceleration',
  'marketplaceDetail.fit.unknownRequirement':
      'No size or quantization data is available to estimate this model’s requirements.',
  'marketplaceDetail.fit.hardwareTitle': 'YOUR HARDWARE',
  'marketplaceDetail.fit.gpuDetected': 'GPU detected',
  'marketplaceDetail.fit.gpuSummary': '{gpu} · {vram} GB VRAM',
  'marketplaceDetail.fit.noGpu': 'No GPU detected',
  'marketplaceDetail.fit.ramSummary': '{ram} GB system memory (RAM)',
  'marketplaceDetail.fit.fullGpu': 'Fits entirely on GPU',
  'marketplaceDetail.fit.partialOffload': 'GPU + system memory',
  'marketplaceDetail.fit.cpuOnlyLabel': 'CPU only (slower)',
  'marketplaceDetail.fit.unsupported': 'Does not fit this device',
  'marketplaceDetail.fit.unknown': 'Compatibility unknown',

  // Model detail dialog
  'marketplaceDetail.model.fallbackName': 'Model',
  'marketplaceDetail.model.noDescription': 'No description available.',
  'marketplaceDetail.model.contextBadge': '{count}K context',
  'marketplaceDetail.model.price': 'Price: {price}',
  'marketplaceDetail.model.intelligence': 'IQ {score}',
  'marketplaceDetail.model.downloads': '{count} hits',
  'marketplaceDetail.model.vram': '{prefix}{value} GB VRAM{suffix}',
  'marketplaceDetail.model.vramEstimatedSuffix': ' (estimated)',
  'marketplaceDetail.model.tags': 'Tags',
  'marketplaceDetail.model.availableVariants': 'Available variants',
  'marketplaceDetail.model.variantFallback': 'Variant',
  'marketplaceDetail.model.shardCount': '{count} related files',

  // Filter preview and recommendation explanations
  'marketplaceDetail.filter.category': 'Category',
  'marketplaceDetail.filter.chat': 'Chat',
  'marketplaceDetail.filter.code': 'Code',
  'marketplaceDetail.filter.reasoning': 'Reasoning',
  'marketplaceDetail.filter.vision': 'Vision',
  'marketplaceDetail.filter.localOnly': 'Local only',
  'marketplaceDetail.recommendation.balanced':
      'Q4_K_M / Q4_0 is the best compromise for most users: about 50% of the original size with almost full quality. It runs on nearly any hardware.',
  'marketplaceDetail.recommendation.maxQuality':
      'FP16 / Q8 / Q5_0 retain almost 100% of the original quality, but need 2–3× more memory/RAM. Best suited to powerful GPUs (24 GB+ VRAM).',
  'marketplaceDetail.recommendation.compact':
      'Q2 / Q3 / Q5_K_S are very small (30–40% of the size), but output quality suffers noticeably. Use only when memory is very limited.',
  'marketplaceDetail.recommendation.unavailable':
      'No recommendation available.',
};

/// Translates a Marketplace detail key, then falls back to the app-wide maps.
String tr(String key, [Map<String, String>? params]) {
  final strings = base.appLanguage == 'en'
      ? marketplaceDetailStringsEn
      : marketplaceDetailStringsDe;
  var value = strings[key] ?? base.AppStrings.tr(key);
  if (params != null) {
    params.forEach((name, replacement) {
      value = value.replaceAll('{$name}', replacement);
    });
  }
  return value;
}
