# PhiloEngine Quick Install und automatische Updates

`quikinstall/` ist die Veröffentlichungsseite des automatischen Updaters. Ein
Benutzer installiert nur einmal das passende `quickinstall`-Archiv. Danach
startet er immer `myphiloengine` (unter Windows `myphiloengine.exe`); der
Launcher prüft `manifest.json`, verifiziert Größe und SHA-256, installiert eine
neue Version atomar und startet Backend und Flutter-Frontend.

Automatisch gebaut werden `linux-x64`, `windows-x64` und `macos-arm64`. Ein
Flutter-Desktop-Bundle lässt sich nicht plattformübergreifend bauen — Windows
braucht Visual Studio auf Windows, macOS braucht Xcode auf macOS. Deshalb baut
[`.github/workflows/release.yml`](../.github/workflows/release.yml) jede
Plattform auf einem nativen Runner und führt die Ergebnisse zusammen. Lokal
lässt sich immer nur die eigene Plattform bauen.

`macos-x64` unterstützt das Build-Skript weiterhin, wird aber nicht automatisch
gebaut: Der `macos-13`-Runner, der ein Intel-Bundle erzeugen könnte, ist bei
GitHub ausgemustert. Wer Intel-Macs bedienen will, baut das Archiv auf einem
solchen Rechner und reicht es manuell nach (siehe „Veröffentlichen").

## Verzeichnis- und Archivlayout

```text
quikinstall/
├── manifest.json          ← versioniert; einziges Artefakt im Repository
├── build_release.py       ← baut eine Plattform
├── merge_manifests.py     ← führt die Plattform-Manifeste zusammen
├── releases/              ← gitignoriert, siehe unten
│   └── 1.2.3/
│       ├── myphiloengine-1.2.3-linux-x64.tar.gz
│       ├── myphiloengine-1.2.3-linux-x64-quickinstall.tar.gz
│       └── current-linux-x64.json
└── tests/
```

`releases/` steht in `.gitignore`. Ein Release wiegt rund 60 MB pro Plattform;
im Repository abgelegt bliebe dieses Gewicht dauerhaft in der Git-Historie und
ließe sich nur per History-Rewrite wieder entfernen. Die Archive werden
stattdessen als GitHub-Release-Assets veröffentlicht.

Das Update-Archiv hat keinen zusätzlichen Top-Level-Ordner:

```text
launcher/myphiloengine
backend/philoengine-server
backend/engineworker/transformers_worker.py
backend/tools/philoengine_hardware_probe.py
backend/requirements-hardware.txt
frontend/myphilostudio
frontend/data/...
frontend/lib/...
LICENSE
NOTICE
THIRD_PARTY_NOTICES.md
licenses/whichllm-MIT.txt
```

Das Erstinstallationsarchiv enthält denselben Payload in einem
versionsgebundenen Ordner:

```text
myphiloengine
current.json
LICENSE
NOTICE
THIRD_PARTY_NOTICES.md
licenses/whichllm-MIT.txt
versions/1.2.3-<erste-12-Zeichen-der-Update-SHA>/
├── .philoengine-bundle.json
├── backend/...
├── frontend/...
├── LICENSE
├── NOTICE
├── THIRD_PARTY_NOTICES.md
├── licenses/whichllm-MIT.txt
└── launcher/myphiloengine
```

Unter Windows enden Launcher, Backend und Frontend auf `.exe`; Windows-Archive
verwenden ZIP. macOS enthält das Flutter-`.app`-Bundle. `current.json` besitzt
diese Statusfelder:

```json
{
  "schema_version": 1,
  "version": "1.2.3",
  "bundle": "versions/1.2.3-0123456789ab",
  "asset_sha256": "<SHA-256 des Update-Archivs>",
  "updated_at": "2026-07-26T12:00:00Z"
}
```

`.philoengine-bundle.json` enthält dieselben Statusfelder und zusätzlich
`"asset"` mit dem vollständigen plattformspezifischen Assetobjekt aus dem
Manifest. Dadurch kann eine bereits installierte Version auch offline gestartet
werden. Die SHA bezieht sich bewusst auf das Update-Archiv. Das Metadatum wird
erst in das Erstinstallationsarchiv aufgenommen und erzeugt deshalb keine
selbstreferenzielle Prüfsumme.

## Zustand im Installationsordner

Neben `current.json` verwaltet der Launcher zwei weitere Dateien selbst; beide
gehören nicht in ein Release-Archiv:

- `quarantine.json` listet Versionen, die sich zwar installieren ließen, aber
  nicht starteten. Nach einem Rollback wird der Eintrag geschrieben, damit
  dieselbe Version nicht bei jedem Start erneut heruntergeladen wird. Ein
  Eintrag ist an Version **und** Asset-Prüfsumme gebunden: Ein neu gebautes
  Archiv derselben Versionsnummer wird also wieder angeboten. Zum manuellen
  Zurücksetzen genügt es, die Datei zu löschen.
- `.philoengine.lock` verhindert, dass zwei Instanzen gleichzeitig laufen oder
  aktualisieren.

Bei jedem Start behält der Launcher unter `versions/` nur die aktive Version und
das Rollback-Ziel; alle älteren Bundles werden entfernt. Abgebrochene Updates
hinterlassen `.staging-*`- und `.update-work-*`-Ordner, die nach 24 Stunden
aufgeräumt werden — die Wartezeit stellt sicher, dass kein laufendes Update
gelöscht wird.

## Release bauen

Voraussetzungen für einen vollständigen Build sind Go, Flutter und die nativen
Flutter-Desktop-Abhängigkeiten. Vom Repository-Root:

```bash
python3 quikinstall/build_release.py --version 1.2.3
```

Das Skript erkennt die aktuelle Plattform. Es verwendet vorhandene
Release-Artefakte nur, wenn sie ausdrücklich als Pfad übergeben werden. Der
normale Aufruf baut Backend, Launcher und Frontend stets frisch, damit kein
alter lokaler Build versehentlich als neue Version veröffentlicht wird:

- Backend: `go build ./cmd/server`
- Launcher: `go build ./cmd/philo-updater`
- Frontend: `flutter build <plattform> --release`

Zusätzlich nimmt der Builder `backend/engineworker/transformers_worker.py`,
`backend/tools/philoengine_hardware_probe.py` und
`backend/requirements-hardware.txt` als benötigte Backend-Laufzeitdateien auf.
`LICENSE`, `NOTICE`, `THIRD_PARTY_NOTICES.md` und die vollständige
WhichLLM-MIT-Lizenz werden mit jedem Update-Bundle sowie im Wurzelverzeichnis
des Erstinstallationsarchivs ausgeliefert. README, Tests und Python-Bytecode
aus den Quellordnern werden nicht mitgeliefert.
Der Launcher wird pro Zielplattform genau einmal aufgelöst oder gebaut. Dieselbe
Binärdatei liegt im Update-Payload unter `launcher/`, im versionierten Bundle
und als direkt startbarer Root-Launcher des Erstinstallationsarchivs. Dadurch
kann ein normales Update auch den Launcher selbst atomar erneuern.

Explizite, bereits kompilierte Artefakte lassen sich übergeben:

```bash
python3 quikinstall/build_release.py \
  --version 1.2.3 \
  --target linux-x64 \
  --backend-artifact /pfad/philoengine-server \
  --frontend-artifact /pfad/flutter-release-bundle \
  --launcher-artifact /pfad/myphiloengine \
  --no-build-missing
```

Mit `--no-build-missing` können alternativ bereits vorhandene Artefakte aus den
dokumentierten Projekt-Buildverzeichnissen verwendet werden. Für einen
regulären Release ist der frische Standard-Build empfohlen.

Für `windows-x64`, `macos-x64` und `macos-arm64` wird derselbe Befehl auf einem
passenden nativen Build-Rechner ausgeführt. Go kann zwar Zielwerte setzen, ein
Flutter-Desktop-Bundle sollte aber nicht betriebssystemübergreifend gebaut
werden. Mehrere Zielplattformen derselben Version ergänzen die vorhandenen
Assets im Manifest. Beim Wechsel auf eine neue Version entfernt das Skript
automatisch alte Asset-Einträge.

Archive werden nicht ohne `--force` überschrieben. Ein bereits veröffentlichtes
Release darf niemals überschrieben werden; stattdessen wird die Versionsnummer
erhöht.

## Veröffentlichen

Der Regelweg ist ein Tag. Damit baut der Workflow alle vier Plattformen auf
nativen Runnern, lädt die Archive als Release-Assets hoch, prüft jede
Asset-URL und veröffentlicht **erst danach** das zusammengeführte Manifest:

```bash
git tag v1.2.3
git push origin v1.2.3
```

Die Reihenfolge ist der Kern: Wird das Manifest veröffentlicht, bevor die Assets
erreichbar sind, laufen alle Clients auf 404. Der Workflow erzwingt das über
einen `curl`-Schritt zwischen Upload und Manifest-Commit. Ohne Tag lässt sich
derselbe Ablauf über *Actions → Release → Run workflow* mit expliziter Version
auslösen.

Manuell — etwa um eine einzelne Plattform nachzureichen:

```bash
# 1. bauen
python3 quikinstall/build_release.py \
  --version 1.2.3 \
  --base-url 'https://github.com/kuchenboss/MyPhiloEngine/releases/download/v{version}'

# 2. Archive prüfen: SHA-256, Größe, Layout, Start aus frischem Verzeichnis
# 3. Assets an den bestehenden Release hängen
gh release upload v1.2.3 quikinstall/releases/1.2.3/*.tar.gz

# 4. Erreichbarkeit bestätigen, dann erst das Manifest ergänzen
curl -fsSLI https://github.com/kuchenboss/MyPhiloEngine/releases/download/v1.2.3/<datei> >/dev/null
python3 quikinstall/merge_manifests.py \
  quikinstall/manifest.json quikinstall/releases/1.2.3/manifest.json \
  --output quikinstall/manifest.json
# committen und pushen
```

Veröffentlichte Dateien niemals überschreiben; für Änderungen immer eine neue
Version bauen. Der Tag `v1.2.3` bleibt unveränderlich.

> **Nach jedem Release:** Der Workflow committet `quikinstall/manifest.json`
> selbst nach `main`. Wer aus einer Arbeitskopie heraus veröffentlicht, muss
> diesen Commit erst zurückholen — sonst überschreibt der nächste Upload das
> Manifest mit dem älteren lokalen Stand und alle Clients sehen wieder „kein
> Build verfügbar":
>
> ```bash
> git fetch origin main
> git checkout origin/main -- quikinstall/manifest.json
> ```

Der Launcher lädt das Manifest weiterhin aus dem Repository
(`raw.githubusercontent.com/.../quikinstall/manifest.json`) — nur die Archive
liegen bei den Release Assets. Die Origin-Policy des Updaters vertraut sowohl
`raw.githubusercontent.com` als auch `github.com` und den Asset-Hosts
`objects.githubusercontent.com` und `release-assets.githubusercontent.com`, auf
die GitHub-Release-Downloads umleiten.

Das Manifest veröffentlicht immer nur die aktuelle Version und folgt Schema 1:

```json
{
  "schema_version": 1,
  "version": "1.2.3",
  "published_at": "2026-07-26T12:00:00Z",
  "assets": {
    "linux-x64": {
      "url": "https://raw.githubusercontent.com/kuchenboss/MyPhiloEngine/main/quikinstall/releases/1.2.3/myphiloengine-1.2.3-linux-x64.tar.gz",
      "sha256": "<64 hex-Zeichen>",
      "size": 123,
      "format": "tar.gz",
      "launcher": {
        "path": "launcher/myphiloengine",
        "args": []
      },
      "backend": {
        "path": "backend/philoengine-server",
        "args": []
      },
      "frontend": {
        "path": "frontend/myphilostudio",
        "args": []
      },
      "health_url": "http://127.0.0.1:8080/health"
    }
  }
}
```

Vor dem Merge:

```bash
python3 -m unittest discover -s quikinstall/tests -v
python3 -m py_compile quikinstall/build_release.py
```
