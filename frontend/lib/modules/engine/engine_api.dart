import './models.dart';

class EngineStreamEvent {
  final String type;
  final Map<String, dynamic> data;
  final DateTime? timestamp;

  const EngineStreamEvent({
    required this.type,
    required this.data,
    this.timestamp,
  });
}

class EngineApiException implements Exception {
  const EngineApiException(
    this.message, {
    this.statusCode,
    this.code,
    this.details = const <String, dynamic>{},
  });

  final String message;
  final int? statusCode;
  final String? code;
  final JsonMap details;

  @override
  String toString() => message;
}

abstract interface class EngineApi {
  Future<List<ModelRecord>> getEngineModels();

  Future<List<ModelRecord>> rescanEngineModels();

  Future<List<ModelRecord>> deleteEngineModel(String modelId);

  Future<EngineCapabilities> getEngineCapabilities();

  Future<List<RuntimeCapability>> getEngineRuntimes();

  Future<EngineMutationResult> installEngineRuntime(String runtimeId);

  Future<ContextPlan> getEngineRecommendation(
    String modelId, {
    EngineConfig? config,
  });

  Future<List<EngineInstance>> getEngineInstances();

  Future<EngineMutationResult> createEngineInstance({
    required String modelId,
    String? servedModelName,
    required EngineConfig config,
  });

  Future<EngineInstance> getEngineInstance(String instanceId);

  Future<EngineEnsureReadyResult> ensureEngineInstanceReady(String instanceId);

  Stream<EngineStreamEvent> streamEngineEvents();

  Future<EngineMutationResult> updateEngineInstance(
    String instanceId,
    Map<String, dynamic> changes,
  );

  Future<EngineMutationResult> deleteEngineInstance(String instanceId);

  Future<EngineOperation> getEngineOperation(String operationId);

  Future<EngineOperation> cancelEngineOperation(String operationId);

  /// The worker process's own output, for when the error summary is not enough.
  Future<InstanceLogs> getEngineInstanceLogs(
    String instanceId, {
    int tailLines,
  });

  /// The target formats the installed llama.cpp build can write.
  Future<QuantizationCatalog> getQuantizationTypes();

  /// What the conversion would do, without writing anything.
  Future<QuantizationPreflight> preflightQuantization(QuantizationJob job);

  /// Schedules the conversion. The result carries the operation to follow.
  Future<EngineQuantizationStart> startQuantization(QuantizationJob job);

  /// The saved configurations, built-ins first.
  Future<List<EnginePreset>> getEnginePresets();

  /// Creates a preset, or replaces the one named by [id].
  Future<EnginePreset> saveEnginePreset({
    String id,
    required String name,
    String description,
    required EngineConfig config,
    String modelId,
  });

  Future<void> deleteEnginePreset(String presetId);

  /// Renders presets as a transfer document. Empty [presetIds] exports every
  /// preset the user saved themselves.
  Future<EnginePresetExport> exportEnginePresets([List<String> presetIds]);

  /// Reads a transfer document back. Each entry arrives under a fresh id.
  Future<List<EnginePreset>> importEnginePresets(String document);
}

/// One requested conversion.
class QuantizationJob {
  final String sourceModelId;
  final String targetType;
  final String targetName;
  final bool allowRequantize;
  final bool leaveOutputTensor;
  final int threads;

  const QuantizationJob({
    required this.sourceModelId,
    required this.targetType,
    this.targetName = '',
    this.allowRequantize = false,
    this.leaveOutputTensor = false,
    this.threads = 0,
  });

  QuantizationJob copyWith({
    String? targetType,
    String? targetName,
    bool? allowRequantize,
    bool? leaveOutputTensor,
    int? threads,
  }) => QuantizationJob(
    sourceModelId: sourceModelId,
    targetType: targetType ?? this.targetType,
    targetName: targetName ?? this.targetName,
    allowRequantize: allowRequantize ?? this.allowRequantize,
    leaveOutputTensor: leaveOutputTensor ?? this.leaveOutputTensor,
    threads: threads ?? this.threads,
  );
}

/// A scheduled conversion: the operation to follow, and the preflight that
/// describes what it will produce.
class EngineQuantizationStart {
  final String operationId;
  final String state;
  final QuantizationPreflight preflight;

  const EngineQuantizationStart({
    this.operationId = '',
    this.state = '',
    this.preflight = const QuantizationPreflight(),
  });
}
