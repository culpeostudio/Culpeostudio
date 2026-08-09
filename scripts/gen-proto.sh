#!/usr/bin/env bash
# Regenerates the Go and Dart gRPC bindings from backend/proto/.
#
# Both output trees (backend/gen/go, frontend/lib/generated) are wiped and
# rewritten on every run - never edit anything in them by hand.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

export PATH="$PATH:${GOPATH:-$HOME/go}/bin:$HOME/.pub-cache/bin"

for tool in buf protoc-gen-go protoc-gen-go-grpc protoc-gen-dart; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "error: $tool not found in PATH" >&2
    echo "  buf, protoc-gen-go, protoc-gen-go-grpc: go install ..." >&2
    echo "  protoc-gen-dart: dart pub global activate protoc_plugin" >&2
    exit 1
  fi
done

buf lint
buf generate

echo "generated: backend/gen/go, frontend/lib/generated"
