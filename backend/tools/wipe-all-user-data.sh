#!/usr/bin/env bash
set -euo pipefail




if [[ "${1:-}" != "--confirm" ]]; then
  echo "Abbruch: Ausfuehrung nur mit --confirm." >&2
  echo "Beispiel: ./tools/wipe-all-user-data.sh --confirm" >&2
  exit 1
fi

DATA_DIR="${DATA_DIR:-data}"
if [[ ! -d "$DATA_DIR" ]]; then
  echo "Datenverzeichnis nicht gefunden: $DATA_DIR" >&2
  exit 1
fi


targets=(
  "$DATA_DIR/login_accounts.json"
  "$DATA_DIR/login_authenticator.json"
  "$DATA_DIR/bots.json"
  "$DATA_DIR/bots.json.v1.bak"
  "$DATA_DIR/engine_user_preferences.json"
  "$DATA_DIR/user_preferences.json"
  "$DATA_DIR/active_api_models.json"
  "$DATA_DIR/settings.json"
  "$DATA_DIR/download_jobs.json"
  "$DATA_DIR/memory"
  "$DATA_DIR/philox/sessions"
)

for target in "${targets[@]}"; do
  rm -rf -- "$target"
done

echo "Alle Benutzer-, Chat-, Memory- und API-Daten wurden geloescht. Modelle und Engine-Laufzeiten bleiben erhalten."
