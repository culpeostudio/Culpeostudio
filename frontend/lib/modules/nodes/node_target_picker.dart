import 'package:flutter/material.dart';

import '../../core/app_strings.dart';
import '../../core/design_tokens.dart';
import '../settings/settings_widgets.dart';
import './node_api.dart';
import './node_format.dart';

/// Which machine a download goes to. An empty id means this one.
class NodeDownloadTarget {
  final String nodeId;
  final String name;

  const NodeDownloadTarget({required this.nodeId, required this.name});

  bool get isLocal => nodeId.isEmpty;
}

/// Asks where a model should be downloaded.
///
/// It is only shown when there is something to choose: with no usable node the
/// answer is always this machine, and a sheet that offers one option is a
/// step, not a choice.
Future<NodeDownloadTarget?> showNodeTargetPicker(
  BuildContext context,
  List<StudioNode> nodes,
) {
  return showModalBottomSheet<NodeDownloadTarget>(
    context: context,
    backgroundColor: CulpeoColors.panel,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                tr('nodes.target.title'),
                style: const TextStyle(
                  color: SettingsPalette.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(
                Icons.computer_outlined,
                color: CulpeoColors.action,
              ),
              title: Text(
                tr('nodes.target.local'),
                style: const TextStyle(
                  color: SettingsPalette.textPrimary,
                  fontSize: 14,
                ),
              ),
              subtitle: Text(
                tr('nodes.target.localDetail'),
                style: const TextStyle(
                  color: SettingsPalette.textFaint,
                  fontSize: 12,
                ),
              ),
              onTap: () => Navigator.of(sheetContext).pop(
                NodeDownloadTarget(nodeId: '', name: tr('nodes.target.local')),
              ),
            ),
            for (final node in nodes)
              ListTile(
                enabled: node.isUsable,
                leading: nodeStateDot(node.state),
                title: Text(
                  node.name,
                  style: TextStyle(
                    color: node.isUsable
                        ? SettingsPalette.textPrimary
                        : SettingsPalette.textFaint,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  _nodeSubtitle(node),
                  style: const TextStyle(
                    color: SettingsPalette.textFaint,
                    fontSize: 12,
                  ),
                ),
                onTap: node.isUsable
                    ? () => Navigator.of(sheetContext).pop(
                        NodeDownloadTarget(nodeId: node.id, name: node.name),
                      )
                    : null,
              ),
          ],
        ),
      ),
    ),
  );
}

String _nodeSubtitle(StudioNode node) {
  if (!node.isUsable) {
    return '${nodeStateLabel(node.state)} · ${tr('nodes.target.unavailable')}';
  }
  final parts = <String>[];
  if (node.diskFreeBytes > 0) {
    parts.add(
      tr('nodes.target.free', {'size': formatNodeBytes(node.diskFreeBytes)}),
    );
  }
  final hardware = nodeHardwareLabel(node);
  if (hardware.isNotEmpty) parts.add(hardware);
  return parts.join(' · ');
}
