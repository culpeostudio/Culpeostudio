import 'package:flutter/material.dart';

import '../../core/api_service.dart';
import '../../core/app_strings.dart';
import '../../core/design_tokens.dart';
import '../settings/settings_widgets.dart';
import './node_api.dart';
import './node_format.dart';

/// Asks for a node and registers it.
///
/// The join code is the ordinary way in: the node printed one, it carries the
/// token and the finished tunnel config, and pasting it is the whole
/// interaction. The manual form is for an operator who runs their own tunnel
/// and only needs the Studio to know where to send things.
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
  final _addressController = TextEditingController();
  final _tokenController = TextEditingController();
  final _grpcPortController = TextEditingController(text: '50051');
  final _gatewayPortController = TextEditingController(text: '8091');

  bool _manual = false;
  bool _submitting = false;
  String _error = '';

  @override
  void dispose() {
    _joinCodeController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _tokenController.dispose();
    _grpcPortController.dispose();
    _gatewayPortController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = '';
    });
    try {
      final result = _manual
          ? await _api.nodes.addNodeManually(
              name: _nameController.text,
              address: _addressController.text,
              token: _tokenController.text,
              grpcPort: int.tryParse(_grpcPortController.text.trim()) ?? 50051,
              gatewayPort:
                  int.tryParse(_gatewayPortController.text.trim()) ?? 8091,
            )
          : await _api.nodes.addNodeFromJoinCode(
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
    if (_submitting) return false;
    if (_manual) {
      return _addressController.text.trim().isNotEmpty &&
          _tokenController.text.trim().isNotEmpty;
    }
    return _joinCodeController.text.trim().isNotEmpty;
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
              if (_manual) ..._manualFields() else ..._joinCodeFields(),
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
              const SizedBox(height: 8),
              TextButton(
                onPressed: _submitting
                    ? null
                    : () => setState(() => _manual = !_manual),
                child: Text(
                  _manual
                      ? tr('nodes.add.joinToggle')
                      : tr('nodes.add.manualToggle'),
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

  List<Widget> _manualFields() {
    return [
      Text(
        tr('nodes.add.addressLabel'),
        style: const TextStyle(
          color: SettingsPalette.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 8),
      TextField(
        controller: _addressController,
        autofocus: true,
        style: const TextStyle(color: SettingsPalette.textPrimary),
        decoration: nodeInputDecoration(tr('nodes.add.addressHint')),
        onChanged: (_) => setState(() {}),
      ),
      const SizedBox(height: 16),
      Text(
        tr('nodes.add.tokenLabel'),
        style: const TextStyle(
          color: SettingsPalette.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 8),
      TextField(
        controller: _tokenController,
        style: const TextStyle(
          color: SettingsPalette.textPrimary,
          fontFamily: 'monospace',
          fontSize: 12,
        ),
        decoration: nodeInputDecoration(''),
        onChanged: (_) => setState(() {}),
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: TextField(
              controller: _grpcPortController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: SettingsPalette.textPrimary),
              decoration: nodeInputDecoration(
                '50051',
                helper: tr('nodes.add.grpcPortLabel'),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _gatewayPortController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: SettingsPalette.textPrimary),
              decoration: nodeInputDecoration(
                '8091',
                helper: tr('nodes.add.gatewayPortLabel'),
              ),
            ),
          ),
        ],
      ),
    ];
  }
}
