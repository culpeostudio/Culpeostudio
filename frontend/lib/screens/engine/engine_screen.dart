import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../engine/controller.dart';
import '../../engine/engine_api.dart';
import '../../engine/models.dart';
import '../../engine/widgets.dart';
import '../../widgets/top_notification.dart';
import 'header_widgets.dart';
import 'instance_card.dart';
import 'wizard_widgets.dart';
import 'telemetry_widgets.dart';

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
  bool _useRamOffload = false;
  bool _allowFallback = true;
  bool _autostart = false;
  bool _trustRemoteCode = false;
  bool _showSetupDetails = false;
  bool _showTelemetryPanel = true;
  String? _planningIssue;
  final Set<String> _expandedInstances = <String>{};

  /// 0 = start a local model, 1 = inspect configured model instances.
  int _workspace = 0;

  /// Currently expanded wizard step (0 = model, 1 = settings, 2 = start).
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
          '${ready.length} Modelle wurden gestartet und sind bereit.',
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
        : 'Das Modell';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showTopNotification(
        context,
        '„$name“ wurde gestartet und ist bereit.',
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
      // Im geführten Modus wählt die 4-Bit-Policy den passenden Cache pro
      // Runtime (TurboQuant, Quanto oder Q4_0). Ein festes Q4_0 würde bei
      // vLLM TurboQuant überspringen.
      if (_expertMode) 'kv_cache_dtype': _kvCacheDtype,
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
      trustRemoteCode: _trustRemoteCode,
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

    // The fit test intentionally starts only after model selection, when the
    // user continues from phase 2. First calculate against dedicated VRAM.
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
    final gpuRuntimeRemediation =
        firstFailure?.code == 'gpu_runtime_unavailable'
        ? firstFailure?.details['remediation']?.toString()
        : null;
    if (firstFailure?.code != 'resource_conflict' &&
        firstFailure?.code != 'gpu_runtime_unavailable') {
      setState(() {
        _planningIssue =
            'Die automatische Berechnung konnte für dieses Modell nicht abgeschlossen werden.';
      });
      return;
    }

    // Either VRAM was insufficient or the GPU runtime is not usable yet. A
    // second dry run checks the explicit CPU/RAM fallback without starting it.
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
        _planningIssue =
            'Das Modell passt aktuell weder vollständig in den Grafikspeicher noch gemeinsam in GPU und freien System-RAM.';
      });
      return;
    }

    final choice = await _askToUseRam(
      model,
      hybridPlan,
      gpuRuntimeIssue: gpuRuntimeIssue,
      gpuRuntimeRemediation: gpuRuntimeRemediation,
    );
    if (!mounted) return;
    if (choice == _MemoryPlanChoice.repairGpu) {
      _controller.chooseModel(model.id);
      await _repairGpuRuntimeAndRetry(model);
      return;
    }
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
    // The successful automatic calculation completes phase 2 and unlocks the
    // actual start in phase 3.
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
    String? gpuRuntimeRemediation,
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
                  ? 'GPU-Unterstützung noch nicht bereit'
                  : 'System-RAM dazunehmen?',
              style: const TextStyle(color: Colors.white),
            ),
            content: Text(
              runtimeUnavailable
                  ? '„${model.name}“ wurde nicht wegen seiner Größe abgelehnt. '
                        'Die Grafikkarte wurde erkannt, aber die passende GPU-Runtime ist noch nicht einsatzbereit.\n\n'
                        '$gpuRuntimeIssue\n\n'
                        'Ein Start über CPU + System-RAM '
                        '${ram > 0 ? '(${formatBytes(ram)} RAM im Plan) ' : ''}ist möglich. Möchtest du diesen Fallback verwenden?'
                  : '„${model.name}“ passt nicht allein in den freien Grafikspeicher. '
                        'Die Berechnung zeigt, dass ein Start mit GPU + System-RAM '
                        '${ram > 0 ? '(${formatBytes(ram)} RAM im Plan) ' : ''}möglich ist.\n\n'
                        'Möchtest du diesen Hybridbetrieb verwenden?',
              style: const TextStyle(color: Colors.white70, height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.of(dialogContext).pop(_MemoryPlanChoice.cancel),
                child: const Text('Nein, anderes Modell wählen'),
              ),
              if (runtimeUnavailable)
                OutlinedButton.icon(
                  key: const Key('engine-auto-repair-gpu'),
                  onPressed: () => Navigator.of(dialogContext).pop(
                    gpuRuntimeRemediation == 'rebuild_gpu_runtime'
                        ? _MemoryPlanChoice.rebuildGpu
                        : _MemoryPlanChoice.repairGpu,
                  ),
                  icon: const Icon(Icons.build_circle_outlined),
                  label: Text(
                    gpuRuntimeRemediation == 'rebuild_gpu_runtime'
                        ? 'GPU-Runtime neu bauen'
                        : 'GPU automatisch einrichten',
                  ),
                ),
              FilledButton.icon(
                onPressed: () =>
                    Navigator.of(dialogContext).pop(_MemoryPlanChoice.useRam),
                icon: const Icon(Icons.check),
                label: Text(
                  runtimeUnavailable ? 'CPU/RAM verwenden' : 'RAM verwenden',
                ),
              ),
            ],
          ),
        ) ??
        _MemoryPlanChoice.cancel;
  }

  Future<void> _repairGpuRuntimeAndRetry(ModelRecord model) async {
    final consent = await _controller.createVulkanDependencyConsent();
    if (!mounted) return;
    if (consent == null) {
      if (_controller.requestFailure?.code == 'dependency_already_available') {
        _controller.clearError();
        await _rebuildGpuRuntimeAndRetry(model);
        return;
      }
      final message =
          _controller.error ??
          'Die automatische GPU-Einrichtung konnte nicht vorbereitet werden.';
      _controller.clearError();
      setState(() => _planningIssue = message);
      return;
    }

    final confirmed = await _confirmAdministratorAction(consent);
    if (!mounted) return;
    if (!confirmed) {
      setState(() {
        _planningIssue =
            'Die GPU-Einrichtung wurde nicht gestartet. Es wurden keine Systemänderungen vorgenommen.';
      });
      return;
    }

    setState(() => _planningIssue = null);
    final operation = await _controller.installVulkanGpuSupport(consent);
    if (!mounted) return;
    if (operation?.state == 'completed') {
      setState(() => _forceCpuRuntime = false);
      _controller.chooseModel(model.id);
      await _calculateAndContinue();
      return;
    }
    final message = operation?.errorSummary.isNotEmpty == true
        ? operation!.errorSummary
        : operation?.error?.isNotEmpty == true
        ? operation!.error!
        : _controller.error ??
              'Die GPU-Unterstützung konnte nicht automatisch eingerichtet werden.';
    _controller.clearError();
    setState(() => _planningIssue = message);
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
        : _controller.error ??
              'Die Vulkan-GPU-Runtime konnte nicht neu gebaut werden.';
    _controller.clearError();
    setState(() => _planningIssue = message);
  }

  Future<bool> _confirmAdministratorAction(
    SystemDependencyConsent consent,
  ) async {
    var acknowledged = false;
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => StatefulBuilder(
            builder: (context, setDialogState) => AlertDialog(
              key: const Key('engine-gpu-admin-consent-dialog'),
              backgroundColor: enginePanelColor,
              icon: const Icon(
                Icons.admin_panel_settings_outlined,
                color: engineAccent,
              ),
              title: const Text(
                'Administratorrechte erlauben?',
                style: TextStyle(color: Colors.white),
              ),
              content: SizedBox(
                width: 560,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PhiloEngine möchte die fehlenden Vulkan-Build-Abhängigkeiten installieren und danach eine GPU-Runtime bauen.',
                      style: TextStyle(color: Colors.white70, height: 1.4),
                    ),
                    const SizedBox(height: 14),
                    _adminConsentDetail(
                      'Systempakete',
                      consent.packageName.isEmpty
                          ? 'Vulkan-Build-Abhängigkeiten'
                          : consent.packageName,
                    ),
                    if (consent.commandSummary.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _adminConsentDetail(
                        'Geplante Aktion',
                        consent.commandSummary,
                      ),
                    ],
                    const SizedBox(height: 14),
                    const Text(
                      'Das Betriebssystem öffnet anschließend seinen eigenen Administrator-Dialog. PhiloEngine sieht oder speichert dein Passwort nicht.',
                      style: TextStyle(color: Colors.white70, height: 1.4),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Diese Erlaubnis gilt nur für diesen einen Versuch. Bei jeder späteren Systemänderung wirst du erneut informiert und musst wieder zustimmen.',
                      style: TextStyle(
                        color: Color(0xFFEBD9A8),
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                      ),
                    ),
                    if (consent.warning.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        consent.warning,
                        style: const TextStyle(
                          color: Color(0xFFFFCC80),
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    CheckboxListTile(
                      key: const Key('engine-gpu-admin-acknowledgement'),
                      contentPadding: EdgeInsets.zero,
                      value: acknowledged,
                      onChanged: (value) =>
                          setDialogState(() => acknowledged = value ?? false),
                      title: const Text(
                        'Ich habe die geplante Systemänderung verstanden.',
                        style: TextStyle(color: Colors.white),
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Abbrechen'),
                ),
                FilledButton.icon(
                  key: const Key('engine-open-admin-dialog'),
                  onPressed: acknowledged
                      ? () => Navigator.of(dialogContext).pop(true)
                      : null,
                  icon: const Icon(Icons.security_outlined),
                  label: const Text('Systemdialog öffnen'),
                ),
              ],
            ),
          ),
        ) ??
        false;
  }

  Widget _adminConsentDetail(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 112,
          child: Text(
            label,
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ),
        Expanded(
          child: SelectableText(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Future<void> _deleteModel(ModelRecord model) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: enginePanelColor,
        title: const Text(
          'Modell löschen?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          '„${model.name}“ wird aus der Liste und vom Speicher entfernt. '
          'Bei einem eigenen Modellpaket wird der vollständige zugehörige '
          'Ordner einschließlich Manifesten und Zusatzdateien gelöscht. '
          'Andere Modelle bleiben erhalten.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            key: const Key('engine-cancel-delete-model'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton.icon(
            key: const Key('engine-confirm-delete-model'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB3261E),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Endgültig löschen'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final ok = await _controller.deleteModel(model.id);
    if (!mounted) return;
    if (ok) {
      _showMessage('Modell und lokale Dateien wurden gelöscht.');
    } else {
      _showError();
    }
  }

  Future<void> _refreshRecommendation() async {
    final ok = await _controller.refreshRecommendation(_draftConfig());
    if (!mounted) return;
    if (!ok) _showError();
  }

  Future<void> _createInstance() async {
    final model = _controller.selectedModel;
    if (model == null) {
      _showMessage('Bitte zuerst ein startbares Modell auswählen.');
      return;
    }
    final config = _draftConfig();
    var ok = await _controller.createInstance(config);
    if (!mounted) return;
    final failure = _controller.requestFailure;
    if (!ok && failure?.requiresRemoteCodeConsent == true) {
      final accepted = await _showRemoteCodeConsent(model, failure!);
      if (!mounted || !accepted) return;
      final approved = await _controller.approveRemoteCode(model.id);
      if (!mounted) return;
      if (!approved) {
        _showError();
        return;
      }
      ok = await _controller.createInstance(config);
      if (!mounted) return;
    }
    if (ok) {
      _showMessage(
        'Instanz wurde eingeplant. Fehlende Runtime-Komponenten werden automatisch installiert.',
      );
    } else {
      _showError();
    }
  }

  Future<bool> _showRemoteCodeConsent(
    ModelRecord model,
    EngineApiException failure,
  ) async {
    final fileCount = failure.details['python_file_count'];
    final pythonHash = failure.details['python_files_hash']?.toString() ?? '';
    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        key: const Key('engine-remote-code-consent-dialog'),
        icon: const Icon(Icons.security_outlined, color: Color(0xFFDFC077)),
        title: const Text('Modellcode ausführen?'),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '„${model.name}“ enthält eigenen Python-Code, den die Runtime zum Laden ausführen möchte.',
              ),
              const SizedBox(height: 12),
              const Text(
                'Der Kindprozess ist keine Sandbox. Schädlicher Modellcode kann auf Dateien und andere Ressourcen deines Benutzerkontos zugreifen.',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              const Text(
                'Die Zustimmung gilt nur für den aktuellen Modellfingerprint und den Hash der Python-Dateien. Ändert sich eine Datei, fragt PhiloEngine erneut.',
              ),
              if (fileCount != null || pythonHash.isNotEmpty) ...[
                const SizedBox(height: 12),
                SelectableText(
                  [
                    if (fileCount != null) 'Python-Dateien: $fileCount',
                    if (pythonHash.isNotEmpty) 'Hash: $pythonHash',
                  ].join('\n'),
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: Colors.white60,
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            key: const Key('engine-remote-code-reject'),
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            key: const Key('engine-remote-code-accept'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Zustimmen & starten'),
          ),
        ],
      ),
    );
    return accepted == true;
  }

  Future<void> _refreshAll() async {
    final ok = await _controller.refreshAll();
    if (!mounted) return;
    _showMessage(
      ok
          ? 'Meine Modelle, Speicher und lokale Modelle sind aktuell.'
          : _controller.error,
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
      ok ? 'Instanzaktion „$action” wurde eingeplant.' : _controller.error,
    );
  }

  /// Executes the backend-suggested one-click remediation for a failed start.
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
              ? 'Die automatische Korrektur wurde gestartet.'
              : _controller.error,
        );
      case 'retry_with_ram':
        final confirmed = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            backgroundColor: enginePanelColor,
            icon: const Icon(Icons.memory_outlined, color: engineAccent),
            title: const Text(
              'System-RAM dazunehmen?',
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              'Der freie Grafikspeicher hat sich während der Vorbereitung geändert. Die Engine kann den Plan erneut mit dem aktuell freien System-RAM berechnen.',
              style: TextStyle(color: Colors.white70, height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Abbrechen'),
              ),
              FilledButton.icon(
                key: const Key('engine-confirm-retry-with-ram'),
                onPressed: () => Navigator.of(dialogContext).pop(true),
                icon: const Icon(Icons.check),
                label: const Text('Mit RAM neu berechnen'),
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
          ok ? 'GPU und System-RAM werden neu berechnet.' : _controller.error,
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
            await _repairGpuRuntimeAndRetry(model);
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
            ok ? 'Die Runtime wird neu vorbereitet.' : _controller.error,
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
        title: const Text('Instanz entfernen?'),
        content: Text(
          '„${instance.servedModelName.isEmpty ? instance.id : instance.servedModelName}“ wird gestoppt und aus der Engine entfernt.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Entfernen'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final ok = await _controller.deleteInstance(instance.id);
    if (!mounted) return;
    _showMessage(ok ? 'Instanz wurde entfernt.' : _controller.error);
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
          title: const Text(
            'Kontext festlegen',
            style: TextStyle(color: Colors.white),
          ),
          content: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${formatTokenCount(current)} Token sind aktiv und durch einen echten Modellstart geprüft. '
                  '${formatTokenCount(estimatedMaximum)} sind das rechnerische GPU+RAM-Maximum, aber noch keine Stabilitätsgarantie.',
                  style: const TextStyle(color: Colors.white70, height: 1.4),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Ein höherer Wert startet das Modell neu. Falls er nicht stabil ist, sucht die Engine automatisch zwischen dem letzten bestätigten Wert und der fehlgeschlagenen Obergrenze weiter. Das kann mehrere Modellstarts dauern.',
                  style: TextStyle(color: Color(0xFFEBD9A8), height: 1.4),
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
                      child: Text('Geprüft ${formatTokenCount(current)}'),
                    ),
                    OutlinedButton(
                      key: const Key('engine-context-use-estimated-max'),
                      onPressed: () => setDialogState(() {
                        valueController.text = estimatedMaximum.toString();
                        validationError = null;
                      }),
                      child: Text(
                        'Schätzung ${formatTokenCount(estimatedMaximum)} testen',
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
                    labelText: 'Kontext-Token',
                    helperText: 'Wählbar: $minimum bis $estimatedMaximum Token',
                    errorText: validationError,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Abbrechen'),
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
                        'Bitte einen Wert zwischen $minimum und $estimatedMaximum eingeben.',
                  );
                  return;
                }
                Navigator.of(dialogContext).pop(value);
              },
              icon: const Icon(Icons.restart_alt),
              label: const Text('Neu starten & prüfen'),
            ),
          ],
        ),
      ),
    );
    valueController.dispose();
    if (selected == null || !mounted) return;
    if (selected == current) {
      _showMessage('Der bereits geprüfte Kontext bleibt unverändert.');
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
                ? 'Der höhere Kontext wird jetzt gestartet und auf Stabilität geprüft.'
                : 'Der Kontext wird mit einem sicheren Neustart geändert.'
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
        title: const Text('Sampling-Defaults'),
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
                decoration: const InputDecoration(labelText: 'Temperature'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: topP,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Top P'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: maxTokens,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Maximale Ausgabe-Token',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, {
              'temperature': double.tryParse(temperature.text) ?? 0.7,
              'top_p': double.tryParse(topP.text) ?? 0.95,
              'max_tokens': int.tryParse(maxTokens.text) ?? 1024,
            }),
            child: const Text('Live anwenden'),
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
    _showMessage(ok ? 'Sampling-Defaults aktualisiert.' : _controller.error);
  }

  void _showError() {
    final failure = _controller.requestFailure;
    if (failure?.code == 'resource_conflict') {
      _showMessage(
        'Dieses Modell passt mit dem aktuell freien RAM- und Grafikspeicher nicht in den Speicher. Wähle ein kleineres oder quantisiertes Modell – oder stoppe zuerst andere lokale Modelle.',
      );
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
              // On desktop the monitor is a true slide-in side rail. On
              // smaller screens the same information opens as a bottom sheet
              // so the setup wizard keeps its full usable width.
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
      color: const Color(0xFF16161D),
      borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
      child: InkWell(
        key: const Key('engine-mobile-telemetry-handle'),
        onTap: _openTelemetry,
        borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 9, vertical: 12),
          child: RotatedBox(
            quarterTurns: 3,
            child: Text(
              'SYSTEM',
              style: TextStyle(
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
          // Do not lay out the dense panel while the rail is still narrower
          // than the panel itself. This keeps the slide-in animation free of
          // transient RenderFlex overflows.
          if (_showTelemetryPanel && constraints.maxWidth >= 280) {
            return _buildTelemetryPanel(onClose: _openTelemetry);
          }
          if (_showTelemetryPanel) return const SizedBox.expand();
          return Tooltip(
            message: 'Systemmonitor öffnen',
            child: Material(
              color: const Color(0xFF16161D),
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                key: const Key('engine-telemetry-open-rail'),
                borderRadius: BorderRadius.circular(14),
                onTap: _openTelemetry,
                child: const Center(
                  child: RotatedBox(
                    quarterTurns: 3,
                    child: Text(
                      'SYSTEMMONITOR',
                      style: TextStyle(
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
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Systemmonitor',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Live-Daten der lokalen Engine',
                        style: TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  key: const Key('engine-telemetry-close'),
                  tooltip: 'Systemmonitor schließen',
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
                const TelemetryLabel(
                  icon: Icons.speed_rounded,
                  label: 'HARDWARE-AUSLASTUNG',
                ),
                const SizedBox(height: 10),
                if (hardware == null)
                  const TelemetryEmpty(
                    icon: Icons.memory_outlined,
                    text: 'Hardwaredaten werden geladen …',
                  )
                else ...[
                  EngineUsageGauge(
                    icon: Icons.memory_rounded,
                    label: 'Arbeitsspeicher',
                    value: _percentUsed(
                      hardware.ramTotalBytes,
                      hardware.ramAvailableBytes,
                    ),
                    detail:
                        '${formatBytes(hardware.ramTotalBytes - hardware.ramAvailableBytes)} von ${formatBytes(hardware.ramTotalBytes)} belegt',
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
                      detail:
                          '${formatBytes(gpu.vramTotalBytes - gpu.vramFreeBytes)} von ${formatBytes(gpu.vramTotalBytes)} belegt',
                      fraction: _usedFraction(
                        gpu.vramTotalBytes,
                        gpu.vramFreeBytes,
                      ),
                      color: const Color(0xFFC9A24A),
                    ),
                  ],
                ],
                const SizedBox(height: 22),
                TelemetryLabel(
                  icon: Icons.bolt_rounded,
                  label: 'LAUFENDER MODELLSTART',
                  trailing: operation == null && current == null
                      ? const Text(
                          'RUHIG',
                          style: TextStyle(
                            color: Color(0xFF81C784),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        )
                      : const Text(
                          'AKTIV',
                          style: TextStyle(
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
                  const TelemetryEmpty(
                    icon: Icons.check_circle_outline,
                    text: 'Kein Startvorgang aktiv. Die Engine ist bereit.',
                  ),
                const SizedBox(height: 22),
                TelemetryLabel(
                  icon: Icons.hub_outlined,
                  label: 'LIVE-MODELLE',
                  trailing: Text(
                    '${running.length} ONLINE',
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
                  const TelemetryEmpty(
                    icon: Icons.power_settings_new_rounded,
                    text: 'Zurzeit läuft kein Modell.',
                  )
                else
                  ...running.map(_buildLiveModelTile),
                const SizedBox(height: 22),
                TelemetryLabel(
                  icon: Icons.settings_suggest_outlined,
                  label: 'TECHNISCHE KOMPONENTEN',
                  trailing: IconButton(
                    key: const Key('engine-system-details-toggle'),
                    onPressed: () =>
                        setState(() => _showSetupDetails = !_showSetupDetails),
                    tooltip: 'Technische Komponenten',
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
        : instance?.id ?? 'Engine-Vorgang';
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
                ? '${(progress * 100).round()} % abgeschlossen'
                : 'Wartet auf Fortschrittsdaten …',
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
                    'Instanz ${instance.id}',
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
                    '${runtimeLabel(instance.effectiveConfig.runtime)} · ${contextTokens == null ? 'Auto-Kontext' : '${formatTokenCount(contextTokens)} Token'}',
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

  // ---------------------------------------------------------------------
  // Guided flow: Modell → Einstellungen → Start, one step at a time.
  // ---------------------------------------------------------------------

  /// A broken or currently installing runtime affects every start, so it
  /// gets one prominent banner above the flow — the single place this state
  /// is shown.
  List<Widget> _buildRuntimeIssueBanner() {
    if (_activeSetupOperation() != null || _setupInstance() != null) {
      // The start flow already shows its own progress; no second banner.
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
                          : 'Eine Laufzeitumgebung wird im Hintergrund vorbereitet.',
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
                    ? '${(installingRuntime.progress * 100).round()} % abgeschlossen'
                    : 'Vorbereitung läuft …',
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
                label: const Text('Einrichtung erneut versuchen'),
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
          label: 'Modell starten',
          selected: _workspace == 0,
          onTap: () => setState(() => _workspace = 0),
        ),
        WorkspaceTab(
          key: const Key('engine-workspace-instances'),
          icon: Icons.inventory_2_outlined,
          label: 'Meine Modelle · $instanceCount',
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
      0 => 'Modell auswählen',
      1 => 'Start konfigurieren',
      _ => 'Modell starten',
    };
    final subtitle = switch (_wizardStep) {
      0 => 'Wähle ein lokales Modell für deine nächste Instanz.',
      1 =>
        _expertMode
            ? 'Prüfe die Experteneinstellungen für dieses Modell.'
            : 'Die Engine plant Speicher und Kontext automatisch.',
      _ => 'Die Engine richtet benötigte Komponenten selbstständig ein.',
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
              'Modell',
              enabled: true,
              done: hasModel,
              currentStep: _wizardStep,
              onSelect: (s) => setState(() => _wizardStep = s),
            ),
            wizardStepDivider(),
            wizardStepNav(
              1,
              'Konfigurieren',
              enabled: hasModel,
              currentStep: _wizardStep,
              onSelect: (s) => setState(() => _wizardStep = s),
            ),
            wizardStepDivider(),
            wizardStepNav(
              2,
              'Starten',
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
              top: BorderSide(color: engineBlue.withValues(alpha: 0.5)),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SCHRITT ${_wizardStep + 1} / 3',
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
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 28),
        child: Column(
          children: [
            Icon(Icons.folder_off_outlined, color: Colors.white30),
            SizedBox(height: 12),
            Text(
              'Keine lokalen Modelle gefunden.\nLade ein Modell im Marktplatz herunter und aktualisiere oben rechts.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: math.min(340, math.max(104, models.length * 104)).toDouble(),
          child: ListView.builder(
            itemCount: models.length,
            itemBuilder: (context, index) {
              final model = models[index];
              final selected = model.id == _controller.selectedModelId;
              return _modelTile(model, selected);
            },
          ),
        ),
      ],
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
        if (_controller.isLoadingRecommendation)
          const Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LinearProgressIndicator(minHeight: 3),
              SizedBox(height: 9),
              Text(
                'Freien Grafikspeicher und Modellbedarf werden berechnet …',
                style: TextStyle(color: Colors.white54, fontSize: 12),
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
                          ? 'CPU-Modus aktiv: Die Engine verwendet den ausdrücklich bestätigten System-RAM.'
                          : 'Hybridmodus aktiv: Die Engine verwendet GPU und den bestätigten System-RAM-Anteil.',
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
          title: const Text(
            'Expertenmodus',
            style: TextStyle(color: Colors.white),
          ),
          subtitle: const Text(
            'Kontext, Runtime, Geräte und Speicher manuell steuern',
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
          value: _expertMode,
          onChanged: (value) => setState(() => _expertMode = value),
        ),
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
              label: const Text('Plan neu berechnen'),
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
            label: const Text('Automatisch berechnen und weiter'),
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
          const Padding(
            padding: EdgeInsets.only(bottom: 14),
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
                    'Auto-Modus aktiv: Die Engine berechnet den Kontext passend zum Speicher, bereitet alle Komponenten vor und behebt Startprobleme selbstständig.',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
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
                ? '${(operation.progress * 100).round()} % abgeschlossen'
                : 'Vorbereitung läuft …',
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
                label: const Text('Erneut versuchen'),
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
              label: const Text('Modell starten'),
            ),
          ),
        ),
      ],
    );
  }

  /// The one non-terminal engine operation currently running, if any.
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

  Widget _buildHeader() {
    return Column(
      key: const Key('engine-header'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HeaderMark(),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Modell-Studio',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.1,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Lokale Modelle einrichten, starten und verwalten.',
                    style: TextStyle(
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
                engineBlue.withValues(alpha: 0.7),
                engineAccent.withValues(alpha: 0.35),
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
            tooltip: 'Meldung schließen',
            onPressed: _controller.clearError,
            icon: const Icon(Icons.close, color: Colors.white60),
          ),
        ],
      ),
    );
  }

  Widget _modelTile(ModelRecord model, bool selected) {
    final deleting = _controller.busyModels.contains(model.id);
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Material(
        color: selected ? engineBlue.withValues(alpha: 0.12) : engineInsetColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          key: Key('engine-model-${model.id}'),
          onTap: model.isStartable ? () => _selectModel(model) : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? engineAccent.withValues(alpha: 0.55)
                    : Colors.white.withValues(alpha: 0.05),
                width: selected ? 1.4 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  model.format == 'gguf'
                      ? Icons.description_outlined
                      : Icons.folder_copy_outlined,
                  color: selected ? engineAccent : Colors.white54,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              model.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          EngineStatusBadge(status: model.status),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _expertMode
                            ? '${model.format.toUpperCase()} · ${model.quantization} · ${formatBytes(model.sizeBytes)} · ${formatTokenCount(model.modelContextLimitTokens)} Token'
                            : '${formatBytes(model.sizeBytes)} · bis zu ${formatTokenCount(model.modelContextLimitTokens)} Token Kontext',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                      ),
                      if (model.validationIssues.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text(
                          model.validationIssues.first,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFFFAB91),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 7),
                IconButton(
                  key: Key('engine-delete-model-${model.id}'),
                  tooltip: 'Modell und lokale Dateien löschen',
                  onPressed: deleting ? null : () => _deleteModel(model),
                  icon: deleting
                      ? const SizedBox(
                          width: 17,
                          height: 17,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.delete_outline),
                  color: Colors.white38,
                  splashRadius: 18,
                ),
                Icon(
                  selected ? Icons.check_circle : Icons.chevron_right,
                  color: selected ? engineAccent : Colors.white30,
                  size: 19,
                ),
              ],
            ),
          ),
        ),
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
            'Kontextplanung',
            'Neustart erforderlich',
          ),
          items: const [
            DropdownMenuItem(
              value: 'auto_max',
              child: Text('Automatisch maximal'),
            ),
            DropdownMenuItem(value: 'fixed', child: Text('Fester Kontext')),
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
            'Maximaler Kontext',
            _contextMode == 'fixed' ? 'Token' : 'Wird automatisch berechnet',
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
              'Runtime',
              'Auto wählt den besten Adapter',
            ),
            items: runtimeIds
                .map(
                  (id) => DropdownMenuItem(
                    value: id,
                    child: Text(id == 'auto' ? 'Automatisch' : id),
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
              'Priorität',
              'Pinned wird nie automatisch verkleinert',
            ),
            items: const [
              DropdownMenuItem(value: 'low', child: Text('Niedrig')),
              DropdownMenuItem(value: 'normal', child: Text('Normal')),
              DropdownMenuItem(value: 'high', child: Text('Hoch')),
              DropdownMenuItem(value: 'pinned', child: Text('Pinned')),
            ],
            onChanged: (value) => setState(() => _priority = value ?? 'normal'),
          ),
        ),
        const SizedBox(height: 12),
        _responsiveFieldPair(
          _numberField(_gpuLayersController, 'GPU-Layer', 'Leer = Auto'),
          _numberField(_threadsController, 'CPU-Threads', 'Leer = Auto'),
        ),
        const SizedBox(height: 12),
        _responsiveFieldPair(
          _numberField(
            _tensorParallelController,
            'Tensor Parallelism',
            'Anzahl GPUs',
          ),
          _numberField(
            _maxSequencesController,
            'Parallele Sequenzen',
            'Mindestens 1',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _gpuIdsController,
          style: const TextStyle(color: Colors.white),
          decoration: _inputDecoration(
            'GPU-IDs',
            'Kommagetrennt; leer = Scheduler entscheidet',
          ),
        ),
        const SizedBox(height: 12),
        _responsiveFieldPair(
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: _offload,
            dropdownColor: enginePanelColor,
            decoration: _inputDecoration('Offload', 'Neustart erforderlich'),
            items: const [
              DropdownMenuItem(value: 'auto', child: Text('Automatisch')),
              DropdownMenuItem(value: 'gpu', child: Text('GPU bevorzugen')),
              DropdownMenuItem(value: 'cpu', child: Text('RAM/CPU bevorzugen')),
            ],
            onChanged: (value) => setState(() => _offload = value ?? 'auto'),
          ),
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: _kvCacheDtype,
            dropdownColor: enginePanelColor,
            decoration: _inputDecoration(
              'KV-Cache-Dtype',
              'Gewichte bleiben unverändert',
            ),
            items: const [
              DropdownMenuItem(
                value: 'auto',
                child: Text('Policy entscheidet'),
              ),
              DropdownMenuItem(value: 'q4_0', child: Text('Q4_0 (llama.cpp)')),
              DropdownMenuItem(
                value: 'turboquant_4bit_nc',
                child: Text('TurboQuant 4-Bit'),
              ),
              DropdownMenuItem(value: 'fp8', child: Text('FP8')),
              DropdownMenuItem(value: 'native', child: Text('Nativ')),
            ],
            onChanged: (value) =>
                setState(() => _kvCacheDtype = value ?? 'auto'),
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: _kvCachePolicy,
          dropdownColor: enginePanelColor,
          decoration: _inputDecoration(
            'KV-Cache-Policy',
            '4-Bit kann Qualität und Durchsatz beeinflussen',
          ),
          items: const [
            DropdownMenuItem(
              value: 'prefer_4bit',
              child: Text('4-Bit bevorzugen, sicher zurückfallen'),
            ),
            DropdownMenuItem(value: 'native', child: Text('Nur nativer Cache')),
          ],
          onChanged: (value) =>
              setState(() => _kvCachePolicy = value ?? 'prefer_4bit'),
        ),
        const SizedBox(height: 4),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text(
            'Auto-Modus (empfohlen)',
            style: TextStyle(color: Colors.white),
          ),
          subtitle: const Text(
            'Die Engine berechnet den Kontext passend zum Speicher und passt Cache, Kontext und Gerät automatisch an, bis das Modell läuft.',
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
          value: _allowFallback,
          onChanged: (value) => setState(() => _allowFallback = value),
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text(
            'System-RAM beim Offload zulassen',
            style: TextStyle(color: Colors.white),
          ),
          subtitle: const Text(
            'Nur aktivieren, wenn das Modell nicht vollständig in den Grafikspeicher passt.',
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
          value: _useRamOffload,
          onChanged: (value) => setState(() => _useRamOffload = value),
        ),
        SwitchListTile.adaptive(
          key: const Key('engine-trust-remote-code'),
          contentPadding: EdgeInsets.zero,
          title: const Text(
            'Modelleigenen Python-Code erlauben',
            style: TextStyle(color: Colors.white),
          ),
          subtitle: Text(
            model.format == 'safetensors'
                ? 'Standardmäßig aus. Vor der ersten Ausführung ist eine hashgebundene Zustimmung nötig.'
                : 'Nur für SafeTensors-Modelle mit eigenem Python-Code relevant.',
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
          value: _trustRemoteCode,
          onChanged: model.format == 'safetensors'
              ? (value) => setState(() => _trustRemoteCode = value)
              : null,
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text('Autostart', style: TextStyle(color: Colors.white)),
          subtitle: const Text(
            'Diese Instanz beim nächsten Backend-Start wiederherstellen',
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
          value: _autostart,
          onChanged: (value) => setState(() => _autostart = value),
        ),
      ],
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
          'Gewichte ${formatBytes(plan.memory.weightsBytes)}',
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        Text(
          'KV ${formatBytes(plan.memory.kvCacheBytes)}',
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        Text(
          'Runtime ${formatBytes(plan.memory.runtimeBytes)}',
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        Text(
          plan.ramRequiredAfterTokens == null
              ? '${plan.confidence} · kein RAM-Offload geplant'
              : '${plan.confidence} · RAM ab ${formatTokenCount(plan.ramRequiredAfterTokens!)} Token',
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
            title: 'Bereits eingerichtete Modelle',
            subtitle:
                '${instances.length} Modell${instances.length == 1 ? '' : 'e'} eingerichtet · Start, Stopp und Verhalten direkt hier steuern',
          ),
          const SizedBox(height: 15),
          if (instances.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  Icon(Icons.power_off, color: Colors.white30, size: 30),
                  SizedBox(height: 10),
                  Text(
                    'Noch keine Engine-Instanz.\nWähle ein Modell und starte es mit der empfohlenen Konfiguration.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white38, fontSize: 12),
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
        const Text(
          'Technische Komponenten',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 9),
        if (runtimes.isEmpty)
          const Text(
            'Noch keine Komponenteninformationen verfügbar.',
            style: TextStyle(color: Colors.white38, fontSize: 12),
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
                      const Text(
                        'Technische Diagnose',
                        style: TextStyle(
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
        const Text(
          'Aktuelle Vorgänge',
          style: TextStyle(
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
                        const Text(
                          'Technische Diagnose',
                          style: TextStyle(
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
                    tooltip: 'Vorgang abbrechen',
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
    return 'Die lokale Ausführung wird vorbereitet.';
  }

  String _friendlyOperationMessage(EngineOperation operation) {
    var message = operation.detailMessage.trim().isNotEmpty
        ? operation.detailMessage.trim()
        : operation.message?.trim() ?? '';
    if (message.isEmpty) {
      switch (operation.type) {
        case 'runtime_install':
          return 'Die benötigten Komponenten werden eingerichtet.';
        case 'start':
          return 'Das Modell wird geladen und geprüft.';
        default:
          return 'Die lokale Ausführung wird vorbereitet.';
      }
    }
    message = message
        .replaceAll('Runtime llama_cpp', 'GGUF-Ausführung')
        .replaceAll('Runtime transformers', 'SafeTensors-Ausführung')
        .replaceAll('Runtime vllm', 'beschleunigte SafeTensors-Ausführung')
        .replaceAll('wird vorgewärmt', 'wird vorbereitet');
    return message;
  }

  String _friendlyRuntimeError(RuntimeCapability runtime) {
    switch (runtime.errorCode) {
      case 'compiler_missing':
        return runtime.error?.isNotEmpty == true
            ? runtime.error!
            : 'Für den nativen Runtime-Build fehlen Compiler oder CMake. Bitte die Build-Werkzeuge installieren und erneut versuchen.';
      case 'disk_full':
        return 'Auf dem Datenträger ist nicht genug freier Speicher. Bitte schaffe etwas Platz und versuche es erneut.';
      case 'network_unavailable':
        return 'Die benötigten Komponenten konnten wegen einer Netzwerkstörung nicht geladen werden. Bitte prüfe die Verbindung und versuche es erneut.';
      case 'package_unavailable':
        return 'Für dieses System ist das benötigte Paket nicht verfügbar. PhiloEngine versucht, eine kompatible Alternative zu verwenden.';
      case 'native_build_failed':
        return 'Die GPU-Ausführung konnte nicht eingerichtet werden. Beim nächsten Versuch wird eine kompatible Alternative verwendet.';
      case 'python_environment_failed':
        return 'Die geschützte Laufzeitumgebung konnte nicht angelegt werden. Bitte versuche es erneut.';
      case 'runtime_probe_failed':
        return 'Die Komponenten wurden installiert, konnten auf diesem Gerät aber nicht erfolgreich geprüft werden.';
    }
    final raw = runtime.error;
    if (raw != null && raw.isNotEmpty) return friendlyEngineError(raw);
    return 'Eine benötigte Komponente konnte nicht eingerichtet werden. Bitte versuche es erneut.';
  }
}

enum _MemoryPlanChoice { cancel, useRam, repairGpu, rebuildGpu }
