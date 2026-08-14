import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/api_service.dart';
import '../../core/app_strings.dart';
import '../../core/design_tokens.dart';
import '../settings/settings_widgets.dart';
import './node_api.dart';
import './node_add_dialog.dart';
import './node_format.dart';

/// The nodes section of the settings screen: which machines this Studio may
/// use, whether each is reachable, and the tunnel to it.
///
/// It is deliberately the only place a node is managed. Downloads and models
/// show which node they belong to but never let one be added or removed, so
/// there is one screen that answers "what is connected".
class NodesScreen extends StatefulWidget {
  const NodesScreen({super.key});

  @override
  State<NodesScreen> createState() => _NodesScreenState();
}

class _NodesScreenState extends State<NodesScreen> {
  final ApiService _api = ApiService();

  List<StudioNode> _nodes = [];
  bool _isLoading = true;
  String _error = '';
  final Set<String> _busyNodes = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final nodes = await _api.nodes.listNodes();
      if (!mounted) return;
      setState(() {
        _nodes = nodes;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error is ApiException ? error.message : error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshAll() async {
    setState(() => _isLoading = true);
    try {
      final nodes = await _api.nodes.refreshNodes();
      if (!mounted) return;
      setState(() {
        _nodes = nodes;
        _isLoading = false;
      });
      _notify(tr('nodes.notification.refreshed'));
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _notify(_messageOf(error), isError: true);
    }
  }

  Future<void> _refreshOne(StudioNode node) async {
    setState(() => _busyNodes.add(node.id));
    try {
      final refreshed = await _api.nodes.refreshNodes(nodeId: node.id);
      if (!mounted) return;
      setState(() {
        for (final updated in refreshed) {
          _replace(updated);
        }
      });
    } catch (error) {
      if (!mounted) return;
      _notify(_messageOf(error), isError: true);
    } finally {
      if (mounted) setState(() => _busyNodes.remove(node.id));
    }
  }

  void _replace(StudioNode node) {
    final index = _nodes.indexWhere((candidate) => candidate.id == node.id);
    if (index >= 0) {
      _nodes[index] = node;
    } else {
      _nodes = [..._nodes, node];
    }
  }

  Future<void> _add() async {
    final result = await showNodeAddDialog(context);
    if (result == null || !mounted) return;
    setState(() => _replace(result.node));
    _notify(tr('nodes.notification.added', {'name': result.node.name}));
    if (result.nextSteps.isNotEmpty) {
      await _showNextSteps(result.nextSteps);
    }
  }

  Future<void> _showNextSteps(List<String> steps) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: SettingsPalette.surfaceRaised,
        title: Text(
          tr('nodes.add.nextSteps'),
          style: const TextStyle(color: SettingsPalette.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final step in steps)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SelectableText(
                  step,
                  style: const TextStyle(
                    color: SettingsPalette.textSecondary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(tr('nodes.action.close')),
          ),
        ],
      ),
    );
  }

  Future<void> _setEnabled(StudioNode node, bool enabled) async {
    setState(() => _busyNodes.add(node.id));
    try {
      final updated = await _api.nodes.updateNode(node.id, enabled: enabled);
      if (!mounted) return;
      setState(() => _replace(updated));
    } catch (error) {
      if (!mounted) return;
      _notify(_messageOf(error), isError: true);
    } finally {
      if (mounted) setState(() => _busyNodes.remove(node.id));
    }
  }

  Future<void> _rename(StudioNode node) async {
    final controller = TextEditingController(text: node.name);
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: SettingsPalette.surfaceRaised,
        title: Text(
          tr('nodes.rename.title'),
          style: const TextStyle(color: SettingsPalette.textPrimary),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: SettingsPalette.textPrimary),
          decoration: nodeInputDecoration(tr('nodes.add.nameHint')),
          onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(tr('nodes.action.cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: Text(tr('nodes.action.rename')),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.trim().isEmpty || !mounted) return;
    try {
      final updated = await _api.nodes.updateNode(node.id, name: name);
      if (!mounted) return;
      setState(() => _replace(updated));
    } catch (error) {
      if (!mounted) return;
      _notify(_messageOf(error), isError: true);
    }
  }

  Future<void> _remove(StudioNode node) async {
    var deleteConfig = node.tunnel.isManaged;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (builderContext, setDialogState) => AlertDialog(
          backgroundColor: SettingsPalette.surfaceRaised,
          title: Text(
            tr('nodes.remove.title'),
            style: const TextStyle(color: SettingsPalette.textPrimary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr('nodes.remove.body', {'name': node.name}),
                style: const TextStyle(
                  color: SettingsPalette.textSecondary,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              if (node.tunnel.isManaged) ...[
                const SizedBox(height: 12),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: deleteConfig,
                  onChanged: (value) =>
                      setDialogState(() => deleteConfig = value ?? false),
                  title: Text(
                    tr('nodes.remove.deleteConfig'),
                    style: const TextStyle(
                      color: SettingsPalette.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(tr('nodes.action.cancel')),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: SettingsPalette.danger,
              ),
              child: Text(tr('nodes.remove.confirm')),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _api.nodes.removeNode(node.id, deleteTunnelConfig: deleteConfig);
      if (!mounted) return;
      setState(() => _nodes.removeWhere((candidate) => candidate.id == node.id));
      _notify(tr('nodes.notification.removed', {'name': node.name}));
    } catch (error) {
      if (!mounted) return;
      _notify(_messageOf(error), isError: true);
    }
  }

  Future<void> _setTunnel(StudioNode node, {required bool up}) async {
    setState(() => _busyNodes.add(node.id));
    try {
      await _api.nodes.setTunnel(node.id, up: up);
      final refreshed = await _api.nodes.refreshNodes(nodeId: node.id);
      if (!mounted) return;
      setState(() {
        for (final updated in refreshed) {
          _replace(updated);
        }
      });
      _notify(
        tr(
          up ? 'nodes.notification.tunnelUp' : 'nodes.notification.tunnelDown',
          {'name': node.name},
        ),
      );
    } catch (error) {
      if (!mounted) return;
      // A system with no privilege helper answers with the command to run by
      // hand, which is worth more room than a snackbar gives it.
      _notify(_messageOf(error), isError: true, long: true);
    } finally {
      if (mounted) setState(() => _busyNodes.remove(node.id));
    }
  }

  Future<void> _showTunnelConfig(StudioNode node) async {
    try {
      final detail = await _api.nodes.getTunnel(node.id);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: SettingsPalette.surfaceRaised,
          title: Text(
            tr('nodes.tunnel.configTitle'),
            style: const TextStyle(color: SettingsPalette.textPrimary),
          ),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('nodes.tunnel.configHint', {
                    'path': detail.tunnel.configPath,
                  }),
                  style: const TextStyle(
                    color: SettingsPalette.textFaint,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: SettingsPalette.surfaceInput,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: SettingsPalette.hairline),
                  ),
                  child: SelectableText(
                    detail.configText,
                    style: const TextStyle(
                      color: SettingsPalette.textSecondary,
                      fontFamily: 'monospace',
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await Clipboard.setData(
                  ClipboardData(text: detail.configText),
                );
                if (!dialogContext.mounted) return;
                Navigator.of(dialogContext).pop();
                _notify(tr('nodes.notification.copied'));
              },
              child: Text(tr('nodes.action.copy')),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(tr('nodes.action.close')),
            ),
          ],
        ),
      );
    } catch (error) {
      if (!mounted) return;
      _notify(_messageOf(error), isError: true);
    }
  }

  String _messageOf(Object error) =>
      error is ApiException ? error.message : error.toString();

  void _notify(String message, {bool isError = false, bool long = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? SettingsPalette.danger
            : SettingsPalette.surfaceRaised,
        duration: Duration(seconds: long ? 12 : 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          if (_isLoading && _nodes.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error.isNotEmpty)
            _buildError()
          else if (_nodes.isEmpty)
            _buildEmpty()
          else
            for (final node in _nodes)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildNodeCard(node),
              ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: SettingsPalette.surfaceRaised,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: SettingsPalette.hairlineSoft),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('nodes.title'),
                  style: const TextStyle(
                    color: SettingsPalette.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  tr('nodes.subtitle'),
                  style: const TextStyle(
                    color: SettingsPalette.textFaint,
                    fontSize: 12,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              FilledButton.icon(
                onPressed: _add,
                icon: const Icon(Icons.add, size: 18),
                label: Text(tr('nodes.action.add')),
                style: FilledButton.styleFrom(
                  backgroundColor: CulpeoColors.action,
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _isLoading ? null : _refreshAll,
                icon: const Icon(Icons.refresh, size: 16),
                label: Text(tr('nodes.action.refreshAll')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: SettingsPalette.surfaceRaised,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: SettingsPalette.danger.withValues(alpha: 0.4),
        ),
      ),
      child: Text(
        _error,
        style: const TextStyle(color: SettingsPalette.danger, fontSize: 13),
      ),
    );
  }

  Widget _buildEmpty() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: SettingsPalette.surfaceRaised,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: SettingsPalette.hairlineSoft),
      ),
      child: Column(
        children: [
          Icon(
            Icons.hub_outlined,
            size: 40,
            color: SettingsPalette.textVeryFaint,
          ),
          const SizedBox(height: 16),
          Text(
            tr('nodes.empty.title'),
            style: const TextStyle(
              color: SettingsPalette.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            tr('nodes.empty.body'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: SettingsPalette.textFaint,
              fontSize: 12,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNodeCard(StudioNode node) {
    final busy = _busyNodes.contains(node.id);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: SettingsPalette.surfaceRaised,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: node.isUsable
              ? CulpeoColors.action.withValues(alpha: 0.35)
              : SettingsPalette.hairlineSoft,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              nodeStateDot(node.state),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      node.name,
                      style: const TextStyle(
                        color: SettingsPalette.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${nodeStateLabel(node.state)} · ${node.address}',
                      style: const TextStyle(
                        color: SettingsPalette.textFaint,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (busy)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else ...[
                IconButton(
                  tooltip: tr('nodes.action.refresh'),
                  onPressed: () => _refreshOne(node),
                  icon: const Icon(Icons.refresh, size: 18),
                  color: SettingsPalette.textMuted,
                ),
                IconButton(
                  tooltip: tr('nodes.action.rename'),
                  onPressed: () => _rename(node),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  color: SettingsPalette.textMuted,
                ),
                IconButton(
                  tooltip: tr('nodes.action.remove'),
                  onPressed: () => _remove(node),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  color: SettingsPalette.textMuted,
                ),
              ],
            ],
          ),
          if (node.statusMessage.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: SettingsPalette.noteBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: SettingsPalette.noteBorder),
              ),
              child: Text(
                node.statusMessage,
                style: const TextStyle(
                  color: SettingsPalette.accentSoft,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 24,
            runSpacing: 10,
            children: [
              nodeFact(tr('nodes.detail.models'), '${node.modelCount}'),
              nodeFact(tr('nodes.detail.instances'), '${node.instanceCount}'),
              if (node.diskFreeBytes > 0)
                nodeFact(
                  tr('nodes.detail.diskFree'),
                  formatNodeBytes(node.diskFreeBytes),
                ),
              if (node.gpuName.isNotEmpty)
                nodeFact(tr('nodes.detail.hardware'), nodeHardwareLabel(node)),
              if (node.version.isNotEmpty)
                nodeFact(tr('nodes.detail.version'), node.version),
              if (node.lastSeenAt != null)
                nodeFact(
                  tr('nodes.detail.lastSeen'),
                  formatNodeTimestamp(node.lastSeenAt!),
                ),
            ],
          ),
          if (node.modelDir.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              '${tr('nodes.detail.modelDir')}: ${node.modelDir}',
              style: const TextStyle(
                color: SettingsPalette.textVeryFaint,
                fontSize: 11,
              ),
            ),
          ],
          const Divider(color: SettingsPalette.dividerLine, height: 32),
          _buildTunnelRow(node, busy),
          const SizedBox(height: 8),
          Row(
            children: [
              Switch(
                value: node.enabled,
                onChanged: busy
                    ? null
                    : (value) => _setEnabled(node, value),
                activeThumbColor: CulpeoColors.action,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tr('nodes.detail.enabledHint'),
                  style: const TextStyle(
                    color: SettingsPalette.textVeryFaint,
                    fontSize: 11,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTunnelRow(StudioNode node, bool busy) {
    final tunnel = node.tunnel;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.vpn_key_outlined,
                    size: 14,
                    color: SettingsPalette.textFaint,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${tr('nodes.tunnel.title')}: ${tunnelStateLabel(tunnel.state, tunnel.isManaged)}',
                    style: TextStyle(
                      color: tunnel.state == NodeTunnelState.up
                          ? CulpeoColors.success
                          : SettingsPalette.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (tunnel.interfaceName.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  '${tunnel.interfaceName} · ${tunnel.localAddress} → ${tunnel.endpoint}',
                  style: const TextStyle(
                    color: SettingsPalette.textVeryFaint,
                    fontSize: 11,
                  ),
                ),
              ],
              if (tunnel.lastHandshakeAt != null) ...[
                const SizedBox(height: 2),
                Text(
                  '${tr('nodes.tunnel.lastHandshake')}: ${formatNodeTimestamp(tunnel.lastHandshakeAt!)}',
                  style: const TextStyle(
                    color: SettingsPalette.textVeryFaint,
                    fontSize: 11,
                  ),
                ),
              ],
              if (tunnel.statusMessage.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  tunnel.statusMessage,
                  style: const TextStyle(
                    color: SettingsPalette.textFaint,
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (tunnel.isManaged) ...[
          TextButton(
            onPressed: () => _showTunnelConfig(node),
            child: Text(tr('nodes.action.showConfig')),
          ),
          const SizedBox(width: 4),
          if (tunnel.state == NodeTunnelState.up)
            OutlinedButton(
              onPressed: busy ? null : () => _setTunnel(node, up: false),
              child: Text(tr('nodes.action.tunnelDown')),
            )
          else
            FilledButton(
              onPressed: busy ? null : () => _setTunnel(node, up: true),
              style: FilledButton.styleFrom(
                backgroundColor: CulpeoColors.action,
              ),
              child: Text(tr('nodes.action.tunnelUp')),
            ),
        ],
      ],
    );
  }
}
