# PhiloEngine installieren

**Deutsch** · [English](../../docs/INSTALLATION.md)

PhiloEngine ist als selbstaktualisierendes Desktop-Bundle oder als Checkout
des Quellcodes verfügbar. Wähle das Desktop-Bundle, wenn du die Anwendung
verwenden möchtest. Wähle den Quellcode-Checkout, wenn du den Code untersuchen,
verändern oder zum Projekt beitragen möchtest.

[← README](../README.md) · [Entwicklung](DEVELOPMENT.md) · [Fehlerbehebung](TROUBLESHOOTING.md)

> [!IMPORTANT]
> PhiloEngine ist Alpha-Software. Bewahre Sicherungskopien wichtiger Projekte
> auf und prüfe die von einem Assistenten angeforderten Berechtigungen, bevor
> du sie genehmigst.

> [!NOTE]
> Veröffentlichte Pakete enthalten den in ihren Release-Hinweisen genannten
> Funktionsumfang. Ein Entwicklungsstand kann dem installierten Paket voraus
> sein.

## Installationsweg wählen

| | Schnellinstallation | Quellcode-Checkout |
|---|---|---|
| Am besten geeignet für | Nutzung von PhiloEngine | Entwicklung und Mitwirkung |
| Flutter SDK | Nicht erforderlich | Erforderlich |
| Go-Toolchain | Nicht erforderlich | Erforderlich |
| Updates | Vom Launcher verwaltet | Sicherer Fast-Forward beim Start mit `start.sh` |
| Laufzeitumgebungen für lokale Modelle | Werden bei Bedarf in isolierten Python-Umgebungen installiert | Ebenso |

Das Schnellinstallationsarchiv enthält bereits das kompilierte
PhiloEngine-Frontend, das Backend und den Launcher. Flutter und Go sind
Build-Werkzeuge und werden daher zum Ausführen dieses Archivs nicht benötigt.

## Schnellinstallation

### Unterstützte Release-Ziele

| Betriebssystem | Architektur | Release-Ziel | Dateiendung der Schnellinstallation |
|---|---:|---|---|
| Linux | x86-64 | `linux-x64` | `-linux-x64-quickinstall.tar.gz` |
| Windows | x86-64 | `windows-x64` | `-windows-x64-quickinstall.zip` |
| macOS | Apple Silicon | `macos-arm64` | `-macos-arm64-quickinstall.tar.gz` |

Intel-macOS ist nicht Teil der automatisierten Release-Matrix. Android, iOS
und andere Architekturen werden nicht als Desktop-Bundles für die
Schnellinstallation angeboten.

### Desktop-Bundle installieren

1. Öffne die [PhiloEngine-Releases](https://github.com/kuchenboss/MyPhiloEngine/releases).
2. Lade das Archiv herunter, dessen Name für dein System auf
   `-<release-target>-quickinstall` mit der passenden Archivendung endet. Das
   Updatearchiv ist kein Paket für die Erstinstallation.
3. Entpacke das vollständige Archiv in ein Verzeichnis, das dauerhaft an
   dieser Stelle bleiben kann.
4. Starte den Launcher auf der obersten Ebene:
   - Linux und macOS: `myphiloengine`
   - Windows: `myphiloengine.exe`
5. Schließe die Authentifizierungseinrichtung beim ersten Start ab und erstelle
   dein Konto.

Starte immer die ausführbare Datei `myphiloengine` auf der obersten Ebene.
Starte Binärdateien innerhalb von `versions/` nicht direkt: Diese Verzeichnisse
werden vom Updater verwaltet.

Unter Unix-artigen Systemen behält ein Archivwerkzeug das Ausführungsbit
normalerweise bei. Falls nicht, stelle es vor dem ersten Start wieder her:

```bash
chmod +x myphiloengine
./myphiloengine
```

### Herausgeberprüfung und Betriebssystemwarnungen

Der Release-Workflow versieht die Desktop-Bundles weder mit einer
Windows-Codesignatur noch mit einer Apple-Codesignatur und Notarisierung. Windows SmartScreen oder macOS Gatekeeper können deshalb vor
einem unbekannten Herausgeber beziehungsweise einem nicht verifizierten
Entwickler warnen, obwohl das Archiv vom Projekt stammt.

Lade ausschließlich von der offiziellen GitHub-Releaseseite des Projekts,
vergleiche vor dem Start den von GitHub angezeigten Asset-Digest oder den
SHA-256-Wert im veröffentlichten Projektmanifest und erteile eine
dateibezogene Betriebssystemfreigabe erst nach dieser Herkunftsprüfung.
SmartScreen, Gatekeeper oder vergleichbare Schutzfunktionen nicht systemweit
deaktivieren. Die Größen- und SHA-256-Prüfungen des Launchers bestätigen die
Übereinstimmung mit dem heruntergeladenen Manifest; sie belegen keine
unabhängig authentifizierte Herausgeberidentität.

### Automatische Updates

Beim Start liest der Launcher das veröffentlichte Manifest des Projekts,
wählt das zum Betriebssystem passende Bundle aus und überprüft vor der
Aktivierung dessen angegebene Größe und SHA-256-Prüfsumme. Die Installation
erfolgt atomar: Ein fehlgeschlagener Download ersetzt nicht die
funktionierende Version. Kann ein neu installiertes Bundle nicht gestartet
werden, kann der Launcher zum vorherigen funktionsfähigen Bundle zurückkehren
und vermeiden, bei jedem Start erneut dasselbe defekte Artefakt zu laden.

Bei einem Offline-Start wird das zuletzt installierte und überprüfte Bundle
verwendet. Setze `PHILOENGINE_SKIP_UPDATE=1` nur, wenn du die Netzwerkprüfung
bewusst überspringen möchtest.

## Voraussetzungen für lokale Modelle

Eine Grafikkarte ist optional. CPU-Inferenz wird unterstützt, ist jedoch
gewöhnlich langsamer und kann viel Arbeitsspeicher erfordern. Chat über einen
API-Anbieter benötigt keine Laufzeitumgebung für lokale Modelle.

PhiloEngine richtet Umgebungen für llama.cpp, Transformers und vLLM bei Bedarf
ein. Diese Umgebungen sind vom Anwendungs-Bundle getrennt und können
zusätzliche Systemvoraussetzungen haben:

- Zum Erstellen der isolierten Laufzeitumgebungen ist eine funktionsfähige
  Python-3-Installation mit `venv` und `pip` erforderlich.
- Für die Verwendung einer NVIDIA-, AMD-, Vulkan- oder Apple-GPU wird ein
  aktueller Treiber benötigt.
- Einige llama.cpp-Konfigurationen werden lokal kompiliert. Dafür sind CMake
  sowie funktionsfähige C- und C++-Compiler erforderlich.
- Unter Linux umfasst eine typische native Build-Umgebung CMake und die C/C++-
  Build-Werkzeuge der Distribution. Vulkan-Builds können zusätzlich die
  Vulkan-Header, `glslc` und SPIR-V-Header erfordern.
- Die integrierte privilegierte Reparatur von GPU-Build-Abhängigkeiten
  unterstützt derzeit nur Debian-basierte Linux-Systeme. Sie fragt ausdrücklich
  nach Zustimmung, bevor sie `pkexec` mit `apt-get` verwendet. Auf anderen
  Linux-Distributionen, macOS und Windows müssen die benötigten Pakete manuell
  installiert werden.
- Installiere unter macOS die Xcode Command Line Tools und CMake, wenn ein
  lokaler Build erforderlich ist.
- Installiere unter Windows eine unterstützte C++-Build-Umgebung und CMake,
  wenn keine passende vorkompilierte Laufzeitumgebung verfügbar ist.
- vLLM wird nur auf kompatibler dedizierter CUDA- oder ROCm-Hardware
  ausgewählt. Die Verfügbarkeit der Laufzeitumgebung unterscheidet sich je nach
  Plattform und Beschleuniger.

Die Engine zeigt den Installationsfortschritt der Laufzeitumgebung und den
Modellstart an. Beim ersten lokalen Start können große Python-Pakete
heruntergeladen oder nativer Code kompiliert werden; deshalb kann er erheblich
länger dauern als spätere Starts.

Auch Modellgewichte benötigen ausreichend freien Speicherplatz. Die Größe
einer Modelldatei entspricht nicht ihrem Speicherbedarf zur Laufzeit; nutze
den Eignungsstatus im Marketplace und die von der Engine vorgeschlagene
Kontextgröße als Orientierung.

### Optionaler ONNX-Embedding-Sidecar

Memory verwendet standardmäßig deterministische lokale Hash-Embeddings. Das
optionale ONNX-Embedding-Backend benötigt den Python-/ONNX-Sidecar aus dem
Quellcode, der separat installiert, gestartet und konfiguriert werden muss. Er
wird von der Schnellinstallation weder mitgeliefert noch gestartet.
Ist der Sidecar nicht verfügbar, fällt Memory auf das Hash-Backend zurück.

## Aus dem Quellcode bauen und starten

### Toolchain

- [Go](https://go.dev/) 1.25 oder neuer
- [Flutter](https://flutter.dev/) 3.44 oder neuer mit Dart 3.12 oder neuer
- Python 3 mit `venv` und `pip`
- Git
- Native Flutter-Desktop-Abhängigkeiten für das Zielbetriebssystem

Klone das Repository:

```bash
git clone https://github.com/kuchenboss/MyPhiloEngine.git philoengine
cd philoengine
```

### Empfohlener Start aus dem Quellcode

Richte unter Linux einmalig die Textual-basierte
Entwicklungskonsole ein:

```bash
cd backend
python3 -m venv .venv
.venv/bin/python -m pip install textual
cd ..
```

Starte PhiloEngine danach aus dem Stammverzeichnis des Repositorys:

```bash
cd /pfad/zu/philoengine
./start.sh
```

`start.sh` öffnet die Entwicklungskonsole und verwaltet Backend und Frontend in
der vorgesehenen Reihenfolge. Wenn der Checkout unverändert ist und sich auf
`main` befindet, kann das Skript vor dem Start ein sicheres
Fast-Forward-Update anwenden. Es überschreibt keine lokalen Änderungen,
wechselt keine Branches und führt keine auseinanderentwickelten Verläufe
zusammen. Setze
`PHILOENGINE_SKIP_UPDATE=1` für einen beabsichtigten Offline- oder
Entwicklungsstart.

### Manueller Start der einzelnen Ebenen

Für die Diagnose oder Entwicklung auf einem System, auf dem `start.sh` nicht
verwendet wird, starte das Backend aus seinem eigenen Verzeichnis, damit die
voreingestellten Pfade nach `backend/data/` aufgelöst werden:

```bash
cd backend
go run ./cmd/server
```

Rufe in einem zweiten Terminal die Flutter-Pakete ab und starte den
Desktop-Client:

```bash
cd frontend
flutter pub get
flutter run -d linux
```

Ersetze `linux` auf dem entsprechenden Host durch `windows` oder `macos`. Das
Backend lauscht standardmäßig auf `127.0.0.1:8080`. Der Desktop-Client erwartet
diesen lokalen Endpunkt.

Informationen zur Repository-Struktur, zu Build-Befehlen und zur Überprüfung
findest du im [Entwicklungsleitfaden](DEVELOPMENT.md).
