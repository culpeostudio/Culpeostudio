import 'package:flutter/foundation.dart';

import '../modules/login/login_api.dart';
import '../modules/benchmark/benchmark_api.dart';
import '../modules/engine/engine_api.dart';
import '../modules/engine/engine_grpc_api.dart';
import '../modules/engine/models.dart';
import '../modules/marketplace/marketplace_api.dart';
import '../modules/news/news_api.dart';
import '../modules/nodes/node_api.dart';
import '../modules/scout/scout_api.dart';
import '../modules/settings/settings_api.dart';
import '../modules/spark/spark_api.dart';
import './api_client.dart';

export '../modules/engine/engine_api.dart' show EngineStreamEvent;
export './api_client.dart' show ApiException, ScoutStreamEvent;

/// Holds the shared connection and hands out one API per module. It stays the
/// single entry point, so a screen reaches its own module through it, e.g.
/// `ApiService().spark.listProjects()`.
class ApiService implements EngineApi {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();
  ApiService.test();

  final ApiClient client = ApiClient();

  late final LoginApi _login = LoginApi(client);
  LoginApi? _loginOverride;

  LoginApi get login => _loginOverride ?? _login;

  /// Replaces a module API with a stand-in. Widget tests run under fake async,
  /// where a real backend connection never completes, so they swap the API
  /// itself rather than the transport underneath it.
  @visibleForTesting
  void debugSetLoginApi(LoginApi api) => _loginOverride = api;
  late final EngineGrpcApi engine = EngineGrpcApi(client);
  late final ScoutApi _scoutApi = ScoutApi(client);
  ScoutApi get scout => _scoutApi;
  late final SparkApi spark = SparkApi(client);
  late final MarketplaceApi _marketplaceApi = MarketplaceApi(client);
  MarketplaceApi? _marketplaceOverride;

  MarketplaceApi get marketplace => _marketplaceOverride ?? _marketplaceApi;

  @visibleForTesting
  void debugSetMarketplaceApi(MarketplaceApi api) => _marketplaceOverride = api;
  late final SettingsApi settings = SettingsApi(client);
  late final NewsApi news = NewsApi(client);
  late final NodeApi nodes = NodeApi(client);
  late final BenchmarkApi benchmark = BenchmarkApi(client);

  String get baseUrl => client.baseUrl;
  set baseUrl(String value) => client.baseUrl = value;

  String? get token => client.token;
  set token(String? value) => client.token = value;

  String? get username => client.username;
  set username(String? value) => client.username = value;

  void Function()? get onSessionExpired => client.onSessionExpired;
  set onSessionExpired(void Function()? value) =>
      client.onSessionExpired = value;

  @override
  Future<List<ModelRecord>> getEngineModels() => engine.getEngineModels();

  @override
  Future<List<ModelRecord>> rescanEngineModels() => engine.rescanEngineModels();

  @override
  Future<List<ModelRecord>> deleteEngineModel(String modelId) =>
      engine.deleteEngineModel(modelId);

  @override
  Future<EngineCapabilities> getEngineCapabilities() =>
      engine.getEngineCapabilities();

  @override
  Future<List<RuntimeCapability>> getEngineRuntimes() =>
      engine.getEngineRuntimes();

  @override
  Future<EngineMutationResult> installEngineRuntime(String runtimeId) =>
      engine.installEngineRuntime(runtimeId);

  @override
  Future<ContextPlan> getEngineRecommendation(
    String modelId, {
    EngineConfig? config,
  }) => engine.getEngineRecommendation(modelId, config: config);

  @override
  Future<List<EngineInstance>> getEngineInstances() =>
      engine.getEngineInstances();

  @override
  Future<EngineMutationResult> createEngineInstance({
    required String modelId,
    String? servedModelName,
    required EngineConfig config,
  }) => engine.createEngineInstance(
    modelId: modelId,
    servedModelName: servedModelName,
    config: config,
  );

  @override
  Future<EngineInstance> getEngineInstance(String instanceId) =>
      engine.getEngineInstance(instanceId);

  @override
  Future<EngineEnsureReadyResult> ensureEngineInstanceReady(
    String instanceId,
  ) => engine.ensureEngineInstanceReady(instanceId);

  @override
  Stream<EngineStreamEvent> streamEngineEvents() => engine.streamEngineEvents();

  @override
  Future<EngineMutationResult> updateEngineInstance(
    String instanceId,
    Map<String, dynamic> changes,
  ) => engine.updateEngineInstance(instanceId, changes);

  @override
  Future<EngineMutationResult> deleteEngineInstance(String instanceId) =>
      engine.deleteEngineInstance(instanceId);

  @override
  Future<EngineOperation> getEngineOperation(String operationId) =>
      engine.getEngineOperation(operationId);

  @override
  Future<EngineOperation> cancelEngineOperation(String operationId) =>
      engine.cancelEngineOperation(operationId);

  @override
  Future<InstanceLogs> getEngineInstanceLogs(
    String instanceId, {
    int tailLines = 0,
  }) => engine.getEngineInstanceLogs(instanceId, tailLines: tailLines);

  @override
  Future<QuantizationCatalog> getQuantizationTypes() =>
      engine.getQuantizationTypes();

  @override
  Future<QuantizationPreflight> preflightQuantization(QuantizationJob job) =>
      engine.preflightQuantization(job);

  @override
  Future<EngineQuantizationStart> startQuantization(QuantizationJob job) =>
      engine.startQuantization(job);

  @override
  Future<List<EnginePreset>> getEnginePresets() => engine.getEnginePresets();

  @override
  Future<EnginePreset> saveEnginePreset({
    String id = '',
    required String name,
    String description = '',
    required EngineConfig config,
    String modelId = '',
  }) => engine.saveEnginePreset(
    id: id,
    name: name,
    description: description,
    config: config,
    modelId: modelId,
  );

  @override
  Future<void> deleteEnginePreset(String presetId) =>
      engine.deleteEnginePreset(presetId);

  @override
  Future<EnginePresetExport> exportEnginePresets([
    List<String> presetIds = const [],
  ]) => engine.exportEnginePresets(presetIds);

  @override
  Future<List<EnginePreset>> importEnginePresets(String document) =>
      engine.importEnginePresets(document);
}
