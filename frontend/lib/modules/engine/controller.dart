import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/remaining_ui_strings.dart';
import './engine_api.dart';
import './models.dart';

class EngineController extends ChangeNotifier {
  EngineController(
    this.api, {
    this.eventReconnectDelay = const Duration(seconds: 2),
  });

  final EngineApi api;
  final Duration eventReconnectDelay;

  bool isLoading = false;
  bool isRescanning = false;
  bool isLoadingRecommendation = false;
  String? error;
  EngineApiException? requestFailure;
  String? selectedModelId;
  List<ModelRecord> models = const [];
  List<EngineInstance> instances = const [];
  List<RuntimeCapability> runtimes = const [];
  EngineCapabilities? capabilities;
  ContextPlan? recommendation;
  final Map<String, EngineOperation> operations = {};
  final Set<String> busyInstances = {};
  final Set<String> busyRuntimes = {};
  final Set<String> busyModels = {};
  bool isRepairingGpuRuntime = false;
  String? gpuRepairOperationId;
  bool _disposed = false;
  bool _eventRefreshInProgress = false;
  bool _eventRefreshPending = false;
  bool _eventRefreshModels = false;
  StreamSubscription<EngineStreamEvent>? _eventSubscription;
  Timer? _eventReconnectTimer;
  final Map<String, Completer<EngineOperation?>> _operationWaiters = {};
  final Set<String> _operationReconciliations = {};
  bool _hasSeenEventSnapshot = false;
  int _eventConnectionAttempts = 0;
  final List<EngineInstance> _readyAnnouncements = [];

  ModelRecord? get selectedModel {
    for (final model in models) {
      if (model.id == selectedModelId) return model;
    }
    return null;
  }

  void chooseModel(String modelId) {
    selectedModelId = modelId;
    recommendation = null;
    error = null;
    requestFailure = null;
    _notify();
  }

  Future<void> initialize() async {
    isLoading = true;
    error = null;
    requestFailure = null;
    _notify();
    final failures = <String>[];

    await Future.wait<void>([
      api.getEngineModels().then((value) => models = value).catchError((
        Object value,
      ) {
        failures.add(value.toString());
        return <ModelRecord>[];
      }),
      api.getEngineInstances().then((value) => instances = value).catchError((
        Object value,
      ) {
        failures.add(value.toString());
        return <EngineInstance>[];
      }),
      api
          .getEngineCapabilities()
          .then((value) => capabilities = value)
          .catchError((Object value) {
            failures.add(value.toString());
            return EngineCapabilities(
              hardware: const HardwareSnapshot(
                ramTotalBytes: 0,
                ramAvailableBytes: 0,
                gpus: [],
              ),
              runtimes: const [],
              defaults: const {},
            );
          }),
      api
          .getEngineRuntimes()
          .then((value) => runtimes = value)
          .catchError((Object _) => <RuntimeCapability>[]),
    ]);

    if (runtimes.isEmpty && capabilities != null) {
      runtimes = capabilities!.runtimes;
    }
    if (selectedModelId != null &&
        !models.any((model) => model.id == selectedModelId)) {
      selectedModelId = null;
      recommendation = null;
    }
    isLoading = false;
    if (failures.isNotEmpty) error = failures.first;
    _notify();
    _connectEngineEvents();
  }

  Future<bool> refreshInstances() async {
    try {
      _replaceInstances(
        await api.getEngineInstances(),
        announceReady: true,
        protectReadyFromStalePreparation: true,
      );
      error = null;
      _notify();
      return true;
    } catch (value) {
      error = value.toString();
      _notify();
      return false;
    }
  }

  Future<bool> refreshAll() async {
    isRescanning = true;
    error = null;
    requestFailure = null;
    _notify();
    final failures = <String>[];

    await Future.wait<void>([
      api
          .rescanEngineModels()
          .then<void>((value) => models = value)
          .catchError((Object value) => failures.add(value.toString())),
      api
          .getEngineInstances()
          .then<void>((value) => _replaceInstances(value, announceReady: true))
          .catchError((Object value) => failures.add(value.toString())),
      api
          .getEngineCapabilities()
          .then<void>((value) => capabilities = value)
          .catchError((Object value) => failures.add(value.toString())),
      api
          .getEngineRuntimes()
          .then<void>((value) => runtimes = value)
          .catchError((Object _) {}),
    ]);

    if (runtimes.isEmpty && capabilities != null) {
      runtimes = capabilities!.runtimes;
    }
    if (selectedModelId != null &&
        !models.any((model) => model.id == selectedModelId)) {
      selectedModelId = null;
      recommendation = null;
    }
    isRescanning = false;
    if (failures.isNotEmpty) error = failures.first;
    _notify();
    return failures.isEmpty;
  }

  Future<bool> selectModel(String modelId, {EngineConfig? config}) async {
    selectedModelId = modelId;
    recommendation = null;
    isLoadingRecommendation = true;
    error = null;
    requestFailure = null;
    _notify();
    try {
      recommendation = await api.getEngineRecommendation(
        modelId,
        config: config,
      );
      return true;
    } catch (value) {
      error = value.toString();
      requestFailure = value is EngineApiException ? value : null;
      return false;
    } finally {
      isLoadingRecommendation = false;
      _notify();
    }
  }

  Future<bool> refreshRecommendation(EngineConfig config) async {
    final modelId = selectedModelId;
    if (modelId == null) return false;
    return selectModel(modelId, config: config);
  }

  Future<bool> createInstance(EngineConfig config) async {
    final modelId = selectedModelId;
    if (modelId == null) return false;
    error = null;
    requestFailure = null;
    busyInstances.add('new');
    _notify();
    try {
      final result = await api.createEngineInstance(
        modelId: modelId,
        config: config,
      );
      _acceptMutation(result);
      await refreshInstances();
      return true;
    } catch (value) {
      error = value.toString();
      requestFailure = value is EngineApiException ? value : null;
      return false;
    } finally {
      busyInstances.remove('new');
      _notify();
    }
  }

  Future<bool> updateInstance(
    String instanceId,
    Map<String, dynamic> changes,
  ) async {
    error = null;
    busyInstances.add(instanceId);
    _notify();
    try {
      final result = await api.updateEngineInstance(instanceId, changes);
      _acceptMutation(result);
      await refreshInstances();
      return true;
    } catch (value) {
      error = value.toString();
      return false;
    } finally {
      busyInstances.remove(instanceId);
      _notify();
    }
  }

  Future<bool> deleteInstance(String instanceId) async {
    error = null;
    busyInstances.add(instanceId);
    _notify();
    try {
      final result = await api.deleteEngineInstance(instanceId);
      _acceptMutation(result);
      instances = instances
          .where((instance) => instance.id != instanceId)
          .toList();
      return true;
    } catch (value) {
      error = value.toString();
      return false;
    } finally {
      busyInstances.remove(instanceId);
      _notify();
    }
  }

  Future<bool> deleteModel(String modelId) async {
    error = null;
    requestFailure = null;
    busyModels.add(modelId);
    _notify();
    try {
      models = await api.deleteEngineModel(modelId);
      if (selectedModelId == modelId) {
        selectedModelId = null;
        recommendation = null;
      }
      return true;
    } catch (value) {
      error = value.toString();
      requestFailure = value is EngineApiException ? value : null;
      return false;
    } finally {
      busyModels.remove(modelId);
      _notify();
    }
  }

  Future<bool> retryRuntime(String runtimeId) async {
    error = null;
    requestFailure = null;
    busyRuntimes.add(runtimeId);
    _notify();
    try {
      final result = await api.installEngineRuntime(runtimeId);
      _acceptMutation(result);
      runtimes = await api.getEngineRuntimes();
      return true;
    } catch (value) {
      error = value.toString();
      requestFailure = value is EngineApiException ? value : null;
      return false;
    } finally {
      busyRuntimes.remove(runtimeId);
      _notify();
    }
  }

  EngineOperation? get gpuRepairOperation {
    final id = gpuRepairOperationId;
    return id == null ? null : operations[id];
  }

  Future<EngineOperation?> rebuildVulkanGpuRuntime() async {
    error = null;
    requestFailure = null;
    isRepairingGpuRuntime = true;
    gpuRepairOperationId = null;
    _notify();
    try {
      final result = await api.installEngineRuntime('llama_cpp');
      _acceptMutation(result);
      final operationId = result.operationId;
      if (operationId == null || operationId.isEmpty) {
        throw EngineApiException(
          remainingUiText('engineController.vulkanOperationMissing'),
          code: 'missing_operation',
        );
      }
      gpuRepairOperationId = operationId;
      _notify();
      final operation = await _waitForOperation(operationId);
      runtimes = await api.getEngineRuntimes();
      if (operation?.state == 'completed') {
        capabilities = await api.getEngineCapabilities();
      }
      return operation;
    } catch (value) {
      error = value.toString();
      requestFailure = value is EngineApiException ? value : null;
      return null;
    } finally {
      isRepairingGpuRuntime = false;
      _notify();
    }
  }

  Future<EngineOperation?> _waitForOperation(String operationId) async {
    final current = operations[operationId];
    if (current?.isTerminal == true) return current;

    final waiter = _operationWaiters.putIfAbsent(
      operationId,
      Completer<EngineOperation?>.new,
    );

    final latest = operations[operationId];
    if (latest?.isTerminal == true) {
      _operationWaiters.remove(operationId);
      return latest;
    }

    unawaited(_reconcileOperation(operationId));
    try {
      final operation = await waiter.future.timeout(
        const Duration(minutes: 30),
        onTimeout: () => null,
      );
      if (operation == null && !_disposed) {
        error = remainingUiText('engineController.gpuSetupTimedOut');
        _notify();
      }
      return operation;
    } finally {
      if (identical(_operationWaiters[operationId], waiter)) {
        _operationWaiters.remove(operationId);
      }
    }
  }

  Future<bool> cancelOperation(String operationId) async {
    try {
      _upsertOperation(await api.cancelEngineOperation(operationId));
      _notify();
      return true;
    } catch (value) {
      error = value.toString();
      _notify();
      return false;
    }
  }

  void clearError() {
    error = null;
    requestFailure = null;
    _notify();
  }

  void _acceptMutation(EngineMutationResult result) {
    final instance = result.instance;
    final operationId = result.operationId;
    if (operationId != null && operationId.isNotEmpty) {
      operations.putIfAbsent(
        operationId,
        () => EngineOperation(
          id: operationId,
          type: 'engine',
          state: 'queued',
          instanceId: instance?.id,
          progress: 0,
          message: 'Vorgang wurde eingeplant',
          error: null,
        ),
      );
    }
  }

  EngineInstance? takeReadyAnnouncement() {
    if (_readyAnnouncements.isEmpty) return null;
    return _readyAnnouncements.removeAt(0);
  }

  void _upsertInstance(EngineInstance instance, {bool announceReady = true}) {
    final index = instances.indexWhere((item) => item.id == instance.id);
    final wasReady = index >= 0 && instances[index].isReady;
    if (index < 0) {
      instances = [...instances, instance];
    } else {
      final updated = [...instances];
      updated[index] = instance;
      instances = updated;
    }
    if (announceReady && instance.isReady && !wasReady) {
      _readyAnnouncements.add(instance);
    }
  }

  void _replaceInstances(
    List<EngineInstance> next, {
    required bool announceReady,
    bool protectReadyFromStalePreparation = false,
  }) {
    final previous = {for (final item in instances) item.id: item};
    final resolved = next.map((incoming) {
      final current = previous[incoming.id];
      if (current != null &&
          protectReadyFromStalePreparation &&
          _incomingPreparationIsOlderThanReady(current, incoming)) {
        return current;
      }
      return incoming;
    }).toList();
    if (announceReady) {
      for (final item in resolved) {
        final prior = previous[item.id];
        if (item.isReady && prior?.isReady != true) {
          _readyAnnouncements.add(item);
        }
      }
    }
    instances = resolved;
  }

  bool _incomingPreparationIsOlderThanReady(
    EngineInstance current,
    EngineInstance incoming,
  ) {
    return current.isReady &&
        incoming.planRevision <= current.planRevision &&
        const {'installing', 'queued', 'starting'}.contains(incoming.state);
  }

  void _connectEngineEvents() {
    if (_disposed || _eventSubscription != null) return;
    _eventConnectionAttempts++;
    _eventSubscription = api.streamEngineEvents().listen(
      (event) {
        _acceptEngineEvent(event);
      },
      onError: (Object _, StackTrace _) {
        _eventSubscription = null;
        _scheduleEventReconnect();
      },
      onDone: () {
        _eventSubscription = null;
        _scheduleEventReconnect();
      },
      cancelOnError: true,
    );
  }

  void _scheduleEventReconnect() {
    if (_disposed || _eventReconnectTimer?.isActive == true) return;
    _eventReconnectTimer = Timer(eventReconnectDelay, () {
      _eventReconnectTimer = null;
      _connectEngineEvents();
    });
  }

  void _acceptEngineEvent(EngineStreamEvent event) {
    if (_disposed) return;
    var refreshModels = false;
    switch (event.type) {
      case 'snapshot':
        final reconnectSnapshot = _hasSeenEventSnapshot;
        final catalogMayHaveChanged =
            reconnectSnapshot || _eventConnectionAttempts > 1;
        final rawInstances = event.data['instances'];
        if (rawInstances is List) {
          final snapshot = rawInstances.map(EngineInstance.fromJson).toList();

          _replaceInstances(snapshot, announceReady: reconnectSnapshot);
          _hasSeenEventSnapshot = true;
        }

        refreshModels = catalogMayHaveChanged;
        _reconcileWaitingOperations();
        break;
      case 'instance_created':
      case 'instance_changed':
        final instance = EngineInstance.fromJson(event.data);
        if (instance.id.isNotEmpty) _upsertInstance(instance);
        break;
      case 'instance_deleted':
        final id = event.data['id']?.toString() ?? '';
        if (id.isNotEmpty) {
          instances = instances.where((item) => item.id != id).toList();
        }
        break;
      case 'operation':
        final operation = EngineOperation.fromJson(event.data);
        if (operation.id.isNotEmpty) _upsertOperation(operation);
        break;
      case 'model_deleted':
      case 'models_rescanned':
        refreshModels = true;
        break;
      case 'guard_state':
        break;
      default:
        break;
    }
    _notify();
    _refreshAfterEvent(includeModels: refreshModels);
  }

  void _upsertOperation(EngineOperation operation) {
    final previous = operations[operation.id];
    if (previous?.isTerminal == true && !operation.isTerminal) return;
    operations[operation.id] = operation;
    final waiter = _operationWaiters[operation.id];
    if (operation.isTerminal && waiter != null && !waiter.isCompleted) {
      waiter.complete(operation);
    }
  }

  void _reconcileWaitingOperations() {
    for (final operationId in _operationWaiters.keys.toList()) {
      unawaited(_reconcileOperation(operationId));
    }
  }

  Future<void> _reconcileOperation(String operationId) async {
    if (_disposed || !_operationReconciliations.add(operationId)) return;
    try {
      final operation = await api.getEngineOperation(operationId);
      if (_disposed) return;
      _upsertOperation(operation);
      _notify();
    } catch (_) {
    } finally {
      _operationReconciliations.remove(operationId);
    }
  }

  void _refreshAfterEvent({bool includeModels = false}) {
    if (_disposed) return;
    _eventRefreshPending = true;
    _eventRefreshModels = _eventRefreshModels || includeModels;
    if (_eventRefreshInProgress) return;
    unawaited(_runEventRefresh());
  }

  Future<void> _runEventRefresh() async {
    if (_disposed || _eventRefreshInProgress) return;
    _eventRefreshInProgress = true;
    try {
      while (!_disposed && _eventRefreshPending) {
        final includeModels = _eventRefreshModels;
        _eventRefreshPending = false;
        _eventRefreshModels = false;
        await Future.wait<void>([
          api
              .getEngineRuntimes()
              .then<void>((value) => runtimes = value)
              .catchError((Object _) {}),
          api
              .getEngineCapabilities()
              .then<void>((value) => capabilities = value)
              .catchError((Object _) {}),
          if (includeModels)
            api
                .getEngineModels()
                .then<void>((value) => models = value)
                .catchError((Object _) {}),
        ]);
        if (runtimes.isEmpty && capabilities != null) {
          runtimes = capabilities!.runtimes;
        }
        if (selectedModelId != null &&
            !models.any((model) => model.id == selectedModelId)) {
          selectedModelId = null;
          recommendation = null;
        }
        _notify();
      }
    } finally {
      _eventRefreshInProgress = false;

      if (!_disposed && _eventRefreshPending) {
        unawaited(_runEventRefresh());
      }
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_eventSubscription?.cancel());
    _eventSubscription = null;
    _eventReconnectTimer?.cancel();
    _eventReconnectTimer = null;
    for (final waiter in _operationWaiters.values) {
      if (!waiter.isCompleted) waiter.complete(null);
    }
    _operationWaiters.clear();
    _operationReconciliations.clear();
    super.dispose();
  }
}
