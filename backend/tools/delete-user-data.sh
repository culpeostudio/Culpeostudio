#!/usr/bin/env bash
set -euo pipefail

# Stop the backend first, then invoke this from backend/:
# ./tools/delete-user-data.sh -username NAME -confirm
cd "$(dirname "$0")/.."
go run ./cmd/delete-user-data "$@"
