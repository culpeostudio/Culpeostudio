typedef JsonMap = Map<String, dynamic>;

JsonMap _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  return const <String, dynamic>{};
}

dynamic _first(JsonMap json, List<String> keys) {
  for (final key in keys) {
    if (json.containsKey(key)) return json[key];
  }
  return null;
}

String _string(dynamic value, [String fallback = '']) {
  if (value == null) return fallback;
  return value.toString();
}

int _integer(dynamic value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

double _decimal(dynamic value, [double fallback = 0]) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

bool _boolean(dynamic value, [bool fallback = false]) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  switch (value?.toString().toLowerCase()) {
    case 'true':
    case 'yes':
    case '1':
      return true;
    case 'false':
    case 'no':
    case '0':
      return false;
    default:
      return fallback;
  }
}

DateTime? _dateTime(dynamic value) {
  final raw = value?.toString().trim() ?? '';
  if (raw.isEmpty) return null;
  return DateTime.tryParse(raw);
}

List<dynamic> _asList(dynamic value) => value is List ? value : const [];

List<String> _stringList(dynamic value) => _asList(value)
    .map((item) {
      if (item is! Map) return _string(item);
      final message = _string(item['message'] ?? item['code']);
      final remediation = _string(item['remediation']);
      if (message.isEmpty) return remediation;
      if (remediation.isEmpty) return message;
      return '$message — $remediation';
    })
    .where((item) => item.isNotEmpty)
    .toList();

class ModelRecord {
  final String id;
  final String name;
  final String format;
  final String relativePath;
  final int sizeBytes;
  final String status;
  final String architecture;
  final String quantization;
  final int modelContextLimitTokens;
  final List<String> runtimeCandidates;
  final List<String> validationIssues;

  const ModelRecord({
    required this.id,
    required this.name,
    required this.format,
    required this.relativePath,
    required this.sizeBytes,
    required this.status,
    required this.architecture,
    required this.quantization,
    required this.modelContextLimitTokens,
    required this.runtimeCandidates,
    required this.validationIssues,
  });

  bool get isStartable =>
      status == 'ready' || status == 'complete' || status == 'available';

  factory ModelRecord.fromJson(dynamic value) {
    final json = _asMap(value);
    final metadata = _asMap(json['metadata']);
    var status = _string(json['status']).toLowerCase();
    if (status.isEmpty) {
      status = _boolean(json['startable'])
          ? 'ready'
          : _boolean(json['complete'])
          ? 'invalid'
          : 'incomplete';
    }
    return ModelRecord(
      id: _string(_first(json, const ['id', 'model_id', 'modelId'])),
      name: _string(
        _first(json, const ['name', 'display_name', 'displayName']),
        'Unbenanntes Modell',
      ),
      format: _string(json['format'], 'unknown').toLowerCase(),
      relativePath: _string(
        _first(json, const ['relative_path', 'relativePath', 'path']),
      ),
      sizeBytes: _integer(_first(json, const ['size_bytes', 'sizeBytes'])),
      status: status,
      architecture: _string(
        json['architecture'] ?? metadata['architecture'],
        'Unbekannt',
      ),
      quantization: _string(
        json['quantization'] ?? metadata['quantization'],
        'Unbekannt',
      ),
      modelContextLimitTokens: _integer(
        _first(json, const [
          'model_context_limit_tokens',
          'modelContextLimitTokens',
          'context_length',
        ]),
        _integer(metadata['context_length']),
      ),
      runtimeCandidates: _stringList(
        _first(json, const ['runtime_candidates', 'runtimeCandidates']),
      ),
      validationIssues: _stringList(
        _first(json, const ['validation_issues', 'validationIssues', 'issues']),
      ),
    );
  }
}

class GpuDevice {
  final String id;
  final String name;
  final int vramTotalBytes;
  final int vramFreeBytes;
  final String backend;
  final bool unifiedMemory;

  const GpuDevice({
    required this.id,
    required this.name,
    required this.vramTotalBytes,
    required this.vramFreeBytes,
    required this.backend,
    required this.unifiedMemory,
  });

  factory GpuDevice.fromJson(dynamic value) {
    final json = _asMap(value);
    return GpuDevice(
      id: _string(_first(json, const ['id', 'stable_id', 'stableId'])),
      name: _string(json['name'], 'GPU'),
      vramTotalBytes: _integer(
        _first(json, const [
          'vram_total_bytes',
          'vramTotalBytes',
          'total_bytes',
        ]),
      ),
      vramFreeBytes: _integer(
        _first(json, const [
          'vram_free_bytes',
          'vramFreeBytes',
          'available_bytes',
        ]),
      ),
      backend: _string(
        _first(json, const ['backend', 'compute_backend', 'computeBackend']),
      ),
      unifiedMemory: _boolean(
        _first(json, const [
          'shared_memory',
          'unified_memory',
          'unifiedMemory',
        ]),
      ),
    );
  }
}

class HardwareSnapshot {
  final int ramTotalBytes;
  final int ramAvailableBytes;
  final List<GpuDevice> gpus;

  const HardwareSnapshot({
    required this.ramTotalBytes,
    required this.ramAvailableBytes,
    required this.gpus,
  });

  factory HardwareSnapshot.fromJson(dynamic value) {
    final json = _asMap(value);
    return HardwareSnapshot(
      ramTotalBytes: _integer(
        _first(json, const ['ram_total_bytes', 'ramTotalBytes']),
      ),
      ramAvailableBytes: _integer(
        _first(json, const ['ram_available_bytes', 'ramAvailableBytes']),
      ),
      gpus: _asList(json['gpus']).map(GpuDevice.fromJson).toList(),
    );
  }
}

class RuntimeCapability {
  final String id;
  final String name;
  final String status;
  final bool available;
  final double progress;
  final String? error;
  final String statusMessage;
  final String errorCode;
  final String version;
  final List<String> gpuBackends;
  final List<String> kvCacheModes;
  final JsonMap configFields;
  final List<String> supportedFields;
  final List<String> liveFields;
  final List<String> restartRequiredFields;

  const RuntimeCapability({
    required this.id,
    required this.name,
    required this.status,
    required this.available,
    required this.progress,
    required this.error,
    this.statusMessage = '',
    this.errorCode = '',
    this.version = '',
    this.gpuBackends = const [],
    this.kvCacheModes = const [],
    this.configFields = const {},
    required this.supportedFields,
    required this.liveFields,
    required this.restartRequiredFields,
  });

  factory RuntimeCapability.fromJson(dynamic value) {
    final json = _asMap(value);
    var progress = _decimal(json['progress']);
    if (progress > 1) progress /= 100;
    final installed = _boolean(json['installed']);
    final healthy = _boolean(json['healthy']);
    final probeError = _string(
      _first(json, const ['error', 'probe_error', 'probeError']),
    );
    var status = _string(json['status']).toLowerCase();
    if (status.isEmpty) {
      status = installed && healthy
          ? 'ready'
          : probeError.isNotEmpty
          ? 'failed'
          : installed
          ? 'installed'
          : 'missing';
    }
    final configFields = _asMap(
      _first(json, const ['config_fields', 'configFields']),
    );
    final inferredSupportedFields = configFields.keys.toList();
    final inferredLiveFields = configFields.entries
        .where((entry) => entry.value == 'live')
        .map((entry) => entry.key)
        .toList();
    final inferredRestartFields = configFields.entries
        .where((entry) => entry.value == 'restart_required')
        .map((entry) => entry.key)
        .toList();
    return RuntimeCapability(
      id: _string(_first(json, const ['id', 'runtime', 'kind', 'name'])),
      name: _string(_first(json, const ['display_name', 'name', 'id', 'kind'])),
      status: status,
      available: _boolean(
        json['available'],
        healthy ||
            status == 'ready' ||
            status == 'installed' ||
            status == 'available',
      ),
      progress: progress.clamp(0, 1),
      error: probeError.isEmpty ? null : probeError,
      statusMessage: _string(
        _first(json, const ['status_message', 'statusMessage', 'message']),
      ),
      errorCode: _string(
        _first(json, const ['error_code', 'errorCode', 'code']),
      ),
      version: _string(json['version']),
      gpuBackends: _stringList(
        _first(json, const ['gpu_backends', 'gpuBackends']),
      ),
      kvCacheModes: _stringList(
        _first(json, const ['kv_cache_modes', 'kvCacheModes', 'kv_caches']),
      ),
      configFields: configFields,
      supportedFields:
          _stringList(
            _first(json, const ['supported_fields', 'supportedFields']),
          ).isEmpty
          ? inferredSupportedFields
          : _stringList(
              _first(json, const ['supported_fields', 'supportedFields']),
            ),
      liveFields:
          _stringList(_first(json, const ['live_fields', 'liveFields'])).isEmpty
          ? inferredLiveFields
          : _stringList(_first(json, const ['live_fields', 'liveFields'])),
      restartRequiredFields:
          _stringList(
            _first(json, const [
              'restart_required_fields',
              'restartRequiredFields',
            ]),
          ).isEmpty
          ? inferredRestartFields
          : _stringList(
              _first(json, const [
                'restart_required_fields',
                'restartRequiredFields',
              ]),
            ),
    );
  }
}

class EngineCapabilities {
  final HardwareSnapshot hardware;
  final List<RuntimeCapability> runtimes;
  final JsonMap defaults;

  const EngineCapabilities({
    required this.hardware,
    required this.runtimes,
    required this.defaults,
  });

  factory EngineCapabilities.fromJson(dynamic value) {
    final json = _asMap(value);
    return EngineCapabilities(
      hardware: HardwareSnapshot.fromJson(json['hardware']),
      runtimes: _asList(
        json['runtimes'],
      ).map(RuntimeCapability.fromJson).toList(),
      defaults: _asMap(json['defaults']),
    );
  }

  int get ramReserveBytes => _integer(
    _first(defaults, const ['ram_reserve_bytes', 'ramReserveBytes']),
  );

  int get gpuReserveBytes => _integer(
    _first(defaults, const ['gpu_reserve_bytes', 'gpuReserveBytes']),
  );

  Map<String, int> get gpuReserveBytesById => _asMap(
    _first(defaults, const ['gpu_reserve_bytes_by_id', 'gpuReserveBytesById']),
  ).map((key, value) => MapEntry(key, _integer(value)));

  bool get ramReserveIsAutomatic => _boolean(
    _first(defaults, const [
      'ram_reserve_is_automatic',
      'ramReserveIsAutomatic',
    ]),
    true,
  );

  bool get gpuReserveIsAutomatic => _boolean(
    _first(defaults, const [
      'gpu_reserve_is_automatic',
      'gpuReserveIsAutomatic',
    ]),
    true,
  );
}

class EngineConfig {
  final String runtime;
  final String contextMode;
  final int? contextTokens;
  final int maxSequences;
  final String priority;
  final String kvCachePolicy;
  final bool allowFallback;
  final bool autostart;
  final bool trustRemoteCode;
  final JsonMap runtimeOptions;
  final JsonMap generationDefaults;

  const EngineConfig({
    this.runtime = 'auto',
    this.contextMode = 'auto_max',
    this.contextTokens,
    this.maxSequences = 1,
    this.priority = 'normal',
    this.kvCachePolicy = 'prefer_4bit',
    this.allowFallback = true,
    this.autostart = false,
    this.trustRemoteCode = false,
    this.runtimeOptions = const {},
    this.generationDefaults = const {},
  });

  factory EngineConfig.fromJson(dynamic value) {
    final json = _asMap(value);
    return EngineConfig(
      runtime: _string(json['runtime'], 'auto'),
      contextMode: _string(
        _first(json, const ['context_mode', 'contextMode']),
        'auto_max',
      ),
      contextTokens:
          _first(json, const [
                'context_tokens',
                'contextTokens',
                'max_context_tokens',
                'context_length',
              ]) ==
              null
          ? null
          : _integer(
              _first(json, const [
                'context_tokens',
                'contextTokens',
                'max_context_tokens',
                'context_length',
              ]),
            ),
      maxSequences: _integer(
        _first(json, const ['max_sequences', 'maxSequences']),
        1,
      ),
      priority: _string(json['priority'], 'normal'),
      kvCachePolicy: _string(
        _first(json, const ['kv_cache_policy', 'kvCachePolicy', 'kv_policy']),
        'prefer_4bit',
      ),
      allowFallback: _boolean(
        _first(json, const ['allow_fallback', 'allowFallback']),
        true,
      ),
      autostart: _boolean(json['autostart']),
      trustRemoteCode: _boolean(
        _first(json, const ['trust_remote_code', 'trustRemoteCode']),
      ),
      runtimeOptions:
          _asMap(
            _first(json, const ['runtime_options', 'runtimeOptions']),
          ).isNotEmpty
          ? _asMap(_first(json, const ['runtime_options', 'runtimeOptions']))
          : {
              if (json.containsKey('gpu_layers'))
                'gpu_layers': json['gpu_layers'],
              if (json.containsKey('threads')) 'threads': json['threads'],
              if (json.containsKey('tensor_parallelism'))
                'tensor_parallel_size': json['tensor_parallelism'],
              if (json.containsKey('kv_cache_dtype'))
                'kv_cache_dtype': json['kv_cache_dtype'],
            },
      generationDefaults: _asMap(
        _first(json, const ['generation_defaults', 'generationDefaults']),
      ),
    );
  }

  JsonMap toJson() => {
    'runtime': runtime,
    'context_mode': contextMode,
    'context_tokens': contextTokens,
    'max_sequences': maxSequences,
    'priority': priority,
    'kv_cache_policy': kvCachePolicy,
    'allow_fallback': allowFallback,
    'autostart': autostart,
    'trust_remote_code': trustRemoteCode,
    'runtime_options': runtimeOptions,
    'generation_defaults': generationDefaults,
  };
}

class RemoteCodeApproval {
  final String modelId;
  final String fingerprint;
  final String pythonFilesHash;
  final int pythonFileCount;
  final String warning;

  const RemoteCodeApproval({
    required this.modelId,
    required this.fingerprint,
    required this.pythonFilesHash,
    required this.pythonFileCount,
    required this.warning,
  });

  factory RemoteCodeApproval.fromJson(dynamic value) {
    final json = _asMap(value);
    return RemoteCodeApproval(
      modelId: _string(_first(json, const ['model_id', 'modelId'])),
      fingerprint: _string(json['fingerprint']),
      pythonFilesHash: _string(
        _first(json, const ['python_files_hash', 'pythonFilesHash']),
      ),
      pythonFileCount: _integer(
        _first(json, const ['python_file_count', 'pythonFileCount']),
      ),
      warning: _string(json['warning']),
    );
  }
}

class SystemDependencyConsent {
  final String token;
  final DateTime? expiresAt;
  final String packageName;
  final String commandSummary;
  final String warning;

  const SystemDependencyConsent({
    required this.token,
    required this.expiresAt,
    required this.packageName,
    required this.commandSummary,
    required this.warning,
  });

  factory SystemDependencyConsent.fromJson(dynamic value) {
    final json = _asMap(value);
    final rawExpiry = _string(_first(json, const ['expires_at', 'expiresAt']));
    return SystemDependencyConsent(
      token: _string(
        _first(json, const ['consent_token', 'consentToken', 'token']),
      ),
      expiresAt: rawExpiry.isEmpty ? null : DateTime.tryParse(rawExpiry),
      packageName: _string(
        _first(json, const ['package', 'package_name', 'packageName']),
      ),
      commandSummary: _string(
        _first(json, const ['command_summary', 'commandSummary']),
      ),
      warning: _string(json['warning']),
    );
  }
}

class MemoryBreakdown {
  final int weightsBytes;
  final int kvCacheBytes;
  final int runtimeBytes;
  final int reserveBytes;
  final int gpuBytes;
  final int ramBytes;

  const MemoryBreakdown({
    required this.weightsBytes,
    required this.kvCacheBytes,
    required this.runtimeBytes,
    required this.reserveBytes,
    required this.gpuBytes,
    required this.ramBytes,
  });

  factory MemoryBreakdown.fromJson(dynamic value) {
    final json = _asMap(value);
    int allocationBytes(String key) => _integer(
      _first(_asMap(json[key]), const ['total_bytes', 'totalBytes']),
    );
    final total = _asMap(json['total']);
    final totalGpu = _asMap(
      total['gpu_bytes'],
    ).values.fold<int>(0, (sum, item) => sum + _integer(item));
    return MemoryBreakdown(
      weightsBytes: _integer(
        _first(json, const ['weights_bytes', 'weightsBytes']),
        allocationBytes('weights'),
      ),
      kvCacheBytes: _integer(
        _first(json, const ['kv_cache_bytes', 'kvCacheBytes']),
        allocationBytes('kv_cache'),
      ),
      runtimeBytes: _integer(
        _first(json, const ['runtime_bytes', 'runtimeBytes']),
        allocationBytes('runtime'),
      ),
      reserveBytes: _integer(
        _first(json, const ['reserve_bytes', 'reserveBytes']),
        allocationBytes('reserve'),
      ),
      gpuBytes: _integer(
        _first(json, const ['gpu_bytes', 'gpuBytes']),
        totalGpu,
      ),
      ramBytes: _integer(
        _first(json, const ['ram_bytes', 'ramBytes']),
        _integer(_first(total, const ['ram_bytes', 'ramBytes'])),
      ),
    );
  }
}

class ContextPlan {
  final int modelContextLimitTokens;
  final int gpuOnlyMaxContextTokens;
  final int hybridMaxContextTokens;
  final int effectiveContextTokens;
  final int? ramRequiredAfterTokens;
  final MemoryBreakdown memory;
  final String confidence;
  final List<String> warnings;
  final int kvBytesPerTokenAtStart;
  final int maxSequences;
  final String kvCacheDtype;
  final String priority;
  final bool pinned;
  final bool restartRequired;
  final bool usesRam;
  final List<String> affectedRestartInstances;
  final PreflightReport preflight;

  const ContextPlan({
    required this.modelContextLimitTokens,
    required this.gpuOnlyMaxContextTokens,
    required this.hybridMaxContextTokens,
    required this.effectiveContextTokens,
    required this.ramRequiredAfterTokens,
    required this.memory,
    required this.confidence,
    required this.warnings,
    this.kvBytesPerTokenAtStart = 0,
    this.maxSequences = 1,
    this.kvCacheDtype = '',
    this.priority = 'normal',
    this.pinned = false,
    this.restartRequired = false,
    this.usesRam = false,
    this.affectedRestartInstances = const [],
    this.preflight = const PreflightReport(),
  });

  factory ContextPlan.fromJson(dynamic value) {
    final json = _asMap(value);
    final ramThreshold = _first(json, const [
      'ram_required_after_tokens',
      'ramRequiredAfterTokens',
      'ram_required_from_context',
    ]);
    return ContextPlan(
      modelContextLimitTokens: _integer(
        _first(json, const [
          'model_context_limit_tokens',
          'modelContextLimitTokens',
          'model_limit',
        ]),
      ),
      gpuOnlyMaxContextTokens: _integer(
        _first(json, const [
          'gpu_only_max_context_tokens',
          'gpuOnlyMaxContextTokens',
          'gpu_only_max_context',
        ]),
      ),
      hybridMaxContextTokens: _integer(
        _first(json, const [
          'hybrid_max_context_tokens',
          'ram_supported_max_context_tokens',
          'hybridMaxContextTokens',
          'ram_backed_max_context',
        ]),
      ),
      effectiveContextTokens: _integer(
        _first(json, const [
          'effective_context_tokens',
          'effectiveContextTokens',
          'context_tokens',
          'effective_context',
        ]),
      ),
      ramRequiredAfterTokens: ramThreshold == null
          ? null
          : _integer(ramThreshold),
      memory: MemoryBreakdown.fromJson(
        _first(json, const [
          'memory',
          'memory_breakdown',
          'memoryBreakdown',
          'breakdown',
        ]),
      ),
      confidence: _string(json['confidence'], 'estimated'),
      warnings: _stringList(json['warnings']),
      kvBytesPerTokenAtStart: _integer(
        _first(json, const [
          'kv_bytes_per_token_at_start',
          'kvBytesPerTokenAtStart',
        ]),
      ),
      maxSequences: _integer(
        _first(json, const ['max_sequences', 'maxSequences']),
        1,
      ),
      kvCacheDtype: _string(
        _first(json, const ['kv_cache_dtype', 'kvCacheDtype']),
      ),
      priority: _string(json['priority'], 'normal'),
      pinned: _boolean(json['pinned']),
      restartRequired: _boolean(
        _first(json, const ['restart_required', 'restartRequired']),
      ),
      usesRam: _boolean(_first(json, const ['uses_ram', 'usesRam'])),
      affectedRestartInstances: _stringList(
        _first(json, const [
          'affected_restart_instances',
          'affectedRestartInstances',
        ]),
      ),
      preflight: PreflightReport.fromJson(json['preflight']),
    );
  }
}

class PreflightCheck {
  final String id;
  final String state;
  final String label;
  final String detail;

  const PreflightCheck({
    required this.id,
    required this.state,
    required this.label,
    required this.detail,
  });

  factory PreflightCheck.fromJson(dynamic value) {
    final json = _asMap(value);
    return PreflightCheck(
      id: _string(json['id']),
      state: _string(json['state'], 'pending'),
      label: _string(json['label']),
      detail: _string(json['detail']),
    );
  }
}

class PreflightReport {
  final String hardwareSnapshotId;
  final String modelFingerprint;
  final String metadataConfidence;
  final List<PreflightCheck> checks;

  const PreflightReport({
    this.hardwareSnapshotId = '',
    this.modelFingerprint = '',
    this.metadataConfidence = '',
    this.checks = const [],
  });

  factory PreflightReport.fromJson(dynamic value) {
    final json = _asMap(value);
    return PreflightReport(
      hardwareSnapshotId: _string(
        _first(json, const ['hardware_snapshot_id', 'hardwareSnapshotId']),
      ),
      modelFingerprint: _string(
        _first(json, const ['model_fingerprint', 'modelFingerprint']),
      ),
      metadataConfidence: _string(
        _first(json, const ['metadata_confidence', 'metadataConfidence']),
      ),
      checks: _asList(json['checks']).map(PreflightCheck.fromJson).toList(),
    );
  }
}

class EngineFallback {
  final String setting;
  final String from;
  final String to;
  final String reason;

  const EngineFallback({
    this.setting = '',
    required this.from,
    required this.to,
    required this.reason,
  });

  factory EngineFallback.fromJson(dynamic value) {
    if (value is String) {
      return EngineFallback(from: '', to: '', reason: value);
    }
    final json = _asMap(value);
    return EngineFallback(
      setting: _string(json['setting']),
      from: _string(json['from']),
      to: _string(json['to']),
      reason: _string(
        _first(json, const ['reason', 'message']),
        'Automatischer Fallback',
      ),
    );
  }

  String get label {
    if (from.isNotEmpty && to.isNotEmpty) return '$from → $to: $reason';
    return reason;
  }
}

/// One-click remediation offered by the backend next to a failure
/// (e.g. automatically shrink the context after an out-of-memory start).
class SuggestedFix {
  final String action;
  final String label;

  const SuggestedFix({required this.action, required this.label});

  static SuggestedFix? fromJson(dynamic value) {
    if (value is! Map) return null;
    final action = _string(value['action']);
    if (action.isEmpty) return null;
    final label = _string(value['label']);
    return SuggestedFix(
      action: action,
      label: label.isEmpty ? 'Automatisch beheben' : label,
    );
  }
}

class EngineInstance {
  final String id;
  final String state;
  final String modelId;
  final String servedModelName;
  final EngineConfig requestedConfig;
  final EngineConfig effectiveConfig;
  final ContextPlan? plan;
  final List<String> restartRequiredFields;
  final List<EngineFallback> fallbacks;
  final String? error;
  final String errorSummary;
  final String errorCode;
  final SuggestedFix? suggestedFix;
  final String phase;
  final String detailMessage;
  final double progress;
  final String runtime;
  final String endpointName;
  final String priority;
  final bool pinned;
  final bool autostart;
  final int planRevision;
  final bool showInChatPicker;
  final String placement;
  final int activeRequests;
  final DateTime? lastUsedAt;
  final DateTime? idleExpiresAt;
  final String guardState;

  const EngineInstance({
    required this.id,
    required this.state,
    required this.modelId,
    required this.servedModelName,
    required this.requestedConfig,
    required this.effectiveConfig,
    required this.plan,
    required this.restartRequiredFields,
    required this.fallbacks,
    required this.error,
    this.errorSummary = '',
    this.errorCode = '',
    this.suggestedFix,
    this.phase = '',
    this.detailMessage = '',
    required this.progress,
    this.runtime = '',
    this.endpointName = '',
    this.priority = 'normal',
    this.pinned = false,
    this.autostart = false,
    this.planRevision = 0,
    this.showInChatPicker = false,
    this.placement = 'unknown',
    this.activeRequests = 0,
    this.lastUsedAt,
    this.idleExpiresAt,
    this.guardState = 'normal',
  });

  bool get isReady => state == 'ready';
  bool get isStopped =>
      const {'stopped', 'failed', 'failed_rollback'}.contains(state);
  bool get isVisibleInChat => isReady || (showInChatPicker && isStopped);
  bool get isActive => const {
    'installing',
    'queued',
    'starting',
    'ready',
    'draining',
    'restarting',
  }.contains(state);

  factory EngineInstance.fromJson(dynamic value) {
    final json = _asMap(value);
    var progress = _decimal(json['progress']);
    if (progress > 1) progress /= 100;
    final rawError = json['error'];
    return EngineInstance(
      id: _string(_first(json, const ['id', 'instance_id', 'instanceId'])),
      state: _string(json['state'], 'stopped').toLowerCase(),
      modelId: _string(_first(json, const ['model_id', 'modelId'])),
      servedModelName: _string(
        _first(json, const ['served_model_name', 'servedModelName']),
      ),
      requestedConfig: EngineConfig.fromJson(
        _first(json, const ['requested_config', 'requestedConfig']),
      ),
      effectiveConfig: EngineConfig.fromJson(
        _first(json, const ['effective_config', 'effectiveConfig']),
      ),
      plan: json['plan'] == null ? null : ContextPlan.fromJson(json['plan']),
      restartRequiredFields: _stringList(
        _first(json, const [
          'restart_required_fields',
          'restartRequiredFields',
        ]),
      ),
      fallbacks: _asList(
        json['fallbacks'],
      ).map(EngineFallback.fromJson).toList(),
      error: rawError == null
          ? null
          : rawError is Map
          ? _string(rawError['message'] ?? rawError['error'])
          : _string(rawError),
      errorSummary: _string(
        _first(json, const ['error_summary', 'errorSummary']),
      ),
      errorCode: _string(_first(json, const ['error_code', 'errorCode'])),
      suggestedFix: SuggestedFix.fromJson(
        _first(json, const ['suggested_fix', 'suggestedFix']),
      ),
      phase: _string(json['phase']),
      detailMessage: _string(
        _first(json, const ['detail_message', 'detailMessage']),
      ),
      progress: progress.clamp(0, 1),
      runtime: _string(json['runtime']),
      endpointName: _string(
        _first(json, const ['endpoint_name', 'endpointName']),
      ),
      priority: _string(json['priority'], 'normal'),
      pinned: _boolean(json['pinned']),
      autostart: _boolean(json['autostart']),
      planRevision: _integer(
        _first(json, const ['plan_revision', 'planRevision']),
      ),
      showInChatPicker: _boolean(
        _first(json, const ['show_in_chat_picker', 'showInChatPicker']),
      ),
      placement: _normalizePlacement(
        _string(_first(json, const ['placement', 'memory_placement'])),
      ),
      activeRequests: _integer(
        _first(json, const ['active_requests', 'activeRequests']),
      ),
      lastUsedAt: _dateTime(_first(json, const ['last_used_at', 'lastUsedAt'])),
      idleExpiresAt: _dateTime(
        _first(json, const ['idle_expires_at', 'idleExpiresAt']),
      ),
      guardState: _normalizeGuardState(
        _string(_first(json, const ['guard_state', 'guardState'])),
      ),
    );
  }
}

String _normalizePlacement(String value) {
  switch (value.trim().toLowerCase()) {
    case 'gpu':
    case 'ram':
    case 'hybrid':
      return value.trim().toLowerCase();
    default:
      return 'unknown';
  }
}

String _normalizeGuardState(String value) {
  switch (value.trim().toLowerCase()) {
    case 'warning':
    case 'critical':
    case 'emergency':
      return value.trim().toLowerCase();
    default:
      return 'normal';
  }
}

class EngineOperation {
  final String id;
  final String type;
  final String state;
  final String? instanceId;
  final double progress;
  final String? message;
  final String? error;
  final String phase;
  final String detailMessage;
  final String errorSummary;
  final String errorCode;
  final int? queuePosition;

  const EngineOperation({
    required this.id,
    required this.type,
    required this.state,
    required this.instanceId,
    required this.progress,
    required this.message,
    required this.error,
    this.phase = '',
    this.detailMessage = '',
    this.errorSummary = '',
    this.errorCode = '',
    this.queuePosition,
  });

  bool get isTerminal => const {
    'completed',
    'complete',
    'canceled',
    'cancelled',
    'failed',
  }.contains(state);

  factory EngineOperation.fromJson(dynamic value) {
    final json = _asMap(value);
    var progress = _decimal(json['progress']);
    if (progress > 1) progress /= 100;
    return EngineOperation(
      id: _string(_first(json, const ['id', 'operation_id', 'operationId'])),
      type: _string(json['type'], 'engine'),
      state: _string(json['state'], 'queued').toLowerCase(),
      instanceId: _first(json, const ['instance_id', 'instanceId']) == null
          ? null
          : _string(_first(json, const ['instance_id', 'instanceId'])),
      progress: progress.clamp(0, 1),
      message: json['message'] == null ? null : _string(json['message']),
      error: json['error'] == null ? null : _string(json['error']),
      phase: _string(json['phase']),
      detailMessage: _string(
        _first(json, const ['detail_message', 'detailMessage']),
      ),
      errorSummary: _string(
        _first(json, const ['error_summary', 'errorSummary']),
      ),
      errorCode: _string(_first(json, const ['error_code', 'errorCode'])),
      queuePosition:
          _first(json, const ['queue_position', 'queuePosition']) == null
          ? null
          : _integer(_first(json, const ['queue_position', 'queuePosition'])),
    );
  }
}

class EngineEnsureReadyResult {
  final String? operationId;
  final String status;
  final int? queuePosition;
  final EngineInstance? instance;

  const EngineEnsureReadyResult({
    this.operationId,
    required this.status,
    this.queuePosition,
    this.instance,
  });

  bool get isReady => status == 'ready' || instance?.isReady == true;

  factory EngineEnsureReadyResult.fromJson(dynamic value) {
    final json = _asMap(value);
    final rawInstance = json['instance'];
    return EngineEnsureReadyResult(
      operationId: _first(json, const ['operation_id', 'operationId']) == null
          ? null
          : _string(_first(json, const ['operation_id', 'operationId'])),
      status: _string(json['status'], 'queued').toLowerCase(),
      queuePosition:
          _first(json, const ['queue_position', 'queuePosition']) == null
          ? null
          : _integer(_first(json, const ['queue_position', 'queuePosition'])),
      instance: rawInstance == null
          ? null
          : EngineInstance.fromJson(rawInstance),
    );
  }
}

class EngineMutationResult {
  final String? operationId;
  final EngineInstance? instance;

  const EngineMutationResult({this.operationId, this.instance});

  factory EngineMutationResult.fromJson(dynamic value) {
    final json = _asMap(value);
    final rawInstance = json['instance'];
    return EngineMutationResult(
      operationId: _first(json, const ['operation_id', 'operationId']) == null
          ? null
          : _string(_first(json, const ['operation_id', 'operationId'])),
      instance: rawInstance == null
          ? (json.containsKey('state') ? EngineInstance.fromJson(json) : null)
          : EngineInstance.fromJson(rawInstance),
    );
  }
}
