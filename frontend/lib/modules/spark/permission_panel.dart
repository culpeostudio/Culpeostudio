import 'package:flutter/material.dart';

import '../../core/design_tokens.dart';

import '../scout/chat_aux_strings.dart';

class PermissionPanel extends StatelessWidget {
  const PermissionPanel({
    super.key,
    required this.pending,
    required this.onRespond,
  });

  final Map<String, dynamic> pending;
  final void Function(String decision) onRespond;

  @override
  Widget build(BuildContext context) {
    final pending = this.pending;
    final tool = pending['tool']?.toString() ?? '';
    final path = pending['path']?.toString() ?? '';
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CulpeoColors.metric.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CulpeoColors.metric.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.privacy_tip_outlined,
                color: CulpeoColors.metricBright,
                size: 16,
              ),
              SizedBox(width: 8),
              Text(
                tr('chatAux.permission.title'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            tr('chatAux.permission.body', {'tool': _permissionToolLabel(tool)}),
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            path,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => onRespond('deny'),
                child: Text(tr('chat.planApproval.reject')),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () => onRespond('once'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: CulpeoColors.metric,
                  side: BorderSide(
                    color: CulpeoColors.metric.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(tr('chatAux.permission.allowOnce')),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => onRespond('session'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CulpeoColors.metric,
                ),
                child: Text(tr('chatAux.permission.allowSession')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _permissionToolLabel(String tool) {
  switch (tool) {
    case 'read_file':
      return tr('chatAux.permission.tool.readFile');
    case 'write_file':
      return tr('chatAux.permission.tool.writeFile');
    case 'patch_file':
      return tr('chatAux.permission.tool.patchFile');
    case 'delete_path':
      return tr('chatAux.permission.tool.deletePath');
    case 'list_dir':
      return tr('chatAux.permission.tool.listDir');
    case 'make_dir':
      return tr('chatAux.permission.tool.makeDir');
    case 'move_path':
      return tr('chatAux.permission.tool.movePath');
    case 'stat_path':
      return tr('chatAux.permission.tool.statPath');
    case 'grep_search':
      return tr('chatAux.permission.tool.grepSearch');
    case 'find_files':
      return tr('chatAux.permission.tool.findFiles');
    case 'run_command':
      return tr('chatAux.permission.tool.runCommand');
    default:
      return tool;
  }
}
