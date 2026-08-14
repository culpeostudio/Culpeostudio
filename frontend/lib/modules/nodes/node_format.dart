import 'package:flutter/material.dart';

import '../../core/app_strings.dart';
import '../../core/design_tokens.dart';
import '../settings/settings_widgets.dart';
import './node_api.dart';

/// The small shared pieces the node screen and the download target picker both
/// render: a state dot, the labels behind the enums, and the two number
/// formats. They live here so a node reads the same wherever it appears.

String nodeStateLabel(NodeState state) {
  switch (state) {
    case NodeState.online:
      return tr('nodes.state.online');
    case NodeState.offline:
      return tr('nodes.state.offline');
    case NodeState.unauthorized:
      return tr('nodes.state.unauthorized');
    case NodeState.disabled:
      return tr('nodes.state.disabled');
    case NodeState.unknown:
      return tr('nodes.state.unknown');
  }
}

Color nodeStateColor(NodeState state) {
  switch (state) {
    case NodeState.online:
      return CulpeoColors.success;
    case NodeState.unauthorized:
      return CulpeoColors.danger;
    case NodeState.offline:
      return CulpeoColors.warning;
    case NodeState.disabled:
    case NodeState.unknown:
      return SettingsPalette.textVeryFaint;
  }
}

/// tunnelStateLabel takes whether the Studio manages the tunnel, because
/// "down" and "somebody else's business" look the same from here otherwise.
String tunnelStateLabel(NodeTunnelState state, bool isManaged) {
  if (!isManaged) return tr('nodes.tunnel.unknown');
  switch (state) {
    case NodeTunnelState.up:
      return tr('nodes.tunnel.up');
    case NodeTunnelState.down:
      return tr('nodes.tunnel.down');
    case NodeTunnelState.unavailable:
      return tr('nodes.tunnel.unavailable');
    case NodeTunnelState.unknown:
      return tr('nodes.tunnel.unknown');
  }
}

Widget nodeStateDot(NodeState state) {
  final color = nodeStateColor(state);
  return Container(
    width: 10,
    height: 10,
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      boxShadow: state == NodeState.online
          ? [
              BoxShadow(
                color: color.withValues(alpha: 0.5),
                blurRadius: 8,
              ),
            ]
          : null,
    ),
  );
}

/// One reading with its label. Gold is the measurement colour, which is what
/// every one of these is.
Widget nodeFact(String label, String value) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: SettingsPalette.textVeryFaint,
          fontSize: 9,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 2),
      Text(
        value,
        style: const TextStyle(
          color: CulpeoColors.metricSoft,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}

String nodeHardwareLabel(StudioNode node) {
  final parts = <String>[];
  if (node.gpuName.trim().isNotEmpty) parts.add(node.gpuName.trim());
  if (node.vramGb > 0) parts.add('${node.vramGb} GB VRAM');
  if (parts.isEmpty && node.ramGb > 0) parts.add('${node.ramGb} GB RAM');
  return parts.join(' · ');
}

String formatNodeBytes(int bytes) {
  if (bytes <= 0) return '–';
  const gigabyte = 1024 * 1024 * 1024;
  if (bytes >= gigabyte) {
    return '${(bytes / gigabyte).toStringAsFixed(1)} GB';
  }
  return '${(bytes / (1024 * 1024)).toStringAsFixed(0)} MB';
}

String formatNodeTimestamp(DateTime value) {
  String two(int number) => number.toString().padLeft(2, '0');
  return '${two(value.day)}.${two(value.month)}. ${two(value.hour)}:${two(value.minute)}';
}

InputDecoration nodeInputDecoration(String hint, {String? helper}) {
  return InputDecoration(
    hintText: hint,
    helperText: helper,
    helperMaxLines: 3,
    hintStyle: const TextStyle(color: SettingsPalette.textHint),
    helperStyle: const TextStyle(
      color: SettingsPalette.textVeryFaint,
      fontSize: 11,
      height: 1.5,
    ),
    filled: true,
    fillColor: SettingsPalette.dialogInputFill,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: SettingsPalette.hairline),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: SettingsPalette.hairline),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: CulpeoColors.action),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  );
}
