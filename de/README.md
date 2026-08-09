<p align="center">
  <img src="../assets/readme-hero.png" alt="Culpeo Studio - Lokales Modell-Studio & llama.cpp Desktop GUI" width="100%">
</p>

<h1 align="center">Culpeo Studio</h1>

<p align="center">
  <strong>Hardwarebewusstes, lokales Open-Source Desktop-Studio für Modelle (LLMs).</strong><br>
  Führe GGUF-Modelle lokal mit llama.cpp aus, binde OpenRouter & Featherless API-Anbieter ein und verwalte Scouts-Agenten, Vektor-Gedächtnis, Textsuche und Benchmarks in einem einheitlichen Flutter Desktop-Workspace.
</p>

<p align="center">
  <a href="../README.md">English</a> ·
  <a href="README.md"><strong>Deutsch</strong></a>
</p>

<p align="center">
  <a href="https://github.com/culpeohq/CulpeoStudio/releases"><img alt="Neuestes Release" src="https://img.shields.io/github/v/release/culpeohq/CulpeoStudio?include_prereleases&amp;sort=semver&amp;style=for-the-badge&amp;color=C1440E"></a>
  <img alt="Projektstatus: Beta" src="https://img.shields.io/badge/status-beta-F59E0B?style=for-the-badge">
  <img alt="Linux, Windows und macOS" src="https://img.shields.io/badge/desktop-Linux%20%7C%20Windows%20%7C%20macOS-5A78FF?style=for-the-badge">
  <a href="https://github.com/culpeohq/CulpeoStudio/blob/main/LICENSE"><img alt="AGPL-3.0" src="https://img.shields.io/badge/license-AGPL--3.0-8B5CF6?style=for-the-badge"></a>
</p>

## Überblick

**Culpeo Studio** ist eine Desktop-App für die Arbeit mit Modellen. Du kannst GGUF-Modelle auf deinem Rechner ausführen, bei Bedarf einen API-Anbieter nutzen und Chats, Einstellungen und Memory standardmäßig lokal halten.

Das Projekt befindet sich noch in Phase 1 Beta. Die wichtigsten Abläufe funktionieren bereits; News und Benchmark werden weiter ausgebaut.

| Kernfunktion | Technologie & Umsetzung |
|:---|:---|
| **Lokale LLM Inferenz** | `llama.cpp` (`llama-server`) mit CUDA, Vulkan, SYCL, Metal & CPU Beschleunigung |
| **Control Plane** | Go 1.25+ gRPC Mikro-Services (`culpeostudio.*.v1`) auf Loopback-Port 50051 |
| **Frontend UI** | Flutter 3.44+ / Dart 3.12+ Material 3 Client mit adaptivem CulpeoGrid System |
| **KI-Assistenten** | Scouts Agenten-Runner mit Tool-Ausführung, Planungsmodus, Rechten & Diffs |
| **Langzeit-Gedächtnis** | Hybride SQLite FTS5 Textsuche + Vektorindex (lokaler 128-d Hash & ONNX-Sidecar) |
| **Textsuche** | CulpeoSearch Metasuche (DuckDuckGo, Brave, Google, Bing, Wikipedia) mit Markdown-Extraktion |
| **Unterstützte Formate** | GGUF-Modelle von Hugging Face sowie OpenRouter- & Featherless-APIs |

---

## Inhalt

| Abschnitt | Beschreibung |
|:---|:---|
| [Download](https://github.com/culpeohq/CulpeoStudio/releases) | Veröffentlichte Pakete und Release-Notes |
| [Installation](#install) | Schnellinstallation und Quellcode-Start |
| [Zwei Betriebsarten](#ein-studio-zwei-wege) | Lokale Runtimes und optionale API-Anbieter |
| [Highlights](#was-culpeo-studio-unterscheidet) | Engine, Scouts, Memory, Suche und Marktplatz |
| [Engine-Demo](#siehe-wie-die-engine-eine-sicherere-wahl-trifft) | Automatische VRAM-Fallback Demonstration |
| [Features](docs/FEATURES.md) | Vollständige Feature- und Reifegrad-Übersicht |
| [Architektur](docs/ARCHITECTURE.md) | Komponenten, Schnittstellen und Datenflüsse |
| [Datenschutz](docs/PRIVACY.md) | Lokaler Speicher und Netzwerkgrenzen |
| [Transparenz](docs/TRANSPARENCY.md) | Anbieterentscheidungen und Open-Source-Lizenz |

> [!IMPORTANT]
> Culpeo Studio befindet sich in der **Phase 1 Beta**. Chat, Modellverwaltung, lokale Inferenz, API-Anbieter, Memory und Marktplatz sind heute nutzbar.

---

## Ein Studio, zwei Wege

<table>
  <tr>
    <td width="50%" valign="top">
      <h3>Lokal ausführen</h3>
      <p>Culpeo Studio erkennt RAM, GPUs und verfügbaren VRAM vor dem Modellstart. Es schlägt eine Kontextgröße vor, wählt die passende llama.cpp Runtime und schaltet bei VRAM-Engpässen automatisch auf eine sicherere Konfiguration zurück.</p>
    </td>
    <td width="50%" valign="top">
      <h3>API-Anbieter nutzen</h3>
      <p>Nutze denselben Marktplatz und Chat-Workflow mit gehosteten Modellen. Provider-Schlüssel bleiben in den lokalen Anwendungsdaten und werden nur an den gewählten Anbieter gesendet.</p>
    </td>
  </tr>
  <tr>
    <td width="50%" valign="top"><strong>Engine:</strong> llama.cpp (CUDA · Vulkan · SYCL · Metal · CPU)</td>
    <td width="50%" valign="top"><strong>Anbieter:</strong> OpenRouter · Featherless</td>
  </tr>
</table>

---

## Was du damit machen kannst

- **Lokale Modelle starten:** Culpeo Studio prüft RAM, GPU und VRAM und versucht bei Bedarf eine kleinere, passende Konfiguration.
- **Mit Scouts arbeiten:** Erstelle fokussierte Assistenten, binde sie an ein Projekt und prüfe Dateiänderungen vor dem Schreiben.
- **Kontext behalten:** Memory speichert nützliche Informationen lokal und macht sie per Text- und Vektorsuche wieder auffindbar.
- **Öffentlich suchen:** CulpeoSearch holt Seiten aus mehreren Suchquellen und bereitet sie als lesbares Markdown auf.
- **Modelle vergleichen:** Im Marktplatz findest du lokale GGUF-Downloads und API-Modelle mit Angaben zu Format, Preis und Hardware-Eignung.

---

## Ein Blick in die Oberfläche

<p align="center">
  <img src="../assets/screenshots/chat.png" alt="Culpeo Studio Chat mit Scout-Sitzung und Projektleiste" width="900">
</p>

<p align="center"><em>Chat, Marktplatz, News und Benchmark zeigen die vier wichtigsten Einstiege in die Anwendung.</em></p>

<table>
  <tr>
    <td width="50%"><img src="../assets/screenshots/markplace.png" alt="Culpeo Studio Marktplatz" width="100%"><p align="center"><strong>Marktplatz</strong><br>Lokale Downloads und API-Modelle filtern.</p></td>
    <td width="50%"><img src="../assets/screenshots/news.png" alt="Culpeo Studio News-Feed" width="100%"><p align="center"><strong>News</strong><br>Artikel durchsuchen, filtern und speichern.</p></td>
  </tr>
  <tr>
    <td width="50%"><img src="../assets/screenshots/benchmark.png" alt="Culpeo Studio Benchmark" width="100%"><p align="center"><strong>Benchmark</strong><br>Modelle nach Kategorien vergleichen.</p></td>
    <td width="50%"><img src="../assets/screenshots/chat.png" alt="Culpeo Studio Chat" width="100%"><p align="center"><strong>Chat</strong><br>Projekte und Sitzungen an einem Ort.</p></td>
  </tr>
</table>

---

## Warum Culpeo Studio?

| Funktion | Culpeo Studio | Herkömmliche Lokale LLM Clients |
|:---|:---:|:---:|
| **Hardware-Erkennung & Auto-Fallback** | Vollständiger RAM/VRAM-Probe & automatisches Fallback | Manuelles Testen nach OOM-Abstürzen |
| **Control-Plane-Protokoll** | Hochperformantes Go gRPC (`culpeostudio.*.v1`) | REST HTTP-Polling oder Electron |
| **Agenten-Werkzeuge** | Scouts mit Planungsmodus, Pfadgrenzen & Diffs | Reine Chat-Prompts |
| **Hybrider Vektorspeicher** | SQLite FTS5 + Vektor-Retrieval | Nur sitzungsbasierter Kontext |
| **UI Design-System** | Flutter Material 3 CulpeoGrid | Generische Web-Wrapper |
| **Open-Source-Lizenz** | 100% Kostenlos AGPL-3.0 | Proprietäre Komponenten |

---

## Installation

### Schnellinstallation (Quick Install)

Lade das **Quick Install**-Archiv für deine Plattform von der [Releases-Seite](https://github.com/culpeohq/CulpeoStudio/releases) herunter. Entpacke das Archiv einmalig und starte `culpeostudio` (unter Windows `culpeostudio.exe`).

| Zielplattform | Datei-Endung |
|---|---|
| **Linux x64** | `-linux-x64-quickinstall.tar.gz` |
| **Windows x64** | `-windows-x64-quickinstall.zip` |
| **macOS ARM64** | `-macos-arm64-quickinstall.tar.gz` |

### Quellcode-Start

```bash
git clone https://github.com/culpeohq/CulpeoStudio.git
cd CulpeoStudio
./start.sh
```

Voraussetzungen: Go 1.25+, Flutter 3.44+ / Dart 3.12+, Python 3 und C/C++-Buildtools.

---

## Mitwirken, Sicherheit und Lizenz

Beiträge sind willkommen! Starte mit [CONTRIBUTING.md](CONTRIBUTING.md). Pull Requests erfordern die Zustimmung zur [CLA](https://github.com/culpeohq/CulpeoStudio/blob/main/CLA.md) und signierte Commits (`git commit -s`).

Sicherheitslücken bitte vertraulich an `security@culpeohq.com` melden (siehe [SECURITY.md](https://github.com/culpeohq/CulpeoStudio/blob/main/SECURITY.md)).

Culpeo Studio steht unter der [GNU AGPL-3.0 Lizenz](https://github.com/culpeohq/CulpeoStudio/blob/main/LICENSE). Siehe auch die [Markenrichtlinien](https://github.com/culpeohq/CulpeoStudio/blob/main/TRADEMARK.md).

---

<p align="center">
  <sub>Erstellt von culpeohq · Powered by Culpeo Studio</sub>
</p>
