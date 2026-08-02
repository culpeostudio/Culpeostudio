# PhiloEngine entwickeln

**Deutsch** · [English](../../docs/DEVELOPMENT.md)

PhiloEngine verbindet einen Flutter-Desktop-Client, eine Go-Steuerungsebene
und Python-Worker, die für ausgewählte Funktionen lokaler Modelle und Hardware
eingesetzt werden. Dieser Leitfaden beschreibt den lokalen Entwicklungsablauf,
nicht die kompilierte Installation für Endnutzer.

[← README](../README.md) · [Installation](INSTALLATION.md) · [Mitwirken](../CONTRIBUTING.md)

## Entwicklungswerkzeuge

| Werkzeug | Aktuelle Projektbasis | Verwendet für |
|---|---:|---|
| Go | 1.25+ | Backend, Launcher, Laufzeitüberwachung |
| Flutter | 3.44+ | Desktop-Frontend |
| Dart | 3.12+ | Frontend-Sprache und -Werkzeuge |
| Python | 3.12 empfohlen | Entwicklerkonsole, Worker, Hardware-Erkennung, Release-Skripte |
| Git | Aktuell unterstützte Version | Quellcodeablauf und sichere Quellcode-Updates |

Installiere die nativen Voraussetzungen für Flutter Desktop für dein
Betriebssystem wie in der Flutter-Dokumentation beschrieben. Lokale
llama.cpp-Builds können zusätzlich CMake sowie C- und C++-Compiler erfordern.
Für beschleunigerspezifische Arbeit werden der passende GPU-Treiber und das
zugehörige SDK beziehungsweise die entsprechende Toolchain benötigt.

## Übersicht des Repositorys

```text
backend/
  cmd/server/             Einstiegspunkt des Go-Servers
  cmd/philo-updater/      Updater für Quellcode und kompilierte Bundles
  cmd/philosearch/        Kommandozeilen-Client für die Metasuche
  modules/                Funktionsmodule und HTTP-Routen
  internal/               gemeinsamer Code für Laufzeit, Memory, Sicherheit und Updates
  engineworker/           Transformers-Worker und Python-Tests
  sidecar/                nur im Quellcode vorhandener ONNX-Memory-Embedding-Dienst
  tools/                  Hardware-Prüfung und Werkzeuge zur Datenpflege
  proto/                  Protokolldefinitionen und generierter Go-Code
frontend/
  lib/screens/            nach Funktion gruppierte Produktansichten
  lib/services/           Backend-Client und Transportverarbeitung
  lib/state/              Anwendungszustand
  lib/l10n/               deutsche und englische UI-Texte
  lib/theme/              gemeinsames visuelles System
  test/                   Flutter-Widget- und Unit-Tests
  integration_test/       Desktop-Integrationstests
quikinstall/
  build_release.py        Erstellung plattformspezifischer Releases
  merge_manifests.py      Zusammenführung der Release-Manifeste
  manifest.json           veröffentlichtes Update-Manifest
  tests/                  Tests der Release-Werkzeuge
docs/
  screenshots/            öffentliche Produktabbildungen
```

Laufzeitstatus, Zugangsdaten, Modelle, Chats und Memory-Daten liegen bei einem
normalen Start aus dem Quellcode unter `backend/data/`. Quickinstall bewahrt
dauerhafte Daten stattdessen unter `<Installationsordner>/backend/data/`
außerhalb seiner versionierten Anwendungs-Bundles auf. Diese Verzeichnisse sind
kein Quellcode. Das `backend/data/` des Repositorys wird von Git ignoriert;
kopiere keines der Datenverzeichnisse in Fixtures, Commits, Issue-Berichte oder
Screenshots.

## Anwendung starten

### Empfohlener überwachter Start

Richte unter Linux die Entwicklungskonsole einmalig ein:

```bash
cd /pfad/zu/philoengine
python3 -m venv backend/.venv
backend/.venv/bin/python -m pip install textual
./start.sh
```

`start.sh` öffnet die Entwicklungskonsole und verwaltet Backend und Frontend in
der vorgesehenen Reihenfolge. Verwende während der Arbeit auf einem Branch
`PHILOENGINE_SKIP_UPDATE=1 ./start.sh`, um eine unnötige Updateprüfung zu
vermeiden. Der Updater lehnt Worktrees mit Änderungen und andere Branches als
`main` ohnehin ab.
Die Entwicklungskonsole startet derzeit `flutter run -d linux`; verwende für
Windows, macOS oder ein anderes Flutter-Ziel die manuellen Befehle unten.

### Manueller Start der einzelnen Ebenen

Starte das Backend für eine gezielte Diagnose aus `backend/`:

```bash
cd backend
go run ./cmd/server
```

Der voreingestellte HTTP-Endpunkt ist `http://127.0.0.1:8080`. Ein paralleler
gRPC-Listener verwendet denselben Loopback-Host; der größte Teil des
Anwendungsverkehrs läuft über HTTP und SSE.

Starte das Frontend in einem weiteren Terminal:

```bash
cd frontend
flutter pub get
flutter run -d linux
```

Verwende auf den entsprechenden Desktop-Systemen `windows` oder `macos` statt
`linux`.

### Optionaler ONNX-Memory-Sidecar

Der ONNX-Embedding-Sidecar ist eine manuelle Komponente, die nur im Quellcode
vorliegt. Er wird weder von `start.sh` gestartet noch im Quickinstall-Paket
mitgeliefert. Erstelle für die Entwicklung eine eigene Umgebung,
installiere seine Abhängigkeiten und lade das Modell von Hugging Face herunter:

```bash
cd /pfad/zu/philoengine/backend/sidecar
python3 -m venv .venv
.venv/bin/python -m pip install -r requirements.txt
.venv/bin/python download_model.py
.venv/bin/python main.py
```

Der Dienst bindet sich an `127.0.0.1:8092`. Starte die Hauptanwendung in einem
anderen Terminal mit `MEMORY_EMBEDDING_BACKEND=onnx_local ./start.sh`. Fehlt der
Sidecar oder ist er nicht funktionsfähig, fällt Memory bewusst auf
deterministische Hash-Embeddings zurück.

## Änderungen überprüfen

Führe Prüfungen aus, die den von dir geänderten Code abdecken. Die folgenden
Befehle sind die lokalen Projektprüfungen; gehe nicht davon aus, dass ein hier
nicht aufgeführter gehosteter CI-Job sie für dich ausführt.

### Go-Backend

```bash
cd backend
go test ./...
go build ./cmd/server
go build ./cmd/philo-updater
```

Formatiere geänderte Go-Dateien vor dem Testen mit `gofmt`.

### Flutter-Frontend

```bash
cd frontend
flutter analyze
flutter test
```

Führe die Desktop-Integrationstests auf einem Host mit funktionsfähigem
Flutter-Desktop-Ziel und grafischer Sitzung aus:

```bash
cd frontend
flutter test integration_test/ -d linux
```

Ersetze das Desktop-Ziel gegebenenfalls durch das lokale Ziel. Formatiere
geänderte Dart-Dateien vor der Analyse mit `dart format`.

### Python-Worker und Release-Werkzeuge

```bash
python3 -m unittest discover -s backend/engineworker -p 'test_*.py' -v
python3 -m unittest discover -s quikinstall/tests -v
python3 -m py_compile \
  backend/engineworker/transformers_worker.py \
  backend/tools/philoengine_hardware_probe.py \
  quikinstall/build_release.py \
  quikinstall/merge_manifests.py
```

Führe diese Befehle aus dem Stammverzeichnis des Repositorys aus.

### Reine Dokumentationsänderungen

Prüfe lokale Links, Überschriftenreihenfolge, Codeblöcke, Bildpfade und die
Darstellung sowohl im hellen als auch im dunklen GitHub-Theme. Vermeide
veränderliche Werte – etwa die Anzahl von Ranglisteneinträgen und aktuelle
Versionsnummern – im Fließtext, sofern sie nicht im Rahmen desselben
Release-Prozesses erzeugt oder aktualisiert werden.

## Desktop-Artefakte bauen

> [!WARNING]
> Der aktuelle Release-Ablauf baut Archive, führt jedoch weder die Go-,
> Flutter- noch Python-Tests aus und signiert oder notarisiert die erzeugten
> Binärdateien nicht. Führe die Prüfungen oben aus, bevor du einen Tag erstellst.
> SHA-256-Werte im Update-Manifest sind Integritätsmetadaten und keine
> Herausgebersignatur.

Backend-Binärdateien können direkt gebaut werden:

```bash
cd backend
go build ./cmd/server
go build ./cmd/philo-updater
```

Flutter-Desktop-Bundles müssen auf dem jeweiligen Zielbetriebssystem gebaut
werden:

```bash
cd frontend
flutter build linux --release
```

Verwende auf dem entsprechenden Host `windows` oder `macos`. Der
Release-Ablauf baut derzeit Linux x64, Windows x64 und macOS ARM64 auf nativen
Runnern. Der vollständige Prozess für Archive und Manifeste ist in
`quikinstall/README.md` im Repository beschrieben.

Ein Entwicklungsstand kann dem veröffentlichten Paket voraus sein. Gleiche
Ansichten und Routen vor Dokumentation oder Aufnahmen mit dem exakten Tag ab,
der veröffentlicht werden soll.

## Architektur- und Codegrenzen

- Halte Feature-Routing und Orchestrierung im Go-Backend; Python-Worker sind
  überwachte Laufzeitkomponenten und kein zweites Anwendungs-Backend.
- Halte Geschäftslogik aus großen Flutter-Widget-Bäumen heraus. Verwende
  Services, State, gemeinsame Widgets und lokalisierte Strings wieder.
- Verwende die PhiloGrid-Konventionen für Karten- und Matrixlayouts: adaptive
  Spalten, wiederverwendbare Zellen, 12/16 px Container-Innenabstand und
  8/12 px Rasterabstand.
- Bewahre die Loopback-Voreinstellungen. Eine Änderung, die einen Dienst über
  den lokalen Rechner hinaus erreichbar macht, benötigt eine ausdrückliche
  Sicherheitsprüfung und eine Aktualisierung der Dokumentation.
- Protokolliere keine Anbieter-Schlüssel, Session-Geheimnisse, Bearer-Tokens
  oder Zugangsdaten für Modelldownloads.
- Behandle Dateizugriffe und Befehlsausführung durch den Assistenten sowie
  Archiventpackung und Updater-Aktivierung als sicherheitsrelevante Grenzen.

Lies vor dem Einreichen deiner Arbeit den
[Leitfaden für Beiträge](../CONTRIBUTING.md).
