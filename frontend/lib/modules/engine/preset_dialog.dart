// The saved engine configurations.
//
// A preset is an EngineConfig under a name. This dialog is where they are
// applied, saved, removed and moved between machines; applying one hands the
// config back to the caller, which writes it into the form rather than starting
// anything, so the user still sees what they are about to run.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/api_service.dart';
import '../../core/design_tokens.dart';
import './engine_api.dart';
import './engine_screen_strings.dart';
import './models.dart';

/// Opens the preset manager. Returns the preset the user chose to apply, or
/// null if they closed it without applying one.
Future<EnginePreset?> showEnginePresetDialog(
  BuildContext context, {
  required EngineConfig currentConfig,
  String modelId = '',
  EngineApi? api,
}) {
  return showDialog<EnginePreset>(
    context: context,
    builder: (context) =>
        _PresetDialog(currentConfig: currentConfig, modelId: modelId, api: api),
  );
}

class _PresetDialog extends StatefulWidget {
  const _PresetDialog({
    required this.currentConfig,
    required this.modelId,
    this.api,
  });

  final EngineConfig currentConfig;
  final String modelId;
  final EngineApi? api;

  @override
  State<_PresetDialog> createState() => _PresetDialogState();
}

class _PresetDialogState extends State<_PresetDialog> {
  late final EngineApi _api = widget.api ?? ApiService();
  final _nameController = TextEditingController();

  List<EnginePreset> _presets = const [];
  bool _loading = true;
  bool _busy = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final presets = await _api.getEnginePresets();
      if (!mounted) return;
      setState(() {
        _presets = presets;
        _loading = false;
      });
    } on EngineApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.message;
      });
    }
  }

  /// Runs one mutation, keeping the list and the error line in step. Every
  /// button goes through this so a failure never leaves the dialog showing a
  /// stale list as if the change had worked.
  Future<void> _mutate(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = '';
    });
    try {
      await action();
      final presets = await _api.getEnginePresets();
      if (!mounted) return;
      setState(() {
        _presets = presets;
        _busy = false;
      });
    } on EngineApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = error.message;
      });
    }
  }

  Future<void> _saveCurrent() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = tr('engineScreen.preset.nameRequired'));
      return;
    }
    await _mutate(() async {
      await _api.saveEnginePreset(
        name: name,
        config: widget.currentConfig,
        modelId: widget.modelId,
      );
      _nameController.clear();
    });
  }

  Future<void> _export() async {
    await _mutate(() async {
      final exported = await _api.exportEnginePresets();
      // There is no file picker in this dialog, so the document goes to the
      // clipboard: it is plain JSON, and pasting it into a file is something
      // the user can do wherever they actually want it.
      await Clipboard.setData(ClipboardData(text: exported.document));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('engineScreen.preset.exported'))),
      );
    });
  }

  Future<void> _import() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final document = data?.text?.trim() ?? '';
    if (document.isEmpty) {
      setState(() => _error = tr('engineScreen.preset.importEmpty'));
      return;
    }
    await _mutate(() => _api.importEnginePresets(document));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: CulpeoColors.panel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CulpeoLayout.cardRadius),
      ),
      title: Text(
        tr('engineScreen.preset.title'),
        style: TextStyle(color: CulpeoColors.textPrimary),
      ),
      content: SizedBox(
        width: 520,
        child: _loading
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            : SingleChildScrollView(child: _content()),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: Text(tr('engineScreen.action.cancel')),
        ),
      ],
    );
  }

  Widget _content() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final preset in _presets) _presetRow(preset),
        const SizedBox(height: 16),
        Divider(color: CulpeoColors.hairline),
        const SizedBox(height: 8),
        Text(
          tr('engineScreen.preset.saveCurrent'),
          style: TextStyle(
            color: CulpeoColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                key: const Key('engine-preset-name'),
                controller: _nameController,
                style: TextStyle(color: CulpeoColors.textPrimary),
                decoration: InputDecoration(
                  hintText: tr('engineScreen.preset.namePlaceholder'),
                  hintStyle: TextStyle(color: CulpeoColors.textFaint),
                ),
                onSubmitted: (_) => _saveCurrent(),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              key: const Key('engine-preset-save'),
              style: FilledButton.styleFrom(
                backgroundColor: CulpeoColors.action,
              ),
              onPressed: _busy ? null : _saveCurrent,
              child: Text(tr('engineScreen.preset.save')),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            TextButton.icon(
              onPressed: _busy ? null : _export,
              icon: const Icon(Icons.upload_outlined, size: 16),
              label: Text(tr('engineScreen.preset.export')),
            ),
            TextButton.icon(
              onPressed: _busy ? null : _import,
              icon: const Icon(Icons.download_outlined, size: 16),
              label: Text(tr('engineScreen.preset.import')),
            ),
          ],
        ),
        if (_error.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: CulpeoColors.danger.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(CulpeoLayout.pillRadius),
              border: Border.all(
                color: CulpeoColors.danger.withValues(alpha: 0.35),
              ),
            ),
            child: Text(
              _error,
              style: TextStyle(color: CulpeoColors.danger, fontSize: 12),
            ),
          ),
        ],
      ],
    );
  }

  Widget _presetRow(EnginePreset preset) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(CulpeoLayout.cardPadding),
      decoration: BoxDecoration(
        color: CulpeoColors.inset,
        borderRadius: BorderRadius.circular(CulpeoLayout.pillRadius),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        preset.name,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: CulpeoColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (preset.builtIn) ...[
                      const SizedBox(width: 8),
                      Text(
                        tr('engineScreen.preset.builtIn'),
                        style: TextStyle(
                          color: CulpeoColors.textFaint,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
                if (preset.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    preset.description,
                    style: TextStyle(
                      color: CulpeoColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            key: Key('engine-preset-apply-${preset.id}'),
            onPressed: _busy ? null : () => Navigator.of(context).pop(preset),
            child: Text(tr('engineScreen.preset.apply')),
          ),
          // A built-in is what a broken preset is recovered from, so it has no
          // delete button at all rather than one that fails.
          if (!preset.builtIn)
            IconButton(
              key: Key('engine-preset-delete-${preset.id}'),
              onPressed: _busy
                  ? null
                  : () => _mutate(() => _api.deleteEnginePreset(preset.id)),
              icon: const Icon(Icons.delete_outline, size: 17),
              color: CulpeoColors.textFaint,
              tooltip: tr('engineScreen.preset.delete'),
            ),
        ],
      ),
    );
  }
}
