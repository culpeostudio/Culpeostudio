# Transparenz und Offenlegung

Diese Seite erklärt, wer Culpeo Studio entwickelt, wie KI-Werkzeuge dabei eingesetzt werden und warum bestimmte Anbieter und News-Quellen eingebunden sind.

---

## 1. Primäre menschliche Autorenschaft & Entwicklung

Culpeo Studio wird **überwiegend vom Entwickler entworfen und programmiert**.

Der überwiegende Hauptteil des Quellcodes — einschließlich des Go gRPC-Backends (`backend/`), der Flutter Desktop-Benutzeroberfläche (`frontend/`), der lokalen Inferenzsteuerung, der Formeln zur Hardware-Erkennung und der Datenbank-Anbindungen — ist **eigenhändig entwickelt**.

KI dient dabei als unterstützendes Werkzeug. Der Entwickler prüft die Ergebnisse und trägt die Verantwortung für die Software.

---

## 2. Rolle von KI als unterstützendes Werkzeug

Wenn KI-Tools eingesetzt werden, helfen sie zum Beispiel bei:

- **Sekundäre Qualitäts- & UI-Prüfung:** Unterstützung beim Aufspüren von Randfällen in Flutter-Layouts oder bei der Inspektion von Code auf potenzielle Race Conditions.
- **Sicherheits- & Penetrationstest-Ideen:** Nutzung als Sparringspartner zum Brainstorming von Sicherheits-Testvektoren, Pfad-Überschreitungsrisiken und Rechtegrenzen.
- **Beratung & Konzept-Abgleich:** Beratung bei der Abwägung von Architektur-Entscheidungen oder beim Abgleich mathematischer Formeln für RAM/VRAM-Berechnungen.
- **Repository-Verwaltung:** Unterstützung beim Entwerfen von Release-Notes, Dokumentations-Formulierung und Issue-Vorlagen.
- **Marketing- & Mediengenerierung:** Unterstützung bei der Erstellung von Grafik-Hintergründen, Splash-Screen-Illustrationen und Demo-Medien.

Finaler Code, Architekturentscheidungen und Sicherheitsänderungen werden vom Entwickler geprüft und verifiziert.

---

## 3. Beweggründe für Anbieter- & Quellenauswahl

### Marktplatz- & API-Anbieter

Culpeo Studio bindet Hugging Face, OpenRouter und Featherless in ein einheitliches Marktplatz-Raster ein:

- **Hugging Face:** Ausgewählt als primäre Quelle für lokale Modell-Downloads, da es der weltweite Open-Source-Community-Standard für das Hosten von Open-Weights-Modellen, GGUF-Quantisierungen und Modell-Metadaten ist.
- **OpenRouter:** Eingebunden, um optionalen Zugriff auf gehostete Open-Source- und proprietäre Modelle über einen einzigen API-Schlüssel bei transparenter Token-Abrechnung zu ermöglichen.
- **Featherless:** Integriert für serverlose Open-Weights-Modellinferenz, wodurch Benutzer auch Modelle testen können, die die lokale Hardwarekapazität übersteigen.

### News-Quellen & Feed-Auswahl

Das News-Modul aggregiert öffentliche KI- und Technologie-Nachrichtenquellen:

- **Auswahlkriterien:** Die Quellen werden nach ihrer technischen Relevanz für Künstliche Intelligenz, Softwareentwicklung und Hardware-Entwicklungen ausgewählt.
- **Standards:** Es werden öffentliche RSS/Atom-Feeds und konforme HTML-Extraktionen genutzt. Artikel werden lokal gecacht und datenschutzkonform aufbereitet.

---

## 4. Versprechen zum Open-Source-Status

Culpeo Studio ist und bleibt zu **100 % kostenlos und Open Source** unter der [GNU AGPL-3.0 Lizenz](../../LICENSE). Lokale Kernfunktionen bleiben unabhängig und werden nicht hinter Bezahlschranken gesperrt.
