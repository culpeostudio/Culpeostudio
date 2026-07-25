import 'models.dart';

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

  bool get requiresRemoteCodeConsent =>
      statusCode == 409 && code == 'remote_code_consent_required';

  @override
  String toString() => message;
}

abstract interface class EngineApi {
  Future<List<ModelRecord>> getEngineModels();

  Future<List<ModelRecord>> rescanEngineModels();

  /// Deletes the selected local model and its catalogued files.
  Future<List<ModelRecord>> deleteEngineModel(String modelId);

  Future<EngineCapabilities> getEngineCapabilities();

  Future<List<RuntimeCapability>> getEngineRuntimes();

  Future<EngineMutationResult> installEngineRuntime(String runtimeId);

  Future<SystemDependencyConsent> createVulkanDependencyConsent();

  Future<EngineMutationResult> installVulkanDependency(
    SystemDependencyConsent consent,
  );

  Future<ContextPlan> getEngineRecommendation(
    String modelId, {
    EngineConfig? config,
  });

  Future<RemoteCodeApproval> approveRemoteCode(String modelId);

  Future<List<EngineInstance>> getEngineInstances();

  Future<EngineMutationResult> createEngineInstance({
    required String modelId,
    String? servedModelName,
    required EngineConfig config,
  });

  Future<EngineInstance> getEngineInstance(String instanceId);

  Future<EngineEnsureReadyResult> ensureEngineInstanceReady(String instanceId);

  /// Authenticated server-sent events for immediate engine state changes.
  Stream<EngineStreamEvent> streamEngineEvents();

  Future<EngineMutationResult> updateEngineInstance(
    String instanceId,
    Map<String, dynamic> changes,
  );

  Future<EngineMutationResult> deleteEngineInstance(String instanceId);

  Future<EngineOperation> getEngineOperation(String operationId);

  Future<EngineOperation> cancelEngineOperation(String operationId);
}
