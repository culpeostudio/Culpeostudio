#!/usr/bin/env bash


set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"





# Quelle für das Quellcode-Update. Solange sie leer ist, startet der Launcher
# ohne Netzzugriff — nötig, bis das Repository unter culpeohq wirklich steht.
# Danach genügt:
#   CULPEOSTUDIO_REPOSITORY=https://github.com/culpeostudio/Culpeostudio.git ./start.sh
# Achtung: Das Update überschreibt lokale Änderungen am Quellcode.
REPOSITORY="${CULPEOSTUDIO_REPOSITORY:-}"

SKIP_UPDATE="${CULPEOSTUDIO_SKIP_UPDATE:-}"
if [[ -z "$REPOSITORY" ]]; then
  echo "[Updater] Keine Quellcode-Quelle gesetzt; es startet der lokale Stand." >&2
elif [[ "${SKIP_UPDATE,,}" != "1" && "${SKIP_UPDATE,,}" != "true" && \
      "${SKIP_UPDATE,,}" != "yes" && "${SKIP_UPDATE,,}" != "on" ]]; then
  UPDATER_DIR="$ROOT_DIR/.culpeostudio"
  UPDATER_BIN="$UPDATER_DIR/culpeo-updater"
  UPDATER_TMP="$UPDATER_DIR/culpeo-updater.tmp.$$"
  mkdir -p "$UPDATER_DIR"
  if command -v go >/dev/null 2>&1; then
    if (
      cd "$ROOT_DIR/backend"
      go build -trimpath -o "$UPDATER_TMP" ./cmd/culpeo-updater
    ); then
      chmod 700 "$UPDATER_TMP"
      mv -f "$UPDATER_TMP" "$UPDATER_BIN"
      "$UPDATER_BIN" source \
        --root "$ROOT_DIR" \
        --repository "$REPOSITORY" \
        --branch main || true
    else
      rm -f "$UPDATER_TMP"
      echo "[Updater] Updater konnte nicht gebaut werden; vorhandene Version wird gestartet." >&2
    fi
  else
    echo "[Updater] Go ist nicht verfügbar; automatische Quellcode-Aktualisierung wurde übersprungen." >&2
  fi
fi

cd "$ROOT_DIR/backend"

exec .venv/bin/python backend-console.py
