# Fehlerbehebung für PhiloEngine

**Deutsch** · [English](../../docs/TROUBLESHOOTING.md)

> [!NOTE]
> PhiloEngine ist Alpha-Software. Ermittle zuerst, auf welcher Ebene der Fehler auftritt – Client, HTTP-API, Laufzeit-Installer, Modell-Worker, externe Quelle oder Updater. Eine funktionierende Benutzeroberfläche beweist nicht, dass jeder optionale Dienst verfügbar ist.

[← README](../README.md) · [Architektur](ARCHITECTURE.md) · [Datenschutz](PRIVACY.md)

## Diagnose in zwei Minuten

Führe diese Befehle im PhiloEngine-Repository aus, sofern bei einem Befehl nichts anderes angegeben ist:

```bash
cd /pfad/zu/philoengine
git status --short
go version
flutter --version
python3 --version
curl -fsS http://127.0.0.1:8080/health
```

Prüfe anschließend die lokalen Listener:

```bash
ss -ltnp | rg ':8080|:50051|:8091|:8092'
```

Verwende auf Systemen ohne `ss` die Socket-Anzeige der jeweiligen Plattform, beispielsweise `lsof -nP -iTCP -sTCP:LISTEN` unter macOS. Eine fehlgeschlagene `/health`-Anfrage bedeutet, dass das HTTP-Backend nicht bereit ist. Behebe dieses Problem vor der Fehlersuche im Flutter-Client.

| Standard-Listener | Zweck | Erwartete Erreichbarkeit |
|---|---|---|
| `127.0.0.1:8080` | HTTP-API, PhiloBot-POST/SSE und ticketbasierte Engine-/Memory-Ereignisse | Nur Loopback |
| `127.0.0.1:50051` | Skills-gRPC | Nur Loopback |
| `127.0.0.1:8091` | OpenAI-kompatibles lokales Modell-Gateway | Nur Loopback; fehlt nur bei ausdrücklicher Deaktivierung |
| `127.0.0.1:8092` | Optionaler ONNX-Memory-Embedding-Sidecar | Nur Quellcode, separat gestartet, nur Loopback |

Modell-Worker verwenden dynamisch zugewiesene Loopback-Ports und besitzen daher
keinen weiteren festen Eintrag in dieser Tabelle.

## Anforderungen an die Entwicklungsumgebung

Der aktuelle Quellcode- und Release-Ablauf ist auf Folgendes ausgerichtet:

- Go 1.25 für das Backend;
- Flutter 3.44.4 mit einer Dart-Version, die zur Frontend-Vorgabe (`^3.12.2`) kompatibel ist;
- Python 3 für die Installation von Engine-Laufzeitumgebungen und eine Textual-Umgebung für den überwachten Quellcode-Launcher;
- CMake sowie C- und C++-Buildwerkzeuge für native llama.cpp-Paket-Builds;
- passende GPU-Treiber/Toolchains bei Beschleunigung über CUDA, ROCm, Vulkan oder Metal.

Das Go-Backend kann ohne Python starten, aber die automatische Installation lokaler Laufzeitumgebungen und die lokale Modellinferenz stehen dann nicht zur Verfügung.

## Starten aus dem Quellcode

### Empfohlener Launcher

Nachdem `backend/.venv` wie unten beschrieben mit Textual vorbereitet wurde,
starte aus dem Stammverzeichnis des Repositorys:

```bash
cd /pfad/zu/philoengine
./start.sh
```

Verwende `PHILOENGINE_SKIP_UPDATE=1 ./start.sh`, wenn ein Entwicklungs-Checkout
seine normale Quellcode-Updateprüfung nicht ausführen soll.

### Backend manuell

```bash
cd backend
go run ./cmd/server
```

Warte auf die Startmeldungen von HTTP und gRPC. Prüfe danach in einem zweiten Terminal `http://127.0.0.1:8080/health`.

### Flutter-Client manuell

```bash
cd frontend
flutter devices
flutter run -d linux
```

Ersetze `linux` durch ein verfügbares Flutter-Ziel. Die von `start.sh` verwendete Entwicklungskonsole startet derzeit das Linux-Flutter-Gerät und sollte nicht als plattformübergreifender Launcher betrachtet werden.

### Entwicklungskonsole

`start.sh` erwartet eine virtuelle Backend-Umgebung, in der Textual installiert ist:

```bash
cd /pfad/zu/philoengine
python3 -m venv backend/.venv
backend/.venv/bin/pip install textual
./start.sh
```

Die Konsole kann `go mod tidy` ausführen und versuchen, ihr Hilfsprogramm zur Hardwareerkennung zu installieren. Prüfe vor der Verwendung einen nicht sauberen Git-Arbeitsbaum, wenn ein vollkommen unveränderter Checkout erforderlich ist.

## Backend startet nicht

1. Prüfe, ob die Ports `8080`, `50051` oder `8091` bereits belegt sind.
2. Lies den ersten Backend-Fehler und nicht den darauf folgenden Verbindungsfehler von Flutter.
3. Vergewissere dich, dass der aktuelle Benutzer das Backend-Verzeichnis `data/` erstellen und aktualisieren darf.
4. Prüfe, ob der konfigurierte Host eine gültige lokale Adresse ist. Eine Bindung an `0.0.0.0` ist eine Freigabe nach außen und keine Lösung für Verbindungsprobleme.
5. Führe die gezielten Backend-Tests unter [Verifizierung](#verifizierung) aus.

HTTP- und gRPC-Server gehören zum selben Backend-Prozess, starten jedoch
unabhängig voneinander. Ein Bindefehler bei gRPC wird protokolliert, während die
HTTP-API funktionsfähig bleiben kann; ein HTTP-Bindefehler beendet den Prozess.
Das Engine-Gateway startet bereits bei der Modulinitialisierung. Ein Bindefehler
auf `8091` verhindert deshalb ebenfalls die Bereitschaft des Backends, sofern
das Gateway nicht ausdrücklich deaktiviert wurde.

## `401 Unauthorized` oder Anmeldeschleifen

- Fordere im Anmeldeablauf ein neues Token an; verwende keine abgelaufene Sitzung erneut.
- Prüfe, ob das Konto noch existiert. Tokens gelöschter Konten werden abgelehnt.
- Ein neu erzeugtes oder ersetztes JWT-Secret macht alle vorherigen Tokens ungültig.
- TOTP ist für die Ersteinrichtung des Authenticators, die Kontoverwaltung und die Passwortzurücksetzung erforderlich – nicht für jede normale Anmeldung mit Benutzername und Passwort.
- Dauerhafte Sitzungen besitzen absichtlich kein Ablaufdatum. Beim Abmelden kann der Client seine Kopie verwerfen; Kontolöschung oder eine serverweite Rotation des Signatur-Secrets macht das Token ungültig. Ein offengelegtes dauerhaftes Token ist als vertraulich zu behandeln.

Umgehe die Authentifizierung nicht, indem du eine Route öffentlich freigibst oder die Middleware deaktivierst.

## Streaming verbindet sich und wird sofort beendet

PhiloBot-Chats streamen über eine authentifizierte Anfrage an
`POST /api/philobot/stream`, deren Antwort den Typ `text/event-stream` besitzt.
Sende das normale Sitzungstoken im Autorisierungsheader und nicht in der URL.
Engine- und Memory-Ereignisfeeds verwenden einen anderen Ablauf: Fordere
unmittelbar vor dem Öffnen ihres `GET`-Streams ein neues SSE-Ticket an. Diese
Tickets sind kurzlebig und einmalig nutzbar; die Wiederverbindungslogik muss
jeweils ein neues Ticket abrufen.

Prüfe außerdem, ob ein gegebenenfalls vorhandener Reverse-Proxy Antworten vom Typ `text/event-stream` nicht puffert und langlebige Verbindungen zulässt.

## Ein gRPC-Client findet Engine oder Chat nicht

Das ist in der aktuellen Alpha-Version zu erwarten. Nur **Skills** ist für gRPC registriert. Proto-Definitionen für Engine, Chat, Training, Quantization und Marketplace sind keine aktiven Serverdienste. Verwende für aktuelle Integrationsarbeiten die HTTP-/SSE-API.

Der Skills-gRPC-Listener übernimmt außerdem nicht die HTTP-JWT-Middleware. Belasse ihn auf Loopback, sofern keine unabhängige authentifizierte Schutzschicht hinzugefügt wurde.

## Ein Modell fehlt im Katalog

- Prüfe das konfigurierte Modellverzeichnis und nicht nur das Standardverzeichnis.
- Lies den Katalog nach dem Kopieren von Dateien erneut ein.
- Verwende eine unterstützte GGUF- oder SafeTensors-Struktur und füge die Metadaten-/Konfigurationsdateien hinzu, die die ausgewählte Laufzeitumgebung benötigt.
- Prüfe Dateiberechtigungen und verfügbaren Speicherplatz.
- Behandle unvollständige oder nur teilweise heruntergeladene Artefakte als ungültig; benenne sie nicht um, um die Validierung zu umgehen.

`trust_remote_code` ist standardmäßig deaktiviert. Aktiviere es nur, wenn das Modell tatsächlich den vom Repository bereitgestellten Code benötigt und dieser Code geprüft wurde.

## Installation der Laufzeitumgebung schlägt fehl

Prüfe zuerst die Werkzeuge des Hosts:

```bash
python3 --version
cmake --version
cc --version
c++ --version
```

Unterscheide danach zwischen diesen Fällen:

- **Paket-Host nicht erreichbar:** Die erstmalige Erstellung einer Laufzeitumgebung benötigt Netzwerkzugriff. Ein vollständig installierter Worker kann anschließend mit lokalen Modelldateien und Offline-Flags arbeiten.
- **Nativer Build fehlgeschlagen:** Bei der Installation von llama.cpp kann nativer Code kompiliert werden; dafür ist eine funktionierende Compiler-Toolchain erforderlich.
- **GPU-Build fehlgeschlagen:** Prüfe, ob Treiber und SDK/Toolkit zum ausgewählten Backend passen.
- **Smoke-Test fehlgeschlagen:** PhiloEngine aktiviert die neue Umgebung nicht. Untersuche die Ausgabe des Installers, statt sie manuell als funktionsfähig zu markieren.
- **Zu wenig Speicherplatz:** Laufzeitumgebungen sind isoliert und inhaltsadressiert, sodass mehrere Rezepte gleichzeitig vorhanden sein können.

Kopiere keine teilweise erstellte Umgebung über eine aktive. Installation und Aktivierung sind für eine atomar gestufte Ausführung ausgelegt.

Die privilegierte Reparatur fehlender Vulkan-Build-Pakete innerhalb der App
unterstützt derzeit nur Debian/Ubuntu und ruft nach einer ausdrücklichen,
einmaligen Zustimmung `pkexec` mit `apt-get` auf. Installiere die erforderliche
Toolchain auf anderen Systemen über die reguläre Paketverwaltung des
Betriebssystems.

## Eine unerwartete Laufzeitumgebung wurde ausgewählt

Die aktuellen Auswahlregeln sind beabsichtigt:

| Situation | Erwartetes Ergebnis |
|---|---|
| GGUF | llama.cpp |
| SafeTensors unter Linux mit unterstütztem diskretem CUDA/ROCm | vLLM, mit Transformers als Fallback |
| SafeTensors auf anderen Systemen | Transformers |

vLLM ist nicht die Standardeinstellung für CPU, Metal oder nicht unterstützte Hosts. Eine fehlgeschlagene bevorzugte Laufzeitumgebung kann auf eine andere Laufzeitumgebung, ein anderes Gerät, einen anderen KV-Cache-Modus oder einen kleineren Kontext zurückfallen. Die Modellgewichte werden nicht automatisch quantisiert.

## Zu wenig Speicher, Speicherdruck oder langsames Laden

- Untersuche die Ausgabe zu Engine-Fähigkeiten/Planung und die Live-Metriken.
- Schließe oder entlade inaktive Instanzen, bevor du den Kontext vergrößerst.
- Reduziere den angeforderten Kontext oder die Anzahl paralleler Instanzen.
- Prüfe, ob Betriebssystem und Treiber realistische Werte für freien Speicher melden; die Planung verwendet aktuelle Snapshots und nicht nur die Nennkapazität.
- Belasse die standardmäßige RAM-/GPU-Reserve, sofern du die Auslastung des Hosts nicht genau kennst.

Planer und Ressourcenüberwachung reduzieren das Risiko einer Überbelegung, können aber weder garantieren, dass das Betriebssystem niemals auslagert, noch dass jeder Treiber den nutzbaren Speicher korrekt meldet.

## Memory-Abruf wirkt schwach oder unerwartet

Das standardmäßige Embedding-Backend ist ein deterministisches, 128-dimensionales Hash-Backend. Es arbeitet zuverlässig und lokal, ist aber nicht mit einem neuronalen semantischen Embedding-Modell gleichzusetzen.

- Prüfe den Memory-Zustand, um das aktive Embedding-Backend zu erkennen.
- Prüfe die Benutzer- und Projektzuordnung, bevor du von fehlenden Daten ausgehst.
- Beachte, dass das hybride Ranking auch FTS-, Aktualitäts-, Quellen- und Typsignale verwendet.
- Ein nicht verfügbares optionales ONNX-, Ollama- oder entferntes API-Backend fällt auf Hash-Embeddings zurück.
- Die Standardkomprimierung ist deterministisch und regelbasiert; Zusammenfassungen können absichtlich Details auslassen.

Der ONNX-Sidecar unter `backend/sidecar/` wird weder von `start.sh` gestartet
noch im Quickinstall-Paket mitgeliefert. Er muss separat auf
`127.0.0.1:8092` laufen; andernfalls fällt `onnx_local` auf das Hash-Backend
zurück.

Bearbeite die SQLite-Datenbank niemals direkt, während das Backend läuft.
Sichere gezielt die betroffenen Daten vor Wartungsarbeiten und lösche nicht das
gesamte Datenverzeichnis als allgemeine Reset-Maßnahme. Beim Quellcodestart ist
dies `backend/data/`, bei Quickinstall
`<Installationsordner>/backend/data/`.

## Suchkategorien melden `no engines available`

Derzeit sind Engines nur für die **Textsuche** registriert: Wikipedia, Bing, Brave, Google und DuckDuckGo. Routenstrukturen für News, Bilder, Videos und Bücher sind vorhanden, besitzen aber noch keine Engines.

Bei Fehlern der Textsuche:

- probiere eine andere registrierte Engine aus;
- rechne damit, dass vorgelagerte HTML-Änderungen oder Rate-Limits Scraping-Anbieter vorübergehend außer Betrieb setzen können;
- prüfe, ob die Anfrage durch eine Netzwerkrichtlinie blockiert wird;
- beachte, dass die Webextraktion Localhost-, private, linklokale und andere geschützte Adressbereiche ablehnt.

Der SSRF-Schutz ist eine Risikominderung und kein Grund, den Abrufdienst feindlichem mandantenfähigem Datenverkehr auszusetzen.

## News oder Benchmark ist leer/veraltet

> [!WARNING]
> News und Benchmark sind Alpha-Module und unterscheiden sich zwischen Releases.
> Untersuche den exakten installierten Build und dessen Release-Hinweise.

- News aktualisiert sich beim Start und alle 15 Minuten. Wenn alle Quellen fehlschlagen, bleibt der aktuelle Cache erhalten; ein neuer Arbeitsbereich kann deshalb mitgelieferte Fallback-Elemente anzeigen.
- Einige News-Quellen sind HTML-Scraper und können ausfallen, wenn ein Herausgeber sein Markup ändert. Der Ausfall einer Quelle darf erfolgreiche Feeds nicht ungültig machen.
- Im neueren lokalen Entwicklungsstand registriert Benchmark nur das LMArena-Text-Board. Beim Backend-Start aktualisiert es einen fehlenden oder mehr als 24 Stunden alten Snapshot; einen separaten täglichen Timer gibt es nicht.
- Schlägt eine Benchmark-Quelle fehl, bleibt der letzte nutzbare Snapshot erhalten. Die aktuelle Anzahl in einem lokalen Snapshot ist keine dauerhafte Zusage zur Modellanzahl.
- Optionale Hugging-Face-Modelldetails benötigen eine auflösbare Repository-ID; importierte Arena-Zeilen liefern nicht immer eine solche ID.

Prüfe die authentifizierten Statusendpunkte und die Backend-Protokolle der Aktualisierung, bevor du einen Cache löschst.

## Updates werden übersprungen oder zurückgesetzt

Prüfe bei Quellcode-Updates:

```bash
git branch --show-current
git status --short
```

Automatische Quellcode-Updates setzen den exakt konfigurierten Branch (normalerweise `main`), einen sauberen Arbeitsbaum ohne nicht versionierte Dateien und eine Fast-Forward-Beziehung zum Remote voraus. Der Updater wechselt absichtlich keine Branches, führt weder Rebase noch Reset aus und überschreibt keine lokalen Arbeiten.

Für Release-Updates gilt:

- Bei einem nicht erreichbaren Offline-Manifest sollte auf das zuvor verifizierte Bundle zurückgefallen werden.
- Größe und SHA-256 des Assets müssen mit dem Manifest übereinstimmen.
- Unsichere Archivpfade und symbolische Links werden abgelehnt.
- Ein unmittelbarer Startfehler kann das neue Bundle isolieren und die vorherige Version erneut aktivieren.
- Ein späterer Laufzeitabsturz löst nicht automatisch ein Downgrade aus.

Das Signaturfeld des Manifests ist reserviert, wird im aktuellen Updater jedoch
**nicht verifiziert**. Eine übereinstimmende Prüfsumme beweist Konsistenz mit
diesem Manifest, nicht das Vorliegen einer unabhängigen Herausgebersignatur. Der
aktuelle Release-Ablauf signiert oder notarisiert seine Binärdateien ebenfalls
nicht; deshalb können Vertrauenswarnungen des Betriebssystems erscheinen.

Setze `PHILOENGINE_SKIP_UPDATE=1`, um die Updateprüfung des Entwicklungs-Launchers zu überspringen. Die aktuelle Release-Automatisierung ist auf Linux x64, Windows x64 und macOS ARM64 ausgerichtet; ein aktuelles macOS-x64-Artefakt ist nicht zu erwarten.

## Verifizierung

Führe die Prüfungen für die von dir geänderte Ebene aus. Beim erstmaligen Auflösen von Abhängigkeiten kann Netzwerkzugriff erforderlich sein.

```bash
cd backend
go test ./...
```

```bash
cd frontend
flutter analyze
flutter test
```

```bash
cd frontend
flutter test integration_test/ -d linux
```

```bash
cd backend
python3 -m unittest engineworker/test_transformers_worker.py
```

```bash
python3 -m unittest discover -s quikinstall/tests -v
python3 -m py_compile quikinstall/build_release.py
```

Führe die Befehle jeweils in dem angegebenen Verzeichnis aus; mehrere Pfade und Datenvorgaben hängen vom Arbeitsverzeichnis ab.

## Ein Problem sicher melden

Gib Folgendes an:

- Betriebssystem, Architektur und PhiloEngine-Commit;
- Go-, Flutter-/Dart- und Python-Versionen;
- Modellformat und ausgewählte Laufzeitumgebung, ohne private Modelldateien hochzuladen;
- GPU-/Treiber-/Laufzeittyp, sofern relevant;
- den ersten ursächlichen Backend-/Installer-Fehler und die Aktion, die ihn ausgelöst hat;
- ob der Checkout nicht sauber ist und ob das Problem mit den Loopback-Standardeinstellungen reproduzierbar ist.

Entferne API-Schlüssel, JWTs, TOTP-Secrets, Memory-Tokens, private Prompts, Projektpfade, Benutzernamen und Anbieter-Anfrage-Payloads, bevor du Protokolle teilst. Unter [Datenschutz](PRIVACY.md) findest du das vollständige Vertrauensmodell.
