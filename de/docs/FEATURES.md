# Funktionen und aktueller Stand

Diese Seite zeigt, was heute funktioniert. „Verfügbar“ heißt: Der Ablauf ist nutzbar. „Beta“ heißt: Die Funktion ist da, wird aber noch weiter verbessert. „Experimentell“ heißt: Daran wird gerade gebaut, verlassen kann man sich darauf nicht.

## Was verfügbar ist

| Bereich | Status | Was du damit machen kannst |
|:---|:---:|:---|
| Lokale Modelle | Verfügbar · Phase 1 Beta | GGUF-Modelle über `llama.cpp` ausführen, mit CUDA, Vulkan, SYCL, Metal oder CPU. |
| API-Anbieter | Verfügbar · Phase 1 Beta | OpenRouter und Featherless anbinden; Schlüssel bleiben in den lokalen Einstellungen. |
| Eigene Anbieter-Verbindungen | Verfügbar · Phase 1 Beta | Eigenen OpenAI-kompatiblen Endpunkt eintragen; der Schlüssel wird verschlüsselt gespeichert und nie wieder im Klartext angezeigt. |
| Gastmodus | Verfügbar · Phase 1 Beta | Ohne Konto starten und die Gast-Chats und -Einstellungen später in ein neues Konto übernehmen. |
| Hardware-Planung | Verfügbar · Phase 1 Beta | RAM und VRAM prüfen, Kontextgröße planen und bei Bedarf eine kleinere Konfiguration versuchen. |
| Scouts | Verfügbar · Phase 1 Beta | Projektbezogene Assistenten mit Planung, Werkzeugen, Berechtigungen und prüfbaren Diffs. |
| Memory | Verfügbar · Phase 1 Beta | Kontext pro Benutzer und Projekt in SQLite speichern und wiederfinden. |
| Marktplatz | Verfügbar · Phase 1 Beta | Hugging-Face-Downloads und gehostete Modelle gemeinsam anzeigen, inklusive Eignungsdaten. |
| CulpeoSearch | Verfügbar · Phase 1 Beta | Öffentliche Quellen durchsuchen und Seiten als Markdown aufbereiten. |
| News | Beta | KI- und Technik-Feeds mit Suche, Filtern und gespeicherten Artikeln. |
| Benchmark | Beta | LMArena-Ranglisten, Kategorien, Vergleiche und aktualisierte Snapshots. |
| Culpeo Node | **Experimentell** | Soll Modelle auf einem anderen Rechner ausführen. Unfertig und instabil; liegt im Repository, weil daran entwickelt wird, nicht weil es funktioniert. Siehe [NODE.md](../../docs/NODE.md). |

![Chat-, Marktplatz-, News- und Benchmark-Ansichten in Culpeo Studio](../assets/screenshots/chat.png)

## Details

### Lokale Engine

Die Engine scannt das Modellverzeichnis, prüft den Rechner und plant den Start, bevor ein Worker gestartet wird. Passt die GPU-Konfiguration nicht, kann sie den Kontext verkleinern oder auf die CPU ausweichen. Die Worker laufen lokal über Loopback und ein Bearer-Token.

### Scouts und Projekte

Scouts können einen eigenen Prompt, Trigger, ein Modell und ein Projektverzeichnis haben. Dateiwerkzeuge bleiben auf freigegebene Projektpfade beschränkt. Änderungen erscheinen zunächst als Diff. Ein planender Scout schlägt den Plan zuerst vor, wartet auf die Freigabe und arbeitet ihn danach als Abarbeitungsliste ab, die auch einen unterbrochenen Lauf übersteht.

### Chats und Sitzungen

Ein Chat wird von dem Modell benannt, das den ersten Austausch beantwortet hat — in der Seitenleiste steht damit das Thema statt der Eingangsnachricht; von Hand umbenennen geht jederzeit. Füllt eine Unterhaltung etwa vier Fünftel des Kontextfensters, werden die älteren Turns zu einer laufenden Zusammenfassung verdichtet: der Verlauf behält jede Nachricht, nur das Modell bekommt die gefaltete Fassung. Die Antwortlänge wird pro Turn gegen den verbleibenden Platz gedeckelt.

### Memory und Suche

Chats, Beobachtungen und Zusammenfassungen liegen in SQLite. Die Suche verbindet klassische FTS5-Textsuche mit Vektorähnlichkeit. Standardmäßig wird ein lokaler deterministischer 128-dimensionaler Hash verwendet; ONNX und weitere Backends sind möglich.

### Marktplatz

Lokale Modelle werden über Hugging Face gesucht und heruntergeladen. Gehostete Modelle kommen über OpenRouter und Featherless. Je nach Anbieter zeigt eine Karte Format, Kontext, Preis oder Hardware-Eignung.

### Culpeo Node (experimentell)

Ein eigenes Backend, das Modelle auf einem anderen Rechner ausführen soll, gekoppelt über eine gepinnte TLS-Verbindung. Es ist unfertig: Kopplung, entfernte Downloads und entfernte Inferenz entstehen gerade und ändern sich ohne Ankündigung. Node gehört nicht zur Beta.

## Geplante Arbeiten

- **Phase 2:** Profile für entfernte Server und hybrides Routing.
- **Phase 3:** Geführte LoRA/QLoRA- und Quantisierungs-Workflows.
- **Phase 4:** Lokale Bild-/Videoerzeugung und ein Workspace für Spieleentwicklung.
- **Phase 5:** Optionales, verschlüsseltes Teilen selbst gehosteter Modelle und Rechenleistung.
