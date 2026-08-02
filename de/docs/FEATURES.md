# PhiloEngine – Funktionen und Grenzen

**Deutsch** · [English](../../docs/FEATURES.md)

Diese Seite beschreibt den **aktuellen Entwicklungsstand** von PhiloEngine. Sie unterscheidet bewusst zwischen nutzbaren Funktionen, Alpha-Modulen, teilweise verdrahteten Bedienelementen, gesperrten Vorschauen und geplanten Zukunftsphasen.

[← Deutsche Übersicht](../README.md) · [Installation](INSTALLATION.md) · [Roadmap](../ROADMAP.md)

> [!NOTE]
> Diese Seite kann veröffentlichten Paketen voraus sein. Für ein installiertes
> Paket gelten die zugehörigen Release-Hinweise als maßgebliche Funktionsliste.

## Statuslegende

| Status | Bedeutung |
|:---|:---|
| **Nutzbar** | Im aktuellen Entwicklungsstand implementiert; als Alpha weiterhin veränderlich. |
| **Alpha** | Implementiert und testbar, aber noch in aktiver Entwicklung oder noch nicht Bestandteil jeder Veröffentlichung. |
| **Teilweise** | Oberfläche oder Infrastruktur existiert, der vollständige Ablauf ist jedoch noch nicht verbunden. |
| **Gesperrt** | Sichtbare Vorschau einer späteren Phase; momentan nicht bedienbar. |
| **Geplant** | Roadmap-Richtung ohne derzeit nutzbare Oberfläche oder Backendablauf. |

## Funktionsmatrix

| Bereich | Status | Kurzbeschreibung |
|:---|:---:|:---|
| Anmeldung und Onboarding | Nutzbar | Login, Sitzungswiederherstellung, TOTP-Einrichtung, Sprache und Classic/Lite-Auswahl |
| Chat | Nutzbar | Lokale und unterstützte Cloudmodelle, Streaming, Markdown, LaTeX, Reasoning, Code und Chatprojekte |
| Engine | Nutzbar | Lokale Modelle konfigurieren, starten, überwachen und verwalten |
| Marketplace | Nutzbar | Hugging-Face-Downloads sowie OpenRouter- und Featherless-Modelle |
| Bot-Verwaltung | Nutzbar | Eigene Bots, Prompts, Stile, Routing und Modellbindung |
| Einstellungen | Nutzbar | Provider, Server, Sprache, UI-Modus, Shortcuts, Bot-Auswahl und Skill-Verwaltung |
| News | Alpha | Aggregierte KI-/Tech-Feeds, Suche, Filter und gespeicherte Artikel |
| Benchmark | Alpha | LMArena-Text-Leaderboard, Details und Modellvergleich |
| Agentische Abläufe | Teilweise | Planning-, Tool-, Berechtigungs- und Diff-Oberflächen vorhanden; direkte Agent-Modi gesperrt |
| Training | Gesperrt | Phase-3-Vorschau für geführtes Full-Finetuning und Finetuning ohne Backendbetrieb |
| Quantisierung | Gesperrt | Phase-3-Vorschau für geführte Konvertierung und Quantisierung ohne Backendbetrieb |
| Gen Studio | Gesperrt | Phase-4-Vorschau für Bild-/Videogenerierung ohne Generierungsdienste |
| Spieleentwicklung | Geplant | Phase-4-Richtung ohne derzeitiges Produktmodul |
| Geteilte Modelle und Rechenleistung | Geplant | Freiwillige Phase-5-Richtung; derzeit existiert kein Netzwerk zur Ressourcenfreigabe |

## Oberfläche und Navigation

PhiloEngine verwendet ein dauerhaft dunkles Material-3-Design mit einer Obsidian-Farbpalette, goldenen Akzenten und einer responsiven Karten- und Rasterstruktur. Die Oberfläche passt Sidebar, Inhaltsflächen und Karten an schmale sowie breite Desktopfenster an.

### Classic und Lite

- **Classic** zeigt Chat, Engine, Marketplace, Training, Quantisierung, Gen Studio, News und Benchmark.
- **Lite** konzentriert die Hauptnavigation auf Chat, Engine, Marketplace, News und Benchmark.
- Einstellungen und Bot-Verwaltung bleiben unabhängig vom gewählten Modus erreichbar.
- Beim Wechsel zu Lite wird ein gerade geöffnetes, dort verborgenes Modul verlassen.

Die Sidebar kann während einer Sitzung eingeklappt, sortiert und um Module reduziert werden. Diese Anpassung ist derzeit nur lokaler UI-Zustand; eine dauerhafte Speicherung ist nicht erkennbar.

## Anmeldung und Onboarding

- Anmeldung mit Benutzername und Passwort.
- Wiederherstellung einer gemerkten Sitzung beim Start.
- Wählbare Sitzungsdauer von acht Stunden bis dauerhaft.
- TOTP-Einrichtung per QR-Code, beispielsweise für Google Authenticator oder 2FAS.
- Registrierung und Passwort-Reset mit Authenticator-Code.
- Nicht überspringbares Erst-Onboarding für **Deutsch/Englisch** und **Classic/Lite**.
- Einstellungen werden über das Backend gespeichert; bei einem Fehler bleibt ein sichtbarer Wiederholungsweg erhalten.

## Chat

### Modelle und Sitzungen

- Auswahl zwischen gestarteten lokalen Engine-Instanzen und aktivierten API-Modellen.
- Modellwechsel pro Chatsitzung.
- Bots können optional fest an ein lokales oder ein API-Modell gebunden werden.
- Aufwärmanzeige für lokale Modelle mit Fortschritt, Abbruch und erneutem Versuch.
- Neue Chats, Verlauf und projektbasierte Organisation.
- Projekte können Name, Farbe, Symbol und optional einen lokalen Ordnerpfad besitzen.
- Chats lassen sich umbenennen, löschen und zwischen Projekten verschieben.

### Antworten und Darstellung

- Gestreamte Antworten per Server-Sent Events.
- Live-Reasoning mit anschließend einklappbarer Reasoning-Ansicht.
- Arbeitsphase, Laufzeit und Fortschritt während einer Antwort.
- GitHub-Flavored Markdown nach Abschluss des Streams.
- Inline- und Block-LaTeX, Checkboxen und Links.
- Codeblöcke mit Vorschau, Quellansicht und Kopierfunktion.
- Native `visual`-Blöcke für Balken-, Säulen-, Linien-, Donut-, Kreis-, Prozess-, Flow- und KPI-Darstellungen.
- Nachrichten kopieren, eigene Nachricht bearbeiten und ab dort neu senden.
- Schnelle Folgeanweisungen wie kürzer, kritischer oder stärker strukturiert.

### Agentische Infrastruktur

Planning kann an die API übermittelt werden. Die Oberfläche enthält außerdem Planfreigaben, Tool-Ereignisse, Dateidiffs und Berechtigungsentscheidungen wie einmalig erlauben, für die Sitzung erlauben oder ablehnen.

Die Denkmodi **Dual** und **Agent** sind in der direkten Auswahl aktuell deaktiviert. Vorhandene agentische UI und Ereignisbehandlung bedeuten deshalb noch keinen allgemein freigeschalteten Agent-Modus.

### Sichtbare, aber noch nicht vollständige Chat-Funktionen

| Bedienelement | Aktuelle Grenze |
|:---|:---|
| Websuche | Der Schalter ändert UI-Zustand und Badge, wird derzeit aber nicht mit der Chat-Anfrage übertragen. |
| Datei-Upload / Drag-and-drop | Dateien erscheinen als Chips, werden aber noch nicht als Anhang an die Nachricht gesendet. |
| Mikrofon | Die Schaltfläche besitzt aktuell keine Aktion; Spracheingabe ist nicht funktionsfähig. |
| Philox | Der Navigationsweg öffnet derzeit dieselbe Chatoberfläche und keine eigenständige Philox-Ansicht. |

## Memory und Embeddings

Der Memory-Abruf verwendet standardmäßig ein deterministisches, lokales
Hash-Embedding-Backend mit 128 Dimensionen. Das optionale lokale ONNX-Backend
benötigt einen Python-/ONNX-Sidecar, der separat aus dem Quellcode gestartet und
konfiguriert werden muss. Die Schnellinstallation liefert diesen Sidecar nicht
mit. Ohne ein funktionsfähiges optionales Backend fällt Memory auf die
Hash-Implementierung zurück.

## Engine

Die Engine führt in drei Schritten vom lokalen Modellkatalog zur laufenden Instanz:

1. Modell auswählen.
2. Ressourcen und Laufzeit konfigurieren beziehungsweise automatisch berechnen lassen.
3. Vorprüfung bestätigen und Instanz starten.

### Modell- und Ressourcenverwaltung

- Lokale Modelle scannen, erneut einlesen und nach Bestätigung löschen.
- Hardware- und Speicherempfehlung für GPU, GPU plus RAM oder CPU/RAM-Fallback.
- Automatische oder feste Kontextgröße mit Vorprüfung von Gewichten, Kontextspeicher und Laufzeitreserve.
- GPU-, CPU- oder Hybrid-Platzierung.
- Laufzeitinstallation und Fortschrittsereignisse.
- Instanzen starten, stoppen, bearbeiten und entfernen.
- Kontextänderungen mit Neustart- und Stabilitätsprüfung.
- Sampling-Standardwerte und technische Fehlerhinweise.

### Expertenoptionen

Unter anderem stehen Laufzeit, Prozesspriorität, GPU-Layer, CPU-Threads, Tensorparallelität, parallele Sequenzen, GPU-Auswahl, Offloading, KV-Cache-Datentyp, Cache-Richtlinie, RAM-Offload, Fallback, Remote Code und Autostart zur Verfügung.

### Sicherheit und Telemetrie

- Die integrierte privilegierte Reparatur von GPU-Build-Abhängigkeiten gilt
  derzeit nur für Debian-basierte Linux-Systeme. Nach ausdrücklicher Zustimmung
  verwendet sie `pkexec` mit `apt-get`; andere Linux-Distributionen, macOS und
  Windows erfordern eine manuelle Einrichtung der Abhängigkeiten.
- Remote-Modellcode läuft nicht in einer vollständigen Sandbox. Die Freigabe ist an Modell-Fingerprint und Python-Code-Hash gebunden und wird bei Änderungen erneut verlangt.
- Die Telemetrie zeigt RAM- und VRAM-Auslastung, Startfortschritt, laufende
  Modelle, aktive Anfragen sowie Laufzeit- und Komponenteninformationen.

## Marketplace

### Lokale Modelle über Hugging Face

- Suche mit verzögerter Anfrage, Seitennavigation und Nachladen.
- Kategorien wie Chat, Code, Reasoning, Vision und Embedding.
- Sortierung nach Popularität, Intelligenz, Kontext, Aktualität und unterstützten Cloud-Preisfeldern.
- Filter für lokale Modelle, GPU-Fit, Quantisierung und Format.
- Grid- und Listenansicht.
- Hardwarebezogene Fit-, VRAM-, Laufzeit- und Kontextinformationen.
- Auswahl konkreter Varianten, Quantisierungen oder Safetensors-Shards.
- Größenprüfung vor dem Download.
- Downloadpanel mit Fortschritt, Geschwindigkeit, Zielpfad, Historie und Schutz vor doppelten Download-Jobs.
- Token-Unterstützung für zugriffsbeschränkte Hugging-Face-Modelle.

### Cloudmodelle

Unterstützte OpenRouter- und Featherless-Modelle können nach hinterlegtem Provider-Token für den Chat aktiviert werden. Preis- und Providerinformationen stammen vom jeweiligen Dienst und können sich außerhalb von PhiloEngine ändern.

## Bots

Eigene Bots können mit folgenden Eigenschaften angelegt werden:

- Name und Systemprompt.
- Routing-Keywords für automatische Zuordnung.
- Antwortstil: kurz, erklären, Schritte, kritisch, Brainstorming oder ausgewogen.
- Optionaler Agentic-Schalter und erlaubte Wurzelpfade.
- Optionale feste Bindung an ein lokales oder ein API-Modell.
- Auswahl eines Standard-Bots.

Der integrierte **Bot Builder** ist ein geschützter System-Bot und wird nur lesbar dargestellt.

## Einstellungen

### Allgemein

- Modell-Downloadordner auswählen.
- Backend-API-Adresse ändern.
- Deutsch oder Englisch wählen.
- Zwischen Classic und Lite wechseln.
- Erkannte Hardware- und Speicherinformationen anzeigen.

### Provider und Server

- Verbindungsstatus des lokalen Backends prüfen.
- Tokens für Hugging Face, OpenRouter und Featherless verwalten.
- Eigene Nodes anlegen, bearbeiten, löschen und auf Erreichbarkeit prüfen.

Eigene Nodes können derzeit **noch nicht als aktive Chat- oder Engine-Verbindung** ausgewählt werden. Die Oberfläche kennzeichnet diesen Ausbau als Phase 2.

### Tastenkürzel, Standard-Bot und Agent Skills

Tastenkürzel für Modulwechsel, Sidebar, Chatfokus, neue Sitzung, Suche und Engine-Aktionen können angepasst werden. Für neue Chats lässt sich automatische Botwahl oder ein bevorzugter Standard-Bot festlegen; laufende Chats behalten ihre bisherige Bindung.

Skill-Ordner lassen sich importieren, validieren, nach `data/skills` kopieren, aktivieren, deaktivieren, löschen und neu einlesen. In dieser Version werden die Skills **noch nicht in Chats geladen**.

## News · Alpha

News gehört zur aktuellen Alpha-Entwicklung und kann den bereits veröffentlichten Paketen voraus sein.

<img src="../../assets/screenshots/news.png" alt="News-Feed mit Anbieter- und Kategoriefiltern" width="100%">

- Responsives Kartenraster mit Bild, Quelle, Zeitangabe, Überschrift, Auszug und Kategorie.
- Suche über Titel, Inhalt und Tags.
- Kategorie-, Quellen- und Gespeichert-Filter.
- Pro Benutzer gespeicherte Artikel mit optimistischer Aktualisierung und Fehler-Rollback.
- Externe Links zur Originalquelle.
- Regelmäßige Feed-Aktualisierung und Deduplizierung.

Zu den eingebundenen Quellen gehören im aktuellen Stand unter anderem OpenAI, Hugging Face, Google DeepMind, Mistral AI, Golem, heise, Hacker News und Anthropic. VideoCardz ist wegen HTTP-403-Antworten deaktiviert. Quellen können ihre Feeds oder Zugriffsmöglichkeiten jederzeit ändern.

## Benchmark · Alpha

Benchmark ist ein Alpha-Modul. Obwohl die interne Struktur mehrere Boards
zulässt, ist derzeit nur **LMArena · Text** registriert.

<img src="../../assets/screenshots/benchmark.gif" alt="Benchmark mit Übersicht, Rangliste und Direktvergleich" width="100%">

- Tabs für Übersicht, Leaderboard und Vergleich.
- Gesamt-Elo sowie Kategorien wie Coding, Mathematik, kreatives Schreiben, Instruction Following, Multi-Turn, längere Anfragen und Non-English.
- Suche, Filter nach Organisation oder offenen Gewichten, Sortierung und Nachladen.
- Detailansicht mit Rang, Perzentil, Stimmen, Konfidenzintervall, Lizenz, Organisation und Evaluationsdatum.
- Hugging-Face-Hub-Daten wie Downloads, Likes, Aktualisierung, Gating, Parameterzahlen und Inference-Provider, soweit verfügbar.
- Vergleich von bis zu vier Modellen.

Leaderboard-Daten stammen aus den Parquet-Dateien von
`lmarena-ai/leaderboard-dataset` auf dem Hugging Face Hub, nicht vom
Hugging-Face-Datasets-Server. Live-Snapshots werden lokal zwischengespeichert
und im Regelfall täglich aktualisiert; Hubdetails besitzen einen kürzeren Cache.
„Live“ bedeutet daher nicht, dass jede Anzeige bei jedem Öffnen neu aus dem
Internet geladen wird.

## Spätere Phasen

### Training · Phase 3

Das Trainingsmodul ist eine gesperrte Designvorschau. Bedienelemente sind deaktiviert; es gibt in diesem Modul aktuell keine Trainings-API, keinen laufenden Job und kein Fortschrittspolling. Phase 3 soll Full-Finetuning und ressourcenschonendere Finetuning-Wege geführt, reproduzierbar und leicht nutzbar machen, ohne Expertenoptionen zu entfernen.

### Quantisierung · Phase 3

Das Quantisierungsmodul ist eine gesperrte Designvorschau. Eine dargestellte Konfiguration oder Vorschau führt derzeit keine Quantisierung aus. Phase 3 soll verständlich durch Entscheidungen zu Format, Qualität, Größe, Speicherbedarf und Kompatibilität sowie durch Konvertierung, Fortschritt, Prüfung und Wiederherstellung führen.

### Gen Studio · Phase 4

Gen Studio zeigt eine gesperrte Vorschau für Bild- und Videogenerierung. Es ist aktuell nicht an einen Generierungsdienst angebunden.

### Spieleentwicklung · Phase 4

Die Roadmap sieht einen eigenen Arbeitsbereich für geordnete Asset-Abläufe und projektbezogene Unterstützung bei der Spieleentwicklung vor. In der aktuellen Oberfläche existiert weder ein Spieleentwicklungsmodul noch ein zugehöriger Backendablauf.

### Geteilte Modelle und Rechenleistung · Phase 5

Langfristig sollen Besitzer selbst gehostete Modelle und Rechenleistung nach ausdrücklicher Freigabe bereitstellen können. Heute wird nichts automatisch geteilt und es existiert kein öffentliches Rechennetzwerk. PhiloEngine selbst soll kostenlos und Open Source bleiben.

## Lokalisierung

Die von PhiloEngine formulierte Oberfläche ist auf Deutsch und Englisch verfügbar. Technische Diagnosen oder Daten, die direkt vom Backend beziehungsweise externen Quellen geliefert werden, können absichtlich unverändert bleiben, um Präzision und Fehlersuche nicht durch Übersetzung zu verfälschen.

## Plattformen

Aktuell bereitgestellte Desktoppakete:

- Linux x64
- Windows x64
- macOS ARM64

Im Flutter-Projekt vorhandene Gerüste für Android, iOS, Web oder weitere Desktoparchitekturen sind nicht gleichbedeutend mit offiziell bereitgestellten und getesteten Releases. macOS x64 kann lokal gebaut werden, wird jedoch nicht automatisch als Releaseartefakt erzeugt.

## Tests und Reifegrad

Das Repository enthält Widget- und Unit-Tests für unter anderem Engine, Chat, Marketplace, News, Benchmark, Einstellungen, Onboarding, Lokalisierung, Authentifizierung, Bots und Dark Theme sowie einen Integration-Smoke-Test. Vorhandene Tests bedeuten nicht automatisch, dass jede Plattform oder jeder externe Provider in jeder Veröffentlichung vollständig verifiziert wurde.

PhiloEngine bleibt Alpha-Software. Prüfe für einen konkreten Stand zusätzlich die [Roadmap](../ROADMAP.md), die [Installationshinweise](INSTALLATION.md) und die Hinweise des jeweiligen Releases.
