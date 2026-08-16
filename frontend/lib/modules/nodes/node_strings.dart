/// The strings of the node screen, kept beside it the way the engine keeps its
/// own. They are merged into AppStrings, so `tr('nodes.…')` reaches them.
const Map<String, String> nodeStringsDe = {
  'settings.nav.nodes': 'Nodes',

  'nodes.title': 'Nodes',
  'nodes.subtitle':
      'Andere Rechner, auf denen dieses Studio Modelle laden und starten darf. '
      'Ein Modell wird direkt auf dem Ziel-Node heruntergeladen und dort ausgefuehrt.',
  'nodes.empty.title': 'Noch kein Node verbunden',
  'nodes.empty.body':
      'Installiere und starte Culpeo Node auf dem anderen Rechner. Fuehre dort '
      '`culpeo-node pairing-link` aus und fuege den einen Verbindungslink hier ein.',

  'nodes.action.add': 'Node hinzufuegen',
  'nodes.action.refresh': 'Aktualisieren',
  'nodes.action.refreshAll': 'Alle pruefen',
  'nodes.action.remove': 'Entfernen',
  'nodes.action.rename': 'Umbenennen',
  'nodes.action.tunnelUp': 'Tunnel starten',
  'nodes.action.tunnelDown': 'Tunnel stoppen',
  'nodes.action.showConfig': 'Konfiguration anzeigen',
  'nodes.action.copy': 'Kopieren',
  'nodes.action.close': 'Schliessen',
  'nodes.action.cancel': 'Abbrechen',

  'nodes.state.online': 'Erreichbar',
  'nodes.state.offline': 'Nicht erreichbar',
  'nodes.state.unauthorized': 'Token abgelehnt',
  'nodes.state.disabled': 'Deaktiviert',
  'nodes.state.unknown': 'Unbekannt',

  'nodes.tunnel.title': 'Tunnel',
  'nodes.tunnel.up': 'Steht',
  'nodes.tunnel.down': 'Gestoppt',
  'nodes.tunnel.unavailable': 'WireGuard fehlt',
  'nodes.tunnel.unknown': 'Extern verwaltet',
  'nodes.tunnel.interface': 'Interface',
  'nodes.tunnel.localAddress': 'Adresse im Tunnel',
  'nodes.tunnel.endpoint': 'Endpunkt',
  'nodes.tunnel.lastHandshake': 'Letzter Handshake',
  'nodes.tunnel.configTitle': 'WireGuard-Konfiguration',
  'nodes.tunnel.configHint':
      'Diese Datei enthaelt einen privaten Schluessel. Sie liegt unter {path}.',
  'nodes.tunnel.needsRoot':
      'Das Interface braucht Administratorrechte. Bitte einmal im Terminal ausfuehren:',

  'nodes.detail.address': 'Adresse',
  'nodes.detail.models': 'Modelle',
  'nodes.detail.instances': 'Instanzen',
  'nodes.detail.diskFree': 'Frei',
  'nodes.detail.modelDir': 'Modellordner',
  'nodes.detail.version': 'Version',
  'nodes.detail.lastSeen': 'Zuletzt gesehen',
  'nodes.detail.hardware': 'Hardware',
  'nodes.detail.enabled': 'Aktiv',
  'nodes.detail.enabledHint':
      'Ein deaktivierter Node taucht in keiner Liste auf und bekommt keine Auftraege.',

  'nodes.add.title': 'Node hinzufuegen',
  'nodes.add.joinCodeLabel': 'Node-Verbindungslink',
  'nodes.add.joinCodeHint': 'culpeo-node://pair/…',
  'nodes.add.joinCodeDescription':
      'Auf dem Node `culpeo-node pairing-link` ausfuehren und die gesamte Zeile '
      'hier einfuegen. Der Link ist ein Zugangsschluessel – bitte vertraulich behandeln.',
  'nodes.add.nameLabel': 'Name (optional)',
  'nodes.add.nameHint': 'Werkstatt-PC',
  'nodes.add.manualToggle': 'Tunnel steht schon? Manuell eintragen',
  'nodes.add.joinToggle': 'Doch lieber den Join-Code verwenden',
  'nodes.add.addressLabel': 'Adresse im Tunnel',
  'nodes.add.addressHint': '10.77.0.1',
  'nodes.add.tokenLabel': 'Pairing-Token',
  'nodes.add.grpcPortLabel': 'gRPC-Port',
  'nodes.add.gatewayPortLabel': 'Gateway-Port',
  'nodes.add.submit': 'Hinzufuegen',
  'nodes.add.nextSteps': 'Naechste Schritte',

  'nodes.remove.title': 'Node entfernen',
  'nodes.remove.body':
      '{name} wird aus diesem Studio entfernt. Modelle und Instanzen auf dem '
      'Node bleiben, wo sie sind.',
  'nodes.remove.deleteConfig': 'Tunnel-Konfiguration mit loeschen',
  'nodes.remove.confirm': 'Entfernen',

  'nodes.rename.title': 'Node umbenennen',

  'nodes.notification.added': '{name} wurde hinzugefuegt.',
  'nodes.notification.removed': '{name} wurde entfernt.',
  'nodes.notification.refreshed': 'Nodes aktualisiert.',
  'nodes.notification.tunnelUp': 'Tunnel zu {name} steht.',
  'nodes.notification.tunnelDown': 'Tunnel zu {name} wurde gestoppt.',
  'nodes.notification.copied': 'In die Zwischenablage kopiert.',

  // Where a download goes, and where a model already lives.
  'nodes.target.title': 'Wohin herunterladen?',
  'nodes.target.local': 'Dieser Rechner',
  'nodes.target.localDetail': 'Standard',
  'nodes.target.unavailable': 'nicht erreichbar',
  'nodes.target.free': '{size} frei',
  'nodes.badge.local': 'Lokal',
};

const Map<String, String> nodeStringsEn = {
  'settings.nav.nodes': 'Nodes',

  'nodes.title': 'Nodes',
  'nodes.subtitle':
      'Other machines this Studio may download to and run models on. A model '
      'is downloaded directly onto and run by its target node.',
  'nodes.empty.title': 'No node connected yet',
  'nodes.empty.body':
      'Install and start Culpeo Node on the other machine. Run '
      '`culpeo-node pairing-link` there, then paste the single connection link here.',

  'nodes.action.add': 'Add node',
  'nodes.action.refresh': 'Refresh',
  'nodes.action.refreshAll': 'Check all',
  'nodes.action.remove': 'Remove',
  'nodes.action.rename': 'Rename',
  'nodes.action.tunnelUp': 'Bring tunnel up',
  'nodes.action.tunnelDown': 'Bring tunnel down',
  'nodes.action.showConfig': 'Show configuration',
  'nodes.action.copy': 'Copy',
  'nodes.action.close': 'Close',
  'nodes.action.cancel': 'Cancel',

  'nodes.state.online': 'Reachable',
  'nodes.state.offline': 'Not reachable',
  'nodes.state.unauthorized': 'Token rejected',
  'nodes.state.disabled': 'Switched off',
  'nodes.state.unknown': 'Unknown',

  'nodes.tunnel.title': 'Tunnel',
  'nodes.tunnel.up': 'Up',
  'nodes.tunnel.down': 'Down',
  'nodes.tunnel.unavailable': 'WireGuard missing',
  'nodes.tunnel.unknown': 'Managed elsewhere',
  'nodes.tunnel.interface': 'Interface',
  'nodes.tunnel.localAddress': 'Address in the tunnel',
  'nodes.tunnel.endpoint': 'Endpoint',
  'nodes.tunnel.lastHandshake': 'Last handshake',
  'nodes.tunnel.configTitle': 'WireGuard configuration',
  'nodes.tunnel.configHint':
      'This file holds a private key. It lives at {path}.',
  'nodes.tunnel.needsRoot':
      'The interface needs administrator rights. Run this once in a terminal:',

  'nodes.detail.address': 'Address',
  'nodes.detail.models': 'Models',
  'nodes.detail.instances': 'Instances',
  'nodes.detail.diskFree': 'Free',
  'nodes.detail.modelDir': 'Model directory',
  'nodes.detail.version': 'Version',
  'nodes.detail.lastSeen': 'Last seen',
  'nodes.detail.hardware': 'Hardware',
  'nodes.detail.enabled': 'Active',
  'nodes.detail.enabledHint':
      'A node that is switched off appears in no list and is given no work.',

  'nodes.add.title': 'Add node',
  'nodes.add.joinCodeLabel': 'Node connection link',
  'nodes.add.joinCodeHint': 'culpeo-node://pair/…',
  'nodes.add.joinCodeDescription':
      'Run `culpeo-node pairing-link` on the node and paste the complete line '
      'here. The link is an access credential; keep it private.',
  'nodes.add.nameLabel': 'Name (optional)',
  'nodes.add.nameHint': 'Workshop PC',
  'nodes.add.manualToggle': 'Tunnel already up? Enter it by hand',
  'nodes.add.joinToggle': 'Use the join code after all',
  'nodes.add.addressLabel': 'Address in the tunnel',
  'nodes.add.addressHint': '10.77.0.1',
  'nodes.add.tokenLabel': 'Pairing token',
  'nodes.add.grpcPortLabel': 'gRPC port',
  'nodes.add.gatewayPortLabel': 'Gateway port',
  'nodes.add.submit': 'Add',
  'nodes.add.nextSteps': 'Next steps',

  'nodes.remove.title': 'Remove node',
  'nodes.remove.body':
      '{name} is removed from this Studio. Models and instances on the node '
      'stay where they are.',
  'nodes.remove.deleteConfig': 'Delete the tunnel configuration too',
  'nodes.remove.confirm': 'Remove',

  'nodes.rename.title': 'Rename node',

  'nodes.notification.added': '{name} was added.',
  'nodes.notification.removed': '{name} was removed.',
  'nodes.notification.refreshed': 'Nodes refreshed.',
  'nodes.notification.tunnelUp': 'The tunnel to {name} is up.',
  'nodes.notification.tunnelDown': 'The tunnel to {name} was brought down.',
  'nodes.notification.copied': 'Copied to the clipboard.',

  'nodes.target.title': 'Download to which machine?',
  'nodes.target.local': 'This machine',
  'nodes.target.localDetail': 'Default',
  'nodes.target.unavailable': 'not reachable',
  'nodes.target.free': '{size} free',
  'nodes.badge.local': 'Local',
};
