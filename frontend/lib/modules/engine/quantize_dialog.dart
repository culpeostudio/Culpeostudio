// Quantising a local GGUF down to a smaller one.
//
// The dialog leads with the trade rather than the controls, because the choice
// here is not "which format" but "how much quality am I spending to get how
// much space back". Everything the engine can say about that - the exact output
// size from the tool's own dry run, the free disk, the perplexity delta the
// build reports - is on screen before the button becomes pressable.
//
// The one thing it refuses to be quiet about: most local GGUFs are already
// quantised, and re-quantising one loses quality twice. That warning is the
// reason the confirmation exists at all.

import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/api_service.dart';
import '../../core/app_strings.dart';
import '../../core/design_tokens.dart';
import './engine_api.dart';
import './models.dart';
import './widgets.dart' show formatBytes;

/// Opens the dialog for one source model. Returns the operation id of a started
/// conversion, or null when the user closed it without starting one.
Future<String?> showQuantizeDialog(
  BuildContext context, {
  required ModelRecord model,
  EngineApi? api,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _QuantizeDialog(model: model, api: api),
  );
}

class _QuantizeDialog extends StatefulWidget {
  const _QuantizeDialog({required this.model, this.api});

  final ModelRecord model;
  final EngineApi? api;

  @override
  State<_QuantizeDialog> createState() => _QuantizeDialogState();
}

class _QuantizeDialogState extends State<_QuantizeDialog> {
  late final EngineApi _api = widget.api ?? ApiService();
  final _targetNameController = TextEditingController();

  List<QuantizationType> _types = const [];
  String _unavailableReason = '';
  bool _loadingTypes = true;

  String _targetType = '';
  bool _allowRequantize = false;
  bool _leaveOutputTensor = false;

  QuantizationPreflight? _preflight;
  bool _checking = false;
  String _error = '';
  bool _starting = false;

  /// Guards against an older preflight landing after a newer one. The dry run
  /// is fast but not instant, and clicking through formats otherwise leaves the
  /// figures describing a format that is no longer selected.
  int _preflightToken = 0;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadTypes();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _targetNameController.dispose();
    super.dispose();
  }

  Future<void> _loadTypes() async {
    try {
      final catalog = await _api.getQuantizationTypes();
      if (!mounted) return;
      // An alias is the same format under a second name; offering both looks
      // like two choices that do different things.
      final usable = catalog.types.where((type) => !type.isAlias).toList();
      setState(() {
        _types = usable;
        _unavailableReason = catalog.unavailableReason;
        _loadingTypes = false;
        if (catalog.available && usable.isNotEmpty) {
          _targetType = _defaultTarget(usable);
        }
      });
      if (_targetType.isNotEmpty) _schedulePreflight();
    } on EngineApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingTypes = false;
        _unavailableReason = error.message;
      });
    }
  }

  /// Q4_K_M is where most people land: it is the smallest format that still
  /// reads as the same model, so it is the useful thing to have preselected.
  String _defaultTarget(List<QuantizationType> types) {
    for (final preferred in const ['Q4_K_M', 'Q4_K_S', 'Q5_K_M']) {
      for (final type in types) {
        if (type.name == preferred) return type.name;
      }
    }
    return types.first.name;
  }

  QuantizationJob get _job => QuantizationJob(
    sourceModelId: widget.model.id,
    targetType: _targetType,
    targetName: _targetNameController.text.trim(),
    allowRequantize: _allowRequantize,
    leaveOutputTensor: _leaveOutputTensor,
  );

  void _schedulePreflight() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), _runPreflight);
  }

  Future<void> _runPreflight() async {
    if (_targetType.isEmpty) return;
    final token = ++_preflightToken;
    setState(() {
      _checking = true;
      _error = '';
    });
    try {
      final report = await _api.preflightQuantization(_job);
      if (!mounted || token != _preflightToken) return;
      setState(() {
        _preflight = report;
        _checking = false;
      });
    } on EngineApiException catch (error) {
      if (!mounted || token != _preflightToken) return;
      setState(() {
        _preflight = null;
        _checking = false;
        _error = error.message;
      });
    }
  }

  Future<void> _start() async {
    setState(() {
      _starting = true;
      _error = '';
    });
    try {
      final started = await _api.startQuantization(_job);
      if (!mounted) return;
      Navigator.of(context).pop(started.operationId);
    } on EngineApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _starting = false;
        _error = error.message;
      });
    }
  }

  bool get _canStart {
    final report = _preflight;
    return report != null && report.feasible && !_checking && !_starting;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: CulpeoColors.panel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CulpeoLayout.cardRadius),
      ),
      title: Text(
        tr('engineQuantize.title'),
        style: TextStyle(color: CulpeoColors.textPrimary),
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(child: _content()),
      ),
      actions: [
        TextButton(
          onPressed: _starting ? null : () => Navigator.of(context).pop(),
          child: Text(tr('engineQuantize.cancel')),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: CulpeoColors.action),
          onPressed: _canStart ? _start : null,
          child: Text(
            _starting
                ? tr('engineQuantize.starting')
                : tr('engineQuantize.start'),
          ),
        ),
      ],
    );
  }

  Widget _content() {
    if (_loadingTypes) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_types.isEmpty) {
      return _notice(
        _unavailableReason.isEmpty
            ? tr('engineQuantize.unavailable')
            : _unavailableReason,
        CulpeoColors.warning,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _sourceSummary(),
        const SizedBox(height: 16),
        _targetPicker(),
        const SizedBox(height: 12),
        TextField(
          controller: _targetNameController,
          style: TextStyle(color: CulpeoColors.textPrimary),
          decoration: InputDecoration(
            labelText: tr('engineQuantize.targetName'),
            hintText: _preflight?.targetName ?? '',
            labelStyle: TextStyle(color: CulpeoColors.textSecondary),
            helperText: tr('engineQuantize.targetNameHelp'),
            helperStyle: TextStyle(color: CulpeoColors.textMuted, fontSize: 12),
          ),
          onChanged: (_) => _schedulePreflight(),
        ),
        const SizedBox(height: 8),
        if (_preflight != null) ...[
          _tradeSummary(_preflight!),
          const SizedBox(height: 12),
        ],
        if (_checking)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 10),
                Text(
                  tr('engineQuantize.checking'),
                  style: TextStyle(color: CulpeoColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
        ..._messages(),
        _advanced(),
        if (_error.isNotEmpty) ...[
          const SizedBox(height: 12),
          _notice(_error, CulpeoColors.danger),
        ],
      ],
    );
  }

  Widget _sourceSummary() {
    final model = widget.model;
    final quantization = model.quantization.trim();
    return Container(
      padding: const EdgeInsets.all(CulpeoLayout.cardPadding),
      decoration: BoxDecoration(
        color: CulpeoColors.inset,
        borderRadius: BorderRadius.circular(CulpeoLayout.pillRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            model.name,
            style: TextStyle(
              color: CulpeoColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            [
              if (quantization.isNotEmpty) quantization,
              formatBytes(model.sizeBytes),
            ].join(' · '),
            // A reading, not an action.
            style: TextStyle(color: CulpeoColors.metricSoft, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _targetPicker() {
    return DropdownButtonFormField<String>(
      initialValue: _targetType.isEmpty ? null : _targetType,
      dropdownColor: CulpeoColors.panel,
      isExpanded: true,
      style: TextStyle(color: CulpeoColors.textPrimary),
      decoration: InputDecoration(
        labelText: tr('engineQuantize.targetFormat'),
        labelStyle: TextStyle(color: CulpeoColors.textSecondary),
      ),
      items: [
        for (final type in _types)
          DropdownMenuItem(
            value: type.name,
            child: Text(_typeLabel(type), overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (value) {
        if (value == null) return;
        setState(() => _targetType = value);
        _schedulePreflight();
      },
    );
  }

  /// The label carries the build's own figures, because "Q3_K_M" alone tells
  /// nobody what it costs.
  String _typeLabel(QuantizationType type) {
    if (type.perplexityDelta != 0) {
      return '${type.name} · ${tr('engineQuantize.pplDelta', {'delta': type.perplexityDelta.toStringAsFixed(4)})}';
    }
    if (type.bitsPerWeight > 0) {
      return '${type.name} · ${tr('engineQuantize.bpw', {'bits': type.bitsPerWeight.toStringAsFixed(2)})}';
    }
    return type.name;
  }

  /// The size trade, which is the reason anybody opened this dialog.
  Widget _tradeSummary(QuantizationPreflight report) {
    final saved = report.savedFraction;
    return Container(
      padding: const EdgeInsets.all(CulpeoLayout.cardPadding),
      decoration: BoxDecoration(
        color: CulpeoColors.inset,
        borderRadius: BorderRadius.circular(CulpeoLayout.pillRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _reading(
                  tr('engineQuantize.currentSize'),
                  formatBytes(report.sourceBytes),
                ),
              ),
              Icon(
                Icons.arrow_forward,
                size: 16,
                color: CulpeoColors.textFaint,
              ),
              Expanded(
                child: _reading(
                  tr('engineQuantize.resultSize'),
                  formatBytes(report.estimatedBytes),
                ),
              ),
            ],
          ),
          if (saved > 0) ...[
            const SizedBox(height: 10),
            Text(
              tr('engineQuantize.saves', {
                'percent': (saved * 100).round().toString(),
                'size': formatBytes(report.sourceBytes - report.estimatedBytes),
              }),
              style: TextStyle(color: CulpeoColors.metricBright, fontSize: 12),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            tr('engineQuantize.diskFree', {
              'free': formatBytes(report.freeDiskBytes),
              'needed': formatBytes(report.requiredDiskBytes),
            }),
            style: TextStyle(color: CulpeoColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _reading(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: CulpeoColors.textFaint, fontSize: 11),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: CulpeoColors.metricSoft,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  List<Widget> _messages() {
    final report = _preflight;
    if (report == null) return const [];
    final widgets = <Widget>[];

    // The requantisation opt-in is a blocker until it is ticked, so it is shown
    // as the switch that clears it rather than as a message to read past.
    if (report.isRequantization) {
      widgets.add(
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text(
            tr('engineQuantize.allowRequantize'),
            style: TextStyle(color: CulpeoColors.textPrimary, fontSize: 14),
          ),
          subtitle: Text(
            tr('engineQuantize.allowRequantizeHelp'),
            style: TextStyle(color: CulpeoColors.warning, fontSize: 12),
          ),
          value: _allowRequantize,
          onChanged: (value) {
            setState(() => _allowRequantize = value);
            _schedulePreflight();
          },
        ),
      );
    }
    for (final warning in report.warnings) {
      if (report.isRequantization && warning.contains('bereits quantisiert')) {
        // Already said by the switch above.
        continue;
      }
      widgets.add(_notice(warning, CulpeoColors.warning));
    }
    for (final blocker in report.blockers) {
      widgets.add(_notice(blocker, CulpeoColors.danger));
    }
    return widgets;
  }

  Widget _advanced() {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        title: Text(
          tr('engineQuantize.advanced'),
          style: TextStyle(color: CulpeoColors.textSecondary, fontSize: 13),
        ),
        children: [
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text(
              tr('engineQuantize.leaveOutputTensor'),
              style: TextStyle(color: CulpeoColors.textPrimary, fontSize: 14),
            ),
            subtitle: Text(
              tr('engineQuantize.leaveOutputTensorHelp'),
              style: TextStyle(color: CulpeoColors.textMuted, fontSize: 12),
            ),
            value: _leaveOutputTensor,
            onChanged: (value) {
              setState(() => _leaveOutputTensor = value);
              _schedulePreflight();
            },
          ),
        ],
      ),
    );
  }

  Widget _notice(String message, Color color) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(CulpeoLayout.pillRadius),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(message, style: TextStyle(color: color, fontSize: 12)),
    );
  }
}
