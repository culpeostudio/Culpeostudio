#!/usr/bin/env bash
# Builds a small, immutable-style Culpeo Node archive. It intentionally
# contains only the standalone cmd/node binary, never the full Studio source.
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
VERSION="dev"
OUTPUT_DIR="$ROOT_DIR/dist"
TARGET_ARCH=""

usage() {
  cat <<'TEXT'
Build a Culpeo Node release archive

  ./scripts/build-node-release.sh [--version <version>] [--arch <amd64|arm64>] [--output <directory>]

The result is a Linux archive plus a .sha256 file. Transfer both to the
server, then install with culpeo-node/install.sh --archive ... --sha256 ... .
TEXT
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --version) VERSION="${2:-}"; shift 2 ;;
    --arch) TARGET_ARCH="${2:-}"; shift 2 ;;
    --output) OUTPUT_DIR="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done

[[ "$VERSION" =~ ^[A-Za-z0-9][A-Za-z0-9._+-]*$ ]] || {
  printf '%s\n' 'version must use only letters, numbers, dot, underscore, plus, or hyphen' >&2
  exit 2
}
command -v go >/dev/null 2>&1 || { printf '%s\n' 'Go is required to build a Node release.' >&2; exit 1; }
command -v tar >/dev/null 2>&1 || { printf '%s\n' 'tar is required to package a Node release.' >&2; exit 1; }
command -v sha256sum >/dev/null 2>&1 || { printf '%s\n' 'sha256sum is required to package a Node release.' >&2; exit 1; }

if [[ -z "$TARGET_ARCH" ]]; then
  TARGET_ARCH="$(uname -m)"
fi
case "$TARGET_ARCH" in
  x86_64|amd64) ARCH="amd64" ;;
  aarch64|arm64) ARCH="arm64" ;;
  *) printf 'unsupported Linux architecture: %s\n' "$TARGET_ARCH" >&2; exit 1 ;;
esac

mkdir -p "$OUTPUT_DIR"
BUILD_DIR="$(mktemp -d)"
trap 'rm -rf -- "$BUILD_DIR"' EXIT
PACKAGE_DIR="$BUILD_DIR/culpeo-node"
mkdir -p "$PACKAGE_DIR"

(
  cd "$ROOT_DIR/backend"
  GOOS=linux GOARCH="$ARCH" CGO_ENABLED=0 go build -trimpath \
    -ldflags "-s -w -X main.version=$VERSION" \
    -o "$PACKAGE_DIR/culpeo-node" ./cmd/node
)
printf '%s\n' "$VERSION" > "$PACKAGE_DIR/VERSION"

ARCHIVE="$OUTPUT_DIR/culpeo-node-${VERSION}-linux-${ARCH}.tar.gz"
tar -C "$BUILD_DIR" -czf "$ARCHIVE" culpeo-node
sha256sum "$ARCHIVE" > "$ARCHIVE.sha256"
printf '%s\n' "built: $ARCHIVE"
printf '%s\n' "sha256: $ARCHIVE.sha256"
