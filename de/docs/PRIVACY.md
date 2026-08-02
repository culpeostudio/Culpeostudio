# Datenschutz und Sicherheit in PhiloEngine

**Deutsch** · [English](../../docs/PRIVACY.md)

> [!IMPORTANT]
> **PhiloEngine verfolgt einen Local-First-Ansatz, ist aber nicht vom Netzwerk isoliert.** Modelle, Chats, Memory-Daten und Zugangsdaten werden standardmäßig lokal gespeichert. Updates, News, Benchmark, Suche, Downloads, die Installation von Laufzeitumgebungen und konfigurierte API-Anbieter können jedoch externe Dienste kontaktieren.

[← README](../README.md) · [Architektur](ARCHITECTURE.md) · [Transparenz](TRANSPARENCY.md) · [Fehlerbehebung](TROUBLESHOOTING.md)

## Kurzfassung

- Lokale Modelle werden standardmäßig über Worker ausgeführt, die ausschließlich an Loopback gebunden sind.
- PhiloBot-Chats werden als lokale JSON-Dateien gespeichert; Memory-Datensätze und -Indizes liegen in einer lokalen SQLite-Datenbank.
- Secrets werden hauptsächlich durch ausschließliche Dateiberechtigungen für den Eigentümer geschützt; die untersuchten Speicher sind im Ruhezustand nicht durch die Anwendung verschlüsselt.
- Die meisten HTTP-API-Routen erfordern ein signiertes Sitzungstoken.
- PhiloBot-Pfadprüfungen und Befehlsregeln sind Schutzmaßnahmen, **keine Betriebssystem-Sandbox**.
- Mehrere Funktionen stellen automatisch oder durch Benutzeraktionen ausgelöst ausgehende Verbindungen her.
- Update-Payloads verwenden HTTPS, Größenprüfungen und SHA-256-Prüfsummen, das Signaturfeld des Manifests wird derzeit jedoch **nicht verifiziert**.

## Geltungsbereich: technische Dokumentation, keine Datenschutzerklärung

Diese Seite beschreibt beobachtbares Speicher-, Netzwerk- und
Sicherheitsverhalten der Software. Sie ist keine Rechtsberatung und **keine**
vollständige Datenschutzerklärung nach
[Artikel 13 DSGVO](https://eur-lex.europa.eu/legal-content/DE/TXT/?uri=CELEX%3A32016R0679)
oder vergleichbarem nationalem Recht.

Bevor eine öffentliche Website, eine gehostete PhiloEngine-Instanz oder API,
ein Supportkanal, ein Analyse-/Telemetriedienst oder ein Kontodienst betrieben
wird, der personenbezogene Daten verarbeitet, muss der Betreiber die geltenden
Pflichten prüfen und vor Beginn der Verarbeitung eine eigene, auf den Dienst
zugeschnittene Erklärung bereitstellen. Soweit einschlägig, benötigt diese die
tatsächliche rechtliche Identität des Betreibers/Verantwortlichen, eine
ladungsfähige Postanschrift und Kontaktdaten; Angaben zu Vertretung und
Datenschutzbeauftragten; Zwecke und Rechtsgrundlagen; berechtigte Interessen;
Empfänger und internationale Übermittlungen; Speicherdauer oder Kriterien;
Betroffenenrechte, Widerrufs- und Beschwerdemöglichkeiten; Angaben dazu, ob die
Bereitstellung von Daten vorgeschrieben ist; sowie Informationen zu
automatisierten Entscheidungen. Zusätzlich kann ein separates Impressum
erforderlich sein. Der genaue Inhalt hängt von Betreiber, Rechtsraum und
tatsächlichem Dienst ab. Diese Projektseite erfindet bewusst keine fehlenden
Betreiberangaben und ersetzt diese Prüfung nicht.

## Was lokal gespeichert wird

Die meisten veränderlichen Daten liegen standardmäßig im `data/`-Verzeichnis des Backends. Der genaue Ort hängt vom Arbeitsverzeichnis und von der Konfiguration des Backends ab; Modell- und Projektpfade können auf andere Orte verweisen.

| Daten | Speicherung und Geltungsbereich | Wichtiger Hinweis |
|---|---|---|
| Konten | Private lokale Dateien mit bcrypt-Passwort-Hashes | Anwendungskonten sind keine getrennten Betriebssystembenutzer |
| JWT-Signatur-Secret | Installationsspezifische private Datei | Wird es rotiert oder gelöscht, werden bestehende Sitzungen ungültig |
| TOTP-Secret für die Einrichtung | Private lokale Datei | TOTP schützt Einrichtung, Kontoverwaltung und Passwortzurücksetzung; es ist nicht bei jeder normalen Anmeldung erforderlich |
| Memory-API-Token | Separate private lokale Datei | Wird für die Memory-Schnittstelle verwendet, sofern dort unterstützt |
| Anbieter-Zugangsdaten | Lokale Einstellungsdatei | Werden lokal gespeichert, sind aber nicht durch die Anwendung verschlüsselt |
| PhiloBot-Chats | Eine lokale JSON-Datei je Chat-Sitzung | Prompts, Antworten, Werkzeugaktivitäten und Metadaten können vertrauliche Informationen enthalten |
| Memory | Benutzerspezifische Datensätze und Indizes in SQLite, einschließlich Beobachtungen und abgeleiteter Zusammenfassungen | Abgeleitete Zusammenfassungen und Indizes können auch nach einer Änderung oder Löschung des ursprünglichen Chats vertrauliche Informationen enthalten |
| Gespeicherte News-Elemente | Benutzerspezifische private JSON-Snapshots | Die aktuelle News-Implementierung ist experimentelle Arbeit der Phase 1 |
| Benchmark-Snapshots | Private lokale Snapshot-Dateien | Öffentliche Benchmark-Daten, die bei Veraltung aktualisiert werden |
| Engine-Laufzeitumgebungen | Inhaltsadressierte lokale Python-Umgebungen | Pakete werden bei der ersten Installation heruntergeladen |
| Modelle und Projekte | Konfigurierte Dateisystemverzeichnisse | Sie können außerhalb des standardmäßigen Datenverzeichnisses liegen |

Dateien mit Secrets sollen auf unterstützten Plattformen mit ausschließlichen
Berechtigungen für den Eigentümer erstellt werden. Andere Datensätze, darunter
Chat-JSON-Dateien, können sich statt eines Eigentümermodus für jede einzelne
Datei auf die restriktiven Berechtigungen des übergeordneten Verzeichnisses
stützen. Wirksame Berechtigungen können außerdem je nach Plattform und bereits
vorhandenen Verzeichnissen abweichen. Wer Dateien als derselbe
Betriebssystembenutzer oder als privilegierterer Benutzer lesen kann, kann
weiterhin auf unverschlüsselte Anwendungsdaten und Anbieter-Zugangsdaten
zugreifen. Verwende eine Festplattenvollverschlüsselung und ein geschütztes
Betriebssystemkonto, wenn der Rechner oder die Daten vertraulich sind.

## Externe Verbindungen

Ausgehende Verbindungen sind funktionsspezifisch. Öffentliche Dienste erhalten auch dann übliche Verbindungsmetadaten wie die öffentliche IP-Adresse des Rechners und den Zeitpunkt der Anfrage, wenn keine Chat-Inhalte übertragen werden.

| Auslöser | Externes Ziel | Daten, die den Rechner verlassen können |
|---|---|---|
| Quellcode-/Release-Update beim Start | Konfiguriertes Git-Repository oder vertrauenswürdiger Release-Host | Repository-/Versionsinformationen und übliche HTTP-/Git-Metadaten |
| News-Aktualisierung beim Start und alle 15 Minuten | Öffentliche RSS-/Atom-Feeds und ausgewählte Nachrichtenseiten | Feed-Anfragen und übliche HTTP-Metadaten; konzeptgemäß keine Projekt- oder Chat-Inhalte |
| Darstellung von News-Bildern im Flutter-Client | Der vom Herausgeber gewählte Bild-Host, häufig der Herausgeber selbst oder ein CDN | Der Client fordert die Bild-URL direkt an; der Host erhält übliche Anfrage- und Verbindungsmetadaten wie die öffentliche IP-Adresse und den Zeitpunkt der Anfrage |
| Benchmark-Start bei veraltetem Snapshot | LMArena-Repository auf dem Hugging Face Hub | Repository- und Parquet-Dateianfragen sowie übliche HTTP-Metadaten |
| Textsuche | Ausgewählte öffentliche Suchmaschinen | Suchanfrage, Sprach-/Kategorieoptionen und Verbindungsmetadaten |
| Seitenextraktion | Die vom Benutzer oder Agenten angegebene URL | Angeforderte URL und Verbindungsmetadaten |
| Marketplace-/Modell-Download | Modell-Host oder konfigurierter Anbieter | Suchbegriffe, Artefaktkennungen und gegebenenfalls das konfigurierte Kontotoken |
| Installation einer Laufzeitumgebung | Python-/Paketdistributions-Hosts | Laufzeitrezept und Paketanfragen |
| Cloud-LLM-Anbieter | Der konfigurierte Anbieter | Prompt, ausgewählter Abruf/Kontext, Werkzeugergebnisse, Generierungseinstellungen und die von der API benötigten Anbieter-Zugangsdaten |
| Entferntes Embedding-Backend | Konfigurierter Ollama-/API-Endpunkt | Zur Einbettung übermittelter Text |
| Optionale Abfrage von Modelldetails | Hugging Face Hub | Modellkennung und Anfragemetadaten |
| Laden von UI-Schriftarten | Google-Fonts-Infrastruktur, wenn eine angeforderte Schriftart weder eingebunden noch im Cache ist | Schriftartanfrage und übliche Verbindungsmetadaten; konzeptgemäß keine Chat-Inhalte |

### Namensnennung für Benchmarkdaten

Das Benchmark-Modul verwendet den Datensatz
[LMArena Leaderboard Dataset](https://huggingface.co/datasets/lmarena-ai/leaderboard-dataset)
von `lmarena-ai`, lizenziert unter
[Creative Commons Namensnennung 4.0](https://creativecommons.org/licenses/by/4.0/deed.de).
PhiloEngine lädt ausgewählte Parquet-Shards aus dem Hugging-Face-Hub-Repository
des Datensatzes und verarbeitet sie für Filterung, Zuordnung, Sortierung,
Zwischenspeicherung und Darstellung zu lokalen Snapshots. Diese
Verarbeitungsschritte sind Änderungen durch PhiloEngine; die daraus
entstehende Darstellung ist keine Empfehlung durch LMArena.

> [!WARNING]
> News und Benchmark sind **Alpha-Module** und können dem neuesten
> veröffentlichten Release voraus sein. Beide können ohne einen Klick für jede
> einzelne Aktualisierung Hintergrundanfragen auslösen. PhiloEngine darf daher
> nicht als System beschrieben werden, bei dem „nichts den Rechner verlässt,
> solange der Benutzer es nicht anfordert“.

Phase 5 beschreibt eine zukünftige, freiwillige Möglichkeit, selbst gehostete
Modelle und Rechenleistung bereitzustellen. Das ist kein aktuelles Verhalten:
PhiloEngine teilt weder Modelle noch Rechner oder Rechenleistung automatisch.

### Arbeiten in einer strikt offline betriebenen Umgebung

1. Setze `PHILOENGINE_SKIP_UPDATE=1`, bevor du den Entwicklungs-Launcher verwendest.
2. Konfiguriere keine Cloud-Anbieter oder entfernten Embedding-Endpunkte.
3. Vermeide Suche, Seitenextraktion, News-Ansichten mit extern geladenen Bildern, Marketplace-Downloads und die erstmalige Installation von Laufzeitumgebungen.
4. Stelle Modelle und alle benötigten Laufzeitpakete vorab bereit, solange eine Verbindung besteht.
5. Binde die konfigurierten UI-Schriftarten ein oder speichere sie vorab im Cache, wenn eine einheitliche Typografie offline erforderlich ist.
6. Blockiere ausgehenden Datenverkehr auf Betriebssystem-/Container-Ebene, wenn eine strikte Durchsetzung nötig ist. Die aktuellen News- und Benchmark-Arbeiten aktualisieren sich im Hintergrund und sollten nicht allein durch ein Versprechen in der Dokumentation kontrolliert werden.

Eine Offline-Firewall kann dazu führen, dass netzwerkgestützte Funktionen fehlschlagen; sie sollte den letzten nutzbaren lokalen News- oder Benchmark-Cache nicht beschädigen.

## Authentifizierungsgrenzen

Die primäre HTTP-API verwendet JWT-HS256-Sitzungen mit einem installationsspezifischen Secret. Gelöschte Konten machen ihre Tokens ungültig, da bei der Authentifizierung geprüft wird, ob das Konto noch existiert. Sitzungen können ablaufen oder ausdrücklich dauerhaft sein.

- Die Ersteinrichtung, Anmeldung und Einstiegspunkte zur Kontowiederherstellung müssen zwangsläufig vor der normalen API-Authentifizierung erreichbar sein.
- Die meisten `/api`-Routen erfordern ein gültiges Kontotoken.
- Chat- und Engine-SSE-Verbindungen verwenden kurzlebige, einmalig nutzbare Tickets, statt ein langlebiges Bearer-Token in einer Ereignisstream-URL zu platzieren.
- Modell-Worker sind an Loopback gebunden und verwenden unabhängige zufällige Bearer-Secrets.
- Die Memory-API kann auf unterstützten Pfaden ein eigenes generiertes Token verwenden.

Der Server erlaubt derzeit CORS von `*`. Die JWT-Authentifizierung schützt authentifizierte HTTP-Routen weiterhin, aber die freizügige CORS-Konfiguration ist ein weiterer Grund, das Backend nicht direkt einem nicht vertrauenswürdigen Netzwerk zugänglich zu machen.

### gRPC-Einschränkung

Derzeit ist nur der Skills-gRPC-Dienst registriert. Er übernimmt nicht die HTTP-JWT-Middleware von Fiber. Belasse den gRPC-Listener auf Loopback oder setze eine unabhängig authentifizierte Schutzschicht davor. Port `50051` darf nicht aufgrund von Annahmen, die für die HTTP-API gelten, nach außen freigegeben werden.

## Sicherheitsgrenzen

### Localhost ist eine Standardeinstellung, keine Firewall

HTTP (`127.0.0.1:8080`), Skills-gRPC (`127.0.0.1:50051`) und das lokale Modell-Gateway (`127.0.0.1:8091`) sind standardmäßig an Loopback gebunden. Eine Änderung des konfigurierten HTTP-Hosts kann auch den gRPC-Listener betreffen. Wenn Fernzugriff erforderlich ist, ergänze Firewall, TLS-Terminierung, starke Authentifizierung und eine ausdrückliche Proxy-Richtlinie, statt direkt an alle Schnittstellen zu binden.

### PhiloBot ist keine Betriebssystem-Sandbox

Dateiwerkzeuge lösen symbolische Links auf und prüfen Pfade gegen zulässige Projekt-Wurzelverzeichnisse. Der Zugriff außerhalb dieser Verzeichnisse kann eine ausdrückliche Sitzungsberechtigung erfordern; privilegierte Launcher wie `sudo`, `su` und `doas` sind gesperrt.

Diese Kontrollen schränken einen Prozess nicht auf Betriebssystemebene ein. Zulässige Programme – darunter Python-, Go-, Node-, Dart- und Flutter-Werkzeuge – laufen mit denselben Betriebssystemberechtigungen wie PhiloEngine und können Pfade in ihren eigenen Argumenten oder in Code auswerten. Verwende für nicht vertrauenswürdige Repositories und Befehle einen Container, eine VM, ein eingeschränktes Betriebssystemkonto oder eine andere echte Sandbox.

### Der Schutz beim Abrufen von Webinhalten hat Grenzen

Die URL-Prüfung akzeptiert HTTP(S) und lehnt Loopback-, private, linklokale sowie Carrier-Grade-NAT-Ziele ab. Das reduziert SSRF-Risiken, aber DNS kann sich zwischen Prüfung und Verbindungsaufbau ändern. Der Fetcher darf nicht als gehärtete Schutzgrenze für eine feindliche mandantenfähige Nutzung betrachtet werden.

### Modellcode ist eine Vertrauensentscheidung

Transformers-Worker fordern lokale Dateien an und setzen gängige Offline-Flags. Von einem Repository bereitgestellter Remote-Code ist standardmäßig deaktiviert, kann aber für jedes Modell ausdrücklich als vertrauenswürdig eingestuft werden. Wird diese Option aktiviert, darf Modellcode mit den Betriebssystemberechtigungen des Worker-Prozesses ausgeführt werden.

## Integrität von Updates

Der Release-Updater verwendet vertrauenswürdige HTTPS-Hosts, prüft die angegebene Downloadgröße und SHA-256-Prüfsumme, lehnt unsichere Archivpfade/symbolische Links ab, führt die Installation atomar gestuft durch und kann nach einem unmittelbaren Startfehler ein Rollback ausführen.

Die Authentizität der Prüfsumme hängt jedoch letztlich vom heruntergeladenen Manifest ab. Das Manifest enthält ein reserviertes Feld `signature`, doch der untersuchte Updater verifiziert es nicht. Deshalb gilt:

- Releases sind als **prüfsummenverifiziert**, nicht als kryptografisch signiert zu beschreiben;
- Artefakte sollten unabhängig verifiziert werden, wenn der Distributionskanal Teil des Bedrohungsmodells ist;
- ein automatisches Rollback schützt nicht vor einem bösartigen, aber korrekt mit einer Prüfsumme versehenen Bundle.

## Praktische Datenschutz-Checkliste

- Belasse alle Listener auf Loopback, sofern eine externe Erreichbarkeit nicht bewusst abgesichert wurde.
- Verwende für vertrauliche lokale Daten ein eigenes Betriebssystemkonto und eine Festplattenvollverschlüsselung.
- Prüfe Anbieter und Embedding-Backend, bevor du vertrauliche Prompts sendest.
- Behandle gespeicherte Zusammenfassungen auch dann als vertraulich, wenn der ursprüngliche Chat gelöscht wurde.
- Lasse `trust_remote_code` für nicht geprüfte Modelle deaktiviert.
- Führe nicht vertrauenswürdige Projektbefehle in einer echten Sandbox aus.
- Prüfe ausgehende Verbindungen, bevor du eine Offline-Bereitstellung zusicherst.
- Nimm niemals JWTs, API-Schlüssel, TOTP-Secrets, Memory-Tokens oder vollständige private Prompts in Fehlerberichte auf.

Unter [Architektur](ARCHITECTURE.md) findest du die Komponentengrenzen, unter [Fehlerbehebung](TROUBLESHOOTING.md) sichere Diagnosebefehle.
