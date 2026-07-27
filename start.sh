#!/usr/bin/env bash
# Startet die Dev-Konsole (Textual-TUI), die Backend und Frontend
# in der richtigen Reihenfolge (erst Backend, dann Frontend) verwaltet.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Eine saubere Quellcode-Installation wird vor jedem Start per Fast-Forward auf
# den aktuellen main-Stand gebracht. Lokale Änderungen, andere Branches und
# fehlendes Netzwerk werden niemals überschrieben: In diesen Fällen startet die
# vorhandene Version und der Updater gibt nur einen Hinweis aus.
SKIP_UPDATE="${PHILOENGINE_SKIP_UPDATE:-}"
if [[ "${SKIP_UPDATE,,}" != "1" && "${SKIP_UPDATE,,}" != "true" && \
      "${SKIP_UPDATE,,}" != "yes" && "${SKIP_UPDATE,,}" != "on" ]]; then
  UPDATER_DIR="$ROOT_DIR/.philoengine"
  UPDATER_BIN="$UPDATER_DIR/philo-updater"
  UPDATER_TMP="$UPDATER_DIR/philo-updater.tmp.$$"
  mkdir -p "$UPDATER_DIR"
  if command -v go >/dev/null 2>&1; then
    if (
      cd "$ROOT_DIR/backend"
      go build -trimpath -o "$UPDATER_TMP" ./cmd/philo-updater
    ); then
      chmod 700 "$UPDATER_TMP"
      mv -f "$UPDATER_TMP" "$UPDATER_BIN"
      "$UPDATER_BIN" source \
        --root "$ROOT_DIR" \
        --repository "https://github.com/kuchenboss/MyPhiloEngine.git" \
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
