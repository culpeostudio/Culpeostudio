# Culpeo Studio Installations-Leitfaden

Du kannst Culpeo Studio als fertiges Quick-Install-Archiv starten oder das Projekt aus dem Quellcode ausführen.

---

## 1. Quick Install (Empfohlen)

Quick-Install-Pakete sind vorkompiliert und enthalten alles Nötige. Flutter, Go und Dart müssen nicht installiert sein.

### Download-Pakete

Öffne die [GitHub-Releases](https://github.com/culpeohq/CulpeoStudio/releases)-Seite und wähle das passende Archiv:

| Plattform | Architektur | Archiv-Name | Starter-Datei |
|---|---|---|---|
| **Linux** | x64 | `culpeostudio-*-linux-x64-quickinstall.tar.gz` | `./culpeostudio` |
| **Windows** | x64 | `culpeostudio-*-windows-x64-quickinstall.zip` | `culpeostudio.exe` |
| **macOS** | ARM64 (Apple Silicon) | `culpeostudio-*-macos-arm64-quickinstall.tar.gz` | `./culpeostudio` |

---

## 2. Quellcode-Start (Entwickler)

### Was du vorher brauchst

- **Go:** 1.25 oder neuer
- **Flutter / Dart:** Flutter 3.44+ / Dart 3.12+ (Desktop aktiviert)
- **Python:** Python 3.10+
- **C/C++ Toolchain:** `gcc`, `g++`, `make`, `cmake` (für `llama.cpp`)

### Starten

```bash
git clone https://github.com/culpeohq/CulpeoStudio.git
cd CulpeoStudio
./start.sh
```

Das Skript baut und startet das Go-Backend, legt die lokalen Daten an und öffnet anschließend das Flutter-Frontend.
