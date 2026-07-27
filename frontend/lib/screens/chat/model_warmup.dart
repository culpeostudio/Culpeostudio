import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/chat_aux_strings.dart';

void prepareWarmupRetryMessages(
  List<Map<String, dynamic>> messages,
  String originalMessage,
) {
  final text = originalMessage.trim();
  if (text.isEmpty) return;
  final existingUser = messages.lastIndexWhere(
    (message) =>
        message['role'] == 'user' &&
        message['content']?.toString().trim() == text,
  );
  if (existingUser < 0) {
    messages.add({'role': 'user', 'content': text});
  }
  if (messages.isEmpty || messages.last['role'] != 'assistant') {
    messages.add({'role': 'assistant', 'content': ''});
  }
}

class ModelWarmupProgress extends ChangeNotifier {
  ModelWarmupProgress({this.tickInterval = const Duration(milliseconds: 120)});

  final Duration tickInterval;
  Timer? _timer;
  double _displayProgress = 0;
  double _phaseCeiling = 0.08;

  String instanceId = '';
  String operationId = '';
  String modelName = '';
  String status = 'idle';
  String phase = '';
  String message = '';
  String placement = 'unknown';
  String errorCode = '';
  int? queuePosition;

  double get displayProgress => _displayProgress;
  bool get isActive =>
      const {'queued', 'running', 'starting', 'warming'}.contains(status);
  bool get isReady => status == 'ready';
  bool get hasFailed =>
      const {'failed', 'error', 'cancelled', 'canceled'}.contains(status);

  String get placementLabel => switch (placement) {
    'gpu' => 'GPU',
    'ram' => 'RAM',
    'hybrid' => 'GPU + RAM',
    _ => tr('chatAux.warmup.placementPending'),
  };

  void begin({
    required String instanceId,
    required String modelName,
    String placement = 'unknown',
  }) {
    this.instanceId = instanceId;
    this.modelName = modelName;
    this.placement = _normalizePlacement(placement);
    operationId = '';
    status = 'queued';
    phase = 'queued';
    message = tr('chatAux.warmup.waiting');
    errorCode = '';
    queuePosition = null;
    _displayProgress = 0.01;
    _phaseCeiling = phaseCeilingForPhase(phase);
    _ensureTimer();
    notifyListeners();
  }

  void updateFromJson(Map<String, dynamic> json) {
    final nextStatus = (json['status'] ?? json['state'])?.toString().trim();
    final nextPhase = json['phase']?.toString().trim();
    final rawProgress = json['progress'];
    var realProgress = rawProgress is num
        ? rawProgress.toDouble()
        : double.tryParse(rawProgress?.toString() ?? '') ?? 0;
    if (realProgress > 1) realProgress /= 100;

    instanceId = json['instance_id']?.toString().trim().isNotEmpty == true
        ? json['instance_id'].toString().trim()
        : instanceId;
    operationId = json['operation_id']?.toString().trim().isNotEmpty == true
        ? json['operation_id'].toString().trim()
        : operationId;
    status = nextStatus?.isNotEmpty == true
        ? _normalizeStatus(nextStatus!)
        : status;
    phase = nextPhase?.isNotEmpty == true ? nextPhase! : phase;
    message = json['message']?.toString().trim().isNotEmpty == true
        ? json['message'].toString().trim()
        : message;
    placement = json['placement']?.toString().trim().isNotEmpty == true
        ? _normalizePlacement(json['placement'].toString())
        : placement;
    errorCode = json['code']?.toString().trim() ?? errorCode;
    final rawQueue = json['queue_position'];
    if (rawQueue != null) {
      queuePosition = rawQueue is num
          ? rawQueue.toInt()
          : int.tryParse(rawQueue.toString());
    }

    if (isReady) {
      _displayProgress = 1;
      _phaseCeiling = 1;
      _timer?.cancel();
      _timer = null;
    } else {
      final ceiling = phaseCeilingForPhase(phase);
      _phaseCeiling = math.max(_phaseCeiling, ceiling);
      final anchored = realProgress.clamp(0.0, 0.99);
      _displayProgress = math.max(_displayProgress, anchored);
      if (isActive) {
        _ensureTimer();
      } else {
        _timer?.cancel();
        _timer = null;
      }
    }
    notifyListeners();
  }

  void complete({String? message}) {
    status = 'ready';
    phase = 'ready';
    this.message = message ?? tr('chat.warmup.modelReady');
    _displayProgress = 1;
    _phaseCeiling = 1;
    _timer?.cancel();
    _timer = null;
    notifyListeners();
  }

  void fail({required String message, String code = ''}) {
    status = 'failed';
    this.message = message;
    errorCode = code;
    _timer?.cancel();
    _timer = null;
    notifyListeners();
  }

  void cancel() {
    status = 'cancelled';
    message = tr('chatAux.warmup.cancelled');
    errorCode = 'model_warmup_canceled';
    _timer?.cancel();
    _timer = null;
    notifyListeners();
  }

  void reset() {
    _timer?.cancel();
    _timer = null;
    _displayProgress = 0;
    _phaseCeiling = 0.08;
    instanceId = '';
    operationId = '';
    modelName = '';
    status = 'idle';
    phase = '';
    message = '';
    placement = 'unknown';
    errorCode = '';
    queuePosition = null;
    notifyListeners();
  }

  void _ensureTimer() {
    if (_timer?.isActive == true) return;
    _timer = Timer.periodic(tickInterval, (_) {
      if (!isActive) return;
      final ceiling = math.min(_phaseCeiling, 0.99);
      if (_displayProgress >= ceiling - 0.0005) return;
      final remaining = ceiling - _displayProgress;
      _displayProgress = math.min(
        ceiling - 0.0001,
        _displayProgress + math.max(0.0004, remaining * 0.045),
      );
      notifyListeners();
    });
  }

  @visibleForTesting
  static double phaseCeilingForPhase(String rawPhase) {
    final value = rawPhase.trim().toLowerCase().replaceAll(
      RegExp(r'[-\s]+'),
      '_',
    );
    switch (value) {
      case 'queued':
      case 'admission':
        return 0.12;
      case 'preparing_runtime':
        return 0.22;
      case 'runtime_ready':
        return 0.30;
      case 'refreshing_plan':
        return 0.36;
      case 'lru_evicting':
        return 0.40;
      case 'starting_instances':
        return 0.48;
      case 'launching_worker':
        return 0.66;
      case 'loading_model':
        return 0.78;
      case 'worker_initializing':
        return 0.86;
      case 'worker_ready':
        return 0.92;
      case 'verifying_worker':
        return 0.98;
      case 'instance_verified':
        return 0.99;
      case 'ready':
        return 1;
    }
    if (value.contains('queue') || value.contains('admission')) return 0.12;
    if (value.contains('resource')) return 0.18;
    if (value.contains('plan')) return 0.36;
    if (value.contains('runtime') || value.contains('environment')) return 0.30;
    if (value.contains('evict')) return 0.40;
    if (value.contains('launch') || value.contains('spawn')) return 0.66;
    if (value.contains('weight') || value.contains('load')) return 0.78;
    if (value.contains('initializ')) return 0.86;
    if (value.contains('health') || value.contains('worker_ready')) return 0.92;
    if (value.contains('verify') ||
        value.contains('inference') ||
        value.contains('probe')) {
      return 0.98;
    }
    return 0.18;
  }

  static String _normalizeStatus(String value) {
    switch (value.toLowerCase()) {
      case 'completed':
      case 'complete':
        return 'ready';
      case 'starting':
      case 'running':
        return 'running';
      case 'canceled':
        return 'cancelled';
      default:
        return value.toLowerCase();
    }
  }

  static String _normalizePlacement(String value) {
    switch (value.toLowerCase()) {
      case 'gpu':
      case 'ram':
      case 'hybrid':
        return value.toLowerCase();
      default:
        return 'unknown';
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

class ModelWarmupPanel extends StatelessWidget {
  const ModelWarmupPanel({
    super.key,
    required this.progress,
    this.onCancel,
    this.onRetry,
    this.onChangeBinding,
    this.onChooseAnother,
  });

  final ModelWarmupProgress progress;
  final VoidCallback? onCancel;
  final VoidCallback? onRetry;
  final VoidCallback? onChangeBinding;
  final VoidCallback? onChooseAnother;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (context, _) {
        if (progress.status == 'idle') return const SizedBox.shrink();
        final failed = progress.hasFailed;
        final color = failed
            ? const Color(0xFFEF5350)
            : const Color(0xFFDFC077);
        return Semantics(
          liveRegion: true,
          label: tr('chatAux.warmup.semanticProgress', {
            'model': progress.modelName,
            'percent': (progress.displayProgress * 100).floor().toString(),
            'phase': _phaseLabel(progress.phase),
          }),
          child: Container(
            key: const Key('model-warmup-panel'),
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      failed ? Icons.error_outline : Icons.memory_outlined,
                      color: color,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            failed
                                ? tr('chatAux.warmup.startFailed')
                                : tr('chatAux.warmup.waiting'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            progress.modelName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _PlacementChip(label: progress.placementLabel),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  key: const Key('model-warmup-progress'),
                  value: progress.displayProgress,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(6),
                  color: color,
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                ),
                const SizedBox(height: 7),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            failed
                                ? progress.message
                                : _phaseLabel(progress.phase),
                            style: TextStyle(
                              color: failed ? color : Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (!failed &&
                              progress.message.isNotEmpty &&
                              progress.message !=
                                  tr('chatAux.warmup.waiting') &&
                              progress.message !=
                                  _phaseLabel(progress.phase)) ...[
                            const SizedBox(height: 2),
                            Text(
                              progress.message,
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (progress.queuePosition != null)
                      Text(
                        tr('chatAux.warmup.queuePosition', {
                          'position': progress.queuePosition.toString(),
                        }),
                        key: const Key('model-warmup-queue-position'),
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    const SizedBox(width: 10),
                    Text(
                      '${(progress.displayProgress * 100).floor()} %',
                      key: const Key('model-warmup-percent'),
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                if (failed) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (onChooseAnother != null)
                        TextButton(
                          onPressed: onChooseAnother,
                          child: Text(tr('chatAux.warmup.chooseAnother')),
                        ),
                      if (onChangeBinding != null)
                        TextButton(
                          onPressed: onChangeBinding,
                          child: Text(tr('chatAux.warmup.changeBinding')),
                        ),
                      if (onRetry != null)
                        FilledButton.tonalIcon(
                          onPressed: onRetry,
                          icon: const Icon(Icons.refresh, size: 17),
                          label: Text(tr('common.retry')),
                        ),
                    ],
                  ),
                ] else if (progress.isActive && onCancel != null) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      key: const Key('model-warmup-cancel'),
                      onPressed: onCancel,
                      icon: const Icon(Icons.close, size: 17),
                      label: Text(tr('common.cancel')),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  static String _phaseLabel(String phase) {
    final normalized = phase.trim().toLowerCase().replaceAll(
      RegExp(r'[-\s]+'),
      '_',
    );
    switch (normalized) {
      case 'queued':
        return tr('chatAux.warmup.phase.queued');
      case 'admission':
        return tr('chatAux.warmup.phase.admission');
      case 'preparing_runtime':
        return tr('chatAux.warmup.phase.preparingRuntime');
      case 'runtime_ready':
        return tr('chatAux.warmup.phase.runtimeReady');
      case 'refreshing_plan':
        return tr('chatAux.warmup.phase.refreshingPlan');
      case 'lru_evicting':
        return tr('chatAux.warmup.phase.evicting');
      case 'starting_instances':
        return tr('chatAux.warmup.phase.startingInstances');
      case 'launching_worker':
        return tr('chatAux.warmup.phase.launchingWorker');
      case 'loading_model':
        return tr('chatAux.warmup.phase.loadingModel');
      case 'worker_initializing':
        return tr('chatAux.warmup.phase.workerInitializing');
      case 'worker_ready':
        return tr('chatAux.warmup.phase.workerReady');
      case 'verifying_worker':
        return tr('chatAux.warmup.phase.verifyingWorker');
      case 'instance_verified':
        return tr('chatAux.warmup.phase.instanceVerified');
      case 'ready':
        return tr('chat.warmup.modelReady');
    }
    if (normalized.contains('queue')) {
      return tr('chatAux.warmup.phase.queued');
    }
    if (normalized.contains('admission')) {
      return tr('chatAux.warmup.phase.admission');
    }
    if (normalized.contains('resource') || normalized.contains('plan')) {
      return tr('chatAux.warmup.phase.resourcePlan');
    }
    if (normalized.contains('runtime')) {
      return tr('chatAux.warmup.phase.preparingRuntime');
    }
    if (normalized.contains('evict')) {
      return tr('chatAux.warmup.phase.evicting');
    }
    if (normalized.contains('launch') || normalized.contains('spawn')) {
      return tr('chatAux.warmup.phase.launchingWorker');
    }
    if (normalized.contains('weight') || normalized.contains('load')) {
      return tr('chatAux.warmup.phase.loadingModel');
    }
    if (normalized.contains('health') ||
        normalized.contains('initializ') ||
        normalized.contains('worker_ready')) {
      return tr('chatAux.warmup.phase.healthcheck');
    }
    if (normalized.contains('verify') ||
        normalized.contains('inference') ||
        normalized.contains('probe')) {
      return tr('chatAux.warmup.phase.verifyingWorker');
    }
    return tr('chatAux.warmup.phase.preparing');
  }
}

class _PlacementChip extends StatelessWidget {
  const _PlacementChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
