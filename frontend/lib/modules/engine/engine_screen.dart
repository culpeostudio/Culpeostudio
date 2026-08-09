import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/api_service.dart';
import '../../core/culpeo_grid.dart';
import '../../core/design_tokens.dart';
import './controller.dart';
import './engine_api.dart';
import './models.dart';
import './preset_dialog.dart';
import './quantize_dialog.dart';
import './widgets.dart';
import './engine_screen_strings.dart';
import '../../core/top_notification.dart';
import './header_widgets.dart';
import './instance_card.dart';
import './wizard_widgets.dart';
import './telemetry_widgets.dart';

class EngineScreen extends StatefulWidget {
  const EngineScreen({super.key, this.api});

  final EngineApi? api;

  @override
  State<EngineScreen> createState() => _EngineScreenState();
}

class _EngineScreenState extends State<EngineScreen> {
  late final EngineController _controller;
  final _contextController = TextEditingController(text: '4096');
  final _maxSequencesController = TextEditingController(text: '1');
  final _gpuLayersController = TextEditingController();
  final _threadsController = TextEditingController();
  final _tensorParallelController = TextEditingController(text: '1');
  final _gpuIdsController = TextEditingController();

  bool _expertMode = false;
  bool _forceCpuRuntime = false;
  String _runtime = 'auto';
  String _contextMode = 'auto_max';
  String _priority = 'normal';
  String _kvCachePolicy = 'prefer_4bit';
  String _offload = 'auto';
  String _kvCacheDtype = 'auto';
  String _flashAttention = 'auto';
  // Off until the user says otherwise. Spilling into RAM is a real trade in
  // speed, so it is offered and explained rather than assumed.
  bool _useRamOffload = false;
  bool _allowFallback = true;
  bool _autostart = false;
  bool _gatewayAutostart = false;
  bool _restartOnCrash = false;

  /// Zero means the engine default; -1 means never unload.
  int _idleTimeoutSeconds = 0;
  bool _showSetupDetails = false;
  bool _showTelemetryPanel = true;
  String? _planningIssue;
  final Set<String> _expandedInstances = <String>{};

  int _workspace = 0;

  int _wizardStep = 0;

  @override
  void initState() {
    super.initState();
    _controller = EngineController(widget.api ?? ApiService());
    _controller.addListener(_handleEngineControllerChange);
    _initializeEngine();
  }

  Future<void> _initializeEngine() async {
    await _controller.initialize();
  }

  @override
  void dispose() {
    _controller.removeListener(_handleEngineControllerChange);
    _controller.dispose();
    _contextController.dispose();
    _maxSequencesController.dispose();
    _gpuLayersController.dispose();
    _threadsController.dispose();
    _tensorParallelController.dispose();
    _gpuIdsController.dispose();
    super.dispose();
  }

  void _handleEngineControllerChange() {
    final ready = <EngineInstance>[];
    for (
      var instance = _controller.takeReadyAnnouncement();
      instance != null;
      instance = _controller.takeReadyAnnouncement()
    ) {
      ready.add(instance);
    }
    if (ready.isEmpty || !mounted) return;
    if (ready.length > 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showTopNotification(
          context,
          tr('engineScreen.notification.modelsStarted', {
            'count': ready.length.toString(),
          }),
          color: const Color(0xFF53D18A),
        );
      });
      return;
    }
    final instance = ready.single;
    final servedName = instance.servedModelName.trim();
    var modelName = '';
    for (final model in _controller.models) {
      if (model.id == instance.modelId) {
        modelName = model.name.trim();
        break;
      }
    }
    final name = servedName.isNotEmpty
        ? servedName
        : modelName.isNotEmpty
        ? modelName
        : tr('engineScreen.default.model');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showTopNotification(
        context,
        tr('engineScreen.notification.modelStarted', {'name': name}),
        color: const Color(0xFF53D18A),
      );
    });
  }

  EngineConfig _draftConfig({bool? allowRamOffload, bool? forceCpuRuntime}) {
    final useCpuRuntime = forceCpuRuntime ?? _forceCpuRuntime;
    final runtimeOptions = <String, dynamic>{
      if (_parseOptionalInt(_gpuLayersController.text) != null)
        'gpu_layers': _parseOptionalInt(_gpuLayersController.text),
      if (_parseOptionalInt(_threadsController.text) != null)
        'threads': _parseOptionalInt(_threadsController.text),
      if (_parseOptionalInt(_tensorParallelController.text) != null)
        'tensor_parallel_size': _parseOptionalInt(
          _tensorParallelController.text,
        ),
      if (_gpuIdsController.text.trim().isNotEmpty)
        'gpu_ids': _gpuIdsController.text
            .split(',')
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty)
            .toList(),
      'offload': useCpuRuntime ? 'cpu' : _offload,
      if (useCpuRuntime) 'force_cpu_runtime': true,
      'allow_ram_offload': allowRamOffload ?? _useRamOffload,

      if (_expertMode) 'kv_cache_dtype': _kvCacheDtype,
      if (_expertMode && _flashAttention != 'auto')
        'flash_attention': _flashAttention,
    };
    return EngineConfig(
      runtime: _runtime,
      contextMode: _contextMode,
      contextTokens: _contextMode == 'fixed'
          ? (_parseOptionalInt(_contextController.text) ?? 4096)
          : null,
      maxSequences: math.max(
        1,
        _parseOptionalInt(_maxSequencesController.text) ?? 1,
      ),
      priority: _priority,
      kvCachePolicy: _expertMode ? _kvCachePolicy : 'prefer_4bit',
      allowFallback: _allowFallback,
      autostart: _autostart,
      gatewayAutostart: _gatewayAutostart,
      restartOnCrash: _restartOnCrash,
      idleTimeoutSeconds: _idleTimeoutSeconds == 0 ? null : _idleTimeoutSeconds,
      runtimeOptions: runtimeOptions,
    );
  }

  int? _parseOptionalInt(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return int.tryParse(trimmed);
  }

  void _selectModel(ModelRecord model) {
    if (!model.isStartable) return;
    _controller.chooseModel(model.id);
    setState(() {
      _useRamOffload = false;
      _forceCpuRuntime = false;
      _planningIssue = null;
      _wizardStep = 1;
    });
  }

  Future<void> _calculateAndContinue() async {
    final model = _controller.selectedModel;
    if (model == null || _controller.isLoadingRecommendation) return;
    setState(() => _planningIssue = null);

    var ok = await _controller.selectModel(
      model.id,
      config: _draftConfig(allowRamOffload: false),
    );
    if (!mounted) return;
    if (ok) {
      _continueWithPlan(useRamOffload: false, forceCpuRuntime: false);
      return;
    }

    final firstFailure = _controller.requestFailure;
    final gpuRuntimeIssue = firstFailure?.code == 'gpu_runtime_unavailable'
        ? (firstFailure?.details['reason']?.toString() ?? firstFailure?.message)
        : null;
    if (firstFailure?.code != 'resource_conflict' &&
        firstFailure?.code != 'gpu_runtime_unavailable') {
      setState(() {
        _planningIssue = tr('engineScreen.error.calculationFailed');
      });
      return;
    }

    ok = await _controller.selectModel(
      model.id,
      config: _draftConfig(
        allowRamOffload: true,
        forceCpuRuntime: gpuRuntimeIssue != null,
      ),
    );
    if (!mounted) return;
    final hybridPlan = _controller.recommendation;
    if (!ok || hybridPlan == null) {
      _controller.chooseModel(model.id);
      setState(() {
        _planningIssue = tr('engineScreen.error.modelDoesNotFit');
      });
      return;
    }

    final choice = await _askToUseRam(
      model,
      hybridPlan,
      gpuRuntimeIssue: gpuRuntimeIssue,
    );
    if (!mounted) return;
    if (choice == _MemoryPlanChoice.rebuildGpu) {
      _controller.chooseModel(model.id);
      await _rebuildGpuRuntimeAndRetry(model);
      return;
    }
    if (choice != _MemoryPlanChoice.useRam) {
      _controller.chooseModel(model.id);
      setState(() => _planningIssue = null);
      return;
    }
    _continueWithPlan(
      useRamOffload: true,
      forceCpuRuntime: gpuRuntimeIssue != null,
    );
  }

  void _continueWithPlan({
    required bool useRamOffload,
    required bool forceCpuRuntime,
  }) {
    final recommendation = _controller.recommendation;
    if (recommendation != null) {
      _contextController.text = recommendation.effectiveContextTokens
          .toString();
    }

    setState(() {
      _useRamOffload = useRamOffload;
      _forceCpuRuntime = forceCpuRuntime;
      _planningIssue = null;
      _wizardStep = 2;
    });
  }

  Future<_MemoryPlanChoice> _askToUseRam(
    ModelRecord model,
    ContextPlan plan, {
    String? gpuRuntimeIssue,
  }) async {
    final ram = plan.memory.ramBytes;
    final runtimeUnavailable = gpuRuntimeIssue != null;
    return await showDialog<_MemoryPlanChoice>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            backgroundColor: enginePanelColor,
            icon: const Icon(Icons.memory_outlined, color: engineAccent),
            title: Text(
              runtimeUnavailable
                  ? tr('engineScreen.memory.gpuNotReady')
                  : tr('engineScreen.memory.addSystemRam'),
              style: const TextStyle(color: Colors.white),
            ),
            content: Text(
              runtimeUnavailable
                  ? tr('engineScreen.memory.gpuNotReadyContent', {
                      'model': model.name,
                      'issue': gpuRuntimeIssue,
                      'ramPlan': ram > 0
                          ? tr('engineScreen.memory.ramPlan', {
                              'ram': formatBytes(ram),
                            })
                          : '',
                    })
                  : tr('engineScreen.memory.addSystemRamContent', {
                      'model': model.name,
                      'ramPlan': ram > 0
                          ? tr('engineScreen.memory.ramPlan', {
                              'ram': formatBytes(ram),
                            })
                          : '',
                    }),
              style: const TextStyle(color: Colors.white70, height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.of(dialogContext).pop(_MemoryPlanChoice.cancel),
                child: Text(tr('engineScreen.memory.chooseOtherModel')),
              ),
              if (runtimeUnavailable)
                OutlinedButton.icon(
                  key: const Key('engine-auto-repair-gpu'),
                  onPressed: () => Navigator.of(
                    dialogContext,
                  ).pop(_MemoryPlanChoice.rebuildGpu),
                  icon: const Icon(Icons.build_circle_outlined),
                  // There is only one repair now: fetch the GPU build again.
                  // Nothing is compiled locally, so there are no system
                  // packages to install first.
                  label: Text(tr('engineScreen.memory.rebuildGpuRuntime')),
                ),
              FilledButton.icon(
                onPressed: () =>
                    Navigator.of(dialogContext).pop(_MemoryPlanChoice.useRam),
                icon: const Icon(Icons.check),
                label: Text(
                  runtimeUnavailable
                      ? tr('engineScreen.memory.useCpuRam')
                      : tr('engineScreen.memory.useRam'),
                ),
              ),
            ],
          ),
        ) ??
        _MemoryPlanChoice.cancel;
  }

  Future<void> _rebuildGpuRuntimeAndRetry(ModelRecord model) async {
    setState(() {
      _planningIssue = null;
      _forceCpuRuntime = false;
    });
    final operation = await _controller.rebuildVulkanGpuRuntime();
    if (!mounted) return;
    if (operation?.state == 'completed') {
      _controller.chooseModel(model.id);
      await _calculateAndContinue();
      return;
    }
    final message = operation?.errorSummary.isNotEmpty == true
        ? operation!.errorSummary
        : operation?.error?.isNotEmpty == true
        ? operation!.error!
        : _controller.error ?? tr('engineScreen.error.gpuRuntimeRebuildFailed');
    _controller.clearError();
    setState(() => _planningIssue = message);
  }

  /// Opens the quantisation dialog for one catalog entry. A started conversion
  /// runs as an ordinary engine operation, so the feed already reports on it;
  /// all this has to do is say it began.
  Future<void> _quantizeModel(ModelRecord model) async {
    final operationId = await showQuantizeDialog(
      context,
      model: model,
      api: widget.api,
    );
    if (!mounted || operationId == null || operationId.isEmpty) return;
    showTopNotification(
      context,
      tr('engineScreen.model.quantizeStarted', {'model': model.name}),
      color: CulpeoColors.metric,
    );
  }

  Future<void> _deleteModel(ModelRecord model) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: enginePanelColor,
        title: Text(
          tr('engineScreen.model.deleteTitle'),
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          tr('engineScreen.model.deleteContent', {'model': model.name}),
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            key: const Key('engine-cancel-delete-model'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(tr('engineScreen.action.cancel')),
          ),
          FilledButton.icon(
            key: const Key('engine-confirm-delete-model'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB3261E),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            icon: const Icon(Icons.delete_outline),
            label: Text(tr('engineScreen.model.deleteConfirm')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final ok = await _controller.deleteModel(model.id);
    if (!mounted) return;
    if (ok) {
      _showMessage(tr('engineScreen.notification.modelDeleted'));
    } else {
      _showError();
    }
  }

  Future<void> _refreshRecommendation() async {
    final ok = await _controller.refreshRecommendation(_draftConfig());
    if (!mounted) return;
    if (!ok) _showError();
  }

  /// The KV cache types the installed llama-server actually reported. A build
  /// with sub-4-bit caches offers them here without any change to this list;
  /// before anything is installed, the upstream set is shown.
  List<String> _availableCacheTypes() {
    for (final runtime in _controller.runtimes) {
      if (runtime.kvCacheModes.isNotEmpty) return runtime.kvCacheModes;
    }
    return const [
      'q4_0',
      'q4_1',
      'iq4_nl',
      'q5_0',
      'q5_1',
      'q8_0',
      'f16',
      'bf16',
      'f32',
    ];
  }

  Future<void> _createInstance() async {
    final model = _controller.selectedModel;
    if (model == null) {
      _showMessage(tr('engineScreen.notification.chooseStartableModel'));
      return;
    }
    final config = _draftConfig();
    var ok = await _controller.createInstance(config);
    if (!mounted) return;
    if (ok) {
      _showMessage(tr('engineScreen.notification.instanceScheduled'));
    } else {
      _showError();
    }
  }

  Future<void> _refreshAll() async {
    final ok = await _controller.refreshAll();
    if (!mounted) return;
    _showMessage(
      ok ? tr('engineScreen.notification.refreshed') : _controller.error,
    );
  }

  Future<void> _instanceAction(EngineInstance instance, String action) async {
    final changes = <String, dynamic>{'action': action};
    if (action == 'restart') {
      changes['requested_config'] = instance.requestedConfig.toJson();
    }
    final ok = await _controller.updateInstance(instance.id, changes);
    if (!mounted) return;
    _showMessage(
      ok
          ? tr('engineScreen.notification.instanceActionScheduled', {
              'action': action,
            })
          : _controller.error,
    );
  }

  Future<void> _applySuggestedFix(
    EngineInstance instance,
    SuggestedFix fix,
  ) async {
    switch (fix.action) {
      case 'reduce_context':
      case 'retry_on_cpu':
        final ok = await _controller.updateInstance(instance.id, {
          'action': 'apply_fix',
          'fix': fix.action,
        });
        if (!mounted) return;
        _showMessage(
          ok
              ? tr('engineScreen.notification.autoFixStarted')
              : _controller.error,
        );
      case 'retry_with_ram':
        final confirmed = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            backgroundColor: enginePanelColor,
            icon: const Icon(Icons.memory_outlined, color: engineAccent),
            title: Text(
              tr('engineScreen.memory.addSystemRam'),
              style: const TextStyle(color: Colors.white),
            ),
            content: Text(
              tr('engineScreen.memory.retryRamContent'),
              style: const TextStyle(color: Colors.white70, height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(tr('engineScreen.action.cancel')),
              ),
              FilledButton.icon(
                key: const Key('engine-confirm-retry-with-ram'),
                onPressed: () => Navigator.of(dialogContext).pop(true),
                icon: const Icon(Icons.check),
                label: Text(tr('engineScreen.memory.recalculateWithRam')),
              ),
            ],
          ),
        );
        if (confirmed != true || !mounted) return;
        final ok = await _controller.updateInstance(instance.id, {
          'action': 'apply_fix',
          'fix': fix.action,
        });
        if (!mounted) return;
        _showMessage(
          ok
              ? tr('engineScreen.notification.gpuRamRecalculated')
              : _controller.error,
        );
      case 'rescan_models':
      case 'check_model_files':
        await _refreshAll();
      case 'reinstall_runtime':
        if (instance.errorCode == 'gpu_runtime_unavailable') {
          final model = _controller.models
              .where((item) => item.id == instance.modelId)
              .firstOrNull;
          if (model != null) {
            await _rebuildGpuRuntimeAndRetry(model);
            return;
          }
        }
        final failedRuntime = _controller.runtimes
            .where(
              (runtime) =>
                  const {'failed', 'error'}.contains(runtime.status) ||
                  !runtime.available,
            )
            .firstOrNull;
        if (failedRuntime != null) {
          final ok = await _controller.retryRuntime(failedRuntime.id);
          if (!mounted) return;
          _showMessage(
            ok
                ? tr('engineScreen.notification.runtimePreparing')
                : _controller.error,
          );
        } else {
          await _instanceAction(instance, 'start');
        }
      default:
        await _instanceAction(instance, 'start');
    }
  }

  Future<void> _deleteInstance(EngineInstance instance) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('engineScreen.instance.removeTitle')),
        content: Text(
          tr('engineScreen.instance.removeContent', {
            'instance': instance.servedModelName.isEmpty
                ? instance.id
                : instance.servedModelName,
          }),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr('engineScreen.action.cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(tr('engineScreen.action.remove')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final ok = await _controller.deleteInstance(instance.id);
    if (!mounted) return;
    _showMessage(
      ok ? tr('engineScreen.notification.instanceRemoved') : _controller.error,
    );
  }

  Future<void> _editContext(EngineInstance instance) async {
    final plan = instance.plan;
    if (plan == null) return;
    final current = plan.effectiveContextTokens;
    final estimatedByMemory = plan.hybridMaxContextTokens > 0
        ? plan.hybridMaxContextTokens
        : current;
    final hardLimit = plan.modelContextLimitTokens > 0
        ? plan.modelContextLimitTokens
        : estimatedByMemory;
    final estimatedMaximum = math.max(
      current,
      math.min(estimatedByMemory, hardLimit),
    );
    final minimum = estimatedMaximum >= 2048 ? 2048 : 1;
    final valueController = TextEditingController(text: current.toString());
    String? validationError;

    final selected = await showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          key: const Key('engine-context-dialog'),
          backgroundColor: enginePanelColor,
          icon: const Icon(Icons.memory_outlined, color: engineAccent),
          title: Text(
            tr('engineScreen.context.title'),
            style: const TextStyle(color: Colors.white),
          ),
          content: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('engineScreen.context.summary', {
                    'current': formatTokenCount(current),
                    'maximum': formatTokenCount(estimatedMaximum),
                  }),
                  style: const TextStyle(color: Colors.white70, height: 1.4),
                ),
                const SizedBox(height: 10),
                Text(
                  tr('engineScreen.context.help'),
                  style: const TextStyle(color: Color(0xFFEBD9A8), height: 1.4),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton(
                      key: const Key('engine-context-use-current'),
                      onPressed: () => setDialogState(() {
                        valueController.text = current.toString();
                        validationError = null;
                      }),
                      child: Text(
                        tr('engineScreen.context.checked', {
                          'tokens': formatTokenCount(current),
                        }),
                      ),
                    ),
                    OutlinedButton(
                      key: const Key('engine-context-use-estimated-max'),
                      onPressed: () => setDialogState(() {
                        valueController.text = estimatedMaximum.toString();
                        validationError = null;
                      }),
                      child: Text(
                        tr('engineScreen.context.testEstimate', {
                          'tokens': formatTokenCount(estimatedMaximum),
                        }),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('engine-context-value'),
                  controller: valueController,
                  keyboardType: TextInputType.number,
                  onChanged: (_) {
                    if (validationError != null) {
                      setDialogState(() => validationError = null);
                    }
                  },
                  decoration: InputDecoration(
                    labelText: tr('engineScreen.context.tokensLabel'),
                    helperText: tr('engineScreen.context.rangeHelper', {
                      'minimum': minimum.toString(),
                      'maximum': estimatedMaximum.toString(),
                    }),
                    errorText: validationError,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(tr('engineScreen.action.cancel')),
            ),
            FilledButton.icon(
              key: const Key('engine-context-confirm'),
              onPressed: () {
                final normalized = valueController.text.trim().replaceAll(
                  RegExp(r'[\s\.,]'),
                  '',
                );
                final value = int.tryParse(normalized);
                if (value == null ||
                    value < minimum ||
                    value > estimatedMaximum) {
                  setDialogState(
                    () => validationError =
                        tr('engineScreen.context.invalidValue', {
                          'minimum': minimum.toString(),
                          'maximum': estimatedMaximum.toString(),
                        }),
                  );
                  return;
                }
                Navigator.of(dialogContext).pop(value);
              },
              icon: const Icon(Icons.restart_alt),
              label: Text(tr('engineScreen.context.restartAndCheck')),
            ),
          ],
        ),
      ),
    );
    valueController.dispose();
    if (selected == null || !mounted) return;
    if (selected == current) {
      _showMessage(tr('engineScreen.notification.contextUnchanged'));
      return;
    }

    final config = Map<String, dynamic>.from(instance.requestedConfig.toJson());
    final runtimeOptions = Map<String, dynamic>.from(
      instance.requestedConfig.runtimeOptions,
    );
    runtimeOptions.remove('_context_search_floor_tokens');
    runtimeOptions.remove('_context_search_ceiling_tokens');
    if (selected > current) {
      runtimeOptions['context_search_mode'] = 'maximize_stable';
    } else {
      runtimeOptions.remove('context_search_mode');
    }
    if (selected > plan.gpuOnlyMaxContextTokens || plan.usesRam) {
      runtimeOptions['allow_ram_offload'] = true;
    }
    config['context_mode'] = 'fixed';
    config['context_tokens'] = selected;
    config['allow_fallback'] = true;
    config['runtime_options'] = runtimeOptions;

    final ok = await _controller.updateInstance(instance.id, {
      'action': 'restart',
      'requested_config': config,
    });
    if (!mounted) return;
    _showMessage(
      ok
          ? selected > current
                ? tr('engineScreen.notification.contextIncrease')
                : tr('engineScreen.notification.contextRestart')
          : _controller.error,
    );
  }

  Future<void> _editSampling(EngineInstance instance) async {
    final current = instance.requestedConfig.generationDefaults;
    final temperature = TextEditingController(
      text: (current['temperature'] ?? 0.7).toString(),
    );
    final topP = TextEditingController(
      text: (current['top_p'] ?? 0.95).toString(),
    );
    final maxTokens = TextEditingController(
      text: (current['max_tokens'] ?? 1024).toString(),
    );
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('engineScreen.sampling.title')),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: temperature,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: tr('engineScreen.sampling.temperature'),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: topP,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: tr('engineScreen.sampling.topP'),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: maxTokens,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: tr('engineScreen.sampling.maxOutputTokens'),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr('engineScreen.action.cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, {
              'temperature': double.tryParse(temperature.text) ?? 0.7,
              'top_p': double.tryParse(topP.text) ?? 0.95,
              'max_tokens': int.tryParse(maxTokens.text) ?? 1024,
            }),
            child: Text(tr('engineScreen.sampling.applyLive')),
          ),
        ],
      ),
    );
    temperature.dispose();
    topP.dispose();
    maxTokens.dispose();
    if (result == null || !mounted) return;
    final ok = await _controller.updateInstance(instance.id, {
      'generation_defaults': result,
    });
    if (!mounted) return;
    _showMessage(
      ok ? tr('engineScreen.notification.samplingUpdated') : _controller.error,
    );
  }

  void _showError() {
    final failure = _controller.requestFailure;
    if (failure?.code == 'resource_conflict') {
      _showMessage(tr('engineScreen.error.resourceConflict'));
      return;
    }
    _showMessage(_controller.error);
  }

  void _showMessage(String? value) {
    if (!mounted || value == null || value.trim().isEmpty) return;
    showTopNotification(context, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (_controller.isLoading &&
              _controller.models.isEmpty &&
              _controller.instances.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          return LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 980) {
                return Stack(
                  children: [
                    _buildPageScroll(),
                    Positioned(
                      right: 0,
                      top: 132,
                      child: _buildMobileTelemetryHandle(),
                    ),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _buildPageScroll()),
                  const SizedBox(width: 16),
                  _buildTelemetryDock(),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildPageScroll() {
    return SingleChildScrollView(
      key: const Key('engine-page-scroll'),
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          if (_controller.error != null &&
              _controller.requestFailure?.code != 'resource_conflict' &&
              _controller.requestFailure?.code !=
                  'gpu_runtime_unavailable') ...[
            _buildErrorBanner(),
            const SizedBox(height: 20),
          ],
          _buildWorkspaceSwitcher(),
          const SizedBox(height: 20),
          if (_workspace == 0) ...[
            ..._buildRuntimeIssueBanner(),
            _buildWizard(),
          ] else
            _buildInstances(),
        ],
      ),
    );
  }

  Widget _buildMobileTelemetryHandle() {
    return Material(
      color: CulpeoColors.panel,
      borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
      child: InkWell(
        key: const Key('engine-mobile-telemetry-handle'),
        onTap: _openTelemetry,
        borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 12),
          child: RotatedBox(
            quarterTurns: 3,
            child: Text(
              tr('engineScreen.system.tab'),
              style: const TextStyle(
                color: Color(0xFFEBD9A8),
                fontWeight: FontWeight.w800,
                fontSize: 10,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openTelemetry() {
    if (MediaQuery.sizeOf(context).width >= 980) {
      setState(() => _showTelemetryPanel = !_showTelemetryPanel);
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: SizedBox(
          height: MediaQuery.sizeOf(sheetContext).height * 0.78,
          child: _buildTelemetryPanel(
            onClose: () => Navigator.of(sheetContext).pop(),
          ),
        ),
      ),
    );
  }

  Widget _buildTelemetryDock() {
    return AnimatedContainer(
      key: const Key('engine-telemetry-dock'),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      width: _showTelemetryPanel ? 352 : 46,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (_showTelemetryPanel && constraints.maxWidth >= 280) {
            return _buildTelemetryPanel(onClose: _openTelemetry);
          }
          if (_showTelemetryPanel) return const SizedBox.expand();
          return Tooltip(
            message: tr('engineScreen.system.openMonitor'),
            child: Material(
              color: CulpeoColors.panel,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                key: const Key('engine-telemetry-open-rail'),
                borderRadius: BorderRadius.circular(14),
                onTap: _openTelemetry,
                child: Center(
                  child: RotatedBox(
                    quarterTurns: 3,
                    child: Text(
                      tr('engineScreen.system.monitor'),
                      style: const TextStyle(
                        color: Color(0xFFEBD9A8),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.3,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTelemetryPanel({required VoidCallback onClose}) {
    final hardware = _controller.capabilities?.hardware;
    final running = _controller.instances
        .where((item) => item.isReady)
        .toList();
    final active = _controller.instances
        .where((item) => item.isActive && !item.isReady)
        .toList();
    final operation = _activeSetupOperation();
    final current = active.firstOrNull;

    return Container(
      key: const Key('engine-telemetry-panel'),
      decoration: BoxDecoration(
        color: const Color(0xFF15151C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.24),
            blurRadius: 20,
            offset: const Offset(-6, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 8, 12),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: engineAccent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(
                    Icons.monitor_heart_outlined,
                    color: engineAccent,
                    size: 17,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('engineScreen.telemetry.title'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        tr('engineScreen.telemetry.subtitle'),
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  key: const Key('engine-telemetry-close'),
                  tooltip: tr('engineScreen.telemetry.closeMonitor'),
                  onPressed: onClose,
                  icon: const Icon(Icons.chevron_right_rounded),
                  color: Colors.white60,
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.white.withValues(alpha: 0.08)),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(14),
              children: [
                TelemetryLabel(
                  icon: Icons.speed_rounded,
                  label: tr('engineScreen.telemetry.hardwareUtilization'),
                ),
                const SizedBox(height: 10),
                if (hardware == null)
                  TelemetryEmpty(
                    icon: Icons.memory_outlined,
                    text: tr('engineScreen.telemetry.hardwareLoading'),
                  )
                else ...[
                  EngineUsageGauge(
                    icon: Icons.memory_rounded,
                    label: tr('engineScreen.telemetry.memory'),
                    value: _percentUsed(
                      hardware.ramTotalBytes,
                      hardware.ramAvailableBytes,
                    ),
                    detail: tr('engineScreen.telemetry.memoryUsed', {
                      'used': formatBytes(
                        hardware.ramTotalBytes - hardware.ramAvailableBytes,
                      ),
                      'total': formatBytes(hardware.ramTotalBytes),
                    }),
                    fraction: _usedFraction(
                      hardware.ramTotalBytes,
                      hardware.ramAvailableBytes,
                    ),
                    color: engineAccent,
                  ),
                  for (final gpu in hardware.gpus) ...[
                    const SizedBox(height: 9),
                    EngineUsageGauge(
                      icon: Icons.developer_board_rounded,
                      label: gpu.name,
                      value: _percentUsed(
                        gpu.vramTotalBytes,
                        gpu.vramFreeBytes,
                      ),
                      detail: tr('engineScreen.telemetry.memoryUsed', {
                        'used': formatBytes(
                          gpu.vramTotalBytes - gpu.vramFreeBytes,
                        ),
                        'total': formatBytes(gpu.vramTotalBytes),
                      }),
                      fraction: _usedFraction(
                        gpu.vramTotalBytes,
                        gpu.vramFreeBytes,
                      ),
                      color: CulpeoColors.metric,
                    ),
                  ],
                ],
                const SizedBox(height: 22),
                TelemetryLabel(
                  icon: Icons.bolt_rounded,
                  label: tr('engineScreen.telemetry.currentModelStart'),
                  trailing: operation == null && current == null
                      ? Text(
                          tr('engineScreen.telemetry.quiet'),
                          style: const TextStyle(
                            color: Color(0xFF81C784),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        )
                      : Text(
                          tr('engineScreen.telemetry.active'),
                          style: const TextStyle(
                            color: Color(0xFFEBD9A8),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                ),
                const SizedBox(height: 10),
                if (operation != null || current != null)
                  _buildCurrentProgress(operation, current)
                else
                  TelemetryEmpty(
                    icon: Icons.check_circle_outline,
                    text: tr('engineScreen.telemetry.noStartActive'),
                  ),
                const SizedBox(height: 22),
                TelemetryLabel(
                  icon: Icons.hub_outlined,
                  label: tr('engineScreen.telemetry.liveModels'),
                  trailing: Text(
                    tr('engineScreen.telemetry.online', {
                      'count': running.length.toString(),
                    }),
                    style: const TextStyle(
                      color: engineAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                if (running.isEmpty)
                  TelemetryEmpty(
                    icon: Icons.power_settings_new_rounded,
                    text: tr('engineScreen.telemetry.noModelRunning'),
                  )
                else
                  ...running.map(_buildLiveModelTile),
                const SizedBox(height: 22),
                TelemetryLabel(
                  icon: Icons.settings_suggest_outlined,
                  label: tr('engineScreen.telemetry.technicalComponents'),
                  trailing: IconButton(
                    key: const Key('engine-system-details-toggle'),
                    onPressed: () =>
                        setState(() => _showSetupDetails = !_showSetupDetails),
                    tooltip: tr('engineScreen.telemetry.componentsTooltip'),
                    icon: Icon(
                      _showSetupDetails
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: const Color(0xFFEBD9A8),
                    ),
                  ),
                ),
                if (_showSetupDetails) ...[
                  const SizedBox(height: 10),
                  _buildRuntimeDetails(),
                  if (_controller.operations.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _buildOperationDetails(),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentProgress(
    EngineOperation? operation,
    EngineInstance? instance,
  ) {
    final progress = operation?.progress ?? instance?.progress ?? 0.0;
    final name = instance?.servedModelName.isNotEmpty == true
        ? instance!.servedModelName
        : instance?.id ?? tr('engineScreen.operation.defaultName');
    final detail = operation != null
        ? _friendlyOperationMessage(operation)
        : instanceStageDescription(instance!);
    return Container(
      key: const Key('engine-telemetry-progress'),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: engineBlue.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: engineBlue.withValues(alpha: 0.19)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            detail,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white60, fontSize: 11),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress > 0 ? progress : null,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.09),
              valueColor: const AlwaysStoppedAnimation<Color>(engineAccent),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            progress > 0
                ? tr('engineScreen.progress.complete', {
                    'percent': (progress * 100).round().toString(),
                  })
                : tr('engineScreen.progress.waiting'),
            style: const TextStyle(color: Color(0xFFEBD9A8), fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveModelTile(EngineInstance instance) {
    final contextTokens =
        instance.plan?.effectiveContextTokens ??
        instance.effectiveConfig.contextTokens;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.035),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF66BB6A),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('engineScreen.instance.label', {'id': instance.id}),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${runtimeLabel(instance.effectiveConfig.runtime)} · ${contextTokens == null ? tr('engineScreen.context.auto') : tr('engineScreen.context.tokenCount', {'tokens': formatTokenCount(contextTokens)})}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white38, fontSize: 10),
                  ),
                ],
              ),
            ),
            if (instance.activeRequests > 0)
              Text(
                '${instance.activeRequests}',
                style: const TextStyle(
                  color: engineAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
          ],
        ),
      ),
    );
  }

  double _usedFraction(int total, int available) {
    if (total <= 0) return 0;
    return (1 - available / total).clamp(0.0, 1.0);
  }

  String _percentUsed(int total, int available) =>
      '${(_usedFraction(total, available) * 100).round()} %';

  List<Widget> _buildRuntimeIssueBanner() {
    if (_activeSetupOperation() != null || _setupInstance() != null) {
      return const [];
    }
    final installingRuntime = _activeSetupRuntime();
    if (installingRuntime != null) {
      return [
        EnginePanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.sync, color: Color(0xFFEBD9A8), size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      installingRuntime.statusMessage.isNotEmpty
                          ? installingRuntime.statusMessage
                          : tr('engineScreen.runtime.backgroundPreparing'),
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: installingRuntime.progress > 0
                    ? installingRuntime.progress
                    : null,
                minHeight: 4,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 6),
              Text(
                installingRuntime.progress > 0
                    ? tr('engineScreen.progress.complete', {
                        'percent': (installingRuntime.progress * 100)
                            .round()
                            .toString(),
                      })
                    : tr('engineScreen.progress.preparing'),
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ];
    }
    final failedRuntime = _controller.runtimes
        .where((runtime) => const {'failed', 'error'}.contains(runtime.status))
        .firstOrNull;
    if (failedRuntime == null) {
      return const [];
    }
    final busy = _controller.busyRuntimes.contains(failedRuntime.id);
    return [
      EnginePanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              key: const Key('engine-setup-friendly-error'),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF44336).withValues(alpha: 0.11),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFF44336).withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Color(0xFFEF9A9A),
                    size: 19,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      _friendlyRuntimeError(failedRuntime),
                      style: const TextStyle(
                        color: Color(0xFFFFCDD2),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.tonalIcon(
                key: const Key('engine-setup-retry'),
                onPressed: busy
                    ? null
                    : () => _controller.retryRuntime(failedRuntime.id),
                icon: const Icon(Icons.refresh),
                label: Text(tr('engineScreen.runtime.retrySetup')),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
    ];
  }

  Widget _buildWorkspaceSwitcher() {
    final instanceCount = _controller.instances.length;
    return Wrap(
      key: const Key('engine-workspace-switcher'),
      spacing: 24,
      runSpacing: 12,
      children: [
        WorkspaceTab(
          key: const Key('engine-workspace-start'),
          icon: Icons.play_circle_outline_rounded,
          label: tr('engineScreen.workspace.startModel'),
          selected: _workspace == 0,
          onTap: () => setState(() => _workspace = 0),
        ),
        WorkspaceTab(
          key: const Key('engine-workspace-instances'),
          icon: Icons.inventory_2_outlined,
          label: tr('engineScreen.workspace.myModels', {
            'count': instanceCount.toString(),
          }),
          selected: _workspace == 1,
          onTap: () => setState(() => _workspace = 1),
        ),
      ],
    );
  }

  Widget _buildWizard() {
    final model = _controller.selectedModel;
    final hasModel = model != null;
    final hasPlan = _controller.recommendation != null;
    final title = switch (_wizardStep) {
      0 => tr('engineScreen.wizard.selectModel'),
      1 => tr('engineScreen.wizard.configureStart'),
      _ => tr('engineScreen.wizard.startModel'),
    };
    final subtitle = switch (_wizardStep) {
      0 => tr('engineScreen.wizard.selectModelSubtitle'),
      1 =>
        _expertMode
            ? tr('engineScreen.wizard.expertSubtitle')
            : tr('engineScreen.wizard.autoSubtitle'),
      _ => tr('engineScreen.wizard.startSubtitle'),
    };
    final content = switch (_wizardStep) {
      0 => _wizardModelStep(),
      1 => _wizardSettingsStep(),
      _ => _wizardStartStep(),
    };
    return Column(
      key: const Key('engine-wizard'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            wizardStepNav(
              0,
              tr('engineScreen.wizard.model'),
              enabled: true,
              done: hasModel,
              currentStep: _wizardStep,
              onSelect: (s) => setState(() => _wizardStep = s),
            ),
            wizardStepDivider(),
            wizardStepNav(
              1,
              tr('engineScreen.wizard.configure'),
              enabled: hasModel,
              currentStep: _wizardStep,
              onSelect: (s) => setState(() => _wizardStep = s),
            ),
            wizardStepDivider(),
            wizardStepNav(
              2,
              tr('engineScreen.wizard.start'),
              enabled: hasModel && hasPlan,
              currentStep: _wizardStep,
              onSelect: (s) => setState(() => _wizardStep = s),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          key: const Key('engine-start-card'),
          padding: const EdgeInsets.only(top: 20),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: engineAction.withValues(alpha: 0.5)),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr('engineScreen.wizard.step', {
                  'step': (_wizardStep + 1).toString(),
                }),
                style: const TextStyle(
                  color: Color(0xFFEBD9A8),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 22),
              content,
            ],
          ),
        ),
      ],
    );
  }

  Widget _wizardModelStep() {
    final models = _controller.models;
    if (models.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Column(
          children: [
            Icon(Icons.folder_off_outlined, color: Colors.white30),
            SizedBox(height: 12),
            Text(
              tr('engineScreen.wizard.noLocalModels'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ),
      );
    }
    // Two rows of cards before it scrolls: enough to compare at a glance
    // without the picker taking over the wizard.
    const rows = 2;
    final height = models.length <= 2
        ? _modelCardExtent
        : (_modelCardExtent * rows) + CulpeoLayout.gridGap;
    return SizedBox(
      height: height,
      child: GridView.builder(
        padding: EdgeInsets.zero,
        gridDelegate: culpeoGridDelegate(extent: _modelCardExtent),
        itemCount: models.length,
        itemBuilder: (context, index) {
          final model = models[index];
          return _modelCard(model, model.id == _controller.selectedModelId);
        },
      ),
    );
  }

  static const double _modelCardExtent = 166;

  /// One model as a card. The same information the old row carried, laid out so
  /// several models can be compared side by side rather than scanned top down.
  Widget _modelCard(ModelRecord model, bool selected) {
    final deleting = _controller.busyModels.contains(model.id);
    return CulpeoGridTile(
      key: Key('engine-model-${model.id}'),
      selected: selected,
      semanticLabel: model.name,
      onTap: model.isStartable ? () => _selectModel(model) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CulpeoCardSlot(
            height: 22,
            child: Row(
              children: [
                Expanded(
                  child: Tooltip(
                    message: model.relativePath.isEmpty
                        ? model.name
                        : model.relativePath,
                    child: Text(
                      model.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selected
                            ? CulpeoColors.textPrimary
                            : Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                EngineStatusBadge(status: model.status),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Rows, not Wrap: the tile height is fixed by the grid, so a pill row
          // that wrapped would push the footer out and clip it. Pills shrink
          // and ellipsise instead.
          CulpeoCardSlot(
            height: 26,
            child: Row(
              children: [
                Flexible(
                  child: CulpeoStatPill(
                    icon: Icons.sd_storage_outlined,
                    label: formatBytes(model.sizeBytes),
                  ),
                ),
                if (model.quantization.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Flexible(
                    child: CulpeoStatPill(
                      icon: Icons.compress_rounded,
                      label: model.quantization,
                      color: CulpeoColors.metricSoft,
                      tooltip: tr('engineScreen.model.quantizationTooltip'),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 6),
          CulpeoCardSlot(
            height: 26,
            child: Row(
              children: [
                if (model.modelContextLimitTokens > 0)
                  Flexible(
                    child: CulpeoStatPill(
                      icon: Icons.notes_rounded,
                      label: formatTokenCount(model.modelContextLimitTokens),
                      color: CulpeoColors.info,
                      tooltip: tr('engineScreen.model.contextTooltip'),
                    ),
                  ),
                if (model.architecture.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Flexible(
                    child: CulpeoStatPill(
                      icon: Icons.account_tree_outlined,
                      label: model.architecture,
                      color: CulpeoColors.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Spacer(),
          Row(
            children: [
              if (!model.isStartable)
                Expanded(
                  child: Text(
                    tr('engineScreen.model.notStartable'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: CulpeoColors.warning, fontSize: 11),
                  ),
                )
              else if (selected)
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 14,
                        color: CulpeoColors.action,
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          tr('engineScreen.model.selected'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: CulpeoColors.action,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                const Spacer(),
              if (deleting)
                const SizedBox(
                  width: 15,
                  height: 15,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else ...[
                if (model.isStartable)
                  IconButton(
                    key: Key('engine-quantize-model-${model.id}'),
                    onPressed: () => _quantizeModel(model),
                    icon: const Icon(Icons.compress, size: 17),
                    color: CulpeoColors.textFaint,
                    tooltip: tr('engineScreen.model.quantizeTooltip'),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 30,
                      minHeight: 30,
                    ),
                  ),
                IconButton(
                  key: Key('engine-delete-model-${model.id}'),
                  onPressed: () => _deleteModel(model),
                  icon: const Icon(Icons.delete_outline, size: 17),
                  color: CulpeoColors.textFaint,
                  tooltip: tr('engineScreen.model.deleteTooltip'),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 30,
                    minHeight: 30,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// Applying a preset writes its values into the form rather than bypassing
  /// it: the user sees what changed and can still adjust before starting, and
  /// the planner recomputes from the same fields it always did.
  void _applyPreset(EnginePreset preset) {
    final config = preset.config;
    final options = config.runtimeOptions;
    setState(() {
      _runtime = config.runtime;
      _contextMode = config.contextMode;
      _contextController.text = config.contextTokens?.toString() ?? '';
      _maxSequencesController.text = config.maxSequences.toString();
      _priority = config.priority;
      _kvCachePolicy = config.kvCachePolicy;
      _allowFallback = config.allowFallback;
      _autostart = config.autostart;
      _gatewayAutostart = config.gatewayAutostart;
      _restartOnCrash = config.restartOnCrash;
      _idleTimeoutSeconds = config.idleTimeoutSeconds ?? 0;

      _useRamOffload = options['allow_ram_offload'] == true;
      _forceCpuRuntime = options['force_cpu_runtime'] == true;
      _gpuLayersController.text = (options['gpu_layers'] ?? '').toString();
      _threadsController.text = (options['threads'] ?? '').toString();
      final dtype = (options['kv_cache_dtype'] ?? '').toString();
      if (dtype.isNotEmpty) _kvCacheDtype = dtype;
      final flash = (options['flash_attention'] ?? '').toString();
      _flashAttention = flash.isEmpty ? 'auto' : flash;
    });
    unawaited(_controller.refreshRecommendation(_draftConfig()));
    showTopNotification(
      context,
      tr('engineScreen.preset.applied', {'name': preset.name}),
      color: CulpeoColors.metric,
    );
  }

  Future<void> _openPresetManager() async {
    final applied = await showEnginePresetDialog(
      context,
      currentConfig: _draftConfig(),
      modelId: _controller.selectedModel?.id ?? '',
      api: widget.api,
    );
    if (!mounted || applied == null) return;
    _applyPreset(applied);
  }

  /// The entry point to the saved configurations, sitting above the fields it
  /// fills in.
  Widget _presetBar() {
    return Align(
      alignment: Alignment.centerLeft,
      child: OutlinedButton.icon(
        key: const Key('engine-open-presets'),
        onPressed: _openPresetManager,
        icon: const Icon(Icons.bookmarks_outlined, size: 16),
        label: Text(tr('engineScreen.preset.open')),
        style: OutlinedButton.styleFrom(
          foregroundColor: CulpeoColors.textSecondary,
          side: BorderSide(color: CulpeoColors.hairlineStrong),
        ),
      ),
    );
  }

  Widget _wizardSettingsStep() {
    final model = _controller.selectedModel;
    if (model == null) return const SizedBox.shrink();
    final recommendation = _controller.recommendation;
    final repairOperation = _controller.gpuRepairOperation;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _presetBar(),
        const SizedBox(height: 14),
        if (_controller.isLoadingRecommendation)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LinearProgressIndicator(minHeight: 3),
              SizedBox(height: 9),
              Text(
                tr('engineScreen.wizard.calculating'),
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          )
        else if (recommendation != null) ...[
          EngineContextBar(plan: recommendation),
          const SizedBox(height: 14),
          EnginePreflightCard(plan: recommendation),
          const SizedBox(height: 14),
          _memorySummary(recommendation),
          if (_useRamOffload) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: engineBlue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: engineBlue.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.memory_outlined,
                    color: engineAccent,
                    size: 18,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      _forceCpuRuntime
                          ? tr('engineScreen.wizard.cpuMode')
                          : tr('engineScreen.wizard.hybridMode'),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (recommendation.warnings.isNotEmpty) ...[
            const SizedBox(height: 12),
            engineWarningBox(recommendation.warnings.join('\n')),
          ],
        ],
        if (_planningIssue != null) ...[
          const SizedBox(height: 12),
          engineWarningBox(_planningIssue!),
        ],
        if (_controller.isRepairingGpuRuntime) ...[
          const SizedBox(height: 14),
          gpuRepairProgress(repairOperation),
        ],
        const SizedBox(height: 18),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text(
            tr('engineScreen.expert.title'),
            style: const TextStyle(color: Colors.white),
          ),
          subtitle: Text(
            tr('engineScreen.expert.subtitle'),
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
          value: _expertMode,
          onChanged: (value) => setState(() => _expertMode = value),
        ),
        if (recommendation != null) ...[
          const SizedBox(height: 14),
          _contextBudget(recommendation),
        ],
        if (_expertMode) ...[
          const Divider(color: Colors.white10),
          const SizedBox(height: 10),
          _buildContextFields(),
          const SizedBox(height: 14),
          _buildExpertFields(model),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: _controller.isLoadingRecommendation
                  ? null
                  : _refreshRecommendation,
              icon: const Icon(Icons.calculate_outlined),
              label: Text(tr('engineScreen.expert.recalculatePlan')),
            ),
          ),
        ],
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.tonalIcon(
            key: const Key('engine-calculate-and-continue'),
            onPressed:
                _controller.isLoadingRecommendation ||
                    _controller.isRepairingGpuRuntime
                ? null
                : _calculateAndContinue,
            icon: _controller.isLoadingRecommendation
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.calculate_outlined, size: 18),
            label: Text(tr('engineScreen.wizard.calculateContinue')),
          ),
        ),
      ],
    );
  }

  Widget _wizardStartStep() {
    final model = _controller.selectedModel;
    if (model == null) return const SizedBox.shrink();
    final operation = _activeSetupOperation();
    final setupInstance = _setupInstance();
    final failedInstance = _lastFailedSetupInstance();
    final busy = _controller.busyInstances.contains('new') || operation != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!_expertMode)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              children: [
                Icon(
                  Icons.auto_awesome_outlined,
                  size: 17,
                  color: Color(0xFFEBD9A8),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tr('engineScreen.wizard.autoMode'),
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        if (operation != null) ...[
          Container(
            key: const Key('engine-current-setup-step'),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: engineBlue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: engineBlue.withValues(alpha: 0.16)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.sync, color: Color(0xFFEBD9A8), size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _currentSetupStep(
                      operation: operation,
                      runtime: _activeSetupRuntime(),
                      instance: setupInstance,
                    ),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: operation.progress > 0 ? operation.progress : null,
            minHeight: 4,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 6),
          Text(
            operation.progress > 0
                ? tr('engineScreen.progress.complete', {
                    'percent': (operation.progress * 100).round().toString(),
                  })
                : tr('engineScreen.progress.preparing'),
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
          const SizedBox(height: 16),
        ] else if (failedInstance != null) ...[
          Container(
            key: const Key('engine-setup-friendly-error'),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF44336).withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFFF44336).withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Color(0xFFEF9A9A),
                  size: 19,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    instanceErrorMessage(failedInstance),
                    style: const TextStyle(
                      color: Color(0xFFFFCDD2),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (failedInstance.suggestedFix != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                key: const Key('engine-setup-retry'),
                onPressed: () => _applySuggestedFix(
                  failedInstance,
                  failedInstance.suggestedFix!,
                ),
                icon: const Icon(Icons.auto_fix_high, size: 17),
                label: Text(failedInstance.suggestedFix!.label),
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.tonalIcon(
                key: const Key('engine-instance-retry'),
                onPressed: () => _instanceAction(failedInstance, 'start'),
                icon: const Icon(Icons.refresh),
                label: Text(tr('engineScreen.action.retry')),
              ),
            ),
          ],
          const SizedBox(height: 16),
        ],
        Align(
          alignment: Alignment.centerRight,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 220),
            child: FilledButton.icon(
              key: const Key('engine-create-instance'),
              onPressed: busy ? null : _createInstance,
              icon: busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.play_arrow_rounded),
              label: Text(tr('engineScreen.wizard.startModel')),
            ),
          ),
        ),
      ],
    );
  }

  EngineOperation? _activeSetupOperation() {
    return _controller.operations.values
        .where((operation) => !operation.isTerminal)
        .firstOrNull;
  }

  RuntimeCapability? _activeSetupRuntime() {
    return _controller.runtimes
        .where((runtime) => _runtimeSetupInProgress(runtime.status))
        .firstOrNull;
  }

  EngineInstance? _setupInstance() {
    return _controller.instances.where((instance) {
      return const {
        'installing',
        'queued',
        'starting',
        'draining',
        'restarting',
      }.contains(instance.state);
    }).firstOrNull;
  }

  EngineInstance? _lastFailedSetupInstance() {
    return _controller.instances
        .where(
          (instance) =>
              const {'failed', 'failed_rollback'}.contains(instance.state) &&
              instance.modelId == _controller.selectedModelId,
        )
        .firstOrNull;
  }

  /// Which prebuilt llama-server this machine resolved to.
  ///
  /// It is a property of the hardware, not of any one instance, so it belongs
  /// beside the page title rather than on each card. Seeing "CUDA" or "CPU"
  /// here answers the first question a slow model raises.
  List<Widget> _buildVariantBadge() {
    for (final runtime in _controller.runtimes) {
      if (runtime.variant.isEmpty) continue;
      final cpu = runtime.variant.toLowerCase() == 'cpu';
      return [
        CulpeoBadge(
          label: runtime.variant,
          icon: cpu ? Icons.memory_rounded : Icons.bolt_rounded,
          color: cpu ? CulpeoColors.textMuted : CulpeoColors.action,
          tooltip: runtime.buildVersion.isEmpty
              ? tr('engineScreen.header.variantTooltip')
              : '${tr('engineScreen.header.variantTooltip')}\n${runtime.buildVersion}',
        ),
      ];
    }
    return const [];
  }

  Widget _buildHeader() {
    return Column(
      key: const Key('engine-header'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HeaderMark(),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Flexible, not bare: at narrow widths the badge would
                      // otherwise push the title past the edge.
                      Flexible(
                        child: Text(
                          tr('engineScreen.header.title'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ..._buildVariantBadge(),
                    ],
                  ),
                  SizedBox(height: 5),
                  Text(
                    tr('engineScreen.header.subtitle'),
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const AutoSyncStatus(),
        const SizedBox(height: 16),
        Container(
          height: 2,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            gradient: LinearGradient(
              colors: [
                engineAction.withValues(alpha: 0.85),
                CulpeoColors.actionHover.withValues(alpha: 0.35),
                Colors.white.withValues(alpha: 0),
              ],
              stops: const [0, 0.4, 1],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF44336).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFF44336).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFEF5350)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _controller.error!,
              style: const TextStyle(color: Color(0xFFFFCDD2)),
            ),
          ),
          IconButton(
            tooltip: tr('engineScreen.error.dismiss'),
            onPressed: _controller.clearError,
            icon: const Icon(Icons.close, color: Colors.white60),
          ),
        ],
      ),
    );
  }

  /// Where the context budget runs out.
  ///
  /// The engine will not spill into system RAM unless the user says so, which
  /// makes one number the whole decision: the token count past which VRAM alone
  /// no longer holds the cache. Showing the two ceilings side by side turns
  /// that from a rejection message into a choice made up front.
  Widget _contextBudget(ContextPlan plan) {
    final gpuOnly = plan.gpuOnlyMaxContextTokens;
    final hybrid = plan.hybridMaxContextTokens;
    if (gpuOnly <= 0 && hybrid <= 0) return const SizedBox.shrink();
    final ramAdds = hybrid > gpuOnly;
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: CulpeoColors.inset,
        borderRadius: BorderRadius.circular(CulpeoLayout.cardRadius),
        border: Border.all(color: CulpeoColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr('engineScreen.context.budgetTitle'),
            style: TextStyle(
              color: CulpeoColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 9),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              CulpeoStatPill(
                icon: Icons.videogame_asset_outlined,
                label: tr('engineScreen.context.gpuOnly', {
                  'tokens': formatTokenCount(gpuOnly),
                }),
                color: CulpeoColors.vram,
                tooltip: tr('engineScreen.context.gpuOnlyTooltip'),
              ),
              if (ramAdds)
                CulpeoStatPill(
                  icon: Icons.memory_rounded,
                  label: tr('engineScreen.context.withRam', {
                    'tokens': formatTokenCount(hybrid),
                  }),
                  color: CulpeoColors.ram,
                  tooltip: tr('engineScreen.context.withRamTooltip'),
                ),
              CulpeoStatPill(
                icon: Icons.straighten_rounded,
                label: tr('engineScreen.context.perToken', {
                  'size': formatBytes(plan.kvBytesPerTokenAtStart),
                }),
                color: CulpeoColors.metricSoft,
                tooltip: tr('engineScreen.context.perTokenTooltip'),
              ),
              if (plan.kvCacheDtype.isNotEmpty)
                CulpeoStatPill(
                  icon: Icons.compress_rounded,
                  label: plan.kvCacheDtype.toUpperCase(),
                  color: CulpeoColors.metric,
                  tooltip: tr('engineScreen.context.cacheTypeTooltip'),
                ),
            ],
          ),
          if (ramAdds && !_useRamOffload) ...[
            const SizedBox(height: 10),
            Text(
              tr('engineScreen.context.ramWouldExtend', {
                'tokens': formatTokenCount(gpuOnly),
              }),
              style: TextStyle(
                color: CulpeoColors.textMuted,
                fontSize: 11.5,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContextFields() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final contextMode = DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: _contextMode,
          dropdownColor: enginePanelColor,
          decoration: _inputDecoration(
            tr('engineScreen.field.contextPlanning'),
            tr('engineScreen.field.restartRequired'),
          ),
          items: [
            DropdownMenuItem(
              value: 'auto_max',
              child: Text(tr('engineScreen.field.autoMaximum')),
            ),
            DropdownMenuItem(
              value: 'fixed',
              child: Text(tr('engineScreen.field.fixedContext')),
            ),
          ],
          onChanged: (value) {
            if (value == null) return;
            setState(() => _contextMode = value);
          },
        );
        final contextValue = TextField(
          controller: _contextController,
          enabled: _contextMode == 'fixed',
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: _inputDecoration(
            tr('engineScreen.field.maximumContext'),
            _contextMode == 'fixed'
                ? tr('engineScreen.field.token')
                : tr('engineScreen.field.autoCalculated'),
          ),
        );
        if (constraints.maxWidth < 520) {
          return Column(
            children: [contextMode, const SizedBox(height: 12), contextValue],
          );
        }
        return Row(
          children: [
            Expanded(child: contextMode),
            const SizedBox(width: 12),
            Expanded(child: contextValue),
          ],
        );
      },
    );
  }

  Widget _buildExpertFields(ModelRecord model) {
    final runtimeIds = <String>{
      'auto',
      ...model.runtimeCandidates,
      ..._controller.runtimes.map((runtime) => runtime.id),
    }.where((value) => value.isNotEmpty).toList();
    if (!runtimeIds.contains(_runtime)) runtimeIds.insert(0, _runtime);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _responsiveFieldPair(
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: _runtime,
            dropdownColor: enginePanelColor,
            decoration: _inputDecoration(
              tr('engineScreen.field.runtime'),
              tr('engineScreen.field.autoSelectsAdapter'),
            ),
            items: runtimeIds
                .map(
                  (id) => DropdownMenuItem(
                    value: id,
                    child: Text(
                      id == 'auto' ? tr('engineScreen.field.automatic') : id,
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _runtime = value ?? 'auto'),
          ),
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: _priority,
            dropdownColor: enginePanelColor,
            decoration: _inputDecoration(
              tr('engineScreen.field.priority'),
              tr('engineScreen.field.pinnedHelp'),
            ),
            items: [
              DropdownMenuItem(
                value: 'low',
                child: Text(tr('engineScreen.field.low')),
              ),
              DropdownMenuItem(
                value: 'normal',
                child: Text(tr('engineScreen.field.normal')),
              ),
              DropdownMenuItem(
                value: 'high',
                child: Text(tr('engineScreen.field.high')),
              ),
              DropdownMenuItem(
                value: 'pinned',
                child: Text(tr('engineScreen.field.pinned')),
              ),
            ],
            onChanged: (value) => setState(() => _priority = value ?? 'normal'),
          ),
        ),
        const SizedBox(height: 12),
        _responsiveFieldPair(
          _numberField(
            _gpuLayersController,
            tr('engineScreen.field.gpuLayers'),
            tr('engineScreen.field.emptyAuto'),
          ),
          _numberField(
            _threadsController,
            tr('engineScreen.field.cpuThreads'),
            tr('engineScreen.field.emptyAuto'),
          ),
        ),
        const SizedBox(height: 12),
        _responsiveFieldPair(
          _numberField(
            _tensorParallelController,
            tr('engineScreen.field.tensorParallelism'),
            tr('engineScreen.field.gpuCount'),
          ),
          _numberField(
            _maxSequencesController,
            tr('engineScreen.field.parallelSequences'),
            tr('engineScreen.field.minimumOne'),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _gpuIdsController,
          style: const TextStyle(color: Colors.white),
          decoration: _inputDecoration(
            tr('engineScreen.field.gpuIds'),
            tr('engineScreen.field.gpuIdsHelp'),
          ),
        ),
        const SizedBox(height: 12),
        _responsiveFieldPair(
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: _offload,
            dropdownColor: enginePanelColor,
            decoration: _inputDecoration(
              tr('engineScreen.field.offload'),
              tr('engineScreen.field.restartRequired'),
            ),
            items: [
              DropdownMenuItem(
                value: 'auto',
                child: Text(tr('engineScreen.field.automatic')),
              ),
              DropdownMenuItem(
                value: 'gpu',
                child: Text(tr('engineScreen.field.preferGpu')),
              ),
              DropdownMenuItem(
                value: 'cpu',
                child: Text(tr('engineScreen.field.preferRamCpu')),
              ),
            ],
            onChanged: (value) => setState(() => _offload = value ?? 'auto'),
          ),
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: _kvCacheDtype,
            dropdownColor: enginePanelColor,
            decoration: _inputDecoration(
              tr('engineScreen.field.kvCacheDtype'),
              tr('engineScreen.field.weightsUnchanged'),
            ),
            items: [
              DropdownMenuItem(
                value: 'auto',
                child: Text(tr('engineScreen.field.policyDecides')),
              ),
              // Driven by what the installed build reported, so a build with
              // sub-4-bit caches offers them and one without does not.
              for (final type in _availableCacheTypes())
                DropdownMenuItem(value: type, child: Text(type.toUpperCase())),
            ],
            onChanged: (value) =>
                setState(() => _kvCacheDtype = value ?? 'auto'),
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: _flashAttention,
          dropdownColor: enginePanelColor,
          decoration: _inputDecoration(
            tr('engineScreen.field.flashAttention'),
            tr('engineScreen.field.flashAttentionHelp'),
          ),
          items: [
            DropdownMenuItem(
              value: 'auto',
              child: Text(tr('engineScreen.field.flashAttentionAuto')),
            ),
            DropdownMenuItem(
              value: 'on',
              child: Text(tr('engineScreen.field.flashAttentionOn')),
            ),
            DropdownMenuItem(
              value: 'off',
              child: Text(tr('engineScreen.field.flashAttentionOff')),
            ),
          ],
          onChanged: (value) =>
              setState(() => _flashAttention = value ?? 'auto'),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: _kvCachePolicy,
          dropdownColor: enginePanelColor,
          decoration: _inputDecoration(
            tr('engineScreen.field.kvCachePolicy'),
            tr('engineScreen.field.kvCachePolicyHelp'),
          ),
          items: [
            DropdownMenuItem(
              value: 'prefer_4bit',
              child: Text(tr('engineScreen.field.prefer4Bit')),
            ),
            DropdownMenuItem(
              value: 'native',
              child: Text(tr('engineScreen.field.nativeCacheOnly')),
            ),
          ],
          onChanged: (value) =>
              setState(() => _kvCachePolicy = value ?? 'prefer_4bit'),
        ),
        const SizedBox(height: 4),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text(
            tr('engineScreen.field.autoModeRecommended'),
            style: const TextStyle(color: Colors.white),
          ),
          subtitle: Text(
            tr('engineScreen.field.autoModeHelp'),
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
          value: _allowFallback,
          onChanged: (value) => setState(() => _allowFallback = value),
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text(
            tr('engineScreen.field.allowRamOffload'),
            style: const TextStyle(color: Colors.white),
          ),
          subtitle: Text(
            tr('engineScreen.field.allowRamOffloadHelp'),
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
          value: _useRamOffload,
          onChanged: (value) => setState(() => _useRamOffload = value),
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text(
            tr('engineScreen.field.autostart'),
            style: const TextStyle(color: Colors.white),
          ),
          subtitle: Text(
            tr('engineScreen.field.autostartHelp'),
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
          value: _autostart,
          onChanged: (value) => setState(() => _autostart = value),
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text(
            tr('engineScreen.field.gatewayAutostart'),
            style: const TextStyle(color: Colors.white),
          ),
          subtitle: Text(
            tr('engineScreen.field.gatewayAutostartHelp'),
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
          value: _gatewayAutostart,
          onChanged: (value) => setState(() => _gatewayAutostart = value),
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text(
            tr('engineScreen.field.restartOnCrash'),
            style: const TextStyle(color: Colors.white),
          ),
          subtitle: Text(
            tr('engineScreen.field.restartOnCrashHelp'),
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
          value: _restartOnCrash,
          onChanged: (value) => setState(() => _restartOnCrash = value),
        ),
        const SizedBox(height: 8),
        _idleTimeoutField(),
      ],
    );
  }

  /// How long an unused instance stays loaded. "Keep loaded" is its own choice
  /// rather than a very large number, because that is what people actually
  /// want when they pin a model for the day.
  Widget _idleTimeoutField() {
    return DropdownButtonFormField<int>(
      initialValue: _idleTimeoutSeconds,
      dropdownColor: const Color(0xFF1A1A1A),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: tr('engineScreen.field.idleTimeout'),
        helperText: tr('engineScreen.field.idleTimeoutHelp'),
        helperStyle: const TextStyle(color: Colors.white38, fontSize: 12),
        labelStyle: const TextStyle(color: Colors.white54),
      ),
      items: [
        DropdownMenuItem(
          value: 0,
          child: Text(tr('engineScreen.field.idleTimeoutDefault')),
        ),
        DropdownMenuItem(
          value: 300,
          child: Text(tr('engineScreen.field.idleTimeout5Minutes')),
        ),
        DropdownMenuItem(
          value: 1800,
          child: Text(tr('engineScreen.field.idleTimeout30Minutes')),
        ),
        DropdownMenuItem(
          value: 7200,
          child: Text(tr('engineScreen.field.idleTimeout2Hours')),
        ),
        DropdownMenuItem(
          value: -1,
          child: Text(tr('engineScreen.field.idleTimeoutNever')),
        ),
      ],
      onChanged: (value) => setState(() => _idleTimeoutSeconds = value ?? 0),
    );
  }

  Widget _responsiveFieldPair(Widget first, Widget second) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 520) {
          return Column(children: [first, const SizedBox(height: 12), second]);
        }
        return Row(
          children: [
            Expanded(child: first),
            const SizedBox(width: 12),
            Expanded(child: second),
          ],
        );
      },
    );
  }

  Widget _numberField(
    TextEditingController controller,
    String label,
    String helper,
  ) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration(label, helper),
    );
  }

  InputDecoration _inputDecoration(String label, String helper) {
    return InputDecoration(
      labelText: label,
      helperText: helper,
      helperMaxLines: 2,
      labelStyle: const TextStyle(color: Colors.white60),
      helperStyle: const TextStyle(color: Colors.white30, fontSize: 12),
      filled: true,
      fillColor: engineInsetColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _memorySummary(ContextPlan plan) {
    return Wrap(
      spacing: 12,
      runSpacing: 6,
      children: [
        Text(
          tr('engineScreen.memory.weights', {
            'size': formatBytes(plan.memory.weightsBytes),
          }),
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        Text(
          tr('engineScreen.memory.kvCache', {
            'size': formatBytes(plan.memory.kvCacheBytes),
          }),
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        Text(
          tr('engineScreen.memory.runtime', {
            'size': formatBytes(plan.memory.runtimeBytes),
          }),
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        Text(
          plan.ramRequiredAfterTokens == null
              ? tr('engineScreen.memory.noRamOffload', {
                  'confidence': plan.confidence,
                })
              : tr('engineScreen.memory.ramAfter', {
                  'confidence': plan.confidence,
                  'tokens': formatTokenCount(plan.ramRequiredAfterTokens!),
                }),
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildInstances() {
    final instances = _controller.instances;
    return EnginePanel(
      key: const Key('engine-instances'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EngineSectionTitle(
            icon: Icons.dns_outlined,
            title: tr('engineScreen.instances.title'),
            subtitle: tr('engineScreen.instances.subtitle', {
              'count': instances.length.toString(),
              'modelLabel': tr(
                instances.length == 1
                    ? 'engineScreen.instances.modelSingular'
                    : 'engineScreen.instances.modelPlural',
              ),
            }),
          ),
          const SizedBox(height: 15),
          if (instances.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  Icon(Icons.power_off, color: Colors.white30, size: 30),
                  SizedBox(height: 10),
                  Text(
                    tr('engineScreen.instances.empty'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: instances.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final instance = instances[index];
                return InstanceCard(
                  instance: instance,
                  models: _controller.models,
                  busy: _controller.busyInstances.contains(instance.id),
                  expanded: _expandedInstances.contains(instance.id),
                  onToggleExpanded: () => setState(() {
                    if (_expandedInstances.contains(instance.id)) {
                      _expandedInstances.remove(instance.id);
                    } else {
                      _expandedInstances.add(instance.id);
                    }
                  }),
                  onAction: (action) => _instanceAction(instance, action),
                  onDelete: () => _deleteInstance(instance),
                  onEditContext: () => _editContext(instance),
                  onEditSampling: () => _editSampling(instance),
                  onApplySuggestedFix: () =>
                      _applySuggestedFix(instance, instance.suggestedFix!),
                  onUpdateInstance: (patch) =>
                      _controller.updateInstance(instance.id, patch),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildRuntimeDetails() {
    final runtimes = _controller.runtimes;
    return Column(
      key: const Key('engine-runtime-details'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          tr('engineScreen.diagnostics.technicalComponents'),
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 9),
        if (runtimes.isEmpty)
          Text(
            tr('engineScreen.diagnostics.noComponents'),
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          )
        else
          ...runtimes.map(
            (runtime) => Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: engineInsetColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            runtimeLabel(
                              runtime.name.isEmpty ? runtime.id : runtime.name,
                            ),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        EngineStatusBadge(status: runtime.status),
                      ],
                    ),
                    if (runtime.statusMessage.isNotEmpty) ...[
                      const SizedBox(height: 7),
                      Text(
                        runtime.statusMessage,
                        key: Key('engine-runtime-message-${runtime.id}'),
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    if (_runtimeSetupInProgress(runtime.status)) ...[
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: runtime.progress > 0 ? runtime.progress : null,
                        minHeight: 3,
                      ),
                    ],
                    if (runtime.error != null) ...[
                      const SizedBox(height: 7),
                      Text(
                        tr('engineScreen.diagnostics.technicalDiagnosis'),
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      SelectableText(
                        runtime.error!,
                        style: const TextStyle(
                          color: Color(0xFFEF9A9A),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildOperationDetails() {
    final operations = _controller.operations.values.toList().reversed.toList();
    return Column(
      key: const Key('engine-operation-details'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          tr('engineScreen.operations.current'),
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 9),
        ...operations.map(
          (operation) => Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _friendlyOperationMessage(operation),
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 5),
                      LinearProgressIndicator(
                        value: operation.progress > 0
                            ? operation.progress
                            : null,
                        minHeight: 3,
                      ),
                      if (operation.error != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          tr('engineScreen.diagnostics.technicalDiagnosis'),
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SelectableText(
                          operation.error!,
                          style: const TextStyle(
                            color: Color(0xFFEF9A9A),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                EngineStatusBadge(status: operation.state),
                if (!operation.isTerminal)
                  IconButton(
                    tooltip: tr('engineScreen.operations.cancel'),
                    onPressed: () => _controller.cancelOperation(operation.id),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white54,
                      size: 18,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  bool _runtimeSetupInProgress(String status) => const {
    'queued',
    'creating_environment',
    'installing',
    'installing_packages',
    'probing',
  }.contains(status);

  String _currentSetupStep({
    required EngineOperation? operation,
    required RuntimeCapability? runtime,
    required EngineInstance? instance,
  }) {
    if (operation?.detailMessage.trim().isNotEmpty == true) {
      return operation!.detailMessage.trim();
    }
    if (instance?.detailMessage.trim().isNotEmpty == true) {
      return instance!.detailMessage.trim();
    }
    if (operation != null &&
        operation.message?.trim().isNotEmpty == true &&
        !operation.message!.contains('wurde eingeplant')) {
      return _friendlyOperationMessage(operation);
    }
    if (runtime != null && runtime.statusMessage.trim().isNotEmpty) {
      return runtime.statusMessage.trim();
    }
    if (operation != null) return _friendlyOperationMessage(operation);
    if (instance != null) return instanceStageDescription(instance);
    return tr('engineScreen.operation.defaultPreparing');
  }

  String _friendlyOperationMessage(EngineOperation operation) {
    var message = operation.detailMessage.trim().isNotEmpty
        ? operation.detailMessage.trim()
        : operation.message?.trim() ?? '';
    if (message.isEmpty) {
      switch (operation.type) {
        case 'runtime_install':
          return tr('engineScreen.operation.installingComponents');
        case 'start':
          return tr('engineScreen.operation.loadingModel');
        default:
          return tr('engineScreen.operation.defaultPreparing');
      }
    }
    message = message
        .replaceAll(
          sourceText('engineScreen.operation.runtimeLlamaCppSource'),
          tr('engineScreen.operation.runtimeLlamaCpp'),
        )
        .replaceAll(
          sourceText('engineScreen.operation.warmingUpSource'),
          tr('engineScreen.operation.isWarmingUp'),
        );
    return message;
  }

  String _friendlyRuntimeError(RuntimeCapability runtime) {
    switch (runtime.errorCode) {
      case 'compiler_missing':
        return runtime.error?.isNotEmpty == true
            ? runtime.error!
            : tr('engineScreen.runtimeError.compilerMissing');
      case 'disk_full':
        return tr('engineScreen.runtimeError.diskFull');
      case 'network_unavailable':
        return tr('engineScreen.runtimeError.networkUnavailable');
      case 'package_unavailable':
        return tr('engineScreen.runtimeError.packageUnavailable');
      case 'native_build_failed':
        return tr('engineScreen.runtimeError.nativeBuildFailed');
      case 'python_environment_failed':
        return tr('engineScreen.runtimeError.pythonEnvironmentFailed');
      case 'runtime_probe_failed':
        return tr('engineScreen.runtimeError.probeFailed');
    }
    final raw = runtime.error;
    if (raw != null && raw.isNotEmpty) return friendlyEngineError(raw);
    return tr('engineScreen.runtimeError.generic');
  }
}

enum _MemoryPlanChoice { cancel, useRam, rebuildGpu }
