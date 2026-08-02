# Zu PhiloEngine beitragen

**Deutsch** · [English](../CONTRIBUTING.md)

Vielen Dank, dass du dabei hilfst, PhiloEngine zu verbessern. Fehlerbehebungen,
Berichte zur Hardwarekompatibilität, gezielte Funktionsentwicklungen, Tests,
Dokumentation und Übersetzungen sind gleichermaßen wertvoll – besonders,
solange sich das Projekt in der Alpha-Phase befindet.

[← README](README.md) · [Entwicklung](docs/DEVELOPMENT.md) · [Roadmap](ROADMAP.md)

## Bevor du beginnst

- Durchsuche die vorhandenen Issues des Repositorys, bevor du ein Duplikat
  eröffnest.
- Beschreibe bei einer umfangreichen Änderung zunächst das Problem und den
  beabsichtigten Umfang, bevor du viel Arbeit in die Umsetzung investierst.
- Halte Pull Requests fokussiert. Unabhängige Refaktorierungen erschweren die
  Überprüfung und Regressionstests.
- Nimm niemals Zugangsdaten, `backend/data/`, Modellgewichte, private
  Chat-Inhalte oder nicht anonymisierte lokale Pfade in einen Commit oder ein
  Issue auf.

Sicherheitslücken dürfen nicht in einem öffentlichen Issue gemeldet werden.
Folge dem vertraulichen Verfahren in der
[Sicherheitsrichtlinie](https://github.com/kuchenboss/MyPhiloEngine/blob/main/SECURITY.md).

## Vereinbarung und Sign-off für Mitwirkende

Für alle Beiträge gilt das
[Contributor License Agreement](https://github.com/kuchenboss/MyPhiloEngine/blob/main/CLA.md).
Lies vor dem Einreichen die aktuelle Vereinbarung unter diesem Link. Füge
deinem Pull Request die folgende exakte Bestätigung aus dem aktuellen CLA hinzu:

```text
Ich habe CLA.md gelesen und stimme den Bedingungen zu.
```

Du behältst das Urheberrecht an deinem Beitrag und räumst zugleich die in diesem
projektspezifischen CLA beschriebenen Rechte ein.

Jeder Commit muss davon getrennt einen Sign-off gemäß dem
[Developer Certificate of Origin 1.1](https://developercertificate.org/)
enthalten. Lies das DCO vor dem Sign-off und erstelle dann Commits mit:

```bash
git commit -s
```

Dadurch wird ein `Signed-off-by`-Trailer mit deinem konfigurierten Git-Namen
und deiner E-Mail-Adresse ergänzt. Die Anforderungen sind nicht austauschbar:
Das CLA räumt die in `CLA.md` beschriebenen projektspezifischen Lizenzrechte
ein; mit dem DCO-Sign-off bestätigst du die Herkunft des Beitrags und dein Recht,
ihn einzureichen. Ein `Signed-off-by`-Trailer gilt nicht von selbst als
CLA-Zustimmung, und die CLA-Bestätigung im Pull Request ersetzt den DCO-Sign-off
nicht.

## Entwicklungsablauf

1. Forke das Repository und erstelle einen Branch für eine zusammenhängende
   Änderung.
2. Lies vor der Bearbeitung den umgebenden Code und die zugehörigen Tests.
3. Implementiere die kleinste vollständige Änderung, die das Problem löst.
4. Ergänze oder aktualisiere Tests für das geänderte Verhalten.
5. Aktualisiere gegebenenfalls die benutzerseitige Dokumentation und beide
   UI-Sprachen.
6. Führe die relevanten Prüfungen aus.
7. Prüfe den Diff auf Geheimnisse, generierte Ausgaben, unabhängige
   Formatierungsänderungen und versehentlich enthaltene lokale Daten.
8. Eröffne einen Pull Request, der das Problem, die Lösung und die
   durchgeführten Prüfungen erklärt.

Der [Entwicklungsleitfaden](docs/DEVELOPMENT.md) enthält Details zu Einrichtung,
Architektur und Build-Prozess.

### KI-unterstützte Beiträge

KI-gestützte Werkzeuge sind erlaubt, ihre Ausgabe wird jedoch als Vorschlag
behandelt. Die beitragende Person bleibt dafür verantwortlich, die Änderung zu
verstehen, den Diff zu prüfen, Tests auszuführen, Lizenzen und Herkunft zu
kontrollieren und alle für die Überprüfung relevanten Einschränkungen
offenzulegen. Reiche keinen generierten Code oder Text ein, den du nicht
erklären und pflegen kannst. Der Ansatz des Projekts ist unter
[Projekttransparenz](docs/TRANSPARENCY.md) dokumentiert.

## Überprüfung

Führe die Prüfungen aus, die zu deiner Änderung passen. Bei einer
bereichsübergreifenden Änderung sollten alle betroffenen Test-Suites ausgeführt
werden.

### Backend-Änderungen

```bash
cd backend
go test ./...
go build ./cmd/server
```

Bei Änderungen am Updater muss zusätzlich dessen Kommando gebaut werden:

```bash
cd backend
go build ./cmd/philo-updater
```

### Frontend-Änderungen

```bash
cd frontend
flutter analyze
flutter test
```

Hängt ein Benutzerablauf von der echten Desktop-Anwendung ab, führe den
relevanten Integrationstest auf einem unterstützten Desktop-Ziel aus:

```bash
cd frontend
flutter test integration_test/ -d linux
```

### Änderungen an Python oder Release-Werkzeugen

Vom Stammverzeichnis des Repositorys aus:

```bash
python3 -m unittest discover -s backend/engineworker -p 'test_*.py' -v
python3 -m unittest discover -s quikinstall/tests -v
```

Kompiliere geänderte Python-Einstiegspunkte mindestens mit
`python3 -m py_compile`, um die Syntax zu prüfen.

### Dokumentationsänderungen

- Stelle sicher, dass jeder relative Link ausgehend von der Datei, in der er
  steht, aufgelöst werden kann.
- Prüfe Bilder und Tabellen bei normaler GitHub-Breite und nicht nur in einem
  breiten Editor.
- Verwende zugängliche Alternativtexte, die den nützlichen Inhalt eines Bildes
  beschreiben.
- Vermeide fest eingetragene Statistiken oder Versionsnummern, die schnell
  veralten.
- Halte Befehle kopierbar und nenne ihr Arbeitsverzeichnis.

Kann eine Prüfung auf deinem System nicht ausgeführt werden, gib im Pull
Request an, welche Prüfung ausgelassen wurde und warum. Melde eine nicht
ausgeführte Prüfung nicht als bestanden.

## Anforderungen an den Code

- Bewahre die Typsicherheit von Go und Dart und gib hilfreiche Fehler zurück.
- Unterdrücke keine Fehler und ersetze eine eigentliche Ursache nicht durch
  einen allgemeinen Erfolgsstatus.
- Begrenze Netzwerk- und Dateisystemoperationen und validiere nicht
  vertrauenswürdige Eingaben.
- Halte Geheimnisse von Logs, API-Antworten, Fixtures und Prozessargumenten
  fern, soweit die zugrunde liegende Laufzeitumgebung dies erlaubt.
- Halte Flutter-Zustand und Geschäftslogik aus Widgets heraus, die nur der
  Darstellung dienen.
- Verwende lokalisierte Strings für benutzerseitige Texte auf Deutsch und
  Englisch.
- Verwende adaptive PhiloGrid-Layouts statt fest eingetragener Desktop-Breiten.
- Ergänze beim Beheben eines reproduzierbaren Fehlers einen Regressionstest.

## Checkliste für Pull Requests

- [ ] Die Änderung verfolgt einen klaren Zweck.
- [ ] Relevante Tests wurden ergänzt oder aktualisiert.
- [ ] Relevante lokale Prüfungen sind erfolgreich, oder ausgelassene Prüfungen
      sind offengelegt.
- [ ] Benutzerseitige Texte sind auf Deutsch und Englisch verfügbar.
- [ ] Die Dokumentation beschreibt das geänderte Verhalten.
- [ ] Es sind keine Zugangsdaten, Laufzeitdaten, Build-Ausgaben oder
      Modelldateien enthalten.
- [ ] Jeder Commit enthält einen `Signed-off-by`-Trailer.
- [ ] Der Pull Request enthält die erforderliche CLA-Bestätigung.

## Sicherheitsrelevante Änderungen

Änderungen an Authentifizierung, TOTP, Session-Tokens, Anbieter-Schlüsseln,
Assistenten-Werkzeugen, Befehlsausführung, entferntem Modellcode,
Update-Verifizierung oder Archiventpackung erfordern ausdrückliche Tests der
Sicherheitsgrenzen. Bewahre die Voreinstellungen mit ausschließlicher
Loopback-Bindung und lehne Zugriffe sicher ab, wenn eine
Autorisierungsentscheidung fehlt oder uneindeutig ist.

Bei einer Sicherheitslücke im aktuellen Code musst du den öffentlichen
Beitragsprozess abbrechen und stattdessen die
[Sicherheitsrichtlinie](https://github.com/kuchenboss/MyPhiloEngine/blob/main/SECURITY.md)
verwenden.

## Lizenz und Projektnamen

In dieses Repository aufgenommene Beiträge werden unter der
[GNU-AGPL-3.0-Lizenz](https://github.com/kuchenboss/MyPhiloEngine/blob/main/LICENSE)
des Projekts und den Bedingungen des CLA veröffentlicht. Die Quellcodelizenz
gewährt nicht das Recht, eine veränderte Distribution als offizielles
PhiloEngine-Produkt darzustellen. Die Regelungen zur Namensverwendung stehen
in der
[Markenrichtlinie](https://github.com/kuchenboss/MyPhiloEngine/blob/main/TRADEMARK.md).
