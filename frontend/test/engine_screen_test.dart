import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myphilostudio/engine/controller.dart';
import 'package:myphilostudio/engine/engine_api.dart';
import 'package:myphilostudio/engine/models.dart';
import 'package:myphilostudio/engine/widgets.dart';
import 'package:myphilostudio/screens/engine/engine_screen.dart';

void main() {
  test('keeps runtime phase and structured failure information from API', () {
    final runtime = RuntimeCapability.fromJson(const {
      'kind': 'llama_cpp',
      'status': 'installing_packages',
      'status_message': 'Runtime-Pakete werden geladen und installiert',
      'error_code': 'network_unavailable',
      'progress': 0.55,
    });

    expect(
      runtime.statusMessage,
      'Runtime-Pakete werden geladen und installiert',
    );
    expect(runtime.errorCode, 'network_unavailable');
    expect(runtime.progress, 0.55);

    final operation = EngineOperation.fromJson(const {
      'id': 'operation-1',
      'type': 'start',
      'state': 'failed',
      'phase': 'loading_weights',
      'detail_message': 'Die Modellgewichte werden in den Speicher geladen.',
      'error_code': 'worker_exit',
      'error_summary': 'Der lokale Modellprozess wurde unerwartet beendet.',
      'error': 'exit status 137: worker stderr',
    });
    expect(operation.phase, 'loading_weights');
    expect(
      operation.detailMessage,
      'Die Modellgewichte werden in den Speicher geladen.',
    );
    expect(operation.errorCode, 'worker_exit');
    expect(
      operation.errorSummary,
      'Der lokale Modellprozess wurde unerwartet beendet.',
    );
    expect(operation.error, 'exit status 137: worker stderr');

    final instance = EngineInstance.fromJson(const {
      'id': 'instance-1',
      'state': 'starting',
      'phase': 'healthcheck',
      'detail_message': 'Der lokale Modellserver wird geprüft.',
      'error_code': 'healthcheck_failed',
      'error_summary': 'Das Modell antwortet noch nicht.',
      'show_in_chat_picker': true,
      'placement': 'hybrid',
      'active_requests': 2,
      'last_used_at': '2026-07-13T10:00:00Z',
      'idle_expires_at': '2026-07-13T10:15:00Z',
      'guard_state': 'warning',
    });
    expect(instance.phase, 'healthcheck');
    expect(instance.detailMessage, 'Der lokale Modellserver wird geprüft.');
    expect(instance.errorCode, 'healthcheck_failed');
    expect(instance.errorSummary, 'Das Modell antwortet noch nicht.');
    expect(instance.showInChatPicker, isTrue);
    expect(instance.placement, 'hybrid');
    expect(instance.activeRequests, 2);
    expect(instance.lastUsedAt, isNotNull);
    expect(instance.idleExpiresAt, isNotNull);
    expect(instance.guardState, 'warning');

    final ensureReady = EngineEnsureReadyResult.fromJson(const {
      'operation_id': 'warmup-1',
      'status': 'queued',
      'queue_position': 3,
      'instance': {'id': 'instance-1', 'state': 'stopped'},
    });
    expect(ensureReady.operationId, 'warmup-1');
    expect(ensureReady.queuePosition, 3);
    expect(ensureReady.isReady, isFalse);
  });

  testWidgets('localizes an incompatible optional runtime', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: EngineStatusBadge(status: 'incompatible')),
        ),
      ),
    );

    expect(find.text('Nicht benötigt'), findsOneWidget);
    expect(find.text('incompatible'), findsNothing);
  });

  testWidgets('explains when the GPU already reaches the model context limit', (
    tester,
  ) async {
    const plan = ContextPlan(
      modelContextLimitTokens: 131072,
      gpuOnlyMaxContextTokens: 131072,
      hybridMaxContextTokens: 131072,
      effectiveContextTokens: 131072,
      ramRequiredAfterTokens: null,
      memory: MemoryBreakdown(
        weightsBytes: 0,
        kvCacheBytes: 0,
        runtimeBytes: 0,
        reserveBytes: 0,
        gpuBytes: 0,
        ramBytes: 0,
      ),
      confidence: 'estimated',
      warnings: [],
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: EngineContextBar(plan: plan)),
      ),
    );

    expect(find.byKey(const Key('context-plan-no-ram-gain')), findsOneWidget);
    expect(
      find.text('Modelllimit bereits vollständig auf GPU'),
      findsOneWidget,
    );
    expect(find.textContaining('GPU + RAM (Schätzung):'), findsNothing);
  });

  testWidgets('shows RAM only when it really extends available context', (
    tester,
  ) async {
    const plan = ContextPlan(
      modelContextLimitTokens: 131072,
      gpuOnlyMaxContextTokens: 32768,
      hybridMaxContextTokens: 131072,
      effectiveContextTokens: 131072,
      ramRequiredAfterTokens: 32769,
      memory: MemoryBreakdown(
        weightsBytes: 0,
        kvCacheBytes: 0,
        runtimeBytes: 0,
        reserveBytes: 0,
        gpuBytes: 0,
        ramBytes: 1073741824,
      ),
      confidence: 'estimated',
      warnings: [],
      usesRam: true,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: EngineContextBar(plan: plan)),
      ),
    );

    expect(find.byKey(const Key('context-plan-ram-extension')), findsOneWidget);
    expect(find.text('GPU + RAM (Schätzung): 131.1k'), findsOneWidget);
    expect(find.byKey(const Key('context-plan-no-ram-gain')), findsNothing);
  });

  testWidgets('keeps the preflight evidence behind an expandable explanation', (
    tester,
  ) async {
    const plan = ContextPlan(
      modelContextLimitTokens: 131072,
      gpuOnlyMaxContextTokens: 32768,
      hybridMaxContextTokens: 131072,
      effectiveContextTokens: 131072,
      ramRequiredAfterTokens: 32769,
      memory: MemoryBreakdown(
        weightsBytes: 700 * 1024 * 1024,
        kvCacheBytes: 1024 * 1024 * 1024,
        runtimeBytes: 256 * 1024 * 1024,
        reserveBytes: 0,
        gpuBytes: 2 * 1024 * 1024 * 1024,
        ramBytes: 1024 * 1024 * 1024,
      ),
      confidence: 'estimated',
      warnings: [],
      usesRam: true,
      preflight: PreflightReport(
        hardwareSnapshotId: 'hw-123456',
        metadataConfidence: 'verified',
        checks: [
          PreflightCheck(
            id: 'worker_probe',
            state: 'pending',
            label: 'Modellantwort verifizieren',
            detail: 'Eine lokale Mini-Inferenz bestätigt den Start.',
          ),
        ],
      ),
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: EnginePreflightCard(plan: plan)),
      ),
    );

    expect(find.byKey(const Key('engine-preflight-card')), findsOneWidget);
    expect(find.text('Start-Check'), findsOneWidget);
    expect(
      find.textContaining('Rechnerisch kann System-RAM den Kontext'),
      findsOneWidget,
    );
    expect(find.text('Modellantwort verifizieren'), findsNothing);

    await tester.tap(find.byKey(const Key('engine-preflight-details')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Modellantwort verifizieren'), findsOneWidget);
    expect(find.text('hw-123456'), findsOneWidget);
  });

  testWidgets('uses dedicated workspaces for setup and configured models', (
    tester,
  ) async {
    await _setViewport(tester, const Size(1300, 1400));

    await tester.pumpWidget(_testApp(EngineScreen(api: _FakeEngineApi())));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('engine-wizard')), findsOneWidget);
    expect(find.byKey(const Key('engine-wizard-step-1')), findsOneWidget);
    expect(find.byKey(const Key('engine-wizard-step-3')), findsOneWidget);
    expect(find.byKey(const Key('engine-workspace-switcher')), findsOneWidget);
    expect(find.byKey(const Key('engine-instances')), findsNothing);
    expect(find.byKey(const Key('engine-hardware-budget')), findsNothing);
    expect(find.byKey(const Key('engine-tab-switcher')), findsNothing);

    await tester.tap(find.byKey(const Key('engine-workspace-instances')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('engine-instances')), findsOneWidget);
    expect(find.byKey(const Key('engine-wizard')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('deletes a selected local model only after confirmation', (
    tester,
  ) async {
    await _setViewport(tester, const Size(1300, 1200));
    final api = _FakeEngineApi();

    await tester.pumpWidget(_testApp(EngineScreen(api: api)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('engine-wizard-step-1')));
    await tester.pumpAndSettle();

    final delete = find.byKey(const Key('engine-delete-model-model-gguf'));
    await tester.ensureVisible(delete);
    await tester.tap(delete);
    await tester.pumpAndSettle();
    expect(find.text('Modell löschen?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('engine-cancel-delete-model')));
    await tester.pumpAndSettle();
    expect(api.deleteModelCalls, 0);

    await tester.tap(delete);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('engine-confirm-delete-model')));
    await tester.pumpAndSettle();

    expect(api.deleteModelCalls, 1);
    expect(api.lastDeletedModelId, 'model-gguf');
    expect(find.byKey(const Key('engine-model-model-gguf')), findsNothing);
    expect(
      find.text('Modell und lokale Dateien wurden gelöscht.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps the guided layout usable in a narrow window', (
    tester,
  ) async {
    await _setViewport(tester, const Size(390, 844));

    await tester.pumpWidget(_testApp(EngineScreen(api: _FakeEngineApi())));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('engine-wizard')), findsOneWidget);
    expect(
      find.byKey(const Key('engine-mobile-telemetry-handle')),
      findsOneWidget,
    );
    expect(
      find.text('SYSTEMDATEN WERDEN AUTOMATISCH SYNCHRONISIERT'),
      findsOneWidget,
    );
    expect(find.text('Modell-Studio'), findsOneWidget);
    expect(find.textContaining('Endpoint:'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('offers hybrid RAM mode when a model does not fit in VRAM', (
    tester,
  ) async {
    await _setViewport(tester, const Size(900, 1400));
    final api = _HybridRecommendationApi();

    await tester.pumpWidget(_testApp(EngineScreen(api: api)));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('engine-model-model-gguf')));
    await tester.pumpAndSettle();

    expect(find.text('SCHRITT 2 / 3'), findsOneWidget);
    expect(find.text('System-RAM dazunehmen?'), findsNothing);

    await tester.tap(find.byKey(const Key('engine-calculate-and-continue')));
    await tester.pumpAndSettle();

    expect(find.text('System-RAM dazunehmen?'), findsOneWidget);
    expect(
      find.textContaining('passt nicht allein in den freien Grafikspeicher'),
      findsOneWidget,
    );

    await tester.tap(find.text('RAM verwenden'));
    await tester.pumpAndSettle();

    expect(find.text('SCHRITT 3 / 3'), findsOneWidget);
    await tester.tap(find.byKey(const Key('engine-create-instance')));
    await tester.pumpAndSettle();

    expect(api.lastCreateConfig?.runtimeOptions['allow_ram_offload'], isTrue);
    expect(
      api.lastCreateConfig?.runtimeOptions.containsKey('kv_cache_dtype'),
      isFalse,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('does not mislabel a missing GPU runtime as insufficient VRAM', (
    tester,
  ) async {
    await _setViewport(tester, const Size(900, 1400));
    final api = _RuntimeUnavailableRecommendationApi();

    await tester.pumpWidget(_testApp(EngineScreen(api: api)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('engine-model-model-gguf')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('engine-calculate-and-continue')));
    await tester.pumpAndSettle();

    expect(find.text('GPU-Unterstützung noch nicht bereit'), findsOneWidget);
    expect(find.textContaining('nicht wegen seiner Größe'), findsOneWidget);
    expect(
      find.textContaining('passt nicht allein in den freien Grafikspeicher'),
      findsNothing,
    );
    expect(
      api.recommendationConfigs.last.runtimeOptions['force_cpu_runtime'],
      isTrue,
    );
    expect(api.recommendationConfigs.last.runtimeOptions['offload'], 'cpu');
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps the confirmed runtime fallback as an explicit CPU plan', (
    tester,
  ) async {
    await _setViewport(tester, const Size(900, 1400));
    final api = _RuntimeUnavailableRecommendationApi();

    await tester.pumpWidget(_testApp(EngineScreen(api: api)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('engine-model-model-gguf')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('engine-calculate-and-continue')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('CPU/RAM verwenden'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('engine-create-instance')));
    await tester.pumpAndSettle();

    expect(api.lastCreateConfig?.runtimeOptions['allow_ram_offload'], isTrue);
    expect(api.lastCreateConfig?.runtimeOptions['force_cpu_runtime'], isTrue);
    expect(api.lastCreateConfig?.runtimeOptions['offload'], 'cpu');
    expect(
      api.lastCreateConfig?.runtimeOptions.containsKey('kv_cache_dtype'),
      isFalse,
    );
  });

  testWidgets('rebuilds a failed GPU runtime without an administrator prompt', (
    tester,
  ) async {
    await _setViewport(tester, const Size(1000, 1500));
    final api = _FailedVulkanRuntimeRecommendationApi();

    await tester.pumpWidget(_testApp(EngineScreen(api: api)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('engine-model-model-gguf')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('engine-calculate-and-continue')));
    await tester.pumpAndSettle();

    expect(find.text('GPU-Runtime neu bauen'), findsOneWidget);
    await tester.tap(find.byKey(const Key('engine-auto-repair-gpu')));
    await tester.pumpAndSettle();

    expect(api.runtimeRebuildCalls, 1);
    expect(api.gpuConsentCalls, 0);
    expect(
      find.byKey(const Key('engine-gpu-admin-consent-dialog')),
      findsNothing,
    );
    expect(find.text('SCHRITT 3 / 3'), findsOneWidget);
  });

  testWidgets(
    'requires fresh informed admin consent before repairing GPU support',
    (tester) async {
      await _setViewport(tester, const Size(1000, 1500));
      final api = _RuntimeUnavailableRecommendationApi();

      await tester.pumpWidget(_testApp(EngineScreen(api: api)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('engine-model-model-gguf')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('engine-calculate-and-continue')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('engine-auto-repair-gpu')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('engine-gpu-admin-consent-dialog')),
        findsOneWidget,
      );
      expect(find.textContaining('libvulkan-dev'), findsOneWidget);
      expect(find.textContaining('glslc'), findsOneWidget);
      expect(find.textContaining('spirv-headers'), findsOneWidget);
      expect(find.textContaining('cmake'), findsOneWidget);
      expect(find.textContaining('build-essential'), findsOneWidget);
      expect(
        find.textContaining('Bei jeder späteren Systemänderung'),
        findsOneWidget,
      );
      FilledButton adminButton = tester.widget(
        find.byKey(const Key('engine-open-admin-dialog')),
      );
      expect(adminButton.onPressed, isNull);
      expect(api.gpuDependencyInstallCalls, 0);

      await tester.tap(
        find.byKey(const Key('engine-gpu-admin-acknowledgement')),
      );
      await tester.pump();
      adminButton = tester.widget(
        find.byKey(const Key('engine-open-admin-dialog')),
      );
      expect(adminButton.onPressed, isNotNull);

      await tester.tap(find.byKey(const Key('engine-open-admin-dialog')));
      await tester.pumpAndSettle();

      expect(api.gpuConsentCalls, 1);
      expect(api.gpuDependencyInstallCalls, 1);
      expect(api.lastGpuConsentToken, 'one-use-consent');
      expect(find.text('SCHRITT 3 / 3'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'keeps live hardware and model status in a collapsible side rail',
    (tester) async {
      await _setViewport(tester, const Size(1300, 1000));

      await tester.pumpWidget(_testApp(EngineScreen(api: _FakeEngineApi())));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('engine-telemetry-panel')), findsOneWidget);
      expect(find.text('HARDWARE-AUSLASTUNG'), findsOneWidget);
      expect(find.text('LIVE-MODELLE'), findsOneWidget);
      expect(find.text('2 ONLINE'), findsOneWidget);

      await tester.tap(find.byKey(const Key('engine-system-details-toggle')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('engine-runtime-details')), findsOneWidget);

      await tester.tap(find.byKey(const Key('engine-telemetry-close')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('engine-telemetry-panel')), findsNothing);
      expect(
        find.byKey(const Key('engine-telemetry-open-rail')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('engine-telemetry-open-rail')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('engine-telemetry-panel')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('renders multiple independent instance cards and context plans', (
    tester,
  ) async {
    await _setViewport(tester, const Size(1300, 1400));

    await tester.pumpWidget(_testApp(EngineScreen(api: _FakeEngineApi())));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('engine-workspace-instances')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('engine-instance-writer')), findsOneWidget);
    expect(find.byKey(const Key('engine-instance-coder')), findsOneWidget);
    expect(find.text('local-writer'), findsOneWidget);
    expect(find.text('local-coder'), findsOneWidget);
    expect(find.text('Bereit'), findsWidgets);
    expect(find.byKey(const Key('context-plan-bar')), findsAtLeastNWidgets(2));
    expect(
      find.textContaining('automatisch eine kompatible Ausführung gewählt'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'distinguishes verified context from estimate and can test the maximum',
    (tester) async {
      await _setViewport(tester, const Size(1300, 1400));
      const plan = ContextPlan(
        modelContextLimitTokens: 262144,
        gpuOnlyMaxContextTokens: 3418,
        hybridMaxContextTokens: 52581,
        effectiveContextTokens: 27648,
        ramRequiredAfterTokens: 0,
        memory: MemoryBreakdown(
          weightsBytes: 13613037280,
          kvCacheBytes: 3523215360,
          runtimeBytes: 268435456,
          reserveBytes: 0,
          gpuBytes: 12984579441,
          ramBytes: 4420108655,
        ),
        confidence: 'estimated',
        warnings: [],
        usesRam: true,
      );
      const instance = EngineInstance(
        id: 'context-choice',
        state: 'ready',
        modelId: 'model-gguf',
        servedModelName: 'Gemma Context Test',
        requestedConfig: EngineConfig(
          runtime: 'auto',
          contextMode: 'auto_max',
          runtimeOptions: {'allow_ram_offload': true},
        ),
        effectiveConfig: EngineConfig(
          runtime: 'llama_cpp',
          contextMode: 'fixed',
          contextTokens: 27648,
        ),
        plan: plan,
        restartRequiredFields: [],
        fallbacks: [
          EngineFallback(
            setting: 'context_tokens',
            from: '55737',
            to: '27648',
            reason: 'Kontext wurde wegen Speicher-Engpass reduziert.',
          ),
        ],
        error: null,
        progress: 1,
        placement: 'hybrid',
      );
      final api = _FakeEngineApi(instances: const [instance]);

      await tester.pumpWidget(_testApp(EngineScreen(api: api)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('engine-workspace-instances')));
      await tester.pumpAndSettle();

      expect(find.text('Aktiv & geprüft: 27.6k'), findsOneWidget);
      expect(find.text('GPU + RAM (Schätzung): 52.6k'), findsOneWidget);
      expect(
        find.textContaining('Der höhere Kontext von 55.7k war nicht stabil'),
        findsOneWidget,
      );

      final edit = find.byKey(const Key('engine-context-edit-context-choice'));
      await tester.ensureVisible(edit);
      await tester.tap(edit);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('engine-context-dialog')), findsOneWidget);
      expect(
        find.textContaining('noch keine Stabilitätsgarantie'),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const Key('engine-context-use-estimated-max')),
      );
      await tester.pump();
      final field = tester.widget<TextField>(
        find.byKey(const Key('engine-context-value')),
      );
      expect(field.controller?.text, '52581');

      await tester.tap(find.byKey(const Key('engine-context-confirm')));
      await tester.pumpAndSettle();

      expect(api.lastUpdateChanges?['action'], 'restart');
      final requested = Map<String, dynamic>.from(
        api.lastUpdateChanges?['requested_config'] as Map,
      );
      expect(requested['context_mode'], 'fixed');
      expect(requested['context_tokens'], 52581);
      expect(requested['allow_fallback'], isTrue);
      final options = Map<String, dynamic>.from(
        requested['runtime_options'] as Map,
      );
      expect(options['allow_ram_offload'], isTrue);
      expect(options['context_search_mode'], 'maximize_stable');
      expect(tester.takeException(), isNull);
    },
  );

  test('preserves a terminal event that beats its mutation response', () async {
    final api = _EarlyCompletedRuntimeApi();
    final controller = EngineController(api);
    addTearDown(controller.dispose);
    await controller.initialize();

    final operation = await controller.rebuildVulkanGpuRuntime().timeout(
      const Duration(seconds: 1),
    );

    expect(operation?.state, 'completed');
    expect(controller.operations['early-runtime']?.state, 'completed');
  });

  test('announces ready when the action reconciliation beats SSE', () async {
    final api = _RestReadyApi();
    final controller = EngineController(api);
    addTearDown(controller.dispose);
    await controller.initialize();
    controller.chooseModel('model-gguf');

    expect(
      await controller.createInstance(const EngineConfig(runtime: 'auto')),
      isTrue,
    );

    expect(controller.instances.single.state, 'ready');
    expect(controller.takeReadyAnnouncement()?.servedModelName, 'REST Ready');
  });

  test('does not let a slow REST snapshot undo a ready event', () async {
    final api = _StaleRestAfterReadyApi();
    final controller = EngineController(api);
    addTearDown(controller.dispose);
    await controller.initialize();
    controller.chooseModel('model-gguf');

    expect(
      await controller.createInstance(const EngineConfig(runtime: 'auto')),
      isTrue,
    );

    expect(controller.instances.single.state, 'ready');
  });

  test('accepts an authoritative rollback to a lower plan revision', () async {
    const ready = EngineInstance(
      id: 'rollback',
      state: 'ready',
      modelId: 'model-gguf',
      servedModelName: 'Rollback Model',
      requestedConfig: EngineConfig(runtime: 'auto'),
      effectiveConfig: EngineConfig(runtime: 'llama_cpp'),
      plan: _FakeEngineApi._plan,
      restartRequiredFields: [],
      fallbacks: [],
      error: null,
      progress: 1,
      planRevision: 4,
    );
    final api = _FakeEngineApi(instances: const [ready]);
    final controller = EngineController(api);
    addTearDown(controller.dispose);
    await controller.initialize();

    api.emitEngineEvent(
      const EngineStreamEvent(
        type: 'instance_changed',
        data: {
          'id': 'rollback',
          'state': 'stopped',
          'model_id': 'model-gguf',
          'served_model_name': 'Rollback Model',
          'requested_config': {'runtime': 'auto'},
          'effective_config': {'runtime': 'llama_cpp'},
          'plan_revision': 3,
          'progress': 0.0,
        },
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(controller.instances.single.state, 'stopped');
    expect(controller.instances.single.planRevision, 3);
  });

  test('reconciles missed catalogue changes on a reconnect snapshot', () async {
    final api = _ReconnectCatalogApi();
    final controller = EngineController(api);
    addTearDown(controller.dispose);
    await controller.initialize();

    api.emitEngineEvent(
      const EngineStreamEvent(type: 'snapshot', data: {'instances': []}),
    );
    await Future<void>.delayed(Duration.zero);
    expect(api.modelRequests, 1);

    api.catalogChanged = true;
    api.emitEngineEvent(
      const EngineStreamEvent(type: 'snapshot', data: {'instances': []}),
    );
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(api.modelRequests, 2);
    expect(controller.models.map((model) => model.id), ['model-safe']);
  });

  test('parses suggested_fix from instance payload', () {
    final instance = EngineInstance.fromJson(const {
      'id': 'oom',
      'state': 'failed',
      'error_code': 'gpu_out_of_memory',
      'error_summary': 'Der Grafikspeicher reicht nicht aus.',
      'suggested_fix': {
        'action': 'reduce_context',
        'label': 'Kontext automatisch verkleinern',
      },
    });
    expect(instance.suggestedFix, isNotNull);
    expect(instance.suggestedFix!.action, 'reduce_context');
    expect(instance.suggestedFix!.label, 'Kontext automatisch verkleinern');

    final withoutFix = EngineInstance.fromJson(const {
      'id': 'plain',
      'state': 'failed',
    });
    expect(withoutFix.suggestedFix, isNull);
  });

  testWidgets('shows a one-click fix button for a diagnosed failure', (
    tester,
  ) async {
    await _setViewport(tester, const Size(1300, 1400));
    final failed = EngineInstance(
      id: 'oom',
      state: 'failed',
      modelId: 'model-gguf',
      servedModelName: 'Lokaler Assistent',
      requestedConfig: const EngineConfig(runtime: 'auto'),
      effectiveConfig: const EngineConfig(runtime: 'llama_cpp'),
      plan: _FakeEngineApi._plan,
      restartRequiredFields: const [],
      fallbacks: const [],
      error: 'CUDA out of memory',
      errorSummary: 'Der Grafikspeicher reicht für dieses Modell nicht aus.',
      suggestedFix: const SuggestedFix(
        action: 'reduce_context',
        label: 'Kontext automatisch verkleinern',
      ),
      progress: 0,
    );
    final api = _FakeEngineApi(instances: [failed]);

    await tester.pumpWidget(_testApp(EngineScreen(api: api)));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('engine-workspace-instances')));
    await tester.pumpAndSettle();

    final fixButton = find.byKey(const Key('engine-suggested-fix-oom'));
    expect(fixButton, findsOneWidget);
    expect(find.text('Kontext automatisch verkleinern'), findsOneWidget);

    await tester.ensureVisible(fixButton);
    await tester.tap(fixButton);
    await tester.pumpAndSettle();

    expect(api.lastUpdateChanges, isNotNull);
    expect(api.lastUpdateChanges!['action'], 'apply_fix');
    expect(api.lastUpdateChanges!['fix'], 'reduce_context');
    expect(tester.takeException(), isNull);
  });

  testWidgets('asks before retrying an async memory conflict with RAM', (
    tester,
  ) async {
    await _setViewport(tester, const Size(1300, 1400));
    final failed = EngineInstance(
      id: 'ram-retry',
      state: 'failed',
      modelId: 'model-gguf',
      servedModelName: 'Lokaler Assistent',
      requestedConfig: const EngineConfig(runtime: 'auto'),
      effectiveConfig: const EngineConfig(runtime: 'llama_cpp'),
      plan: _FakeEngineApi._plan,
      restartRequiredFields: const [],
      fallbacks: const [],
      error: 'Hardwarebudget hat sich geändert',
      errorSummary: 'Der freie Grafikspeicher reicht nicht mehr aus.',
      errorCode: 'resource_conflict',
      suggestedFix: const SuggestedFix(
        action: 'retry_with_ram',
        label: 'Mit System-RAM neu berechnen',
      ),
      progress: 1,
    );
    final api = _FakeEngineApi(instances: [failed]);

    await tester.pumpWidget(_testApp(EngineScreen(api: api)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('engine-workspace-instances')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('engine-suggested-fix-ram-retry')));
    await tester.pumpAndSettle();

    expect(find.text('System-RAM dazunehmen?'), findsOneWidget);
    expect(api.lastUpdateChanges, isNull);
    await tester.tap(find.byKey(const Key('engine-confirm-retry-with-ram')));
    await tester.pumpAndSettle();

    expect(api.lastUpdateChanges?['action'], 'apply_fix');
    expect(api.lastUpdateChanges?['fix'], 'retry_with_ram');
    expect(tester.takeException(), isNull);
  });

  testWidgets('routes an async GPU runtime fix to the Vulkan runtime only', (
    tester,
  ) async {
    await _setViewport(tester, const Size(1300, 1400));
    final failed = EngineInstance(
      id: 'gpu-runtime-failed',
      state: 'failed',
      modelId: 'model-gguf',
      servedModelName: 'Lokaler Assistent',
      requestedConfig: const EngineConfig(runtime: 'auto'),
      effectiveConfig: const EngineConfig(runtime: 'llama_cpp'),
      plan: _FakeEngineApi._plan,
      restartRequiredFields: const [],
      fallbacks: const [],
      error: 'GPU-Runtime ist nicht verfügbar',
      errorSummary: 'Die Vulkan-Runtime muss neu gebaut werden.',
      errorCode: 'gpu_runtime_unavailable',
      suggestedFix: const SuggestedFix(
        action: 'reinstall_runtime',
        label: 'GPU-Runtime neu einrichten',
      ),
      progress: 1,
    );
    final api = _AlreadyAvailableVulkanRepairApi([failed]);

    await tester.pumpWidget(_testApp(EngineScreen(api: api)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('engine-workspace-instances')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('engine-suggested-fix-gpu-runtime-failed')),
    );
    await tester.pumpAndSettle();

    expect(api.runtimeRebuildCalls, 1);
    expect(api.lastRuntimeId, 'llama_cpp');
    expect(
      find.byKey(const Key('engine-gpu-admin-consent-dialog')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'keeps technical failures and restart fields behind optional details',
    (tester) async {
      await _setViewport(tester, const Size(1300, 1200));
      final failed = EngineInstance(
        id: 'broken',
        state: 'failed',
        modelId: 'model-gguf',
        servedModelName: 'Lokaler Assistent',
        requestedConfig: const EngineConfig(runtime: 'auto'),
        effectiveConfig: const EngineConfig(runtime: 'llama_cpp'),
        plan: _FakeEngineApi._plan,
        restartRequiredFields: const ['runtime', 'gpu_layers'],
        fallbacks: const [],
        error: 'exit status 1: build wheel failed',
        errorSummary:
            'Die Laufzeitprüfung ist fehlgeschlagen. Bitte versuche es erneut.',
        progress: 0,
      );
      final api = _FakeEngineApi(
        instances: [failed],
        runtimes: const [
          RuntimeCapability(
            id: 'llama_cpp',
            name: 'llama_cpp',
            status: 'failed',
            available: false,
            progress: 0,
            error: 'exit status 1: build wheel failed',
            supportedFields: ['gpu_layers'],
            liveFields: [],
            restartRequiredFields: ['gpu_layers'],
          ),
        ],
      );

      await tester.pumpWidget(_testApp(EngineScreen(api: api)));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('engine-workspace-instances')));
      await tester.pumpAndSettle();

      expect(find.textContaining('exit status 1'), findsNothing);
      expect(find.textContaining('gpu_layers'), findsNothing);
      expect(find.textContaining('Endpoint:'), findsNothing);
      expect(find.text('Erneut versuchen'), findsOneWidget);
      expect(
        find.text(
          'Die Laufzeitprüfung ist fehlgeschlagen. Bitte versuche es erneut.',
        ),
        findsOneWidget,
      );

      final detailsToggle = find.byKey(
        const Key('engine-instance-details-toggle-broken'),
      );
      await tester.ensureVisible(detailsToggle);
      await tester.tap(detailsToggle);
      await tester.pump();

      expect(
        find.byKey(const Key('engine-instance-details-broken')),
        findsOneWidget,
      );
      expect(find.text('Lokaler Modellname'), findsOneWidget);
      expect(find.textContaining('exit status 1'), findsOneWidget);
      expect(find.textContaining('GPU-Layer'), findsOneWidget);
      expect(find.textContaining('gpu_layers'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('hides an internal persisted planner conflict from the status', (
    tester,
  ) async {
    await _setViewport(tester, const Size(1300, 1200));
    const internal =
        'Hardwarebudget hat sich geaendert: engine plan conflict for target on memory: minimum context 4096 cannot fit; maximum is 0';
    final failed = EngineInstance(
      id: 'old-plan-conflict',
      state: 'failed',
      modelId: 'model-gguf',
      servedModelName: 'Lokaler Assistent',
      requestedConfig: const EngineConfig(runtime: 'auto'),
      effectiveConfig: const EngineConfig(runtime: 'llama_cpp'),
      plan: _FakeEngineApi._plan,
      restartRequiredFields: const [],
      fallbacks: const [],
      error: internal,
      errorSummary: internal,
      errorCode: 'engine_operation_failed',
      progress: 1,
    );

    await tester.pumpWidget(
      _testApp(EngineScreen(api: _FakeEngineApi(instances: [failed]))),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('engine-workspace-instances')));
    await tester.pumpAndSettle();

    expect(find.textContaining('engine plan conflict'), findsNothing);
    expect(
      find.textContaining('GPU und System-RAM werden beim nächsten Versuch'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('applies a ready event without interval polling', (tester) async {
    await _setViewport(tester, const Size(1300, 1400));
    final api = _PollingEngineApi();

    await tester.pumpWidget(_testApp(EngineScreen(api: api)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));

    await tester.tap(find.byKey(const Key('engine-workspace-instances')));
    await tester.pump();

    expect(find.text('Einmalige Einrichtung läuft'), findsOneWidget);
    expect(
      find.text('Die Modellgewichte werden jetzt in den Speicher geladen.'),
      findsWidgets,
    );

    await tester.pump(const Duration(milliseconds: 260));
    await tester.pump();

    expect(find.text('Bereit für lokale Anfragen'), findsOneWidget);
    expect(find.text('Einmalige Einrichtung läuft'), findsNothing);
    expect(
      find.text('„Lokaler Assistent“ wurde gestartet und ist bereit.'),
      findsOneWidget,
    );
    expect(api.instanceRequests, 1);
    expect(api.runtimeRequests, greaterThanOrEqualTo(2));

    final instanceRequestsAfterEvent = api.instanceRequests;
    final runtimeRequestsAfterEvent = api.runtimeRequests;
    await tester.pump(const Duration(seconds: 6));
    expect(api.instanceRequests, instanceRequestsAfterEvent);
    expect(api.runtimeRequests, runtimeRequestsAfterEvent);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'prioritizes the precise operation detail over generic progress',
    (tester) async {
      await _setViewport(tester, const Size(900, 1400));
      final api = _OperationDetailApi();

      await tester.pumpWidget(_testApp(EngineScreen(api: api)));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('engine-wizard-step-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('engine-model-model-gguf')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('engine-calculate-and-continue')));
      await tester.pumpAndSettle();
      final create = find.byKey(const Key('engine-create-instance'));
      await tester.ensureVisible(create);
      await tester.tap(create);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();

      expect(
        find.text(
          'Der Modellprozess läuft; 6 von 40 Gewichtsschichten sind geladen.',
        ),
        findsOneWidget,
      );
      expect(find.text('70 % abgeschlossen'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('refreshes an early runtime setup when an event arrives', (
    tester,
  ) async {
    await _setViewport(tester, const Size(1300, 1400));
    final api = _RuntimePrewarmApi();

    await tester.pumpWidget(_testApp(EngineScreen(api: api)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));

    expect(
      find.text('Isolierte Python-Umgebung wird angelegt'),
      findsOneWidget,
    );
    expect(find.text('10 % abgeschlossen'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 260));
    await tester.pump();

    expect(api.runtimeRequests, greaterThanOrEqualTo(2));
    expect(find.text('Isolierte Python-Umgebung wird angelegt'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'shows a friendly runtime failure and retries while details stay optional',
    (tester) async {
      await _setViewport(tester, const Size(900, 1400));
      final api = _FailedRuntimeApi();

      await tester.pumpWidget(_testApp(EngineScreen(api: api)));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('engine-setup-friendly-error')),
        findsOneWidget,
      );
      expect(find.textContaining('Netzwerkstörung'), findsOneWidget);
      expect(find.textContaining('pip connection traceback'), findsNothing);
      expect(find.byKey(const Key('engine-setup-retry')), findsOneWidget);

      final retry = find.byKey(const Key('engine-setup-retry'));
      await tester.ensureVisible(retry);
      await tester.tap(retry);
      await tester.pump();

      expect(api.installCalls, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'requires explicit hash-bound consent before retrying remote model code',
    (tester) async {
      await _setViewport(tester, const Size(1300, 1200));
      final api = _FakeEngineApi(requireRemoteCodeConsent: true);

      await tester.pumpWidget(_testApp(EngineScreen(api: api)));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('engine-wizard-step-1')));
      await tester.tap(find.byKey(const Key('engine-wizard-step-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('engine-model-model-safe')));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Expertenmodus'));
      await tester.tap(find.text('Expertenmodus'));
      await tester.pumpAndSettle();

      final trustTile = find.byKey(const Key('engine-trust-remote-code'));
      await tester.ensureVisible(trustTile);
      await tester.tap(trustTile);
      await tester.pumpAndSettle();

      final nextButton = find.byKey(const Key('engine-calculate-and-continue'));
      await tester.ensureVisible(nextButton);
      await tester.tap(nextButton);
      await tester.pumpAndSettle();

      final createButton = find.byKey(const Key('engine-create-instance'));
      await tester.ensureVisible(createButton);
      await tester.tap(createButton);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('engine-remote-code-consent-dialog')),
        findsOneWidget,
      );
      expect(
        find.textContaining('Der Kindprozess ist keine Sandbox.'),
        findsOneWidget,
      );
      expect(find.textContaining('Python-Dateien: 2'), findsOneWidget);
      expect(api.createCalls, 1);
      expect(api.approvalCalls, 0);
      expect(api.lastCreateConfig?.trustRemoteCode, isTrue);

      await tester.tap(find.byKey(const Key('engine-remote-code-accept')));
      await tester.pumpAndSettle();

      expect(api.approvalCalls, 1);
      expect(api.createCalls, 2);
      expect(api.approvedModelId, 'model-safe');
      expect(
        find.byKey(const Key('engine-remote-code-consent-dialog')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );
}

Widget _testApp(Widget child) {
  return MaterialApp(
    theme: ThemeData.dark(useMaterial3: true),
    home: Padding(padding: const EdgeInsets.all(18), child: child),
  );
}

Future<void> _setViewport(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

class _FakeEngineApi implements EngineApi {
  _FakeEngineApi({
    this.requireRemoteCodeConsent = false,
    List<RuntimeCapability>? runtimes,
    List<EngineInstance>? instances,
  }) : runtimeValues = runtimes ?? _runtimes,
       instanceValues = instances ?? _instances;

  final bool requireRemoteCodeConsent;
  final List<RuntimeCapability> runtimeValues;
  final List<EngineInstance> instanceValues;
  int createCalls = 0;
  int approvalCalls = 0;
  int gpuConsentCalls = 0;
  int gpuDependencyInstallCalls = 0;
  int deleteModelCalls = 0;
  bool _remoteCodeApproved = false;
  String? approvedModelId;
  String? lastGpuConsentToken;
  String? lastDeletedModelId;
  EngineConfig? lastCreateConfig;
  Map<String, dynamic>? lastUpdateChanges;
  final StreamController<EngineStreamEvent> engineEvents =
      StreamController<EngineStreamEvent>.broadcast();

  void emitEngineEvent(EngineStreamEvent event) {
    if (!engineEvents.isClosed) engineEvents.add(event);
  }

  void completeOperationSoon(String operationId, {String type = 'engine'}) {
    Future<void>.delayed(Duration.zero, () {
      emitEngineEvent(
        EngineStreamEvent(
          type: 'operation',
          data: {
            'id': operationId,
            'type': type,
            'state': 'completed',
            'progress': 1.0,
            'message': 'Fertig',
          },
        ),
      );
    });
  }

  static const _models = [
    ModelRecord(
      id: 'model-gguf',
      name: 'Llama Writer',
      format: 'gguf',
      relativePath: 'llama/writer.gguf',
      sizeBytes: 4294967296,
      status: 'ready',
      architecture: 'llama',
      quantization: 'Q4_K_M',
      modelContextLimitTokens: 32768,
      runtimeCandidates: ['llama-cpp-python'],
      validationIssues: [],
    ),
    ModelRecord(
      id: 'model-safe',
      name: 'Coder SafeTensors',
      format: 'safetensors',
      relativePath: 'coder/main',
      sizeBytes: 8589934592,
      status: 'ready',
      architecture: 'qwen2',
      quantization: 'BF16',
      modelContextLimitTokens: 65536,
      runtimeCandidates: ['vllm', 'transformers'],
      validationIssues: [],
    ),
  ];

  static const _plan = ContextPlan(
    modelContextLimitTokens: 32768,
    gpuOnlyMaxContextTokens: 16384,
    hybridMaxContextTokens: 32768,
    effectiveContextTokens: 24576,
    ramRequiredAfterTokens: 16384,
    memory: MemoryBreakdown(
      weightsBytes: 4294967296,
      kvCacheBytes: 536870912,
      runtimeBytes: 268435456,
      reserveBytes: 1073741824,
      gpuBytes: 5368709120,
      ramBytes: 1073741824,
    ),
    confidence: 'measured',
    warnings: [],
  );

  static const _runtimes = [
    RuntimeCapability(
      id: 'llama-cpp-python',
      name: 'llama-cpp-python',
      status: 'ready',
      available: true,
      progress: 1,
      error: null,
      supportedFields: ['gpu_layers', 'threads', 'kv_cache_dtype'],
      liveFields: ['generation_defaults'],
      restartRequiredFields: ['context_tokens', 'gpu_layers'],
    ),
    RuntimeCapability(
      id: 'vllm',
      name: 'vLLM',
      status: 'installing',
      available: false,
      progress: 0.45,
      error: null,
      supportedFields: ['tensor_parallel_size', 'kv_cache_dtype'],
      liveFields: ['generation_defaults'],
      restartRequiredFields: ['context_tokens', 'tensor_parallel_size'],
    ),
  ];

  static const _instances = [
    EngineInstance(
      id: 'writer',
      state: 'ready',
      modelId: 'model-gguf',
      servedModelName: 'local-writer',
      requestedConfig: EngineConfig(runtime: 'auto'),
      effectiveConfig: EngineConfig(
        runtime: 'llama-cpp-python',
        contextMode: 'fixed',
        contextTokens: 24576,
      ),
      plan: _plan,
      restartRequiredFields: [],
      fallbacks: [],
      error: null,
      progress: 1,
    ),
    EngineInstance(
      id: 'coder',
      state: 'ready',
      modelId: 'model-safe',
      servedModelName: 'local-coder',
      requestedConfig: EngineConfig(runtime: 'vllm'),
      effectiveConfig: EngineConfig(
        runtime: 'transformers',
        contextMode: 'fixed',
        contextTokens: 24576,
      ),
      plan: _plan,
      restartRequiredFields: [],
      fallbacks: [
        EngineFallback(
          from: 'vllm',
          to: 'transformers',
          reason: 'ROCm ist nicht verfügbar',
        ),
      ],
      error: null,
      progress: 1,
    ),
  ];

  @override
  Future<List<ModelRecord>> getEngineModels() async => _models;

  @override
  Future<List<ModelRecord>> rescanEngineModels() async => _models;

  @override
  Future<List<ModelRecord>> deleteEngineModel(String modelId) async {
    deleteModelCalls++;
    lastDeletedModelId = modelId;
    return _models.where((model) => model.id != modelId).toList();
  }

  @override
  Future<EngineCapabilities> getEngineCapabilities() async =>
      const EngineCapabilities(
        hardware: HardwareSnapshot(
          ramTotalBytes: 34359738368,
          ramAvailableBytes: 17179869184,
          gpus: [
            GpuDevice(
              id: 'gpu-0',
              name: 'Test GPU',
              vramTotalBytes: 17179869184,
              vramFreeBytes: 12884901888,
              backend: 'vulkan',
              unifiedMemory: false,
            ),
          ],
        ),
        runtimes: _runtimes,
        defaults: {
          'ram_reserve_bytes': 4294967296,
          'gpu_reserve_bytes': 1073741824,
        },
      );

  @override
  Future<List<RuntimeCapability>> getEngineRuntimes() async => runtimeValues;

  @override
  Future<EngineMutationResult> installEngineRuntime(String runtimeId) async =>
      const EngineMutationResult();

  @override
  Future<SystemDependencyConsent> createVulkanDependencyConsent() async {
    gpuConsentCalls++;
    return SystemDependencyConsent(
      token: 'one-use-consent',
      expiresAt: DateTime.utc(2026, 7, 16, 21),
      packageName:
          'libvulkan-dev, glslc, spirv-headers, cmake und build-essential',
      commandSummary: 'Vulkan-Build-Abhängigkeiten installieren',
      warning: 'Das Betriebssystem fragt nach Administratorrechten.',
    );
  }

  @override
  Future<EngineMutationResult> installVulkanDependency(
    SystemDependencyConsent consent,
  ) async {
    gpuDependencyInstallCalls++;
    lastGpuConsentToken = consent.token;
    completeOperationSoon('gpu-repair', type: 'system_dependency_install');
    return const EngineMutationResult(operationId: 'gpu-repair');
  }

  @override
  Future<ContextPlan> getEngineRecommendation(
    String modelId, {
    EngineConfig? config,
  }) async => _plan;

  @override
  Future<RemoteCodeApproval> approveRemoteCode(String modelId) async {
    approvalCalls++;
    approvedModelId = modelId;
    _remoteCodeApproved = true;
    return const RemoteCodeApproval(
      modelId: 'model-safe',
      fingerprint: 'model-fingerprint',
      pythonFilesHash: 'python-hash',
      pythonFileCount: 2,
      warning: 'Der Kindprozess ist keine Sandbox.',
    );
  }

  @override
  Future<List<EngineInstance>> getEngineInstances() async => instanceValues;

  @override
  Future<EngineMutationResult> createEngineInstance({
    required String modelId,
    String? servedModelName,
    required EngineConfig config,
  }) async {
    createCalls++;
    lastCreateConfig = config;
    if (requireRemoteCodeConsent &&
        config.trustRemoteCode &&
        !_remoteCodeApproved) {
      throw const EngineApiException(
        'Explizite Zustimmung für modelleigenen Code ist erforderlich.',
        statusCode: 409,
        code: 'remote_code_consent_required',
        details: {
          'code': 'remote_code_consent_required',
          'model_fingerprint': 'model-fingerprint',
          'python_files_hash': 'python-hash',
          'python_file_count': 2,
          'not_a_sandbox': true,
        },
      );
    }
    return EngineMutationResult(instance: _instances.first);
  }

  @override
  Future<EngineInstance> getEngineInstance(String instanceId) async =>
      _instances.firstWhere((instance) => instance.id == instanceId);

  @override
  Future<EngineEnsureReadyResult> ensureEngineInstanceReady(
    String instanceId,
  ) async => EngineEnsureReadyResult(
    status: 'ready',
    instance: await getEngineInstance(instanceId),
  );

  @override
  Stream<EngineStreamEvent> streamEngineEvents() => engineEvents.stream;

  @override
  Future<EngineMutationResult> updateEngineInstance(
    String instanceId,
    Map<String, dynamic> changes,
  ) async {
    lastUpdateChanges = changes;
    return EngineMutationResult(
      instance: instanceValues.firstWhere(
        (instance) => instance.id == instanceId,
        orElse: () => _instances.first,
      ),
    );
  }

  @override
  Future<EngineMutationResult> deleteEngineInstance(String instanceId) async =>
      const EngineMutationResult();

  @override
  Future<EngineOperation> getEngineOperation(String operationId) async =>
      EngineOperation(
        id: operationId,
        type: 'start',
        state: 'completed',
        instanceId: 'writer',
        progress: 1,
        message: 'Fertig',
        error: null,
      );

  @override
  Future<EngineOperation> cancelEngineOperation(String operationId) =>
      getEngineOperation(operationId);
}

class _HybridRecommendationApi extends _FakeEngineApi {
  @override
  Future<ContextPlan> getEngineRecommendation(
    String modelId, {
    EngineConfig? config,
  }) async {
    if (config?.runtimeOptions['allow_ram_offload'] != true) {
      throw const EngineApiException(
        'engine plan conflict for recommendation on memory',
        statusCode: 409,
        code: 'resource_conflict',
      );
    }
    return const ContextPlan(
      modelContextLimitTokens: 32768,
      gpuOnlyMaxContextTokens: 0,
      hybridMaxContextTokens: 24576,
      effectiveContextTokens: 24576,
      ramRequiredAfterTokens: 0,
      memory: MemoryBreakdown(
        weightsBytes: 4294967296,
        kvCacheBytes: 536870912,
        runtimeBytes: 268435456,
        reserveBytes: 1073741824,
        gpuBytes: 2147483648,
        ramBytes: 3221225472,
      ),
      confidence: 'measured',
      warnings: [],
      usesRam: true,
    );
  }
}

class _RuntimeUnavailableRecommendationApi extends _HybridRecommendationApi {
  bool repaired = false;
  final List<EngineConfig> recommendationConfigs = [];

  @override
  Future<ContextPlan> getEngineRecommendation(
    String modelId, {
    EngineConfig? config,
  }) async {
    if (config != null) recommendationConfigs.add(config);
    if (repaired) return _FakeEngineApi._plan;
    if (!repaired && config?.runtimeOptions['allow_ram_offload'] != true) {
      throw const EngineApiException(
        'GPU-Runtime ist noch nicht verfügbar',
        statusCode: 409,
        code: 'gpu_runtime_unavailable',
        details: {'reason': 'Vulkan-Entwicklungsdateien fehlen für llama.cpp.'},
      );
    }
    return super.getEngineRecommendation(modelId, config: config);
  }

  @override
  Future<EngineMutationResult> installVulkanDependency(
    SystemDependencyConsent consent,
  ) async {
    final result = await super.installVulkanDependency(consent);
    repaired = true;
    return result;
  }
}

class _FailedVulkanRuntimeRecommendationApi
    extends _RuntimeUnavailableRecommendationApi {
  bool runtimeRebuilt = false;
  int runtimeRebuildCalls = 0;

  @override
  Future<ContextPlan> getEngineRecommendation(
    String modelId, {
    EngineConfig? config,
  }) async {
    if (config != null) recommendationConfigs.add(config);
    if (runtimeRebuilt) return _FakeEngineApi._plan;
    if (config?.runtimeOptions['allow_ram_offload'] != true) {
      throw const EngineApiException(
        'GPU-Runtime ist noch nicht verfügbar',
        statusCode: 409,
        code: 'gpu_runtime_unavailable',
        details: {
          'reason': 'Der Vulkan-GPU-Funktionstest ist fehlgeschlagen.',
          'remediation': 'rebuild_gpu_runtime',
        },
      );
    }
    return _HybridRecommendationApi().getEngineRecommendation(
      modelId,
      config: config,
    );
  }

  @override
  Future<EngineMutationResult> installEngineRuntime(String runtimeId) async {
    expect(runtimeId, 'llama_cpp');
    runtimeRebuildCalls++;
    runtimeRebuilt = true;
    completeOperationSoon('vulkan-runtime-rebuild', type: 'runtime_install');
    return const EngineMutationResult(operationId: 'vulkan-runtime-rebuild');
  }
}

class _AlreadyAvailableVulkanRepairApi extends _FakeEngineApi {
  _AlreadyAvailableVulkanRepairApi(List<EngineInstance> instances)
    : super(instances: instances);

  int runtimeRebuildCalls = 0;
  String? lastRuntimeId;

  @override
  Future<SystemDependencyConsent> createVulkanDependencyConsent() async {
    gpuConsentCalls++;
    throw const EngineApiException(
      'Die Vulkan-Build-Abhängigkeiten sind bereits installiert.',
      statusCode: 409,
      code: 'dependency_already_available',
    );
  }

  @override
  Future<EngineMutationResult> installEngineRuntime(String runtimeId) async {
    runtimeRebuildCalls++;
    lastRuntimeId = runtimeId;
    completeOperationSoon('vulkan-runtime-rebuild', type: 'runtime_install');
    return const EngineMutationResult(operationId: 'vulkan-runtime-rebuild');
  }
}

class _EarlyCompletedRuntimeApi extends _FakeEngineApi {
  @override
  Future<EngineMutationResult> installEngineRuntime(String runtimeId) async {
    emitEngineEvent(
      const EngineStreamEvent(
        type: 'operation',
        data: {
          'id': 'early-runtime',
          'type': 'runtime_install',
          'state': 'completed',
          'progress': 1.0,
          'message': 'GPU-Runtime ist bereit',
        },
      ),
    );
    await Future<void>.delayed(Duration.zero);
    return const EngineMutationResult(operationId: 'early-runtime');
  }

  @override
  Future<EngineOperation> getEngineOperation(String operationId) async =>
      EngineOperation(
        id: operationId,
        type: 'runtime_install',
        state: 'running',
        instanceId: null,
        progress: 0.8,
        message: 'Fast fertig',
        error: null,
      );
}

class _RestReadyApi extends _FakeEngineApi {
  int instanceRequests = 0;

  static const installing = EngineInstance(
    id: 'rest-ready',
    state: 'starting',
    modelId: 'model-gguf',
    servedModelName: 'REST Ready',
    requestedConfig: EngineConfig(runtime: 'auto'),
    effectiveConfig: EngineConfig(runtime: 'llama_cpp'),
    plan: _FakeEngineApi._plan,
    restartRequiredFields: [],
    fallbacks: [],
    error: null,
    progress: 0.7,
  );

  static const ready = EngineInstance(
    id: 'rest-ready',
    state: 'ready',
    modelId: 'model-gguf',
    servedModelName: 'REST Ready',
    requestedConfig: EngineConfig(runtime: 'auto'),
    effectiveConfig: EngineConfig(runtime: 'llama_cpp'),
    plan: _FakeEngineApi._plan,
    restartRequiredFields: [],
    fallbacks: [],
    error: null,
    progress: 1,
  );

  @override
  Future<List<EngineInstance>> getEngineInstances() async {
    instanceRequests++;
    return [instanceRequests == 1 ? installing : ready];
  }

  @override
  Future<EngineMutationResult> createEngineInstance({
    required String modelId,
    String? servedModelName,
    required EngineConfig config,
  }) async => const EngineMutationResult(instance: installing);
}

class _ReconnectCatalogApi extends _FakeEngineApi {
  int modelRequests = 0;
  bool catalogChanged = false;

  @override
  Future<List<ModelRecord>> getEngineModels() async {
    modelRequests++;
    return catalogChanged
        ? [_FakeEngineApi._models.last]
        : _FakeEngineApi._models;
  }
}

class _StaleRestAfterReadyApi extends _FakeEngineApi {
  int instanceRequests = 0;

  @override
  Future<List<EngineInstance>> getEngineInstances() async {
    instanceRequests++;
    if (instanceRequests > 1) {
      emitEngineEvent(
        const EngineStreamEvent(
          type: 'instance_changed',
          data: {
            'id': 'stale-rest',
            'state': 'ready',
            'model_id': 'model-gguf',
            'served_model_name': 'Event Ready',
            'requested_config': {'runtime': 'auto'},
            'effective_config': {'runtime': 'llama_cpp'},
            'plan_revision': 1,
            'progress': 1.0,
          },
        ),
      );
      await Future<void>.delayed(Duration.zero);
    }
    return const [
      EngineInstance(
        id: 'stale-rest',
        state: 'starting',
        modelId: 'model-gguf',
        servedModelName: 'Event Ready',
        requestedConfig: EngineConfig(runtime: 'auto'),
        effectiveConfig: EngineConfig(runtime: 'llama_cpp'),
        plan: _FakeEngineApi._plan,
        restartRequiredFields: [],
        fallbacks: [],
        error: null,
        progress: 0.6,
        planRevision: 1,
      ),
    ];
  }

  @override
  Future<EngineMutationResult> createEngineInstance({
    required String modelId,
    String? servedModelName,
    required EngineConfig config,
  }) async => const EngineMutationResult(operationId: 'stale-rest-start');
}

class _PollingEngineApi extends _FakeEngineApi {
  int instanceRequests = 0;
  int runtimeRequests = 0;
  bool _eventScheduled = false;

  static final _installingInstance = EngineInstance(
    id: 'setup',
    state: 'installing',
    modelId: 'model-gguf',
    servedModelName: 'Lokaler Assistent',
    requestedConfig: const EngineConfig(runtime: 'auto'),
    effectiveConfig: const EngineConfig(runtime: 'llama_cpp'),
    plan: _FakeEngineApi._plan,
    restartRequiredFields: const [],
    fallbacks: const [],
    error: null,
    phase: 'loading_weights',
    detailMessage: 'Die Modellgewichte werden jetzt in den Speicher geladen.',
    progress: 0.4,
  );

  @override
  Future<List<EngineInstance>> getEngineInstances() async {
    instanceRequests++;
    return [_installingInstance];
  }

  @override
  Future<List<RuntimeCapability>> getEngineRuntimes() async {
    runtimeRequests++;
    return [
      RuntimeCapability(
        id: 'llama_cpp',
        name: 'llama.cpp',
        status: runtimeRequests == 1 ? 'installing' : 'ready',
        available: runtimeRequests > 1,
        progress: runtimeRequests == 1 ? 0.4 : 1,
        error: null,
        supportedFields: const [],
        liveFields: const [],
        restartRequiredFields: const [],
      ),
    ];
  }

  @override
  Stream<EngineStreamEvent> streamEngineEvents() {
    if (!_eventScheduled) {
      _eventScheduled = true;
      Future<void>.delayed(const Duration(milliseconds: 100), () {
        emitEngineEvent(
          const EngineStreamEvent(
            type: 'instance_changed',
            data: {
              'id': 'setup',
              'state': 'ready',
              'model_id': 'model-gguf',
              'served_model_name': 'Lokaler Assistent',
              'requested_config': {'runtime': 'auto'},
              'effective_config': {'runtime': 'llama_cpp'},
              'progress': 1.0,
            },
          ),
        );
      });
    }
    return super.streamEngineEvents();
  }
}

class _RuntimePrewarmApi extends _FakeEngineApi {
  int runtimeRequests = 0;
  bool _eventScheduled = false;

  @override
  Future<List<EngineInstance>> getEngineInstances() async => const [];

  @override
  Future<List<RuntimeCapability>> getEngineRuntimes() async {
    runtimeRequests++;
    return [
      RuntimeCapability(
        id: 'llama_cpp',
        name: 'llama.cpp',
        status: runtimeRequests == 1 ? 'creating_environment' : 'ready',
        available: runtimeRequests > 1,
        progress: runtimeRequests == 1 ? 0.1 : 1,
        error: null,
        statusMessage: runtimeRequests == 1
            ? 'Isolierte Python-Umgebung wird angelegt'
            : 'Runtime ist installiert und einsatzbereit',
        supportedFields: const [],
        liveFields: const [],
        restartRequiredFields: const [],
      ),
    ];
  }

  @override
  Stream<EngineStreamEvent> streamEngineEvents() {
    if (!_eventScheduled) {
      _eventScheduled = true;
      Future<void>.delayed(const Duration(milliseconds: 100), () {
        emitEngineEvent(
          const EngineStreamEvent(
            type: 'operation',
            data: {
              'id': 'runtime-prewarm',
              'type': 'runtime_prewarm',
              'state': 'completed',
              'progress': 1.0,
              'message': 'Runtime ist bereit',
            },
          ),
        );
      });
    }
    return super.streamEngineEvents();
  }
}

class _OperationDetailApi extends _FakeEngineApi {
  @override
  Future<List<EngineInstance>> getEngineInstances() async => const [];

  @override
  Future<List<RuntimeCapability>> getEngineRuntimes() async => const [
    RuntimeCapability(
      id: 'llama_cpp',
      name: 'llama.cpp',
      status: 'ready',
      available: true,
      progress: 1,
      error: null,
      supportedFields: [],
      liveFields: [],
      restartRequiredFields: [],
    ),
  ];

  @override
  Future<EngineMutationResult> createEngineInstance({
    required String modelId,
    String? servedModelName,
    required EngineConfig config,
  }) async {
    Future<void>.delayed(const Duration(milliseconds: 20), () {
      emitEngineEvent(
        const EngineStreamEvent(
          type: 'operation',
          data: {
            'id': 'operation-detail',
            'type': 'start',
            'state': 'running',
            'instance_id': 'local-model',
            'progress': 0.7,
            'phase': 'loading_weights',
            'message': 'Modell wird gestartet',
            'detail_message':
                'Der Modellprozess läuft; 6 von 40 Gewichtsschichten sind geladen.',
          },
        ),
      );
    });
    return const EngineMutationResult(operationId: 'operation-detail');
  }

  @override
  Future<EngineOperation> getEngineOperation(String operationId) async =>
      EngineOperation(
        id: operationId,
        type: 'start',
        state: 'running',
        instanceId: 'local-model',
        progress: 0.7,
        phase: 'loading_weights',
        message: 'Modell wird gestartet',
        detailMessage:
            'Der Modellprozess läuft; 6 von 40 Gewichtsschichten sind geladen.',
        error: null,
      );
}

class _FailedRuntimeApi extends _FakeEngineApi {
  int installCalls = 0;

  @override
  Future<List<EngineInstance>> getEngineInstances() async => const [];

  @override
  Future<List<RuntimeCapability>> getEngineRuntimes() async => const [
    RuntimeCapability(
      id: 'llama_cpp',
      name: 'llama.cpp',
      status: 'failed',
      available: false,
      progress: 1,
      error: 'pip connection traceback: exit status 1',
      statusMessage: 'Fehlgeschlagen während der Paketinstallation',
      errorCode: 'network_unavailable',
      supportedFields: [],
      liveFields: [],
      restartRequiredFields: [],
    ),
  ];

  @override
  Future<EngineMutationResult> installEngineRuntime(String runtimeId) async {
    installCalls++;
    return const EngineMutationResult();
  }
}
