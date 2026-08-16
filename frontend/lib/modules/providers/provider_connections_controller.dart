import 'package:flutter/foundation.dart';

import 'provider_api.dart';

/// Presentation state for [ProviderConnectionsPanel].
///
/// The controller keeps only public connection metadata and discovered model
/// information.  API keys are write-only request values and are intentionally
/// absent from this state object.
class ProviderConnectionsController extends ChangeNotifier {
  ProviderConnectionsController(this.api);

  final ProviderApi api;

  List<ProviderPreset> presets = const [];
  List<ProviderConnection> connections = const [];
  List<ActiveProviderModel> activeModels = const [];
  final Map<String, List<ProviderModel>> modelsByConnection = {};
  final Set<String> syncingConnectionIds = {};
  final Set<String> testingConnectionIds = {};
  final Set<String> activatingModelKeys = {};

  bool isLoading = false;
  String? loadError;
  String? lastActionError;
  bool _disposed = false;

  Future<void> load() async {
    if (isLoading) return;
    isLoading = true;
    loadError = null;
    _notify();

    final errors = <String>[];
    await Future.wait<void>([
      _loadPresets(errors),
      _loadConnections(errors),
      _loadActiveModels(errors),
    ]);

    if (errors.isNotEmpty) loadError = errors.first;
    isLoading = false;
    _notify();
  }

  Future<void> _loadPresets(List<String> errors) async {
    try {
      presets = List<ProviderPreset>.unmodifiable(await api.listPresets());
    } catch (error) {
      errors.add(_message(error));
    }
  }

  Future<void> _loadConnections(List<String> errors) async {
    try {
      connections = List<ProviderConnection>.unmodifiable(
        await api.listConnections(),
      );
    } catch (error) {
      errors.add(_message(error));
    }
  }

  Future<void> _loadActiveModels(List<String> errors) async {
    try {
      activeModels = List<ActiveProviderModel>.unmodifiable(
        await api.listActiveModels(),
      );
    } catch (error) {
      errors.add(_message(error));
    }
  }

  Future<SaveProviderConnectionResult?> saveConnection({
    String id = '',
    required String presetId,
    required String name,
    required ProviderConnectionProtocol protocol,
    required String baseUrl,
    String? apiKey,
    bool clearApiKey = false,
    bool enabled = true,
    bool syncModels = true,
  }) async {
    lastActionError = null;
    _notify();
    try {
      final result = await api.saveConnection(
        id: id,
        presetId: presetId,
        name: name,
        protocol: protocol,
        baseUrl: baseUrl,
        apiKey: apiKey,
        clearApiKey: clearApiKey,
        enabled: enabled,
        syncModels: syncModels,
      );
      _upsertConnection(result.connection);
      if (result.models.isNotEmpty || syncModels) {
        modelsByConnection[result.connection.id] =
            List<ProviderModel>.unmodifiable(result.models);
      }
      if (result.syncError.isNotEmpty) lastActionError = result.syncError;
      _notify();
      return result;
    } catch (error) {
      lastActionError = _message(error);
      _notify();
      return null;
    }
  }

  Future<bool> deleteConnection(String connectionId) async {
    lastActionError = null;
    _notify();
    try {
      await api.deleteConnection(connectionId);
      connections = List<ProviderConnection>.unmodifiable(
        connections.where((connection) => connection.id != connectionId),
      );
      activeModels = List<ActiveProviderModel>.unmodifiable(
        activeModels.where((model) => model.connectionId != connectionId),
      );
      modelsByConnection.remove(connectionId);
      _notify();
      return true;
    } catch (error) {
      lastActionError = _message(error);
      _notify();
      return false;
    }
  }

  Future<ProviderConnectionTest?> testConnection(String connectionId) async {
    testingConnectionIds.add(connectionId);
    lastActionError = null;
    _notify();
    try {
      return await api.testConnection(connectionId);
    } catch (error) {
      lastActionError = _message(error);
      return null;
    } finally {
      testingConnectionIds.remove(connectionId);
      _notify();
    }
  }

  Future<ProviderModelSync?> syncConnection(String connectionId) async {
    syncingConnectionIds.add(connectionId);
    lastActionError = null;
    _notify();
    try {
      final result = await api.syncConnectionModels(connectionId);
      _upsertConnection(result.connection);
      modelsByConnection[connectionId] = List<ProviderModel>.unmodifiable(
        result.models,
      );
      _notify();
      return result;
    } catch (error) {
      lastActionError = _message(error);
      _notify();
      return null;
    } finally {
      syncingConnectionIds.remove(connectionId);
      _notify();
    }
  }

  Future<ProviderModelSync?> loadModels(String connectionId) async {
    if (modelsByConnection.containsKey(connectionId)) {
      final connection = connectionForId(connectionId);
      if (connection != null) {
        return ProviderModelSync(
          connection: connection,
          models: modelsByConnection[connectionId]!,
        );
      }
    }

    syncingConnectionIds.add(connectionId);
    lastActionError = null;
    _notify();
    try {
      final result = await api.listConnectionModels(connectionId);
      _upsertConnection(result.connection);
      modelsByConnection[connectionId] = List<ProviderModel>.unmodifiable(
        result.models,
      );
      _notify();
      return result;
    } catch (error) {
      lastActionError = _message(error);
      _notify();
      return null;
    } finally {
      syncingConnectionIds.remove(connectionId);
      _notify();
    }
  }

  Future<ActiveProviderModel?> activateModel({
    required String connectionId,
    required ProviderModel model,
  }) async {
    final key = '$connectionId:${model.id}';
    activatingModelKeys.add(key);
    lastActionError = null;
    _notify();
    try {
      final active = await api.activateModel(
        connectionId: connectionId,
        modelId: model.id,
        displayName: model.displayName,
      );
      final remaining =
          activeModels
              .where((current) => current.modelRef != active.modelRef)
              .toList(growable: true)
            ..add(active);
      activeModels = List<ActiveProviderModel>.unmodifiable(remaining);
      _notify();
      return active;
    } catch (error) {
      lastActionError = _message(error);
      _notify();
      return null;
    } finally {
      activatingModelKeys.remove(key);
      _notify();
    }
  }

  Future<bool> deactivateModel(String modelRef) async {
    lastActionError = null;
    _notify();
    try {
      await api.deleteActiveModel(modelRef);
      activeModels = List<ActiveProviderModel>.unmodifiable(
        activeModels.where((model) => model.modelRef != modelRef),
      );
      _notify();
      return true;
    } catch (error) {
      lastActionError = _message(error);
      _notify();
      return false;
    }
  }

  ProviderConnection? connectionForId(String id) {
    for (final connection in connections) {
      if (connection.id == id) return connection;
    }
    return null;
  }

  ActiveProviderModel? activeModelFor({
    required String connectionId,
    required String modelId,
  }) {
    for (final model in activeModels) {
      if (model.connectionId == connectionId && model.modelId == modelId) {
        return model;
      }
    }
    return null;
  }

  bool isActivating(String connectionId, String modelId) =>
      activatingModelKeys.contains('$connectionId:$modelId');

  void _upsertConnection(ProviderConnection connection) {
    final updated =
        connections
            .where((current) => current.id != connection.id)
            .toList(growable: true)
          ..add(connection);
    updated.sort((first, second) => first.name.compareTo(second.name));
    connections = List<ProviderConnection>.unmodifiable(updated);
  }

  String _message(Object error) =>
      error is ProviderApiException ? error.message : error.toString();

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
