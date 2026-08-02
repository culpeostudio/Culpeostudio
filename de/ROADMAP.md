<h1 align="center">PhiloEngine Roadmap</h1>

<p align="center">
  <strong>Auf dem Vorhandenen aufbauen, es sorgfältig verbessern und neue Möglichkeiten in klaren Phasen öffnen.</strong>
</p>

<p align="center">
  <strong>Deutsch</strong> · <a href="../ROADMAP.md">English</a>
</p>

<p align="center">
  <img alt="Roadmap-Status: Phase 1" src="https://img.shields.io/badge/aktuell-Phase%201-C9A24A?style=for-the-badge&amp;labelColor=0A0A0B">
  <img alt="Projektreife: Alpha" src="https://img.shields.io/badge/Reifegrad-Alpha-F59E0B?style=for-the-badge&amp;labelColor=0A0A0B">
</p>

> **Zuletzt aktualisiert:** 2. August 2026  
> Diese Roadmap wird laufend gepflegt. Sie beschreibt Richtung und
> Abhängigkeiten, aber keine garantierten Veröffentlichungstermine.

[← Deutsche README](README.md) · [Funktionen](docs/FEATURES.md) · [Installation](docs/INSTALLATION.md) · [Mitwirken](CONTRIBUTING.md)

> [!NOTE]
> Abgehakte Punkte beschreiben den aktuellen Entwicklungsstand, nicht
> automatisch das neueste veröffentlichte Paket. Prüfe die zugehörigen
> Release-Hinweise, bevor du einen Roadmap-Punkt als ausgeliefert betrachtest.

## Die Roadmap auf einen Blick

~~~mermaid
timeline
    title PhiloEngine-Entwicklung — fünf aufeinander aufbauende Phasen ohne feste Termine
    JETZT — Phase 1 : Vorhandene Module festigen
                     : Frontend-Überarbeitung abschließen
                     : Fehler beheben und Dokumentation stärken
    DANACH — Phase 2 : Aktuelle Funktionen erweitern und verbessern
                      : Externe Server mit Chat und Engine verbinden
                      : Zuverlässigkeit, Performance und Barrierefreiheit vertiefen
    SPÄTER — Phase 3 : Full-Finetuning und Finetuning geführt anbieten
                     : Quantisierung geführt und leicht nutzbar machen
                     : Jobs reproduzierbar und wiederherstellbar halten
    ZUKUNFT — Phase 4 : Bild- und Videogenerierung ergänzen
                      : Arbeitsbereich für Spieleentwicklung ausarbeiten
                      : Lokale und optionale gehostete Laufzeiten nutzen
    LANGFRISTIG — Phase 5 : Selbst gehostete Modelle freiwillig teilen
                           : Rechenleistung sicher bereitstellen
                           : PhiloEngine selbst kostenlos und Open Source halten
~~~

<details>
<summary><strong>Textfassung des Zeitstrahls</strong></summary>

1. **Phase 1 — jetzt:** vorhandene Module festigen, die Frontend-Überarbeitung
   abschließen, Fehler beheben, Bedienbarkeit verbessern und die Dokumentation
   fertigstellen.
2. **Phase 2 — danach:** bestehende Funktionen erweitern und verbessern sowie
   eingerichtete externe Server in Chat und Engine nutzbar machen.
3. **Phase 3 — später:** geführte, leicht nutzbare Abläufe für Full-Finetuning,
   weitere Finetuning-Wege, Modellkonvertierung und Quantisierung bereitstellen.
4. **Phase 4 — Zukunft:** Bild- und Videogenerierung zusammen mit einem eigenen
   Arbeitsbereich für Spieleentwicklung ausarbeiten.
5. **Phase 5 — langfristig:** Nutzern erlauben, selbst gehostete KI-Modelle und
   Rechenleistung freiwillig bereitzustellen und dabei dem Projektversprechen
   zu folgen, die PhiloEngine-Software kostenlos und Open Source zu halten.

</details>

| Phase | Einordnung | Hauptergebnis |
|:---|:---:|:---|
| **Phase 1** | Jetzt | Eine stimmige und zuverlässige Fassung des bereits vorhandenen Produkts |
| **Phase 2** | Danach | Vertiefte bestehende Funktionen und nutzbare externe Serververbindungen |
| **Phase 3** | Später | Geführtes Full-Finetuning, Finetuning und Quantisieren |
| **Phase 4** | Zukunft | Abläufe für Bild, Video und Spieleentwicklung |
| **Phase 5** | Langfristig | Freiwilliger Zugriff auf selbst gehostete Modelle und geteilte Rechenleistung |

Die Reihenfolge beschreibt Abhängigkeiten. Eine spätere Phase beginnt erst,
wenn die vorherige Grundlage zuverlässig genug dafür ist.

## 🟡 Phase 1 — das vorhandene Produkt festigen

**Ziel:** Den bereits vorhandenen Stand verbessern, statt jede neue Idee sofort
als aktive Entwicklung darzustellen.

### Vorhandene Grundlage

- [x] Chat mit lokalen Modellinstanzen
- [x] Chat mit unterstützten OpenRouter- und Featherless-Modellen
- [x] Hardwareerkennung, Speicherplanung und verwaltete lokale Laufzeiten
- [x] Marketplace für lokale Downloads und unterstützte API-Modelle
- [x] PhiloBots, Projekte, Toolereignisse, Berechtigungen und lesbare Diffs
- [x] Nutzer- und projektbezogene Memory-Infrastruktur
- [x] Text-Metasuche und Aufbereitung öffentlicher Webseiten
- [x] News mit Feeds, Filtern, Suche und gespeicherten Artikeln
- [x] LMArena-Text-Benchmark mit Übersicht, Ranking, Details und Vergleich
- [x] Authentifizierung, Einstellungen, Deutsch/Englisch sowie Classic/Lite
- [x] Grundlagen für plattformübergreifende Releases und Updates

### Aktuelle Arbeiten

- [ ] Visuelle und funktionale Überarbeitung des vorhandenen Frontends abschließen
- [ ] Bestehende Funktionen verbessern und unvollständige Abläufe fertigstellen
- [ ] Bekannte Fehler beheben und Regressionen mit gezielten Tests verhindern
- [ ] Navigation, responsive Layouts sowie Lade-, Leer- und Fehlerzustände vereinheitlichen
- [ ] Performance und Barrierefreiheit dort verbessern, wo die aktuelle Oberfläche es benötigt
- [ ] Englische und deutsche Dokumentation vollständig und konsistent halten
- [ ] Releasepakete, Updates, Rollback und Offline-Neustart überprüfen

### Aktive Arbeitsbereiche

| Arbeitsbereich | Angestrebtes Ergebnis |
|:---|:---|
| **Frontend-Überarbeitung** | Eine einheitliche und verständlichere Oberfläche in allen vorhandenen Modulen |
| **Funktionsverbesserung** | Vorhandene Bedienelemente und Abläufe funktionieren vollständig und vorhersehbar |
| **Fehlerbehebung** | Bekannte Fehler und Regressionen werden reproduziert, behoben und durch Tests abgesichert |
| **Dokumentation** | README, Roadmap, Installation, Datenschutz, Architektur und Hilfe bleiben auf demselben Stand |
| **Releasebereitschaft** | Unterstützte Pakete starten, aktualisieren und erholen sich wie dokumentiert und funktionieren offline |

### Abschlusskriterien für Phase 1

Phase 2 beginnt, wenn:

- die Frontend-Überarbeitung in allen verfügbaren Modulen stimmig ist;
- sichtbare Kernfunktionen vollständig arbeiten oder klar als nicht verfügbar
  gekennzeichnet sind;
- kein bekannter kritischer Fehler bei Anmeldung, Datenverlust, Updates oder
  Projektgrenzen offen ist;
- News und Benchmark sicher reagieren, wenn eine externe Quelle nicht verfügbar ist;
- unterstützte Releasepakete ihre Prüfungen bestehen;
- die englische und deutsche Dokumentation dem veröffentlichten Stand entspricht.

Es gibt keinen festen Abschlusszeitpunkt. Stabilität und eine verständliche
Bedienung sind wichtiger als ein künstlicher Termin.

## 🔵 Phase 2 — vorhandene Funktionen erweitern und externe Server anbinden

**Ziel:** Das bestehende Produkt vertiefen und entfernte Systeme als bewussten,
testbaren Teil der normalen Abläufe nutzbar machen.

| Geplanter Bereich | Angestrebtes Ergebnis |
|:---|:---|
| Vorhandene Module | Vollständigere Abläufe für Chat, Engine, Marketplace, Memory, Suche, News, Benchmark, PhiloBot und Einstellungen |
| Externe Server | Gespeicherte und geprüfte Serverprofile können als aktive Chat- oder Engine-Verbindung verwendet werden |
| Verbindungskontrolle | Klare Informationen zu Endpunkt, Authentifizierung, Fähigkeiten, Zustand, Latenz und Fehlern |
| Laufzeit- und Hardwareabdeckung | Zuverlässigerer Betrieb mit realen GPUs, Treibern, Modellformaten und CPU-Systemen |
| Performance | Schnellerer Start, geringerer UI-Overhead und flüssigere große Modellkataloge |
| Barrierefreiheit | Bessere Tastaturbedienung, Fokusführung, Kontraste, Skalierung und Screenreader-Unterstützung |
| Zuverlässigkeit | Stärkere Wiederherstellung, Migration, Updateprüfung und Integrationstests |

Die Einbindung externer Server muss immer sichtbar bleiben. Nutzer sollen
erkennen können, welcher Server eine Anfrage verarbeitet und ob Daten den
lokalen Rechner verlassen.

## 🟣 Phase 3 — geführtes Finetuning und Quantisieren

**Ziel:** Fortgeschrittene Modellarbeit leicht nutzbar machen, ohne die nötigen
Optionen für erfahrene Nutzer zu verstecken.

### Full-Finetuning und Finetuning

- Geführte Projekteinrichtung von der Datensatzauswahl bis zum exportierbaren Ergebnis
- Import, Prüfung und Aufbereitung von Datensätzen mit verständlichen Fehlermeldungen
- Bewusste Wahl zwischen Full-Finetuning und ressourcenschonenderen Finetuning-Wegen
- Hardware- und Speicherprüfung vor dem Start eines Jobs
- Reproduzierbare Konfiguration, Checkpoints, Pause, Fortsetzen, Abbruch und Wiederherstellung
- Auswertung, Herkunftsnachweis und Vergleich mit dem Ausgangsmodell
- Einfache Standardwerte mit optionalem Expertenpfad

### Quantisierung und Konvertierung

- Geführte Auswahl von Ausgangsmodell, Zielformat und Quantisierungsstufe
- Verständliche Abwägung zwischen Qualität, Größe, Speicherbedarf und Kompatibilität
- Hardwarebezogene Vorprüfung und Speicherplanung
- Reproduzierbare Konvertierungsjobs mit Fortschritt, Logs, Abbruch und Wiederherstellung
- Prüfung des erzeugten Modells, bevor es der Engine hinzugefügt wird

Die aktuellen Seiten für Training und Quantisierung sind gesperrte
Designvorschauen. Sie starten derzeit keine Backend-Jobs.

## ⚫ Phase 4 — Bild, Video und Spieleentwicklung

**Ziel:** PhiloEngine über Sprachmodelle hinaus erweitern und dabei sichtbare
Laufzeitentscheidungen, Hardwareplanung und Local-first-Kontrolle beibehalten.

### Bild- und Videogenerierung

- Lokale und optionale providerbasierte Generierung
- Sichtbare Modelle, Laufzeiten, Parameter, Speicherung und Herkunft
- Wiederverwendbare Abläufe für Generierung, Überarbeitung und Export
- Hardwarebezogene Planung und wiederherstellbare Jobs

### Arbeitsbereich für Spieleentwicklung

- Eigenes Modul für unterstützte Abläufe bei der Spieleentwicklung
- Geordnete Erzeugung und Überarbeitung von Projekt-Assets
- Projektbezogene Unterstützung für Konzepte, Inhalte und Implementierungsarbeit
- Klare Exportgrenzen, ohne vorzugeben, eine vollständige Game Engine zu ersetzen

Der genaue Umfang wird weiter ausgearbeitet, sobald die Phasen 1–3 eine stabile
Grundlage bilden.

## ⚪ Phase 5 — selbst gehostete Modelle und geteilte Rechenleistung

**Ziel:** Nutzern ermöglichen, eigene gehostete KI-Modelle und Rechenleistung
freiwillig für andere bereitzustellen.

Geplante Grundsätze:

- Teilen ist standardmäßig deaktiviert und erfordert eine ausdrückliche Freigabe des Besitzers;
- Besitzer kontrollieren Modelle, Kapazität, Grenzen, Zugriff und Widerruf;
- Nutzer sehen, wo eine Anfrage verarbeitet wird und welche Daten gesendet werden;
- Authentifizierung, Isolation, Missbrauchsschutz, Jobgrenzen und Nachvollziehbarkeit
  sind Voraussetzungen für eine öffentliche Freigabe;
- die lokale Nutzung bleibt ohne Teilnahme an geteilter Rechenleistung möglich;
- kein privates Modell und kein Rechner wird automatisch bereitgestellt.

**Das aktuelle Projektversprechen lautet, die PhiloEngine-Software kostenlos
und Open Source zu halten.** Dieses Versprechen beschreibt die Projektrichtung;
es ist keine rechtliche Garantie für die zukünftige Verfügbarkeit oder
Preisgestaltung unabhängiger Dienste. Phase 5 soll vorhandene lokale Funktionen
nicht hinter eine Bezahlschranke verschieben. Externe API-Anbieter, Hosting,
Strom oder unabhängig betriebene Infrastruktur können außerhalb der
PhiloEngine-Software weiterhin Kosten verursachen.

## Kürzlich fertiggestellte Grundlagen

- Releasepakete für Linux x64, Windows x64 und macOS ARM64
- Atomare Aktivierung, Rollback und Quarantäne fehlerhafter Updates
- Deutsch/Englisch sowie Classic/Lite als kontobezogene Einstellungen
- Hardwarebezogener Marketplace und Engine-Planung
- Projektbezogene PhiloBot-Sitzungen und persistente Memory-Infrastruktur
- Native News- und Benchmark-Module im aktuellen Entwicklungsstand

## Damit die Roadmap aktuell bleibt

Die Roadmap wird aktualisiert, wenn:

1. eine geplante Funktion zur aktuellen Arbeit wird;
2. ein Release den verfügbaren Funktionsumfang ändert;
3. ein Abschlusskriterium erfüllt oder verändert wird;
4. ein geplanter Punkt entfernt, verschoben oder ersetzt wird.

Fortschrittswerte sollten nur verwendet werden, wenn sie auf messbaren Aufgaben
beruhen. Checklisten, Abschlusskriterien, Tests und Release Notes zeigen den
tatsächlichen Stand ehrlicher. Sicherheitsprobleme, Datenverlustrisiken,
fehlerhafte Updates und Regressionen können die Reihenfolge jederzeit ändern.

## Fortschritt verfolgen oder mitwirken

- Den genauen [Funktionsstatus](docs/FEATURES.md) lesen.
- Unter [GitHub Releases](https://github.com/kuchenboss/MyPhiloEngine/releases)
  prüfen, was tatsächlich veröffentlicht ist.
- Vor einem Roadmap-Beitrag den [Beitragsleitfaden](CONTRIBUTING.md) lesen.
- Sicherheitsprobleme privat nach der
  [Sicherheitsrichtlinie](https://github.com/kuchenboss/MyPhiloEngine/blob/main/SECURITY.md)
  melden.
