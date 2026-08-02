# PhiloEngine Transparenz

**Deutsch** · [English](../../docs/TRANSPARENCY.md)

> [!NOTE]
> PhiloEngine verbindet lokale Ausführung mit optionalen Online-Diensten. Diese
> Seite erklärt, warum es diese Wege gibt und wie KI-Werkzeuge die Entwicklung
> unterstützen. Sie beschreibt Designentscheidungen – sie ist keine Empfehlung
> für jedes Modell, jeden Datensatz oder jedes Ergebnis eines eingebundenen
> Dienstes.

[← README](../README.md) · [Datenschutz & Netzwerkgrenzen](PRIVACY.md) · [Mitwirken](../CONTRIBUTING.md)

## Kurz gesagt

- Lokale Laufzeiten sind der bevorzugte Weg, wenn Datenschutz, Kontrolle oder
  Offline-Nutzung wichtig sind.
- Gehostete Anbieter bleiben optional, wenn ein Modell oder eine Aufgabe nicht
  zur vorhandenen Hardware passt.
- Mehrere Wege erhalten die Wahlfreiheit und verringern die Abhängigkeit von
  einer einzelnen Laufzeit, einem Katalog oder Anbieter.
- Öffentliche Such-, News- und Benchmarkquellen ergänzen aktuelle externe
  Informationen; sie gelten nicht automatisch als zweifelsfreie Wahrheit.
- KI unterstützt Teile der Projektentwicklung. Menschen bleiben jedoch für
  Entscheidungen, Prüfung, Tests, Sicherheit, Lizenzen und Releases
  verantwortlich.

## Warum PhiloEngine mehrere Wege unterstützt

Es gibt keinen Inferenzweg, der für jeden Rechner und jede Aufgabe am besten
ist. Ein kompaktes quantisiertes Modell auf einem Notebook, ein auf Durchsatz
ausgelegter GPU-Server und eine gelegentliche Anfrage an ein gehostetes Modell
stellen unterschiedliche Anforderungen. PhiloEngine soll den gewählten Weg
deshalb sichtbar und auswählbar machen, statt unbemerkt jede Aufgabe über ein
einziges Unternehmen oder eine einzige Laufzeit zu leiten.

Die wichtigsten Auswahlkriterien sind:

| Kriterium | Bedeutung in PhiloEngine |
|---|---|
| **Wahlfreiheit** | Nutzer können lokale Inferenz, einen eingerichteten Online-Anbieter und ein passendes Modell wählen. Eine vorhandene Integration ist nicht automatisch die Standardempfehlung. |
| **Lokale Kontrolle** | Bei lokaler Ausführung bleiben Modelldateien und Inferenz auf der vom Nutzer kontrollierten Hardware – abgesehen von separat aktivierten Online-Werkzeugen und entfernten Embedding-Diensten. |
| **Hardware-Eignung** | Unterschiedliche Laufzeiten decken verschiedene Modellformate, Beschleuniger, Speichergrenzen und Leistungsprofile ab. Die Engine kann verfügbaren RAM und VRAM einplanen. |
| **Reichweite** | Gehostete Kataloge und Anbieter erschließen weitere Modelle, wenn Download oder lokale Ausführung unpraktisch sind. |
| **Ausfallsicherheit** | Mehr als ein Weg verringert die Abhängigkeit von einer einzelnen Laufzeit oder einem Dienst. Das garantiert nicht, dass externe Dienste immer verfügbar oder austauschbar sind. |
| **Sichtbare Grenzen** | Netzwerkgestützte Aktionen sollen erkennbar sein, damit Nutzer selbst über die Eignung für ihre Daten und Umgebung entscheiden können. |

## Warum diese Laufzeiten und Dienste enthalten sind

### Lokale Laufzeiten

| Laufzeit | Warum sie nützlich ist |
|---|---|
| **llama.cpp** | Ein praxistauglicher lokaler Weg für quantisierte Modelle und viele Arten von Consumer-Hardware, auch wenn Speichereffizienz wichtig ist. |
| **vLLM** | Ein Weg für beschleunigerorientiertes Serving und Aufgaben, bei denen effiziente Anfrageplanung und Durchsatz wichtig sind. |
| **Transformers** | Ein flexibler Weg für Modellarchitekturen und Arbeitsabläufe aus dem breiteren Transformers-Ökosystem. |

Diese Laufzeiten ergänzen einander. Ihre Einbindung ist kein Versprechen, dass
jedes Modell mit jeder Laufzeit, jedem Betriebssystem oder Beschleuniger
funktioniert. Die Kompatibilität hängt weiterhin von Modell, Format,
Laufzeitversion und lokaler Hardware ab.

### Modellsuche, Downloads und öffentliche Daten

**Hugging Face** erschließt dem Marketplace ein breites Modell-Ökosystem,
Artefakt-Metadaten, Modelldateien und ausgewählte öffentliche Datensätze für
unterstützte Funktionen. Dadurch kann PhiloEngine Modelle auffindbar und
beziehbar machen, ohne selbst jedes Artefakt zu spiegeln. Eine Auflistung ist
keine Freigabe hinsichtlich Sicherheit, Qualität oder Lizenz: Vor der Nutzung
sollten Modellkarte, Lizenz, Herausgeber, Dateien und eine mögliche Anforderung
an fremden Modellcode geprüft werden.

### Optionale gehostete Inferenz

**OpenRouter** bietet einen optionalen Zugang zu einem breiten Katalog
gehosteter Modelle über eine Integration. **Featherless** stellt einen weiteren
optionalen Weg für gehostete Inferenz bereit. Diese Wege sind nützlich, wenn ein
Modell lokal nicht passt, eine andere Modellfamilie benötigt wird oder Nutzer
sich für eine Aufgabe bewusst für gehostete Ausführung entscheiden.

Gehostete Anbieter erhalten die für eine Anfrage benötigten Informationen.
Dazu können Prompts, ausgewählter Kontext oder Erinnerungen, Werkzeugergebnisse,
Generierungseinstellungen und die für die jeweilige API erforderlichen
Zugangsdaten gehören. Zusätzlich gelten deren eigene Bedingungen, Verfügbarkeit,
Preise, Aufbewahrungs- und Datenschutzregeln. Für lokale Inferenz ist keiner
dieser Anbieter erforderlich. Vor dem Senden vertraulicher Inhalte sollte die
[Datenschutz- und Netzwerkübersicht](PRIVACY.md) gelesen werden.

### Such-, News- und Benchmarkquellen

PhiloEngine kann öffentliche Suchmaschinen, RSS-/Atom-Feeds, Webseiten und
öffentliche Benchmarkdatensätze ansprechen. Je nach ausgewählter Funktion
können dazu Suchdienste wie DuckDuckGo, Brave, Google, Bing oder Wikipedia,
öffentliche News-Angebote sowie über Hugging Face bereitgestellte öffentliche
Leaderboard-Daten gehören.

Sie erfüllen unterschiedliche Aufgaben:

- **Suche** ruft Informationen passend zu einer Anfrage ab.
- **News** bringt zeitabhängige öffentliche Berichte in eine native Ansicht.
- **Benchmarks** liefern ein externes Vergleichssignal für Modelle.

Externe Inhalte können unvollständig, veraltet, verzerrt, falsch bezeichnet
oder vorübergehend nicht erreichbar sein. Ein Benchmark-Rang beweist nicht,
dass ein Modell für jeden Nutzer das beste ist. Auch ein Suchrang oder eine
News-Auflistung ist keine redaktionelle Empfehlung durch PhiloEngine. Wichtige
Aussagen sollten anhand geeigneter Primärquellen überprüft werden.

Das aktuelle Benchmark-Modul verwendet den Datensatz
[LMArena Leaderboard Dataset](https://huggingface.co/datasets/lmarena-ai/leaderboard-dataset)
von `lmarena-ai`, bereitgestellt unter
[Creative Commons Namensnennung 4.0](https://creativecommons.org/licenses/by/4.0/deed.de).
PhiloEngine lädt ausgewählte Parquet-Shards aus dem Hugging-Face-Hub-Repository
des Datensatzes und filtert, ordnet, sortiert, speichert und zeigt die Daten in
einer eigenen Oberfläche an. Diese Verarbeitungs- und Darstellungsschritte sind
Änderungen durch PhiloEngine und können von der Darstellung an der Quelle
abweichen. Die Namensnennung bedeutet nicht, dass LMArena PhiloEngine
finanziert, freigegeben oder empfohlen hat.

## Unabhängigkeit und wirtschaftliche Beziehungen

Integrationen werden wegen technischer Abdeckung, Wahlfreiheit,
Hardware-Eignung, Reichweite und Ausfallsicherheit ausgewählt. Ihre Einbindung
ist weder als bezahltes Ranking noch als Beleg dafür zu verstehen, dass ein
Anbieter PhiloEngine finanziert oder freigegeben hat. Diese Seite behauptet
keine bezahlte Empfehlung und keine exklusive Anbieterbeziehung. Sollte künftig
ein Sponsoring, eine Affiliate-Beziehung oder eine andere wesentliche
wirtschaftliche Verbindung eine Empfehlung beeinflussen, sollte dies direkt
bei der betreffenden Empfehlung klar offengelegt werden.

Dienstnamen gehören ihren jeweiligen Inhabern. Integrationen und verfügbare
Quellen können sich ändern, wenn APIs, Bedingungen, technische Kompatibilität
oder Projektanforderungen sich weiterentwickeln.

PhiloEngine selbst soll kostenlos und Open Source bleiben. Die für Phase 5
geplante Möglichkeit, selbst gehostete Modelle und Rechenleistung zu teilen,
verschiebt keine vorhandene lokale Funktion hinter eine Bezahlschranke.
Externe Anbieter, Hosting, Strom oder unabhängig betriebene Infrastruktur
können außerhalb der PhiloEngine-Software weiterhin Kosten verursachen; private
Ressourcen werden nicht automatisch freigegeben.

## KI-Unterstützung bei der Projektentwicklung

Als Projektentwickler nutze ich selbst KI-gestützte Werkzeuge bei der Arbeit an
PhiloEngine. Ich lege diese Nutzung offen, weil auch der Entstehungsprozess
wichtig ist und Verantwortung nicht an ein Modell abgegeben werden kann. Zu
meinen derzeitigen Einsatzbereichen gehören:

| Bereich | Wie KI meine Arbeit unterstützt |
|---|---|
| **Frontend-Entwicklung** | Flutter-/UI-Code, Layouts, Komponenten, Interaktionen, Texte und Verbesserungen der Barrierefreiheit entwerfen und überarbeiten |
| **Debugging und Fehlersuche** | Fehler, Logs, Stacktraces und fehlschlagende Abläufe untersuchen, mögliche Ursachen eingrenzen und gezielte Prüfungen oder Korrekturen vorschlagen |
| **Sicherheits- und Penetrationstests** | Bei Bedrohungsanalysen und kontrollierten Angriffsszenarien gegen PhiloEngine und ausdrücklich autorisierte Umgebungen unterstützen, um mögliche Schwachstellen, unsichere Eingaben, fehlerhafte Berechtigungen und offengelegte Vertrauensgrenzen zu finden; Verdachtsfälle müssen von einem Menschen reproduziert, bewertet und bearbeitet werden |
| **Uploads und Veröffentlichungen** | Uploadschritte, Release-Hinweise, Checklisten und Prüfungen vorbereiten; der tatsächliche Upload oder die Veröffentlichung bleibt eine bewusste menschliche Handlung |
| **Dokumentation und Übersetzung** | Dokumentation für Nutzer und Entwickler entwerfen, redigieren, neu strukturieren und übersetzen |
| **Projektumstrukturierung** | Klarere Module, Verzeichnisse, Zuständigkeiten und Migrationsschritte planen, bevor die Projektstruktur verändert wird |
| **Codebereinigung und Refactoring** | Stark verflochtenen, historisch gewachsenen oder als „Spaghetticode“ bezeichneten Code in kleinere und verständlichere Einheiten zerlegen und dabei das beabsichtigte Verhalten prüfen |

Dabei handelt es sich um interne, KI-unterstützte Entwicklungs- und
Sicherheitsprüfungen. Solange ein gesonderter, überprüfbarer Bericht nicht
ausdrücklich etwas anderes festhält, sind sie **keine** unabhängige
Sicherheitsprüfung, Zertifizierung oder externe professionelle
Penetrationsprüfung. Sie können nicht belegen, dass PhiloEngine frei von
Schwachstellen ist.

KI entscheidet nicht selbstständig, was hochgeladen, veröffentlicht, gemergt
oder als Release freigegeben wird. Sie liefert Vorschläge, Entwürfe,
Erklärungen und mögliche Lösungen, die ich prüfe und überarbeite. Diese
Offenlegung bedeutet außerdem nicht, dass jeder Teil von PhiloEngine durch KI
entstanden ist. Die konkret eingesetzten Werkzeuge, Anbieter und Modelle können
wechseln und werden deshalb nicht als festes Inventar dargestellt.

## Die menschliche Prüfstufe

Menschen bleiben für alle Inhalte verantwortlich, die in das Projekt
übernommen werden. KI-erzeugte oder KI-veränderte Arbeit gilt als Vorschlag,
nicht als Beweis für die Korrektheit einer Änderung.

Bevor eine Änderung angenommen oder veröffentlicht wird, soll ein Mensch:

1. entscheiden, ob die Änderung in das Projekt gehört;
2. den tatsächlichen Diff und die Auswirkungen auf den umgebenden Code oder
   Inhalt prüfen;
3. die relevanten Tests und Build-Prüfungen ausführen und bewerten;
4. Sicherheit, Datenschutz, Fehlerfälle und Datengrenzen untersuchen;
5. Lizenzen, Namensnennungen und Herkunft prüfen, wenn externes Material
   betroffen ist; und
6. die endgültige Merge- und Release-Entscheidung treffen.

PhiloEngine verwendet eine KI-Antwort nicht als ungeprüfte automatische
Veröffentlichungs- oder Release-Entscheidung. Auch bestandene Tests ersetzen
keine menschliche Beurteilung: Die Testabdeckung kann unvollständig sein und
generierter Code kann plausibel wirken, obwohl er unsicher oder falsch ist.

Mitwirkende dürfen KI-Werkzeuge einsetzen. Für ihre Beiträge gelten trotzdem
dieselben Anforderungen an Prüfung, Verifikation, Sicherheit, Lizenzen und
Sign-off. Der [Beitragsleitfaden](../CONTRIBUTING.md) beschreibt die
projektweiten Erwartungen.

## Fragen und Korrekturen

Transparenzdokumentation sollte angepasst werden, sobald sich Implementierung
oder Projektpraxis ändern. Wenn diese Seite unvollständig ist oder nicht mehr
zum beobachtbaren Verhalten passt, kann die konkrete Abweichung gemeldet
werden – ohne Geheimnisse, private Prompts, Zugangsdaten oder persönliche Daten
beizufügen.
