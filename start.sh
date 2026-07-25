#!/usr/bin/env bash
# Startet die Dev-Konsole (Textual-TUI), die Backend und Frontend
# in der richtigen Reihenfolge (erst Backend, dann Frontend) verwaltet.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR/backend"

exec .venv/bin/python backend-console.py
