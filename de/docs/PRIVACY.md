# Culpeo Studio Datenschutz & Netzwerkgrenzen

Culpeo Studio arbeitet local-first: Konten, Chats, Scout-Projektdaten, Memory-Indizes und lokale Modelle bleiben auf deinem Rechner, solange eine Funktion nicht ausdrücklich einen externen Dienst braucht.

## Netzwerk-Verbindungsmatrix

| Funktion / Aktion | Ziel-Host | Übertragene Daten | Auslöser |
|:---|:---|:---|:---|
| **Lokaler Modell-Chat** | Keiner (`127.0.0.1` Loopback) | Prompts & Tokens bleiben auf dem Host | Standard bei lokalen Modellen |
| **API-Provider-Chat** | `openrouter.ai` / `api.featherless.ai` | Prompts, System-Prompts, Verlauf | Ausdrückliche Wahl eines API-Modells |
| **CulpeoSearch** | DuckDuckGo, Brave, Google, Bing, Wikipedia | Suchanfragen & Ziel-URL-Abrufe | Manuelle Suche oder Scout-Suchwerkzeug |
| **News-Modul** | Konfigurierte RSS/Atom-Feeds | HTTP GET-Abrufe | Automatisch (alle 15 Min) oder manuell |
| **Benchmark-Modul** | LMArena Öffentliche Quellen | Leaderboard-Abfragen | Start-Refresh (wenn Cache >24h) oder manuell |
| **Marktplatz-Downloads** | `huggingface.co` | Modell-Download-Anfragen | Manuell ausgelöster Download |
| **Update-Prüfer** | `raw.githubusercontent.com` / `github.com` | Manifest- & Asset-Download | Anwendungsstart |

## Scouts und Berechtigungen

> [!WARNING]
> Scout-Werkzeuge laufen mit den Rechten des Culpeo-Studio-Prozesses. Die Pfadprüfung ist keine Betriebssystem-Sandbox.

- Scout-Projekte sind auf ausdrücklich gebundene Verzeichnisse begrenzt.
- Dateiänderungen erscheinen vor dem Schreiben als Diff.
- API-Schlüssel liegen lokal in `data/settings.json` und werden nur beim jeweiligen Anbieter verwendet.
