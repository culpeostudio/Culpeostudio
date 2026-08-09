# Culpeo Studio Installation Guide

There are two ways to start Culpeo Studio: use a ready-made Quick Install archive, or run the project from source.

---

## 1. Quick Install (Recommended)

Quick Install packages are precompiled and self-contained. You do not need Flutter, Go, or Dart installed.

### Downloads

Open the [GitHub Releases](https://github.com/culpeostudio/Culpeostudio/releases) page and choose the archive for your system:

| Platform | Target | Archive Format | Executable Name |
|---|---|---|---|
| **Linux** | x64 | `culpeostudio-*-linux-x64-quickinstall.tar.gz` | `./culpeostudio` |
| **Windows** | x64 | `culpeostudio-*-windows-x64-quickinstall.zip` | `culpeostudio.exe` |
| **macOS** | ARM64 (Apple Silicon) | `culpeostudio-*-macos-arm64-quickinstall.tar.gz` | `./culpeostudio` |

---

## 2. Run from Source (Developers)

### Prerequisites

For a source build, install:

- **Go:** 1.25 or higher
- **Flutter / Dart:** Flutter 3.44+ / Dart 3.12+ (with desktop support enabled: `flutter config --enable-linux-desktop`)
- **Python:** Python 3.10+
- **C/C++ Toolchain:** `gcc`, `g++`, `make`, `cmake` (required for local `llama.cpp` compilation/execution)

### Building & Running

```bash
git clone https://github.com/culpeostudio/Culpeostudio.git
cd Culpeostudio
./start.sh
```

`start.sh` builds and starts the Go backend, creates the required local data files, and launches the Flutter frontend.
