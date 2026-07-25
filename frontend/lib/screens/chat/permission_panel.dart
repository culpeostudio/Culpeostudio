import 'package:flutter/material.dart';

/// Nachfrage-Panel, wenn ein Projekt-Tool auf etwas ausserhalb des
/// Projekt-Ordners zugreifen will. Der Chat haelt die Anfrage-Daten und
/// beantwortet die Entscheidung ueber [onRespond] ('deny'/'once'/'session').
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
        color: const Color(0xFFC9A24A).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFC9A24A).withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.privacy_tip_outlined,
                color: Color(0xFFDFC077),
                size: 16,
              ),
              SizedBox(width: 8),
              Text(
                'Zugriffsanfrage',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'PhiloBot möchte außerhalb des Projektpfads arbeiten '
            '(${_permissionToolLabel(tool)}):',
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
                child: const Text('Ablehnen'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () => onRespond('once'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFC9A24A),
                  side: BorderSide(
                    color: const Color(0xFFC9A24A).withValues(alpha: 0.5),
                  ),
                ),
                child: const Text('Einmal erlauben'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => onRespond('session'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC9A24A),
                ),
                child: const Text('Für Sitzung erlauben'),
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
      return 'Datei lesen';
    case 'write_file':
      return 'Datei schreiben';
    case 'patch_file':
      return 'Datei ändern';
    case 'delete_path':
      return 'Löschen (rekursiv)';
    case 'list_dir':
      return 'Ordner auflisten';
    case 'make_dir':
      return 'Ordner erstellen';
    case 'move_path':
      return 'Verschieben/Umbenennen';
    case 'stat_path':
      return 'Datei-Info lesen';
    case 'grep_search':
      return 'Projekt durchsuchen';
    case 'find_files':
      return 'Dateien suchen';
    case 'run_command':
      return 'Befehl ausführen';
    default:
      return tool;
  }
}
