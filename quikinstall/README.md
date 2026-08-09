# Culpeo Studio Quick Install und automatische Updates

`quikinstall/` ist das Veröffentlichungssystem des automatischen Updaters. Ein Benutzer installiert einmalig das passende `quickinstall`-Archiv. Danach startet er immer `culpeostudio` (unter Windows `culpeostudio.exe`).

Der Launcher verifiziert `manifest.json`, prüft Größe und SHA-256 des Pakets, installiert neue Versionen atomar und startet den Go gRPC-Backend-Server sowie das Flutter-Frontend.

## Verzeichnislayout

```text
quikinstall/
├── manifest.json          ← versioniertes Veröffentlichungsmanifest
├── build_release.py       ← baut ein Plattform-Release
├── merge_manifests.py     ← führt Plattform-Manifeste zusammen
└── releases/              ← Ausgabeverzeichnis für Build-Artefakte
```

## Release bauen

```bash
python3 quikinstall/build_release.py --version 1.2.0
```

Unterstützte Zielplattformen: `linux-x64`, `windows-x64` und `macos-arm64`.
