import '../../core/api_client.dart';
import '../../generated/culpeostudio/providers/v1/providers.pbgrpc.dart'
    as providerpb;

/// The three wire protocols the backend currently knows how to discover and
/// stream.  Vendors are deliberately represented by presets, rather than by
/// this enum, so an OpenAI-compatible provider does not require a Flutter
/// release of its own.
enum ProviderConnectionProtocol {
  openAiCompatible,
  anthropicMessages,
  googleGenAi,
}

extension ProviderConnectionProtocolLabel on ProviderConnectionProtocol {
  String get label => switch (this) {
    ProviderConnectionProtocol.openAiCompatible => 'OpenAI-kompatibel',
    ProviderConnectionProtocol.anthropicMessages => 'Anthropic Messages',
    ProviderConnectionProtocol.googleGenAi => 'Google GenAI',
  };
}

/// A deliberately small exception boundary for the feature.  The UI can show
/// the gRPC error without needing to understand generated transport types.
class ProviderApiException implements Exception {
  const ProviderApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ProviderPreset {
  const ProviderPreset({
    required this.id,
    required this.name,
    required this.description,
    required this.protocol,
    required this.defaultBaseUrl,
    required this.documentationUrl,
    required this.apiKeyRequired,
    required this.available,
    required this.unavailableReason,
    required this.localOnly,
  });

  final String id;
  final String name;
  final String description;
  final ProviderConnectionProtocol protocol;
  final String defaultBaseUrl;
  final String documentationUrl;
  final bool apiKeyRequired;
  final bool available;
  final String unavailableReason;
  final bool localOnly;
}

class ProviderConnection {
  const ProviderConnection({
    required this.id,
    required this.presetId,
    required this.name,
    required this.protocol,
    required this.baseUrl,
    required this.apiKeySet,
    required this.enabled,
    required this.modelCount,
    required this.lastSyncedAt,
    required this.lastSyncError,
    required this.chatSupported,
    required this.stale,
    required this.providerLabel,
  });

  final String id;
  final String presetId;
  final String name;
  final ProviderConnectionProtocol protocol;
  final String baseUrl;

  /// This is the only key-related value ever returned by the server.  The API
  /// key itself is write-only and never enters app state or local storage.
  final bool apiKeySet;
  final bool enabled;
  final int modelCount;
  final DateTime? lastSyncedAt;
  final String lastSyncError;
  final bool chatSupported;
  final bool stale;
  final String providerLabel;

  ProviderConnection copyWith({
    String? id,
    String? presetId,
    String? name,
    ProviderConnectionProtocol? protocol,
    String? baseUrl,
    bool? apiKeySet,
    bool? enabled,
    int? modelCount,
    DateTime? lastSyncedAt,
    String? lastSyncError,
    bool? chatSupported,
    bool? stale,
    String? providerLabel,
  }) {
    return ProviderConnection(
      id: id ?? this.id,
      presetId: presetId ?? this.presetId,
      name: name ?? this.name,
      protocol: protocol ?? this.protocol,
      baseUrl: baseUrl ?? this.baseUrl,
      apiKeySet: apiKeySet ?? this.apiKeySet,
      enabled: enabled ?? this.enabled,
      modelCount: modelCount ?? this.modelCount,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      lastSyncError: lastSyncError ?? this.lastSyncError,
      chatSupported: chatSupported ?? this.chatSupported,
      stale: stale ?? this.stale,
      providerLabel: providerLabel ?? this.providerLabel,
    );
  }
}

class ProviderModel {
  const ProviderModel({
    required this.id,
    required this.displayName,
    required this.description,
    required this.contextWindow,
    required this.maxOutputTokens,
    required this.inputModalities,
    required this.outputModalities,
    required this.capabilities,
    required this.chatSupported,
    required this.deprecated,
    required this.discoveredAt,
  });

  final String id;
  final String displayName;
  final String description;
  final int contextWindow;
  final int maxOutputTokens;
  final List<String> inputModalities;
  final List<String> outputModalities;
  final List<String> capabilities;
  final bool chatSupported;
  final bool deprecated;
  final DateTime? discoveredAt;
}

class ActiveProviderModel {
  const ActiveProviderModel({
    required this.modelRef,
    required this.connectionId,
    required this.providerLabel,
    required this.providerId,
    required this.modelId,
    required this.displayName,
    required this.protocol,
    required this.activatedAt,
    required this.lastUsedAt,
  });

  final String modelRef;
  final String connectionId;
  final String providerLabel;
  final String providerId;
  final String modelId;
  final String displayName;
  final ProviderConnectionProtocol protocol;
  final DateTime? activatedAt;
  final DateTime? lastUsedAt;
}

class ProviderConnectionTest {
  const ProviderConnectionTest({
    required this.reachable,
    required this.message,
    required this.discoveredModelCount,
  });

  final bool reachable;
  final String message;
  final int discoveredModelCount;
}

class ProviderModelSync {
  const ProviderModelSync({required this.connection, required this.models});

  final ProviderConnection connection;
  final List<ProviderModel> models;
}

class SaveProviderConnectionResult {
  const SaveProviderConnectionResult({
    required this.connection,
    required this.models,
    required this.syncError,
  });

  final ProviderConnection connection;
  final List<ProviderModel> models;

  /// A connection is persisted even when the remote catalogue cannot be read.
  /// This message is intentionally separate from a transport failure.
  final String syncError;
}

/// Typed data boundary for the provider-connection gRPC service.
///
/// It never caches or exposes an API key.  [apiKey] is assigned directly to a
/// write-only protobuf field for one request, then discarded by the caller.
class ProviderApi {
  ProviderApi(this._client);

  final ApiClient _client;

  Future<List<ProviderPreset>> listPresets() => _guard(() async {
    final response = await _client.providersClient.listPresets(
      providerpb.ListPresetsRequest(),
    );
    return response.presets.map(_presetFromProto).toList(growable: false);
  });

  Future<List<ProviderConnection>> listConnections() => _guard(() async {
    final response = await _client.providersClient.listConnections(
      providerpb.ListConnectionsRequest(),
    );
    return response.connections
        .map(_connectionFromProto)
        .toList(growable: false);
  });

  Future<SaveProviderConnectionResult> saveConnection({
    String id = '',
    required String presetId,
    required String name,
    required ProviderConnectionProtocol protocol,
    required String baseUrl,
    String? apiKey,
    bool clearApiKey = false,
    bool enabled = true,
    bool syncModels = true,
  }) => _guard(() async {
    final request = providerpb.SaveConnectionRequest(
      id: id,
      presetId: presetId,
      name: name,
      protocol: _protocolToProto(protocol),
      baseUrl: baseUrl,
      // The generated Dart name has the field number suffix because the
      // protobuf field `clear_api_key` otherwise collides with the generated
      // `clearApiKey()` method for `api_key`.
      clearApiKey_7: clearApiKey,
      enabled: enabled,
      syncModels: syncModels,
    );
    if (apiKey != null) request.apiKey = apiKey;

    final response = await _client.providersClient.saveConnection(request);
    return SaveProviderConnectionResult(
      connection: _connectionFromProto(response.connection),
      models: response.models.map(_modelFromProto).toList(growable: false),
      syncError: response.syncError,
    );
  });

  Future<void> deleteConnection(String id) => _guard(() async {
    await _client.providersClient.deleteConnection(
      providerpb.DeleteConnectionRequest(id: id),
    );
  });

  Future<ProviderConnectionTest> testConnection(String id) => _guard(() async {
    final response = await _client.providersClient.testConnection(
      providerpb.TestConnectionRequest(id: id),
    );
    return ProviderConnectionTest(
      reachable: response.reachable,
      message: response.message,
      discoveredModelCount: response.discoveredModelCount,
    );
  });

  Future<ProviderModelSync> syncConnectionModels(String id) => _guard(() async {
    final response = await _client.providersClient.syncConnectionModels(
      providerpb.SyncConnectionModelsRequest(id: id),
    );
    return ProviderModelSync(
      connection: _connectionFromProto(response.connection),
      models: response.models.map(_modelFromProto).toList(growable: false),
    );
  });

  Future<ProviderModelSync> listConnectionModels(String connectionId) =>
      _guard(() async {
        final response = await _client.providersClient.listConnectionModels(
          providerpb.ListConnectionModelsRequest(connectionId: connectionId),
        );
        return ProviderModelSync(
          connection: _connectionFromProto(response.connection),
          models: response.models.map(_modelFromProto).toList(growable: false),
        );
      });

  Future<ActiveProviderModel> activateModel({
    required String connectionId,
    required String modelId,
    String displayName = '',
  }) => _guard(() async {
    final response = await _client.providersClient.activateModel(
      providerpb.ActivateModelRequest(
        connectionId: connectionId,
        modelId: modelId,
        displayName: displayName,
      ),
    );
    return _activeModelFromProto(response.model);
  });

  Future<List<ActiveProviderModel>> listActiveModels() => _guard(() async {
    final response = await _client.providersClient.listActiveModels(
      providerpb.ListActiveModelsRequest(),
    );
    return response.models.map(_activeModelFromProto).toList(growable: false);
  });

  Future<void> deleteActiveModel(String modelRef) => _guard(() async {
    await _client.providersClient.deleteActiveModel(
      providerpb.DeleteActiveModelRequest(modelRef: modelRef),
    );
  });

  Future<T> _guard<T>(Future<T> Function() request) async {
    try {
      return await request();
    } catch (error) {
      throw ProviderApiException(_client.grpcErrorMessage(error));
    }
  }

  ProviderPreset _presetFromProto(providerpb.ProviderPreset value) {
    return ProviderPreset(
      id: value.id,
      name: value.name,
      description: value.description,
      protocol: _protocolFromProto(value.protocol),
      defaultBaseUrl: value.defaultBaseUrl,
      documentationUrl: value.documentationUrl,
      apiKeyRequired: value.apiKeyRequired,
      available: value.available,
      unavailableReason: value.unavailableReason,
      localOnly: value.localOnly,
    );
  }

  ProviderConnection _connectionFromProto(providerpb.ProviderConnection value) {
    return ProviderConnection(
      id: value.id,
      presetId: value.presetId,
      name: value.name,
      protocol: _protocolFromProto(value.protocol),
      baseUrl: value.baseUrl,
      apiKeySet: value.apiKeySet,
      enabled: value.enabled,
      modelCount: value.modelCount,
      lastSyncedAt: value.hasLastSyncedAt()
          ? value.lastSyncedAt.toDateTime()
          : null,
      lastSyncError: value.lastSyncError,
      chatSupported: value.chatSupported,
      stale: value.stale,
      providerLabel: value.providerLabel,
    );
  }

  ProviderModel _modelFromProto(providerpb.ProviderModel value) {
    return ProviderModel(
      id: value.id,
      displayName: value.displayName,
      description: value.description,
      contextWindow: value.contextWindow,
      maxOutputTokens: value.maxOutputTokens,
      inputModalities: List<String>.unmodifiable(value.inputModalities),
      outputModalities: List<String>.unmodifiable(value.outputModalities),
      capabilities: List<String>.unmodifiable(value.capabilities),
      chatSupported: value.chatSupported,
      deprecated: value.deprecated,
      discoveredAt: value.hasDiscoveredAt()
          ? value.discoveredAt.toDateTime()
          : null,
    );
  }

  ActiveProviderModel _activeModelFromProto(
    providerpb.ActiveProviderModel value,
  ) {
    return ActiveProviderModel(
      modelRef: value.modelRef,
      connectionId: value.connectionId,
      providerLabel: value.providerLabel,
      providerId: value.providerId,
      modelId: value.modelId,
      displayName: value.displayName,
      protocol: _protocolFromProto(value.protocol),
      activatedAt: value.hasActivatedAt()
          ? value.activatedAt.toDateTime()
          : null,
      lastUsedAt: value.hasLastUsedAt() ? value.lastUsedAt.toDateTime() : null,
    );
  }

  ProviderConnectionProtocol _protocolFromProto(
    providerpb.ConnectionProtocol value,
  ) {
    return switch (value) {
      providerpb.ConnectionProtocol.CONNECTION_PROTOCOL_ANTHROPIC_MESSAGES =>
        ProviderConnectionProtocol.anthropicMessages,
      providerpb.ConnectionProtocol.CONNECTION_PROTOCOL_GOOGLE_GENAI =>
        ProviderConnectionProtocol.googleGenAi,
      providerpb.ConnectionProtocol.CONNECTION_PROTOCOL_OPENAI_COMPATIBLE ||
      providerpb.ConnectionProtocol.CONNECTION_PROTOCOL_UNSPECIFIED =>
        ProviderConnectionProtocol.openAiCompatible,
      _ => ProviderConnectionProtocol.openAiCompatible,
    };
  }

  providerpb.ConnectionProtocol _protocolToProto(
    ProviderConnectionProtocol value,
  ) {
    return switch (value) {
      ProviderConnectionProtocol.openAiCompatible =>
        providerpb.ConnectionProtocol.CONNECTION_PROTOCOL_OPENAI_COMPATIBLE,
      ProviderConnectionProtocol.anthropicMessages =>
        providerpb.ConnectionProtocol.CONNECTION_PROTOCOL_ANTHROPIC_MESSAGES,
      ProviderConnectionProtocol.googleGenAi =>
        providerpb.ConnectionProtocol.CONNECTION_PROTOCOL_GOOGLE_GENAI,
    };
  }
}
