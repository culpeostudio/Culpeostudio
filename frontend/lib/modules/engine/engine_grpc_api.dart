import 'package:grpc/grpc.dart';
import 'package:protobuf/protobuf.dart';
import 'package:protobuf/well_known_types/google/protobuf/struct.pb.dart'
    as structpb;

import '../../core/api_client.dart';
import '../../generated/culpeostudio/engine/v1/engine.pbgrpc.dart' as pb;
import './engine_api.dart';
import './models.dart';

/// Every enum prefix the engine schema uses. Proto3 JSON writes an enum as its
/// declared name, so `OPERATION_STATE_COMPLETED` would reach a model that
/// compares against `completed` and never match. Stripping the prefix restores
/// the spelling the models and widgets were written for.
const List<String> _enumPrefixes = [
  'RUNTIME_KIND_',
  'CONTEXT_MODE_',
  'PRIORITY_',
  'KV_CACHE_POLICY_',
  'KV_CACHE_DTYPE_',
  'INSTANCE_STATE_',
  'OPERATION_STATE_',
  'PLACEMENT_',
  'GUARD_STATE_',
  'MODEL_FORMAT_',
  'MODEL_STATUS_',
  'ISSUE_SEVERITY_',
  'CHANGE_MODE_',
  'CONFIDENCE_',
];

/// Rewrites the enum names in a decoded message so the existing model parsers
/// keep working. `_UNSPECIFIED` becomes an empty string, which is what an
/// omitted field used to be and what the models already default from.
dynamic _normalizeEnums(dynamic value) {
  if (value is Map) {
    return value.map(
      (key, item) => MapEntry(key.toString(), _normalizeEnums(item)),
    );
  }
  if (value is List) {
    return value.map(_normalizeEnums).toList();
  }
  if (value is String) {
    for (final prefix in _enumPrefixes) {
      if (!value.startsWith(prefix)) continue;
      final rest = value.substring(prefix.length);
      return rest == 'UNSPECIFIED' ? '' : rest.toLowerCase();
    }
  }
  return value;
}

Map<String, dynamic> _decode(GeneratedMessage? message) {
  if (message == null) return <String, dynamic>{};
  final decoded = _normalizeEnums(message.toProto3Json());
  return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
}

structpb.Struct _toStruct(Map<String, dynamic>? value) {
  final struct = structpb.Struct();
  if (value != null && value.isNotEmpty) {
    struct.mergeFromProto3Json(value);
  }
  return struct;
}

Map<String, dynamic> _fromStruct(structpb.Struct? struct) {
  if (struct == null) return <String, dynamic>{};
  final decoded = struct.toProto3Json();
  return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
}

T _enumOr<T extends ProtobufEnum>(
  List<T> values,
  String prefix,
  String raw,
  T fallback,
) {
  final wanted = '$prefix${raw.trim().toUpperCase()}';
  for (final value in values) {
    if (value.name == wanted) return value;
  }
  return fallback;
}

pb.EngineConfig _configToProto(EngineConfig config) {
  final message = pb.EngineConfig(
    runtime: _enumOr(
      pb.RuntimeKind.values,
      'RUNTIME_KIND_',
      config.runtime,
      pb.RuntimeKind.RUNTIME_KIND_UNSPECIFIED,
    ),
    contextMode: _enumOr(
      pb.ContextMode.values,
      'CONTEXT_MODE_',
      config.contextMode,
      pb.ContextMode.CONTEXT_MODE_UNSPECIFIED,
    ),
    maxSequences: config.maxSequences,
    priority: _enumOr(
      pb.Priority.values,
      'PRIORITY_',
      config.priority,
      pb.Priority.PRIORITY_UNSPECIFIED,
    ),
    kvCachePolicy: _enumOr(
      pb.KvCachePolicy.values,
      'KV_CACHE_POLICY_',
      config.kvCachePolicy,
      pb.KvCachePolicy.KV_CACHE_POLICY_UNSPECIFIED,
    ),
    autostart: config.autostart,
    gatewayAutostart: config.gatewayAutostart,
    restartOnCrash: config.restartOnCrash,
    runtimeOptions: _toStruct(config.runtimeOptions),
    generationDefaults: _toStruct(config.generationDefaults),
  );
  // Both are optional in the schema: leaving them unset asks for the planner's
  // choice rather than sending a zero the engine would take literally.
  final contextTokens = config.contextTokens;
  if (contextTokens != null && contextTokens > 0) {
    message.contextTokens = contextTokens;
  }
  message.allowFallback = config.allowFallback;
  // Left unset the engine applies its own idle timeout; a negative value is how
  // "keep it loaded until I stop it" is expressed, so it must survive as-is
  // rather than being clamped to zero.
  final idleTimeout = config.idleTimeoutSeconds;
  if (idleTimeout != null) {
    message.idleTimeoutSeconds = idleTimeout;
  }
  return message;
}

pb.QuantizationRequest _quantizationRequest(QuantizationJob job) {
  final request = pb.QuantizationRequest(
    sourceModelId: job.sourceModelId,
    targetType: job.targetType,
    allowRequantize: job.allowRequantize,
    leaveOutputTensor: job.leaveOutputTensor,
  );
  final name = job.targetName.trim();
  if (name.isNotEmpty) request.targetName = name;
  if (job.threads > 0) request.threads = job.threads;
  return request;
}

pb.EngineConfig _configFromMap(Map<String, dynamic> value) =>
    _configToProto(EngineConfig.fromJson(value));

/// Maps a gRPC status onto the HTTP status the screens still branch on, and
/// pulls the engine's own error code out of the status detail so the remote
/// code consent dialog still recognises its case.
EngineApiException _engineError(GrpcError error) {
  const codes = {
    StatusCode.invalidArgument: 400,
    StatusCode.unauthenticated: 401,
    StatusCode.permissionDenied: 403,
    StatusCode.notFound: 404,
    StatusCode.alreadyExists: 409,
    StatusCode.failedPrecondition: 409,
    StatusCode.resourceExhausted: 429,
    StatusCode.unavailable: 503,
    StatusCode.deadlineExceeded: 504,
  };

  String? code;
  var details = <String, dynamic>{};
  for (final detail in error.details ?? const <GeneratedMessage>[]) {
    if (detail is pb.EngineError) {
      code = detail.code;
      details = _decode(detail);
      break;
    }
  }

  return EngineApiException(
    error.message ?? error.codeName,
    statusCode: codes[error.code] ?? 500,
    code: code,
    details: details,
  );
}

Future<T> _call<T>(Future<T> Function() body) async {
  try {
    return await body();
  } on GrpcError catch (error) {
    throw _engineError(error);
  }
}

/// The engine over gRPC. Results are handed to the existing model parsers, so
/// the screens keep the shapes they were built against.
class EngineGrpcApi implements EngineApi {
  EngineGrpcApi(this._c);

  final ApiClient _c;

  pb.EngineServiceClient get _client => _c.engineClient;

  List<ModelRecord> _models(List<pb.ModelRecord> records) =>
      records.map((record) => ModelRecord.fromJson(_decode(record))).toList();

  @override
  Future<List<ModelRecord>> getEngineModels() => _call(() async {
    final response = await _client.listModels(pb.ListModelsRequest());
    return _models(response.models);
  });

  @override
  Future<List<ModelRecord>> rescanEngineModels() => _call(() async {
    final response = await _client.rescanModels(pb.RescanModelsRequest());
    return _models(response.models);
  });

  @override
  Future<List<ModelRecord>> deleteEngineModel(String modelId) =>
      _call(() async {
        final response = await _client.deleteModel(
          pb.DeleteModelRequest(modelId: modelId),
        );
        return _models(response.models);
      });

  @override
  Future<EngineCapabilities> getEngineCapabilities() => _call(() async {
    final response = await _client.getCapabilities(pb.GetCapabilitiesRequest());
    return EngineCapabilities.fromJson(_decode(response));
  });

  @override
  Future<List<RuntimeCapability>> getEngineRuntimes() => _call(() async {
    final response = await _client.listRuntimes(pb.ListRuntimesRequest());
    return response.runtimes
        .map((runtime) => RuntimeCapability.fromJson(_decode(runtime)))
        .toList();
  });

  @override
  Future<EngineMutationResult> installEngineRuntime(String runtimeId) =>
      _call(() async {
        final response = await _client.installRuntime(
          pb.InstallRuntimeRequest(
            runtime: _enumOr(
              pb.RuntimeKind.values,
              'RUNTIME_KIND_',
              runtimeId,
              pb.RuntimeKind.RUNTIME_KIND_UNSPECIFIED,
            ),
          ),
        );
        return EngineMutationResult.fromJson(_decode(response));
      });

  @override
  Future<ContextPlan> getEngineRecommendation(
    String modelId, {
    EngineConfig? config,
  }) => _call(() async {
    final request = pb.GetRecommendationRequest(modelId: modelId);
    if (config != null) request.config = _configToProto(config);
    final response = await _client.getRecommendation(request);
    return ContextPlan.fromJson(_decode(response.plan));
  });

  @override
  Future<List<EngineInstance>> getEngineInstances() => _call(() async {
    final response = await _client.listInstances(pb.ListInstancesRequest());
    return response.instances
        .map((instance) => EngineInstance.fromJson(_decode(instance)))
        .toList();
  });

  @override
  Future<EngineMutationResult> createEngineInstance({
    required String modelId,
    String? servedModelName,
    required EngineConfig config,
  }) => _call(() async {
    final request = pb.CreateInstanceRequest(
      modelId: modelId,
      config: _configToProto(config),
    );
    final name = servedModelName?.trim() ?? '';
    if (name.isNotEmpty) request.servedModelName = name;
    final response = await _client.createInstance(request);
    return EngineMutationResult.fromJson(_decode(response));
  });

  @override
  Future<EngineInstance> getEngineInstance(String instanceId) =>
      _call(() async {
        final response = await _client.getInstance(
          pb.GetInstanceRequest(instanceId: instanceId),
        );
        return EngineInstance.fromJson(_decode(response.instance));
      });

  @override
  Future<EngineEnsureReadyResult> ensureEngineInstanceReady(
    String instanceId,
  ) => _call(() async {
    final response = await _client.ensureInstanceReady(
      pb.EnsureInstanceReadyRequest(instanceId: instanceId),
    );
    return EngineEnsureReadyResult.fromJson(_decode(response));
  });

  @override
  Future<EngineMutationResult> updateEngineInstance(
    String instanceId,
    Map<String, dynamic> changes,
  ) => _call(() async {
    final response = await _client.updateInstance(
      _updateRequest(instanceId, changes),
    );
    return EngineMutationResult.fromJson(_decode(response));
  });

  /// Translates the free-form patch the screens build into the one change the
  /// schema carries. Anything unrecognised is refused rather than silently
  /// doing nothing, because a dropped patch looks like a backend that ignored
  /// the user.
  pb.UpdateInstanceRequest _updateRequest(
    String instanceId,
    Map<String, dynamic> changes,
  ) {
    final request = pb.UpdateInstanceRequest(instanceId: instanceId);
    final action = (changes['action'] ?? '').toString().trim();
    final rawConfig = changes['requested_config'];

    if (changes.containsKey('show_in_chat_picker')) {
      request.visibility = pb.SetVisibility(
        showInChatPicker: changes['show_in_chat_picker'] == true,
      );
      return request;
    }
    if (changes.containsKey('generation_defaults') && action.isEmpty) {
      request.generationDefaults = pb.SetGenerationDefaults(
        generationDefaults: _toStruct(
          Map<String, dynamic>.from(changes['generation_defaults'] as Map),
        ),
      );
      return request;
    }

    switch (action) {
      case 'start':
      case 'restart':
        final start = pb.StartInstance(restart: action == 'restart');
        if (rawConfig is Map) {
          start.requestedConfig = _configFromMap(
            Map<String, dynamic>.from(rawConfig),
          );
        }
        request.start = start;
        return request;
      case 'stop':
        request.stop = pb.StopInstance();
        return request;
      case 'apply_fix':
        request.applyFix = pb.ApplyFix(fix: (changes['fix'] ?? '').toString());
        return request;
    }

    if (rawConfig is Map) {
      request.requestedConfig = pb.SetRequestedConfig(
        requestedConfig: _configFromMap(Map<String, dynamic>.from(rawConfig)),
      );
      return request;
    }

    throw EngineApiException(
      'Unbekannte Instanzänderung: ${changes.keys.join(', ')}',
      statusCode: 400,
    );
  }

  @override
  Future<EngineMutationResult> deleteEngineInstance(String instanceId) =>
      _call(() async {
        final response = await _client.deleteInstance(
          pb.DeleteInstanceRequest(instanceId: instanceId),
        );
        return EngineMutationResult.fromJson(_decode(response));
      });

  @override
  Future<EngineOperation> getEngineOperation(String operationId) =>
      _call(() async {
        final response = await _client.getOperation(
          pb.GetOperationRequest(operationId: operationId),
        );
        return EngineOperation.fromJson(_decode(response.operation));
      });

  @override
  Future<EngineOperation> cancelEngineOperation(String operationId) =>
      _call(() async {
        final response = await _client.cancelOperation(
          pb.CancelOperationRequest(operationId: operationId),
        );
        return EngineOperation.fromJson(_decode(response.operation));
      });

  @override
  Future<InstanceLogs> getEngineInstanceLogs(
    String instanceId, {
    int tailLines = 0,
  }) => _call(() async {
    final response = await _client.getInstanceLogs(
      pb.GetInstanceLogsRequest(instanceId: instanceId, tailLines: tailLines),
    );
    return InstanceLogs.fromJson(_decode(response));
  });

  @override
  Future<QuantizationCatalog> getQuantizationTypes() => _call(() async {
    final response = await _client.listQuantizationTypes(
      pb.ListQuantizationTypesRequest(),
    );
    return QuantizationCatalog.fromJson(_decode(response));
  });

  @override
  Future<QuantizationPreflight> preflightQuantization(QuantizationJob job) =>
      _call(() async {
        final response = await _client.preflightQuantization(
          pb.PreflightQuantizationRequest(request: _quantizationRequest(job)),
        );
        return QuantizationPreflight.fromJson(_decode(response.preflight));
      });

  @override
  Future<EngineQuantizationStart> startQuantization(QuantizationJob job) =>
      _call(() async {
        final response = await _client.startQuantization(
          pb.StartQuantizationRequest(request: _quantizationRequest(job)),
        );
        final decoded = _decode(response);
        return EngineQuantizationStart(
          operationId: (decoded['operationId'] ?? decoded['operation_id'] ?? '')
              .toString(),
          state: (decoded['state'] ?? '').toString(),
          preflight: QuantizationPreflight.fromJson(response.preflight),
        );
      });

  @override
  Future<List<EnginePreset>> getEnginePresets() => _call(() async {
    final response = await _client.listPresets(pb.ListPresetsRequest());
    return response.presets
        .map((preset) => EnginePreset.fromJson(_decode(preset)))
        .toList();
  });

  @override
  Future<EnginePreset> saveEnginePreset({
    String id = '',
    required String name,
    String description = '',
    required EngineConfig config,
    String modelId = '',
  }) => _call(() async {
    final preset = pb.EnginePreset(
      name: name,
      description: description,
      config: _configToProto(config),
    );
    if (id.trim().isNotEmpty) preset.id = id.trim();
    if (modelId.trim().isNotEmpty) preset.modelId = modelId.trim();
    final response = await _client.savePreset(
      pb.SavePresetRequest(preset: preset),
    );
    return EnginePreset.fromJson(_decode(response.preset));
  });

  @override
  Future<void> deleteEnginePreset(String presetId) => _call(() async {
    await _client.deletePreset(pb.DeletePresetRequest(presetId: presetId));
  });

  @override
  Future<EnginePresetExport> exportEnginePresets([
    List<String> presetIds = const [],
  ]) => _call(() async {
    final response = await _client.exportPresets(
      pb.ExportPresetsRequest(presetIds: presetIds),
    );
    return EnginePresetExport.fromJson(_decode(response));
  });

  @override
  Future<List<EnginePreset>> importEnginePresets(String document) =>
      _call(() async {
        final response = await _client.importPresets(
          pb.ImportPresetsRequest(document: document),
        );
        return response.presets
            .map((preset) => EnginePreset.fromJson(_decode(preset)))
            .toList();
      });

  /// Reads the engine feed. The ticket dance is gone: a gRPC stream carries the
  /// session token like any other call.
  @override
  Stream<EngineStreamEvent> streamEngineEvents() async* {
    final stream = _client.streamEvents(pb.StreamEventsRequest());
    try {
      await for (final entry in stream) {
        final event = _streamEvent(entry);
        if (event != null) yield event;
      }
    } on GrpcError catch (error) {
      // The unary interceptor cannot see a stream, so an expired session has
      // to be reported from here.
      _c.reportGrpcError(error);
      throw _engineError(error);
    }
  }

  EngineStreamEvent? _streamEvent(pb.StreamEventsResponse entry) {
    final timestamp = entry.hasTimestamp()
        ? entry.timestamp.toDateTime()
        : null;

    EngineStreamEvent build(String type, Map<String, dynamic> data) =>
        EngineStreamEvent(type: type, data: data, timestamp: timestamp);

    switch (entry.whichEvent()) {
      case pb.StreamEventsResponse_Event.snapshot:
        return build('snapshot', _decode(entry.snapshot));
      case pb.StreamEventsResponse_Event.instanceCreated:
        return build('instance_created', _decode(entry.instanceCreated));
      case pb.StreamEventsResponse_Event.instanceChanged:
        return build('instance_changed', _decode(entry.instanceChanged));
      case pb.StreamEventsResponse_Event.instanceDeleted:
        return build('instance_deleted', _decode(entry.instanceDeleted));
      case pb.StreamEventsResponse_Event.operation:
        return build('operation', _decode(entry.operation));
      case pb.StreamEventsResponse_Event.modelsRescanned:
        return build('models_rescanned', _decode(entry.modelsRescanned));
      case pb.StreamEventsResponse_Event.modelDeleted:
        return build('model_deleted', _decode(entry.modelDeleted));
      case pb.StreamEventsResponse_Event.guardState:
        return build('guard_state', _decode(entry.guardState));
      case pb.StreamEventsResponse_Event.generic:
        return build(entry.generic.type, _fromStruct(entry.generic.data));
      case pb.StreamEventsResponse_Event.notSet:
        return null;
    }
  }
}
