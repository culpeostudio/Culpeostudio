import 'package:flutter/material.dart';

import '../../core/api_service.dart';
import '../../core/app_strings.dart';
import '../../core/design_tokens.dart';
import '../settings/settings_widgets.dart';
import './node_api.dart';
import './node_format.dart';

/// Asks for a node and registers it.
///
/// A standalone Node prints one direct, TLS-pinned connection link. Pasting
/// that link is the whole normal interaction; Studio never asks a user to
/// transcribe addresses, ports, tokens, or tunnel settings.
Future<NodeAddResult?> showNodeAddDialog(BuildContext context) {
  return showDialog<NodeAddResult>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => const _NodeAddDialog(),
  );
}

class _NodeAddDialog extends StatefulWidget {
  const _NodeAddDialog();

  @override
  State<_NodeAddDialog> createState() => _NodeAddDialogState();
}

class _NodeAddDialogState extends State<_NodeAddDialog> {
  final ApiService _api = ApiService();

  final _joinCodeController = TextEditingController();
  final _nameController = TextEditingController();

  bool _submitting = false;
  String _error = '';

  @override
  void dispose() {
    _joinCodeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = '';
    });
    try {
      final result = await _api.nodes.addNodeFromJoinCode(
        _joinCodeController.text,
        name: _nameController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop(result);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error is ApiException ? error.message : error.toString();
        _submitting = false;
      });
    }
  }

  bool get _canSubmit {
    return !_submitting && _joinCodeController.text.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: SettingsPalette.surfaceRaised,
      title: Text(
        tr('nodes.add.title'),
        style: const TextStyle(color: SettingsPalette.textPrimary),
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ..._joinCodeFields(),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                style: const TextStyle(color: SettingsPalette.textPrimary),
                decoration: nodeInputDecoration(tr('nodes.add.nameHint')),
                onChanged: (_) => setState(() {}),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  tr('nodes.add.nameLabel'),
                  style: const TextStyle(
                    color: SettingsPalette.textVeryFaint,
                    fontSize: 11,
                  ),
                ),
              ),
              if (_error.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: SettingsPalette.danger.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: SettingsPalette.danger.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    _error,
                    style: const TextStyle(
                      color: SettingsPalette.danger,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: Text(tr('nodes.action.cancel')),
        ),
        FilledButton(
          onPressed: _canSubmit ? _submit : null,
          style: FilledButton.styleFrom(backgroundColor: CulpeoColors.action),
          child: _submitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(tr('nodes.add.submit')),
        ),
      ],
    );
  }

  List<Widget> _joinCodeFields() {
    return [
      Text(
        tr('nodes.add.joinCodeLabel'),
        style: const TextStyle(
          color: SettingsPalette.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 8),
      TextField(
        controller: _joinCodeController,
        autofocus: true,
        maxLines: 4,
        minLines: 3,
        style: const TextStyle(
          color: SettingsPalette.textPrimary,
          fontFamily: 'monospace',
          fontSize: 12,
        ),
        decoration: nodeInputDecoration(
          tr('nodes.add.joinCodeHint'),
          helper: tr('nodes.add.joinCodeDescription'),
        ),
        onChanged: (_) => setState(() {}),
      ),
    ];
  }
}
